// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault {
    bool public emergencyMode = false;
    address public admin;
    address public defiProjectA;
    address public defiProjectB;

    address[] public defiProjects;

    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public defiAllocation;
    mapping(address => bool) public supportedTokens;

    constructor(address _projectA, address _projectB) {
        defiProjectA = _projectA;
        defiProjectB = _projectB;
        admin = msg.sender;
    }

    modifier OnlyAdmin(address user) {
        require(user == admin, "No permission");
        _;
    }

    modifier OnlyNonEmergency() {
        require(emergencyMode == false, "Emergency Mode");
        _;
    }

    event Deposit(address indexed user, address indexed token, uint256 amount);
    event Withdraw(address indexed user, address indexed token, uint256 amount);
    event StakeToProjectA(address indexed user, uint256 amount);
    event StakeToProjectB(address indexed user, uint256 amount);
    event EmergencyTriggered(address indexed admin);
    event EmergencyResolved(address indexed admin);

    function authorizeToken(address token) public OnlyAdmin(msg.sender) {
        // require();
        supportedTokens[token] = true;
    }

    function deposit(address token, uint256 amount) public OnlyNonEmergency {
        require(supportedTokens[token], "Token not supported");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        balances[token] += amount;
        emit Deposit(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) public OnlyNonEmergency {
        require(balances[token] >= amount, "Insufficient balance");
        balances[token] -= amount;
        IERC20(token).transfer(msg.sender, amount);
        emit Withdraw(msg.sender, token, amount);
    }

    function stakeToProjectA(uint256 amount) public OnlyNonEmergency {
        require(
            balances[address(this)] >= amount,
            "Insufficient balance in Vault"
        );
        IERC20(defiProjectA).transfer(defiProjectA, amount);
        defiAllocation[msg.sender][defiProjectA] += amount;
        emit StakeToProjectA(msg.sender, amount);
    }

    function stakeToProjectB(uint256 amount) public OnlyNonEmergency {
        require(
            balances[address(this)] >= amount,
            "Insufficient balance in Vault"
        );
        IERC20(defiProjectB).transfer(defiProjectB, amount);
        defiAllocation[msg.sender][defiProjectB] += amount;
        emit StakeToProjectB(msg.sender, amount);
    }

    function emergencyWithdraw(address token) public {
        require(emergencyMode);
        uint256 amount = balances[token];
        balances[token] = 0;
        IERC20(token).transfer(msg.sender, amount);
        emit EmergencyResolved(msg.sender);
    }

    function triggerEmergency() public OnlyAdmin(msg.sender) {
        emergencyMode = true;
        emit EmergencyTriggered(msg.sender);
    }

    function resolveEmergency() public OnlyAdmin(msg.sender) {
        emergencyMode = false;
        emit EmergencyResolved(msg.sender);
    }
}

contract ProfitFarm {}

contract LendingProtocol {}
