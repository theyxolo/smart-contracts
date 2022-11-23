import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
import '@nomicfoundation/hardhat-chai-matchers'
import '@openzeppelin/hardhat-upgrades'
import dotenv from 'dotenv'

dotenv.config()

const { PROJECT_ID, ETHERSCAN_API_KEY, PRIVATE_KEY } = process.env

const config: HardhatUserConfig = {
	defaultNetwork: 'goerli',
	solidity: {
		version: '0.8.17',
		settings: {
			optimizer: {
				enabled: true,
				runs: 102000,
			},
		},
	},
	networks: {
		goerli: {
			url: `https://goerli.infura.io/v3/${PROJECT_ID}`,
			// eslint-disable-next-line @typescript-eslint/no-non-null-assertion
			accounts: [PRIVATE_KEY!],
		},
	},
	etherscan: {
		apiKey: ETHERSCAN_API_KEY,
	},
}

export default config
