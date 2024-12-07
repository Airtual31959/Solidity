//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Proxy {
    address public logicContract;
    address public owner;

    error NoPermission(address caller, address callee);

    constructor(address _logicContract) {
        logicContract = _logicContract;
        owner = msg.sender;
    }

    function upgradeLogicContract(address _newLogicContract) public {
        if (msg.sender != owner) {
            revert NoPermission(msg.sender, owner);
        }
        logicContract = _newLogicContract;
    }

    function call(uint256 _value) public returns (bytes memory) {
        address Logic = logicContract;
        require(Logic != address(0), "Logic contract address is zero.");

        (bool success, bytes memory data) = Logic.delegatecall(
            abi.encodeWithSignature("store(uint256)", _value)
        );
        require(success, "Delegatecall failed.");
        return data;
    }
}

contract LogicV1 {
    uint256 public storedValue;

    function store(uint256 _value) public {
        storedValue = _value;
    }

    function get() public view returns (uint256) {
        return storedValue;
    }
}
