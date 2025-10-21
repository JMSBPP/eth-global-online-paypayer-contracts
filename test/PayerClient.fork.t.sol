// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {PayerClient} from "../contracts/PayerClient.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";


import {ForkTest} from "../lib/evk-periphery/lib/euler-price-oracle/test/utils/ForkTest.sol";
import {UniswapV3Oracle} from "euler-price-oracle/adapter/uniswap/UniswapV3Oracle.sol";
import {PythOracle} from "euler-price-oracle/adapter/pyth/PythOracle.sol";

import {DAI, USDC, UNISWAP_V3_FACTORY} from "euler-price-oracle-test/utils/EthereumAddresses.sol";

import {OracleLens} from "evk-periphery/src/Lens/OracleLens.sol";


import {ChainPriceOracle} from "../contracts/ChainPriceOracle.sol";
import {IChainPriceOracle} from "../contracts/interfaces/IChainPriceOracle.sol";

import {PayerClient} from "../contracts/PayerClient.sol";
import {IPayer} from "../contracts/interfaces/IPayer.sol";

import {PaymentGateway} from "../contracts/PaymentGateway.sol";
import {IPaymentGateway} from "../contracts/interfaces/IPaymentGateway.sol";

import {PythStructs} from "@pyth/PythStructs.sol";
import {IPyth} from "@pyth/IPyth.sol";

import { PYTH,PYTH_DAI_USD_FEED,PYTH_USDC_USD_FEED} from "euler-price-oracle-test/adapter/pyth/PythFeeds.sol";

struct PayPalOnChainData{
    address[] paypalOnChainEndpoints;
    bytes[] frompyUSDCToPaypalContractCalls;
    uint256[] values;
}


contract PayerClientForkTest is ForkTest {
    address constant PYUSDC = address(0x6c3ea9036406852006290770BEdFcAbA0e23A0e8);
    
    address constant ORACLE_LENS = address(0x30E6dFB84782A31d561536f64F47231451F7b48A);
    // NOTE: This is a pyth oracle for Aave USDC
    address constant DAI_USD_ORACLE = address(0x4E33D9874EbB7847C9C11E47aEEa8D3F215bF676);
    address constant USDC_USD_ORACLE = address(0xC039229EBCef32f898031eB81f646880F39a190B);
    address constant USD = address(0x0000000000000000000000000000000000000348);
    
    address constant DAI_WHALE = address(0x837c20D568Dfcd35E74E5CC0B8030f9Cebe10A28);





    address uniswapV3Oracle;

    address chainPriceOracle;
    address paymentGateway;
    address payerClient;
    bytes32 recipientId;

    PayPalOnChainData EMPTY_DATA;






    function setUp() public {
        _setUpFork(23628283);
        UniswapV3Oracle _uniswapV3Oracle = new UniswapV3Oracle(USDC, PYUSDC, 100, 15 minutes, UNISWAP_V3_FACTORY);
        uniswapV3Oracle = address(_uniswapV3Oracle);
        ChainPriceOracle _chainPriceOracle = new ChainPriceOracle();
        chainPriceOracle = address(_chainPriceOracle);
        PaymentGateway _paymentGateway = new PaymentGateway(chainPriceOracle);
        paymentGateway = address(_paymentGateway);
        PayerClient _payerClient = new PayerClient(PYUSDC, paymentGateway);
        payerClient = address(_payerClient);

        recipientId = bytes32(uint256(uint160(address(this))));
        
        EMPTY_DATA.paypalOnChainEndpoints = new address[](0);
        EMPTY_DATA.frompyUSDCToPaypalContractCalls = new bytes[](0);
        EMPTY_DATA.values = new uint256[](0);

        IChainPriceOracle(chainPriceOracle).setPaymentToken(PYUSDC);
        IChainPriceOracle(chainPriceOracle).setUnitOfAccount(USD);
        IChainPriceOracle(chainPriceOracle).setUnitOfAccountToken(USDC);
        IChainPriceOracle(chainPriceOracle).setUnitOfAccountTokenOracle(USDC_USD_ORACLE);
        IChainPriceOracle(chainPriceOracle).setPaymentOracle(uniswapV3Oracle);
        IChainPriceOracle(chainPriceOracle).setOracleLens(ORACLE_LENS);

        IPaymentGateway(paymentGateway).setUnitOfAccount(USD);



    }


    function test__pay__mustFetchValidQuote() external {
        
        PythStructs.Price memory $_1 = IPyth(PYTH).getPriceUnsafe(
            PYTH_DAI_USD_FEED
        );

        $_1.publishTime = block.timestamp - 5 minutes;
        PythStructs.Price memory $_2 = IPyth(PYTH).getPriceUnsafe(
            PYTH_USDC_USD_FEED
        );

        $_2.publishTime = block.timestamp - 5 minutes;
        vm.startPrank(DAI_WHALE);

        vm.mockCall(PYTH, abi.encodeCall(IPyth.getPriceUnsafe, (PYTH_DAI_USD_FEED)), abi.encode($_1));
        vm.mockCall(PYTH, abi.encodeCall(IPyth.getPriceUnsafe, (PYTH_USDC_USD_FEED)), abi.encode($_2));
        
        


        // IPayer(payerClient).pay(
        //     DAI_WHALE,
        //     DAI,
        //     2500e6,
        //     recipientId,
        //     EMPTY_DATA.paypalOnChainEndpoints,
        //     EMPTY_DATA.frompyUSDCToPaypalContractCalls,
        //     EMPTY_DATA.values
        // );
        vm.stopPrank();

    }






}