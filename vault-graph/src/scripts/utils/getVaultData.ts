import { ethers } from "ethers";
import { Token__factory } from "../../../typechain-types/factories/contracts/Token__factory";
import { Vault__factory } from "../../../typechain-types/factories/contracts/Vault__factory";

interface VaultData {
  vaultSymbol: string;
  vaultName: string;
  assetAddress: string;
  assetSymbol: string;
  assetName: string;
  assetDecimals: bigint;
  totalAssetsBaseUnits: bigint;
}

export async function getVaultData(vaultAddress: string): Promise<VaultData> {
  const provider = new ethers.JsonRpcProvider(
    process.env.JSON_RPC_PROVIDER_URL
  );
  const vaultContract = Vault__factory.connect(vaultAddress, provider);

  try {
    const assetAddress = await vaultContract.asset();
    const assetContract = Token__factory.connect(assetAddress, provider);

    const [
      vaultSymbol,
      vaultName,
      assetSymbol,
      assetName,
      assetDecimals,
      totalAssetsBaseUnits,
    ] = await Promise.all([
      vaultContract.symbol(),
      vaultContract.name(),
      assetContract.symbol(),
      assetContract.name(),
      assetContract.decimals(),
      vaultContract.totalAssets(),
    ]);

    return {
      vaultSymbol,
      vaultName,
      assetAddress,
      assetSymbol,
      assetName,
      assetDecimals,
      totalAssetsBaseUnits,
    };
  } catch (error) {
    //console.error(`Error fetching data for vault ${vaultAddress}:`, error);
    return {
      vaultSymbol: "error",
      vaultName: "error",
      assetAddress: "0x0",
      assetSymbol: "error",
      assetName: "error",
      assetDecimals: 0n,
      totalAssetsBaseUnits: 0n,
    };
  }
}
