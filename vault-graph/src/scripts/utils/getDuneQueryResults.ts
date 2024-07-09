import { DuneClient, RunQueryArgs } from "@duneanalytics/client-sdk";

export async function getDuneQueryResults(
  apiKey: string,
  queryId: number,
  targetFile: string
): Promise<void> {
  const dune = new DuneClient(apiKey);
  try {
    const runQueryArgs: RunQueryArgs = {
      queryId: queryId,
      opts: {
        batchSize: 1000,
        pingFrequency: 10,
        maxAgeHours: 1,
      },
    };
    await dune.downloadCSV(runQueryArgs, targetFile);    
  } catch (error) {
    console.error("Error downloading or saving file:", error);
    throw error;
  }
}