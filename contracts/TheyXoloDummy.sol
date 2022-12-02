// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title TheyXolo
/// @author cesargdm.eth

import './ERC721X.sol';

contract TheyXoloDummy is ERC721X {
	constructor()
		ERC721X(
			'They Xolo Dummy',
			'TXOD',
			10000,
			0 ether,
			0 ether,
			10,
			10,
			800,
			'https://dummy.xyz/api/tokens/',
			'https://dummy.xyz/api/contract.json'
		)
	{
		//
		_safeMint(msg.sender, 10);
	}
}
