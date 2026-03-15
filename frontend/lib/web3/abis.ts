export const ORBIT_WORK_ABI = [
  "function createEscrow(address,address[],uint8,uint256[],string[],address,uint256,string,string) external returns (uint256)",
  "function createEscrowNative(address,address[],uint8,uint256[],string[],uint256,string,string) external payable returns (uint256)",
  "function startWork(uint256) external",
  "function submitMilestone(uint256,uint256,string) external",
  "function approveMilestone(uint256,uint256,uint256,bytes) external",
  "function rejectMilestone(uint256,uint256,string) external",
  "function resubmitMilestone(uint256,uint256,string) external",
  "function disputeMilestone(uint256,uint256,string) external",
  "function resolveDispute(uint256,uint256,uint256,string) external",
  "function getEscrowSummary(uint256) external view returns (address,address,address[],uint8,uint256,uint256,uint256,address,uint256,bool,uint256,uint256,bool,string,string)",
  "function getReputation(address) external view returns (uint256)",
  "function getCompletedEscrows(address) external view returns (uint256)",
  "function reputation(address) external view returns (uint256)",
  "function completedEscrows(address) external view returns (uint256)",
  "function rateFreelancer(uint256,uint256) external",
  "function getFreelancerRating(address) external view returns (uint256,uint256)",
  "function getEscrowRating(uint256) external view returns (address,address,uint256,uint256,bool)",
  "function getBadgeTier(address) external view returns (uint256)",
  "event EscrowCreated(uint256 indexed,address indexed,address indexed,address[],uint256,uint256,address,uint256,bool)",
  "event MilestoneSubmitted(uint256 indexed,uint256 indexed,address indexed,string,uint256)",
  "event MilestoneApproved(uint256 indexed,uint256 indexed,address indexed,uint256,uint256)"
];

export const ERC20_ABI = [
  "function approve(address,uint256) external returns (bool)",
  "function balanceof(address) external view returns (uint256)",
  "function allowance(address,address) external view returns (uint256)"
];

export const ESCROW_HOOK_ABI = [
  "function getEscrowYield(uint256) external view returns (uint256)",
  "function claimCommission() external",
  "function distributeYield(uint256) external"
];
