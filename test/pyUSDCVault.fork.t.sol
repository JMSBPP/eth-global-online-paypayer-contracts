// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;




import {USDC} from "euler-price-oracle-test/utils/EthereumAddresses.sol";
import "./utils/ForkUtils.sol";

import {console2} from "forge-std/console2.sol";
import "./utils/Deployers.sol";
import {ForkTest} from "../lib/evk-periphery/lib/euler-price-oracle/test/utils/ForkTest.sol";


import "../lib/euler-vault-kit/test/unit/evault/EVaultTestBase.t.sol";

import "permit2/test/utils/DeployPermit2.sol";


import {IEVault} from "../lib/euler-vault-kit/src/EVault/IEVault.sol";

contract pyUSDCVaultForkTest is ForkTest, Deployers, DeployPermit2 {
    
    



    address pyUSDCVault;

    // TODO: Further logic needs to be appliad here for the feeReceiver
    address feeReceiver = makeAddr("feeReceiver"); 

    function setUp() public {
        _setUpFork(23626800);

        deployUniswapV3Oracle();

        deployChainOracleAndSetAll(PYUSDC, USD, USDC, PYTH_USDC_USD_FEED, uniswapV3Oracle, ORACLE_LENS, PYTH);
        deployPaymentGateway(chainPriceOracle);
        deployPayerClient(PYUSDC, paymentGateway);
        
        pyUSDCVault = 
            GenericFactory(EVAULT_FACTORY).createProxy(
                EVAULT_IMPLEMENTATION,
                true,
                abi.encodePacked(
                    PYUSDC,
                    chainPriceOracle,
                    USDC
                )
            );
        IEVault(pyUSDCVault).setHookConfig(address(0), 0);
        IEVault(pyUSDCVault).setInterestRateModel(address(new IRMTestDefault()));
        IEVault(pyUSDCVault).setMaxLiquidationDiscount(0.2e4);
        IEVault(pyUSDCVault).setFeeReceiver(feeReceiver);
        IEVault(pyUSDCVault).setInterestFee(1e4);
// function setCaps(uint16 supplyCap, uint16 borrowCap) external;
// function setConfigFlags(uint32 newConfigFlags) external;
// function setFeeReceiver(address newFeeReceiver) external;
// function setGovernorAdmin(address newGovernorAdmin) external;
// function setHookConfig(address newHookTarget, uint32 newHookedOps) external;
// function setInterestFee(uint16 newFee) external;
// function setInterestRateModel(address newModel) external;
// function setLTV(address collateral, uint16 borrowLTV, uint16 liquidationLTV, uint32 rampDuration) external;
// function setLiquidationCoolOffTime(uint16 newCoolOffTime) external;
// function setMaxLiquidationDiscount(uint16 newDiscount) external;
    }


}



