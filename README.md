# ETH Global Online - Payment Gateway

## Deployed Contracts (Mainnet)

| Contract | Address | Etherscan |
|----------|---------|-----------|
| UniswapV3Oracle | `0xc6b4617c1781065d31d83ae2b37c3380a75997af` | [View on Etherscan](https://etherscan.io/address/0xc6b4617c1781065d31d83ae2b37c3380a75997af) |
| ChainPriceOracle | `0xfca85fb05db96070ef336136fe8ca9c6a3853de1` | [View on Etherscan](https://etherscan.io/address/0xfca85fb05db96070ef336136fe8ca9c6a3853de1) |
| PaymentGateway | `0x3abed3335da4cbca36938d094b77d52477fbf60c` | [View on Etherscan](https://etherscan.io/address/0x3abed3335da4cbca36938d094b77d52477fbf60c) |
| Client | `0x72c21100bb512aeefb4afc11048e100a00dc4dc1` | [View on Etherscan](https://etherscan.io/address/0x72c21100bb512aeefb4afc11048e100a00dc4dc1) |

## Features

- **Multi-token Payment Support**: Accept ETH, ERC20 tokens, and same-token payments
> NOTE: Payment token needs to be a token paired with USDC on Uniswap V3


- **Automatic Token Swapping**: Seamless conversion to pyUSDC via Uniswap V3
- **Escrow Vault Integration**: Secure token storage using Euler Vault Kit
- **Price Oracle Integration**: Real-time price feeds via Pyth and Uniswap

## Supported Payment Types

1. **ETH Payments**: ETH → WETH → USDC → pyUSDC
2. **ERC20 Payments**: DAI/USDT/etc → USDC → pyUSDC  
3. **Same Token Payments**: PYUSD → PYUSD (direct deposit)

## Architecture

The payment system consists of four main contracts:

- **PaymentGateway**: Core payment processing logic
- **Client**: User-facing payment interface
- **ChainPriceOracle**: Price feed aggregation and validation
- **UniswapV3Oracle**: Uniswap V3 price oracle integration