// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;



import {Test} from "forge-std/Test.sol";

import {PaymentGateway} from "../../contracts/PaymentGateway.sol";
import {ChainPriceOracle} from "../../contracts/ChainPriceOracle.sol";
import {UniswapV3Oracle} from "euler-price-oracle/adapter/uniswap/UniswapV3Oracle.sol";
import {Client} from "../../contracts/Client.sol";
import {IChainPriceOracle} from "../../contracts/interfaces/IChainPriceOracle.sol";
import {IPaymentGateway} from "../../contracts/interfaces/IPaymentGateway.sol";
import {IEVault} from "euler-interfaces/IEVault.sol";
import {IEscrowedCollateralPerspective} from "euler-interfaces/IEscrowedCollateralPerspective.sol";

import "./ForkUtils.sol";
import "euler-price-oracle-test/adapter/pyth/PythFeeds.sol";
import "euler-price-oracle-test/utils/EthereumAddresses.sol";
import {GenericFactory} from "../../lib/euler-vault-kit/test/unit/evault/EVaultTestBase.t.sol";
import {IEthereumVaultConnector} from "euler-interfaces/IEthereumVaultConnector.sol";

contract Deployers is Test {

    address uniswapV3Oracle;
    address chainPriceOracle;
    address paymentGateway;
    address client;

    function deployUniswapV3Oracle() public {
        uniswapV3Oracle = address(new UniswapV3Oracle(USDC, PYUSD, 100, 15 minutes, UNISWAP_V3_FACTORY));
    }

    function deployChainPriceOracle() public {
        chainPriceOracle = address(new ChainPriceOracle());
    }

    function deployChainOracleAndSetAll(
        address _PYUSD,
        address _USD,
        address _USDC,
        bytes32 _PYTH_USDC_USD_FEED,
        address _uniswapV3Oracle,
        address _oracleLens,
        address _pyth

    ) public {
        deployChainPriceOracle();
        IChainPriceOracle(chainPriceOracle).setPaymentToken(_PYUSD);
        IChainPriceOracle(chainPriceOracle).setUnitOfAccount(USD);
        IChainPriceOracle(chainPriceOracle).setUnitOfAccountToken(USDC);
        IChainPriceOracle(chainPriceOracle).setUnitOfAccountTokenFeedId(PYTH_USDC_USD_FEED);
        IChainPriceOracle(chainPriceOracle).setPaymentOracle(uniswapV3Oracle);
        IChainPriceOracle(chainPriceOracle).setOracleLens(ORACLE_LENS);
        IChainPriceOracle(chainPriceOracle).setPyth(PYTH);

    }

    function deployEVault(address _underlyingToken) internal returns (address) {
        address eVault = GenericFactory(EVAULT_FACTORY).createProxy(
                    address(0),
                    true,
                    abi.encodePacked(
                        _underlyingToken,
                        address(0), // Escrow vaults must not have oracle
                        address(0)  // Escrow vaults must not have unit of account
                    )
             );

             // NOTE: Escrow vaults must not have hook targets
             {
                IEVault(eVault).setHookConfig(address(0x00), 0);
                IEVault(eVault).setInterestRateModel(address(0x00));
                IEVault(eVault).setFeeReceiver(address(0x00));
                IEVault(eVault).setCaps(0, 0);
                IEVault(eVault).setConfigFlags(0);
                IEVault(eVault).setMaxLiquidationDiscount(0);
                IEVault(eVault).setLiquidationCoolOffTime(0);
                IEVault(eVault).setGovernorAdmin(address(0x00));
             }

             IEscrowedCollateralPerspective(
                ESCROWED_COLLATERAL_PERSPECTIVE
             ).perspectiveVerify(eVault, false);

             return eVault;

    }

    function deployPaymentGatewayAndSetAll() internal {
        paymentGateway = address(
            new PaymentGateway(
                EVAULT_IMPLEMENTATION,
                PYUSD,
                EVC,
                EVAULT_FACTORY,
                UNISWAP_V3_SWAP_ROUTER,
                UNISWAP_V3_QUOTER,
                ESCROWED_COLLATERAL_PERSPECTIVE,
                WETH
            )
        );

        IPaymentGateway(paymentGateway).setChainPriceOracle(chainPriceOracle);
        IPaymentGateway(paymentGateway).setUnitOfAccount(USDC);

    }

    function deployClient() internal {
        client = address(new Client(paymentGateway));
        IPaymentGateway(paymentGateway).setPaymentClient(client);
    }

        




}