import { expect } from "chai";
import fs from "fs";
import { s30_buildGraphML } from "../src/scripts/s30_buildGraphML";
import dotenv from "dotenv";
import "mocha";

dotenv.config();

describe("buildGraphML", () => {
  const testVaultsFile = "./test/data/vaults-test.csv";
  const outputGraphMLFile = "./test/data/output-test.graphml";

  before(() => {
    // Prepare a sample CSV file for testing
    const csvData = `vault_address,vault_symbol,vault_name,asset_address,asset_symbol,asset_name,total_aum_usd_m,event_count
    0xVault1,VLT1,Vault One,0xAsset1,AST1,Asset One,100,10
    0xVault2,VLT2,Vault Two,0xAsset2,AST2,Asset Two,200,20`;

    fs.writeFileSync(testVaultsFile, csvData);
  });

  after(() => {
    // Clean up the test files
    if (fs.existsSync(testVaultsFile)) fs.unlinkSync(testVaultsFile);
    if (fs.existsSync(outputGraphMLFile)) fs.unlinkSync(outputGraphMLFile);
  });

  it("should create a GraphML file from CSV data", async () => {
    await s30_buildGraphML(testVaultsFile, outputGraphMLFile);

    expect(fs.existsSync(outputGraphMLFile)).to.be.true;

    const graphMLContent = fs.readFileSync(outputGraphMLFile, "utf8");
    expect(graphMLContent).to.include("<graphml");
    expect(graphMLContent).to.include("Vault One");
    expect(graphMLContent).to.include("Vault Two");
    expect(graphMLContent).to.include("Asset One");
    expect(graphMLContent).to.include("Asset Two");
  });
});
