// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {PayerClient} from "../contracts/PayerClient.sol";
import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {IEulerRouter} from "euler-interfaces/IEulerRouter.sol";


import {ForkTest} from "../lib/evk-periphery/lib/euler-price-oracle/test/utils/ForkTest.sol";

contract PayerClientForkTest is ForkTest {
    
    IERC20 PYUSDC = IERC20(address(0x6c3ea9036406852006290770BEdFcAbA0e23A0e8)); 
    IEulerRouter EULER_ROUTER = IEulerRouter(address(0xa62Fa63445fADA0e90949778f8C84003F6D69004));
    IERC20 USDC = IERC20(address(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48));
    IERC20 WETH = IERC20(address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));

    function setUp() public {
        _setUpFork(19000000);
    }


    function test__getQuote__WETH_USDC() 





}