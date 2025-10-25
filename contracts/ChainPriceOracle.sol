// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


import {IChainPriceOracle} from "./interfaces/IChainPriceOracle.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IPriceOracle} from "euler-vault-kit/src/interfaces/IPriceOracle.sol";
import {Errors} from "euler-price-oracle/adapter/BaseAdapter.sol";
import {PythStructs} from "@pyth/PythStructs.sol";
import {IPyth} from "@pyth/IPyth.sol";
import {ScaleUtils, Scale} from "euler-price-oracle/lib/ScaleUtils.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
// oracle = new MockPriceOracle(); -> TO DEPLOY/
// Uniswap V3 Oracle for pyUSDC and pyTh Oracle for others
// One can use he l

contract ChainPriceOracle is IChainPriceOracle {
    using Address for address;
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MAX_CONF_WIDTH = 300;
    


    address public paymentToken;
    address public paymentOracle;
    address public unitOfAccount;
    address public unitOfAccountToken;
    bytes32 public unitOfAccountTokenFeedId;
    address public pyth;


    address public oracleLens;

    function getPaymentToken() external view returns (address){
        return paymentToken;
    }

    function getUnitOfAccount() external view returns (address){
        return unitOfAccount;
    }

    function getUnitOfAccountToken() external view returns (address){
        return unitOfAccountToken;
    }

    function getUnitOfAccountTokenFeedId() external view returns (bytes32){
        return unitOfAccountTokenFeedId;
    }

    function getPaymentOracle() external view returns (address){
        return paymentOracle;
    }

    function getOracleLens() external view returns (address){
        return oracleLens;
    }


    function setPaymentToken(address _paymentToken) external{
        paymentToken = _paymentToken;
    }

    function setUnitOfAccount(address _unitOfAccount) external{
        unitOfAccount = _unitOfAccount;
    }

    function setUnitOfAccountToken(address _unitOfAccountToken) external{
        unitOfAccountToken = _unitOfAccountToken;
    }

    function setUnitOfAccountTokenFeedId(bytes32 _unitOfAccountTokenFeedId) external{
        unitOfAccountTokenFeedId = _unitOfAccountTokenFeedId;
    }

    function setPyth(address _pyth) external{
        pyth = _pyth;
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


    // NOTE: This is the version that is used by most clients since the quote 
    // token is known at all times 

    function getQuote(
        uint256 inAmount,
        address paymentToken
    ) external view returns (uint256 outAmount){
        (uint256 outAmountOfBase, uint256 outAmountOfUnitOfAccount) = _getQuote(inAmount, paymentToken);
        return outAmountOfBase;
    }

    function _getQuote(
        uint256 inAmount,
        address base
    ) internal view returns(uint256 outAmountOfBase, uint256 outAmountOfUnitOfAccount){
        bytes32 baseFeedId =  _validateAndGetBaseTokenFeedId(base);
        uint256 amountOutUnitOfAccount = _processQuote(baseFeedId, base, unitOfAccount, inAmount);
        uint256 amountOutUnitOfAccountToken = _processQuote(unitOfAccountTokenFeedId, unitOfAccount, unitOfAccountToken, amountOutUnitOfAccount);
        outAmountOfBase = IPriceOracle(paymentOracle).getQuote(
            amountOutUnitOfAccount,
            unitOfAccountToken,
            paymentToken
       );

       outAmountOfUnitOfAccount = amountOutUnitOfAccountToken;


    
    }

    // NOTE: This is the version that is required for the IPriceOracle interface

    function getQuote(uint256 inAmount, address base, address quote) external view returns (uint256 outAmount){
        return this.getQuote(inAmount, base);        
    }

    function _validateAndGetBaseTokenFeedId(address _base) private view returns (bytes32 baseFeedId) {
        bytes memory encodedOracles = oracleLens.functionStaticCall(
            abi.encodeWithSignature("getValidAdapters(address,address)", _base, unitOfAccount)
        );
        address[] memory oraclesOnToken = abi.decode(encodedOracles, (address[]));

        for (uint256 i = 0; i < oraclesOnToken.length; i++) {
            address adapter = oraclesOnToken[i];
            if (adapter == address(0)) break; // reached end of valid adapters without finding one
            
            (bool ok, bytes memory res) = adapter.staticcall(abi.encodeWithSignature("pyth()"));
            if (!ok) continue; 

            address adapterPyth = abi.decode(res, (address));
            if (adapterPyth != pyth) continue; 


            (bool okId, bytes memory resId) = adapter.staticcall(abi.encodeWithSignature("feedId()"));
            if (!okId || resId.length != 32) revert Errors.PriceOracle_InvalidConfiguration();
            baseFeedId = abi.decode(resId, (bytes32));
            return baseFeedId;
        }

        revert Errors.PriceOracle_NotSupported(_base, unitOfAccount);
    }

    function _getDecimals(address _asset) internal view returns (uint8){
        if (uint160(_asset) <= uint256(0xffffffff)) {
            return 18;
        } else {
            (bool success, bytes memory data) = _asset.staticcall(abi.encodeCall(IERC20.decimals, ()));
            return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
        }
    }

    function _processQuote(
        bytes32 feedId,
        address base,
        address quote,
        uint256 inAmount
    ) internal view returns(uint256 amountOut){
        bool inverse = ScaleUtils.getDirectionOrRevert(base, base,  unitOfAccount, unitOfAccount);
        
        PythStructs.Price memory $_1 = IPyth(pyth).getPriceUnsafe(feedId);
        
        if ($_1.price <= 0  || $_1.conf > uint64($_1.price) * MAX_CONF_WIDTH / BASIS_POINTS) revert Errors.PriceOracle_InvalidAnswer();
        
        uint256 marginPrice = uint256(uint64($_1.price));
        
        uint8 baseDecimals = _getDecimals(base);
        
        int8 feedExponent = int8(baseDecimals) - int8($_1.expo);

        uint8 quoteDecimals = _getDecimals(unitOfAccount);

        Scale scale;
        if (feedExponent > 0) {
            scale = ScaleUtils.from(quoteDecimals, uint8(feedExponent));
        } else {
            scale = ScaleUtils.from(quoteDecimals + uint8(-feedExponent), 0);
        }

        amountOut = ScaleUtils.calcOutAmount(inAmount, marginPrice, scale, inverse);

    }

    function getQuotes(uint256 inAmount, address base, address quote) external view returns (uint256 bid, uint256 ask){
        (uint256 outAmountOfBase, uint256 outAmountOfUnitOfAccount) = _getQuote(inAmount, base);
        bid = outAmountOfBase;
        ask = outAmountOfUnitOfAccount;
    }





}