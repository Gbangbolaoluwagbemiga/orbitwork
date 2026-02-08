# Orbitwork 🪐

**The World's First Yield-Bearing Escrow Platform**

Orbitwork transforms passive escrow deposits into active, yield-generating liquidity using Uniswap v4 Hooks. By deploying escrow funds into Uniswap v4 pools while work is in progress, we unlock capital efficiency for the gig economy.

---

## 🚀 Live on Unichain Sepolia

### Deployed Contracts
| Contract | Address | Explorer |
|----------|---------|----------|
| **EscrowHook** | `0x510759629739023E26D3DF22F4e9E06D62A5ca00` | [View on Uniscan](https://sepolia.uniscan.xyz/address/0x510759629739023E26D3DF22F4e9E06D62A5ca00) |
| **EscrowCore** | *Coming soon* | - |

---

## 💡 The Problem & Solution

**The Problem:** Traditional escrow platforms lock up billions of dollars in idle capital. A $10,000 project taking 3 months means $10,000 earning $0 yield.

**Our Solution:** **Liquid Escrow**
1. **Deposit**: Client funds are verified and locked.
2. **Deploy**: Our `EscrowHook` automatically adds funds as liquidity to a Uniswap v4 pool.
3. **Earn**: Funds earn trading fees (0.05% - 0.30%) while work is being done.
4. **Release**: When milestones are approved, liquidity is removed. 
   - Freelancer gets paid (Principal)
   - Platform/Client shares the yield (Fees)

---

## ✨ Key Features

### 💧 Liquid Escrow Hook
- **Zero Idle Capital**: Funds work for you while you work.
- **Automated Management**: Hook handles add/remove liquidity logic securely.
- **Yield Generation**: Earns LP fees from Uniswap trading volume.

### 🛡️ Self Protocol Identity
- **Verified Reputation**: Integration with Self Protocol for on-chain identity.
- **Fee Discounts**: Verified users get **50% off** platform fees when creating escrows.

### ⚡ Unichain Native
- Built specifically for Unichain's low-latency, low-cost environment.
- Leverages Uniswap v4's singleton architecture for gas efficiency.

---

## 🛠️ Technical Architecture

### Smart Contracts
- **`EscrowHook.sol`**: The brain. Manages interactions with Uniswap v4 `PoolManager`.
- **`EscrowCore.sol`**: The body. Manages escrow state, milestones, and disputes.
- **`EscrowManagement.sol`**: Handles deposits and creation logic.

### Tech Stack
- **Framework**: Foundry (Smart Contracts) + Next.js (Frontend)
- **Network**: Unichain Sepolia Testnet
- **Hooks**: Uniswap v4 (BeforeAddLiquidity, BeforeRemoveLiquidity)

---

## 📦 Installation & Setup

### Prerequisites
- Foundry (`forge`, `cast`, `anvil`)
- Node.js & Bun/Yarn

### 1. Clone the Repo
```bash
git clone https://github.com/Gbangbolaoluwagbemiga/orbitwork.git
cd orbitwork
```

### 2. Smart Contracts (Foundry)
```bash
cd orbitwork-hook
forge install
forge build
forge test
```

### 3. Frontend
```bash
cd frontend
bun install
bun dev
```

---

## 🧪 Testing

Run the full test suite to verify hook logic:

```bash
cd orbitwork-hook
forge test -vv
```

---

## 🏆 Hackathon Tracks

- **Unichain**: Deployed on Unichain Sepolia.
- **Uniswap v4 Hooks**: Novel usage of hooks for real-world asset (RWA) escrow utility.

---

## License

MIT
