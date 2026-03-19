// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {PoolId, PoolIdLibrary} from "@uniswap/v4-core/src/types/PoolId.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IEscrowHook} from "../src/core/interfaces/IEscrowHook.sol";

/**
 * @title SwapSimulation
 * @notice Script to perform a swap on Unichain Sepolia to generate yield for OrbitWork escrows.
 */
contract SwapScript is Script {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;

    // Unichain Sepolia Addresses
    address constant SWAP_ROUTER = 0x9140a78c1A137c7fF1c151EC8231272aF78a99A4; 
    address constant USDC = 0x8f22D60F408DBA32ba2D4123aD0aE6D3c0b1d28B;
    address constant ESCROW_HOOK = 0x637696BE3514c4d65Ee6558e491eaa49EfbC4a40;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        // 0. Check yield before for Escrow ID 2
        uint256 yieldBefore = IEscrowHook(ESCROW_HOOK).getEscrowYield(2);
        console2.log("Yield Before Swap (wei):", yieldBefore);

        // 1. Define PoolKey (ETH / USDC 0.3%)
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(USDC),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(ESCROW_HOOK)
        });

        console2.log("Performing swap to generate yield for Escrow ID 2...");
        PoolSwapTest swapRouter = PoolSwapTest(SWAP_ROUTER);

        // Swap 0.005 ETH for USDC
        swapRouter.swap{value: 0.005 ether}(
            key,
            SwapParams({
                zeroForOne: true,
                amountSpecified: -0.005 ether,
                sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
            }),
            PoolSwapTest.TestSettings({
                takeClaims: false,
                settleUsingBurn: false
            }),
            ""
        );

        console2.log("Swap completed.");

        // 2. Check yield after
        uint256 yieldAfter = IEscrowHook(ESCROW_HOOK).getEscrowYield(2);
        console2.log("Yield After Swap (wei):", yieldAfter);
        
        if(yieldAfter > yieldBefore) {
            console2.log("SUCCESS: Yield increased by:", yieldAfter - yieldBefore);
            console2.log("Check your dashboard now!");
        } else {
            console2.log("WARNING: Yield did not increase. Ensure escrow is in range.");
        }

        vm.stopBroadcast();
    }
}
