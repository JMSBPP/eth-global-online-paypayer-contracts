// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


import {IChainPriceOracle} from "./interfaces/IChainPriceOracle.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SnapshotRegistry} from "evk-periphery/src/SnapshotRegistry.sol";
contract ChainPriceOracle is IChainPriceOracle {
    using Address for address;

    struct ConversionStep{
        address inToken;
        address outToken;
        addres pairOracle;
        bytes32 feedId;
    }

    struct Chain{
        ConversionStep[0x02] steps;
    }


    address public paymentToken;
    address public paymentOracle;
    address public unitOfAccount;


    address public oracleRegistry;

    Chain private chain;

 


    function setPaymentToken(address _paymentToken) external{
        paymentToken = _paymentToken;
    }

    function setUnitOfAccount(address _unitOfAccount) external{
        unitOfAccount = _unitOfAccount;
    }

    function setPaymentOracle(address _paymentOracle) external{
        paymentOracle = _paymentOracle;
    }



 
    function setOracleRegistry(address _oracleRegistry) external{
        oracleRegistry = _oracleRegistry;
    }

    // NOTE: This function validates incoming token
    // quotability




    
    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount){
        if (paymentOracle == address(0x00)) revert ("Payment Oracle Not set");
        address baseOracle =  _validateAndGetBaseTokenOracle(base);
        uint256 amountOutUnitOfAccount = IPriceOracle(baseOracle).getQuote(
             inAmount,
             base,
             unitOfAccount
        );

       outAmount = IPriceOracle(paymentOracle).getQuote(
            amountOutUnitOfAccount,
            unitOfAccount,
            paymentToken
       );
    }

    function _validateAndGetBaseTokenOracle(addres _base) private returns (address baseOracle){
        if (oracleRegistry == address(0x00)) revert("OracleRegistry not set");
        
        bytes memory encodedOracles =  oracleRegistry.functionStaticCall(
            abi.encodeCall(
                SnapshotRegistry.getValidAddresses,
                (_base, unitOfAccount, uint256(block.timestamp))
            )
        );

        address[] memory oraclesOnToken = new address[](encodedOracles.length);
        

        // NOTE: This is a placeholder
        return oraclesOnToken[0x01];


    }




}