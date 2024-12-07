// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract MultiSignatureWallet {
    uint256 public minSignatures;
    address[] public managers; // Managers

    mapping(address => bool) public isManager; // Permission table
    mapping(bytes32 => uint256) public transactionSignatures; 
    mapping(bytes32 => bool) public transactionExecuted;
    mapping(bytes32 => Transaction) public transactions;
    mapping(bytes32 => address[]) public transactionSigners; // Signers table

    struct Transaction {
        address to;
        uint256 amount;
        bytes data;
    }

    modifier onlyManager() {
        require(isManager[msg.sender], "Not a manager");
        _;
    }

    modifier notExecuted(bytes32 _transactionHash) {
        require(
            !transactionExecuted[_transactionHash],
            "Transaction already executed"
        );
        _;
    }

    constructor(address[] memory _managers) {
        for (uint256 i = 0; i < _managers.length; i++) {
            isManager[_managers[i]] = true;
            managers.push(_managers[i]);
        }

        if (_managers.length == 1) {
            minSignatures = 1;
        } else if (_managers.length == 0) {
            revert("Managers is null");
        } else {
            minSignatures = (_managers.length * 2) / 3;
        }
    }

    function submitTransaction(
        address _to,
        uint256 _amount,
        bytes memory _data
    ) public onlyManager {
        bytes32 transactionHash = keccak256(abi.encode(_to, _amount, _data));

        require(
            transactionSignatures[transactionHash] == 0,
            "Transaction already exists"
        );

        // Store the original transaction data
        transactions[transactionHash] = Transaction({
            to: _to,
            amount: _amount,
            data: _data
        });
        transactionSigners[transactionHash].push(msg.sender);
        transactionSignatures[transactionHash] = 0;
    }

    function confirmTransaction(bytes32 _transactionHash) public onlyManager {
        require(
            transactionSignatures[_transactionHash] < minSignatures,
            "Transaction already confirmed"
        );

        for (
            uint256 i = 0;
            i < transactionSigners[_transactionHash].length;
            i++
        ) {
            if (msg.sender == transactionSigners[_transactionHash][i]) {
                revert("Transaction signature repeated");
            }
        }

        transactionSignatures[_transactionHash] += 1;
    }

    function executeTransaction(bytes32 _transactionHash)
        public
        onlyManager
        notExecuted(_transactionHash)
    {
        require(
            transactionSignatures[_transactionHash] >= minSignatures,
            "Transaction not confirmed"
        );

        transactionExecuted[_transactionHash] = true;
        Transaction memory txn = transactions[_transactionHash];

        if (txn.amount > 0) {
            payable(txn.to).transfer(txn.amount);
        }

        if (txn.data.length > 0) {
            (bool success, ) = txn.to.call{value: txn.amount}(txn.data);
            require(success, "Transaction execution failed");
        }
    }

    receive() external payable {}

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
