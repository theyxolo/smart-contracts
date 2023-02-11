/* eslint-disable no-console */
import { ethers } from 'hardhat'

async function deployContract() {
	console.log(`Getting factory`)
	const Contract = await ethers.getContractFactory('SecretSanta')
	const contract = await Contract.deploy('1671926400', [
		'0xBB3A83e3cbB30ceA709C0ABc3DB1915127792816',
		'0xa4aaba131f8758805223aa2024708bfd0bff49aa',
		'0x741B8f2e044332e6598560735FbBcFcd870BBdAC',
		'0x32216cEF02FFF0a86243E8Bd7F46F59AA6412263',
		'0x5136ef1976a4be1bf2f29bc4240f53c969fb1d76',
		'0xce735f825732f23ce52674e3c5cc048d461637d2',
	])

	console.log(`Deploying contract`)
	await contract.deployed()

	const txHash = (contract as any).deployTransaction.hash

	console.log(`Waiting for transaction confirmation...`)
	const txReceipt = await (ethers as any).provider.waitForTransaction(txHash)
	const { contractAddress } = txReceipt

	console.log(`Contract deployed to address ${contractAddress}`)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
deployContract().catch((error) => {
	console.error(error)
	process.exitCode = 1
})
