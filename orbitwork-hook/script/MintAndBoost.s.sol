// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

interface IMockERC20 is IERC20 {
    function mint(address to, uint256 amount) external;
}

/**
 * @title MintAndBoost
 * @notice HIGH POWER version for demo:
 *         1. Mints 1M MockUSDC.
 *         2. Performs 10 swaps of 0.01 ETH each (0.1 ETH total).
 */
contract MintAndBoost is Script {
    // Unichain Sepolia Addresses
    address constant SWAP_ROUTER = 0x9140a78c1A137c7fF1c151EC8231272aF78a99A4;
    address constant USDC = 0x8f22D60F408DBA32ba2D4123aD0aE6D3c0b1d28B;
    address constant ESCROW_HOOK = 0x637696BE3514c4d65Ee6558e491eaa49EfbC4a40;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(pk);

        vm.startBroadcast(pk);

        // --- 1. Mint USDC ---
        console2.log("Minting 1,000,000 MockUSDC...");
        IMockERC20(USDC).mint(user, 1_000_000 * 10**6);

        // --- 2. Yield Boost (HIGH POWER) ---
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(USDC),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(ESCROW_HOOK)
        });

        PoolSwapTest swapRouter = PoolSwapTest(SWAP_ROUTER);
        
        console2.log("Generating high-intensity yield boost...");
        
        // Loop 5 times with 0.01 ETH each (Total 0.05 ETH + Gas)
        for (uint i = 0; i < 5; i++) {
            swapRouter.swap{value: 0.01 ether}(
                key,
                SwapParams({
                    zeroForOne: true,
                    amountSpecified: -0.01 ether,
                    sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
                }),
                PoolSwapTest.TestSettings({
                    takeClaims: false,
                    settleUsingBurn: false
                }),
                ""
            );
            console2.log("Swap", i+1, "of 0.01 ETH successful.");
        }

        console2.log("==========================================");
        console2.log("HIGH-POWER BOOST SUCCESSFUL");
        console2.log("Yield should have jumped significantly.");
        console2.log("==========================================");

        vm.stopBroadcast();
    }
}
