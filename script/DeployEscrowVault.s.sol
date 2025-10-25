// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {Script, console2} from "forge-std/Script.sol";
import {Deployers} from "../test/utils/Deployers.sol";
import {IEVault} from "euler-interfaces/IEVault.sol";
import "euler-price-oracle-test/utils/EthereumAddresses.sol";

contract DeployEscrowVault is Script, Deployers {
    function run() external {
        vm.startBroadcast();
        
        // Deploy escrow vault for PYUSDC
        address pyUsdcVault = deployEVault(0x6c3ea9036406852006290770BEdFcAbA0e23A0e8);
        
        console2.log("Escrow Vault deployed at:", pyUsdcVault);
        console2.log("Vault asset:", IEVault(pyUsdcVault).asset());
        
        vm.stopBroadcast();
    }
}
