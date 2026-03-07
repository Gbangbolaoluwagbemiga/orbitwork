import orbitWorkAbi from "./orbitwork-abi.json";

export const ORBIT_WORK_ABI = orbitWorkAbi;

export const ERC20_ABI = [
  {
    inputs: [],
    name: "name",
    outputs: [{ internalType: "string", name: "", type: "string" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [{ internalType: "string", name: "", type: "string" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "decimals",
    outputs: [{ internalType: "uint8", name: "", type: "uint8" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "address", name: "account", type: "address" }],
    name: "balanceOf",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "spender", type: "address" },
      { internalType: "uint256", name: "amount", type: "uint256" },
    ],
    name: "approve",
    outputs: [{ internalType: "bool", name: "", type: "bool" }],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      { internalType: "address", name: "owner", type: "address" },
      { internalType: "address", name: "spender", type: "address" },
    ],
    name: "allowance",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
] as const;

export const ESCROW_HOOK_ABI = [
  {
    inputs: [{ internalType: "uint256", name: "escrowId", type: "uint256" }],
    name: "getEscrowYield",
    outputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [{ internalType: "uint256", name: "", type: "uint256" }],
    name: "escrowPositions",
    outputs: [
      {
        internalType: "struct IEscrowHook.PoolKey", name: "key", type: "tuple", components: [
          { name: "currency0", type: "address" },
          { name: "currency1", type: "address" },
          { name: "fee", type: "uint24" },
          { name: "tickSpacing", type: "int24" },
          { name: "hooks", type: "address" }
        ]
      },
      { internalType: "uint128", name: "liquidity", type: "uint128" },
      { internalType: "uint256", name: "reserveAmount", type: "uint256" },
      { internalType: "uint256", name: "token0FeeGrowthLast", type: "uint256" },
      { internalType: "uint256", name: "token1FeeGrowthLast", type: "uint256" },
      { internalType: "uint256", name: "yieldAccumulated", type: "uint256" },
      { internalType: "bool", name: "isActive", type: "bool" }
    ],
    stateMutability: "view",
    type: "function",
  }
] as const;
