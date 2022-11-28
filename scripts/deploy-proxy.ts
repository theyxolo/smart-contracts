// scripts/create-box.js
import { ethers, upgrades } from 'hardhat'

async function main() {
	console.log('Getting Contract factory')

	const Contract = await ethers.getContractFactory('Tonim')

	console.log('Deploying Contract...')

	const proxy = await upgrades.deployProxy(Contract, [], { timeout: 60_000 })

	console.log('Waiting for confirmation...')

	await proxy.deployed()

	console.log('\nProxy contract at:', proxy.address)

	console.log(
		'Implementation at:',
		await upgrades.erc1967.getImplementationAddress(proxy.address),
	)
}

main()
