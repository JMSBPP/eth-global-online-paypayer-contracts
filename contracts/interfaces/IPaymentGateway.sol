// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


interface IPaymentGateway {


    error InsufficientBalance();

    error NoMarketFound();

    function processPayment(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        bytes32 recipientId
    ) external returns(uint256 amountReceivedForPaymentOnPyUSDC);

    function setUnitOfAccount(address _unitOfAccount) external;


    function setGenericFactory(
        address _genericFactory
    ) external;

    function setEscrowCollateralPerspective(
        address _escrowCollateralPerspective
    ) external;


    function setChainPriceOracle(
        address _chainPriceOracle
    ) external;

    





    

}