// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IPayer} from "../interfaces/IPayer.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {
    PayPalOnChainApi,
    Multicaller
} from "../PayPalOnChainApi.sol";


abstract contract PayerBase is IPayer {
    address public immutable PYUSDC;

    address public paypalOnChainApi;

    constructor(
        address _PYUSDC,
    ) {
        PYUSDC = _PYUSDC;
    }

 
    function setPaypalOnChainApi(
        address _paypalOnChainApi
    ) external {
        paypalOnChainApi = _paypalOnChainApi;
    }

    function pay(
        address payer, // NOTE: It can be msg.sender or any other address
        address paymentToken,
        uint256 amountToPay,
        bytes32 recipientId,
        address[] calldata paypalOnChainEndpoints,
        bytes[] calldata frompyUSDCToPaypalContractCalls
        uint256[] calldata values
    ) external returns (
        uint256 paymentAmountPaidOnPYUSDC,
        bytes[] memory results
    ) {
        uint256 _beforePaymentPayerBalance = IERC20(PYUSDC).balanceOf(
            payer
        );

        paymentAmountOnPYUSDC = _pay(paymentToken, amountToPay, recipiantId);
        bool success = paymentAmountOnPYUSDC > uint256(0x00) && IERC20(PYUSDC).balanceOf(payer) - _beforePaymentPayerBalance >= paymentAmountOnPYUSDC;
        
        if (success) {
            bytes[] memory results = Multicaller(paypalOnChainApi).aggregate(
                paypalOnChainEndpoints,
                frompyUSDCToPaypalContractCalls
                values,
                payable(payer)
            );
            emit Payment(
                payer,
                paymentToken,
                recipientId,
                amountPaidOnPYUSDC,
                bytes("") // NOTE: This is a placeholder
            );

        }

        return (success, amountPaidOnPYUSDC, results);
    }


    function _pay(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        bytes32 recipiantId
    )internal  virtual returns (uint256 paymentAmountOnPYUSDC) {
        // NOTE: Here the calls until we reach the payment amount on PYUSDC
        uint256 _paymentAmountOnPYUSDC;
        paymentAmountOnPYUSDC = _paymentAmountOnPYUSDC;

    }
}