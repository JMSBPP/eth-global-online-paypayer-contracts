// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

interface IPayer {
    
    // NOTE: Other data can be added, this is to be determined depeding on the events we need to
    //index for client

    event Payment(
        address indexed sender,
        address indexed paymentToken,
        bytes32 indexed recipiantId,
        uint256 amountPaid,
        bytes additionalData
    );
    
    

    function pay(
        address payer,
        address paymentToken,
        uint256  amountToPay,
        bytes32  recipiantId, // NOTE:  This can be an address or an id of paypal receivers
        address[] calldata paypalOnChainEndpoints,
        bytes[] calldata frompyUSDCToPaypalContractCalls
        uint256[] calldata values
    ) external returns (
        uint256 paymentAmountPaidOnPYUSDC,
        bytes[] memory results
    );
}