# Orbitwork 🪐

**The World's First Yield-Bearing Escrow Platform on Uniswap v4**

> 🏆 **Submission for Uniswap Hook Incubator (UHI)**

Orbitwork transforms passive escrow deposits into active, yield-generating liquidity. By deploying escrow funds into Uniswap v4 pools via a custom Hook, we unlock capital efficiency for the gig economy, allowing both clients and freelancers to earn yield on idle assets.

---

## 🚀 Live on Unichain Sepolia

### Deployed Contracts
| Contract | Address | Description |
|----------|---------|-------------|
| **EscrowHook** | `0x1c55CC2Aac4B4AE0740fFac84CC838EeF2438A40` | The Uniswap v4 Hook that manages liquidity. |
| **EscrowCore** | `0xFD64e85e04778c79f2628379EA7D226f2bc1bdC3` | The main logic for milestones and payments. |
| **Ratings** | `0xa29de3678ea79c7031fc1c5c9c0547411637bd9f` | On-chain reputation system. |

---

## 💡 The Problem & Solution

**The Problem:** Traditional escrow platforms lock up billions of dollars in idle capital. A $10,000 project taking 3 months means $10,000 earning $0 yield.

**Our Solution:** **Liquid Escrow**
1.  **Deposit**: Client funds are verified and locked in the escrow contract.
2.  **Auto-LP**: Our `EscrowHook` automatically adds these funds as liquidity to a Uniswap v4 pool.
3.  **Real Yield**: Funds earn trading fees (0.05% - 0.30%) while work is being done.
4.  **Yield Distribution**: When milestones are released, the yield is distributed (e.g. 70% to Freelancer, 30% to Platform).

---

## ✨ Key Features

### 💧 Productive Capital (Real Yield)
*   **Zero Idle Capital**: Funds work for you while you work.
*   **Live Tracking**: The dashboard shows **Real Yield** earned from the Uniswap pool in real-time.
*   **Collapsible UI**: Clean interface to view yield performance.

### 🛡️ Verified Identity & Reputation
*   **Self Protocol Integration**: Users verify their identity on-chain.
*   **Fee Discounts**: Verified users get **50% off** platform fees.
*   **On-Chain Ratings**: Immutable review history for every completed job.

### ⚡ Unichain Native
*   **Low Latency**: Built for the speed of commerce.
*   **Gas Efficiency**: Leverages Uniswap v4's singleton architecture.

---

## 🛠️ Technical Architecture

### Smart Contracts (Foundry)
*   **`EscrowHook.sol`**: The core hook. Intercepts `onEscrowCreated` to liquidity.
*   **`EscrowCore.sol`**: Manages the business logic (Milestones, Disputes).
*   **`OrbitworkRatings.sol`**: Decoupled reputation system.

### Frontend (Next.js 14)
*   **Dashboard**: Real-time management of jobs and applications.
*   **Web3 Integration**: Custom `useWeb3` hook with optimized provider handling.
*   **Yield Tracker**: Fetches live data from the Hook contract.

---

## 📦 Installation & Setup

1.  **Clone the Repo**
    ```bash
    git clone https://github.com/Gbangbolaoluwagbemiga/orbitwork.git
    cd orbitwork
    ```

2.  **Install Dependencies**
    ```bash
    cd frontend
    bun install
    ```

3.  **Run Development Server**
    ```bash
    bun dev
    ```

4.  **Run Smart Contract Tests**
    ```bash
    cd orbitwork-hook
    forge test
    ```

---

## 🧪 How to Demo

1.  **Connect Wallet**: Connect your Metamask (Unichain Sepolia).
2.  **Create Job**: Go to "Post a Job", fill in details, and fund the escrow.
3.  **View Yield**: Go to the Dashboard. Expand the **"Productive Capital"** card to see the "Active" status and yield accumulating.
4.  **Hire Freelancer**: Accept a freelancer application to start the work.

---

## 👥 Team
*   **Oluwagbemiga** - Full Stack Developer & Smart Contract Engineer

---

*Built with ❤️ for the Uniswap Hook Incubator*
