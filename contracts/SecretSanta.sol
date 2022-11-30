// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title SecretSanta
/// @author cesargdm.eth

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import '@openzeppelin/contracts/access/Ownable.sol';

import '@openzeppelin/contracts/security/Pausable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

/**
 * @dev This implementation uses Ownable, a Multisig wallet would be the best
 * owner of this contract or some kind of governance system.
 */
contract SecretSanta is IERC721Receiver, Ownable, ReentrancyGuard, Pausable {
	struct Gift {
		address participant;
		address collection;
		uint256 itemId;
	}

	uint256 public receiveTimestamp;

	Gift[] private availableGifts;

	mapping(address => bool) private allParticipants;
	/**
	 * Track participants that have already claimed their gift
	 */
	mapping(address => bool) private participantsReceived;

	/**
	 * @dev Better than allowlisting wallets, we allowlist collections
	 * this can be used to make exchanges between small and large communities
	 */
	mapping(address => bool) public allowedCollections;

	constructor(uint256 _receiveTimestamp) {
		receiveTimestamp = _receiveTimestamp;
	}

	/**
	 * @dev This doesnt prevent malicious collections from transfering a token,
	 * but won't not take into account any tokens that are not allowed
	 * @notice Don't transfer tokens if your collection is not allowed
	 */
	function onERC721Received(
		address,
		address _from,
		uint256 _tokenId,
		bytes calldata
	) external whenNotPaused returns (bytes4) {
		require(!allParticipants[_from], 'SecretSanta: you already sent a gift');
		require(
			block.timestamp <= receiveTimestamp,
			'SecretSanta: you can no longer send a gift'
		);
		require(
			allowedCollections[_msgSender()],
			'SecretSanta: this collection is not allowed'
		);

		availableGifts.push(Gift(_from, _msgSender(), _tokenId));
		allParticipants[_from] = true;

		return this.onERC721Received.selector;
	}

	/*

		R E C E I V E

	*/

	/**
	 * @dev Withdraws the NFT from the contract and sends it to the participant
	 */
	function receiveGift() external nonReentrant whenNotPaused {
		require(
			block.timestamp > receiveTimestamp,
			'SecretSanta: receive not yet available'
		);
		require(
			!participantsReceived[_msgSender()],
			'SecretSanta: you have already claimed your gift'
		);
		require(
			allParticipants[_msgSender()],
			'SecretSanta: you are not a participant'
		);
		require(this.giftsCount() > 0, 'SecretSanta: no presents available');

		Gift memory gift = availableGifts[this.giftsCount() - 1];

		require(
			gift.participant != _msgSender(),
			'SecretSanta: you cannot receive your own gift'
		);

		IERC721(gift.collection).safeTransferFrom(
			address(this),
			_msgSender(),
			gift.itemId
		);

		availableGifts.pop();

		participantsReceived[_msgSender()] = true;
	}

	/*

		A D M I N

	*/

	/**
	 * @dev Intended to be used when we face an issue with the regular
	 * process of receiving a gift. Only to be used as the last resort.
	 */
	function transferPresent(
		address _collection,
		address _toAddress,
		uint256 _itemId
	) external onlyOwner whenPaused {
		IERC721(_collection).safeTransferFrom(address(this), _toAddress, _itemId);
	}

	/*

		U T I L I T I E S

	*/

	/**
	 * @dev Set the timestamp when participants can start receiving their gifts
	 */
	function setReceiveTimestamp(uint256 _timestamp) external onlyOwner {
		receiveTimestamp = _timestamp;
	}

	/**
	 * @dev Add a collection to the allowedCollections
	 */
	function setAllowedCollection(address _collection) external onlyOwner {
		allowedCollections[_collection] = true;
	}

	function isParticipant(address _address) external view returns (bool) {
		return allParticipants[_address] || false;
	}

	function giftsCount() external view returns (uint256) {
		return availableGifts.length;
	}

	function gifts() external view returns (Gift[] memory) {
		Gift[] memory _gifts = new Gift[](this.giftsCount());

		for (uint256 i = 0; i < this.giftsCount(); i++) {
			_gifts[i] = availableGifts[i];
		}

		return _gifts;
	}
}
