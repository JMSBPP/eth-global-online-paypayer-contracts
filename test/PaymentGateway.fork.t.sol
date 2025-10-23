// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IPaymentGateway} from "../contracts/interfaces/IPaymentGateway.sol";

import {ForkTest} from "../lib/evk-periphery/lib/euler-price-oracle/test/utils/ForkTest.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {console2} from "forge-std/console2.sol";

import "./utils/ForkUtils.sol";
import "./utils/Deployers.sol";

import {PYTH,PYTH_DAI_USD_FEED,PYTH_USDC_USD_FEED} from "euler-price-oracle-test/adapter/pyth/PythFeeds.sol";
import {DAI, USDC, UNISWAP_V3_FACTORY} from "euler-price-oracle-test/utils/EthereumAddresses.sol";

import {IPaymentGateway} from "../contracts/interfaces/IPaymentGateway.sol";

contract PaymentGatewayForkTest is ForkTest, Deployers {


    function setUp() public {
        _setUpFork(23626800);


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

        deployPaymentGatewayAndSetAll(chainPriceOracle);
    
    }

    function test__unit__processPayment__mustCreateNewVaultForNewPaymentToken() external {
        IPaymentGateway(paymentGateway).processPayment(
            address(this),
            DAI,
            DEFAULT_PAYMENT_AMOUNT,
            bytes32(uint256(uint160(address(this))))
        );




    }
}
