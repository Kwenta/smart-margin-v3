import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

const ONE_ADDRESS = "0x0000000000000000000000000000000000000001";

// example data
const domainSeparator =
  "0x8c5858714ec5af03fd2ee4772a4502b25abc93609cb57f7745fca2c17a7dbf1f";
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
const conditions: any[] = [];
const engineAddress = "0x500A139459fA3628C416A6b19BFADd83B20e5D0b";

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

  describe("Deployment", function () {
    it("Should set the right unlockTime", async function () {
      const { engine } = await loadFixture(bootstrapSystem);

      expect(await engine.getAddress()).to.exist;
    });

    it("Should work", async () => {
      const { engine, owner } = await loadFixture(bootstrapSystem);
      const wallet = new ethers.Wallet(signerPrivateKey);
      const signer = wallet.address;
      const engineAddress = await engine.getAddress();

      // const domain = {
      //   name: "CollectorDAO",
      //   version: "1",
      //   chainId: 31337,
      //   verifyingContract: await engine.getAddress(),
      // };

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

      const signature = await owner.signTypedData(
        domain,
        types,
        conditionalOrder
      );

      const expectedSignerAddress = owner.address;
      const recoveredAddress = ethers.verifyTypedData(
        domain,
        types,
        conditionalOrder,
        signature
      );

      expect(recoveredAddress).to.equal(expectedSignerAddress);
    });

    // it("Should set the right owner", async function () {
    //   const { lock, owner } = await loadFixture(bootstrapSystem);

    //   expect(await lock.owner()).to.equal(owner.address);
    // });

    // it("Should receive and store the funds to lock", async function () {
    //   const { lock, lockedAmount } = await loadFixture(
    //     bootstrapSystem
    //   );

    //   expect(await ethers.provider.getBalance(lock.target)).to.equal(
    //     lockedAmount
    //   );
    // });

    // it("Should fail if the unlockTime is not in the future", async function () {
    //   // We don't use the fixture here because we want a different deployment
    //   const latestTime = await time.latest();
    //   const Lock = await ethers.getContractFactory("Lock");
    //   await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
    //     "Unlock time should be in the future"
    //   );
    // });
  });

  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(bootstrapSystem);

  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         bootstrapSystem
  //       );

  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);

  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });

  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         bootstrapSystem
  //       );

  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });

  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         bootstrapSystem
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });

  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         bootstrapSystem
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  // });
});
