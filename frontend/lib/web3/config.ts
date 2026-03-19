// Unichain Sepolia - Primary network for Uniswap v4 Hooks
export const UNICHAIN_SEPOLIA = {
  chainId: "0x515", // 1301 in hex
  chainName: "Unichain Sepolia",
  nativeCurrency: {
    name: "ETH",
    symbol: "ETH",
    decimals: 18,
  },
  rpcUrls: ["https://sepolia.unichain.org"],
  blockExplorerUrls: ["https://sepolia.uniscan.xyz"],
};

// Default network export for the app
export const DEFAULT_NETWORK = UNICHAIN_SEPOLIA;

export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

// Defaults for Unichain Sepolia
const ORBIT_WORK_ADDR =
  process.env.NEXT_PUBLIC_ORBIT_WORK_ESCROW ||
  "0x46cd4d93426c33c210ee8d237cc238074794ec2e";

const RATINGS_ADDR =
  process.env.NEXT_PUBLIC_ORBITWORK_RATINGS ||
  "0xa29de3678ea79c7031fc1c5c9c0547411637bd9f";

const UNICHAIN_SEPOLIA_CONFIG = {
  RPC_URL: "https://sepolia.unichain.org",
  CHAIN_ID: 1301,
  // Definitive addresses from latest deployment (Fixed insolvency and Uniswap robustness)
  HOOK_ADDRESS: "0x637696BE3514c4d65Ee6558e491eaa49EfbC4a40",
  USDC_ADDRESS: "0x8f22D60F408DBA32ba2D4123aD0aE6D3c0b1d28B",
  MOCK_ERC20: "0x8f22D60F408DBA32ba2D4123aD0aE6D3c0b1d28B",
  POOL_MANAGER: "0x00B036B58a818B1BC34d502D3fE730Db729e62AC",
};

export const CONTRACTS = {
  // Unichain Sepolia
  ORBIT_WORK_ESCROW_UNICHAIN: "0x62C4dd1414AB677B5766264Fa5C263A13D31d547",
  ORBITWORK_RATINGS: ORBIT_WORK_ADDR,
  ESCROW_HOOK: UNICHAIN_SEPOLIA_CONFIG.HOOK_ADDRESS,

  // Default contracts (used by frontend)
  ORBIT_WORK_ESCROW: "0x62C4dd1414AB677B5766264Fa5C263A13D31d547",
  USDC: UNICHAIN_SEPOLIA_CONFIG.USDC_ADDRESS,
  MOCK_ERC20: UNICHAIN_SEPOLIA_CONFIG.MOCK_ERC20,
};
