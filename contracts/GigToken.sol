// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

contract GigToken is ERC1155, Ownable {
    uint256 public constant gigToken = 0;
    uint256 public gigWorkerCount;
    uint256 public moderatorCount;
    uint256 welcome;
    mapping(address => bool) public gigWorkers;
    mapping(address => mapping(uint256 => string)) public moderator;
    mapping(address => uint256) public deposit;

    constructor() ERC1155("") {
        _mint(msg.sender, gigToken, 10**18, "");
        gigWorkerCount = 0;
        moderatorCount = 0;
        welcome = 100;
    }

    function mintGigToken(uint256 amount) private onlyOwner {
        _mint(msg.sender, 0, amount, "");
    }

    function welcomeToken(address gigWorker) external onlyOwner {
        require(gigWorkers[gigWorker] == false, "Already residtered");
        gigWorkerCount++;
        _safeTransferFrom(msg.sender, gigWorker, 0, welcome, "");
        _setApprovalForAll(gigWorker, msg.sender, true);
    }

    function addNewModerator(address gigWorker, string memory tokenUri)
        external
        onlyOwner
    {
        moderatorCount++;
        uint256 moderatorId = moderatorCount;
        _mint(gigWorker, moderatorId, 1, "");
        moderator[gigWorker][moderatorId] = tokenUri;
    }

    function depositToken(address gigWorker, uint256 amount) external {
        require(balanceOf(gigWorker, 0) < amount, "Insufficient funds");
        deposit[gigWorker] += amount;
        _safeTransferFrom(gigWorker, msg.sender, 0, amount, "");
    }

    function withdrawDeposit(address gigWorker, uint256 amount) external {
        require(deposit[gigWorker] >= amount, "Insufficient funds");
        deposit[gigWorker] -= amount;
        _safeTransferFrom(msg.sender, gigWorker, 0, amount, "");
    }
}
