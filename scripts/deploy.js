const { ethers } = require('hardhat');
const hre = require('hardhat');

async function deployStakingRaw(deployer) {
  const registrationWaitTimeCurrent = 100;
  const registrationWaitTimeSavings = 200;
  const registrationFundingAmountCurrent = ethers.utils.parseEther('1');
  const registrationFundingAmountSavings = ethers.utils.parseEther('2');

  const STAKING = await ethers.getContractFactory('Staking');
  const staking = await STAKING.deploy();
  console.log(`Staking implementation contract address - ${staking.address}`);
  const contractABI = [
    {
      inputs: [
        {
          internalType: 'uint256',
          name: '_registrationWaitTimeCurrent',
          type: 'uint256',
        },
        {
          internalType: 'uint256',
          name: '_registrationWaitTimeSavings',
          type: 'uint256',
        },
        {
          internalType: 'uint256',
          name: '_stakerFundingAmountCurrent',
          type: 'uint256',
        },
        {
          internalType: 'uint256',
          name: '_stakerFundingAmountSavings',
          type: 'uint256',
        },
      ],
      name: 'initialize',
      outputs: [],
      stateMutability: 'nonpayable',
      type: 'function',
    },
  ];

  const contract = new ethers.Contract(staking.address, contractABI);
  const encodedData = contract.interface.encodeFunctionData('initialize', [
    registrationWaitTimeCurrent, 
    registrationWaitTimeSavings,
    registrationFundingAmountCurrent,
    registrationFundingAmountSavings
  ]);

  const PROXY = await ethers.getContractFactory('TransparentProxy');
  const proxy = await PROXY.deploy(
    staking.address,
    deployer.address,
    encodedData,
  );
  console.log(`Staking proxy contract address - ${proxy.address}`);
}

async function main() {
  const [deployer] = await ethers.getSigners();
  await deployStakingRaw(deployer);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
})
