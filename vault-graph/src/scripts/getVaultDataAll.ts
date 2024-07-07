import { config } from "dotenv";
import { createReadStream } from "fs";
import { createWriteStream } from "fs";
import { getVaultData } from "./getVaultData";
import { writeStringToFile } from "./utils/utils";
import csvParser from "csv-parser";
import { stringify } from "csv-stringify/sync";

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
  total_aum_usd_m: number;
  event_count: number;
}

async function processCsv() {
  const vaultRecords: VaultRecord[] = [];

  return new Promise<void>((resolve, reject) => {
    createReadStream("./src/data/addresses.csv")
      .pipe(csvParser())
      .on("data", async (record: AddressRecord) => {
        try {
          const vaultData = await getVaultData(record.contract_address);

          if (
            vaultData.vaultName === "error" ||
            vaultData.vaultSymbol === "error" ||
            vaultData.assetAddress === "0x0"
          ) {
            console.error(
              `Skipping ${record.contract_address} because it is missing functions and so \probably not a vault`
            );
            return;
          }

          vaultRecords.push({
            vault_address: record.contract_address,
            vault_symbol: vaultData.vaultSymbol,
            vault_name: vaultData.vaultName,
            asset_address: vaultData.assetAddress,
            asset_symbol: vaultData.assetSymbol,
            asset_name: vaultData.assetName,
            total_aum_usd_m: 0,
            event_count: record.event_count,
          });
          console.log(`Processed ${record.contract_address}`);
        } catch (error) {
          console.error(
            `Skipping ${record.contract_address} because of error: ${error}`
          );
        }
      })
      .on("end", () => {
        const outputCsv = stringify(vaultRecords, {
          header: true,
        });

        writeStringToFile(outputCsv, "./src/data/vaults.csv");
        resolve();
      })
      .on("error", (error) => {
        console.error("Error reading the CSV file:", error);
        reject(error);
      });
  });
}

async function main() {
  try {
    await processCsv();
  } catch (error) {
    console.error("Error in main processing:", error);
  }
}

main();
