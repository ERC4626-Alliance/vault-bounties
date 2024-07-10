import { expect } from "chai";
import fs from "fs";
import path from "path";
import dotenv from "dotenv";
import { getDuneQueryResults } from "../src/scripts/utils/getDuneQueryResults";
import "mocha";

dotenv.config();

describe("getDuneQueryResults", () => {
  const apiKey = process.env.DUNE_API_KEY;
  const queryId = 3904744; // prices subset
  const targetFile = "./test/data/dune-query-results.csv";

  if (!apiKey) {
    console.error("DUNE_API_KEY is not set in the environment variables.");
    process.exit(1);
  }

  after(() => {
    // Clean up the test file if it exists
    if (fs.existsSync(targetFile)) {
      fs.unlinkSync(targetFile);
    }
  });

  it("should download and save the query results to a CSV file", async () => {
    try {
      await getDuneQueryResults(apiKey, queryId, targetFile);
      // Check if the file was created
      const fileExists = fs.existsSync(targetFile);
      expect(fileExists).to.be.true;
    } catch (error) {
      console.error("Error in test:", error);
      throw error;
    }
  });
});
