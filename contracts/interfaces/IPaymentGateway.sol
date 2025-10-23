// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


interface IPaymentGateway {


    error InsufficientBalance();

    function processPayment(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        bytes32 recipientId
    ) external returns(bytes[] memory res);

    function setUnitOfAccount(address _unitOfAccount) external;

    function setEulerSwapFactory(
        address _eulerSwapFactory
    ) external;

    function setGenericFactory(
        address _genericFactory
    ) external;

    function setEscrowCollateralPerspective(
        address _escrowCollateralPerspective
    ) external;

    function setPyUSDCVault(
        address _pyUSDCVault
    ) external;

    function setEVC(address _evc) external;

}