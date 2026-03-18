// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";

interface IOrbitWork {
    function getUserEscrows(address u) external view returns (uint256[] memory);
    function getEscrowSummary(uint256 eId) external view returns (
        address dep, address ben, address[] memory arbs, uint8 st, uint256 tot, uint256 paid,
        uint256 rem, address tok, uint256 dead, bool work, uint256 cre, uint256 count, bool open,
        string memory pT, string memory pD
    );
    function extendDeadline(uint256 eId, uint256 ext) external;
    function refundEscrow(uint256 eId) external;
}

contract ClearJobs is Script {
    address constant ORBIT_WORK = 0xEe8a174c6fabDEb52a5d75e8e3F951EFbC667fDB;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(pk);
        IOrbitWork orbitWork = IOrbitWork(ORBIT_WORK);

        console.log("Clearing jobs for:", user);
        
        uint256[] memory myEscrows = orbitWork.getUserEscrows(user);
        console.log("Total total escrows ever associated:", myEscrows.length);

        vm.startBroadcast(pk);

        uint256 cleared = 0;
        for (uint i = 0; i < myEscrows.length; i++) {
            uint256 eId = myEscrows[i];
            
            (address dep, , , uint8 st, , , , , uint256 dead, bool work, , , , , ) = orbitWork.getEscrowSummary(eId);
            
            // Only the depositor can claim refunds. 
            // Status: 0 = Pending.
            if (dep == user && st == 0 && !work) {
                if (block.timestamp > dead) {
                    console.log("Extending deadline for escrow:", eId);
                    // Extend by 30 days to make it active again
                    orbitWork.extendDeadline(eId, 30 days);
                }
                
                console.log("Refunding escrow:", eId);
                orbitWork.refundEscrow(eId);
                cleared++;
            }
        }

        vm.stopBroadcast();
        console.log("Successfully cleared", cleared, "jobs.");
    }
}
