// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


import {IChainPriceOracle} from "./interfaces/IChainPriceOracle.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IPriceOracle} from "euler-vault-kit/src/interfaces/IPriceOracle.sol";

// oracle = new MockPriceOracle(); -> TO DEPLOY/
// Uniswap V3 Oracle for pyUSDC and pyTh Oracle for others
// One can use he l

contract ChainPriceOracle is IChainPriceOracle {
    using Address for address;
    


    address public paymentToken;
    address public paymentOracle;
    address public unitOfAccount;
    address public unitOfAccountToken;
    address public unitOfAccountTokenOracle;

    address public oracleLens;


    function setPaymentToken(address _paymentToken) external{
        paymentToken = _paymentToken;
    }

    function setUnitOfAccount(address _unitOfAccount) external{
        unitOfAccount = _unitOfAccount;
    }

    function setUnitOfAccountToken(address _unitOfAccountToken) external{
        unitOfAccountToken = _unitOfAccountToken;
    }

    function setUnitOfAccountTokenOracle(address _unitOfAccountTokenOracle) external{
        unitOfAccountTokenOracle = _unitOfAccountTokenOracle;
    }



    function setPaymentOracle(address _paymentOracle) external{
        paymentOracle = _paymentOracle;
    }


    function setOracleLens(address _oracleLens) external{
        oracleLens = _oracleLens;
    }

    // NOTE: This function validates incoming token
    // quotability
    function name() external view returns (string memory){
        return "ChainPriceOracle";
    }

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount){
        // NOTE: In this case quote is USD which is not an actual token, we need the oracle USD/USDC
        address baseOracle =  _validateAndGetBaseTokenOracle(base);
        uint256 amountOutUnitOfAccount = IPriceOracle(baseOracle).getQuote(
             inAmount,
             base,
             unitOfAccount
        );

        uint256 amountOutUnitOfAccountToken = IPriceOracle(unitOfAccountTokenOracle).getQuote(
            amountOutUnitOfAccount,
            unitOfAccount,
            unitOfAccountToken
        );

       outAmount = IPriceOracle(paymentOracle).getQuote(
            amountOutUnitOfAccountToken,
            unitOfAccountToken,
            paymentToken
       );
    }

    function _validateAndGetBaseTokenOracle(address _base) private view returns (address baseOracle){
        
        bytes memory encodedOracles =  oracleLens.functionStaticCall(
            abi.encodeWithSignature("getValidAdapters(address,address)", _base, unitOfAccount)
        );
        address[] memory oraclesOnToken = abi.decode(encodedOracles, (address[]));
        // NOTE: This is a placeholder
        return oraclesOnToken[0x00];

    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256 bid, uint256 ask){}





}