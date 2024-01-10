# <h1 align="center"> Hardhat and Foundry sample staking smart contract project </h1>

**The repository demonstrates a staking smart contract which is upgradeable after initial deployment. The unit tests for the smart contract are written with Foundry**

The Staking smart contract is written using Solidty and the OpenZeppelin framework and implements the management of roles, stakers, and configuration of the system.

Stakers can register, unregister, stake and slash (or withdraw) their staked amounts. When a staker reigsters for the first time its account is funded by `n` wei based on the contract configuration by the admin. The contact ensures that the contract has enough balance to fund this amount for the staker.

A staker can register to one or more roles. In this case, they can have a savings or current account type or role with different configuratons for registration funding and registration period (time between registration of the account and when the user can stake and unstake for their account type).

The configuration controls the configuration of the system, for example which roles exist, how much wei the staker will be funded, how much time to wait before staker ask to register and it is registered.

Furthermore:
* The smart contact is upgradeable
* All state changing functions have checks for who can call them
* Staker represents an ethereum address
* It is assumed that there will be only two roles for stakers, i.e., current and savings staking accounts / roles
* Only admin role user can update the smart contact configurations
* Unit tests achieve very high code coverage


### Getting Started

Ensure that Foundry is installed on your machine. Please see the Foundry installation [guide](https://book.getfoundry.sh/getting-started/installation).
Also, ensure you have installed npm and node following this [guide](https://docs.npmjs.com/downloading-and-installing-node-js-and-npm).


Install the required project dependencies.

 * Foundry: 
```bash
forge install
```

 * Hardhat:
```bash
npm run setup
```


Note: add a new line with `solc = "0.8.20"` in the `foundry.toml` file to force Foundry to use the required Solidity compiler version `0.8.20`.


### Features

 * Compile the smart contracts with Foundry:
```bash
forge build
```

 * Run tests with Foundry:
```bash
forge test
```

 * Deploy the upgradeable `Staking` smart contract: 
```bash
npx hardhat run scripts/deploy.js --network <network>
```

### Notes

Whenever you install new libraries using Foundry, make sure to update the `remappings.txt` file by running `forge remappings > remappings.txt`. 

This is required because we use `hardhat-preprocessor` and the `remappings.txt` file to allow Hardhat to resolve libraries you install with Foundry.
