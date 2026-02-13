// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/core/modules/OrbitworkRatings.sol";

contract DeployRatings is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        // OrbitWork address from previous deployment
        address orbitWork = vm.envAddress("ESCROW_CORE"); 

        vm.startBroadcast(deployerPrivateKey);

        OrbitworkRatings ratings = new OrbitworkRatings(orbitWork);
        console.log("OrbitworkRatings deployed at:", address(ratings));

        vm.stopBroadcast();
    }
}
