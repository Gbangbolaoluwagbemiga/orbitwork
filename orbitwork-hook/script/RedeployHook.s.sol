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
 * @title RedeployHook
 * @notice Redeploys ONLY the EscrowHook and links it to the EXISTING OrbitWork contract.
 */
contract RedeployHook is Script {
    // Unichain Sepolia Addresses
    IPoolManager constant POOL_MANAGER = IPoolManager(0x00B036B58a818B1BC34d502D3fE730Db729e62AC);
    address constant MOCK_USDC = 0x8f22D60F408DBA32ba2D4123aD0aE6D3c0b1d28B;
    address constant CREATE2_FACTORY = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    
    // THE EXISTING ORBITWORK ADDRESS
    address constant EXISTING_ORBITWORK = 0x62C4dd1414AB677B5766264Fa5C263A13D31d547;

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
        console.log("Redeploying Hook from:", deployer);
        console.log("Target Orbitwork:", EXISTING_ORBITWORK);

        // --- 1. Mine Hook Salt ---
        bytes memory constructorArgs = abi.encode(address(POOL_MANAGER), EXISTING_ORBITWORK);
        console.log("Mining hook address for existing OrbitWork...");
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_FACTORY,
            FLAGS,
            type(EscrowHook).creationCode,
            constructorArgs
        );
        console.log("Mined hook address:", hookAddress);
        console.log("Salt:", vm.toString(salt));

        vm.startBroadcast(pk);

        // --- 2. Deploy EscrowHook ---
        EscrowHook hook = new EscrowHook{salt: salt}(POOL_MANAGER, EXISTING_ORBITWORK);
        require(address(hook) == hookAddress, "Hook address mismatch");
        console.log("EscrowHook deployed at:", address(hook));

        // --- 3. Link Hook to OrbitWork ---
        OrbitWork(payable(EXISTING_ORBITWORK)).setEscrowHook(address(hook));
        console.log("Hook linked to OrbitWork");

        // --- 4. Initialize Pool (with new hook) ---
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

        // Use try-catch for Pool initialization as it might already be initialized for this hook (if reused)
        try POOL_MANAGER.initialize(key, SQRT_PRICE_X96) returns (int24 tick) {
            console.log("Uniswap v4 Pool initialized at tick:", vm.toString(tick));
        } catch {
            console.log("Pool already initialized or failed");
        }

        vm.stopBroadcast();

        console.log("==========================================");
        console.log("REDEPLOYMENT SUCCESSFUL");
        console.log("OrbitWork:", EXISTING_ORBITWORK);
        console.log("New EscrowHook:", address(hook));
        console.log("==========================================");
    }
}
