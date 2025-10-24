// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IPaymentGateway} from "../contracts/interfaces/IPaymentGateway.sol";

import {ForkTest} from "../lib/evk-periphery/lib/euler-price-oracle/test/utils/ForkTest.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";

import {console2} from "forge-std/console2.sol";

import "./utils/ForkUtils.sol";
import "./utils/Deployers.sol";

import {PYTH,PYTH_DAI_USD_FEED,PYTH_USDC_USD_FEED} from "euler-price-oracle-test/adapter/pyth/PythFeeds.sol";
import {DAI, USDC, UNISWAP_V3_FACTORY} from "euler-price-oracle-test/utils/EthereumAddresses.sol";

import {IPaymentGateway} from "../contracts/interfaces/IPaymentGateway.sol";

contract PaymentGatewayForkTest is ForkTest, Deployers {

    address pyUsdcVault;
    function setUp() public {
        _setUpFork(23626800);


        deployUniswapV3Oracle();
        deployChainOracleAndSetAll(
            PYUSDC,
            USD,
            USDC,
            PYTH_USDC_USD_FEED,
            uniswapV3Oracle,
            ORACLE_LENS,
            PYTH
        );

        deployPaymentGatewayAndSetAll(chainPriceOracle);
        pyUsdcVault = deploypyUSDCVault(
            EVC,
            address(this),
            uint256(0x00),
            chainPriceOracle,
            PYUSDC,
            USDC  
        );


        IPaymentGateway(paymentGateway).setPyUSDCVault(pyUsdcVault);
    
    }

    function test__unit__processPayment__mustCreateNewVaultForNewPaymentToken() external {
        vm.startPrank(DAI_WHALE);

        IERC20(DAI).approve(address(paymentGateway), DEFAULT_PAYMENT_AMOUNT*DECIMAL_OFFSET);
        
        IEthereumVaultConnector(EVC).setAccountOperator(
            DAI_WHALE,
            paymentGateway,
            true
        );

        IEthereumVaultConnector(payable(EVC)).call(
            address(paymentGateway),
            DAI_WHALE,
            uint256(0x00),
            abi.encodeCall(
                IPaymentGateway.processPayment,
                (
                    DAI_WHALE,
                    DAI,
                    DEFAULT_PAYMENT_AMOUNT*DECIMAL_OFFSET,
                    bytes32(uint256(uint160(address(this))))                )
            )
        );
        

        vm.stopPrank();





    }
}
