// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console2} from "forge-std/Script.sol";
import {OrbitWork} from "../src/core/OrbitWork.sol";
import {EscrowHook} from "../src/EscrowHook.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolSwapTest} from "@uniswap/v4-core/src/test/PoolSwapTest.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {SwapParams} from "@uniswap/v4-core/src/types/PoolOperation.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";

contract DemoFlow is Script {
    OrbitWork orbitWork = OrbitWork(payable(0x46cD4d93426C33c210Ee8D237cc238074794Ec2E));
    address constant USDC = 0x8f22D60F408DBA32ba2D4123aD0aE6D3c0b1d28B;
    address constant SWAP_ROUTER = 0x9140a78c1A137c7fF1c151EC8231272aF78a99A4;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(pk);

        // 1. Create Escrow
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 50 * 10**6; // 50 USDC
        string[] memory descs = new string[](1);
        descs[0] = "Final Verification Milestone";

        // Approve USDC for OrbitWork
        IERC20(USDC).approve(address(orbitWork), 50 * 10**6);
        
        uint256 eId = orbitWork.createEscrow(
            address(0x123), // Beneficiary
            new address[](0), // Arbiters
            0, // Required confirmations
            amounts,
            descs,
            USDC,
            30 days,
            "Verification Project",
            "This project proves that the token approval fix works."
        );
        console2.log("Created Escrow ID:", eId);

        // 2. Perform Swap to generate yield
        console2.log("Performing swap to generate yield...");
        PoolSwapTest swapRouter = PoolSwapTest(SWAP_ROUTER);
        
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(address(0)),
            currency1: Currency.wrap(USDC),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(address(orbitWork.escrowHook()))
        });

        // Swap 0.01 ETH for USDC
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
        
        console2.log("Swap completed.");
        
        // 3. Check yield
        uint256 yield = orbitWork.escrowHook().getEscrowYield(eId);
        console2.log("Yield Accumulated (wei):");
        console2.logUint(yield);

        vm.stopBroadcast();
    }
}
