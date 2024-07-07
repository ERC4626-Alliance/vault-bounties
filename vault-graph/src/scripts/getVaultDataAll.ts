import { config } from "dotenv";
import { createReadStream, writeFileSync } from "fs";
import csvParser from "csv-parser";
import { getVaultData } from "./getVaultData";
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

async function processRecords(
  records: AddressRecord[]
): Promise<VaultRecord[]> {
  const vaultRecords: VaultRecord[] = [];

  for (const record of records) {
    try {
      const vaultData = await getVaultData(record.contract_address);

      if (
        vaultData.vaultName === "error" ||
        vaultData.vaultSymbol === "error" ||
        vaultData.assetAddress === "0x0"
      ) {
        console.error(
          `Skipping ${record.contract_address} because it is missing functions`
        );
        continue;
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
    const inputFilePath = "./src/data/in/addresses-6m.csv";
    const outputFilePath = "./src/data/process/vaults-6m.csv";

    const addressRecords = await readCsv(inputFilePath);
    const vaultRecords = await processRecords(addressRecords);

    writeCsv(outputFilePath, vaultRecords);
    console.log(`File written to ${outputFilePath}`);
  } catch (error) {
    console.error("Error in main processing:", error);
  }
}

main();
