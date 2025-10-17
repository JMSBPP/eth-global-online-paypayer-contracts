// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import {IFlashWeightedPool} from "./interfaces/IFlashWeightedPool.sol";


// NOTE: This pool self-destroys on the same transaction using selfdestruct
// EIP-6780, It only serves to serve the payment on the most efficient way

// To be even more efficient this pool can be a clone
// following Deterministic cloning deployment
// parametrized by the weights of the tokens

abstract contract FlashWeightedPool is IFlashWeightedPool{


}