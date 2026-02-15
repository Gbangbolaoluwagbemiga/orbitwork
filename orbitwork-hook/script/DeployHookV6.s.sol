// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {EscrowHook} from "../src/EscrowHook.sol";
import {OrbitWork} from "../src/core/OrbitWork.sol";

contract DeployHookV6 is Script {
    IPoolManager constant POOL_MANAGER = IPoolManager(0x00B036B58a818B1BC34d502D3fE730Db729e62AC);
    address constant ORBIT_WORK = 0xEe8a174c6fabDEb52a5d75e8e3F951EFbC667fDB;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);

        // Mine salt for flags: BeforeAdd, BeforeRemove, AfterSwap
        uint160 flags = uint160(
            Hooks.BEFORE_ADD_LIQUIDITY_FLAG | 
            Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG | 
            Hooks.AFTER_SWAP_FLAG
        );
        
        console.log("Mining hook with flags:", flags);

        bytes memory creationCode = type(EscrowHook).creationCode;
        bytes memory constructorArgs = abi.encode(POOL_MANAGER, ORBIT_WORK);

        address CREATE2_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
        (address hookAddress, bytes32 salt) = HookMiner.find(
            CREATE2_DEPLOYER, 
            flags, 
            creationCode, 
            constructorArgs
        );
        
        console.log("Mined Hook Address:", hookAddress);
        console.log("Mined Salt:", vm.toString(salt));

        // Deploy
        EscrowHook hook = new EscrowHook{salt: salt}(POOL_MANAGER, ORBIT_WORK);
        require(address(hook) == hookAddress, "Hook address mismatch");

        // Link
        OrbitWork(payable(ORBIT_WORK)).setEscrowHook(address(hook));
        console.log("Linked V6 Hook to OrbitWork");

        vm.stopBroadcast();
    }
}
