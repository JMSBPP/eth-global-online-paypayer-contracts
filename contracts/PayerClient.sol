// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IPayer} from "./interfaces/IPayer.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {
    PayPalOnChainApi,
    Multicaller
} from "./PayPalOnChainApi.sol";

import {IEulerRouter} from "euler-interfaces/IEulerRouter.sol";

import {IPaymentGateway} from "./interfaces/IPaymentGateway.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract PayerClient is IPayer, AccessControl {
    address public immutable PYUSDC;
    


    address public paypalOnChainApi;
    address public paymentGateway;

    constructor(
        address _PYUSDC, // NOTE: Payment token
        address _paymentGateway
    
    ) {

        PYUSDC = _PYUSDC;
        paymentGateway = _paymentGateway;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }


 
    function setPaypalOnChainApi(
        address _paypalOnChainApi
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paypalOnChainApi = _paypalOnChainApi;
    }


    function pay(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        bytes32 recipientId, // NOTE: It can be msg.sender or any other addres
        address[] calldata paypalOnChainEndpoints,
        bytes[] calldata frompyUSDCToPaypalContractCalls,
        uint256[] calldata values        
       
    ) external returns (
        bytes[] memory results
    ) {
        uint256 _beforePaymentPayerBalance = IERC20(PYUSDC).balanceOf(
            payer
        );


        bytes[] memory partialRes = IPaymentGateway(paymentGateway).processPayment(
            payer,
            paymentToken,
            amountToPay,
            recipientId
        );


 
        // bool success = paymentAmountOnPYUSDC > uint256(0x00) && IERC20(PYUSDC).balanceOf(paymentCalldata.payer) - _beforePaymentPayerBalance >= paymentAmountOnPYUSDC;
        
        // if (success) {
        //     bytes[] memory _results = Multicaller(paypalOnChainApi).aggregate(
        //         paypalOnChainEndpoints,
        //         frompyUSDCToPaypalContractCalls,
        //         values,
        //         payable(payer)
        //     );
        //     emit Payment(
        //         payer,
        //         paymentToken,
        //         recipientId,
        //         paymentAmountOnPYUSDC,
        //         bytes("") // NOTE: This is a placeholder
        //     );

        // }

        bytes[] memory results = new bytes[](0);

        return results;
    }





}