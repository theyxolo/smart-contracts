/* eslint-disable no-unused-expressions */
import { time, loadFixture } from '@nomicfoundation/hardhat-network-helpers'
import { expect } from 'chai'
import { ethers } from 'hardhat'

// We define a fixture to reuse the same setup in every test.
// We use loadFixture to run this setup once, snapshot that state,
// and reset Hardhat Network to that snapshot in every test.
async function deploySecretSantaFixture() {
	// eslint-disable-next-line no-magic-numbers
	const ONE_MIN_IN_SECS = 60 * 60

	const RECEIVE_TIMESTAMP = (await time.latest()) + ONE_MIN_IN_SECS

	const [owner, ...accounts] = await ethers.getSigners()

	const SecretSanta = await ethers.getContractFactory('SecretSanta')
	const secretSanta = await SecretSanta.deploy(RECEIVE_TIMESTAMP, [])

	return { owner, accounts, secretSanta }
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
})
