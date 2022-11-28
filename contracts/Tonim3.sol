// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Tonim3
/// @author cesargdm.eth

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20VotesUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol';

import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract Tonim3 is
	ERC20Upgradeable,
	AccessControlUpgradeable,
	ERC20VotesUpgradeable
{
	uint256 constant initialSupply = 250_000 * (10 ** 18);
	uint256 public constant maxSupply = 100_000_000 * (10 ** 18);

	bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
	bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

	function initialize() public initializer {
		__ERC20_init('Tonim', 'TNM');
		__AccessControl_init();
		__ERC20Votes_init();
		__ERC20Permit_init('Tonim');

		_grantRole(DEFAULT_ADMIN_ROLE, _msgSender());

		_mint(_msgSender(), initialSupply);
	}

	function mint(
		address _address,
		uint256 _amount
	) external onlyRole(MINTER_ROLE) {
		require(totalSupply() + _amount <= maxSupply, 'TNM: maxSupply reached');

		_mint(_address, _amount);
	}

	function _mint(
		address to,
		uint256 amount
	) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
		super._mint(to, amount);
	}

	function _burn(
		address _address,
		uint256 _amount
	) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
		super._burn(_address, _amount);
	}

	function _afterTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override(ERC20Upgradeable, ERC20VotesUpgradeable) {
		super._afterTokenTransfer(from, to, amount);
	}
}
