// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


import {IPaymentGateway} from "./interfaces/IPaymentGateway.sol";
import {IChainPriceOracle} from "./interfaces/IChainPriceOracle.sol";


contract PaymentGateway is IPaymentGateway{
    
    address chainPriceOracle;
    address unitOfAccount;

    constructor(address _chainPriceOracle){
        chainPriceOracle = _chainPriceOracle;
    }

    function setUnitOfAccount(address _unitOfAccount) external{
        unitOfAccount = _unitOfAccount;
    }

    
    // NOTE: This is the main fucntion
    function processPayment(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        bytes32 recipientId
    ) external returns(bytes[] memory res){
        uint256 amountToPaypyUSDC = IChainPriceOracle(chainPriceOracle).getQuote(
            amountToPay,
            paymentToken,
            unitOfAccount
        );


    }
}