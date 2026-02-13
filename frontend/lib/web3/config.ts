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
const SECUREFLOW_ADDR =
  process.env.NEXT_PUBLIC_SECUREFLOW_ESCROW ||
  "0xFD64e85e04778c79f2628379EA7D226f2bc1bdC3";

const RATINGS_ADDR =
  process.env.NEXT_PUBLIC_ORBITWORK_RATINGS ||
  "0xa29de3678ea79c7031fc1c5c9c0547411637bd9f";

export const CONTRACTS = {
  // Unichain Sepolia
  SECUREFLOW_ESCROW_UNICHAIN: SECUREFLOW_ADDR,
  ORBITWORK_RATINGS: RATINGS_ADDR,
  ESCROW_HOOK: "0x1c55CC2Aac4B4AE0740fFac84CC838EeF2438A40",

  // Default contracts (used by frontend)
  SECUREFLOW_ESCROW: SECUREFLOW_ADDR,
  USDC: "0x0000000000000000000000000000000000000000", // Needs actual USDC on Unichain if available
  MOCK_ERC20: "0x0000000000000000000000000000000000000000",
};
