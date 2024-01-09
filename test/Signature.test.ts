import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';

const MOCK_USDC_BYTECODE =
	'0x608060405234801561001057600080fd5b5060b98061001f6000396000f3fe6080604052348015600f57600080fd5b506004361060285760003560e01c8063313ce56714602d575b600080fd5b60336047565b604051603e9190606a565b60405180910390f35b60006008905090565b600060ff82169050919050565b6064816050565b82525050565b6000602082019050607d6000830184605d565b9291505056fea264697066735822122070561a079f6d67b91cf7443eab290d752ac6b75378d0b77716c1d028b31c85d064736f6c63430008140033';
const MOCK_USDC_ABI = [
	{
		inputs: [],
		name: 'decimals',
		outputs: [
			{
				internalType: 'uint8',
				name: '',
				type: 'uint8',
			},
		],
		stateMutability: 'pure',
		type: 'function',
	},
];

const MOCK_SPOT_MARKET_BYTECODE =
	'0x608060405234801561001057600080fd5b506102a3806100206000396000f3fe608060405234801561001057600080fd5b50600436106100365760003560e01c806369e0365f1461003b578063c624440a1461006b575b600080fd5b61005560048036038101906100509190610132565b61009b565b60405161006291906101a0565b60405180910390f35b61008560048036038101906100809190610132565b6100a6565b604051610092919061024b565b60405180910390f35b600060069050919050565b60606040518060400160405280601e81526020017f53796e7468657469632055534420436f696e2053706f74204d61726b657400008152509050919050565b600080fd5b60006fffffffffffffffffffffffffffffffff82169050919050565b61010f816100ea565b811461011a57600080fd5b50565b60008135905061012c81610106565b92915050565b600060208284031215610148576101476100e5565b5b60006101568482850161011d565b91505092915050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b600061018a8261015f565b9050919050565b61019a8161017f565b82525050565b60006020820190506101b56000830184610191565b92915050565b600081519050919050565b600082825260208201905092915050565b60005b838110156101f55780820151818401526020810190506101da565b60008484015250505050565b6000601f19601f8301169050919050565b600061021d826101bb565b61022781856101c6565b93506102378185602086016101d7565b61024081610201565b840191505092915050565b600060208201905081810360008301526102658184610212565b90509291505056fea26469706673582212203c499a7561201aac9c11d851aa1980731b3532382af7a59a5794b115e64e02c964736f6c63430008140033';
const MOCK_SPOT_MARKET_ABI = [
	{
		inputs: [
			{
				internalType: 'uint128',
				name: '',
				type: 'uint128',
			},
		],
		name: 'getSynth',
		outputs: [
			{
				internalType: 'address',
				name: '',
				type: 'address',
			},
		],
		stateMutability: 'pure',
		type: 'function',
	},
	{
		inputs: [
			{
				internalType: 'uint128',
				name: '',
				type: 'uint128',
			},
		],
		name: 'name',
		outputs: [
			{
				internalType: 'string',
				name: '',
				type: 'string',
			},
		],
		stateMutability: 'pure',
		type: 'function',
	},
];

const ONE_ADDRESS = '0x0000000000000000000000000000000000000001';
const ID = 19;

// example data
const signerPrivateKey =
	'0xe690d00bd51f5343c6999d8e88328e3dfa0111b65f2a8790d48f89fe43ad07c0';
const marketId = '200';
const accountId = '170141183460469231731687303715884105756';
const sizeDelta = '1000000000000000000';
const settlementStrategyId = '0';
const acceptablePrice =
	'115792089237316195423570985008687907853269984665640564039457584007913129639935';
const isReduceOnly = false;
const trackingCode =
	'0x4b57454e54410000000000000000000000000000000000000000000000000000';
const referrer = '0xF510a2Ff7e9DD7e18629137adA4eb56B9c13E885';
const nonce = '0';
const requireVerified = false;
const trustedExecutor = '0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496';
const maxExecutorFee =
	'115792089237316195423570985008687907853269984665640564039457584007913129639935';
// 0x6162630000000000000000000000000000000000000000000000000000000000 = abc
// 0x6465660000000000000000000000000000000000000000000000000000000000 = def
// 0x6768690000000000000000000000000000000000000000000000000000000000 = ghi
const conditions: string[] = [
	'0x6162630000000000000000000000000000000000000000000000000000000000',
	'0x6465660000000000000000000000000000000000000000000000000000000000',
	'0x6768690000000000000000000000000000000000000000000000000000000000',
];

describe('Signature', function () {
	// We define a fixture to reuse the same setup in every test.
	// We use loadFixture to run this setup once, snapshot that state,
	// and reset Hardhat Network to that snapshot in every test.
	async function bootstrapSystem() {
		// Contracts are deployed using the first signer/account by default
		const [owner, otherAccount] = await ethers.getSigners();

		const MockUSDC = new ethers.ContractFactory(
			MOCK_USDC_ABI,
			MOCK_USDC_BYTECODE,
			otherAccount
		);
		const usdc = await MockUSDC.deploy();

		const MockSpotMarket = new ethers.ContractFactory(
			MOCK_SPOT_MARKET_ABI,
			MOCK_SPOT_MARKET_BYTECODE,
			otherAccount
		);
		const spotMarket = await MockSpotMarket.deploy();

		const Engine = await ethers.getContractFactory('Engine');
		const engine = await Engine.deploy(
			ONE_ADDRESS, // Perps Market Proxy Address
			spotMarket.getAddress(), // Spot Market Proxy Address
			ONE_ADDRESS, // sUSD Token Proxy Address
			ONE_ADDRESS, // pDAO Multisig Address
			usdc.getAddress(), // USDC Address
			ID // sUSD Id
		);
		await engine.waitForDeployment();

		return { engine, owner, otherAccount };
	}

	describe('Signature checks', function () {
		it('The engine deployed successfully', async function () {
			const { engine } = await loadFixture(bootstrapSystem);

			expect(await engine.getAddress()).to.exist;
		});

		it('Signature is verified', async () => {
			const { engine } = await loadFixture(bootstrapSystem);
			const wallet = new ethers.Wallet(signerPrivateKey);
			const signer = wallet.address;
			const engineAddress = await engine.getAddress();

			const domain = {
				name: 'SMv3: OrderBook',
				version: '1',
				chainId: 31337,
				verifyingContract: engineAddress,
			};

			const types = {
				OrderDetails: [
					{ name: 'marketId', type: 'uint128' },
					{ name: 'accountId', type: 'uint128' },
					{ name: 'sizeDelta', type: 'int128' },
					{ name: 'settlementStrategyId', type: 'uint128' },
					{ name: 'acceptablePrice', type: 'uint256' },
					{ name: 'isReduceOnly', type: 'bool' },
					{ name: 'trackingCode', type: 'bytes32' },
					{ name: 'referrer', type: 'address' },
				],
				ConditionalOrder: [
					{ name: 'orderDetails', type: 'OrderDetails' },
					{ name: 'signer', type: 'address' },
					{ name: 'nonce', type: 'uint256' },
					{ name: 'requireVerified', type: 'bool' },
					{ name: 'trustedExecutor', type: 'address' },
					{ name: 'maxExecutorFee', type: 'uint256' },
					{ name: 'conditions', type: 'bytes[]' },
				],
			};

			let orderDetails = {
				marketId: BigInt(marketId),
				accountId: BigInt(accountId),
				sizeDelta: BigInt(sizeDelta),
				settlementStrategyId: BigInt(settlementStrategyId),
				acceptablePrice: BigInt(acceptablePrice),
				isReduceOnly: isReduceOnly,
				trackingCode: trackingCode,
				referrer: referrer,
			};

			// define the conditional order struct
			let conditionalOrder = {
				orderDetails: orderDetails,
				signer: signer,
				nonce: BigInt(nonce),
				requireVerified: requireVerified,
				trustedExecutor: trustedExecutor,
				maxExecutorFee: BigInt(maxExecutorFee),
				conditions: conditions,
			};

			const signature = await wallet.signTypedData(
				domain,
				types,
				conditionalOrder
			);

			const recoveredAddress = ethers.verifyTypedData(
				domain,
				types,
				conditionalOrder,
				signature
			);

			expect(recoveredAddress).to.equal(signer);

			const res = await engine.verifySignature(
				conditionalOrder,
				signature
			);
			expect(res).to.be.true;
		});
	});
});
