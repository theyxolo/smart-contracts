// scripts/create-box.js
import { ethers, upgrades } from 'hardhat'

async function main() {
	console.log('Getting Contract factory')

	const Contract = await ethers.getContractFactory('StakeXolo')

	console.log('Deploying Contract...')

	const proxy = await upgrades.deployProxy(
		Contract,
		[
			'0xdc8fcd95b62c7f84d89b4012c9030c1e25cf02ea',
			'0x1519758d9C05199128ebA200DA9318fbfc5eC8E2',
		],
		{ timeout: 60_000 },
	)

	console.log('Waiting for confirmation...')

	await proxy.deployed()

	console.log('\nProxy contract at:', proxy.address)

	console.log(
		'Implementation at:',
		await upgrades.erc1967.getImplementationAddress(proxy.address),
	)
}

main()
