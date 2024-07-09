import { config } from "dotenv";
import { createReadStream, writeFileSync } from "fs";
import csvParser from "csv-parser";
import { getVaultData } from "./utils/getVaultData";
import { stringify } from "csv-stringify/sync";
import { ethers } from "ethers";
config();

interface AddressRecord {
  contract_address: string;
  event_count: number;
}

interface VaultRecord {
  vault_address: string;
  vault_symbol: string;
  vault_name: string;
  asset_address: string;
  asset_symbol: string;
  asset_name: string;
  asset_decimals: number;
  total_assets_base_units: string;
  total_aum_usd_m: number;
  event_count: number;
}

interface AssetPriceRecord {
  contract_address: string;
  price: number;
}

async function readCsv(filePath: string): Promise<AddressRecord[]> {
  const records: AddressRecord[] = [];
  return new Promise((resolve, reject) => {
    createReadStream(filePath)
      .pipe(csvParser())
      .on("data", (data) => records.push(data))
      .on("end", () => resolve(records))
      .on("error", (error) => reject(error));
  });
}

async function readAssetPrices(filePath: string): Promise<Map<string, number>> {
  const assetPrices = new Map<string, number>();
  return new Promise((resolve, reject) => {
    createReadStream(filePath)
      .pipe(csvParser())
      .on("data", (data: AssetPriceRecord) => {
        assetPrices.set(data.contract_address, data.price);
      })
      .on("end", () => resolve(assetPrices))
      .on("error", (error) => reject(error));
  });
}

async function processRecords(
  records: AddressRecord[],
  assetPrices: Map<string, number>
): Promise<VaultRecord[]> {
  const vaultRecords: VaultRecord[] = [];

  for (const record of records) {
    try {
      // chain read
      const vaultData = await getVaultData(record.contract_address);
      if (
        vaultData.vaultName === "error" ||
        vaultData.vaultSymbol === "error" ||
        vaultData.assetAddress === "0x0"
      ) {
        console.error(
          `Skipping ${record.contract_address} because it is missing functions and so not a proper ERC-4626 vault.`
        );
        continue;
      }

      const totalAssetsBaseUnits = BigInt(vaultData.totalAssetsBaseUnits);
      const totalAssetsNaturalUnits = Number(
        ethers.formatUnits(totalAssetsBaseUnits, vaultData.assetDecimals)
      );
      const assetPrice =
        assetPrices.get(vaultData.assetAddress.toLowerCase()) || 0;
      const totalAumUsdM = parseFloat(
        ((totalAssetsNaturalUnits * assetPrice) / 1000000).toFixed(3)
      );
      // console.log(`Vault Address: ${record.contract_address}`);
      // console.log(`Asset Address: ${vaultData.assetAddress}`);
      // console.log(`Total AUM in USD (M): ${totalAumUsdM}`);
      // console.log(`Total Assets (natural units): ${totalAssetsNaturalUnits}`);
      // console.log(`Asset Price: ${assetPrice}`);
      vaultRecords.push({
        vault_address: record.contract_address,
        vault_symbol: vaultData.vaultSymbol,
        vault_name: vaultData.vaultName,
        asset_address: vaultData.assetAddress,
        asset_symbol: vaultData.assetSymbol,
        asset_name: vaultData.assetName,
        asset_decimals: Number(vaultData.assetDecimals),
        total_assets_base_units: vaultData.totalAssetsBaseUnits.toString(),
        total_aum_usd_m: totalAumUsdM,
        event_count: record.event_count,
      });

      console.log(`Processed ${record.contract_address}`);
    } catch (error) {
      console.error(
        `Skipping ${record.contract_address} because of error: ${error}`
      );
    }
  }

  return vaultRecords;
}

function writeCsv(filePath: string, records: VaultRecord[]): void {
  const outputCsv = stringify(records, {
    header: true,
  });

  writeFileSync(filePath, outputCsv);
}

async function main() {
  try {
    const inputFilePath = "./src/data/in/addresses.csv";
    const outputFilePath = "./src/data/process/vaults.csv";
    const assetPricesFilePath = "./src/data/reference/asset-prices.csv";

    const addressRecords = await readCsv(inputFilePath);
    const assetPrices = await readAssetPrices(assetPricesFilePath);
    const vaultRecords = await processRecords(addressRecords, assetPrices);

    writeCsv(outputFilePath, vaultRecords);
    console.log(`File written to ${outputFilePath}`);
  } catch (error) {
    console.error("Error in main processing:", error);
  }
}

main();
