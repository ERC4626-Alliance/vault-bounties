// FILE: getVaultData.ts
import { ethers } from "ethers";
import { config } from "dotenv";
import { Vault__factory } from "../../../typechain-types/factories/contracts/Vault__factory";
import { Token__factory } from "../../../typechain-types/factories/contracts/Token__factory";
config();

async function main() {
  const provider = new ethers.JsonRpcProvider(
    process.env.JSON_RPC_PROVIDER_URL
  );
  console.log(process.env.JSON_RPC_PROVIDER_URL);

  // Get vault
  const vaultContractAddress = "0xd9a442856c234a39a81a089c06451ebaa4306a72";
  const vaultContract = Vault__factory.connect(vaultContractAddress, provider);

  // Get vault data
  const assetAddress: string = await vaultContract.asset();
  console.log("Asset address:", assetAddress);
  const tokenContract = Token__factory.connect(assetAddress, provider);
  const tokenName = await tokenContract.name();
  console.log("Token name:", tokenName);
}

main().catch((error) => {
  console.error("Error:", error);
  process.exit(1);
});
