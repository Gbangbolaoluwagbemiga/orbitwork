// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title OrbitworkReactive
 * @dev Deployed on Reactive Network (Lasna/Kopli testnet).
 * Listens for MilestoneSubmitted events on Unichain Sepolia and triggers a callback
 * to the OrbitWork contract to auto-approve the milestone if not disputed.
 */
contract OrbitworkReactive {
    uint256 private constant SEPOLIA_CHAIN_ID = 11155111; // Origin chain (can be Unichain testnet)
    uint256 private constant CALLBACK_GAS_LIMIT = 500000;
    
    // Address of the OrbitWork contract on the origin chain
    address public immutable targetContract;
    
    // The topic0 of MilestoneSubmitted(uint256,uint256,address,string,uint256)
    // We can calculate it or just subscribe to the address
    bytes32 public constant MILESTONE_SUBMITTED_TOPIC = 0xb73b6441e88beab02b54bc9f91a5ec3a040b2e3da40d8cd5f756614459f21f1d; // Replace with actual topic later

    // Represents the subscription service on Reactive Network
    address public immutable subscriptionService;

    constructor(address _targetContract, address _subscriptionService) {
        targetContract = _targetContract;
        subscriptionService = _subscriptionService;
        
        // Setup subscription
        _subscribeToMilestoneEvents();
    }

    function _subscribeToMilestoneEvents() internal {
        // Pseudo-code for reactive network subscription
        // Normally calls something like:
        // ISubscriptionService(subscriptionService).subscribe(
        //     SEPOLIA_CHAIN_ID,
        //     targetContract,
        //     MILESTONE_SUBMITTED_TOPIC
        // );
    }

    // This function is invoked by the Reactive Network nodes when an event is detected
    function react(
        uint256 chainId,
        address _contract,
        uint256 topic0,
        uint256 topic1,
        uint256 topic2,
        uint256 topic3,
        bytes calldata data,
        uint256 blockNumber,
        uint256 opCode
    ) external {
        // Ensure this is from our target
        if (_contract != targetContract) return;

        // Parse event parameters
        // For MilestoneSubmitted, topic1 = escrowId, topic2 = milestoneIndex
        uint256 escrowId = topic1;
        uint256 milestoneIndex = topic2;

        // Emit callback transaction to target chain
        bytes memory payload = abi.encodeWithSignature(
            "autoApproveMilestone(uint256,uint256)", 
            escrowId, 
            milestoneIndex
        );

        // In a real reactive contract, this emits a callback event that nodes pick up
        // emit Callback(SEPOLIA_CHAIN_ID, targetContract, CALLBACK_GAS_LIMIT, payload);
    }
}
