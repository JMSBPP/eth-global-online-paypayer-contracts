// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


import "euler-price-oracle-test/adapter/pyth/PythFeeds.sol";
import "euler-price-oracle-test/utils/EthereumAddresses.sol";
import "./utils/ForkUtils.sol";
import "./utils/Deployers.sol";

import {IPaymentGateway} from "../contracts/interfaces/IPaymentGateway.sol";
import {IPayer} from "../contracts/interfaces/IPayer.sol";
import {IPayee} from "../contracts/interfaces/IPayee.sol";

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
        uint256 balanceBeforePaymentTargetToken = treasury != address(0x00) ? IEVault(treasury).balanceOf(address(paymentGateway)) : uint256(0x00);

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

        uint256 balanceAfterPaymentTargetToken = IEVault(updatedTreasury).balanceOf(address(paymentGateway));

        assertEq(balanceAfterPaymentPaymentToken, balanceBeforePaymentPaymentToken - DEFAULT_PAYMENT_AMOUNT);
        uint256 payedAmount = balanceAfterPaymentTargetToken - balanceBeforePaymentTargetToken;

        assertGt(payedAmount, 0);

        vm.stopPrank();

    }


    function test__unit__mustPayForETH() external {
        vm.startPrank(ETH_WHALE);
        
        uint256 balanceBeforePayment = ETH_WHALE.balance;

        address treasury = IPaymentGateway(paymentGateway).getTreasury();
        uint256 balanceBeforePaymentTargetToken = treasury != address(0x00) ? IEVault(treasury).balanceOf(address(paymentGateway)) : uint256(0x00);


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
        uint256 balanceAfterPaymentTargetToken = IEVault(updatedTreasury).balanceOf(address(paymentGateway));

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
        uint256 balanceBeforePaymentTargetToken = treasury != address(0x00) ? IEVault(treasury).balanceOf(address(paymentGateway)) : uint256(0x00);
    
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
        uint256 balanceAfterPaymentTargetToken = IEVault(updatedTreasury).balanceOf(address(paymentGateway));

        assertEq(balanceAfterPayment, balanceBeforePayment - paymentAmount);
        uint256 payedAmount = balanceAfterPaymentTargetToken - balanceBeforePaymentTargetToken;

        assertGt(payedAmount, 0);

        vm.stopPrank();
    }

    function test__fuzz__mustPayAndClaimForValidPaymentToken(
        uint256 _amountToPay
    ) external {

        // NOTE: This are payments from 1 USD to 10.000 USD
        uint256 amountToPay = bound(_amountToPay, 1e18, 10000e18);
        vm.startPrank(DAI_WHALE);
        
        // Check balances before payment
        uint256 balanceBeforePaymentPaymentToken = IERC20(DAI).balanceOf(DAI_WHALE);
        address treasury = IPaymentGateway(paymentGateway).getTreasury();
        uint256 balanceBeforePaymentTargetToken = treasury != address(0x00) ? IEVault(treasury).balanceOf(address(paymentGateway)) : uint256(0x00);
        
        // NOTE: DAI WHALE has sent DAI to ETH_WHALE
        IERC20(DAI).approve(address(paymentGateway), amountToPay);
        IPayer(client).pay(
            DAI_WHALE,
            DAI,
            amountToPay,
            ETH_WHALE,
            new address[](0),
            new bytes[](0),
            new uint256[](0)
        );
        
        // Check balances after payment
        uint256 balanceAfterPaymentPaymentToken = IERC20(DAI).balanceOf(DAI_WHALE);
        address updatedTreasury = IPaymentGateway(paymentGateway).getTreasury();
        uint256 balanceAfterPaymentTargetToken = IEVault(updatedTreasury).balanceOf(address(paymentGateway));

        // Verify payment token balance decreased correctly
        assertEq(balanceAfterPaymentPaymentToken, balanceBeforePaymentPaymentToken - amountToPay);
        
        // Verify target token balance increased (payment was processed)
        uint256 payedAmount = balanceAfterPaymentTargetToken - balanceBeforePaymentTargetToken;
        assertGt(payedAmount, 0);
        
        vm.stopPrank();

        vm.startPrank(ETH_WHALE);
        
        // Get the actual amount from the payment queue
        IPaymentGateway.PaymentData[] memory payments = IPaymentGateway(paymentGateway).getPaymentsQueue(ETH_WHALE);
        require(payments.length > 0, "No payments found");
        uint256 amountReceived = payments[0].amountPaid;
        
        IPayee(client).claimPayment(
            ETH_WHALE,
            DAI_WHALE,
            amountReceived, // Use the actual received amount (pyUSDC) instead of original amount (DAI)
            ETH_WHALE
        );
        vm.stopPrank();
        vm.startPrank(DAI_WHALE);
        

    }

    // function test__fuzz__mustPayAndClaimForETH(uint256 _amountToPay) external {
    //     // NOTE: Transfer ETH  
    //     uint256 amountToPay = bound(_amountToPay, 1e18, 10000e18);

    //     vm.deal(ETH_WHALE, amountToPay);
    //     vm.startPrank(ETH_WHALE);
        
    //     // Check balances before payment
    //     uint256 balanceBeforePaymentETH = ETH_WHALE.balance;
    //     address treasury = IPaymentGateway(paymentGateway).getTreasury();
    //     uint256 balanceBeforePaymentTargetToken = treasury != address(0x00) ? IEVault(treasury).balanceOf(address(paymentGateway)) : uint256(0x00);
        
    //     IPayer(client).pay{value : amountToPay}(
    //         ETH_WHALE,
    //         ETH,
    //         amountToPay,
    //         DAI_WHALE,
    //         new address[](0),
    //         new bytes[](0),
    //         new uint256[](0)
    //     );

    //     // Check balances after payment
    //     uint256 balanceAfterPaymentETH = ETH_WHALE.balance;
    //     address updatedTreasury = IPaymentGateway(paymentGateway).getTreasury();
    //     uint256 balanceAfterPaymentTargetToken = IEVault(updatedTreasury).balanceOf(address(paymentGateway));

    //     // Verify ETH balance decreased correctly
    //     assertEq(balanceAfterPaymentETH, balanceBeforePaymentETH - amountToPay);
        
    //     // Verify target token balance increased (payment was processed)
    //     uint256 payedAmount = balanceAfterPaymentTargetToken - balanceBeforePaymentTargetToken;
    //     assertGt(payedAmount, 0);

    //     vm.stopPrank();

    //     vm.startPrank(DAI_WHALE);
        
    //     IPaymentGateway.PaymentData[] memory payments = IPaymentGateway(paymentGateway).getPaymentsQueue(DAI_WHALE);
    //     require(payments.length > 0, "No payments found");
    //     uint256 amountReceived = payments[0].amountPaid;
        
    //     IPayee(client).claimPayment(
    //         DAI_WHALE,
    //         ETH_WHALE,
    //         amountReceived,
    //         ETH_WHALE
    //     );
    //     vm.stopPrank();
    // }

    function test__fuzz__mustPayAndClaimForPYUSD(uint256 _amountToPay) external {
        // NOTE: PYUSD payments (same token as target)
        uint256 amountToPay = bound(_amountToPay, 1e6, 1000000e6); // 1 PYUSD to 1M PYUSD

        vm.startPrank(PYUSD_WHALE);
        
        // Check balances before payment
        uint256 balanceBeforePaymentPYUSD = IERC20(PYUSD).balanceOf(PYUSD_WHALE);
        address treasury = IPaymentGateway(paymentGateway).getTreasury();
        uint256 balanceBeforePaymentTargetToken = treasury != address(0x00) ? IEVault(treasury).balanceOf(address(paymentGateway)) : uint256(0x00);
        
        // Ensure PYUSD_WHALE has enough balance
        require(balanceBeforePaymentPYUSD >= amountToPay, "Insufficient PYUSD balance");
        
        IERC20(PYUSD).approve(address(paymentGateway), amountToPay);
        IPayer(client).pay(
            PYUSD_WHALE,
            PYUSD,
            amountToPay,
            ETH_WHALE,
            new address[](0),
            new bytes[](0),
            new uint256[](0)
        );

        // Check balances after payment
        uint256 balanceAfterPaymentPYUSD = IERC20(PYUSD).balanceOf(PYUSD_WHALE);
        address updatedTreasury = IPaymentGateway(paymentGateway).getTreasury();
        uint256 balanceAfterPaymentTargetToken = IEVault(updatedTreasury).balanceOf(address(paymentGateway));

        // Verify PYUSD balance decreased correctly
        assertEq(balanceAfterPaymentPYUSD, balanceBeforePaymentPYUSD - amountToPay);
        
        // Verify target token balance increased (payment was processed)
        uint256 payedAmount = balanceAfterPaymentTargetToken - balanceBeforePaymentTargetToken;
        assertGt(payedAmount, 0);

        vm.stopPrank();

        vm.startPrank(ETH_WHALE);
        
        IPaymentGateway.PaymentData[] memory payments = IPaymentGateway(paymentGateway).getPaymentsQueue(ETH_WHALE);
        require(payments.length > 0, "No payments found");
        uint256 amountReceived = payments[0].amountPaid;
        
        IPayee(client).claimPayment(
            ETH_WHALE,
            PYUSD_WHALE,
            amountReceived,
            ETH_WHALE
        );
        vm.stopPrank();

    }


}
