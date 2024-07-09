import { getDuneQueryResults } from "./utils/getDuneQueryResults";
import { config } from "dotenv";
config();

const DUNE_QUERY_PRICES = 3904744;

async function main() {
  const apiKey = process.env.DUNE_API_KEY;
  if (!apiKey) {
    throw new Error("DUNE_API_KEY is not set in the environment variables.");
  }
  try {
    await getDuneQueryResults(apiKey, DUNE_QUERY_PRICES, "myfile.txt");
  } catch (error) {
    console.error("Error in main processing:", error);
  }
}

main();
