/**
 * Script to find GoodDollar (G$) token address on Celo
 * 
 * This script searches for the G$ token contract on Celo mainnet
 * by checking known addresses or scanning token lists.
 */

const hre = require("hardhat");
const { ethers } = require("ethers");

// Known G$ address on Celo (from GoodDollar documentation)
const POTENTIAL_ADDRESSES = [
  "0x62B8B11039FcfE5aB0C56E502b1C372A3d2a9c7A", // G$ on Celo mainnet (official)
];

// Celo RPC
const CELO_RPC = "https://forno.celo.org";
const provider = new ethers.JsonRpcProvider(CELO_RPC);

// Standard ERC20 ABI for checking token
const ERC20_ABI = [
  "function name() view returns (string)",
  "function symbol() view returns (string)",
  "function decimals() view returns (uint8)",
  "function totalSupply() view returns (uint256)",
  "function balanceOf(address) view returns (uint256)",
];

async function checkToken(address) {
  try {
    const token = new ethers.Contract(address, ERC20_ABI, provider);
    const [name, symbol, decimals] = await Promise.all([
      token.name(),
      token.symbol(),
      token.decimals(),
    ]);
    
    // Check if it's GoodDollar
    if (symbol.toUpperCase().includes("G$") || 
        symbol.toUpperCase() === "GDOLLAR" ||
        name.toLowerCase().includes("gooddollar")) {
      return { address, name, symbol, decimals, isGoodDollar: true };
    }
    
    return { address, name, symbol, decimals, isGoodDollar: false };
  } catch (error) {
    return { address, error: error.message };
  }
}

async function findGoodDollar() {
  console.log("🔍 Searching for GoodDollar (G$) token on Celo...\n");
  
  // Method 1: Check known addresses
  if (POTENTIAL_ADDRESSES.length > 0) {
    console.log("📋 Checking known addresses...");
    for (const addr of POTENTIAL_ADDRESSES) {
      const info = await checkToken(addr);
      if (info.isGoodDollar) {
        console.log("\n✅ FOUND G$ TOKEN!");
        console.log("Address:", info.address);
        console.log("Name:", info.name);
        console.log("Symbol:", info.symbol);
        console.log("Decimals:", info.decimals);
        return info.address;
      } else if (info.error) {
        console.log(`❌ ${addr}: ${info.error}`);
      } else {
        console.log(`⚠️  ${addr}: ${info.symbol} (${info.name}) - Not G$`);
      }
    }
  }
  
  // Method 2: Check token lists
  console.log("\n📋 Checking token lists...");
  console.log("💡 Try checking:");
  console.log("   - GoodWallet repository");
  console.log("   - GoodDollar GitHub: https://github.com/GoodDollar");
  console.log("   - Celo token lists");
  console.log("   - GoodWallet documentation");
  
  // Method 3: Contact GoodDollar team
  console.log("\n💡 Alternative: Contact GoodDollar team for Celo address");
  console.log("   - Discord: https://discord.gg/gooddollar");
  console.log("   - GitHub Issues: https://github.com/GoodDollar");
  
  console.log("\n⚠️  G$ token address on Celo not found automatically.");
  console.log("    Please check GoodDollar documentation or contact their team.");
  
  return null;
}

// Alternative: Manual search using CeloScan
async function searchCeloScan() {
  console.log("\n💡 To find manually:");
  console.log("1. Go to https://celoscan.io");
  console.log("2. Search for 'GoodDollar' or 'G$'");
  console.log("3. Check token contracts");
  console.log("4. Verify it's the official GoodDollar token");
}

async function main() {
  console.log("🌍 GoodDollar (G$) Token Finder for Celo\n");
  console.log("Network: Celo Mainnet");
  console.log("RPC:", CELO_RPC);
  console.log("─".repeat(50));
  
  const address = await findGoodDollar();
  
  if (address) {
    console.log("\n✅ Add this to your config:");
    console.log(`GDOLLAR_CELO: "${address}"`);
  } else {
    await searchCeloScan();
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

