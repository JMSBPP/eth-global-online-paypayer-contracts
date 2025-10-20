// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

interface IPayer {
    struct OracleCalldata{
        bytes32 feedId;
        bytes[] additionalData;
    }

    struct PaymentCalldata{
        address payer;
        address paymentToken;
        uint256 amountToPay;
        bytes32 recipientId; // NOTE: It can be msg.sender or any other addres
    }

    // NOTE: This is data for the after hvaing pyUSDC balance
    // make payment flow to paypal API
        

    struct PayCalldata{
        address[] paypalOnChainEndpoints;
        bytes[] frompyUSDCToPaypalContractCalls;
        uint256[] values;        
    }

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
        PaymentCalldata calldata paymentCalldata,
        OracleCalldata calldata oracleCalldata,
        PayCalldata calldata payCalldata
    ) external returns (
        uint256 paymentAmountPaidOnPYUSDC,
        bytes[] memory results
    );
}