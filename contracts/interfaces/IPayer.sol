// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

interface IPayer {
    

    // NOTE: Other data can be added, this is to be determined depeding on the events we need to
    //index for client

    event Payment(
        address indexed sender,
        address indexed paymentToken,
        address indexed payee,
        uint256 amountPaid,
        bytes additionalData
    );
    
    
    function pay(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        address payee, // NOTE: It can be msg.sender or any other addres
        address[] calldata paypalOnChainEndpoints,
        bytes[] calldata frompyUSDCToPaypalContractCalls,
        uint256[] calldata values        
    ) external payable;
}