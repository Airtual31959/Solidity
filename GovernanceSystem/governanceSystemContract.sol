// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GovernanceLogic {
    struct Proposal {
        address proposer;
        string proposalDescription;
        uint256 yesVotes;
        uint256 noVotes;
        bool executed;
    }

    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;

    event ProposalSubmitted(
        uint256 proposalId,
        address proposer,
        string description
    );
    event Voted(address voter, uint256 proposalId, bool support);
    event ProposalExecuted(uint256 proposalId, bool executed);

    function submitProposal(string memory _description) public {
        proposalCount++;
        proposals[proposalCount] = Proposal(
            msg.sender,
            _description,
            0,
            0,
            false
        );
        emit ProposalSubmitted(proposalCount, msg.sender, _description);
    }

    function voteOnProposal(uint256 _proposalId, bool _support) public {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");

        if (_support) {
            proposal.yesVotes++;
        } else {
            proposal.noVotes++;
        }

        emit Voted(msg.sender, _proposalId, _support);
    }

    function executeProposal(uint256 _proposalId) public {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");

        if (proposal.yesVotes > proposal.noVotes) {
            proposal.executed = true;
            emit ProposalExecuted(_proposalId, true);
        } else {
            proposal.executed = false;
            emit ProposalExecuted(_proposalId, false);
        }
    }
}

contract GovernanceProxy {
    address public governanceLogic;
    address public owner;
    mapping(address => address) public delegatedTo;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyDelegates(address _voter) {
        require(delegatedTo[_voter] == msg.sender, "Not authorized to vote");
        _;
    }

    constructor(address _governanceLogic) {
        governanceLogic = _governanceLogic;
        owner = msg.sender;
    }

    // Upgrade governance logic contract
    function upgradeGovernanceLogic(address _newLogic) external onlyOwner {
        governanceLogic = _newLogic;
    }

    // Submit proposal (via delegatecall to governance logic)
    function submitProposal(string memory _description) external {
        (bool success, ) = governanceLogic.delegatecall(
            abi.encodeWithSignature("submitProposal(string)", _description)
        );
        require(success, "Proposal submission failed");
    }

    // Vote on proposal (via delegatecall to governance logic)
    function voteOnProposal(uint256 _proposalId, bool _support)
        external
        onlyDelegates(msg.sender)
    {
        (bool success, ) = governanceLogic.delegatecall(
            abi.encodeWithSignature(
                "voteOnProposal(uint256,bool)",
                _proposalId,
                _support
            )
        );
        require(success, "Voting failed");
    }

    // Execute proposal (via delegatecall to governance logic)
    function executeProposal(uint256 _proposalId) external {
        (bool success, ) = governanceLogic.delegatecall(
            abi.encodeWithSignature("executeProposal(uint256)", _proposalId)
        );
        require(success, "Proposal execution failed");
    }

    // Delegate voting rights to another address
    function delegateVoting(address _delegate) external {
        delegatedTo[msg.sender] = _delegate;
    }
}
