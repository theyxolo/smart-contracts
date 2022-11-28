// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Tonim2
/// @author cesargdm.eth

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol';

contract Tonim2 is ERC20Upgradeable, AccessControlUpgradeable {
	uint256 constant initialSupply = 250_000 * (10 ** 18);
	uint256 public constant maxSupply = 100_000_000 * (10 ** 18);

	bytes32 public constant MINTER_ROLE = keccak256('MINTER_ROLE');
	bytes32 public constant BURNER_ROLE = keccak256('BURNER_ROLE');

	function initialize() public initializer {
		__ERC20_init('Tonim', 'TNM');
		__AccessControl_init();

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
}
