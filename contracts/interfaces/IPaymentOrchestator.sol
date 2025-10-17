// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


// NOTE: This contract requests the flashloan
// And needs to enable to query the price
interface IPaymentOrchestator{
    
    function orchestate_payment(
        bytes[] calldata dataOnPayment
    ) external returns(bytes memory paymentResData);
}