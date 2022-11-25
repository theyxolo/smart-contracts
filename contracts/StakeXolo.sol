// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title StakeXolo
/// @author cesargdm.eth

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol';

import '@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';

interface IERC721 {
	function ownerOf(uint256 tokenId) external view returns (address);

	function transferFrom(address from, address to, uint256 tokenId) external;
}

// ERC20
interface ITominToken {
	function mint(address add, uint256 amount) external;
}

interface IERC20 {
	function transfer(address to, uint256 amount) external returns (bool);

	function balanceOf(address account) external view returns (uint256);
}

contract StakeXolo is
	IERC721ReceiverUpgradeable,
	PausableUpgradeable,
	ReentrancyGuardUpgradeable,
	OwnableUpgradeable
{
	using StringsUpgradeable for uint256;

	IERC721 theyXolo;
	ITominToken tomin;
	IERC20 ierc20;

	uint256 public defaultTokenRate;
	uint256[] public rewardTiers;

	mapping(uint256 => mapping(address => uint256)) private tokenIdToStartTime;
	mapping(address => uint256[]) userStakedTokens;
	mapping(uint256 => address) tokenIdToUser;

	function initialize(
		address theyXoloAddress_,
		address tominAddress_
	) public initializer {
		theyXolo = IERC721(theyXoloAddress_);
		tomin = ITominToken(tominAddress_);

		defaultTokenRate = 100;
		rewardTiers = [1, 2, 10, 20, 40];
	}

	function stake(
		uint256[] memory tokenIds
	) external nonReentrant whenNotPaused {
		uint256[] memory _tokenIds = new uint256[](tokenIds.length);

		_tokenIds = tokenIds;

		for (uint256 i; i < _tokenIds.length; i++) {
			require(
				theyXolo.ownerOf(_tokenIds[i]) == msg.sender,
				'Not your They Xolo'
			);

			tokenIdToStartTime[_tokenIds[i]][msg.sender] = block.timestamp;

			theyXolo.transferFrom(msg.sender, address(this), _tokenIds[i]);

			tokenIdToUser[_tokenIds[i]] = msg.sender;
			userStakedTokens[msg.sender].push(_tokenIds[i]);
		}
	}

	function unstake(uint256[] memory tokenIds) external nonReentrant {
		uint256[] memory _tokenIds = new uint256[](tokenIds.length);

		_tokenIds = tokenIds;

		for (uint256 i; i < _tokenIds.length; i++) {
			require(
				tokenIdToUser[_tokenIds[i]] == msg.sender,
				'Not your They Xolo Token'
			);

			theyXolo.transferFrom(address(this), msg.sender, _tokenIds[i]);

			for (uint256 j; j < userStakedTokens[msg.sender].length; j++) {
				if (userStakedTokens[msg.sender][j] == _tokenIds[i]) {
					userStakedTokens[msg.sender][j] = userStakedTokens[msg.sender][
						userStakedTokens[msg.sender].length - 1
					];
					userStakedTokens[msg.sender].pop();
					break;
				}
			}

			uint256 current;
			uint256 reward;

			delete tokenIdToUser[_tokenIds[i]];

			if (tokenIdToStartTime[_tokenIds[i]][msg.sender] > 0) {
				uint256 rate = defaultTokenRate;
				current =
					block.timestamp -
					tokenIdToStartTime[_tokenIds[i]][msg.sender];

				reward = ((rate * 10 ** 18) * current) / 86400;

				tomin.mint(msg.sender, reward);
				tokenIdToStartTime[_tokenIds[i]][msg.sender] = 0;
			}
		}
	}

	function claim() public nonReentrant whenNotPaused {
		require(userStakedTokens[msg.sender].length > 0, 'No tokens staked');

		uint256[] memory tokenIds = new uint256[](
			userStakedTokens[msg.sender].length
		);
		tokenIds = userStakedTokens[msg.sender];

		uint256 current;
		uint256 reward;
		uint256 rewardBalance;

		for (uint256 i; i < tokenIds.length; i++) {
			if (tokenIdToStartTime[tokenIds[i]][msg.sender] > 0) {
				uint256 rate = defaultTokenRate;
				current = block.timestamp - tokenIdToStartTime[tokenIds[i]][msg.sender];
				reward = ((rate * 10 ** 18) * current) / 86400;
				rewardBalance += reward;
				tokenIdToStartTime[tokenIds[i]][msg.sender] = block.timestamp;
			}
		}

		tomin.mint(msg.sender, rewardBalance);
	}

	function balance(uint256 tokenId) public view returns (uint256) {
		uint256 current;
		uint256 reward;

		if (tokenIdToStartTime[tokenId][msg.sender] > 0) {
			uint256 rate = defaultTokenRate;
			current = block.timestamp - tokenIdToStartTime[tokenId][msg.sender];
			reward = ((rate * 10 ** 18) * current) / 86400;

			return reward;
		}

		return 0;
	}

	function balanceOf(address account) public view returns (uint256) {
		uint256[] memory tokenIds = new uint256[](userStakedTokens[account].length);

		tokenIds = userStakedTokens[account];

		uint256 current;
		uint256 reward;
		uint256 rewardBalance;

		for (uint256 i; i < tokenIds.length; i++) {
			if (tokenIdToStartTime[tokenIds[i]][account] > 0) {
				uint256 rate = defaultTokenRate;

				current = block.timestamp - tokenIdToStartTime[tokenIds[i]][account];
				reward = ((rate * 10 ** 18) * current) / 86400;
				rewardBalance += reward;
			}
		}

		return rewardBalance;
	}

	function deposits(address account) public view returns (uint256[] memory) {
		return userStakedTokens[account];
	}

	function withdrawErc20(address _tokenAddress, address to) public onlyOwner {
		IERC20(_tokenAddress).transfer(to, ierc20.balanceOf(address(this)));
	}

	function setDefaultTokenRate(uint256 _defaultTokenRate) public onlyOwner {
		defaultTokenRate = _defaultTokenRate;
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		return IERC721ReceiverUpgradeable.onERC721Received.selector;
	}
}
