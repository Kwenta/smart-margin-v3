import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-preprocessor';
import fs from 'fs';

function getRemappings() {
	return fs
		.readFileSync('remappings.txt', 'utf8')
		.split('\n')
		.filter(Boolean) // remove empty lines
		.map((line) => line.trim().split('='));
}

const config: HardhatUserConfig = {
	solidity: {
		version: '0.8.20',
		settings: {
			optimizer: {
				enabled: true,
				runs: 1000,
			},
		},
	},
	preprocess: {
		eachLine: (_) => ({
			transform: (line: string) => {
				if (line.match(/^\s*import /i)) {
					for (const [from, to] of getRemappings()) {
						if (line.includes(from)) {
							line = line.replace(from, to);
							break;
						}
					}
				}
				return line;
			},
		}),
	},
	paths: {
		sources: './src',
		cache: './cache_hardhat',
	},
};

export default config;
