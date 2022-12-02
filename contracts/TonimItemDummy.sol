// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

contract TonimItemDummy is ERC1155 {
	uint256 public constant GOLD = 0;
	uint256 public constant SILVER = 1;

	constructor() ERC1155('https://game.example/api/item/{id}.json') {
		_mint(_msgSender(), GOLD, 10 ** 18, '');
		_mint(_msgSender(), SILVER, 10 ** 18, '');
	}
}
