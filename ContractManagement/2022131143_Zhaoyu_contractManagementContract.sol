//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract ContractManagement {
    struct UserAccount {
        string userName;
        uint256 userAge;
        string userEmail;
        address accountAddress;
        uint256 registrationTime;
    }
    mapping(address => UserAccount) UserAccounts;

    function registerAccount(
        string memory _userName,
        uint256 _userAge,
        string memory _userEmail
    ) public returns (string memory message) {
        require(bytes(_userName).length > 0, "User name cannot be empty.");
        address _userAddress = msg.sender;

        if (UserAccounts[_userAddress].accountAddress == _userAddress) {
            revert("Account already exists.");
        }

        UserAccounts[_userAddress].userName = _userName;
        UserAccounts[_userAddress].userAge = _userAge;
        UserAccounts[_userAddress].userEmail = _userEmail;
        UserAccounts[_userAddress].accountAddress = _userAddress;
        UserAccounts[_userAddress].registrationTime = block.timestamp;

        return "Account successfully registered.";
    }

    function getAccount(address _userAddress)
        public
        view
        returns (UserAccount memory)
    {
        // if (msg.sender != _userAddress) {
        //     revert("No permission to get account");
        // }

        return UserAccounts[_userAddress];
    }

    function updateAccount(address _userAddress, string memory _newEmail)
        public
        returns (string memory result)
    {
        require(msg.sender == _userAddress, "No permission to update account.");
        UserAccounts[_userAddress].userEmail = _newEmail;
        return "Successfully update the account.";
    }

    function deleteAccount(address _userAddress)
        public
        returns (string memory)
    {
        // require(
        //     msg.sender == _userAddress,
        //     "No permission to delete account."
        // );
        require(
            _userAddress != address(0),
            "Delete account fail: Invalid address."
        );

        UserAccount storage user = UserAccounts[_userAddress];
        require(
            bytes(user.userName).length > 0,
            "Delete account fail: Account does not exist."
        );

        user.userName = "";
        user.userAge = 0;
        user.userEmail = "";
        user.accountAddress = address(0);
        user.registrationTime = 0;

        return "Successfully deleted the account.";
    }
}
