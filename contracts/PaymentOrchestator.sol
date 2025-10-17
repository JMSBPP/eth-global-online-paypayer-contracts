// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IPaymentOrchestator} from "./interfaces/IPaymentOrchestator.sol";

import {IMorphoFlashLoanCallback} from "@morpho-blue/interfaces/IMorphoCallbacks.sol";

import {IBasePoolFactory} from "@balancer-labs/v3-interfaces/contracts/vault/IBasePoolFactory.sol";
import {IBatchRouter} from "@balancer-labs/v3-interfaces/contracts/vault/IBatchRouter.sol";

import {IPoolLiquidity} from "@balancer-labs/v3-interfaces/contracts/vault/IPoolLiquidity.sol";
import {Multicaller} from "@Multicaller/Multicaller.sol";

// NOTE: This requests a flash loan to some falh loan lender
// it needs to inherit the flah loan receiver

// NOTE: This also serves as a router for initializaring the flash
// pool and for the payment swap/liquidity flow


// NOTE: Pool Liquidity allows for flash liquidity operations to enable the swap

abstract contract PaymentOrchestator is 
    IPaymentOrchestator,
    IMorphoFlashLoanCallback,
    IPoolLiquidity,
    Multicaller
{
    
    
    // NOTE: This allows to create the flash pool
    IBasePoolFactory basePoolFactory;
    // NOTE: This allows the trade token -> eth -> pySWAP
    IBatchRouter batchRouter;
    
    constructor(
        IBasePoolFactory _basePoolFactory,
        IBatchRouter _batchRouter
    )
    {
        basePoolFactory = _basePoolFactory;
        batchRouter = _batchRouter;
        basePoolFactory = _basePoolFactory;
    }

    
    // NOTE: Most of the function of this contract are protected
    // to be only called by the paymentEnabler



}
