// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract LimitedTimePayment {
    struct DepositInfo {
        address depositor;
        uint256 amount;
        uint256 depositTime;
        uint256 withdrawTime;
    }

    mapping(address => DepositInfo) public depositInfo;

    modifier onlyAfterTime(address _depositor) {
        require(
            block.timestamp > depositInfo[_depositor].withdrawTime,
            "Withdraw time has not yet passed"
        );
        _;
    }

    function deposit(uint256 _amount, uint256 _withdrawTime) public payable {
        require(
            msg.value == _amount,
            "Amount sent does not match the provided amount"
        );
        require(_withdrawTime > block.timestamp, "Invalid withdraw time");

        DepositInfo memory newDepositInfo = DepositInfo({
            depositor: msg.sender,
            amount: _amount,
            depositTime: block.timestamp,
            withdrawTime: _withdrawTime
        });

        depositInfo[msg.sender] = newDepositInfo;
    }

    function withdraw(uint256 _withdrawalAmount)
        public
        onlyAfterTime(msg.sender)
    {
        uint256 amountToWithdraw = depositInfo[msg.sender].amount; 
        require(
            amountToWithdraw >= _withdrawalAmount,
            "Not enough balance to withdraw"
        );

        depositInfo[msg.sender].amount =
            depositInfo[msg.sender].amount -
            _withdrawalAmount;

        (bool success, ) = payable(msg.sender).call{value: _withdrawalAmount}(
            ""
        );
        require(success, "Transfer failed");
    }

    function getDepositInfo(address _depositor)
        public
        view
        returns (DepositInfo memory)
    {
        return depositInfo[_depositor];
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}
