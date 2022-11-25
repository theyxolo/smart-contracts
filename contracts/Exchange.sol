// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

import '@openzeppelin/contracts/access/Ownable.sol';

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Exchange is IERC721Receiver, Ownable, ReentrancyGuard, Pausable {
	struct Gift {
		address participant;
		address contractAddress;
		uint256 tokenId;
	}

	uint256 xmasTimestamp = 1640688000;

	Gift[] gifts;

	mapping(address => bool) participantsAlreadyClaimed;
	mapping(address => bool) participants;

	constructor() {
		//
	}

	function onERC721Received(
		address,
		address _from,
		uint256 _tokenId,
		bytes calldata
	) external returns (bytes4) {
		require(!participants[_from], 'You already sent a gift');

		gifts.push(Gift(_from, _msgSender(), _tokenId));
		participants[_from] = true;

		return this.onERC721Received.selector;
	}

	function listPresents() external view returns (Gift[] memory) {
		uint256 giftsCount = gifts.length;

		Gift[] memory _gifts = new Gift[](giftsCount);

		for (uint256 i = 0; i < giftsCount; i++) {
			_gifts[i] = gifts[i];
		}

		return _gifts;
	}

	function claimPresent() external nonReentrant whenNotPaused {
		// require(block.timestamp >= xmasTimestamp, 'Not yet available');

		require(
			!participantsAlreadyClaimed[_msgSender()],
			'Exchange: you have already claimed your gift'
		);
		require(gifts.length > 0, 'Exchange: no gifts available');
		require(participants[_msgSender()], 'Exchange: you did not send a gift');

		uint256 giftsCount = gifts.length;

		Gift memory gift = gifts[giftsCount - 1];

		require(
			gift.participant != _msgSender(),
			'Exchange: you cannot claim your own gift'
		);

		IERC721(gift.contractAddress).safeTransferFrom(
			address(this),
			_msgSender(),
			gift.tokenId
		);

		gifts.pop();
		participantsAlreadyClaimed[_msgSender()] = true;
	}

	function ownerClaimGift(address _toAddress) external onlyOwner {
		uint256 giftsCount = gifts.length;

		require(giftsCount > 0, 'No gifts available');

		Gift memory gift = gifts[giftsCount - 1];
		gifts.pop();

		IERC721(gift.contractAddress).safeTransferFrom(
			address(this),
			_toAddress,
			gift.tokenId
		);
	}
}
