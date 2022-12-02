/* eslint-disable no-magic-numbers */
/* eslint-disable no-unused-expressions */
import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { expect } from 'chai'
import { BigNumber } from 'ethers'
import { ethers } from 'hardhat'

enum TonimItemDummy {
	GOLD,
	SILVER,
}

enum Participation {
	None,
	Sent,
	Received,
}

// We define a fixture to reuse the same setup in every test.
// We use loadFixture to run this setup once, snapshot that state,
// and reset Hardhat Network to that snapshot in every test.
async function deploySecretSantaFixture() {
	// eslint-disable-next-line no-magic-numbers
	const ONE_MIN_IN_SECS = 60 * 60

	const RECEIVE_TIMESTAMP = (await time.latest()) + ONE_MIN_IN_SECS

	const [owner, ...accounts] = await ethers.getSigners()

	const ERC721 = await ethers.getContractFactory('TheyXoloDummy')
	const erc721 = await ERC721.deploy()

	const ERC1155 = await ethers.getContractFactory('TonimItemDummy')
	const erc1155 = await ERC1155.deploy()

	const SecretSanta = await ethers.getContractFactory('SecretSanta')
	const secretSanta = await SecretSanta.deploy(RECEIVE_TIMESTAMP, [
		erc721.address,
	])

	return { owner, accounts, secretSanta, erc721, erc1155, RECEIVE_TIMESTAMP }
}

describe('SecretSanta', function () {
	describe('Receive timeframe', () => {
		it('Should set the right owner', async () => {
			const { secretSanta, owner } = await loadFixture(deploySecretSantaFixture)

			expect(await secretSanta.owner()).to.equal(owner.address)
		})

		it('Should display as not participant for non-participant', async () => {
			const { secretSanta, accounts } = await loadFixture(
				deploySecretSantaFixture,
			)

			expect(await secretSanta.participations(accounts[0].address)).to.eq(0)
		})

		it('Should block receiveGift', async () => {
			const { secretSanta } = await loadFixture(deploySecretSantaFixture)

			await expect(secretSanta.receiveGift()).to.be.revertedWith(
				'SecretSanta: receive not yet available',
			)
		})

		it('Should show all gifts', async () => {
			const { secretSanta } = await loadFixture(deploySecretSantaFixture)

			expect(await secretSanta.gifts()).to.have.lengthOf(0)
		})
	})

	describe('Transfer', () => {
		it('Should receive erc721 tokens', async () => {
			const { secretSanta, owner, accounts, erc721, erc1155 } =
				await loadFixture(deploySecretSantaFixture)

			await expect(
				erc1155.safeTransferFrom(
					owner.address,
					secretSanta.address,
					TonimItemDummy.GOLD,
					1,
					[],
				),
			).to.be.revertedWith('SecretSanta: this collection is not approved')

			await erc721['safeTransferFrom(address,address,uint256)'](
				owner.address,
				secretSanta.address,
				1,
			)

			expect(await secretSanta.participations(owner.address)).to.be.eq(
				Participation.Sent,
			)

			expect(await secretSanta.participations(accounts[0].address)).to.be.eq(
				Participation.None,
			)
		})

		it('Should receive erc1155 tokens', async () => {
			const { secretSanta, owner, erc1155 } = await loadFixture(
				deploySecretSantaFixture,
			)

			await expect(
				erc1155.safeTransferFrom(
					owner.address,
					secretSanta.address,
					TonimItemDummy.GOLD,
					1,
					[],
				),
			).to.be.revertedWith('SecretSanta: this collection is not approved')

			await secretSanta.approveCollection(erc1155.address)

			// Transfer from owner to account 0
			await erc1155.safeTransferFrom(
				owner.address,
				secretSanta.address,
				TonimItemDummy.GOLD,
				1,
				[],
			)

			expect(await secretSanta.participations(owner.address)).to.be.eq(
				Participation.Sent,
			)
		})

		it('Should not allow more than one transfer', async () => {
			const { secretSanta, owner, accounts, erc721, erc1155 } =
				await loadFixture(deploySecretSantaFixture)

			await erc721['safeTransferFrom(address,address,uint256)'](
				owner.address,
				secretSanta.address,
				1,
			)

			await expect(
				erc721['safeTransferFrom(address,address,uint256)'](
					owner.address,
					secretSanta.address,
					2,
				),
			).to.be.revertedWith('SecretSanta: you already sent a gift')

			await secretSanta.approveCollection(erc1155.address)

			await expect(
				erc1155.safeTransferFrom(
					owner.address,
					secretSanta.address,
					TonimItemDummy.GOLD,
					1,
					[],
				),
			).to.be.revertedWith('SecretSanta: you already sent a gift')

			await erc1155.safeTransferFrom(
				owner.address,
				accounts[0].address,
				TonimItemDummy.GOLD,
				1,
				[],
			)

			await erc1155
				.connect(accounts[0])
				.safeTransferFrom(
					accounts[0].address,
					secretSanta.address,
					TonimItemDummy.GOLD,
					0,
					[],
				)

			await expect(
				erc1155
					.connect(accounts[0])
					.safeTransferFrom(accounts[0].address, secretSanta.address, 0, 1, []),
			).to.be.revertedWith('SecretSanta: you already sent a gift')
		})

		it('Should enable receiving tokens', async () => {
			const {
				secretSanta,
				owner,
				accounts,
				erc721,
				erc1155,
				RECEIVE_TIMESTAMP,
			} = await loadFixture(deploySecretSantaFixture)

			await secretSanta.approveCollection(erc1155.address)

			await erc721['safeTransferFrom(address,address,uint256)'](
				owner.address,
				secretSanta.address,
				1,
			)

			await erc721['safeTransferFrom(address,address,uint256)'](
				owner.address,
				accounts[0].address,
				2,
			)

			await erc1155.safeTransferFrom(
				owner.address,
				accounts[1].address,
				TonimItemDummy.GOLD,
				10,
				[],
			)

			await erc721['safeTransferFrom(address,address,uint256)'](
				owner.address,
				accounts[2].address,
				3,
			)

			await erc721
				.connect(accounts[0])
				['safeTransferFrom(address,address,uint256)'](
					accounts[0].address,
					secretSanta.address,
					2,
				)

			await erc1155
				.connect(accounts[1])
				.safeTransferFrom(
					accounts[1].address,
					secretSanta.address,
					TonimItemDummy.GOLD,
					5,
					[],
				)

			expect(await erc721.balanceOf(accounts[1].address)).to.be.eq(0)

			expect(await secretSanta.gifts()).to.have.lengthOf(3)

			await time.increaseTo(RECEIVE_TIMESTAMP)

			await expect(
				erc721
					.connect(accounts[2])
					[`safeTransferFrom(address,address,uint256)`](
						accounts[2].address,
						secretSanta.address,
						3,
					),
			).to.be.revertedWith('SecretSanta: you can no longer send a gift')

			expect(
				await erc1155.balanceOf(owner.address, TonimItemDummy.GOLD),
			).to.be.eq(BigNumber.from('999999999999999990'))

			await secretSanta.receiveGift()

			expect(
				await erc1155.balanceOf(owner.address, TonimItemDummy.GOLD),
			).to.be.eq(BigNumber.from('999999999999999995'))

			await expect(secretSanta.receiveGift()).to.be.revertedWith(
				"SecretSanta: you've already received a gift",
			)

			await expect(
				secretSanta.connect(accounts[0]).receiveGift(),
			).to.be.revertedWith('SecretSanta: you cannot receive your own gift')

			await secretSanta.connect(accounts[1]).receiveGift()

			expect(await erc721.balanceOf(accounts[1].address)).to.be.eq(1)

			await secretSanta.connect(accounts[0]).receiveGift()

			expect(await secretSanta.gifts()).to.have.lengthOf(0)

			await expect(
				secretSanta.connect(accounts[0]).receiveGift(),
			).to.be.revertedWith("SecretSanta: you've already received a gift")
		})

		it('Should set new receive timestamp', async () => {
			const { secretSanta, RECEIVE_TIMESTAMP } = await loadFixture(
				deploySecretSantaFixture,
			)

			expect(await secretSanta.receiveTimestamp()).to.be.eq(RECEIVE_TIMESTAMP)

			await expect(secretSanta.setReceiveTimestamp(0)).to.be.revertedWith(
				'SecretSanta: receive timestamp must be in the future',
			)

			await secretSanta.setReceiveTimestamp(RECEIVE_TIMESTAMP + 10)
		})

		it('Should support transfering tokens as owner', async () => {
			const { secretSanta, owner, erc721, erc1155, accounts } =
				await loadFixture(deploySecretSantaFixture)

			await expect(
				secretSanta.connect(accounts[0]).transferOwnership(accounts[1].address),
			).to.be.revertedWith('Ownable: caller is not the owner')

			await erc721['safeTransferFrom(address,address,uint256)'](
				owner.address,
				secretSanta.address,
				1,
			)

			await erc1155.safeTransferFrom(
				owner.address,
				accounts[0].address,
				TonimItemDummy.GOLD,
				10,
				[],
			)

			await secretSanta.approveCollection(erc1155.address)

			await erc1155
				.connect(accounts[0])
				.safeTransferFrom(
					accounts[0].address,
					secretSanta.address,
					TonimItemDummy.GOLD,
					10,
					[],
				)

			await expect(
				secretSanta['safeTransfer(address,address,uint256)'](
					owner.address,
					accounts[0].address,
					1,
				),
			).to.be.revertedWith('Pausable: not paused')

			await secretSanta.pause()

			await secretSanta['safeTransfer(address,address,uint256)'](
				erc721.address,
				accounts[0].address,
				1,
			)
			await secretSanta['safeTransfer(address,address,uint256,uint256)'](
				erc1155.address,
				accounts[0].address,
				TonimItemDummy.GOLD,
				10,
			)

			await expect(secretSanta.receiveGift()).to.be.revertedWith(
				'Pausable: paused',
			)

			await secretSanta.unpause()
		})
	})
})
