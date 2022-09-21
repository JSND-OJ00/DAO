// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./GigToken.sol";
// import "https://github.com/MyAccount/ContractRepository/Contract.sol";

error NotModerator();

contract DAO is ERC1155Holder {
    GigToken gigToken;
    address public owner;
    uint256 proposalCount;
    mapping(uint256 => proposal) public Proposals;

    constructor() {
        gigToken = GigToken(0x026f4E00f8c3e7DF259Bd29926b727effD1F9895);
    }

    struct proposal {
        uint256 id;
        address proposer;
        string description;
        uint deadline;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 quorum;
        mapping(address => bool) voted;
        bool passed;
    }

    event newProposal(
        uint256 id,
        string description,
        uint256 quorum,
        address proposer
    );

    event newVote(
        uint256 proposal,
        uint256 votesFor,
        uint256 votesAgainst,
        address voter,
        bool votedFor
    );

    event proposalPassed(uint256 id, bool passed);
    // event proposalNotPassed(uint256 id, bool notPassed);

    modifier gigWorkerOnly(address gigWorker) {
        require(gigToken.balanceOf(gigWorker, 0) >= 0, "Gig Workers Only");
        _;
    }

    modifier moderatorOnly(address gigWorker, uint256 moderatorId) {
        if (gigToken.balanceOf(gigWorker, moderatorId) != 1) {
            revert NotModerator();
        }
        _;
    }

    function getQuorum() public view returns (uint256) {
        return gigToken.gigWorkerCount() / 2;
    }

    function createProposal(
        address gigWorker,
        uint256 moderatorId,
        uint256 deposit,
        string memory _description
    ) public moderatorOnly(gigWorker, moderatorId) {
        proposal storage _Proposal = Proposals[proposalCount];
        _Proposal.id = proposalCount;
        _Proposal.proposer = gigWorker;
        _Proposal.description = _description;
        _Proposal.deadline = block.number + 100;
        _Proposal.quorum = getQuorum();

        emit newProposal(
            proposalCount,
            _description,
            _Proposal.quorum,
            gigWorker
        );
        proposalCount++;

        gigToken.depositToken(gigWorker, deposit);
    }

    function voteOnProposal(
        address gigWorker,
        uint256 proposalId,
        bool vote
    ) public gigWorkerOnly(gigWorker) {
        require(!Proposals[proposalId].voted[gigWorker], "Already voted");
        require(
            block.number <= Proposals[proposalId].deadline,
            "Proposal is over"
        );

        proposal storage _proposal = Proposals[proposalId];

        if (vote) {
            _proposal.votesFor++;
        } else {
            _proposal.votesAgainst++;
        }

        _proposal.voted[gigWorker] = true;

        emit newVote(
            proposalId,
            _proposal.votesFor,
            _proposal.votesAgainst,
            gigWorker,
            vote
        );
    }

    function countVotes(uint256 proposalId, address gigWorker) public {
        require(
            Proposals[proposalId].proposer == gigWorker,
            "Only proposer can count"
        );
        require(
            block.number > Proposals[proposalId].deadline,
            "Voting is not over"
        );

        proposal storage _proposal = Proposals[proposalId];

        if (_proposal.quorum >= _proposal.votesFor) {
            _proposal.passed = true;
            emit proposalPassed(proposalId, _proposal.passed);
            // deposit 돌려주기 + 보상
        }

        // 정족수를 넘지 못한 경우
        // emit poroposalNotPassed
        // deposit 조금 차감하고 돌려주기
    }
}