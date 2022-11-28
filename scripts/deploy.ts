/* eslint-disable no-console */
import { ethers } from 'hardhat'

async function deployContract() {
	console.log(`Getting factory`)
	const Contract = await ethers.getContractFactory('Santa')
	const contract = await Contract.deploy('1669620442000')

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
