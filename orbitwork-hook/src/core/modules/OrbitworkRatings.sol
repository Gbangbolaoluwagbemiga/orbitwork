// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../interfaces/ISecureFlow.sol";

contract OrbitworkRatings {
    ISecureFlow public secureFlow;

    struct Rating {
        uint256 escrowId;
        address rater;
        address rated;
        uint8 score; // 1-5
        string comment;
        uint256 timestamp;
    }

    // rated => Rating[]
    mapping(address => Rating[]) public ratings;
    // escrowId => rater => bool
    mapping(uint256 => mapping(address => bool)) public hasRated;

    event RatingSubmitted(address indexed rater, address indexed rated, uint256 escrowId, uint8 score);

    constructor(address _secureFlow) {
        secureFlow = ISecureFlow(_secureFlow);
    }

    function rateTransaction(uint256 escrowId, uint8 score, string calldata comment) external {
        require(score >= 1 && score <= 5, "Invalid score");
        require(!hasRated[escrowId][msg.sender], "Already rated");

        // Verify escrow status via SecureFlow
        (
            address depositor,
            address beneficiary,
            , // arbiters
            ISecureFlow.EscrowStatus status,
            , // totalAmount
            , // paidAmount
            , // remaining
            , // token
            , // deadline
            , // workStarted
            , // createdAt
            , // milestoneCount
            , // isOpenJob
            , // projectTitle
            // projectDescription
        ) = secureFlow.getEscrowSummary(escrowId);

        require(
            status == ISecureFlow.EscrowStatus.Released || 
            status == ISecureFlow.EscrowStatus.Refunded, 
            "Escrow not completed"
        );

        address ratedUser;
        if (msg.sender == depositor) {
            ratedUser = beneficiary;
        } else if (msg.sender == beneficiary) {
            ratedUser = depositor;
        } else {
            revert("Not a party to this escrow");
        }

        require(ratedUser != address(0), "Invalid rated user");
        
        Rating memory newRating = Rating({
            escrowId: escrowId,
            rater: msg.sender,
            rated: ratedUser,
            score: score,
            comment: comment,
            timestamp: block.timestamp
        });

        ratings[ratedUser].push(newRating);
        hasRated[escrowId][msg.sender] = true;

        emit RatingSubmitted(msg.sender, ratedUser, escrowId, score);
    }
    
    function getRatingCount(address user) external view returns (uint256) {
        return ratings[user].length;
    }

    function getAverageRating(address user) external view returns (uint256) {
        uint256 count = ratings[user].length;
        if (count == 0) return 0;
        
        uint256 total = 0;
        for (uint256 i = 0; i < count; i++) {
            total += ratings[user][i].score;
        }
        // Return average * 100 for precision
        return (total * 100) / count;
    }

    function getRatings(address user) external view returns (Rating[] memory) {
        return ratings[user];
    }
}
