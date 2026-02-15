// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {BalanceDelta} from "@uniswap/v4-core/src/types/BalanceDelta.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {OrbitWork} from "../src/core/OrbitWork.sol";
import {MockERC20} from "../src/core/MockERC20.sol";

contract RobustSwapper {
    IPoolManager manager;
    
    constructor(IPoolManager _manager) {
        manager = _manager;
    }

    struct CallbackData {
        PoolKey key;
        IPoolManager.SwapParams params;
        address sender;
    }

    function swap(PoolKey memory key, IPoolManager.SwapParams memory params) external payable {
        manager.unlock(abi.encode(CallbackData(key, params, msg.sender)));
    }

    function unlockCallback(bytes calldata data) external returns (bytes memory) {
        CallbackData memory cb = abi.decode(data, (CallbackData));
        (BalanceDelta delta) = manager.swap(cb.key, cb.params, "");
        
        if (delta.amount0() < 0) {
            _settle(cb.key.currency0, uint128(-delta.amount0()));
        }
        if (delta.amount1() < 0) {
            _settle(cb.key.currency1, uint128(-delta.amount1()));
        }
        if (delta.amount0() > 0) {
            manager.take(cb.key.currency0, address(this), uint256(uint128(delta.amount0())));
        }
        if (delta.amount1() > 0) {
            manager.take(cb.key.currency1, address(this), uint256(uint128(delta.amount1())));
        }
        return "";
    }
    
    function _settle(Currency currency, uint256 amount) internal {
        if (currency.isAddressZero()) {
            manager.settle{value: amount}();
        } else {
            IERC20(Currency.unwrap(currency)).transferFrom(msg.sender, address(manager), amount);
            manager.sync(currency);
        }
    }
}

contract SwapScript is Script {
    IPoolManager constant MANAGER = IPoolManager(0x00B036B58a818B1BC34d502D3fE730Db729e62AC);
    address constant USDC = 0x8f22D60F408DBA32ba2D4123aD0aE6D3c0b1d28B; 
    address constant HOOK = 0x03C499185c31fEef9b018E9e2f957fA4B0330a40;
    address constant ORBIT_WORK = 0xEe8a174c6fabDEb52a5d75e8e3F951EFbC667fDB;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Define Key
        address token0 = USDC;
        address token1 = address(0);
        if (token0 > token1) (token0, token1) = (token1, token0);
        
        PoolKey memory key = PoolKey({
            currency0: Currency.wrap(token0),
            currency1: Currency.wrap(token1),
            fee: 3000,
            tickSpacing: 60,
            hooks: IHooks(HOOK)
        });

        // 1. Initialize Pool since it is new (new Hook address)
        try MANAGER.initialize(key, TickMath.getSqrtPriceAtTick(0)) {
            console.log("Pool Initialized");
        } catch {
            console.log("Pool already initialized");
        }
        
        // 1. Create a NEW Escrow (ID 2) to initialize the new hook
        console.log("Creating new Escrow...");
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 250 * 1e6; // 250 USDC
        
        // Mint USDC to this script for escrow
        MockERC20(USDC).mint(deployer, 300 * 1e6);
        MockERC20(USDC).approve(ORBIT_WORK, 300 * 1e6);

        string[] memory m = new string[](1);
        m[0] = "Simulation Milestone";
        
        address[] memory arbiters = new address[](1);
        arbiters[0] = deployer;

        uint256 escrowId = OrbitWork(payable(ORBIT_WORK)).createEscrow(
            0xF1E430aa48c3110B2f223f278863A4c8E2548d8C, // beneficiary
            arbiters,
            1, // requiredConfirmations
            amounts,
            m,
            USDC,
            86400 * 30, // duration
            "Simulation Project",
            "Project for yield simulation"
        );
        console.log("Created Escrow ID:", escrowId);

        // 2. Deploy Swapper
        RobustSwapper swapper = new RobustSwapper(MANAGER);
        
        // 3. Swap
        // We want to swap ETH for USDC to push tick into our liquidity range [MIN, tick]
        bool zeroForOne = (USDC == token1); // If USDC is token1, then ETH is token0. zeroForOne=true is ETH -> USDC.
        console.log("Swapping 0.005 ETH for USDC...");
        
        IPoolManager.SwapParams memory params = IPoolManager.SwapParams({
            zeroForOne: zeroForOne,
            amountSpecified: -1e15, // 0.001 ETH
            sqrtPriceLimitX96: zeroForOne ? TickMath.MIN_SQRT_PRICE + 1 : TickMath.MAX_SQRT_PRICE - 1
        });
        
        try swapper.swap{value: 1e15}(key, params) {
            console.log("Swap Complete!");
        } catch Error(string memory reason) {
            console.log("Swap Failed:", reason);
        } catch (bytes memory lowLevelData) {
            console.log("Swap Failed (Bytes)");
            // Cannot easily decode bytes here in script without helper
        }
        
        vm.stopBroadcast();
    }
}
