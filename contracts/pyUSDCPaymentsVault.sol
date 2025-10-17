// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {EVault} from "evk/EVault/EVault.sol";
import {IPerspective} from "evk/Perspectives/implementation/interfaces/IPerspective.sol";


// eTST3 = IEVault(
//     factory.createProxy(address(0), true, abi.encodePacked(address(assetTST3), address(oracle), unitOfAccount))
// );
// GenericFactory.createProxy(address desiredImplementation, bool upgradeable, bytes memory trailingData)
// function createProxy(address desiredImplementation, bool upgradeable, bytes memory trailingData)



// eTST3.setHookConfig(address(0), 0);
// eTST3.setInterestRateModel(address(new IRMTestDefault()));
// eTST3.setMaxLiquidationDiscount(0.2e4);
// eTST3.setFeeReceiver(feeReceiver);

// // Vault config

// eTST.setLTV(address(eTST2), 0.9e4, 0.9e4, 0);
// eTST2.setLTV(address(eTST), 0.9e4, 0.9e4, 0);
// eTST.setLTV(address(eTST3), 0.9e4, 0.9e4, 0);

abstract contract pyUSDCPaymentsVault is EVault {
    address public immutable escrowedCollateralPerspective;
    address public immutable pyUSDCAddress;

    error PerspectiveVerificationFailed();

    // NOTE: pyUSDC Vault is an escrow vault type
    constructor(
        Integrations memory integrations,
        DeployedModules memory modules,
        address _escrowedCollateralPerspective,
        address _pyUSDCAddress
    ) EVault(integrations, modules) {
        escrowedCollateralPerspective = _escrowedCollateralPerspective;
        pyUSDCAddress = _pyUSDCAddress;
        IPerspective(escrowedCollateralPerspective).perspectiveVerify(address(this));
    }
}
