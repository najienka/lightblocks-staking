// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";
import "forge-std/Test.sol";

import "../src/Staking.sol";
import {ITransparentUpgradeableProxy, TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract StakingTest is Test {
    Staking public stakingContract;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant CURRENT_STAKER_ROLE = keccak256("CURRENT_STAKER_ROLE");
    bytes32 public constant SAVINGS_STAKER_ROLE = keccak256("SAVINGS_STAKER_ROLE");
    bytes32 public constant INVALID_STAKER_ROLE = keccak256("INVALID_STAKER_ROLE");

    event StakerRegistered(address indexed staker, bytes32 role);
    event StakerUnregistered(address indexed staker, bytes32 role);
    event StakerStaked(address indexed staker, bytes32 role, uint256 amount);
    event StakerSlashed(address indexed staker, bytes32 role, uint256 amount);

    uint256 public registrationWaitTimeCurrent = 10;
    uint256 public registrationWaitTimeSavings = 20;
    uint256 public registrationFundingAmountCurrent = 1 ether;
    uint256 public registrationFundingAmountSavings = 2 ether;

    address public stakingContractAddress;
    // address public stakingContractAddressV2;
    address payable public proxy;
    address public immutable deployer;
    address public immutable alice;

    constructor() {
        deployer = makeAddr("DEPLOYER");
        alice = makeAddr("alice");
    }

    function setUp() public {
        Staking s = new Staking();
        stakingContractAddress = address(s);
        bytes memory data = abi.encodeCall(s.initialize, (
            registrationWaitTimeCurrent, // registration wait time for current account staker
            registrationWaitTimeSavings, // registration wait time for savings account staker
            registrationFundingAmountCurrent, // allocation to current account staker after first registration
            registrationFundingAmountSavings // allocation to savings account staker after first registration
        ));
        vm.prank(deployer);
        proxy = payable(address(new TransparentUpgradeableProxy(stakingContractAddress, deployer, data)));

        stakingContract = Staking(proxy);
    }

    function testTotalStakedUponDeployment() public {
        assertEq(stakingContract.totalStaked(), 0, "total staked post deployment should be zero");
    }

    function testContractEtherBalance() public {
        uint256 balanceBefore = address(stakingContract).balance;
        assertEq(balanceBefore, 0, "balance post deployment should be zero");

        hoax(address(stakingContract), 10000e18);
        uint256 balanceAfterHoax = address(stakingContract).balance;
        assertEq(balanceAfterHoax, 10000e18, "incorrect contract balance after receiving ether");
    }

    // should update configuration parameters post deployment and with admin function
    function testConfigurationParameters() public {
        assertEq(stakingContract.stakerFundingAmount(CURRENT_STAKER_ROLE), registrationFundingAmountCurrent, "incorrect funding amount for current post deployment");
        assertEq(stakingContract.stakerFundingAmount(SAVINGS_STAKER_ROLE), registrationFundingAmountSavings, "incorrect funding amount for savings post deployment");
        assertEq(stakingContract.registrationWaitTime(CURRENT_STAKER_ROLE), registrationWaitTimeCurrent, "incorrect wait time for current post deployment");
        assertEq(stakingContract.registrationWaitTime(SAVINGS_STAKER_ROLE), registrationWaitTimeSavings, "incorrect wait time for savings post deployment");

        uint256 _registrationWaitTimeCurrent = 30;
        uint256 _registrationWaitTimeSavings = 30;
        uint256 _stakerFundingAmountCurrent = 3 ether;
        uint256 _stakerFundingAmountSavings = 4 ether;

        vm.prank(deployer);
        
        stakingContract.updateConfiguration(
            _registrationWaitTimeCurrent, 
            _registrationWaitTimeSavings, 
            _stakerFundingAmountCurrent, 
            _stakerFundingAmountSavings
        );

        assertEq(stakingContract.stakerFundingAmount(CURRENT_STAKER_ROLE), _stakerFundingAmountCurrent, "incorrect funding amount for current post update");
        assertEq(stakingContract.stakerFundingAmount(SAVINGS_STAKER_ROLE), _stakerFundingAmountSavings, "incorrect funding amount for savings post update");
        assertEq(stakingContract.registrationWaitTime(CURRENT_STAKER_ROLE), _registrationWaitTimeCurrent, "incorrect wait time for current post update");
        assertEq(stakingContract.registrationWaitTime(SAVINGS_STAKER_ROLE), _registrationWaitTimeSavings, "incorrect wait time for savings post update");
    }

    // should revert if role is invalid for registration
    function testRevertStakerRole() public {
        vm.expectRevert(abi.encodePacked("Role must be current or savings staker role"));
        stakingContract.registerStaker(INVALID_STAKER_ROLE);
    }

    // function makeAddr(string memory name) public returns (address) {
    //     address addr = address(uint160(uint256(keccak256(abi.encodePacked(name)))));
    //     vm.label(addr, name);
    //     return addr;
    // }

    // should revert if caller does not have admin role for contract configuration
    function testRevertNotAdminRole() public {
        vm.prank(alice);
        
        vm.expectRevert(abi.encodePacked("Not an admin"));

        uint256 _registrationWaitTimeCurrent = 30;
        uint256 _registrationWaitTimeSavings = 30;
        uint256 _stakerFundingAmountCurrent = 3 ether;
        uint256 _stakerFundingAmountSavings = 4 ether;

        stakingContract.updateConfiguration(
            _registrationWaitTimeCurrent, 
            _registrationWaitTimeSavings, 
            _stakerFundingAmountCurrent, 
            _stakerFundingAmountSavings
        );
    }

    // should revert if caller does not have staker role for unregister, stake, slash
    function testRevertNotStakerRole() public {
        vm.startPrank(alice);

        vm.expectRevert(abi.encodePacked("Staker does not have role"));
        stakingContract.unregisterStaker(CURRENT_STAKER_ROLE);

        vm.expectRevert(abi.encodePacked("Staker does not have role"));
        stakingContract.stake(CURRENT_STAKER_ROLE);

        vm.expectRevert(abi.encodePacked("Staker does not have role"));
        uint256 slashAmount = 1 ether;
        stakingContract.slash(slashAmount, CURRENT_STAKER_ROLE);

        vm.stopPrank();
    }

    function testRevertInsufficientContractBalanceForTotalStaked() public {
        vm.expectRevert(abi.encodePacked("Insufficient contract balance for total staked"));

        stakingContract.registerStaker(CURRENT_STAKER_ROLE);

        startHoax(address(stakingContract), 10000e18);
        vm.stopPrank();
        stakingContract.registerStaker(CURRENT_STAKER_ROLE);
    }

    // should revert if registration time for role has not not elapsed
    function testRevertRegistrationTimeNotElapsed() public {
        uint256 stakeAmount = 1e18;

        startHoax(address(stakingContract), 10000e18);
        vm.stopPrank();

        startHoax(alice, 2e18);
        vm.stopPrank();
        
        vm.startPrank(alice);

        vm.expectEmit(true, true, false, false, address(stakingContract));
        emit StakerRegistered(alice, CURRENT_STAKER_ROLE);
        
        stakingContract.registerStaker(CURRENT_STAKER_ROLE);

        vm.expectRevert(abi.encodePacked("Registration wait time not elapsed"));
        stakingContract.stake{value: stakeAmount}(CURRENT_STAKER_ROLE);

        skip(stakingContract.registrationWaitTime(CURRENT_STAKER_ROLE) + 1);
        
        vm.expectEmit(true, true, true, false, address(stakingContract));
        emit StakerStaked(alice, CURRENT_STAKER_ROLE, stakeAmount);

        stakingContract.stake{value: stakeAmount}(CURRENT_STAKER_ROLE);
        
        // should update stake balance for role
        assertEq(
            stakingContract.getStakeBalance(alice, CURRENT_STAKER_ROLE), 
            stakeAmount + stakingContract.stakerFundingAmount(CURRENT_STAKER_ROLE),
            "staker staked balance incorrect after staking"
        );

        assertEq(
            alice.balance, 
            2e18 - stakeAmount,
            "staker wallet balance incorrect after staking"
        );

        vm.stopPrank();
    }

    // should register new staker and allocate funds and update lastUpdated timestamp for staker
    function testRegisterNewStaker() public {
        startHoax(address(stakingContract), 10000e18);
        vm.stopPrank();

        startHoax(alice, 2e18);
        vm.stopPrank();

        vm.startPrank(alice);
        stakingContract.registerStaker(CURRENT_STAKER_ROLE);

        vm.expectRevert(abi.encodePacked("Not an unregistered staker"));
        stakingContract.registerStaker(CURRENT_STAKER_ROLE);
    
        assertEq(
            stakingContract.getStakeBalance(alice, CURRENT_STAKER_ROLE), 
            stakingContract.stakerFundingAmount(CURRENT_STAKER_ROLE),
            "staker not funded upon registration"
        );

        assertEq(stakingContract.getLastUpdatedTimestamp(alice), block.timestamp);
        vm.stopPrank();
    }

    // should re-register an unregistered staker and not allocate funds
    function testReRegisterOldStaker() public {
        startHoax(address(stakingContract), 10000e18);
        vm.stopPrank();

        startHoax(alice, 2e18);
        vm.stopPrank();

        vm.startPrank(alice);
        stakingContract.registerStaker(CURRENT_STAKER_ROLE);

        vm.expectEmit(true, true, false, false, address(stakingContract));
        emit StakerUnregistered(alice, CURRENT_STAKER_ROLE);

        stakingContract.unregisterStaker(CURRENT_STAKER_ROLE);

        stakingContract.registerStaker(CURRENT_STAKER_ROLE);
    
        assertEq(
            stakingContract.getStakeBalance(alice, CURRENT_STAKER_ROLE), 
            0,
            "staker funded upon second registration"
        );

        vm.stopPrank();
    }

    // should unregister staker and withdraw everything staked
    function testUnregisterStaker() public {
        startHoax(address(stakingContract), 10000e18);
        vm.stopPrank();

        assertEq(
            alice.balance, 
            0, 
            "incorrect balance for new alice wallet"
        );

        startHoax(alice, 2e18);
        vm.stopPrank();

        vm.startPrank(alice);
        stakingContract.registerStaker(CURRENT_STAKER_ROLE);

        stakingContract.unregisterStaker(CURRENT_STAKER_ROLE);
    
        assertEq(
            stakingContract.getStakeBalance(alice, CURRENT_STAKER_ROLE), 
            0,
            "staker funded upon second registration"
        );

        uint256 balanceAfterUnregister = alice.balance;
        assertEq(
            balanceAfterUnregister, 
            stakingContract.stakerFundingAmount(CURRENT_STAKER_ROLE) + 2e18, 
            "user funds not returned after unregister"
        );

        vm.stopPrank();
    }

    // should not stake zero amount and update stake balance for role
    function testRevertStakeZeroAmount() public {
        uint256 stakeAmount = 0;

        startHoax(address(stakingContract), 10000e18);
        vm.stopPrank();

        startHoax(alice, 2e18);
        vm.stopPrank();
        
        vm.startPrank(alice);
        stakingContract.registerStaker(CURRENT_STAKER_ROLE);

        skip(stakingContract.registrationWaitTime(CURRENT_STAKER_ROLE) + 1);
        
        vm.expectRevert(abi.encodePacked("Cannot stake zero amount"));
        stakingContract.stake{value: stakeAmount}(CURRENT_STAKER_ROLE);
        
        // should update stake balance for role and wallet balance
        assertEq(
            stakingContract.getStakeBalance(alice, CURRENT_STAKER_ROLE), 
            stakeAmount + stakingContract.stakerFundingAmount(CURRENT_STAKER_ROLE),
            "staker staked balance incorrect after staking"
        );

        assertEq(
            alice.balance, 
            2e18 - stakeAmount,
            "staker wallet balance incorrect after staking"
        );

        vm.stopPrank();
    }

    // should slash and update stake balance for role
    function testSlashStake() public {
        uint256 stakeAmount = 1e18;
        uint256 slashAmount = 1e10;

        startHoax(address(stakingContract), 10000e18);
        vm.stopPrank();

        startHoax(alice, 2e18);
        vm.stopPrank();
        
        vm.startPrank(alice);
        stakingContract.registerStaker(CURRENT_STAKER_ROLE);

        skip(stakingContract.registrationWaitTime(CURRENT_STAKER_ROLE) + 1);
        
        stakingContract.stake{value: stakeAmount}(CURRENT_STAKER_ROLE);
        
        vm.expectEmit(true, true, true, false, address(stakingContract));
        emit StakerSlashed(alice, CURRENT_STAKER_ROLE, stakeAmount);

        stakingContract.slash(slashAmount, CURRENT_STAKER_ROLE);

        // should update stake balance for role and wallet balance
        assertEq(
            stakingContract.getStakeBalance(alice, CURRENT_STAKER_ROLE), 
            stakeAmount + stakingContract.stakerFundingAmount(CURRENT_STAKER_ROLE) - slashAmount,
            "staker staked balance incorrect after slashing"
        );

        assertEq(
            alice.balance, 
            2e18 - stakeAmount + slashAmount,
            "staker wallet balance incorrect after slashing"
        );

        vm.stopPrank();
    }

    // should not slash above stake balance for specific role
    function testRevertSlashStakeAmount() public {
        uint256 stakeAmount = 1e18;
        uint256 slashAmount = 1e19;

        startHoax(address(stakingContract), 10000e18);
        vm.stopPrank();

        startHoax(alice, 2e18);
        vm.stopPrank();
        
        vm.startPrank(alice);
        stakingContract.registerStaker(CURRENT_STAKER_ROLE);

        skip(stakingContract.registrationWaitTime(CURRENT_STAKER_ROLE) + 1);
        
        stakingContract.stake{value: stakeAmount}(CURRENT_STAKER_ROLE);

        vm.expectRevert(abi.encodePacked("Balance cannot fund slash amount"));
        stakingContract.slash(slashAmount, CURRENT_STAKER_ROLE);

        // should update stake balance for role and wallet balance
        assertEq(
            stakingContract.getStakeBalance(alice, CURRENT_STAKER_ROLE), 
            stakeAmount + stakingContract.stakerFundingAmount(CURRENT_STAKER_ROLE),
            "staker staked balance incorrect after slashing"
        );

        assertEq(
            alice.balance, 
            2e18 - stakeAmount,
            "staker wallet balance incorrect after slashing"
        );

        vm.stopPrank();
    }
}
