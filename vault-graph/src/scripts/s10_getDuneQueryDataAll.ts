import { getDuneQueryResults } from "./utils/getDuneQueryResults";
import { config } from "dotenv";
config();

export async function s10_getDuneQueryDataAll(
  mode: string,
  addressesFile: string,
  pricesFile: string
) {
  const DUNE_QUERY_PRICES = 3907436;
  const DUNE_QUERY_VAULTS = 3901350;

  const apiKey = process.env.DUNE_API_KEY;
  if (!apiKey) {
    throw new Error("DUNE_API_KEY is not set in the environment variables.");
  }
  try {
    console.log("Fetching data from Dune Analytics...");
    await getDuneQueryResults(apiKey, DUNE_QUERY_PRICES, pricesFile);
    // If we're in sample mode, don't want to rebuild the addresses file, it already contains subset of vaults
    if (mode !== "sample") {
      await getDuneQueryResults(apiKey, DUNE_QUERY_VAULTS, addressesFile);
    }
    console.log("Done.");
  } catch (error) {
    console.error("Error in main processing:", error);
    throw error;
  }
}
