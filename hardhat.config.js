require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
          viaIR: true,
        },
      },
      {
        version: "0.8.20",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
          viaIR: true,
        },
      }
    ],
  },
  paths: {
    sources: "./orbitwork-hook/src/core",
    tests: "./orbitwork-hook/test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  networks: {
    UNICHAIN_SEPOLIA: {
      url: process.env.UNICH_RPC_URL || "https://sepolia.unichain.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
    },
  },
};
