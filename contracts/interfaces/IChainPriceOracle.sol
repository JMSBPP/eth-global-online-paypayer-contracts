// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IPriceOracle} from "euler-vault-kit/src/interfaces/IPriceOracle.sol";


interface IChainPriceOracle is IPriceOracle{

    function getPaymentToken() external view returns (address);
    function getUnitOfAccount() external view returns (address);
    function getUnitOfAccountToken() external view returns (address);
    function getUnitOfAccountTokenFeedId() external view returns (bytes32);
    function getPaymentOracle() external view returns (address);
    function getOracleLens() external view returns (address);

    function setPaymentToken(address _paymentToken) external;

    function setUnitOfAccount(address _unitOfAccount) external;

    function setUnitOfAccountToken(address _unitOfAccountToken) external;

    function setUnitOfAccountTokenFeedId(bytes32 _unitOfAccountTokenFeedId) external;

    function setPaymentOracle(address _paymentOracle) external;

    function setPyth(address _pyth) external;

    function setOracleLens(address _oracleLens) external;
    

}