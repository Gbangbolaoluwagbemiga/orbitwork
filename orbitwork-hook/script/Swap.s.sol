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

/**
 * @title SwapSimulation
 * @notice Script to perform a swap on Unichain Sepolia to generate yield for OrbitWork escrows.
 * For judges to see "Yield Earned" increasing in real-time.
 */
contract SwapScript is Script {
    using CurrencyLibrary for Currency;
    using PoolIdLibrary for PoolKey;

    // Unichain Sepolia Addresses
    address constant POOL_MANAGER = 0x00B036B58a818B1BC34d502D3fE730Db729e62AC;
    address constant SWAP_ROUTER = 0x9140a78c1A137c7fF1c151EC8231272aF78a99A4; 
    address constant USDC = 0x8f22D60F408DBA32ba2D4123aD0aE6D3c0b1d28B;
    address constant ESCROW_HOOK = 0xC6721B7fad95Ae93e3c2deD00908a88299740a40;

    function run() external {
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0));
        if (deployerPrivateKey == 0) {
            console2.log("Error: PRIVATE_KEY not found in .env");
            return;
        }

        vm.startBroadcast(deployerPrivateKey);

        // Define PoolKey (ETH / USDC 0.3%)
        PoolKey memory key = PoolKey({
            currency0: CurrencyLibrary.ADDRESS_ZERO, // Native ETH
            currency1: Currency.wrap(USDC),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(ESCROW_HOOK) // Hook address
        });

        console2.log("Generating yield by swapping ETH for USDC...");
        
        // We use PoolSwapTest helper to perform the swap
        // Usually deployed at a known address on testnet
        PoolSwapTest swapRouter = PoolSwapTest(SWAP_ROUTER);

        // Swap Params: 
        // ZeroForOne = true (ETH -> USDC)
        // amountSpecified = -0.1 ether (Exact input)
        // sqrtPriceLimitX96 = min if selling ETH
        
        SwapParams memory params = SwapParams({
            zeroForOne: true,
            amountSpecified: -0.01 ether, 
            sqrtPriceLimitX96: TickMath.MIN_SQRT_PRICE + 1
        });

        PoolSwapTest.TestSettings memory settings = PoolSwapTest.TestSettings({
            takeClaims: false,
            settleUsingBurn: false
        });

        // Execute Swap
        try swapRouter.swap{value: 0.01 ether}(key, params, settings, "") returns (BalanceDelta delta) {
            console2.log("Swap successful!");
            console2.log("Delta0 (ETH):");
            console2.logInt(int256(delta.amount0()));
            console2.log("Delta1 (USDC):");
            console2.logInt(int256(delta.amount1()));
            console2.log("-----------------------------------------");
            console2.log("Check the Dashboard now! Yield should have increased.");
        } catch Error(string memory reason) {
            console2.log("Swap failed:", reason);
            console2.log("Ensure you have at least 0.11 ETH in your wallet.");
        }

        vm.stopBroadcast();
    }
}
