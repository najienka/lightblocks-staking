// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/AccessControl.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";


contract Staking is AccessControl, Initializable {
    // field variables

    // roles
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // There are two roles for staking, current account and savings account
    bytes32 public constant CURRENT_STAKER_ROLE =
        keccak256("CURRENT_STAKER_ROLE");
    bytes32 public constant SAVINGS_STAKER_ROLE =
        keccak256("SAVINGS_STAKER_ROLE");
    // staker properties
    struct Staker {
        uint256 lastUpdatedTimestamp;
        mapping(bytes32 => uint256) registrationTimestamps;
        // current or savings staker
        mapping(bytes32 => bool) roles;
        // current or savings staking balances
        mapping(bytes32 => uint256) balances;
    }
    // stakers
    mapping(address => Staker) public stakers;
    // total amount staked
    uint256 public totalStaked;

    // Configuration parameters
    mapping(bytes32 => uint256) public registrationWaitTime;
    mapping(bytes32 => uint256) public stakerFundingAmount;

    // events
    event StakerRegistered(address indexed staker, bytes32 role);
    event StakerUnregistered(address indexed staker, bytes32 role);
    event StakerStaked(address indexed staker, bytes32 role, uint256 amount);
    event StakerSlashed(address indexed staker, bytes32 role, uint256 amount);

    // modifiers to minimise code repetition
    modifier onlyAdmin() {
        // ensure caller has admin role
        require(hasRole(ADMIN_ROLE, msg.sender), "Not an admin");
        _;
    }

    modifier hasStakerRole(bytes32 role) {
        // Ensure caller has one of staker roles
        require(stakers[msg.sender].roles[role], "Staker does not have role");
        _;
    }

    modifier registrationWaitTimeElapsed(bytes32 role) {
        // Ensure that registration wait time has passed
        require(
            (block.timestamp -
                stakers[msg.sender].registrationTimestamps[role]) >=
                registrationWaitTime[role],
            "Registration wait time not elapsed"
        );
        _;
    }

    modifier onlyValidRoles(bytes32 role) {
        require(
            (role == CURRENT_STAKER_ROLE) || (role == SAVINGS_STAKER_ROLE),
            "Role must be current or savings staker role"
        );
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint256 _registrationWaitTimeCurrent,
        uint256 _registrationWaitTimeSavings,
        uint256 _stakerFundingAmountCurrent,
        uint256 _stakerFundingAmountSavings
    ) initializer public {
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        registrationWaitTime[
            CURRENT_STAKER_ROLE
        ] = _registrationWaitTimeCurrent;
        registrationWaitTime[
            SAVINGS_STAKER_ROLE
        ] = _registrationWaitTimeSavings;
        stakerFundingAmount[CURRENT_STAKER_ROLE] = _stakerFundingAmountCurrent;
        stakerFundingAmount[SAVINGS_STAKER_ROLE] = _stakerFundingAmountSavings;
    }

    /**
     * @dev This function is called when the contract receives Ether without any data.
     * It is marked as external and payable to handle plain Ether transfers.
     */
    receive() external payable {}

    /**
     * @dev This function is only called by an address with admin role,
     * to update the smart contract configuration
     */
    function updateConfiguration(
        uint256 _registrationWaitTimeCurrent,
        uint256 _registrationWaitTimeSavings,
        uint256 _stakerFundingAmountCurrent,
        uint256 _stakerFundingAmountSavings
    ) external onlyAdmin {
        registrationWaitTime[
            CURRENT_STAKER_ROLE
        ] = _registrationWaitTimeCurrent;
        registrationWaitTime[
            SAVINGS_STAKER_ROLE
        ] = _registrationWaitTimeSavings;
        stakerFundingAmount[CURRENT_STAKER_ROLE] = _stakerFundingAmountCurrent;
        stakerFundingAmount[SAVINGS_STAKER_ROLE] = _stakerFundingAmountSavings;
    }

    /**
     * @dev This function is called by any address,
     * to register as a staker for a current or savings staking account.
     * Depending on the contract configuration for the staker role, upon registration,
     * an amount of Ether is allocated to the callers address.
     */
    function registerStaker(bytes32 role) external onlyValidRoles(role) {
        stakers[msg.sender].lastUpdatedTimestamp = block.timestamp;

        // only unregistered staker
        require(!stakers[msg.sender].roles[role], "Not an unregistered staker");

        // assign role
        stakers[msg.sender].roles[role] = true;

        // check if first registration, set registration timestamp and allocate funds
        if (stakers[msg.sender].registrationTimestamps[role] == 0) {
            stakers[msg.sender].registrationTimestamps[role] = block.timestamp;
            // increment total staked
            totalStaked += stakerFundingAmount[role];
            // ensure contract balance is enough to cover allocation
            // check new total staked <= contract balance
            // balance could include other stakes too
            // plus admin transfers to contract
            require(
                totalStaked <= address(this).balance,
                "Insufficient contract balance for total staked"
            );
            // allocate funds to the staker if first registration
            stakers[msg.sender].balances[role] = stakerFundingAmount[role];
        }

        emit StakerRegistered(msg.sender, role);
    }

    /**
     * @dev This function is called by any address,
     * that is a register current or savings account staker
     * to unregister. The function sends the total staked balance
     * for that account role to the caller.
     */
    function unregisterStaker(bytes32 role) external hasStakerRole(role) {
        stakers[msg.sender].lastUpdatedTimestamp = block.timestamp;

        // revoke role
        stakers[msg.sender].roles[role] = false;
        // transfer remaining funds back to the staker
        uint256 amount = stakers[msg.sender].balances[role];
        // decrease total staked
        totalStaked -= amount;
        // should reduce balance to zero
        stakers[msg.sender].balances[role] -= amount;
        // transfer amount
        payable(msg.sender).transfer(amount);

        emit StakerUnregistered(msg.sender, role);
    }

    /**
     * @dev This function is called by any address,
     * that is a register current or savings account staker
     * to stake an amount of ether which will be assigned to their
     * current or savings account / role.
     */
    function stake(
        bytes32 role
    ) external payable hasStakerRole(role) registrationWaitTimeElapsed(role) {
        stakers[msg.sender].lastUpdatedTimestamp = block.timestamp;

        require(msg.value > 0, "Cannot stake zero amount");
        // update balance
        stakers[msg.sender].balances[role] += msg.value;
        // increase total staked
        totalStaked += msg.value;

        // emit event
        emit StakerStaked(msg.sender, role, msg.value);
    }

    /**
     * @dev This function is called by any address,
     * that is a register current or savings account staker
     * to unstake an amount of ether which must have been assigned to their
     * current or savings account / role in a previous transaction.
     * Either upon registration or upon staking.
     */
    function slash(
        uint256 amount,
        bytes32 role
    ) external hasStakerRole(role) registrationWaitTimeElapsed(role) {
        stakers[msg.sender].lastUpdatedTimestamp = block.timestamp;

        require(
            stakers[msg.sender].balances[role] >= amount,
            "Balance cannot fund slash amount"
        );
        // update balance
        stakers[msg.sender].balances[role] -= amount;
        // decrease total staked
        totalStaked -= amount;
        // transfer amount to staker
        payable(msg.sender).transfer(amount);

        // emit event
        emit StakerSlashed(msg.sender, role, amount);
    }

    function getStakeBalance(address staker, bytes32 role) external view  returns (uint256) {
        return stakers[staker].balances[role];
    }

    function getLastUpdatedTimestamp(address staker) external view  returns (uint256) {
        return stakers[staker].lastUpdatedTimestamp;
    }
}
