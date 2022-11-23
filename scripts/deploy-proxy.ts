/* eslint-disable no-console */
// scripts/create-box.js
import { ethers, upgrades } from 'hardhat'

async function main() {
	console.log('Getting Contract factory')

	const Contract = await ethers.getContractFactory('Tonim')

	console.log('Deploying Contract')

	const proxy = await upgrades.deployProxy(Contract, [])

	console.log('Waiting for confirmation...')

	await proxy.deployed()

	console.log('Contract proxy deployed to:', proxy.address)

	console.log(
		'Implementation at:',
		await upgrades.erc1967.getImplementationAddress(proxy.address),
	)
}

main()
