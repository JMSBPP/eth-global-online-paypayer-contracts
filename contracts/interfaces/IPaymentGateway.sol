// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


interface IPaymentGateway {

    struct PaymentData{
        address payer;
        uint48 timeStamp;
        uint256 amountPaid;
        bool withdrawable;
    }




    error InsufficientBalance();

    error NoMarketFound();

    function processPayment(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        address payee
    ) external payable returns(uint256 amountReceivedForPaymentOnPyUSDC);

    function closePayment(
        address payee,
        address destination,
        uint256 index
    ) external;

    function setUnitOfAccount(address _unitOfAccount) external;

    function setPaymentClient(
        address _paymentClient
    ) external;



    function setChainPriceOracle(
        address _chainPriceOracle
    ) external;

    function getTreasury() external view returns (address);

    function getPaymentsQueue(
        address payee
    ) external view returns (PaymentData[] memory);

    function setTreasury(address _treasury) external;

}