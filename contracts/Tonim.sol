// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Tonim
/// @author cesargdm.eth

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

contract Tonim is ERC20Upgradeable, OwnableUpgradeable {
	uint256 constant initialSupply = 250_000 * (10**18);
	uint256 public constant maxSupply = 50_000_000 * (10**18);

	mapping(address => bool) approvedToMint;

	function initialize() public initializer {
		__ERC20_init('TONIM', 'TNM');
		__Ownable_init();

		_mint(_msgSender(), initialSupply);
	}

	function setApprovedToMint(address _address) external onlyOwner {
		approvedToMint[_address] = true;
	}

	function removeApprovedToMint(address _address) external onlyOwner {
		// delete approvedToMint[_address];
		approvedToMint[_address] = false;
	}

	function mint(address _address, uint256 _amount) external {
		require(approvedToMint[msg.sender] == true, 'TNM: not approved to mint');

		require(totalSupply() + _amount <= maxSupply, 'TNM: maxSupply reached');

		_mint(_address, _amount);
	}
}
