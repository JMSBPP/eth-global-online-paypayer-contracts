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

contract PaymentGateway is IPaymentGateway{
    
    address chainPriceOracle;
    address unitOfAccount;
    address eulerSwapFactory;
    address genericFactory;
    address pyUSDCVault;
    address escrowedCollateralPerspective;
    address payable evc;
    
    // NOTE: Each payer has it's own registry of pools.
    //  This is each payer has a resgistry of valid tkens
    // they have enable per payment. This is becase liquidity provision is only allowed 
    // by one euler account

    // NOTE: This

    mapping(address payer => mapping(address paymentAsset => address eulerSwapPool)) payerPoolMap;

    constructor(address _chainPriceOracle){
        chainPriceOracle = _chainPriceOracle;
    }

    function setUnitOfAccount(address _unitOfAccount) external{
        unitOfAccount = _unitOfAccount;
    }

    function setEVC(address _evc) external{
        evc = payable(_evc);
    }


    // TODO: This function needs to be guarded

    function setEulerSwapFactory(
        address _eulerSwapFactory
    ) external {
        eulerSwapFactory = _eulerSwapFactory;
    }

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

    function setPyUSDCVault(
        address _pyUSDCVault
    ) external {
        pyUSDCVault = _pyUSDCVault;
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



        address paymentTokenVault = _getOrCreatePaymentTokenVault(
            paymentToken
        );
        _depositCollateral(
            paymentToken,
            paymentTokenVault,
            payer,
            amountToPay
        );

        _enableCollateralAndController(
            payer,
            paymentTokenVault,
            pyUSDCVault
        );
        

     
        // NOTE: With the collateral in the vault, we need to enable the pyUSDC vault to 
        // allow the paymentVault to be used as collateral

    }




    function _enableCollateralAndController(
        address _payer,
        address _paymentTokenVault,
        address _pyUSDCVault
    ) internal {
        IEVC.BatchItem[] memory batchItems = new IEVC.BatchItem[](2);
        
        batchItems[0] = IEVC.BatchItem({
            targetContract: address(this),  // PaymentGateway as target
            onBehalfOfAccount: _payer,      // payer as onBehalfOfAccount
            value: 0,
            data: abi.encodeCall(
                this._enableCollateral,
                (_payer, _paymentTokenVault)
            )
        });
        
        batchItems[1] = IEVC.BatchItem({
            targetContract: address(this),  // PaymentGateway as target
            onBehalfOfAccount: _payer,      // payer as onBehalfOfAccount
            value: 0,
            data: abi.encodeCall(
                this._enableController,
                (_payer, _pyUSDCVault)
            )
        });

        IEthereumVaultConnector(evc).batch(batchItems);
    }

    function _enableCollateral(address payer, address vault) external {
        IEthereumVaultConnector(evc).enableCollateral(payer, vault);
    }

    function _enableController(address payer, address vault) external {
        IEthereumVaultConnector(evc).enableController(payer, vault);
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



    function _getOrCreatePaymentTokenVault(
        address paymentToken
    ) internal returns (address paymentTokenVault) {
 
        address paymentTokenVault = IEscrowedCollateralPerspective(
            escrowedCollateralPerspective
        ).singletonLookup(paymentToken);

        // NOTE: This token has not been used as payment yet

        if (paymentTokenVault == address(0x00)) {
            paymentTokenVault = GenericFactory(genericFactory).createProxy(
                    address(0),
                    true,
                    abi.encodePacked(
                        address(paymentToken),
                        address(0), // Escrow vaults must not have oracle
                        address(0)  // Escrow vaults must not have unit of account
                    )
             );

             // NOTE: Escrow vaults must not have hook targets
             {
                IEVault(paymentTokenVault).setHookConfig(address(0x00), 0);
                IEVault(paymentTokenVault).setInterestRateModel(address(0x00));
                IEVault(paymentTokenVault).setFeeReceiver(address(0x00));
                IEVault(paymentTokenVault).setCaps(0, 0);
                IEVault(paymentTokenVault).setConfigFlags(0);
                IEVault(paymentTokenVault).setMaxLiquidationDiscount(0);
                IEVault(paymentTokenVault).setLiquidationCoolOffTime(0);
                IEVault(paymentTokenVault).setGovernorAdmin(address(0x00));
             }

             IEscrowedCollateralPerspective(
                escrowedCollateralPerspective
             ).perspectiveVerify(paymentTokenVault, true);

        }

        return paymentTokenVault;
    }


}


