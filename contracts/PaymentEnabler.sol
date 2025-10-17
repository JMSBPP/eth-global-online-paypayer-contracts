// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IPaymentOrchestator} from "./interfaces/IPaymentOrchestator.sol";
import {IPaymentEnabler} from "./interfaces/IPaymentEnabler.sol";

import "@pythnetwork/pyth-sdk-solidity/IPyth.sol";
import "@pythnetwork/pyth-sdk-solidity/PythStructs.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";
// NOTE: This contract 
abstract contract PaymentEnabler is IPaymentEnabler {
    
    // NOTE: There needs to be permit2 permissions for the flashloans
    // and addional verifications
    IPaymentOrchestator  paymentOrchestator;
    // TODO: This needs to be a interface for a valid oracle
    address oracle;



    mapping(bytes32 paymentId => address pool) paymentPools;

    constructor(
        IPaymentOrchestator _paymentOrchestator,
        address _oracle
    
    ) {
        paymentOrchestator = _paymentOrchestator;
        oracle = _oracle;
    }

    function pay(
        address to,
    )











    






}