// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


interface IPayee {
    
    event PaymentReceived(
        address indexed sender,
        uint256 amountReceived
    );

    function receivePayment(
        bytes32 recipientId
    ) external;

    function setPayee(
        bytes32 recipientId,
        address payee
    ) external;


}