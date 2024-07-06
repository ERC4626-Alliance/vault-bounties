import { ethers } from "ethers";
import { config } from "dotenv";
config();

// check can get latest block
async function main() {
  const provider = new ethers.JsonRpcProvider(
    process.env.JSON_RPC_PROVIDER_URL
  );

  console.log(process.env.JSON_RPC_PROVIDER_URL);

  const blockNumber = await provider.getBlockNumber();
  console.log("Latest block number:", blockNumber);
}

main().catch((error) => {
  console.error("Error:", error);
  process.exit(1);
});
