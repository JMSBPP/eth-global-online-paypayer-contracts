// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface IPaymentEnabler {
    

    struct DataOnRouter{
        uint256 amountSpecified;
        bytes pyUSDPoolData; // 256 OR 160
        address token;
        bool tokenForPyUSD;
    }

    event Payed(
        bytes32 indexed paymentId,
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount // NOTE: Amount of pyUSD paid to payPal wallet owner
    ) anonymous;






    // NOTE: This function is COSTLY
    // Unless handled on try/call
    // iT will excecute payment
    function pay(
        bytes[] calldata dataOnOracle,
        bytes calldata dataOnRouter
    ) external;

    // NOTE: This function is not COSTLY

    function quote_payment(
        bytes[] calldata dataOnOracle,
        bytes calldata dataOnRouter
    ) external view returns(
        uint256 amount,
        uint256 effectivePrice, // NOTE: The price of the token relative to pyUSD only
        uint256 totalPrice // NOTE: The total cost of the payment (It includes swapFees + transactions costs (gas paid))
    );




}