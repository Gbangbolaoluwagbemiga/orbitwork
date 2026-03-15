import { ethers } from "ethers";
import { CONTRACTS } from "./config";
import { ORBIT_WORK_ABI } from "./abis";

export class ContractService {
  private provider: ethers.Provider;
  private contract: ethers.Contract;

  constructor(contractAddress?: string) {
    const rpcUrl = "https://sepolia.unichain.org";
    this.provider = new ethers.JsonRpcProvider(rpcUrl);
    this.contract = new ethers.Contract(
      contractAddress || CONTRACTS.ORBIT_WORK_ESCROW,
      ORBIT_WORK_ABI,
      this.provider
    );
  }

  async getEscrow(escrowId: number) {
    try {
      const summary = await this.contract.getEscrowSummary(escrowId);
      // summary: [creator, beneficiary, arbiters, status, amount, releasedAt, ...]
      return {
        id: escrowId,
        creator: summary[0],
        beneficiary: summary[1],
        status: Number(summary[3]),
        amount: summary[4].toString(),
        // Add more fields as per ABI
        projectDescription: summary[13] || "",
        projectTitle: summary[14] || ""
      };
    } catch (error) {
      console.error("Error getting escrow:", error);
      return null;
    }
  }

  async getApplications(escrowId: number) {
    // This depends on the contract having an applications mapping
    // If not, we might need to fetch events
    return [];
  }

  async submitRating(escrowId: number, rating: number, review: string, signerAddress?: string) {
    // Implementation for submitting ratings
    console.log("Submitting rating:", { escrowId, rating, review });
  }

  async selectFreelancer(escrowId: number, freelancer: string, signerAddress: string) {
    // Implementation for selecting freelancer
    console.log("Selecting freelancer:", { escrowId, freelancer });
  }
  
  // Singleton instance
  static getInstance() {
    return new ContractService();
  }
}

export const contractService = ContractService.getInstance();
