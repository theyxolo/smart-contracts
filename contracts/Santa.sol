// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import '@openzeppelin/contracts/access/Ownable.sol';

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Santa is IERC721Receiver, Ownable, ReentrancyGuard, Pausable {
	struct Gift {
		address participant;
		address contractAddress;
		uint256 tokenId;
	}

	// 1671926400
	uint256 public claimTimestamp;

	Gift[] allPresents;

	mapping(address => bool) participants;
	mapping(address => bool) participantsAlreadyClaimed;

	constructor(uint256 _claimTimestamp) {
		claimTimestamp = _claimTimestamp;
	}

	function onERC721Received(
		address,
		address _from,
		uint256 _tokenId,
		bytes calldata
	) external whenNotPaused returns (bytes4) {
		require(!participants[_from], 'Santa: you already sent a gift');
		require(
			block.timestamp <= claimTimestamp,
			'Santa: you can no longer send a gift'
		);

		allPresents.push(Gift(_from, _msgSender(), _tokenId));
		participants[_from] = true;

		return this.onERC721Received.selector;
	}

	function listPresents() external view returns (Gift[] memory) {
		uint256 giftsCount = allPresents.length;

		Gift[] memory _gifts = new Gift[](giftsCount);

		for (uint256 i = 0; i < giftsCount; i++) {
			_gifts[i] = allPresents[i];
		}

		return _gifts;
	}

	function isParticipant(address _address) external view returns (bool) {
		return participants[_address] || false;
	}

	function totalSupply() external view returns (uint256) {
		return allPresents.length;
	}

	function isClaimPresentAvailable() external view returns (bool) {
		return block.timestamp >= claimTimestamp;
	}

	function setClaimTimestamp(uint256 _timestamp) external onlyOwner {
		claimTimestamp = _timestamp;
	}

	function claimPresent() external nonReentrant whenNotPaused {
		require(
			block.timestamp >= claimTimestamp,
			'Santa: claim not yet available'
		);
		require(
			!participantsAlreadyClaimed[_msgSender()],
			'Santa: you have already claimed your gift'
		);
		require(allPresents.length > 0, 'Santa: no presents available');
		require(participants[_msgSender()], 'Santa: you are not a participant');

		uint256 giftsCount = allPresents.length;

		Gift memory gift = allPresents[giftsCount - 1];

		require(
			gift.participant != _msgSender(),
			'Santa: you cannot claim your own gift'
		);

		IERC721(gift.contractAddress).safeTransferFrom(
			address(this),
			_msgSender(),
			gift.tokenId
		);

		allPresents.pop();
		participantsAlreadyClaimed[_msgSender()] = true;
	}

	function ownerClaimGift(address _toAddress) external onlyOwner {
		uint256 giftsCount = allPresents.length;

		require(giftsCount > 0, 'Santa: No allPresents available');

		Gift memory gift = allPresents[giftsCount - 1];
		allPresents.pop();

		IERC721(gift.contractAddress).safeTransferFrom(
			address(this),
			_toAddress,
			gift.tokenId
		);
	}
}
