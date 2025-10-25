// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IPaymentGateway} from "../contracts/interfaces/IPaymentGateway.sol";

import {ForkTest} from "../lib/evk-periphery/lib/euler-price-oracle/test/utils/ForkTest.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {console2} from "forge-std/console2.sol";

import "./utils/ForkUtils.sol";
import "./utils/Deployers.sol";

import {PYTH,PYTH_DAI_USD_FEED,PYTH_USDC_USD_FEED} from "euler-price-oracle-test/adapter/pyth/PythFeeds.sol";
import "euler-price-oracle-test/utils/EthereumAddresses.sol";

import {IPaymentGateway} from "../contracts/interfaces/IPaymentGateway.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IPeripheryImmutableState} from "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";

import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

import {SqrtPriceLibrary} from "../lib/foundational-hooks/src/libraries/SqrtPriceLibrary.sol";

contract PaymentGatewayForkTest is ForkTest, Deployers {
    using TickMath for uint160;


    address pyUsdcVault;
    function setUp() public {
        _setUpFork(23655119);


        deployUniswapV3Oracle();
        deployChainOracleAndSetAll(
            PYUSDC,
            USD,
            USDC,
            PYTH_USDC_USD_FEED,
            uniswapV3Oracle,
            ORACLE_LENS,
            PYTH
        );

        deployPaymentGatewayAndSetAll();


    
    }

    function test__unit__processPayment__mustSwapPaymentTokenToPyUSDC() external {
        vm.startPrank(DAI_WHALE);

        console2.log("DAI balance of DAI_WHALE:", IERC20(DAI).balanceOf(DAI_WHALE));

        IERC20(DAI).approve(address(paymentGateway), type(uint256).max);
        address pool = IUniswapV3Factory(IPeripheryImmutableState(UNISWAP_V3_QUOTER).factory()).getPool(
            DAI,
            USDC,
            uint24(100)
        );

        (uint160 currentPriceX96,int24 currentTick,,,,,)= IUniswapV3Pool(pool).slot0();

        uint256 amountOutUSDC = IChainPriceOracle(chainPriceOracle).getQuote(
            DEFAULT_PAYMENT_AMOUNT*DECIMAL_OFFSET,
            DAI,
            USDC
        );

        uint160 externalCurrentPriceX96 = SqrtPriceLibrary.fractionToSqrtPriceX96(
            amountOutUSDC,
            DEFAULT_PAYMENT_AMOUNT*DECIMAL_OFFSET
        );


        console2.log("currentPriceX96:", currentPriceX96);

        (uint128 liquidityGross, int128 liquidityNet,,,,,,)= IUniswapV3Pool(pool).ticks(currentTick);
        console2.log("liquidityGross:", liquidityGross);
        console2.log("liquidityNet:", liquidityNet);

        // Test with 100 DAI instead of 250,000 DAI
        uint256 testAmount = 100e18; // 100 DAI
        console2.log("Test amount (DAI):", testAmount);
        
        uint256 amountOut = IQuoter(UNISWAP_V3_QUOTER).quoteExactInputSingle(
            DAI,
            USDC,
            100,
            testAmount,
            0
        );

        console2.log("Amount out (USDC):", amountOut);


        // console2.log("amountOut:", amountOut);

        
        
        IPaymentGateway(paymentGateway).processPayment(
            DAI_WHALE,
            DAI,
            100e18,
            bytes32(uint256(uint160(address(this))))
        );
        
        vm.stopPrank();
        // IEthereumVaultConnector(payable(EVC)).call(
        //     address(paymentGateway),
        //     DAI_WHALE,
        //     uint256(0x00),
        //     abi.encodeCall(
        //         IPaymentGateway.processPayment,
        //         (
        //             DAI_WHALE,
        //             DAI,
        //             DEFAULT_PAYMENT_AMOUNT*DECIMAL_OFFSET,
        //             bytes32(uint256(uint160(address(this))))                )
        //     )
        // );
        

        vm.stopPrank();





    }
}
