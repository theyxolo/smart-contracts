// scripts/upgrade-box.js
import { ethers, upgrades } from 'hardhat'

const PROXY_ADDRESS = '0xF79E44edA0e01690169A767aFCb81467c68D3536'

async function main() {
	console.log('Getting factory...')
	const ContractFactory = await ethers.getContractFactory('Tonim2')

	console.log('Upgrading proxy...')
	const proxy = await upgrades.upgradeProxy(PROXY_ADDRESS, ContractFactory, {
		constructorArgs: [],
	})
	console.log('Proxy upgraded', proxy.address)

	console.log(
		'Implementation at:',
		await upgrades.erc1967.getImplementationAddress(PROXY_ADDRESS),
	)
}

main()
