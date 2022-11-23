// scripts/upgrade-box.js
import { ethers, upgrades } from 'hardhat'

const PROXY_ADDRESS = '0x5821EfB4e442622664432C75960b134BE7Dcd356'

async function main() {
	// const StakeXolo2 = await ethers.getContractFactory('StakeXolo2')
	// const proxy = await upgrades.upgradeProxy(PROXY_ADDRESS, StakeXolo2)
	// console.log('Proxy upgraded')

	console.log(
		'Implementation at:',
		await upgrades.erc1967.getImplementationAddress(PROXY_ADDRESS),
	)
}

main()
