// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


interface IPaymentGateway{
    
    function processPayment(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        bytes32 recipientId
    ) external returns(bytes[] memory res);

    function setUnitOfAccount(address _unitOfAccount) external;
}