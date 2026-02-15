// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {EscrowHook} from "../src/EscrowHook.sol";
import {OrbitWork} from "../src/core/OrbitWork.sol";

contract UpgradeHook is Script {
    IPoolManager constant POOL_MANAGER = IPoolManager(0x00B036B58a818B1BC34d502D3fE730Db729e62AC);
    address constant ORBIT_WORK = 0xEe8a174c6fabDEb52a5d75e8e3F951EFbC667fDB;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy new Hook (Version 6)
        EscrowHook newHook = new EscrowHook(POOL_MANAGER, ORBIT_WORK);
        console.log("New EscrowHook deployed at:", address(newHook));

        // Link to OrbitWork
        OrbitWork(payable(ORBIT_WORK)).setEscrowHook(address(newHook));
        console.log("Linked new hook to OrbitWork");

        vm.stopBroadcast();
    }
}
