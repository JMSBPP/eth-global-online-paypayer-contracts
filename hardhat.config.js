require("@nomicfoundation/hardhat-toolbox");
require("hardhat-foundry");

// The URL of the RPC endpoint for the network you want to deploy to
// For local development, you can use a local node or a public testnet like Goerli
const GOERLI_RPC_URL = process.env.GOERLI_RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

module.exports = {
  solidity: "0.8.19",
  networks: {
    goerli: {
      url: GOERLI_RPC_URL,
      accounts: PRIVATE_KEY !== "" ? [PRIVATE_KEY] : [],
      saveDeployments: true,
    },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  // Settings for the compiler
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};