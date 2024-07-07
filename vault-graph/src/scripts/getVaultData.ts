// FILE: getVaultData.ts
import { ethers } from "ethers";
import { config } from "dotenv";
import { Vault__factory } from "../../typechain-types/factories/contracts/Vault__factory";
config();

async function main() {
  const provider = new ethers.JsonRpcProvider(
    process.env.JSON_RPC_PROVIDER_URL
  );

  console.log(process.env.JSON_RPC_PROVIDER_URL);

  // Define the contract address
  const contractAddress = "0xd9a442856c234a39a81a089c06451ebaa4306a72";

  // Create a contract instance using the factory
  const vaultContract = Vault__factory.connect(contractAddress, provider);

  try {
    // Call the asset() function
    const assetAddress: string = await vaultContract.asset();
    console.log("Asset address:", assetAddress);
  } catch (error) {
    console.error("Error calling asset():", error);
  }
}

main().catch((error) => {
  console.error("Error:", error);
  process.exit(1);
});
