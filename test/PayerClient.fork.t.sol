// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {PayerClient} from "../contracts/PayerClient.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";


import {ForkTest} from "../lib/evk-periphery/lib/euler-price-oracle/test/utils/ForkTest.sol";

import {OracleLens} from "evk-periphery/src/Lens/OracleLens.sol";



import {IPayer} from "../contracts/interfaces/IPayer.sol";

import {IPaymentGateway} from "../contracts/interfaces/IPaymentGateway.sol";


import {console} from "forge-std/console.sol";
import {Deployers} from "./utils/Deployers.sol";


import "./utils/ForkUtils.sol";

contract PayerClientForkTest is ForkTest , Deployers {

    bytes32 recipientId;

    PayPalOnChainData EMPTY_DATA;

    function setUp() public {

        _setUpFork(23626800);
        
        recipientId = bytes32(uint256(uint160(address(this))));
        
        EMPTY_DATA.paypalOnChainEndpoints = new address[](0);
        EMPTY_DATA.frompyUSDCToPaypalContractCalls = new bytes[](0);
        EMPTY_DATA.values = new uint256[](0);

    }


    // function test__pay__mustFetchValidQuote() external {

    //     vm.startPrank(DAI_WHALE);

    //     IPayer(payerClient).pay(
    //         DAI_WHALE,
    //         DAI,
    //         2500e6,
    //         recipientId,
    //         EMPTY_DATA.paypalOnChainEndpoints,
    //         EMPTY_DATA.frompyUSDCToPaypalContractCalls,
    //         EMPTY_DATA.values
    //     );
    //     vm.stopPrank();

    // }






}