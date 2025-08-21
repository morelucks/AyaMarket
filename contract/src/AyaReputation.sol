// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Reputation is Ownable {
    mapping(address => uint256) public sellerScore;
    mapping(address => bool) public verifiedSellers;

    event SellerVerified(address indexed seller);
    event ScoreUpdated(address indexed seller, uint256 score);

    constructor(address initialOwner) Ownable(initialOwner) {}

    function verifySeller(address seller) external onlyOwner {
        verifiedSellers[seller] = true;
        emit SellerVerified(seller);
    }

    function updateScore(address seller, uint256 delta) external onlyOwner {
        sellerScore[seller] += delta;
        emit ScoreUpdated(seller, sellerScore[seller]);
    }
}
