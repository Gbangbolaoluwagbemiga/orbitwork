// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/reactive/OrbitworkReactive.sol";

contract DeployOrbitworkReactive is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);

        // Address of OrbitWork on Unichain Sepolia 
        address orbitworkAddress = vm.envOr("ORBITWORK_ADDRESS", address(0x322fF82E9857d22d8d2CDBA11Cf524349Fb52A3e));
        
        // Reactive Network Subscription Service Address (Kopli Testnet)
        address subscriptionService = 0x0000000000000000000000000000000000000000; // Mock or standard address

        OrbitworkReactive reactiveContract = new OrbitworkReactive(orbitworkAddress, subscriptionService);

        console.log("OrbitworkReactive deployed to:", address(reactiveContract));
        console.log("Listening to target contract:", orbitworkAddress);

        vm.stopBroadcast();
    }
}
