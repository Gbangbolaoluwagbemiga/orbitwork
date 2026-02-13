# Unichain Sepolia Deployment Results

## Deployment 1 (Legacy Hook Only)
- Date: 2026-02-05
- Hook Address: `0xBEc49fA140aCaA83533f900E8c78D2DDE69Cd07C`

## Deployment 3 (Marketplace + Productive Escrow)
- Date: 2026-02-12
- Network: Unichain Sepolia
- **SecureFlow (EscrowCore):** `0xFD64e85e04778c79f2628379EA7D226f2bc1bdC3`
- **EscrowHook:** `0x1c55CC2Aac4B4AE0740fFac84CC838EeF2438A40`
- **OrbitworkRatings:** `0xa29de3678ea79c7031fc1c5c9c0547411637bd9f` (Reused)
- **PoolManager:** `0x00B036B58a818B1BC34d502D3fE730Db729e62AC`

### Configuration
- `optimizer = true` (runs: 1)
- `via_ir = true`
- Removed Modules: RefundSystem, RatingSystem (to fit 24KB limit)
- Included Modules: Marketplace (re-enabled for application logic)
- Hook Flags: `beforeAddLiquidity`, `beforeRemoveLiquidity`, `afterSwap`

### Verification
To verify contracts:
```bash
forge verify-contract 0xaa6a6Ee940803Ba5759d26a8c2FADbeE7d939052 src/core/SecureFlow.sol:SecureFlow --chain-id 1301 --watch
forge verify-contract 0x73640cC810E3cC302568Adfac03587669D300a00 src/EscrowHook.sol:EscrowHook --chain-id 1301 --watch
```
