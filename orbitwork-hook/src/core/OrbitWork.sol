// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./modules/EscrowCore.sol";
import "./modules/OrbitWorkLib.sol";

/**
 * @title OrbitWork
 * @dev Optimized main contract for the OrbitWork protocol.
 * Consolidates all features into one contract to stay under EVM size limits.
 */
contract OrbitWork is EscrowCore {
    using SafeERC20 for IERC20;
    using OrbitWorkLib for OrbitWorkLib.EscrowState;

    constructor(
        address _orbitworkToken,
        address _feeCollector,
        uint256 _platformFeeBP
    ) EscrowCore(_orbitworkToken, _feeCollector, _platformFeeBP) {}

    // ===== Escrow Management =====
    function createEscrow(
        address ben, address[] calldata arbs, uint8 req, uint256[] calldata mAmts,
        string[] calldata mDescs, address tok, uint256 dur, string calldata pT, string calldata pD
    ) external override whenNotPaused whenJobCreationNotPaused nonReentrant returns (uint256) {
        return _createInternal(ben, arbs, req, mAmts, mDescs, tok, dur, pT, pD, false, 0);
    }

    function createEscrowNative(
        address ben, address[] calldata arbs, uint8 req, uint256[] calldata mAmts,
        string[] calldata mDescs, uint256 dur, string calldata pT, string calldata pD
    ) external payable override whenNotPaused whenJobCreationNotPaused nonReentrant returns (uint256) {
        return _createInternal(ben, arbs, req, mAmts, mDescs, address(0), dur, pT, pD, true, msg.value);
    }

    function _createInternal(
        address ben, address[] calldata arbs, uint8 req, uint256[] calldata mAmts,
        string[] calldata mDescs, address tok, uint256 dur, string calldata pT, string calldata pD,
        bool isNative, uint256 val
    ) internal returns (uint256 id) {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        id = OrbitWorkLib.createEscrow(s, msg.sender, ben, arbs, req, mAmts, mDescs, tok, block.timestamp + dur, pT, pD, isNative, val, MAX_MILESTONES);
        EscrowData storage e = s.escrows[id];
        emit EscrowCreated(id, msg.sender, ben, arbs, e.totalAmount, e.platformFee, tok, e.deadline, e.isOpenJob);
    }

    // ===== Work Lifecycle =====
    function startWork(uint256 eId) external override validEscrow(eId) onlyBeneficiary(eId) whenNotPaused {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        EscrowData storage e = s.escrows[eId];
        require(e.status == EscrowStatus.Pending && !e.workStarted, "state");
        e.workStarted = true;
        e.status = EscrowStatus.InProgress;
        if (e.platformFee > 0) s.totalFeesByToken[e.token] += e.platformFee;
        emit WorkStarted(eId, msg.sender, block.timestamp);
        emit EscrowUpdated(eId, EscrowStatus.InProgress, block.timestamp);
    }

    function submitMilestone(uint256 eId, uint256 idx, string calldata desc) external override validEscrow(eId) onlyBeneficiary(eId) whenNotPaused {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        Milestone storage m = s.milestones[eId][idx];
        require(m.status == MilestoneStatus.NotStarted, "state");
        m.status = MilestoneStatus.Submitted;
        m.submittedAt = block.timestamp;
        if (bytes(desc).length > 0) m.description = desc;
        emit MilestoneSubmitted(eId, idx, msg.sender, m.description, block.timestamp);
    }

    function approveMilestone(uint256 eId, uint256 idx, uint256, bytes calldata) external override validEscrow(eId) onlyDepositor(eId) whenNotPaused nonReentrant {
        _approveInternal(eId, idx);
    }

    function autoApproveMilestone(uint256 eId, uint256 idx) external override validEscrow(eId) whenNotPaused nonReentrant {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        require(msg.sender == s.reactiveCallbackSender, "auth");
        Milestone storage m = s.milestones[eId][idx];
        require(block.timestamp > m.submittedAt + DISPUTE_PERIOD, "delay");
        _approveInternal(eId, idx);
    }

    function _approveInternal(uint256 eId, uint256 idx) internal {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        EscrowData storage e = s.escrows[eId];
        uint256 baseAmt = s.milestones[eId][idx].amount;
        (uint256 pay, uint256 yield) = OrbitWorkLib.handleApproval(s, eId, idx, MIN_REP_ELIGIBLE_ESCROW_VALUE, REPUTATION_PER_MILESTONE, REPUTATION_PER_ESCROW);
        _transferOut(e.token, e.beneficiary, pay);
        if (yield > 0) _transferOut(e.token, s.feeCollector, yield);
        emit MilestoneApproved(eId, idx, msg.sender, baseAmt, block.timestamp);
        if (e.status == EscrowStatus.Released) {
            emit EscrowCompleted(eId, e.beneficiary, e.paidAmount);
            emit EscrowUpdated(eId, EscrowStatus.Released, block.timestamp);
        }
    }

    function rejectMilestone(uint256 eId, uint256 idx, string calldata r) external override validEscrow(eId) onlyDepositor(eId) whenNotPaused nonReentrant {
        OrbitWorkLib.rejectMilestone(_getLogicState(), eId, idx, r, msg.sender);
        emit MilestoneRejected(eId, idx, msg.sender, r, block.timestamp);
    }

    function resubmitMilestone(uint256 eId, uint256 idx, string calldata d) external override validEscrow(eId) onlyBeneficiary(eId) whenNotPaused nonReentrant {
        OrbitWorkLib.resubmitMilestone(_getLogicState(), eId, idx, d);
        emit MilestoneResubmitted(eId, idx, msg.sender, d, block.timestamp);
    }

    // ===== Marketplace =====
    function applyToJob(uint256 eId, string calldata cover, uint256 tim) external override validEscrow(eId) nonReentrant whenNotPaused {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        EscrowData storage e = s.escrows[eId];
        require(e.isOpenJob && e.status == EscrowStatus.Pending && !s.hasApplied[eId][msg.sender], "job");
        require(s.escrowApplications[eId].length < MAX_APPLICATIONS, "apps");
        require(msg.sender != e.depositor, "depositor");
        s.escrowApplications[eId].push(Application({
            freelancer: msg.sender, coverLetter: cover, proposedTimeline: tim, appliedAt: block.timestamp,
            exists: true, averageRating: 0, totalRatings: 0
        }));
        s.hasApplied[eId][msg.sender] = true;
        emit ApplicationSubmitted(eId, msg.sender, cover, tim);
    }

    function acceptFreelancer(uint256 eId, address free) external override validEscrow(eId) onlyDepositor(eId) nonReentrant whenNotPaused {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        EscrowData storage e = s.escrows[eId];
        require(e.isOpenJob && e.status == EscrowStatus.Pending && s.hasApplied[eId][free], "free");
        e.beneficiary = free;
        e.isOpenJob = false;
        s.userEscrows[free].push(eId);
        emit FreelancerAccepted(eId, free);
    }

    // ===== Admin & Emergency =====
    function whitelistToken(address t) external onlyOwner { _getLogicState().whitelistedTokens[t] = true; emit TokenWhitelisted(t); }
    function blacklistToken(address t) external onlyOwner { _getLogicState().whitelistedTokens[t] = false; emit TokenBlacklisted(t); }
    function authorizeArbiter(address a) external onlyOwner { _getLogicState().authorizedArbiters[a] = true; emit ArbiterAuthorized(a); }
    function revokeArbiter(address a) external onlyOwner { _getLogicState().authorizedArbiters[a] = false; emit ArbiterRevoked(a); }
    
    function withdrawFees(address t) external nonReentrant {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        require(msg.sender == s.feeCollector || msg.sender == owner(), "auth");
        uint256 amt = s.totalFeesByToken[t];
        require(amt > 0, "noFees");
        s.totalFeesByToken[t] = 0;
        _transferOut(t, msg.sender, amt);
        emit FeesWithdrawn(t, amt, msg.sender);
    }

    function emergencyWithdraw(address t, uint256 amt) external onlyOwner nonReentrant {
        OrbitWorkLib.emergencyWithdraw(_getLogicState(), t, amt, owner());
        emit EmergencyWithdrawn(t, amt, owner());
    }

    // ===== Self Protocol =====
    function verifyUserIdentity(address u) external override onlyOwner {
        OrbitWorkLib.verifyUserIdentity(_getLogicState(), u);
        emit UserVerified(u, block.timestamp);
    }
    function revokeUserVerification(address u) external override onlyOwner {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        s.selfVerifiedUsers[u] = false;
        s.verificationTimestamp[u] = 0;
    }

    // ===== Views =====
    function getEscrowSummary(uint256 eId) external view override returns (
        address dep, address ben, address[] memory arbs, EscrowStatus st, uint256 tot, uint256 paid,
        uint256 rem, address tok, uint256 dead, bool work, uint256 cre, uint256 count, bool open,
        string memory pT, string memory pD
    ) {
        return OrbitWorkLib.getEscrowSummary(_getLogicState(), eId);
    }
    function getMilestones(uint256 eId) external view override returns (Milestone[] memory) {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        uint256 c = s.escrows[eId].milestoneCount;
        Milestone[] memory l = new Milestone[](c);
        for (uint256 i = 0; i < c; i++) l[i] = s.milestones[eId][i];
        return l;
    }
    function getUserEscrows(address u) external view override returns (uint256[] memory) { return _getLogicState().userEscrows[u]; }
    function getReputation(address u) external view override returns (uint256) { return _getLogicState().reputation[u]; }
    function getCompletedEscrows(address u) external view override returns (uint256) { return _getLogicState().completedEscrows[u]; }
    function getWithdrawableFees(address t) external view override returns (uint256) { return _getLogicState().totalFeesByToken[t]; }
    function getApplicationCount(uint256 eId) external view override returns (uint256) { return _getLogicState().escrowApplications[eId].length; }
    function hasUserApplied(uint256 eId, address u) external view override returns (bool) { return _getLogicState().hasApplied[eId][u]; }
    function getApplicationsPage(uint256 eId, uint256 off, uint256 lim) external view override returns (Application[] memory) {
        Application[] storage all = _getLogicState().escrowApplications[eId];
        uint256 end = off + lim > all.length ? all.length : off + lim;
        Application[] memory r = new Application[](end - off);
        for (uint256 i = 0; i < r.length; i++) r[i] = all[off + i];
        return r;
    }

    // ===== Others =====
    function disputeMilestone(uint256 eId, uint256 idx, string calldata r) external override validEscrow(eId) onlyEscrowParticipant(eId) whenNotPaused {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        Milestone storage m = s.milestones[eId][idx];
        require(m.status == MilestoneStatus.Submitted, "state");
        m.status = MilestoneStatus.Disputed;
        m.disputedAt = block.timestamp; m.disputedBy = msg.sender; m.disputeReason = r;
        s.escrows[eId].status = EscrowStatus.Disputed;
        emit MilestoneDisputed(eId, idx, msg.sender, r, block.timestamp);
        emit EscrowUpdated(eId, EscrowStatus.Disputed, block.timestamp);
    }

    function resolveDispute(uint256 eId, uint256 idx, uint256 bAmt, string calldata resReason) external override validEscrow(eId) onlyArbiter(eId) whenNotPaused nonReentrant {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        EscrowData storage e = s.escrows[eId];
        require(e.status == EscrowStatus.Disputed, "dispute");
        uint256 refund = OrbitWorkLib.resolveDispute(s, eId, idx, bAmt);
        s.milestones[eId][idx].disputeReason = resReason;
        if (bAmt > 0) _transferOut(e.token, e.beneficiary, bAmt);
        if (refund > 0) _transferOut(e.token, e.depositor, refund);
        emit DisputeResolved(eId, idx, msg.sender, bAmt, refund, block.timestamp);
        emit EscrowUpdated(eId, EscrowStatus.InProgress, block.timestamp);
        if (e.status == EscrowStatus.Released) {
            emit EscrowCompleted(eId, e.beneficiary, e.paidAmount);
            emit EscrowUpdated(eId, EscrowStatus.Released, block.timestamp);
        }
    }

    function refundEscrow(uint256 eId) external override validEscrow(eId) onlyDepositor(eId) whenNotPaused nonReentrant {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        require(s.escrows[eId].status == EscrowStatus.Pending && !s.escrows[eId].workStarted && block.timestamp < s.escrows[eId].deadline, "refund");
        uint256 amt = OrbitWorkLib.refundEscrow(s, eId);
        _transferOut(s.escrows[eId].token, msg.sender, amt);
        emit FundsRefunded(eId, msg.sender, amt);
        emit EscrowUpdated(eId, EscrowStatus.Refunded, block.timestamp);
    }

    function emergencyRefundAfterDeadline(uint256 eId) external override validEscrow(eId) onlyDepositor(eId) whenNotPaused nonReentrant {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        EscrowData storage e = s.escrows[eId];
        require(block.timestamp > e.deadline + EMERGENCY_REFUND_DELAY, "delay");
        require(e.status != EscrowStatus.Released && e.status != EscrowStatus.Refunded, "status");
        uint256 amt = OrbitWorkLib.emergencyRefundAfterDeadline(s, eId);
        _transferOut(e.token, msg.sender, amt);
        emit EmergencyRefundExecuted(eId, msg.sender, amt);
        emit EscrowUpdated(eId, EscrowStatus.Expired, block.timestamp);
    }

    /**
     * @notice Client opens a dispute when the deadline has passed and the
     *         freelancer never submitted any milestone work.
     *         Sets the escrow status to Disputed so the admin/arbiter can
     *         quickly resolve it as a full refund without waiting 30 days.
     * @param eId The escrow ID
     */
    function raiseDeadlineDispute(uint256 eId)
        external
        validEscrow(eId)
        onlyDepositor(eId)
        whenNotPaused
    {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        EscrowData storage e = s.escrows[eId];
        require(block.timestamp > e.deadline, "deadline not passed");
        require(
            e.status == EscrowStatus.Pending || e.status == EscrowStatus.InProgress,
            "wrong status"
        );

        // Check that NO milestone has ever been submitted — if one was,
        // use the normal disputeMilestone() flow instead.
        bool anySubmitted = false;
        for (uint256 i = 0; i < e.milestoneCount; i++) {
            if (s.milestones[eId][i].status != MilestoneStatus.NotStarted) {
                anySubmitted = true;
                break;
            }
        }
        require(!anySubmitted, "use disputeMilestone(): work was submitted");

        // Mark first milestone as Disputed so resolveDispute() can act on it
        s.milestones[eId][0].status = MilestoneStatus.Disputed;
        s.milestones[eId][0].disputedAt = block.timestamp;
        s.milestones[eId][0].disputedBy = msg.sender;
        s.milestones[eId][0].disputeReason = "Deadline passed with no work submitted";

        e.status = EscrowStatus.Disputed;

        emit MilestoneDisputed(eId, 0, msg.sender, "Deadline passed with no work submitted", block.timestamp);
        emit EscrowUpdated(eId, EscrowStatus.Disputed, block.timestamp);
    }

    function extendDeadline(uint256 eId, uint256 ext) external override validEscrow(eId) onlyDepositor(eId) whenNotPaused {
        require(ext > 0 && ext <= 30 days, "ext");
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        EscrowData storage e = s.escrows[eId];
        require(e.status == EscrowStatus.InProgress || e.status == EscrowStatus.Pending, "status");
        e.deadline += ext; emit DeadlineExtended(eId, e.deadline);
    }

    function rateFreelancer(uint256 eId, uint256 r) external override validEscrow(eId) whenNotPaused nonReentrant {
        OrbitWorkLib.rateFreelancer(_getLogicState(), eId, r, msg.sender);
    }
    function getFreelancerRating(address f) external view override returns (uint256 a, uint256 t) {
        OrbitWorkLib.FreelancerRating storage fr = _getLogicState().freelancerRatings[f];
        return (fr.averageRating, fr.totalRatings);
    }
    function getEscrowRating(uint256 eId) external view override returns (address ra, address fr, uint256 r, uint256 t, bool ex) {
        OrbitWorkLib.EscrowRating storage er = _getLogicState().escrowRatings[eId];
        return (er.rater, er.freelancer, er.rating, er.ratedAt, er.exists);
    }
    function getBadgeTier(address f) external view override returns (uint256) {
        uint256 c = _getLogicState().completedEscrows[f];
        if (c >= 20) return 2; if (c >= 5) return 1; return 0;
    }

    function setEscrowHook(address h) external onlyOwner {
        require(h != address(0), "hook");
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        s.escrowHook = IEscrowHook(h);
        s.liquidEscrowEnabled = true;
    }
    function setReactiveCallbackSender(address s) external onlyOwner {
        OrbitWorkLib.EscrowState storage state = _getLogicState();
        state.reactiveCallbackSender = s;
        emit ReactiveCallbackSenderUpdated(s);
    }
    function pauseJobCreation() external onlyOwner { _getLogicState().jobCreationPaused = true; emit JobCreationPaused(); }
    function unpauseJobCreation() external onlyOwner { _getLogicState().jobCreationPaused = false; emit JobCreationUnpaused(); }

    /**
     * @notice Manually initialize an escrow in the hook (Admin ONLY)
     * Useful for fixing escrows created before hook was active or during migrations.
     */
    function fixEscrowInHook(uint256 eId) external onlyOwner {
        OrbitWorkLib.EscrowState storage s = _getLogicState();
        IOrbitWork.EscrowData storage e = s.escrows[eId];
        require(e.totalAmount > 0, "no escrow");
        
        IEscrowHook.PoolKey memory key = IEscrowHook.PoolKey({
            currency0: address(0),
            currency1: (e.token == address(0)) ? 0x8f22D60F408DBA32ba2D4123aD0aE6D3c0b1d28B : e.token,
            fee: 3000,
            tickSpacing: 60,
            hooks: address(s.escrowHook)
        });
        
        s.escrowPoolKeys[eId] = key;
        
        if (e.token != address(0)) {
            IERC20(e.token).approve(address(s.escrowHook), e.totalAmount + e.platformFee);
        }
        
        s.escrowHook.onEscrowCreated(eId, e.totalAmount + e.platformFee, key);
    }
}
