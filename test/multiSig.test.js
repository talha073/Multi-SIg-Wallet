const { ethers } = require("hardhat");
const { expect, assert } = require("chai");

describe("MultiSigWallet", function () {
  let multiSigWallet;
  let owner1;
  let owner2;
  let owner3;
  let nonOwner;
  let confirmation = 2;

  beforeEach(async function () {
    const MultiSigWallet = await ethers.getContractFactory("multiSigWallet");
    [owner1, owner2, owner3, nonOwner] = await ethers.getSigners();
    multiSigWallet = await MultiSigWallet.deploy(
      [owner1.address, owner2.address, owner3.address],
      confirmation
    );
    await multiSigWallet.deployed();
  });

  it("should have the correct owners and required confirmations", async function () {
    expect(await multiSigWallet.getOwners()).to.have.members([
      owner1.address,
      owner2.address,
      owner3.address,
    ]);
    expect(await multiSigWallet.required()).to.equal(2);
  });
  it("should allow depositing ether", async function () {
    const depositAmount = ethers.utils.parseEther("1");
    const initialBalance = await ethers.provider.getBalance(
      multiSigWallet.address
    );
    await owner1.sendTransaction({
      to: multiSigWallet.address,
      value: depositAmount,
    });
    const newBalance = await ethers.provider.getBalance(multiSigWallet.address);
    expect(newBalance).to.equal(initialBalance.add(depositAmount));
  });
  it("should submit and approve a transaction", async () => {
    const to = owner2.address;
    const value = ethers.utils.parseEther("1.0");
    const data = "0x";

    // Submit a transaction from owner1 to owner2
    const submitTransaction = await multiSigWallet.submit(to, value, data);
    const submitTransactionReceipt = await submitTransaction.wait();
    const txId = submitTransactionReceipt.events[0].args[0].toNumber();

    // Verify the SubmitTransaction event is emitted correctly
    const submitTransactionEvent = await getEvent(
      multiSigWallet,
      "SubmitTransaction(uint256)"
    );

    assert.equal(
      submitTransactionEvent.txId.toNumber(),
      txId,
      "Transaction ID is incorrect"
    );

    // Approve the transaction from owner2
    const approveTransaction = await multiSigWallet
      .connect(owner2)
      .approve(txId);
    await approveTransaction.wait();

    // Verify the Approve event is emitted correctly
    const approveEvent = await getEvent(
      multiSigWallet,
      "Approve(address,uint256)"
    );

    assert.equal(
      approveEvent.owner,
      owner2.address,
      "Approving owner address is incorrect"
    );
    assert.equal(
      approveEvent.txId.toNumber(),
      txId,
      "Transaction ID is incorrect"
    );
  });

  // Helper function to get a specific event emitted by the contract
  async function getEvent(contract, eventName) {
    const filter = contract.filters[eventName]();
    const logs = await contract.queryFilter(filter);
    const event = logs[logs.length - 1].args;
    return event;
  }
  it("should allow confirming a transaction", async function () {
    await multiSigWallet.submit(
      nonOwner.address,
      ethers.utils.parseEther("1"),
      "0x"
    );
    const tx = await multiSigWallet.connect(owner2).approve(0);
    const receipt = await tx.wait();
    expect(receipt.events[0].event).to.equal("Approve");
    expect(receipt.events[0].args.owner).to.equal(owner2.address);
  });
  it("should not allow confirming a transaction twice", async function () {
    await multiSigWallet.submit(
      nonOwner.address,
      ethers.utils.parseEther("1"),
      "0x"
    );
    await multiSigWallet.connect(owner2).approve(0);
    await expect(multiSigWallet.connect(owner2).approve(0)).to.be.revertedWith(
      "tx already approved"
    );
  });
  it("should not allow confirming a non-existent transaction", async function () {
    await expect(multiSigWallet.connect(owner1).approve(0)).to.be.revertedWith(
      "Tx not exist"
    );
  });
  it("should allow revoking a confirmation", async function () {
    await multiSigWallet.submit(
      nonOwner.address,
      ethers.utils.parseEther("1"),
      "0x"
    );
    await multiSigWallet.connect(owner2).approve(0);
    const tx = await multiSigWallet.connect(owner2).revoke(0);
    const receipt = await tx.wait();
    expect(receipt.events[0].event).to.equal("Revoke");
    expect(receipt.events[0].args.owner).to.equal(owner2.address);
  });
  it("should not allow revoking a non-existent transaction", async function () {
    await expect(multiSigWallet.connect(owner1).revoke(0)).to.be.revertedWith(
      "Tx not exist"
    );
  });
  it("should not allow executing a non-existent transaction", async function () {
    await expect(multiSigWallet.connect(owner2).approve(1)).to.be.revertedWith(
      "Tx not exist"
    );
  });
});
