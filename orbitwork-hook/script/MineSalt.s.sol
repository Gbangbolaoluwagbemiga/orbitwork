// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {EscrowHook} from "../src/EscrowHook.sol";

contract MineSaltScript is Script {

    IPoolManager constant POOL_MANAGER = IPoolManager(0x00B036B58a818B1BC34d502D3fE730Db729e62AC);
    address constant ORBIT_WORK = 0xEe8a174c6fabDEb52a5d75e8e3F951EFbC667fDB; // Deployed on Sepolia

    function run() external {
        // Target: Low Bit flags (0xA40 = 2624)
        uint160 flags = 2624;
        uint160 mask = (1 << 14) - 1;

        bytes memory constructorArgs = abi.encode(POOL_MANAGER, ORBIT_WORK);
        bytes memory initCode = abi.encodePacked(type(EscrowHook).creationCode, constructorArgs);
        bytes32 initCodeHash = keccak256(initCode);
        
        address hookAddress;
        bytes32 salt;
        
        console.log("Mining locally for 0xA40...");
        
        // 1M iterations locally is fast
        for (uint256 i = 0; i < 1000000; i++) {
            salt = bytes32(i);
            hookAddress = vm.computeCreate2Address(salt, initCodeHash, CREATE2_FACTORY);
            
            if ((uint160(hookAddress) & mask) == flags) {
                console.log("Found Salt:", vm.toString(salt));
                console.log("Found Address:", hookAddress);
                return;
            }
        }
        console.log("Failed to mine salt in 1M iterations");
    }
}
