const hre = require("hardhat");

async function main() {
  console.log("⚙️ Setting Engagement Rewards Contract Address...\n");

  // 1. Get the Engagement Rewards Address
  // We need to get this from Lewis/GoodDollar or environment variable
  const ENGAGEMENT_REWARDS_ADDRESS = process.env.ENGAGEMENT_REWARDS_ADDRESS;

  if (!ENGAGEMENT_REWARDS_ADDRESS) {
    console.error("❌ Error: ENGAGEMENT_REWARDS_ADDRESS is missing.");
    console.log("   Please set it using:");
    console.log("   export ENGAGEMENT_REWARDS_ADDRESS=0x...");
    console.log("   npx hardhat run scripts/set-engagement-rewards.js --network celo");
    process.exit(1);
  }

  // 2. Get the deployed SecureFlow contract
  const deployedInfo = require("../deployed.json");
  const secureFlowAddress = deployedInfo.networks?.celo?.SecureFlow || deployedInfo.contracts?.SecureFlow;

  if (!secureFlowAddress) {
    console.error("❌ Error: SecureFlow contract address not found in deployed.json");
    process.exit(1);
  }

  console.log("SecureFlow Contract:", secureFlowAddress);
  console.log("Engagement Rewards:", ENGAGEMENT_REWARDS_ADDRESS);

  // 3. Get Signer
  const [deployer] = await hre.ethers.getSigners();
  console.log("\nActing as:", deployer.address);

  // 4. Attach to Contract
  const SecureFlow = await hre.ethers.getContractFactory("SecureFlow");
  const secureFlow = SecureFlow.attach(secureFlowAddress);

  // 5. Set the address
  console.log("\n📝 Sending transaction to setEngagementRewards...");
  try {
    const tx = await secureFlow.setEngagementRewards(ENGAGEMENT_REWARDS_ADDRESS);
    console.log("   Tx Hash:", tx.hash);
    console.log("   Waiting for confirmation...");
    
    await tx.wait();
    console.log("✅ Success! Engagement Rewards address configured.");
    
    // Verify
    const currentAddress = await secureFlow.engagementRewards();
    console.log("\n🔍 Verification:");
    console.log("   Current Configured Address:", currentAddress);
    
    if (currentAddress.toLowerCase() === ENGAGEMENT_REWARDS_ADDRESS.toLowerCase()) {
      console.log("   Match Confirmed!");
    } else {
      console.warn("   ⚠️ Warning: Address mismatch after update.");
    }

  } catch (error) {
    console.error("\n❌ Transaction failed:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
