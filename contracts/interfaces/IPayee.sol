// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


interface IPayee {
    
    event PaymentClaimed(
        address indexed sender,
        address indexed payee,
        address indexed destination,
        uint256 amountReceived
    );

    function claimPayment(
        address payee,
        address payer,
        uint256 amount,
        address destination
    ) external;

    


    function hasQueuedPayments(
        address payee
    ) external view returns (bool);




}