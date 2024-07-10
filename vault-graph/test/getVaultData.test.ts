import { expect } from "chai";
import dotenv from "dotenv";
import "mocha";
import { getVaultData } from "../src/scripts/utils/getVaultData";

dotenv.config();

describe("getVaultData", () => {
  it("should retrieve vault data for a valid vault address", async () => {
    const vaultAddress = "0xd9a442856c234a39a81a089c06451ebaa4306a72";
    const data = await getVaultData(vaultAddress);

    expect(data.vaultSymbol).to.not.equal("error");
    expect(data.vaultName).to.not.equal("error");
    expect(data.assetAddress).to.not.equal("0x0");
    expect(data.assetSymbol).to.not.equal("error");
    expect(data.assetName).to.not.equal("error");
    expect(data.assetDecimals).to.be.a("bigint").that.is.greaterThan(0);
    expect(data.totalAssetsBaseUnits).to.be.a("bigint").that.is.greaterThan(0);
  });

  it("should return error data for an invalid vault address", async () => {
    const vaultAddress = "0xInvalidVaultAddress";
    const data = await getVaultData(vaultAddress);

    expect(data.vaultSymbol).to.equal("error");
    expect(data.vaultName).to.equal("error");
    expect(data.assetAddress).to.equal("0x0");
    expect(data.assetSymbol).to.equal("error");
    expect(data.assetName).to.equal("error");
    expect(data.assetDecimals).to.equal(0n);
    expect(data.totalAssetsBaseUnits).to.equal(0n);
  });
});
