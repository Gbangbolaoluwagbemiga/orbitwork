// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title IEscrowHook
 * @notice Interface for the Uniswap v4 hook that handles liquid escrows.
 */
interface IEscrowHook {
    // We use address/uint24/int24/int256 instead of full types to avoid importing v4-core 
    // into the Hardhat project directly if dependencies are missing there.
    // However, if we can, we should use the structs.
    
    struct PoolKey {
        address currency0;
        address currency1;
        uint24 fee;
        int24 tickSpacing;
        address hooks;
    }

    struct ModifyLiquidityParams {
        int24 tickLower;
        int24 tickUpper;
        int256 liquidityDelta;
        bytes32 salt;
    }

    function addLiquidity(uint256 escrowId, PoolKey calldata key, ModifyLiquidityParams calldata params) external;
    function removeLiquidity(PoolKey calldata key, ModifyLiquidityParams calldata params) external;
    
    // Productive Escrow Functions
    function onEscrowCreated(uint256 escrowId, uint256 totalAmount, PoolKey calldata key) 
        external returns (uint256 lpAmount, uint256 reserveAmount);
    
    function onMilestoneApproved(uint256 escrowId, uint256 milestoneAmount, address freelancer) 
        external returns (uint256 payment, uint256 platformYield);
    
    function getEscrowYield(uint256 escrowId) external view returns (uint256);
}
