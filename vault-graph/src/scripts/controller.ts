import { s10_getDuneQueryDataAll } from "./s10_getDuneQueryDataAll";
import { s20_getVaultDataAll } from "./s20_getVaultDataAll";
import { s30_buildGraphML } from "./s30_buildGraphML";

const mode = process.env.MODE || "sample";
if (mode !== "sample" && mode !== "full") {
  console.error('Please specify the mode: "sample" or "full"');
  process.exit(1);
}

const fileMappings = {
  sample: {
    addresses: "./src/data/in/addresses-sample.csv",
    vaults: "./src/data/process/vaults-sample.csv",
    output: "./src/data/out/output-sample.graphml",
    prices: "./src/data/reference/asset-prices.csv",
  },
  full: {
    addresses: "./src/data/in/addresses.csv",
    vaults: "./src/data/process/vaults.csv",
    output: "./src/data/out/output.graphml",
    prices: "./src/data/reference/asset-prices.csv",
  },
};

const files = fileMappings[mode];

async function main() {
  console.log(`Running in ${mode} mode...`);

  try {
    await s10_getDuneQueryDataAll(mode, files.addresses, files.prices);
    await s20_getVaultDataAll(files.addresses, files.vaults, files.prices);
    await s30_buildGraphML(files.vaults, files.output);
    console.log("All steps completed.");
  } catch (error) {
    console.error("Error running the pipeline:", error);
    process.exit(1);
  }
}

main();
