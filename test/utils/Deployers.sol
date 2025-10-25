// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;



import {Test} from "forge-std/Test.sol";

import {PaymentGateway} from "../../contracts/PaymentGateway.sol";
import {ChainPriceOracle} from "../../contracts/ChainPriceOracle.sol";
import {UniswapV3Oracle} from "euler-price-oracle/adapter/uniswap/UniswapV3Oracle.sol";
import {PayerClient} from "../../contracts/PayerClient.sol";
import {IChainPriceOracle} from "../../contracts/interfaces/IChainPriceOracle.sol";
import {IPaymentGateway} from "../../contracts/interfaces/IPaymentGateway.sol";
import "./ForkUtils.sol";
import "euler-price-oracle-test/adapter/pyth/PythFeeds.sol";
import "euler-price-oracle-test/utils/EthereumAddresses.sol";
import {GenericFactory} from "../../lib/euler-vault-kit/test/unit/evault/EVaultTestBase.t.sol";
import {IEthereumVaultConnector} from "euler-interfaces/IEthereumVaultConnector.sol";

contract Deployers is Test {

    address uniswapV3Oracle;
    address chainPriceOracle;
    address paymentGateway;
    address payerClient;

    function deployUniswapV3Oracle() public {
        uniswapV3Oracle = address(new UniswapV3Oracle(USDC, PYUSDC, 100, 15 minutes, UNISWAP_V3_FACTORY));
    }

    function deployChainPriceOracle() public {
        chainPriceOracle = address(new ChainPriceOracle());
    }

    function deployChainOracleAndSetAll(
        address _PYUSDC,
        address _USD,
        address _USDC,
        bytes32 _PYTH_USDC_USD_FEED,
        address _uniswapV3Oracle,
        address _oracleLens,
        address _pyth

    ) public {
        deployChainPriceOracle();
        IChainPriceOracle(chainPriceOracle).setPaymentToken(PYUSDC);
        IChainPriceOracle(chainPriceOracle).setUnitOfAccount(USD);
        IChainPriceOracle(chainPriceOracle).setUnitOfAccountToken(USDC);
        IChainPriceOracle(chainPriceOracle).setUnitOfAccountTokenFeedId(PYTH_USDC_USD_FEED);
        IChainPriceOracle(chainPriceOracle).setPaymentOracle(uniswapV3Oracle);
        IChainPriceOracle(chainPriceOracle).setOracleLens(ORACLE_LENS);
        IChainPriceOracle(chainPriceOracle).setPyth(PYTH);

    }

    function deployPaymentGatewayAndSetAll() internal {
        paymentGateway = address(new PaymentGateway(EVAULT_IMPLEMENTATION, PYUSDC, EVC, EVAULT_FACTORY));
        IPaymentGateway(paymentGateway).setGenericFactory(EVAULT_FACTORY);
        IPaymentGateway(paymentGateway).setEscrowCollateralPerspective(
            ESCROWED_COLLATERAL_PERSPECTIVE
        );
        IPaymentGateway(paymentGateway).setChainPriceOracle(chainPriceOracle);
        IPaymentGateway(paymentGateway).setUnitOfAccount(USDC);

    }

    function deployPayerClient(address _PYUSDC, address _paymentGateway) internal {
        payerClient = address(new PayerClient(_PYUSDC, _paymentGateway));
    }

        




}