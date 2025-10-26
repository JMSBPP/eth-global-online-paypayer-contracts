// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";
import {IPayer} from "../contracts/interfaces/IPayer.sol";
import {IPayee} from "../contracts/interfaces/IPayee.sol";

import "euler-price-oracle-test/utils/EthereumAddresses.sol";
import "../test/utils/ForkUtils.sol";

contract EthereumPayments is Script{


    function run() public{
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        address deployerAddress = vm.rememberKey(deployerKey);
        address client = DevOpsTools.get_most_recent_deployment("Client", block.chainid, "./broadcast/Deployments.s.sol/1");
        vm.startBroadcast(deployerAddress);


        IPayer(client).pay{value : 7e14}(
            deployerAddress,
            ETH,
            1e14,
            deployerAddress,
            new address[](0),
            new bytes[](0),
            new uint256[](0)
        );

        vm.stopBroadcast();

        vm.startPrank(deployerAddress);

        IPayee(client).claimPayment(
            deployerAddress,
            deployerAddress,
            1e14,
            deployerAddress
        );

        vm.stopBroadcast();

    }


}