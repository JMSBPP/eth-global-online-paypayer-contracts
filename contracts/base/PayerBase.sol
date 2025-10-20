// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IPayer} from "../interfaces/IPayer.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {
    PayPalOnChainApi,
    Multicaller
} from "../PayPalOnChainApi.sol";

import {IEulerRouter} from "euler-interfaces/IEulerRouter.sol";

abstract contract PayerBase is IPayer {
   
    
    address public immutable PYUSDC;
    address public immutable UNIT_OF_ACCOUNT;
    address public immutable EVC;



    address public paypalOnChainApi;
    address public eulerRouter;

    constructor(
        address _PYUSDC, // NOTE: Payment token
        address unitOfAccount, // NOTE: Unist of account, USDC by defualt
        address _evc // NOTE: vault connector
    ) {

        PYUSDC = _PYUSDC;
        UNIT_OF_ACCOUNT = unitOfAccount;
        EVC = _evc;
    }

    function setRouter(
        address _eulerRouter
    ) external {
        eulerRouter = _eulerRouter;
    }

 
    function setPaypalOnChainApi(
        address _paypalOnChainApi
    ) external {
        paypalOnChainApi = _paypalOnChainApi;
    }


    function pay(
        PaymentCalldata calldata paymentCalldata,
        OracleCalldata calldata oracleCalldata,
        PayCalldata calldata payCalldata
    
    ) external returns (
        uint256 paymentAmountPaidOnPYUSDC,
        bytes[] memory results
    ) {
        uint256 _beforePaymentPayerBalance = IERC20(PYUSDC).balanceOf(
            paymentCalldata.payer
        );

        paymentAmountOnPYUSDC = _pay(
            paymentCalldata,
            oracleCalldata
        );

        bool success = paymentAmountOnPYUSDC > uint256(0x00) && IERC20(PYUSDC).balanceOf(paymentCalldata.payer) - _beforePaymentPayerBalance >= paymentAmountOnPYUSDC;
        
        if (success) {
            bytes[] memory _results = Multicaller(paypalOnChainApi).aggregate(
                payCalldata.paypalOnChainEndpoints,
                payCalldata.frompyUSDCToPaypalContractCalls,
                payCalldata.values,
                payable(paymentCalldata.payer)
            );
            emit Payment(
                paymentCalldata.payer,
                paymentCalldata.paymentToken,
                paymentCalldata.recipientId,
                paymentAmountOnPYUSDC,
                bytes("") // NOTE: This is a placeholder
            );

        }

        return (success, amountPaidOnPYUSDC, results);
    }


    function _pay(
        PaymentCalldata calldata paymentCalldata,
        OracleCalldata calldata oracleCalldata
    )internal  virtual returns (uint256 paymentAmountOnPYUSDC) {
        // NOTE: Here the calls until we reach the payment amount on PYUSDC

        // NOTE: The first thing is to check if the assset is quotable by the
        //price oracle, 
        uint256 quotedAmount = IEulerRouter(eulerRouter).getQuote(
            paymentCalldata.amountToPay,
            paymentCalldata.paymentToken,
            UNIT_OF_ACCOUNT
        );

        // NOTE: Now we have this quotedAmount on the unit of acocunt token
        // we send i


    }


}