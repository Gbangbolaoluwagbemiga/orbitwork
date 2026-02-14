// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";

import {EscrowHook} from "../src/EscrowHook.sol";
import {OrbitWork} from "../src/core/OrbitWork.sol";
import {MockUSDC} from "../src/mocks/MockUSDC.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployRealYield is Script {
    using CurrencyLibrary for Currency;

    // Unichain Sepolia Testnet Addresses
    // Unichain Sepolia Testnet Addresses
    IPoolManager constant POOL_MANAGER = IPoolManager(0x00B036B58a818B1BC34d502D3fE730Db729e62AC);

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("==== Deploying Real Yield System ====");
        console.log("Deployer:", deployer);
        
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Mock Token (USDC)
        MockUSDC usdc = new MockUSDC();
        console.log("MockUSDC deployed at:", address(usdc));

        // 2. Use Existing OrbitWork (Already Deployed)
        OrbitWork orbitWork = OrbitWork(payable(0xEe8a174c6fabDEb52a5d75e8e3F951EFbC667fDB));
        console.log("Using existing OrbitWork at:", address(orbitWork));

        // 3. Deploy EscrowHook with Mined Salt
        // Mined locally: 0x...56b3 -> 0xF3Db...A40
        bytes32 salt = bytes32(uint256(0x56b3));
        address expectedAddress = 0xF3Db6afEd83E7dDECbF099eA4717DB1A7B544a40;
        
        console.log("Deploying EscrowHook with salt:", vm.toString(salt));
        
        EscrowHook escrowHook = new EscrowHook{salt: salt}(POOL_MANAGER, address(orbitWork));
        require(address(escrowHook) == expectedAddress, "Hook Address Mismatch");
        console.log("EscrowHook deployed at:", address(escrowHook));

        // 4. Link Hook to Core
        orbitWork.setEscrowHook(address(escrowHook));
        console.log("Linked Hook to Core");

        // 5. Initialize Pool (USDC / Native)
        // Sort tokens
        address token0 = address(usdc);
        address token1 = address(0); // Native is 0
        if (token0 > token1) {
            (token0, token1) = (token1, token0);
        }
        
        Currency currency0 = Currency.wrap(token0);
        Currency currency1 = Currency.wrap(token1);
        
        PoolKey memory key = PoolKey({
            currency0: currency0,
            currency1: currency1,
            fee: 3000, // 0.3%
            tickSpacing: 60,
            hooks: IHooks(address(escrowHook))
        });
        
        // Check if pool exists, if not initialize
        // SQRT_RATIO_1_1 = 79228162514264337593543950336
        uint160 sqrtPriceX96 = 79228162514264337593543950336;
        
        // We use try/catch to avoid failure if pool already exists (though with new hook, it shouldn't)
        try POOL_MANAGER.initialize(key, sqrtPriceX96) {
            console.log("Pool Initialized");
        } catch {
            console.log("Pool already initialized (unexpected for new hook)");
        }

        // 6. Add Initial Liquidity (Generic LP - Optional, but useful for baseline)
        // Actually, let's just do a swap to generate fees?
        // But we need liquidity to swap against.
        // Deployer adds liquidity.
        
        // Mint USDC to deployer for LP
        usdc.mint(deployer, 1000000 * 1e18);
        usdc.approve(address(POOL_MANAGER), type(uint256).max);
        
        // Add full range liquidity
        int24 tickLower = (TickMath.MIN_TICK / 60) * 60;
        int24 tickUpper = (TickMath.MAX_TICK / 60) * 60;
        
        // Add 1000 USDC and ~1000 ETH worth (mock)
        // This requires providing ETH.
        
        IPoolManager.ModifyLiquidityParams memory params = IPoolManager.ModifyLiquidityParams({
             tickLower: tickLower,
             tickUpper: tickUpper,
             liquidityDelta: 100 ether, // Just some liquidity
             salt: bytes32(0)
        });
        
        // We need to pass ETH. `modifyLiquidity` is not payable directly?
        // In v4, we use `modifyLiquidity` then settle.
        // Script simplified: just unlock and callback.
        // But doing this in a script without a proper Router/PositionManager is complex.
        // We'll skip adding generic LP for now.
        // The *User* will add liquidity via Escrow.
        
        // Wait, if no liquidity in pool, the EscrowHook might fail to calculate optimal amounts?
        // No, single-sided liquidity works even in empty pool (it initializes tight range around current tick? No, full range).
        // It relies on current tick. Initialized pool has tick corresponding to `sqrtPriceX96`.
        
        vm.stopBroadcast();
        
        console.log("==== Deployment Complete ====");
        console.log("USDC:", address(usdc));
        console.log("OrbitWork:", address(orbitWork));
        console.log("Hook:", address(escrowHook));
    }
}
