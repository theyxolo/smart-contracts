// scripts/upgrade-box.js
import { ethers, upgrades } from 'hardhat'

const PROXY_ADDRESS = '0x39eB8a67aE91440BB3e7487fFD309f61B1271Df5'

async function main() {
	console.log('Getting factory...')
	const ContractFactory = await ethers.getContractFactory('StakeXolo2')

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
