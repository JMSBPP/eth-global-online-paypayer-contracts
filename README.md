# Papaya Contracts

## Quick Start

```bash
# Install dependencies
make install

# Run tests
make test

# Deploy contracts
cp env.example .env
# Edit .env with your keys
make deploy

# Make a payment
make pay PAYER=0x... PAYMENT_TOKEN=0x... AMOUNT=1000000000000000000 PAYEE=0x...
```

## Deployed Contracts (Mainnet)

| Contract | Address | Etherscan |
|----------|---------|-----------|
| UniswapV3Oracle | `0x8fff822893486c999831514b194773e02a08695b` | [View on Etherscan](https://etherscan.io/address/0x8fff822893486c999831514b194773e02a08695b) |
| ChainPriceOracle | `0x6fc13169c426a1f4027a5c1388ff17ae183bbbca` | [View on Etherscan](https://etherscan.io/address/0x6fc13169c426a1f4027a5c1388ff17ae183bbbca) |
| PaymentGateway | `0x5c9475e14b7a4857e460702764c4d5186ffd697d` | [View on Etherscan](https://etherscan.io/address/0x5c9475e14b7a4857e460702764c4d5186ffd697d) |
| Client | `0xd3335a63df9a3133fc313b1306fdd48612d7fd98` | [View on Etherscan](https://etherscan.io/address/0xd3335a63df9a3133fc313b1306fdd48612d7fd98) |

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