import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

const ONE_ADDRESS = "0x0000000000000000000000000000000000000001";

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

      const domain = {
        name: "CollectorDAO",
        version: "1",
        chainId: 31337,
        verifyingContract: await engine.getAddress(),
      };

      const types = {
        Ballot: [
          { name: "proposalId", type: "bytes32" },
          { name: "voteFor", type: "bool" },
        ],
      };

      const proposalId = "0x7361646600000000000000000000000000000000000000000000000000000000";
      const voteFor = true;

      const ballot = {
        proposalId,
        voteFor,
      };

      const signature = await owner.signTypedData(domain, types, ballot);

      const expectedSignerAddress = owner.address;
      const recoveredAddress = ethers.verifyTypedData(
        domain,
        types,
        ballot,
        signature
      );

      expect(recoveredAddress).to.equal(expectedSignerAddress);
    })

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
