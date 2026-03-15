const hre = require("hardhat");

async function main() {
  console.log("Starting deployment...");
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying from:", deployer.address);

  const OrbitWork = await hre.ethers.getContractFactory("OrbitWork");
  console.log("ContractFactory obtained.");
  
  const orbitWork = await OrbitWork.deploy("0x0000000000000000000000000000000000000000", deployer.address, 0);
  console.log("Deployment transaction sent.");

  await orbitWork.waitForDeployment();
  const address = await orbitWork.getAddress();
  console.log("OrbitWork deployed to:", address);
}

main().catch((error) => {
  console.error("DEPLOYMENT ERROR:", error);
  process.exit(1);
});
