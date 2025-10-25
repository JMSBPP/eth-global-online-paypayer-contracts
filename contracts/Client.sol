// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IPayer} from "./interfaces/IPayer.sol";
import {IPayee} from "./interfaces/IPayee.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {
    PayPalOnChainApi,
    Multicaller
} from "./PayPalOnChainApi.sol";

import {IEulerRouter} from "euler-interfaces/IEulerRouter.sol";

import {IPaymentGateway} from "./interfaces/IPaymentGateway.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract Client is IPayer, IPayee, AccessControl {
    


    mapping(bytes32 => address) public payees;


    address public paypalOnChainApi;
    address public paymentGateway;



    error PayeeNotSet();

    constructor(
        address _paymentGateway
    
    ) {
        paymentGateway = _paymentGateway;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }


 
    function setPaypalOnChainApi(
        address _paypalOnChainApi
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paypalOnChainApi = _paypalOnChainApi;
    }

    function setPayee(
        bytes32 recipientId,
        address payee
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        payees[recipientId] = payee;
    }

    function getPayee(
        bytes32 recipientId
    ) external view returns (address) {
        return payees[recipientId];
    }


    function pay(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        bytes32 recipientId, // NOTE: It can be msg.sender or any other addres
        address[] calldata paypalOnChainEndpoints,
        bytes[] calldata frompyUSDCToPaypalContractCalls,
        uint256[] calldata values        
       
    ) external {

        if (payees[recipientId] == address(0)) {
            revert PayeeNotSet();
        }



        uint256 amountReceivedForPaymentOnPyUSDC = IPaymentGateway(paymentGateway).processPayment(
            payer,
            paymentToken,
            amountToPay,
            recipientId
        );


        emit Payment(
            payer,
            paymentToken,
            recipientId,
            amountReceivedForPaymentOnPyUSDC,
            bytes("") // NOTE: This is a placeholder
        );

    }

    function receivePayment(
        bytes32 recipientId
    ) external {

        address payee = payees[recipientId];
        IEVault(payee).withdraw(
            amountReceivedForPaymentOnPyUSDC,
            payee,
            paymentGateway
        );

        emit PaymentReceived(payer, amountReceivedForPaymentOnPyUSDC);
    }




}