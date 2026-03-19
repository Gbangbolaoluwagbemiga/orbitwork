// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IOrbitWork.sol";
import "../interfaces/IEscrowHook.sol";

library OrbitWorkLib {
    using SafeERC20 for IERC20;

    struct FreelancerRating {
        uint256 totalRatings;
        uint256 sumRatings;
        uint256 averageRating;
    }

    struct EscrowRating {
        address rater;
        address freelancer;
        uint256 rating;
        uint256 escrowId;
        uint256 ratedAt;
        bool exists;
    }

    struct EscrowState {
        // --- Core Protocol State ---
        uint256 nextEscrowId; 
        address orbitworkToken;
        uint256 platformFeeBP;
        address feeCollector;
        bool jobCreationPaused;

        // --- Mappings ---
        mapping(uint256 => IOrbitWork.EscrowData) escrows;
        mapping(uint256 => mapping(uint256 => IOrbitWork.Milestone)) milestones;
        mapping(address => uint256[]) userEscrows;
        mapping(address => bool) authorizedArbiters;
        mapping(address => bool) whitelistedTokens;
        mapping(address => uint256) escrowedAmount;
        mapping(address => uint256) totalFeesByToken;

        // --- Marketplace & Reputation ---
        mapping(uint256 => IOrbitWork.Application[]) escrowApplications;
        mapping(uint256 => mapping(address => bool)) hasApplied;
        mapping(address => uint256) reputation;
        mapping(address => uint256) completedEscrows;
        mapping(address => bool) selfVerifiedUsers;
        mapping(address => uint256) verificationTimestamp;

        // --- Integrations & Automation ---
        IEscrowHook escrowHook;
        bool liquidEscrowEnabled;
        mapping(uint256 => IEscrowHook.PoolKey) escrowPoolKeys;
        mapping(uint256 => IEscrowHook.ModifyLiquidityParams) escrowPoolParams;
        address reactiveCallbackSender;

        // --- Ratings ---
        mapping(address => FreelancerRating) freelancerRatings;
        mapping(uint256 => EscrowRating) escrowRatings;
        mapping(address => uint256[]) freelancerRatedEscrows;
    }

    function createEscrow(
        EscrowState storage s,
        address depositor,
        address beneficiary,
        address[] calldata arbiters,
        uint8 requiredConfirmationsParam,
        uint256[] calldata milestoneAmounts,
        string[] calldata milestoneDescriptions,
        address token,
        uint256 deadline,
        string calldata projectTitle,
        string calldata projectDescription,
        bool isNative,
        uint256 msgValue,
        uint256 maxMilestones
    ) external returns (uint256 id) {
        require(milestoneAmounts.length > 0 && milestoneAmounts.length <= maxMilestones, "Invalid milestones");
        require(milestoneAmounts.length == milestoneDescriptions.length, "Mismatched arrays");

        id = s.nextEscrowId++;
        IOrbitWork.EscrowData storage e = s.escrows[id];
        e.depositor = depositor;
        e.beneficiary = beneficiary;
        e.token = token;
        e.deadline = deadline;
        e.status = IOrbitWork.EscrowStatus.Pending;
        e.milestoneCount = milestoneAmounts.length;
        e.isOpenJob = (beneficiary == address(0));
        e.projectTitle = projectTitle;
        e.projectDescription = projectDescription;
        e.createdAt = block.timestamp;

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < milestoneAmounts.length; ++i) {
            require(milestoneAmounts[i] > 0, "Invalid amount");
            totalAmount += milestoneAmounts[i];
            s.milestones[id][i] = IOrbitWork.Milestone({
                amount: milestoneAmounts[i],
                description: milestoneDescriptions[i],
                status: IOrbitWork.MilestoneStatus.NotStarted,
                submittedAt: 0,
                approvedAt: 0,
                disputedAt: 0,
                disputedBy: address(0),
                disputeReason: ""
            });
        }

        e.totalAmount = totalAmount;
        if (s.platformFeeBP > 0) {
            e.platformFee = (totalAmount * s.platformFeeBP) / 10000;
        }

        if (isNative) {
            require(msgValue >= totalAmount + e.platformFee, "Insufficient ETH");
            s.escrowedAmount[address(0)] += totalAmount;
            s.totalFeesByToken[address(0)] += e.platformFee;
        } else {
            s.escrowedAmount[token] += totalAmount;
            s.totalFeesByToken[token] += e.platformFee;
            IERC20(token).safeTransferFrom(depositor, address(this), totalAmount + e.platformFee);
        }

        e.arbiters = arbiters;
        e.requiredConfirmations = requiredConfirmationsParam;
        
        if (beneficiary != address(0)) {
            s.userEscrows[beneficiary].push(id);
        }
        s.userEscrows[depositor].push(id);

        // --- Liquid Escrow Integration ---
        if (s.liquidEscrowEnabled && address(s.escrowHook) != address(0)) {
            // For hackathon: Construct default PoolKey (ETH/USDC 0.3%)
            // In production, this would be passed or discovered.
            IEscrowHook.PoolKey memory key = IEscrowHook.PoolKey({
                currency0: address(0), 
                currency1: token == address(0) ? 0x8f22D60F408DBA32ba2D4123aD0aE6D3c0b1d28B : token, // Default to USDC if native
                fee: 3000,
                tickSpacing: 60,
                hooks: address(s.escrowHook)
            });
            
            // If the token is actually Currency1 in our pool, swap them
            if (token != address(0) && token < address(0)) {
                // Should not happen with address(0)
            }

            s.escrowPoolKeys[id] = key;
            
            // --- NEW: Approve hook to pull tokens ---
            if (token != address(0)) {
                IERC20(token).approve(address(s.escrowHook), totalAmount + e.platformFee);
            }

            // Perform the "onEscrowCreated" call which moves funds
            // Note: OrbitWork must have moved funds from depositor to itself already (done above)
            // Now we call hook which pulls balance from OrbitWork
            try s.escrowHook.onEscrowCreated(id, totalAmount + e.platformFee, key) returns (uint256 lp, uint256 res) {
                // Success: record or emit
            } catch (bytes memory reason) {
                // Fallback: Continue without liquid escrow if hook fails
                // console2.log("Hook call failed");
            }
        }
    }

    function handleApproval(
        EscrowState storage s,
        uint256 escrowId,
        uint256 milestoneIndex,
        uint256 minRepEligibleValue,
        uint256 repPerMilestone,
        uint256 repPerEscrow
    ) external returns (uint256 totalPayment, uint256 platformYield) {
        IOrbitWork.EscrowData storage e = s.escrows[escrowId];
        IOrbitWork.Milestone storage m = s.milestones[escrowId][milestoneIndex];
        
        require(m.status == IOrbitWork.MilestoneStatus.Submitted, "state");

        uint256 amount = m.amount;
        m.status = IOrbitWork.MilestoneStatus.Approved;
        m.approvedAt = block.timestamp;
        e.paidAmount += amount;
        s.escrowedAmount[e.token] -= amount;

        totalPayment = amount;
        if (s.liquidEscrowEnabled && address(s.escrowHook) != address(0)) {
            IEscrowHook.PoolKey memory key = s.escrowPoolKeys[escrowId];
            if (key.fee != 0) { // Check if key was set
                try s.escrowHook.onMilestoneApproved(escrowId, amount, e.beneficiary) returns (uint256 paymentWithYield, uint256 yield) {
                    totalPayment = paymentWithYield;
                    platformYield = yield;
                } catch {
                    // Fallback to base amount if hook fails
                }
            }
        }

        if (e.totalAmount >= minRepEligibleValue && s.selfVerifiedUsers[e.beneficiary]) {
            s.reputation[e.beneficiary] += repPerMilestone;
        }

        if (e.paidAmount == e.totalAmount) {
            e.status = IOrbitWork.EscrowStatus.Released;
            s.completedEscrows[e.beneficiary] += 1;
            s.completedEscrows[e.depositor] += 1;
            if (e.totalAmount >= minRepEligibleValue) {
                if (s.selfVerifiedUsers[e.beneficiary]) s.reputation[e.beneficiary] += repPerEscrow;
                if (s.selfVerifiedUsers[e.depositor]) s.reputation[e.depositor] += repPerEscrow;
            }
        }
    }

    function rejectMilestone(EscrowState storage s, uint256 escrowId, uint256 idx, string calldata reason, address sender) external {
        IOrbitWork.Milestone storage m = s.milestones[escrowId][idx];
        require(m.status == IOrbitWork.MilestoneStatus.Submitted, "state");
        m.status = IOrbitWork.MilestoneStatus.Rejected;
        m.disputedAt = block.timestamp;
        m.disputedBy = sender;
        m.disputeReason = reason;
    }

    function resubmitMilestone(EscrowState storage s, uint256 escrowId, uint256 idx, string calldata desc) external {
        IOrbitWork.Milestone storage m = s.milestones[escrowId][idx];
        require(m.status == IOrbitWork.MilestoneStatus.Rejected, "state");
        m.status = IOrbitWork.MilestoneStatus.Submitted;
        m.submittedAt = block.timestamp;
        if (bytes(desc).length > 0) m.description = desc;
    }

    function resolveDispute(
        EscrowState storage s,
        uint256 escrowId,
        uint256 milestoneIndex,
        uint256 beneficiaryAmount
    ) external returns (uint256 refundAmount) {
        IOrbitWork.EscrowData storage e = s.escrows[escrowId];
        IOrbitWork.Milestone storage m = s.milestones[escrowId][milestoneIndex];
        
        uint256 milestoneAmount = m.amount;
        require(beneficiaryAmount <= milestoneAmount, "alloc");
        refundAmount = milestoneAmount - beneficiaryAmount;

        m.status = IOrbitWork.MilestoneStatus.Resolved;
        m.approvedAt = block.timestamp;
        
        if (beneficiaryAmount > 0) {
            e.paidAmount += beneficiaryAmount;
            s.escrowedAmount[e.token] -= beneficiaryAmount;
        }
        if (refundAmount > 0) s.escrowedAmount[e.token] -= refundAmount;

        e.status = IOrbitWork.EscrowStatus.InProgress;
        if (e.paidAmount == e.totalAmount) {
            e.status = IOrbitWork.EscrowStatus.Released;
            s.completedEscrows[e.beneficiary] += 1;
            s.completedEscrows[e.depositor] += 1;
        }
    }

    function rateFreelancer(
        EscrowState storage s,
        uint256 escrowId,
        uint256 rating,
        address rater
    ) external returns (uint256 newAverageRating) {
        IOrbitWork.EscrowData storage e = s.escrows[escrowId];
        address freelancer = e.beneficiary;
        
        FreelancerRating storage fr = s.freelancerRatings[freelancer];
        
        // Update rating
        fr.totalRatings += 1;
        fr.sumRatings += rating;
        fr.averageRating = (fr.sumRatings * 100) / fr.totalRatings;
        
        s.escrowRatings[escrowId] = EscrowRating({
            rater: rater,
            freelancer: freelancer,
            rating: rating,
            escrowId: escrowId,
            ratedAt: block.timestamp,
            exists: true
        });
        
        s.freelancerRatedEscrows[freelancer].push(escrowId);
        return fr.averageRating;
    }

    function emergencyWithdraw(
        EscrowState storage s,
        address token,
        uint256 amount,
        address recipient
    ) external {
        uint256 balance;
        if (token == address(0)) {
            balance = address(this).balance;
            uint256 reserved = s.escrowedAmount[address(0)] + s.totalFeesByToken[address(0)];
            require(balance > reserved, "Nothing withdrawable");
            uint256 available = balance - reserved;
            require(amount <= available, "Amount exceeds available");
            (bool success, ) = payable(recipient).call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            balance = IERC20(token).balanceOf(address(this));
            uint256 reserved = s.escrowedAmount[token] + s.totalFeesByToken[token];
            require(balance >= reserved + amount, "Insufficient non-escrow balance");
            IERC20(token).safeTransfer(recipient, amount);
        }
    }

    function verifyUserIdentity(EscrowState storage s, address user) external {
        require(user != address(0), "Invalid user");
        require(!s.selfVerifiedUsers[user], "Already verified");
        s.selfVerifiedUsers[user] = true;
        s.verificationTimestamp[user] = block.timestamp;
    }

    function refundEscrow(EscrowState storage s, uint256 escrowId) external returns (uint256 refundAmount) {
        IOrbitWork.EscrowData storage e = s.escrows[escrowId];
        refundAmount = e.totalAmount - e.paidAmount;
        e.status = IOrbitWork.EscrowStatus.Refunded;
        s.escrowedAmount[e.token] -= refundAmount;
    }

    function emergencyRefundAfterDeadline(EscrowState storage s, uint256 escrowId) external returns (uint256 refundAmount) {
        IOrbitWork.EscrowData storage e = s.escrows[escrowId];
        refundAmount = e.totalAmount - e.paidAmount;
        e.status = IOrbitWork.EscrowStatus.Expired;
        s.escrowedAmount[e.token] -= refundAmount;
    }

    function getEscrowSummary(EscrowState storage s, uint256 escrowId) external view returns (
        address depositor,
        address beneficiary,
        address[] memory arbiters,
        IOrbitWork.EscrowStatus status,
        uint256 totalAmount,
        uint256 paidAmount,
        uint256 remaining,
        address token,
        uint256 deadline,
        bool workStarted,
        uint256 createdAt,
        uint256 milestoneCount,
        bool isOpenJob,
        string memory projectTitle,
        string memory projectDescription
    ) {
        IOrbitWork.EscrowData storage e = s.escrows[escrowId];
        return (
            e.depositor,
            e.beneficiary,
            e.arbiters,
            e.status,
            e.totalAmount,
            e.paidAmount,
            e.totalAmount - e.paidAmount,
            e.token,
            e.deadline,
            e.workStarted,
            e.createdAt,
            e.milestoneCount,
            e.isOpenJob,
            e.projectTitle,
            e.projectDescription
        );
    }
}
