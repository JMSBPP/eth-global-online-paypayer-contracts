// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import "euler-price-oracle-test/adapter/pyth/PythFeeds.sol";
import "euler-price-oracle-test/utils/EthereumAddresses.sol";
import "../test/utils/ForkUtils.sol";
import "../test/utils/Deployers.sol";
import {Client} from "../contracts/Client.sol";
import {PaymentGateway} from "../contracts/PaymentGateway.sol";
import {ChainPriceOracle} from "../contracts/ChainPriceOracle.sol";





contract EthereumDeployments is Script, Deployers {

    function run() public {
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.rememberKey(deployerKey);
        vm.startBroadcast(deployerAddress);

        deployUniswapV3Oracle();
        deployChainPriceOracle();
        deployChainOracleAndSetAll(
            PYUSD,
            USD,
            USDC,
            PYTH_USDC_USD_FEED,
            uniswapV3Oracle,
            ORACLE_LENS,
            PYTH
        );
        deployPaymentGatewayAndSetAll();
        deployClient();

        vm.stopBroadcast();

    }





}