// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IPriceOracle} from "euler-vault-kit/src/interfaces/IPriceOracle.sol";


interface IChainPriceOracle is IPriceOracle{

    function setPaymentToken(address _paymentToken) external;

    function setUnitOfAccount(address _unitOfAccount) external;

    function setUnitOfAccountToken(address _unitOfAccountToken) external;

    function setUnitOfAccountTokenOracle(address _unitOfAccountTokenOracle) external;

    function setPaymentOracle(address _paymentOracle) external;


    function setOracleLens(address _oracleLens) external;
    

}