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
  "0x2aA6Dbc1Ac1AD4eE06b84fcc107DE18329BbcdfE";

const RATINGS_ADDR =
  process.env.NEXT_PUBLIC_ORBITWORK_RATINGS ||
  "0xa29de3678ea79c7031fc1c5c9c0547411637bd9f";

const UNICHAIN_SEPOLIA_CONFIG = {
  RPC_URL: "https://sepolia.unichain.org",
  CHAIN_ID: 1301,
  // Updated addresses from latest deployment (Execution 4)
  HOOK_ADDRESS: "0x99D6b6F5b42b0220EB265026828c79d47e774a40",
  USDC_ADDRESS: "0xA657eCf4120a91FFB6CD67168C98133BcB7a6098",
  MOCK_ERC20: "0xA657eCf4120a91FFB6CD67168C98133BcB7a6098",
  POOL_MANAGER: "0x00B036B58a818B1BC34d502D3fE730Db729e62AC",
};

export const CONTRACTS = {
  // Unichain Sepolia
  ORBIT_WORK_ESCROW_UNICHAIN: "0x2aA6Dbc1Ac1AD4eE06b84fcc107DE18329BbcdfE",
  ORBITWORK_RATINGS: RATINGS_ADDR,
  ESCROW_HOOK: UNICHAIN_SEPOLIA_CONFIG.HOOK_ADDRESS,

  // Default contracts (used by frontend)
  ORBIT_WORK_ESCROW: "0x2aA6Dbc1Ac1AD4eE06b84fcc107DE18329BbcdfE",
  USDC: UNICHAIN_SEPOLIA_CONFIG.USDC_ADDRESS,
  MOCK_ERC20: UNICHAIN_SEPOLIA_CONFIG.MOCK_ERC20,
};
