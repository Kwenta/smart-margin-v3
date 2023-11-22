import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

const ONE_ADDRESS = "0x0000000000000000000000000000000000000001";

// example data
const signerPrivateKey =
  "0xe690d00bd51f5343c6999d8e88328e3dfa0111b65f2a8790d48f89fe43ad07c0";
const marketId = "200";
const accountId = "170141183460469231731687303715884105756";
const sizeDelta = "1000000000000000000";
const settlementStrategyId = "0";
const acceptablePrice =
  "115792089237316195423570985008687907853269984665640564039457584007913129639935";
const isReduceOnly = false;
const trackingCode =
  "0x4b57454e54410000000000000000000000000000000000000000000000000000";
const referrer = "0xF510a2Ff7e9DD7e18629137adA4eb56B9c13E885";
const nonce = "0";
const requireVerified = false;
const trustedExecutor = "0x7FA9385bE102ac3EAc297483Dd6233D62b3e1496";
const maxExecutorFee =
  "115792089237316195423570985008687907853269984665640564039457584007913129639935";
// 0x6162630000000000000000000000000000000000000000000000000000000000 = abc
// 0x6465660000000000000000000000000000000000000000000000000000000000 = def
// 0x6768690000000000000000000000000000000000000000000000000000000000 = ghi
const conditions: any[] = [
  "0x6162630000000000000000000000000000000000000000000000000000000000",
  "0x6465660000000000000000000000000000000000000000000000000000000000",
  "0x6768690000000000000000000000000000000000000000000000000000000000",
];

describe("Signature", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function bootstrapSystem() {
    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const Engine = await ethers.getContractFactory("Engine");
    const engine = await Engine.deploy(
      ONE_ADDRESS,
      ONE_ADDRESS,
      ONE_ADDRESS,
      ONE_ADDRESS,
      ONE_ADDRESS
    );
    await engine.waitForDeployment();

    return { engine, owner, otherAccount };
  }

  describe("Signature checks", function () {
    it("The engine deployed successfully", async function () {
      const { engine } = await loadFixture(bootstrapSystem);

      expect(await engine.getAddress()).to.exist;
    });

    it("Signature is verified", async () => {
      const { engine } = await loadFixture(bootstrapSystem);
      const wallet = new ethers.Wallet(signerPrivateKey);
      const signer = wallet.address;
      const engineAddress = await engine.getAddress();

      const domain = {
        name: "SMv3: OrderBook",
        version: "1",
        chainId: 31337,
        verifyingContract: engineAddress,
      };

      const types = {
        OrderDetails: [
          { name: "marketId", type: "uint128" },
          { name: "accountId", type: "uint128" },
          { name: "sizeDelta", type: "int128" },
          { name: "settlementStrategyId", type: "uint128" },
          { name: "acceptablePrice", type: "uint256" },
          { name: "isReduceOnly", type: "bool" },
          { name: "trackingCode", type: "bytes32" },
          { name: "referrer", type: "address" },
        ],
        ConditionalOrder: [
          { name: "orderDetails", type: "OrderDetails" },
          { name: "signer", type: "address" },
          { name: "nonce", type: "uint256" },
          { name: "requireVerified", type: "bool" },
          { name: "trustedExecutor", type: "address" },
          { name: "maxExecutorFee", type: "uint256" },
          { name: "conditions", type: "bytes[]" },
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

      const res = await engine.verifySignature(conditionalOrder, signature);
      expect(res).to.be.true;
    });
  });
});
