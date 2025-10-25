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

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {IUniswapV3Factory} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";
import {IPeripheryImmutableState} from "@uniswap/v3-periphery/contracts/interfaces/IPeripheryImmutableState.sol";

import {IQuoter} from "@uniswap/v3-periphery/contracts/interfaces/IQuoter.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

import {console2} from "forge-std/console2.sol";

contract PaymentGateway is IPaymentGateway{
    address immutable EVAULT_IMPLEMENTATION;
    address immutable TARGET_TOKEN;
    address immutable EVAULT_FACTORY;
    address immutable UNISWAP_V3_SWAP_ROUTER;
    address immutable UNISWAP_V3_QUOTER;
    
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
        address _targetToken,
        address _evc,
        address _evaultFactory,
        address _uniswapV3SwapRouter,
        address _uniswapV3Quoter
    
    ){
        EVAULT_IMPLEMENTATION = _evaultImplementation;
        TARGET_TOKEN = _targetToken;
        EVAULT_FACTORY = _evaultFactory;
        evc = payable(_evc);
        UNISWAP_V3_SWAP_ROUTER = _uniswapV3SwapRouter;
        UNISWAP_V3_QUOTER = _uniswapV3Quoter;
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
    ) external returns(uint256 amountReceivedForPaymentOnPyUSDC){
        // NOTE: This is the amount of pyUSDC to pay, the user has not deposited any
        // amount of token yet


        (uint256 amountToPaypyUSDC, uint256 amountToPayUnitOfAccount) = IChainPriceOracle(chainPriceOracle).getQuotes(
            amountToPay,
            paymentToken,
            unitOfAccount
        );

        IERC20(paymentToken).transferFrom(payer, address(this), amountToPay);
        IERC20(paymentToken).approve(UNISWAP_V3_SWAP_ROUTER, amountToPay);


        address paymentTokenUnitOfAccountMarket = 
            findWorkingFeeAndQuote(paymentToken, amountToPayUnitOfAccount);

        address targetTokenUnitOfAccountMarket = 
            findWorkingFeeAndQuote(TARGET_TOKEN, amountToPaypyUSDC);

        bytes memory path = abi.encodePacked(
            paymentToken,
            IUniswapV3Pool(paymentTokenUnitOfAccountMarket).fee(),
            unitOfAccount,
            IUniswapV3Pool(targetTokenUnitOfAccountMarket).fee(),
            TARGET_TOKEN
        );


        ISwapRouter.ExactInputParams memory internalSwapPayment = ISwapRouter.ExactInputParams({
            path: path,
            recipient: address(this),
            deadline: block.timestamp + 300,
            amountIn: amountToPay,
            amountOutMinimum: 0
        });

        uint256 amountReceivedForPaymentOnPyUSDC = ISwapRouter(UNISWAP_V3_SWAP_ROUTER).exactInput(internalSwapPayment);

        address pyUSDCVault = _getOrCreateEscrowVault(TARGET_TOKEN);

        IERC20(TARGET_TOKEN).approve(pyUSDCVault, amountReceivedForPaymentOnPyUSDC);

        IEVault(pyUSDCVault).deposit(amountReceivedForPaymentOnPyUSDC, address(this));




        return amountReceivedForPaymentOnPyUSDC;
    
    }


    function findWorkingFeeAndQuote(
        address _token,
        uint256 _amount
    ) public returns (address _pool){
        
        uint24[3] memory fees = [uint24(3000), uint24(500), uint24(100)];
        uint128 maxLiquidityOnRange;
        unchecked {
            uint256 index;
            for (index = 0; index < fees.length; index++) {
                address currentPool = IUniswapV3Factory(
                    IPeripheryImmutableState(UNISWAP_V3_QUOTER).factory()
                ).getPool(
                    _token,
                    unitOfAccount,
                    fees[index]
                );

                (,int24 currentTick,,,,,) = IUniswapV3Pool(currentPool).slot0();
                (uint128 currentPoolLiquidityOnRange,,,,,,,) = IUniswapV3Pool(currentPool).ticks(currentTick);
                if (currentPoolLiquidityOnRange > maxLiquidityOnRange) {
                    maxLiquidityOnRange = currentPoolLiquidityOnRange;
                    _pool = currentPool;
                }

            }
        }

        if (maxLiquidityOnRange == 0) {
            revert NoMarketFound();
        }

        return _pool;

    
    }


    function _getOrCreateEscrowVault(
        address _underlyingToken
    ) internal returns (address _escrowVault) {


        address _escrowVault = IEscrowedCollateralPerspective(
            escrowedCollateralPerspective
        ).singletonLookup(_underlyingToken);

        // NOTE: This token has not been used as payment yet

        if (_escrowVault == address(0x00)) {
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


        }
        

        return _escrowVault;
    }


}


