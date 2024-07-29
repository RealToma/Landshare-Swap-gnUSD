// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const addressgnUSD = "0x5c1409a46cD113b3A667Db6dF0a8D7bE37ed3BB3";
  const addressLandshare = "0x45934E0253955dE498320D67c0346793be44BEC0";

  const contractLandshareSwap = await hre.ethers.getContractFactory(
    "LandshareSwap"
  );
  const greeter = await contractLandshareSwap.deploy(
    addressgnUSD,
    addressLandshare
  );

  await greeter.deployed();

  console.log("Greeter deployed to:", greeter.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
