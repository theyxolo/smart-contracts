// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @title Tomin
/// @author cesargdm.eth

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Tomin is ERC20, ERC20Permit, ERC20Votes, Ownable {
	uint256 constant initialSupply = 20_000_000 * (10**18);
	uint256 public maxSupply = 200_000_000 * (10**18);

	mapping(address => bool) onlyApprovedContractAddress;

	constructor() ERC20('Tomin', 'TMIN') ERC20Permit('Tomin') {
		_mint(msg.sender, initialSupply);
	}

	function setApprovedContractAddress(address add) external onlyOwner {
		onlyApprovedContractAddress[add] = true;
	}

	function removeApprovedContractAddress(address add) external onlyOwner {
		onlyApprovedContractAddress[add] = false;
	}

	function mint(address add, uint256 amount) external {
		require(
			onlyApprovedContractAddress[msg.sender] == true,
			'Tomin: not approved to mint'
		);

		require(totalSupply() + amount <= maxSupply, '$TOMIN limit reached');

		_mint(add, amount);
	}

	// Overrides based on https://docs.openzeppelin.com/contracts/4.x/governance

	function _afterTokenTransfer(
		address from,
		address to,
		uint256 amount
	) internal override(ERC20, ERC20Votes) {
		super._afterTokenTransfer(from, to, amount);
	}

	function _mint(address to, uint256 amount)
		internal
		override(ERC20, ERC20Votes)
	{
		super._mint(to, amount);
	}

	function _burn(address account, uint256 amount)
		internal
		override(ERC20, ERC20Votes)
	{
		super._burn(account, amount);
	}
}
