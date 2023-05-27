const hre = require("hardhat");

async function main() {
  const MultiSigWallet = await hre.ethers.getContractFactory("multiSigWallet");
  [owner1, owner2, owner3, nonOwner] = await ethers.getSigners();
  const multiSigWallet = await MultiSigWallet.deploy(
    [owner1.address, owner2.address, owner3.address],
    2
  );
  await multiSigWallet.deployed();
  console.log("contract deployed at: ", multiSigWallet.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
