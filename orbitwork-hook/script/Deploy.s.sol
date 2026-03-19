// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {OrbitWork} from "../src/core/OrbitWork.sol";
import {EscrowHook} from "../src/EscrowHook.sol";

/**
 * @title Deploy
 * @notice 
 *  1. Deploy OrbitWork with 0% Platform Fee
 *  2. Mine CREATE2 salt for EscrowHook (pointing to new OrbitWork)
 *  3. Deploy EscrowHook
 *  4. Link Hook to OrbitWork
 *  5. Whitelist MockUSDC
 *  6. Initialize Uniswap v4 Pool (ETH/MockUSDC)
 */
contract Deploy is Script {
    // Unichain Sepolia Addresses
    IPoolManager constant POOL_MANAGER = IPoolManager(0x00B036B58a818B1BC34d502D3fE730Db729e62AC);
    address constant MOCK_USDC = 0x8f22D60F408DBA32ba2D4123aD0aE6D3c0b1d28B;
    address constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;

    // Hook Flags: beforeAddLiquidity (0x800) | beforeRemoveLiquidity (0x200) | afterSwap (0x40) = 0x0A40
    uint160 constant FLAGS = uint160(
        Hooks.BEFORE_ADD_LIQUIDITY_FLAG |
        Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG |
        Hooks.AFTER_SWAP_FLAG
    );

    // sqrtPriceX96 ≈ 1 ETH = 2000 USDC
    uint160 constant SQRT_PRICE_X96 = 3961408125713216879677197516800;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);
        console.log("Deploying V3 from:", deployer);

        vm.startBroadcast(pk);

        // --- 1. Deploy OrbitWork (0% Fee) ---
        // Args: _orbitworkToken, _feeCollector, _platformFeeBP
        OrbitWork orbitWork = new OrbitWork(address(0), deployer, 0);
        console.log("OrbitWork deployed at:", address(orbitWork));

        vm.stopBroadcast();

        // --- 2. Mine Hook Salt ---
        bytes memory constructorArgs = abi.encode(address(POOL_MANAGER), address(orbitWork));
        console.log("Mining hook address for OrbitWork...");
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_FACTORY,
            FLAGS,
            type(EscrowHook).creationCode,
            constructorArgs
        );
        console.log("Mined hook address:", hookAddress);
        console.log("Salt:", vm.toString(salt));

        vm.startBroadcast(pk);

        // --- 3. Deploy EscrowHook ---
        EscrowHook hook = new EscrowHook{salt: salt}(POOL_MANAGER, address(orbitWork));
        require(address(hook) == hookAddress, "Hook address mismatch-remine");
        console.log("EscrowHook deployed at:", address(hook));

        // --- 4. Link Hook to OrbitWork ---
        orbitWork.setEscrowHook(address(hook));
        console.log("Hook linked to OrbitWork");

        // --- 5. Whitelist MockUSDC ---
        orbitWork.whitelistToken(MOCK_USDC);
        console.log("MockUSDC whitelisted");

        // --- 6. Initialize Pool ---
        (Currency c0, Currency c1) = address(0) < MOCK_USDC
            ? (Currency.wrap(address(0)), Currency.wrap(MOCK_USDC))
            : (Currency.wrap(MOCK_USDC), Currency.wrap(address(0)));

        PoolKey memory key = PoolKey({
            currency0: c0,
            currency1: c1,
            fee: 3000,
            tickSpacing: 60,
            hooks: hook
        });

        int24 tick = POOL_MANAGER.initialize(key, SQRT_PRICE_X96);
        console.log("Uniswap v4 Pool initialized at tick:", vm.toString(tick));

        vm.stopBroadcast();

        console.log("==========================================");
        console.log("DEPLOYMENT SUCCESSFUL");
        console.log("OrbitWork:", address(orbitWork));
        console.log("EscrowHook:", address(hook));
        console.log("==========================================");
    }
}
