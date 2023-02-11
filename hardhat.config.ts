/* eslint-disable @typescript-eslint/no-non-null-assertion */
import { HardhatUserConfig } from 'hardhat/config'
import '@nomicfoundation/hardhat-toolbox'
import '@nomicfoundation/hardhat-chai-matchers'
import '@openzeppelin/hardhat-upgrades'
import dotenv from 'dotenv'
import 'solidity-coverage'

dotenv.config()

const {
	PROJECT_ID,
	PRIVATE_KEY,
	ARBISCAN_API_KEY,
	SNOWTRACE_API_KEY,
	ETHERSCAN_API_KEY,
	POLYGONSCAN_API_KEY,
	OPTIMISM_ETHERSCAN_API_KEY,
} = process.env

const config: HardhatUserConfig = {
	defaultNetwork: 'goerli',
	solidity: {
		version: '0.8.17',
		settings: {
			optimizer: {
				enabled: true,
				runs: 200,
			},
		},
	},
	networks: {
		hardhat: {},
		mainnet: {
			url: `https://mainnet.infura.io/v3/${PROJECT_ID}`,
			accounts: [PRIVATE_KEY!],
		},
		goerli: {
			url: `https://goerli.infura.io/v3/${PROJECT_ID}`,
			accounts: [PRIVATE_KEY!],
		},
		polygon: {
			url: `https://polygon-mainnet.infura.io/v3/${PROJECT_ID}`,
			accounts: [PRIVATE_KEY!],
		},
		polygonMumbai: {
			url: `https://polygon-mumbai.infura.io/v3/${PROJECT_ID}`,
			accounts: [PRIVATE_KEY!],
		},
		optimisticGoerli: {
			url: `https://optimism-goerli.infura.io/v3/${PROJECT_ID}`,
			accounts: [PRIVATE_KEY!],
		},
		arbitrumGoerli: {
			url: `https://arbitrum-goerli.infura.io/v3/${PROJECT_ID}`,
			accounts: [PRIVATE_KEY!],
		},
		avalancheFujiTestnet: {
			url: `https://avalanche-fuji.infura.io/v3/${PROJECT_ID}`,
			accounts: [PRIVATE_KEY!],
		},
	},
	etherscan: {
		apiKey: {
			mainnet: ETHERSCAN_API_KEY!,
			goerli: ETHERSCAN_API_KEY!,
			polygon: POLYGONSCAN_API_KEY!,
			arbitrumGoerli: ARBISCAN_API_KEY!,
			polygonMumbai: POLYGONSCAN_API_KEY!,
			avalancheFujiTestnet: SNOWTRACE_API_KEY!,
			optimisticGoerli: OPTIMISM_ETHERSCAN_API_KEY!,
		},
	},
}

export default config
