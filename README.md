# <h1 align="center"> Hardhat x Foundry Staking Smart Contract Project </h1>

**The repository demonstrates a staking smart contract which is upgradeable after initial deployment. The unit tests for the smart contract are written with Foundry**

The Staking smart contract is written using Solidty and Openzepplin framework and implements the management of roles, stakers, and configuration of the system.

Stakers can register, unregister, stake and slash or withdraw their staked amounts. When a stakers reigsters for the first time it being funded by `n` wei based on the contract configuration by the admin. The contact ensures that the contract has enough balance to fund this amount for the staker.

A staker can register to one or more roles. In this case, they can have a savings or current account type or role with different configuratons for registration funding and registration period (time between registration of the account and when the user can stake and unstake for their account type).

The configuration controls the configuration of the system, for example which roles exist, how much wei the staker will be funded, how much time to wait before staker ask to register and it is registered.

Furthermore:
* The smart contact is upgradeable
* All state changing functions have checks for who can call them
* Staker represents an ethereum address
* It is assumed that there will be only two roles for stakers
* Only admin role user can update contact configurations
* Unit tests achieve 100% code coverage


### Getting Started

 * Foundry: 
```bash
forge install
```

 * Hardhat:
```bash
npm run setup
```

### Features

 * Run tests with Foundry:
```bash
forge test
```

 * Deploy the upgradeable `Staking` smart contract: 
```bash
npx hardhat run scripts/deploy.js --network <network>
```

### Notes

Whenever you install new libraries using Foundry, make sure to update your `remappings.txt` file by running `forge remappings > remappings.txt`. This is required because we use `hardhat-preprocessor` and the `remappings.txt` file to allow Hardhat to resolve libraries you install with Foundry.
