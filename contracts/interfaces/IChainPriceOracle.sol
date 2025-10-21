// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IPriceOracle} from "euler-interfaces/interfaces/IPriceOracle.sol";


interface IChainPriceOracle is IPriceOracle{

    fucntion setPaymentToken(address _paymentToken) external;

    function setUnitOfAccount(address _unitOfAccount) external;
    
}