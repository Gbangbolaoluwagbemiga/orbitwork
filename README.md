# Orbitwork 🪐

**The World's First Yield-Bearing Escrow Platform on Uniswap v4**

> 🏆 **Submitted for Uniswap Hook Incubator (UHI)**

Orbitwork transforms passive escrow deposits into active, yield-generating liquidity. By deploying escrow funds into Uniswap v4 pools via a custom Hook, we unlock capital efficiency for the gig economy, allowing both clients and freelancers to earn yield on idle assets while ensuring trustless payments.

---

## 🚀 Live Deployment (Unichain Sepolia)

We are live on **Unichain Sepolia Testnet**!

### Contract Addresses (Unichain Sepolia)
| Contract | Address | Description |
|----------|---------|-------------|
| **OrbitWork** | `0x58cc32920E25e9aaf528dc6F37996d7670d5374A` | Core Escrow logic with 0% upfront fees. |
| **EscrowHook** | `0xc6721B7fad95Ae93e3c2ded00908a88299740a40` | Uniswap v4 Hook for liquid escrow yield generation. |

### Contract Addresses (Reactive Network - Kopli/Lasna)
| Contract | Address | Description |
|----------|---------|-------------|
| **OrbitworkReactive** | `0xfdbb4b239eab62d22f432e9b402d7f0368f71a4d` | Autonomous monitoring and auto-approval service. |

---

## 💡 The Problem & Solution

**The Problem:** Traditional escrow platforms lock up billions of dollars in idle capital. A $10,000 project taking 3 months effectively earns $0 yield, representing a massive opportunity cost.

**Our Solution:** **Liquid Escrow**
1.  **Deposit**: Client funds (USDC, ETH, etc.) are verified and locked in the `EscrowCore` contract.
2.  **Auto-LP Deployment**: Our `EscrowHook` automatically intercepts the deposit and deploys 80% of the funds as liquidity into a concentrated Uniswap v4 pool.
3.  **Real Yield Generation**: While the freelancer works, the funds earn trading fees (swap fees) from the pool.
4.  **Yield Distribution**: Upon milestone completion, the accumulated yield is distributed (e.g., 70% to Freelancer as a bonus, 30% to Platform/Client).

---

## ✨ Key Features

### 💧 Productive Capital (Real Yield)
*   **Zero Idle Capital**: Escrowed funds are put to work immediately.
*   **Live Tracking**: The dashboard features a "Productive Capital" widget that tracks accumulated yield in real-time.
*   **Automated Liquidity Management**: The Hook handles the complexity of adding/removing liquidity during escrow lifecycle events (creation, release, refund).

### 🛡️ Verified Identity & Reputation
*   **0% Upfront Fees**: OrbitWork relies entirely on yield, charging 0% to clients at escrow creation.
*   **Verified Identity**: Users can verify their identity on-chain for trusted interactions.
*   **On-Chain Ratings**: Every completed job generates an immutable review, building a verifiable reputation history.

### ⚡ Unichain Native
*   **Low Latency**: Built on Unichain for instant interactions and sub-second block times.
*   **Gas Efficiency**: Leverages Uniswap v4's singleton architecture and Unichain's low fees.

### 🤖 Autonomous Lifecycle (Reactive Network)
*   **Decentralized Automation**: Orbitwork leverages the **Reactive Network** to provide an autonomous settlement layer.
*   **The Reactive Usecase**: Our `OrbitworkReactive.sol` contract (on Kopli/Lasna) monitors Unichain Sepolia for `MilestoneSubmitted` events.
*   **Trustless Auto-Approval**: If a milestone is not disputed within the mandatory window, Reactive automatically triggers the `autoApproveMilestone` callback on the main contract to release funds.
*   **Zero-Maintenance**: This setup removes the need for centralized bots or "keepers", making the entire escrow-to-payout pipeline decentralized and self-driving.

---

## 🛠️ Technical Architecture

### Smart Contracts (Foundry)
*   **`EscrowHook.sol`**: The heart of the yield engine. It implements `IHook` to interact with the Uniswap v4 `PoolManager`.
    *   `beforeAddLiquidity`: Validates liquidity provision.
    *   `beforeRemoveLiquidity`: Ensures only authorized escrow withdrawals can remove liquidity.
    *   `getEscrowYield`: View function to calculate accrued fees for a specific escrow.
*   **`EscrowCore.sol`**: Manages the business logic.
    *   `createEscrow`: Initializes escrow and triggers the Hook.
    *   `releaseMilestone`: Releases funds to freelancer and claimed yield.
    *   `dispute`: Handles dispute resolution via trusted arbiters.
*   **`OrbitworkRatings.sol`**: A decoupled, NFT-based reputation system for storing job reviews.

### Frontend (Next.js 14)
*   **Dashboard**: A comprehensive interface for managing jobs, applications, and viewing financial stats.
*   **Web3 Integration**: deeply integrated with `wagmi` and `ethers.js` for seamless wallet connection and contract interaction.
*   **Yield Tracker**: A dedicated component that fetches live yield data directly from the Hook, displaying it with correct decimal formatting for any token.

---

## 📦 Installation & Setup

### Prerequisites
*   [Foundry](https://book.getfoundry.sh/getting-started/installation) (for smart contracts)
*   [Bun](https://bun.sh/) or Node.js (for frontend)

### 1. Clone the Repository
```bash
git clone https://github.com/Gbangbolaoluwagbemiga/orbitwork.git
cd orbitwork
```

### 2. Smart Contract Setup
```bash
cd orbitwork-hook
forge install
forge build
forge test
```

### 3. Frontend Setup
```bash
cd frontend
bun install
# Create a .env.local file with your configuration (see .env.example)
bun dev
```

The app will be available at `http://localhost:3000`.

---

## 🧪 Simulation & Testing Yield

To verify the yield generation mechanism locally or on testnet, we provide a simulation script.

1.  **Configure Environment**:
    Ensure your `.env` in `orbitwork-hook` contains your `PRIVATE_KEY`.

2.  **Run the Swap Simulation**:
    This script performs creating an escrow and executing a swap to generate fees for it.
    ```bash
    cd orbitwork-hook
    forge script script/Swap.s.sol:SwapScript --rpc-url https://sepolia.unichain.org --broadcast
    ```

3.  **Verify on Frontend**:
    Refresh the dashboard. You should see the "Yield Earned" amount increase for the relevant escrow.

---

## 👥 Team
*   **Oluwagbemiga** - Full Stack Developer & Smart Contract Engineer

---

*Built with ❤️ for the Uniswap Hook Incubator*
