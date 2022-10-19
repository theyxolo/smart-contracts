// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title StakeXolo
/// @author cesargdm.eth

import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

interface IERC721 {
	function ownerOf(uint256 tokenId) external view returns (address);

	function transferFrom(
		address from,
		address to,
		uint256 tokenId
	) external;
}

// ERC20
interface ITominToken {
	function mint(address add, uint256 amount) external;
}

interface IERC20 {
	function transfer(address to, uint256 amount) external returns (bool);

	function balanceOf(address account) external view returns (uint256);
}

contract StakeXolo is IERC721Receiver, Ownable {
	using Strings for uint256;

	IERC721 theyXolo;
	ITominToken tomin;
	IERC20 ierc20;

	bool public isStarted = true;
	uint256 public defaultTokenRate = 100;

	mapping(uint256 => mapping(address => uint256)) private idToStartingTime;
	mapping(address => uint256[]) xolosStaked;
	mapping(uint256 => address) idToStaker;

	constructor(address _theyXoloAddress, address _tominAddress) {
		theyXolo = IERC721(_theyXoloAddress);
		tomin = ITominToken(_tominAddress);
	}

	function stake(uint256[] memory xoloIds) external {
		require(isStarted, '$TOMIN staking paused');

		uint256[] memory _xoloIds = new uint256[](xoloIds.length);

		_xoloIds = xoloIds;

		for (uint256 i; i < _xoloIds.length; i++) {
			require(
				theyXolo.ownerOf(_xoloIds[i]) == msg.sender,
				'Not your They Xolo Token'
			);

			idToStartingTime[_xoloIds[i]][msg.sender] = block.timestamp;

			theyXolo.transferFrom(msg.sender, address(this), _xoloIds[i]);

			idToStaker[_xoloIds[i]] = msg.sender;
			xolosStaked[msg.sender].push(_xoloIds[i]);
		}
	}

	function unstake(uint256[] memory xoloIds) external {
		uint256[] memory _xoloIds = new uint256[](xoloIds.length);

		_xoloIds = xoloIds;

		for (uint256 i; i < _xoloIds.length; i++) {
			require(
				idToStaker[_xoloIds[i]] == msg.sender,
				'Not your They Xolo Token'
			);

			theyXolo.transferFrom(address(this), msg.sender, _xoloIds[i]);

			for (uint256 j; j < xolosStaked[msg.sender].length; j++) {
				if (xolosStaked[msg.sender][j] == _xoloIds[i]) {
					xolosStaked[msg.sender][j] = xolosStaked[msg.sender][
						xolosStaked[msg.sender].length - 1
					];
					xolosStaked[msg.sender].pop();
					break;
				}
			}

			uint256 current;
			uint256 reward;

			delete idToStaker[_xoloIds[i]];

			if (idToStartingTime[_xoloIds[i]][msg.sender] > 0) {
				uint256 rate = defaultTokenRate;
				current = block.timestamp - idToStartingTime[_xoloIds[i]][msg.sender];

				reward = ((rate * 10**18) * current) / 86400;

				tomin.mint(msg.sender, reward);
				idToStartingTime[_xoloIds[i]][msg.sender] = 0;
			}
		}
	}

	function setStakingState(bool _isStarted) public onlyOwner {
		isStarted = _isStarted;
	}

	function claim() public {
		require(xolosStaked[msg.sender].length > 0, 'No tokens staked');

		uint256[] memory xoloIds = new uint256[](xolosStaked[msg.sender].length);
		xoloIds = xolosStaked[msg.sender];

		uint256 current;
		uint256 reward;
		uint256 rewardBalance;

		for (uint256 i; i < xoloIds.length; i++) {
			if (idToStartingTime[xoloIds[i]][msg.sender] > 0) {
				uint256 rate = defaultTokenRate;
				current = block.timestamp - idToStartingTime[xoloIds[i]][msg.sender];
				reward = ((rate * 10**18) * current) / 86400;
				rewardBalance += reward;
				idToStartingTime[xoloIds[i]][msg.sender] = block.timestamp;
			}
		}

		tomin.mint(msg.sender, rewardBalance);
	}

	function balance(uint256 tokenId) public view returns (uint256) {
		uint256 current;
		uint256 reward;

		if (idToStartingTime[tokenId][msg.sender] > 0) {
			uint256 rate = defaultTokenRate;
			current = block.timestamp - idToStartingTime[tokenId][msg.sender];
			reward = ((rate * 10**18) * current) / 86400;

			return reward;
		}

		return 0;
	}

	function balanceOf(address account) public view returns (uint256) {
		uint256[] memory xoloIds = new uint256[](xolosStaked[account].length);

		xoloIds = xolosStaked[account];

		uint256 current;
		uint256 reward;
		uint256 rewardBalance;

		for (uint256 i; i < xoloIds.length; i++) {
			if (idToStartingTime[xoloIds[i]][account] > 0) {
				uint256 rate = defaultTokenRate;

				current = block.timestamp - idToStartingTime[xoloIds[i]][account];
				reward = ((rate * 10**18) * current) / 86400;
				rewardBalance += reward;
			}
		}

		return rewardBalance;
	}

	function deposits(address account) public view returns (uint256[] memory) {
		return xolosStaked[account];
	}

	function withdrawErc20(address _tokenAddress, address to) public onlyOwner {
		ierc20 = IERC20(_tokenAddress);
		ierc20.transfer(to, ierc20.balanceOf(address(this)));
	}

	function onERC721Received(
		address,
		address,
		uint256,
		bytes calldata
	) external pure override returns (bytes4) {
		return IERC721Receiver.onERC721Received.selector;
	}
}
