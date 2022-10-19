/* eslint-disable no-unused-expressions */
import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { expect } from 'chai'
import { ethers } from 'hardhat'
import { MerkleTree } from 'merkletreejs'

enum MintPhase {
	Idle,
	Private,
	Public,
}

const MAX_TOKEN_SUPPLY = 100
const BASE_TOKEN_URI = 'https://test.com/tokens/meta/'
const BASE_CONTRACT_URI = 'https://test.com/contract.json'
const PUBLIC_SALE_COST_PER_TOKEN = ethers.utils.parseEther('0.02')
const PRESALE_COST_PER_TOKEN = ethers.utils.parseEther('0.01')
const MAX_PER_WALLET_PRESALE = 2
const MAX_PER_TX = 10
const ROYALTY_BASE_POINTS = 800 // 8%
const MAX_TOKEN_SUPPLY_PLUS_ONE = MAX_TOKEN_SUPPLY + 1
const TOKEN_NAME = 'Test'
const TOKEN_SYMBOL = 'TST'

const IERC721_INTERFACE_ID = 0x80ac58cd
const IERC721_METADATA_INTERFACE_ID = 0x5b5e139f
const IERC2981_INTERFACE_ID = 0x2a55205a

function getMerkle(leafs: string[], leaf?: string) {
	let proof

	const hashedLeafs = leafs.map((address) => ethers.utils.keccak256(address))
	const tree = new MerkleTree(hashedLeafs, ethers.utils.keccak256, {
		sortPairs: true,
	})

	if (leaf) {
		const hashedLeaf = ethers.utils.keccak256(leaf)
		proof = tree.getHexProof(hashedLeaf)
	}

	const root = tree.getRoot()

	return { root, proof }
}

describe('ERC721X', function () {
	// We define a fixture to reuse the same setup in every test.
	// We use loadFixture to run this setup once, snapshot that state,
	// and reset Hardhat Network to that snapshot in every test.
	async function deployERC721XFixture() {
		// eslint-disable-next-line no-magic-numbers
		const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60
		const ONE_GWEI = 1_000_000_000

		const lockedAmount = ONE_GWEI
		const unlockTime = (await time.latest()) + ONE_YEAR_IN_SECS

		// Contracts are deployed using the first signer/account by default

		const [owner, ...accounts] = await (ethers as any).getSigners()

		// await network.provider.send('hardhat_setBalance', [
		// 	unfoundedAccount.address,
		// 	ethers.utils.parseEther('0.01'),
		// ])

		const ERC721X = await ethers.getContractFactory('ERC721X')
		const erc721x = await ERC721X.deploy(
			TOKEN_NAME,
			TOKEN_SYMBOL,
			MAX_TOKEN_SUPPLY,
			PUBLIC_SALE_COST_PER_TOKEN,
			PRESALE_COST_PER_TOKEN,
			MAX_PER_TX,
			MAX_PER_WALLET_PRESALE,
			ROYALTY_BASE_POINTS,
			BASE_TOKEN_URI,
			BASE_CONTRACT_URI,
		)

		return {
			erc721x,
			unlockTime,
			lockedAmount,
			owner,
			accounts,
		}
	}

	describe('Deployment', () => {
		it('Should have correct default values', async () => {
			const { erc721x, owner } = await loadFixture(deployERC721XFixture)

			// Token name
			expect(await erc721x.name()).to.equal(TOKEN_NAME)

			// Token symbol
			expect(await erc721x.symbol()).to.equal(TOKEN_SYMBOL)

			// Token costPerPublicMint
			expect(await erc721x.costPerPublicMint()).to.equal(
				PUBLIC_SALE_COST_PER_TOKEN,
			)

			// Token costPerPublicMint
			expect(await erc721x.costPerPrivateMint()).to.equal(
				PRESALE_COST_PER_TOKEN,
			)

			// Base Token URI
			expect(await erc721x.tokenURIPrefix()).to.equal(BASE_TOKEN_URI)

			// Contract URI
			expect(await erc721x.contractURI()).to.equal(BASE_CONTRACT_URI)

			// Max supply
			// NOTE: we use plus one because we change the maxToken value to
			// save in the arithmetic operation when checking if we have reached max
			expect(await erc721x.maxTokenSupply()).to.equal(MAX_TOKEN_SUPPLY_PLUS_ONE)

			// debug log
			// JSON log to workaround comparison with Arrays
			expect(
				JSON.stringify(
					await erc721x.royaltyInfo(1, PUBLIC_SALE_COST_PER_TOKEN),
				),
			).to.be.eq(
				JSON.stringify([owner.address, ethers.utils.parseEther('0.0016')]),
			)
		})

		it('Should set the right owner', async () => {
			const { erc721x, owner } = await loadFixture(deployERC721XFixture)

			expect(await erc721x.owner()).to.equal(owner.address)
		})

		it('Should support support IERC721, IERC721Metadata and IERC2981', async () => {
			const { erc721x } = await loadFixture(deployERC721XFixture)

			expect(await erc721x.supportsInterface(IERC721_INTERFACE_ID)).to.be.true
			expect(await erc721x.supportsInterface(IERC2981_INTERFACE_ID)).to.be.true
			expect(await erc721x.supportsInterface(IERC721_METADATA_INTERFACE_ID)).to
				.be.true
		})
	})

	describe('Mint Phase', () => {
		it('Should be in NONE phase', async () => {
			const { erc721x } = await loadFixture(deployERC721XFixture)

			expect(await erc721x.mintPhase()).to.be.equal(MintPhase.Idle)
		})

		it('Should not be able to mint in NONE/PAUSED phase', async () => {
			const { erc721x } = await loadFixture(deployERC721XFixture)

			await expect(
				erc721x.publicMint(PUBLIC_SALE_COST_PER_TOKEN),
			).to.be.revertedWith('ERC721X: mintPhase invalid')

			// Private mint
			await expect(
				erc721x.privateMint(PUBLIC_SALE_COST_PER_TOKEN, []),
			).to.be.revertedWith('ERC721X: mintPhase invalid')

			await erc721x.setMintPhase(MintPhase.Idle)

			expect(await erc721x.mintPhase()).to.be.equal(MintPhase.Idle)

			await expect(
				erc721x.publicMint(PUBLIC_SALE_COST_PER_TOKEN),
			).to.be.revertedWith('ERC721X: mintPhase invalid')

			// Private mint
			await expect(
				erc721x.privateMint(PUBLIC_SALE_COST_PER_TOKEN, []),
			).to.be.revertedWith('ERC721X: mintPhase invalid')
		})

		it('Should be able to update mint phase', async () => {
			const { erc721x } = await loadFixture(deployERC721XFixture)

			await erc721x.setMintPhase(MintPhase.Idle)
			expect(await erc721x.mintPhase()).to.be.equal(MintPhase.Idle)

			await erc721x.setMintPhase(MintPhase.Private)
			expect(await erc721x.mintPhase()).to.be.equal(MintPhase.Private)

			await erc721x.setMintPhase(MintPhase.Public)
			expect(await erc721x.mintPhase()).to.be.equal(MintPhase.Public)
		})
	})

	describe('Mint', () => {
		it('Should presale mint', async () => {
			const { erc721x, accounts } = await loadFixture(deployERC721XFixture)
			await erc721x.setMintPhase(MintPhase.Private)

			const allowedAddresses = [accounts[0].address, accounts[1].address]

			const { root } = getMerkle(allowedAddresses)

			await erc721x.setMerkleRoot(root)

			const { proof: correctProof } = getMerkle(
				allowedAddresses,
				accounts[0].address,
			)

			await erc721x.connect(accounts[0]).privateMint(1, correctProof as any)

			const { proof: invalidProof } = getMerkle(
				allowedAddresses,
				accounts[2].address,
			)

			expect(
				erc721x.connect(accounts[2]).privateMint(1, invalidProof as any),
			).to.be.revertedWith('ERC721X: proof invalid')
			expect(
				erc721x.connect(accounts[2]).privateMint(1, correctProof as any),
			).to.be.revertedWith('ERC721X: proof invalid')
			expect(
				erc721x.connect(accounts[1]).privateMint(1, correctProof as any),
			).to.be.revertedWith('ERC721X: proof invalid')
		})

		it('Should not allow allowList minting more than maxPerWalletPresale', async () => {
			const { erc721x, accounts } = await loadFixture(deployERC721XFixture)
			await erc721x.setMintPhase(MintPhase.Private)

			const allowedAddresses = [accounts[0].address, accounts[1].address]

			const { root } = getMerkle(allowedAddresses)

			await erc721x.setMerkleRoot(root)

			const { proof: correctProof } = getMerkle(
				allowedAddresses,
				accounts[0].address,
			)

			await erc721x.connect(accounts[0]).privateMint(1, correctProof as any)
			expect(
				await erc721x.connect(accounts[0]).privateMint(1, correctProof as any),
			).to.be.revertedWith('ERC721X: maxPerWalletPresale exceeded')
		})

		it('Should not enable minting incorrect value', async () => {
			const { erc721x, accounts } = await loadFixture(deployERC721XFixture)

			await erc721x.setMintPhase(MintPhase.Public)

			await expect(
				erc721x
					.connect(accounts[0])
					.publicMint(1, { value: ethers.utils.parseEther('0.1') }),
			).to.be.revertedWith('ERC721X: value invalid')
		})

		it('Should enable public minting', async () => {
			const { erc721x, accounts } = await loadFixture(deployERC721XFixture)
			await erc721x.setMintPhase(MintPhase.Public)

			expect(await erc721x.balanceOf(accounts[0].address)).to.be.equal(0)

			await erc721x
				.connect(accounts[0])
				.publicMint(1, { value: PUBLIC_SALE_COST_PER_TOKEN })

			expect(await erc721x.balanceOf(accounts[0].address)).to.be.equal(1)
			expect(await erc721x.totalSupply()).to.be.equal(1)

			// Expect to be correct token URI
			expect(await erc721x.tokenURI(1)).to.be.equal(BASE_TOKEN_URI + '1.json')

			// eslint-disable-next-line no-magic-numbers
			expect(erc721x.tokenURI(2)).to.be.revertedWith(
				'ERC721Metadata: URI query for nonexistent token',
			)
		})

		it('Should not exceed maxPerTx', async () => {
			const { erc721x, accounts } = await loadFixture(deployERC721XFixture)
			await erc721x.setMintPhase(MintPhase.Public)

			expect(await erc721x.balanceOf(accounts[0].address)).to.be.equal(0)

			const maxTxAmount = MAX_PER_TX
			const exceedingTxAmount = MAX_PER_TX + 1

			// Exceeding tx amount
			await expect(
				erc721x.connect(accounts[0]).publicMint(exceedingTxAmount, {
					value: PUBLIC_SALE_COST_PER_TOKEN.mul(exceedingTxAmount),
				}),
			).to.be.revertedWith('ERC721X: maxPerTx exceeded')

			// Correct tx amount
			expect(
				await erc721x.connect(accounts[0]).publicMint(maxTxAmount, {
					value: PUBLIC_SALE_COST_PER_TOKEN.mul(maxTxAmount),
				}),
			)
		})

		it('Should not exceed maxTokenSupply', async () => {
			const { erc721x, accounts } = await loadFixture(deployERC721XFixture)

			await erc721x.setMintPhase(MintPhase.Public)

			for (let i = 0; i < MAX_TOKEN_SUPPLY; i++) {
				await erc721x
					.connect(accounts[0])
					.publicMint(1, { value: PUBLIC_SALE_COST_PER_TOKEN })
			}

			await expect(
				erc721x.connect(accounts[0]).publicMint(1, {
					value: PUBLIC_SALE_COST_PER_TOKEN,
				}),
			).to.be.revertedWith('ERC721X: maxTokenSupply exceeded')
		})
	})

	describe('BaseTokenURI', () => {
		it('Should be able to set new Base Token URI', async () => {
			const { erc721x, owner } = await loadFixture(deployERC721XFixture)

			const NEW_TOKEN_URI = 'ipfs://0x0'

			await erc721x.setBaseTokenURI(NEW_TOKEN_URI)

			expect(await erc721x.connect(owner).tokenURIPrefix()).to.be.equal(
				NEW_TOKEN_URI,
			)
		})
	})

	describe('Security', () => {
		it('Should restrict to owner functions', async () => {
			const { erc721x, accounts } = await loadFixture(deployERC721XFixture)

			expect(
				erc721x.connect(accounts[0]).setBaseTokenURI(''),
			).to.be.revertedWith('Ownable: caller is not the owner')

			expect(
				erc721x.connect(accounts[0]).setMintPhase(MintPhase.Public),
			).to.be.revertedWith('Ownable: caller is not the owner')

			expect(erc721x.connect(accounts[0]).setMerkleRoot([])).to.be.revertedWith(
				'Ownable: caller is not the owner',
			)

			expect(
				erc721x.connect(accounts[0]).setContractURI(''),
			).to.be.revertedWith('Ownable: caller is not the owner')

			expect(
				erc721x.connect(accounts[0]).setDefaultRoyalty(accounts.address, 0),
			).to.be.revertedWith('Ownable: caller is not the owner')

			expect(erc721x.connect(accounts[0]).withdraw()).to.be.revertedWith(
				'Ownable: caller is not the owner',
			)

			expect(
				erc721x.connect(accounts[0]).setTokenRoyalty(0, accounts.address, 0),
			).to.be.revertedWith('Ownable: caller is not the owner')

			expect(
				erc721x.connect(accounts[0]).resetTokenRoyalty(0),
			).to.be.revertedWith('Ownable: caller is not the owner')
		})

		it('Should set merkle root', async () => {
			const { erc721x, accounts } = await loadFixture(deployERC721XFixture)
			await erc721x.setMintPhase(MintPhase.Private)

			const { root } = getMerkle([accounts[0].address, accounts[1].address])

			await erc721x.setMerkleRoot(root)

			expect(await erc721x.merkleRoot()).to.be.equal(
				`0x${root.toString('hex')}`,
			)
		})
	})

	describe('Withdraw', () => {
		it('Should revert with the right error if called from another account', async () => {
			const { erc721x, accounts } = await loadFixture(deployERC721XFixture)

			const erc721FromFounded = erc721x.connect(accounts[0])
			// We use erc721x.connect() to send a transaction from another account
			await expect(erc721FromFounded.withdraw()).to.be.revertedWith(
				'Ownable: caller is not the owner',
			)

			await expect(erc721FromFounded.resetTokenRoyalty(1)).to.be.revertedWith(
				'Ownable: caller is not the owner',
			)
			await expect(
				// eslint-disable-next-line no-magic-numbers
				erc721FromFounded.setTokenRoyalty(1, accounts[0].getAddress(), 10),
			).to.be.revertedWith('Ownable: caller is not the owner')
		})

		it('Should withdraw to the owner address', async () => {
			const { erc721x, owner, accounts } = await loadFixture(
				deployERC721XFixture,
			)

			const setMintPhaseTx = await erc721x.setMintPhase(MintPhase.Public)
			await setMintPhaseTx.wait()

			const balanceBefore = await (ethers as any).provider.getBalance(
				owner.address,
			)

			const mintTx = await erc721x.connect(accounts[0]).publicMint(MAX_PER_TX, {
				value: PUBLIC_SALE_COST_PER_TOKEN.mul(MAX_PER_TX),
			})

			await mintTx.wait()

			const trans = await erc721x.withdraw()
			const receipt = await trans.wait()
			const gasCostForTxn = receipt.gasUsed.mul(receipt.effectiveGasPrice)

			const balanceAfter = await (ethers as any).provider.getBalance(
				owner.address,
			)

			expect(balanceAfter).to.be.equal(
				balanceBefore
					.add(PUBLIC_SALE_COST_PER_TOKEN.mul(MAX_PER_TX))
					.sub(gasCostForTxn),
			)
		})
	})
})
