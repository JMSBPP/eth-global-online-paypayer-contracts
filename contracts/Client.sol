// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IPayer} from "./interfaces/IPayer.sol";
import {IPayee} from "./interfaces/IPayee.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {IPaymentGateway} from "./interfaces/IPaymentGateway.sol";

contract Client is IPayer, IPayee {


    address public paymentGateway;



    error PayeeNotSet();
    error NoPaymentsQueued();
    error NoPaymentFound();

    constructor(
        address _paymentGateway
    
    ) {
        paymentGateway = _paymentGateway;
    }





    function pay(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        address payee, // NOTE: It can be msg.sender or any other addres
        address[] calldata paypalOnChainEndpoints,
        bytes[] calldata frompyUSDCToPaypalContractCalls,
        uint256[] calldata values               
    ) external payable {



        uint256 amountReceivedForPaymentOnPyUSDC = IPaymentGateway(paymentGateway).processPayment{value : msg.value}(
            payer,
            paymentToken,
            amountToPay,
            payee
        );


        emit Payment(
            payer,
            paymentToken,
            payee,
            amountReceivedForPaymentOnPyUSDC,
            bytes("") // NOTE: This is a placeholder
        );

    }

    function hasQueuedPayments(
        address payee
    ) external view returns (bool) {
        return _hasQueuedPayments(payee);
    }

    function _hasQueuedPayments(
        address payee
    ) internal view returns (bool) {
        IPaymentGateway.PaymentData[] memory payments = IPaymentGateway(paymentGateway).getPaymentsQueue(payee);
        return payments.length > 0;

    }



    function claimPayment(
        address payee,
        address payer,
        uint256 amount,
        address destination
    ) external {
        
        if (!_hasQueuedPayments(payee)) {
            revert NoPaymentsQueued();
        }


        IPaymentGateway.PaymentData[] memory payments = IPaymentGateway(paymentGateway).getPaymentsQueue(payee);
        

        bool found = false;
        for (uint256 i = 0; i < payments.length; i++) {
            if (payments[i].payer == payer && payments[i].amountPaid == amount) {               
                IPaymentGateway(
                    paymentGateway
                ).closePayment(
                    payee,
                    destination,
                    i
                );

                emit PaymentClaimed(
                    payer,
                    payee,
                    destination,
                    amount
                );

                found = true;
                break;
            }
        }

        if (!found) {
            revert NoPaymentFound();
        }


    }


}