import fs from "fs";
import { HardhatUserConfig, task } from "hardhat/config";
import "hardhat-preprocessor";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-deploy";
import "hardhat-contract-sizer";
import "@nomiclabs/hardhat-ethers";


function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean)
    .map((line) => line.trim().split("="));
}

const config: HardhatUserConfig = {
  networks: {
    localhost: {
        chainId: 1337,
        url: "http://127.0.0.1:8545",
        timeout: 5 * 60 * 1000, 
    },
  },

  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },

  },

  contractSizer: {
    runOnCompile: false,
  },

  paths: {
    sources: "./src", // Use ./src rather than ./contracts as Hardhat expects
    cache: "./cache_hardhat", // Use a different cache for Hardhat than Foundry
  },
  // This fully resolves paths for imports in the ./lib directory for Hardhat
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
};

if (process.env.NODE_ENV) {
  let path = `.env.${process.env.NODE_ENV}`;
  if (!fs.existsSync(path)) throw(`unable to open env file: ${path}`);
  require("dotenv").config({ path, });
} else if (fs.existsSync('./.env')) {
  require("dotenv").config();
}

for (let k in process.env) {
  if (k.startsWith("RPC_URL_")) {
      let networkName = k.slice(8).toLowerCase();

      config.networks = {
          ...config.networks,
          [networkName]: {
              url: `${process.env[k]}`,
              accounts: [`0x${process.env.PRIVATE_KEY}`],
          }
      }
  }
}


export default config;
