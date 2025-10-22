// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


import {DAI, USDC, UNISWAP_V3_FACTORY} from "euler-price-oracle-test/utils/EthereumAddresses.sol";

import {IChainPriceOracle} from "../contracts/interfaces/IChainPriceOracle.sol";
import {ForkTest} from "../lib/evk-periphery/lib/euler-price-oracle/test/utils/ForkTest.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {PYTH,PYTH_DAI_USD_FEED,PYTH_USDC_USD_FEED} from "euler-price-oracle-test/adapter/pyth/PythFeeds.sol";
import {PythStructs} from "@pyth/PythStructs.sol";
import {IPyth} from "@pyth/IPyth.sol";
import {console2} from "forge-std/console2.sol";

import "./utils/ForkUtils.sol";
import "./utils/Deployers.sol";
import {FullMath} from "euler-swap/src/math/FullMath.sol";


contract ChainPriceOracleForkTest is ForkTest, Deployers {
    // uint256 constant MAX_STABLE_DELTA;
    uint256 constant DEFAULT_PAYMENT_AMOUNT = 2500;
    uint256 constant DECIMAL_OFFSET = 1e8;
    // type(uint160).max / 1e8 -1 
    uint256 constant MAX_PAYMENT_AMOUNT = 0x0000000000000000000000000000002af31dc4611873bf3f70834acdae9f0f4e;

    function setUp() public {
        _setUpFork(23626800);

        deployUniswapV3Oracle();
        deployChainOracleAndSetAll(PYUSDC, USD, USDC, PYTH_USDC_USD_FEED, uniswapV3Oracle, ORACLE_LENS, PYTH);
        deployPaymentGateway(chainPriceOracle);
        deployPayerClient(PYUSDC, paymentGateway);

    }

    function test__unit__getQuote__mustReturnValidQuoteForStablePaymentToken() external {
        uint256 pyUsdcAmount = IChainPriceOracle(chainPriceOracle).getQuote(
            DEFAULT_PAYMENT_AMOUNT * DECIMAL_OFFSET,
            DAI,
            USD
        );

        uint256 peg = FullMath.mulDiv(DEFAULT_PAYMENT_AMOUNT, DECIMAL_OFFSET, pyUsdcAmount);
        assertEq(peg, uint256(0x01));

    }

    // function test__fuzz_getQuote__mustReturnValidQuoteForStablePaymentToken(uint256 paymentAmount) external {
    //     uint256 _paymentAmount = bound(paymentAmount, 0, MAX_PAYMENT_AMOUNT);
    //     uint256 pyUsdcAmount = IChainPriceOracle(chainPriceOracle).getQuote(
    //         _paymentAmount * DECIMAL_OFFSET,
    //         DAI,
    //         USD
    //     );

    //     uint256 peg = FullMath.mulDiv(_paymentAmount, DECIMAL_OFFSET, pyUsdcAmount);
    //     assertEq(peg, uint256(0x01));

    // }

}