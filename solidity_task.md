# Eoracle Solidity Home Assignment
This explains the home assignment focuses on Solidity
You will be checked on claritiy of the code, storage selection, unit tests, security of the smart contracts and gas effiencency

## Home Assginment Spec
Create smart contracts using solidty and openzepplin framework that will implement the management of roles, stakers, configuration of the system.

Stakers can register, unregister and slashed. When a stakers reigsters for the first time it being funded by `n` wei.

A staker can register to one or more roles.

The configuration controls the configuration of the system, for example which roles exist, how much wei the staker will be funded, how much time to wait before staker ask to register and it is registered.

You can add more configurations that you think are relevant

### Requeirements
* All smart contracts must be upgraded
* All functions should be checked the input and who can call them
* Staker should represnt an ethereum address
* Roles should represent name, description, ...
* Use cast / foundry for testing

## Submiting the project
* The project should be submitted using a github repo
* The project can run on a dev instance on and evm compliant chain
* Instructions how to init, run, and test 
* any assumptions you made

