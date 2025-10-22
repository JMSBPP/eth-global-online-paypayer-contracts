// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

struct PayPalOnChainData{
    address[] paypalOnChainEndpoints;
    bytes[] frompyUSDCToPaypalContractCalls;
    uint256[] values;
}

address constant PYUSDC = address(0x6c3ea9036406852006290770BEdFcAbA0e23A0e8);

address constant ORACLE_LENS = address(0x30E6dFB84782A31d561536f64F47231451F7b48A);

address constant DAI_USD_ORACLE = address(0x4E33D9874EbB7847C9C11E47aEEa8D3F215bF676);
address constant USDC_USD_ORACLE = address(0xC039229EBCef32f898031eB81f646880F39a190B);

address constant DAI_WHALE = address(0x837c20D568Dfcd35E74E5CC0B8030f9Cebe10A28);
