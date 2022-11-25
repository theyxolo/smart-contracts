// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Tonim
/// @author cesargdm.eth

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract Tonim2 is
	ERC20Upgradeable,
	OwnableUpgradeable,
	AccessControlUpgradeable
{
	uint256 constant initialSupply = 250_000 * (10 ** 18);
	uint256 public constant maxSupply = 50_000_000 * (10 ** 18);

	mapping(address => bool) approvedToMint;

	bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
	bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

	function initialize() public initializer {
		__ERC20_init('TONIM', 'TNM');
		__Ownable_init();
		__AccessControl_init();

		_mint(_msgSender(), initialSupply);
	}

	function mint(
		address _address,
		uint256 _amount
	) external onlyRole(MINTER_ROLE) {
		require(totalSupply() + _amount <= maxSupply, 'TNM: maxSupply reached');

		_mint(_address, _amount);
	}
}
