// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FundsManager is ReentrancyGuard {
    struct Account {
        address accountAddress;
        uint256 balance;
    }

    struct Author {
        address externalAddress;
        uint256 authorBalance;
        bool isAuthor;
    }

    mapping(address => Author) public authorizes;
    mapping(address => Account) public accounts;

    modifier onlyEnough(address _accountAddress, uint256 _amount) {
        require(
            accounts[_accountAddress].balance >= _amount,
            "[Failed] Funds Manager Contract: onlyEnough: Insufficient balance"
        );
        _;
    }
    modifier onlyAuthor(address externalAddress) {
        require(authorizes[externalAddress].isAuthor);
        _;
    }

    // constructor() payable {}

    function deposit(uint256 _amount) public payable {
        require(msg.value == _amount, "[Failed] Funds Manager Contract: deposit function: Incorrect input");
        if (accounts[msg.sender].accountAddress == address(0)) {
            accounts[msg.sender].accountAddress = msg.sender;
            accounts[msg.sender].balance = 0;
        }
        accounts[msg.sender].balance += _amount;
    }

    function withdraw(uint256 _amount)
        public
        payable
        onlyEnough(msg.sender, _amount)
        nonReentrant
    {
        require(
            accounts[msg.sender].accountAddress != address(0),
            "[Failed] Funds Manager Contract: withdraw function: Account does not exist"
        );
        require(
            address(this).balance >= _amount,
            "[Failed] Funds Manager Contract: withdraw function: Not enough balance in contract"
        );

        accounts[msg.sender].balance -= _amount;

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "[Failed] Funds Manager Contract: withdraw function: Withdraw failed");
    }

    function externalWithdraw(address _from, uint256 _amount)
        public
        payable
        onlyEnough(msg.sender, _amount)
        onlyAuthor(_from)
        nonReentrant
    {
        require(authorizes[_from].authorBalance >= _amount);
        accounts[msg.sender].balance += _amount;
        authorizes[_from].authorBalance -= _amount;

        (bool success, ) = _from.call(
            abi.encodeWithSignature(
                "withdraw(address,uint256)",
                address(this),
                _amount
            )
        );
        require(success, "[Failed] Funds Manager Contract: externalWithdraw function: Call failed");
    }

    function transfer(address _to, uint256 _amount)
        public
        payable
        onlyEnough(msg.sender, _amount)
        onlyAuthor(_to)
    {
        // require(msg.value == _amount, "Incorrect amount sent");
        accounts[msg.sender].balance -= _amount;
        authorizes[_to].authorBalance += _amount;

        (bool success, ) = _to.call{value: _amount}(
            abi.encodeWithSignature("deposit(address,uint256)", _to, _amount)
        );
        require(success, "[Failed] Funds Manager Contract: transfer function: Call failed");
    }

    function authorize(address _spender, uint256 _amount)
        public
        onlyEnough(msg.sender, _amount)
    {
        authorizes[_spender] = Author({
            externalAddress: _spender,
            authorBalance: _amount,
            isAuthor: true
        });
    }

    receive() external payable {}
}

contract ExternalContract {
    struct Account {
        address accountAddress;
        uint256 balance;
    }

    mapping(address => Account) public accounts;

    function deposit(address _to, uint256 _amount) external payable {
        // require(msg.value == _amount, "Incorrect amount sent");
        accounts[msg.sender].accountAddress = msg.sender;
        accounts[msg.sender].balance += _amount;

        (bool success, ) = _to.call{value: _amount}("");
        require(success, "[Failed] External Contract: deposit function: Deposit failed");
    }

    function withdraw(address _from, uint256 _amount) external payable {
        require(
            accounts[msg.sender].accountAddress != address(0),
            "[Failed] External Contract: withdraw function: Account does not exist"
        );
        require(
            accounts[msg.sender].balance >= _amount,
            "[Failed] External Contract: withdraw function: Insufficient balance"
        );

        accounts[msg.sender].balance -= _amount;
        (bool success, ) = _from.call{value: _amount}("");
        require(success, "[Failed] External Contract: Withdraw failed");
    }

    receive() external payable {}
}
