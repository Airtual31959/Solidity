//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Vote {
    enum VoteStatus {
        NotVoted,
        Voted
    }

    mapping(address => VoteStatus) voteStatus;
    mapping(uint256 => uint256) voteCounts;

    modifier onlyOnce(address _voter) {
        require(voteStatus[_voter] == VoteStatus.NotVoted);
        _;
        voteStatus[msg.sender] = VoteStatus.Voted;
    }

    function vote(uint256 _candidateId) public onlyOnce(msg.sender) {
        voteCounts[_candidateId] += 1;
    }

    function getVoteCount(uint256 _candidateId) public view returns (uint256) {
        return voteCounts[_candidateId];
    }
}
