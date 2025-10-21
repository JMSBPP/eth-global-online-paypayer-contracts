// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {EVault} from "evk/EVault/EVault.sol";



// admin --> This is a Governor 
//   --> From now it can be GovernorGuardian

// feeReceiver = makeAddr("feeReceiver"); --> TO DEPLOY The payer or what is incentivizing LP's

// protocolFeeReceiver = makeAddr("protocolFeeReceiver"); --> TO DEPLOY Fund manager
// (Treasury) of the protocol 

// factory = new GenericFactory(admin); -> DEPLOYED 

// evc = new EthereumVaultConnector(); --> DEPLOYED 
// protocolConfig = new ProtocolConfig(admin, protocolFeeReceiver); -> TO DEPLOY/ NOT MODIFIABLE

// balanceTracker = address(new MockBalanceTracker()); --> TO DEPLOY

// /// @title IBalanceTracker
// /// @custom:security-contact security@euler.xyz
// /// @author Euler Labs (https://www.eulerlabs.com/)
// /// @notice Provides an interface for tracking the balance of accounts.
// interface IBalanceTracker {
//     /// @notice Executes the balance tracking hook for an account.
//     /// @dev This function is called by the Balance Forwarder contract which was enabled for the account. This function
//     /// must be called with the current balance of the account when enabling the balance forwarding for it. This
//     /// function must be called with 0 balance of the account when disabling the balance forwarding for it. This
//     /// function allows to be called on zero balance transfers, when the newAccountBalance is the same as the previous
//     /// one. To prevent DOS attacks, forfeitRecentReward should be used appropriately.
//     /// @param account The account address to execute the hook for.
//     /// @param newAccountBalance The new balance of the account.
//     /// @param forfeitRecentReward Whether to forfeit the most recent reward and not update the accumulator.
//     function balanceTrackerHook(address account, uint256 newAccountBalance, bool forfeitRecentReward) external;
// }


// oracle = new MockPriceOracle(); -> TO DEPLOY/
// Uniswap V3 Oracle for pyUSDC and pyTh Oracle for others
// One can use he l


// unitOfAccount = address(1); --> USDC
// permit2 = deployPermit2(); --> Deploy Permit2
// sequenceRegistry = address(new SequenceRegistry()); --> TO DEPLOY / NOT MODIFIABLE 
// integrations =
//     Base.Integrations(address(evc),
///                      address(protocolConfig),
//                       sequenceRegistry,
//                       balanceTracker,
//                         permit2);
// For modeules we have more customability, this is by tracking the virtual function 
// --> InitalizeModule --> What requirements does it need ?
// --> TokenModules --> This wraps the pyUSDC 
//    - Deployable using Token
//    - Modifiable using TokenModule

// --> VaultModule 
//    - Deployable using Vault
//    - Modifiable using VaultModule

// --> LiquididatioModule
//                       --> From now we are ignoring this ones
// --> BorrowingMdoule 

// --> riskManageModule

// --> BalanceForwarder 
//                --> This handles communication with the BalanceTrackerHook

// --> Governance
//    --> IMPORTANT
//       -->  - Deployable using Governance
//       -->   -Modifiable using GovernanceModule

// eTST3 = IEVault(
//     factory.createProxy(
//       address(0), // New Implementation 
//       true, // Upgradeable
//   abi.encodePacked(
//                   address(pyUSDC)
//                   address(oracle), 
//                   unitOfAccount)
// )

// eTST3.setHookConfig(address(0), 0);
// eTST3.setInterestRateModel(address(new IRMTestDefault()));
// eTST3.setMaxLiquidationDiscount(0.2e4);
// eTST3.setFeeReceiver(feeReceiver);

// // Vault config

// eTST.setLTV(address(eTST2), 0.9e4, 0.9e4, 0);
// eTST2.setLTV(address(eTST), 0.9e4, 0.9e4, 0);
// eTST.setLTV(address(eTST3), 0.9e4, 0.9e4, 0);

abstract contract pyUSDCPaymentsVault is EVault {


    constructor(
        Integrations memory integrations,
        DeployedModules memory modules
    ) EVault(integrations, modules) {
    }
}
