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
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

import {IWETH} from "@pendle/core-v2/interfaces/IWETH.sol";

contract PaymentGateway is IPaymentGateway, AccessControl{
    bytes32 public constant PAYMENT_CLIENT_ROLE = keccak256("PAYMENT_CLIENT_ROLE");
    address constant ETH = address(0x00);
    address immutable EVAULT_IMPLEMENTATION;
    address immutable TARGET_TOKEN;
    address immutable EVAULT_FACTORY;
    address immutable UNISWAP_V3_SWAP_ROUTER;
    address immutable UNISWAP_V3_QUOTER;
    address immutable ESCROWED_COLLATERAL_PERSPECTIVE;
    address immutable GENERIC_FACTORY;
    address payable immutable EVC;
    address immutable WETH;



    address chainPriceOracle;
    address unitOfAccount;
    address treasury;
    address paymentClient;
    
    // NOTE: Each payer has it's own registry of pools.
    //  This is each payer has a resgistry of valid tkens
    // they have enable per payment. This is becase liquidity provision is only allowed 
    // by one euler account

    mapping(address _payee => PaymentData[] _payments) paymentsQueue;




    constructor(
        address _evaultImplementation,
        address _targetToken,
        address _evc,
        address _evaultFactory,
        address _uniswapV3SwapRouter,
        address _uniswapV3Quoter,
        address _escrowedCollateralPerspective,
        address _weth
    
    ){
        EVAULT_IMPLEMENTATION = _evaultImplementation;
        TARGET_TOKEN = _targetToken;
        EVAULT_FACTORY = _evaultFactory;
        EVC = payable(_evc);
        UNISWAP_V3_SWAP_ROUTER = _uniswapV3SwapRouter;
        UNISWAP_V3_QUOTER = _uniswapV3Quoter;
        ESCROWED_COLLATERAL_PERSPECTIVE = _escrowedCollateralPerspective;
        WETH = _weth;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    
    }

    function setUnitOfAccount(address _unitOfAccount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        unitOfAccount = _unitOfAccount;
    }

    function setChainPriceOracle(address _chainPriceOracle) external onlyRole(DEFAULT_ADMIN_ROLE) {
        chainPriceOracle = _chainPriceOracle;
    }

    function setPaymentClient(address _paymentClient) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paymentClient = _paymentClient;
        _grantRole(PAYMENT_CLIENT_ROLE, _paymentClient);
    }


    function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = _treasury;
    }


    function getTreasury() external view returns (address) {
        return treasury; 
    }


    // NOTE: This is the main fucntion
    function processPayment(
        address payer,
        address paymentToken,
        uint256 amountToPay,
        address payee
    ) external payable onlyRole(PAYMENT_CLIENT_ROLE) returns(uint256 amountReceivedForPaymentOnPyUSDC){

        // TODO: This is the amount of pyUSDC quoted against external market, this is to be used 
        // to set slippage tolerance for the payment
        bool isETH = (paymentToken == ETH);
        if (isETH) {
            
            uint256 balanceBefore = IWETH(WETH).balanceOf(address(this));
            if (msg.value != amountToPay) revert InsufficientBalance();
            IWETH(WETH).deposit{value: amountToPay}();

            uint256 balanceAfter = IWETH(WETH).balanceOf(address(this));
            
            if (balanceAfter - balanceBefore != amountToPay) revert InsufficientBalance();
            
            paymentToken = WETH;
        }

    
        uint256 amountReceivedForPaymentOnPyUSDC;
        
        if (paymentToken == TARGET_TOKEN) {
            // No swapping needed - just transfer directly
            if (!isETH) {
                IERC20(paymentToken).transferFrom(payer, address(this), amountToPay);
            }
            amountReceivedForPaymentOnPyUSDC = amountToPay;
        } else {
            // Normal flow with price quotes and swapping
            (uint256 amountToPaypyUSDC, uint256 amountToPayUnitOfAccount) = IChainPriceOracle(chainPriceOracle).getQuotes(
                amountToPay,
                paymentToken,
                unitOfAccount
            );

            // TODO: This needs to be improved to allow permit approvals

            // Only transfer from payer if it's not ETH (which we already wrapped)
            if (!isETH) {
                IERC20(paymentToken).transferFrom(payer, address(this), amountToPay);
            }
            IERC20(paymentToken).approve(UNISWAP_V3_SWAP_ROUTER, amountToPay);

            bytes memory path = abi.encodePacked(
                paymentToken,
                IUniswapV3Pool(findWorkingFeeAndQuote(paymentToken, amountToPayUnitOfAccount)).fee(),
                unitOfAccount,
                IUniswapV3Pool(findWorkingFeeAndQuote(TARGET_TOKEN, amountToPaypyUSDC)).fee(),
                TARGET_TOKEN
            );

            amountReceivedForPaymentOnPyUSDC = ISwapRouter(UNISWAP_V3_SWAP_ROUTER).exactInput(ISwapRouter.ExactInputParams({
                path: path,
                recipient: address(this),
                deadline: block.timestamp + 300,
                amountIn: amountToPay,
                amountOutMinimum: 0
            }));
        }

        // Only create vault if treasury is not already set
        if (treasury == address(0)) {
            treasury = _getOrCreateEscrowVault(TARGET_TOKEN);
        }

        IERC20(TARGET_TOKEN).approve(treasury, amountReceivedForPaymentOnPyUSDC);

        IEVault(treasury).deposit(amountReceivedForPaymentOnPyUSDC, payee);
        
        paymentsQueue[payee].push(PaymentData({
            payer: payer,
            timeStamp: uint48(block.timestamp),
            amountPaid: amountReceivedForPaymentOnPyUSDC,
            withdrawable: false
        }));


        return amountReceivedForPaymentOnPyUSDC;
    
    }

    function closePayment(
        address payee,
        address destination,
        uint256 index
    ) external onlyRole(PAYMENT_CLIENT_ROLE) {
        IEVault(treasury).withdraw(
            paymentsQueue[payee][index].amountPaid,
            destination,
            payee
        );

        delete paymentsQueue[payee][index];
    }

    function getPaymentsQueue(
        address payee
    ) external view onlyRole(PAYMENT_CLIENT_ROLE) returns (PaymentData[] memory payments) {
        return paymentsQueue[payee];
    }


    function findWorkingFeeAndQuote(
        address _token,
        uint256 /* _amount */
    ) public view returns (address _pool){
        
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
            ESCROWED_COLLATERAL_PERSPECTIVE
        ).singletonLookup(_underlyingToken);

        // NOTE: This token has not been used as payment yet

        if (_escrowVault == address(0x00)) {
            _escrowVault = GenericFactory(EVAULT_FACTORY).createProxy(
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
                ESCROWED_COLLATERAL_PERSPECTIVE
             ).perspectiveVerify(_escrowVault, true);


        }
        

        return _escrowVault;
    }


}


