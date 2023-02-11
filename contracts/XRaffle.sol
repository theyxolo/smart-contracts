// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/AccessControl.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import '@chainlink/contracts/src/v0.8/VRFV2WrapperConsumerBase.sol';

import './Raffle.sol';
import './IterableMapping.sol';

contract XRaffle is
	ERC1155,
	AccessControl,
	ConfirmedOwner,
	ReentrancyGuard,
	VRFV2WrapperConsumerBase
{
	using Strings for uint256;

	// Just a struct holding our data.
	itmap _mapBalances;
	mapping(uint256 => address[]) _balances;

	// Apply library functions to the data type.
	using IterableMapping for itmap;

	struct RequestStatus {
		uint256 paid; // amount paid in link
		bool fulfilled; // whether the request has been successfully fulfilled
		uint256[] randomWords;
	}

	event RequestSent(uint256 requestId, uint32 numWords);

	// Depends on the number of requested values that you want sent to the
	// fulfillRandomWords() function. Test and adjust
	// this limit based on the network that you select, the size of the request,
	// and the processing of the callback request in the fulfillRandomWords()
	// function.
	uint32 callbackGasLimit = 100000;

	// The default is 3, but you can set this higher.
	uint16 requestConfirmations = 3;

	// For this example, retrieve 2 random values in one request.
	// Cannot exceed VRFV2Wrapper.getConfig().maxNumWords.
	uint32 numWords = 2;

	// past requests Id.
	uint256[] public requestIds;
	uint256 public lastRequestId;
	mapping(address => bool) private _winners;

	bytes32 public constant DEPLOYER_ROLE = keccak256('DEPLOYER_ROLE');

	mapping(uint256 => Raffle) public allRaffles;
	uint256[] public allRaffleIds;

	/*
        R a n d o m n e s s
    */

	event RequestFulfilled(
		uint256 requestId,
		uint256[] randomWords,
		uint256 payment
	);

	address linkAddress = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB; // Address LINK - hardcoded for Goerli
	address wrapperAddress = 0x708701a1DfF4f478de54383E49a627eD4852C816; // address WRAPPER - hardcoded for Goerli
	mapping(uint256 => RequestStatus)
		public s_requests; /* requestId --> requestStatus */

	constructor(
		string memory _baseUri
	)
		ERC1155(_baseUri)
		ConfirmedOwner(msg.sender)
		VRFV2WrapperConsumerBase(linkAddress, wrapperAddress)
	{
		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
	}

	/*

        M o d i f i e r s

    */

	modifier whenNotPickingWinner(uint256 _raffleId) {
		Raffle storage existingRaffle = allRaffles[_raffleId];

		(, bool fulfilled, ) = getRequestStatus(existingRaffle.randomRequestId);

		require(!fulfilled, 'Request not fulfilled');

		_;
	}

	modifier onlyDeployer() {
		require(
			hasRole(DEPLOYER_ROLE, _msgSender()),
			'Must have deployer role to call this function'
		);

		_;
	}

	modifier onlyAdmin() {
		require(
			hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
			'Must have admin role to call this function'
		);

		_;
	}

	/*

        F u n c t i o n s

	*/

	function getRaffles(
		uint256[] calldata _raffleIds
	) external view returns (Raffle[] memory) {
		Raffle[] memory _raffles = new Raffle[](_raffleIds.length);

		for (uint256 i = 0; i < _raffleIds.length; i++) {
			_raffles[i] = allRaffles[_raffleIds[i]];
		}

		return _raffles;
	}

	function getRaffle(uint256 _raffleId) external view returns (Raffle memory) {
		Raffle memory _raffle = allRaffles[_raffleId];

		return _raffle;
	}

	function assignDeployerRole(address _deployer) external onlyAdmin {
		_setupRole(DEPLOYER_ROLE, _deployer);
	}

	function setRaffle(
		uint256 _raffleId,
		uint256 _salePrice,
		RafflePhase _phase,
		uint256 _presalePrice,
		uint256 _maxSupply,
		uint256 _maxPerWallet,
		uint256 _maxPerTx,
		bytes32 _merkleRoot,
		uint256 _saleStartAt,
		uint256 _saleEndAt,
		uint256 _presaleStartAt
	) external onlyDeployer whenNotPickingWinner(_raffleId) {
		Raffle storage existingRaffle = allRaffles[_raffleId];

		// Allow changes only if raffle is not ended or canceled
		require(
			existingRaffle.phase != RafflePhase.Ended &&
				existingRaffle.phase != RafflePhase.Canceled,
			'Raffle is ended or canceled'
		);

		if (!existingRaffle.isExisting) {
			allRaffleIds.push(_raffleId);

			allRaffles[_raffleId] = Raffle({
				id: _raffleId,
				salePrice: _salePrice,
				presalePrice: _presalePrice,
				maxSupply: _maxSupply,
				phase: RafflePhase.Draft,
				maxPerWallet: _maxPerWallet,
				maxPerTx: _maxPerTx,
				merkleRoot: _merkleRoot,
				saleStartAt: _saleStartAt,
				saleEndAt: _saleEndAt,
				presaleStartAt: _presaleStartAt,
				isExisting: true,
				randomRequestId: 0x0,
				winner: address(0),
				isPriceClaimed: false
			});
		} else {
			existingRaffle.salePrice = _salePrice;
			existingRaffle.presalePrice = _presalePrice;
			existingRaffle.maxSupply = _maxSupply;
			existingRaffle.phase = _phase;
			existingRaffle.maxPerWallet = _maxPerWallet;
			existingRaffle.maxPerTx = _maxPerTx;
			existingRaffle.merkleRoot = _merkleRoot;
			existingRaffle.saleStartAt = _saleStartAt;
			existingRaffle.saleEndAt = _saleEndAt;
			existingRaffle.presaleStartAt = _presaleStartAt;
		}
	}

	function mint(
		address _toAddress,
		uint256 _raffleId,
		uint256 _amount,
		bytes memory _data
	) external payable nonReentrant whenNotPickingWinner(_raffleId) {
		Raffle storage existingRaffle = allRaffles[_raffleId];

		require(
			existingRaffle.phase == RafflePhase.Presale ||
				existingRaffle.phase == RafflePhase.Sale,
			'Raffle is not in presale or sale phase'
		);

		require(
			_amount <= existingRaffle.maxPerWallet,
			'Amount exceeds max per wallet'
		);

		if (existingRaffle.phase == RafflePhase.Presale) {
			require(
				msg.value == existingRaffle.presalePrice * _amount,
				'Incorrect amount of ETH sent'
			);
		} else if (existingRaffle.phase == RafflePhase.Sale) {
			require(
				msg.value == existingRaffle.salePrice * _amount,
				'Incorrect amount of ETH sent'
			);
		}

		require(
			balanceOf(_toAddress, _raffleId) < existingRaffle.maxPerWallet,
			'You have already minted the max amount of tokens for this raffle'
		);

		_mint(_toAddress, _raffleId, _amount, _data);
	}

	function claim(uint256 raffleId) external nonReentrant {
		// Allow to claim price
		Raffle storage raffle = allRaffles[raffleId];

		require(raffle.phase == RafflePhase.Ended, 'Raffle is not in ended phase');

		require(raffle.winner == _msgSender(), 'Only winner can claim the price');

		require(!raffle.isPriceClaimed, 'Winner has already claimed the price');

		raffle.isPriceClaimed = true;

		// TODO: send price to winner
	}

	// Overrides

	function supportsInterface(
		bytes4 interfaceId
	) public view virtual override(AccessControl, ERC1155) returns (bool) {
		return
			interfaceId == type(IERC1155).interfaceId ||
			interfaceId == type(IAccessControl).interfaceId ||
			interfaceId == type(IERC1155MetadataURI).interfaceId ||
			super.supportsInterface(interfaceId);
	}

	function requestWinner(
		uint256 raffleId
	) external onlyDeployer nonReentrant whenNotPickingWinner(raffleId) {
		Raffle storage existingRaffle = allRaffles[raffleId];

		existingRaffle.phase = RafflePhase.Ended;

		if (existingRaffle.randomRequestId == 0x0) {
			// TODO: prevent minting,transfering, burning until winner is chosen
			existingRaffle.randomRequestId = requestRandomWords();
			return;
		}

		(, , uint256[] memory randomWords) = getRequestStatus(
			existingRaffle.randomRequestId
		);

		// address[] memory raffleBalances = raffleToBalances[raffleId];
		// // Get winner index using maxSupply and randomWords
		// uint256 winnerIndex = randomWords[0] % raffleBalances.length;

		// address winnerAddress = raffleBalances[winnerIndex];

		// existingRaffle.winner = winnerAddress;

		// Transfer amount to winner address
	}

	function requestRandomWords() private returns (uint256 requestId) {
		requestId = requestRandomness(
			callbackGasLimit,
			requestConfirmations,
			numWords
		);
		s_requests[requestId] = RequestStatus({
			paid: VRF_V2_WRAPPER.calculateRequestPrice(callbackGasLimit),
			randomWords: new uint256[](0),
			fulfilled: false
		});
		requestIds.push(requestId);
		lastRequestId = requestId;

		emit RequestSent(requestId, numWords);

		return requestId;
	}

	function fulfillRandomWords(
		uint256 _requestId,
		uint256[] memory _randomWords
	) internal override {
		require(s_requests[_requestId].paid > 0, 'request not found');

		s_requests[_requestId].fulfilled = true;
		s_requests[_requestId].randomWords = _randomWords;

		emit RequestFulfilled(
			_requestId,
			_randomWords,
			s_requests[_requestId].paid
		);
	}

	/*
        R a n d o m n e s s
    */

	function getRequestStatus(
		uint256 _requestId
	)
		public
		view
		returns (uint256 paid, bool fulfilled, uint256[] memory randomWords)
	{
		require(s_requests[_requestId].paid > 0, 'request not found');
		RequestStatus memory request = s_requests[_requestId];
		return (request.paid, request.fulfilled, request.randomWords);
	}

	function withdrawLink() public onlyOwner {
		LinkTokenInterface link = LinkTokenInterface(linkAddress);
		require(
			link.transfer(msg.sender, link.balanceOf(address(this))),
			'Unable to transfer'
		);
	}

	/*
			H O O K S
	*/

	function removeParticipant(
		uint256 raffleId,
		uint256 participantIndex
	) internal {
		if (participantIndex >= _balances[raffleId].length) return;

		for (uint i = participantIndex; i < _balances[raffleId].length - 1; i++) {
			_balances[raffleId][i] = _balances[raffleId][i + 1];
		}

		_balances[raffleId].pop();
	}

	function _afterTokenTransfer(
		address operator,
		address fromAddress,
		address toAddress,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual override {
		super._afterTokenTransfer(
			operator,
			fromAddress,
			toAddress,
			ids,
			amounts,
			data
		);

		for (uint256 i = 0; i < ids.length; i++) {
			uint256 id = ids[i];

			_balances[id].push(toAddress);

			for (uint j = 0; j < _balances[id].length; j++) {
				if (
					_balances[id][j] == fromAddress && balanceOf(fromAddress, id) == 0
				) {
					removeParticipant(id, j);
				}
			}
		}
	}

	function _beforeTokenTransfer(
		address operator,
		address from,
		address to,
		uint256[] memory ids,
		uint256[] memory amounts,
		bytes memory data
	) internal virtual override {
		super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

		// Verify that the raffle is not in the process of picking a winner
		for (uint256 i = 0; i < ids.length; i++) {
			Raffle memory raffle = allRaffles[ids[i]];

			if (raffle.randomRequestId != 0x0) {
				(, bool fulfilled, ) = getRequestStatus(raffle.randomRequestId);

				require(fulfilled, 'Winner picking in progress, cannot operate');
			}
		}
	}
}
