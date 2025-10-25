// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;


import {IPaymentGateway} from "./interfaces/IPaymentGateway.sol";
import {IChainPriceOracle} from "./interfaces/IChainPriceOracle.sol";
import {IEulerSwapFactory} from "euler-swap/src/interfaces/IEulerSwapFactory.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IEVault} from "euler-interfaces/IEVault.sol";
import {IEulerSwap} from "euler-swap/src/interfaces/IEulerSwap.sol";
import {IEscrowedCollateralPerspective} from "euler-interfaces/IEscrowedCollateralPerspective.sol";
import {GenericFactory} from "evk/GenericFactory/GenericFactory.sol";
import {IEthereumVaultConnector, IEVC} from "euler-interfaces/IEthereumVaultConnector.sol";

import {FullMath} from "euler-swap/src/math/FullMath.sol";

contract PaymentGateway is IPaymentGateway{
    address immutable EVAULT_IMPLEMENTATION;
    address immutable UNDERLYING_TOKEN;
    address immutable EVAULT_FACTORY;
    address immutable UNSIWAP_V3_ROUTER;


    address chainPriceOracle;
    address unitOfAccount;
    address genericFactory;
    address pyUSDCVault;
    address escrowedCollateralPerspective;
    address payable evc;
    
    // NOTE: Each payer has it's own registry of pools.
    //  This is each payer has a resgistry of valid tkens
    // they have enable per payment. This is becase liquidity provision is only allowed 
    // by one euler account



    constructor(
        address _evaultImplementation,
        address _underlyingToken,
        address _evc,
        address _evaultFactory,
        address _uniswapV3Router
    ){
        EVAULT_IMPLEMENTATION = _evaultImplementation;
        UNDERLYING_TOKEN = _underlyingToken;
        EVAULT_FACTORY = _evaultFactory;
        evc = payable(_evc);
        UNSIWAP_V3_ROUTER = _uniswapV3Router;
    }

    function setUnitOfAccount(address _unitOfAccount) external{
        unitOfAccount = _unitOfAccount;
    }

    function setChainPriceOracle(address _chainPriceOracle) external{
        chainPriceOracle = _chainPriceOracle;
    }


    // TODO: This function needs to be guarded


    function setGenericFactory(
        address _genericFactory
    ) external {
        genericFactory = _genericFactory;
    }

    function setEscrowCollateralPerspective(
        address _escrowCollateralPerspective
    ) external {
        escrowedCollateralPerspective = _escrowCollateralPerspective;
    }



    // NOTE: This is the main fucntion
    function processPayment(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        bytes32 recipientId
    ) external returns(bytes[] memory res){
        // NOTE: This is the amount of pyUSDC to pay, the user has not deposited any
        // amount of token yet
        uint256 amountToPaypyUSDC = IChainPriceOracle(chainPriceOracle).getQuote(
            amountToPay,
            paymentToken,
            unitOfAccount
        );


        (address paymentTokenVault, address pyUSDCVault) = (_getOrCreatePaymentTokenVault(paymentToken), _getOrDeployPyUSDCVault(amountToPaypyUSDC));

        // NOTE: getQuote guaranteees that there is a reliable market for the token that accurately quotes
        // it against the USDC

        // NOTE: What now needs to be done is to create a market on euler swap for the pair

        // (token, pyUSDC), We have as utils (price_{pyUSDC/token} and the pair (pyUSDC, USDC))
        _getOrCreateEulerSwapMarket(
            paymentToken,
            amountToPay,
            amountToPaypyUSDC,
            paymentTokenVault,
            pyUSDCVault
        );





        // NOTE: Here we do the swap
    



        // NOTE: The paymentTokenVault is now enabled as collateral for the pyUSDCVault
        // and 



        

    }

    function _getOrCreateEulerSwapMarket(
        address _paymentToken,
        uint256 _amountToPay,
        uint256 _amountToPaypyUSDC,
        address _paymentTokenVault,
        address _pyUSDCVault
    ) private returns (address _eulerSwapPool){
        IEulerSwap.StaticParams memory marketMetadata = IEulerSwap.StaticParams({
            supplyVault0: _paymentTokenVault,
            supplyVault1: _pyUSDCVault,
            borrowVault0: address(0x00),
            borrowVault1: address(0x00),
            eulerAccount: address(this),
            feeRecipient: address(this),
            protocolFeeRecipient: address(this),
            protocolFee: 0 // TODO: This is to be determined
        });

        uint256 priceX = FullMath.mulDiv(1e18, _amountToPaypyUSDC, _amountToPay);

        IEulerSwap.DynamicParams memory marketDynamicParams = IEulerSwap.DynamicParams({
            equilibriumReserve0: _amountToPay,
            equilibriumReserve1: _amountToPaypyUSDC,
            minReserve0: 0,
            minReserve1: 0,
            priceX: 1e18,
            priceY: 1e18,
            concentrationX: 1e18,
            concentrationY: 1e18,
            fee0: 0,
            fee1: 0,
            expiration: 0,
            swapHookedOperations: 0,
            swapHook: address(0x00)
        });


    }



    function _depositCollateral(
        address _paymentToken,
        address _paymentTokenVault,
        address _payer,
        uint256 _amountToPay
    ) private{
           // NOTE: Transfer the payment token from the payer to this contract
        IERC20(_paymentToken).transferFrom(_payer, address(this), _amountToPay);
        
        // NOTE: Approve the vault to spend the tokens
        IERC20(_paymentToken).approve(_paymentTokenVault, _amountToPay);

        // NOTE: Now we need to deposit the collateral that the payer holds
        IEVault(_paymentTokenVault).deposit(_amountToPay, address(this));

    
    }



    function _getOrCreateEscrowVaultVault(
        address _underlyingToken
    ) internal returns (address _escrowVault) {


        address _escrowVault = IEscrowedCollateralPerspective(
            escrowedCollateralPerspective
        ).singletonLookup(_underlyingToken);

        // NOTE: This token has not been used as payment yet

        if (paymentTokenVault == address(0x00)) {
            _escrowVault = GenericFactory(genericFactory).createProxy(
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
                IEVault(_escrowVault).setHookConfig(address(0x00), 0);
                IEVault(_escrowVault).setInterestRateModel(address(0x00));
                IEVault(_escrowVault).setFeeReceiver(address(0x00));
                IEVault(_escrowVault).setCaps(0, 0);
                IEVault(_escrowVault).setConfigFlags(0);
                IEVault(_escrowVault).setMaxLiquidationDiscount(0);
                IEVault(_escrowVault).setLiquidationCoolOffTime(0);
                IEVault(_escrowVault).setGovernorAdmin(address(0x00));
             }

             IEscrowedCollateralPerspective(
                escrowedCollateralPerspective
             ).perspectiveVerify(_escrowVault, true);

             escrowVault = _escrowVault;

        }
        

        return _escrowVault;
    }


}


