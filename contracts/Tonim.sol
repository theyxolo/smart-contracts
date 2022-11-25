// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Tonim
/// @author cesargdm.eth

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract Tonim is ERC20Upgradeable, AccessControlUpgradeable {
	uint256 constant initialSupply = 250_000 * (10 ** 18);
	uint256 public constant maxSupply = 100_000_000 * (10 ** 18);

	bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');

	function initialize() public initializer {
		__ERC20_init('TONIM', 'TNM');
		__AccessControl_init();

		_grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
	}

	function mint(
		address _address,
		uint256 _amount
	) external onlyRole(MINTER_ROLE) {
		require(totalSupply() + _amount <= maxSupply, 'TNM: maxSupply reached');

		_mint(_address, _amount);
	}
}
