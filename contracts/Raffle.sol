// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

enum RafflePhase {
	Draft,
	Presale,
	Sale,
	Ended,
	Canceled
}

struct Raffle {
	uint256 id;
	RafflePhase phase;
	uint256 salePrice;
	uint256 presalePrice;
	// Max
	uint256 maxSupply;
	uint256 maxPerWallet;
	uint256 maxPerTx;
	bytes32 merkleRoot;
	// Times
	uint256 saleStartAt;
	uint256 saleEndAt;
	uint256 presaleStartAt;
	// Utils
	bool isExisting;
	uint256 randomRequestId;
	address winner;
	bool isPriceClaimed;
}
