// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


import "euler-price-oracle-test/adapter/pyth/PythFeeds.sol";
import "euler-price-oracle-test/utils/EthereumAddresses.sol";
import "./utils/ForkUtils.sol";
import "./utils/Deployers.sol";

import {IPaymentGateway} from "../contracts/interfaces/IPaymentGateway.sol";
import {IPayer} from "../contracts/interfaces/IPayer.sol";

import {ForkTest} from "../lib/evk-periphery/lib/euler-price-oracle/test/utils/ForkTest.sol";
import {console2} from "forge-std/console2.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IPeripheryImmutableState} from "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";
import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";

import {IEVault} from "euler-interfaces/IEVault.sol";

contract PayerForkTest is ForkTest, Deployers {



    function setUp() public {
        _setUpFork(23655119);

        deployUniswapV3Oracle();
        deployChainOracleAndSetAll(
            PYUSD,
            USD,
            USDC,
            PYTH_USDC_USD_FEED,
            uniswapV3Oracle,
            ORACLE_LENS,
            PYTH
        );

        deployPaymentGatewayAndSetAll();
        
        deployClient();
    }

    function test__unit___mustPayForValidPaymentToken() external {
        vm.startPrank(DAI_WHALE);

        IERC20(DAI).approve(address(paymentGateway), DEFAULT_PAYMENT_AMOUNT);

        uint256 balanceBeforePaymentPaymentToken = IERC20(DAI).balanceOf(DAI_WHALE);
    
        address treasury = IPaymentGateway(paymentGateway).getTreasury();
        uint256 balanceBeforePaymentTargetToken = treasury != address(0x00) ? IEVault(treasury).balanceOf(address(this)) : uint256(0x00);

        IPayer(client).pay(
            DAI_WHALE,
            DAI,
            DEFAULT_PAYMENT_AMOUNT,
            address(this),
            new address[](0),
            new bytes[](0),
            new uint256[](0)
        );

        uint256 balanceAfterPaymentPaymentToken = IERC20(DAI).balanceOf(DAI_WHALE);
        address updatedTreasury = IPaymentGateway(paymentGateway).getTreasury();

        uint256 balanceAfterPaymentTargetToken = IEVault(updatedTreasury).balanceOf(address(this));

        assertEq(balanceAfterPaymentPaymentToken, balanceBeforePaymentPaymentToken - DEFAULT_PAYMENT_AMOUNT);
        uint256 payedAmount = balanceAfterPaymentTargetToken - balanceBeforePaymentTargetToken;

        assertGt(payedAmount, 0);

        vm.stopPrank();

    }


    function test__unit__mustPayForETH() external {
        vm.startPrank(ETH_WHALE);
        
        uint256 balanceBeforePayment = ETH_WHALE.balance;

        address treasury = IPaymentGateway(paymentGateway).getTreasury();
        uint256 balanceBeforePaymentTargetToken = treasury != address(0x00) ? IEVault(treasury).balanceOf(address(this)) : uint256(0x00);


        IPayer(client).pay{value : DEFAULT_PAYMENT_AMOUNT}(
            ETH_WHALE,
            ETH,
            DEFAULT_PAYMENT_AMOUNT,
            address(this),
            new address[](0),
            new bytes[](0),
            new uint256[](0)
        );

        uint256 balanceAfterPayment = ETH_WHALE.balance;
        address updatedTreasury = IPaymentGateway(paymentGateway).getTreasury();
        uint256 balanceAfterPaymentTargetToken = IEVault(updatedTreasury).balanceOf(address(this));

        assertEq(balanceAfterPayment, balanceBeforePayment - DEFAULT_PAYMENT_AMOUNT);
        uint256 payedAmount = balanceAfterPaymentTargetToken - balanceBeforePaymentTargetToken;

        assertGt(payedAmount, 0);

        vm.stopPrank();

    }

    function test__unit__mustPayForPYUSD() external {
        vm.startPrank(PYUSD_WHALE);
        
        uint256 balance = IERC20(PYUSD).balanceOf(PYUSD_WHALE);
        console2.log("PYUSD_WHALE balance:", balance);
        
        uint256 paymentAmount = balance > 1000e6 ? 1000e6 : balance / 2; // Use 1000 PYUSD or half the balance
        console2.log("Using payment amount:", paymentAmount);
        
        IERC20(PYUSD).approve(address(paymentGateway), paymentAmount);

        uint256 balanceBeforePayment = IERC20(PYUSD).balanceOf(PYUSD_WHALE);

        address treasury = IPaymentGateway(paymentGateway).getTreasury();
        uint256 balanceBeforePaymentTargetToken = treasury != address(0x00) ? IEVault(treasury).balanceOf(address(this)) : uint256(0x00);
    
        IPayer(client).pay(
            PYUSD_WHALE,
            PYUSD,
            paymentAmount,
            address(this),
            new address[](0),
            new bytes[](0),
            new uint256[](0)
        );

        uint256 balanceAfterPayment = IERC20(PYUSD).balanceOf(PYUSD_WHALE);
        address updatedTreasury = IPaymentGateway(paymentGateway).getTreasury();
        uint256 balanceAfterPaymentTargetToken = IEVault(updatedTreasury).balanceOf(address(this));

        assertEq(balanceAfterPayment, balanceBeforePayment - paymentAmount);
        uint256 payedAmount = balanceAfterPaymentTargetToken - balanceBeforePaymentTargetToken;

        assertGt(payedAmount, 0);

        vm.stopPrank();

    }
}
