import fs from "fs";
import csv from "csv-parser";
import { writeStringToFile } from "./utils/utils";

interface VaultAssetData {
  vault_address: string;
  vault_symbol: string;
  vault_name: string;
  asset_address: string;
  asset_symbol: string;
  asset_name: string;
  total_aum_usd_m: number;
  event_count: number;
}

interface GraphNode {
  id: string;
  type: "vault" | "asset" | "mixed";
  address: string;
  name: string;
  symbol: string;
  totalAumUsdMillion: number;
  eventCount: number;
}

interface GraphEdge {
  source: string;
  target: string;
}

function readCSVFile(filePath: string): Promise<VaultAssetData[]> {
  return new Promise((resolve, reject) => {
    const results: VaultAssetData[] = [];
    fs.createReadStream(filePath)
      .pipe(csv())
      .on("data", (data) => results.push(data))
      .on("end", () => resolve(results))
      .on("error", (error) => reject(error));
  });
}

function prepareGraphML(nodes: GraphNode[], edges: GraphEdge[]): string {
  let graphML = `<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns"  
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns 
     http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
  <key id="type" for="node" attr.name="type" attr.type="string"/>
  <key id="address" for="node" attr.name="address" attr.type="string"/>
  <key id="name" for="node" attr.name="name" attr.type="string"/>
  <key id="symbol" for="node" attr.name="symbol" attr.type="string"/>
  <key id="totalAumUsdMillion" for="node" attr.name="totalAumUsdMillion" attr.type="double"/>
  <key id="eventCount" for="node" attr.name="eventCount" attr.type="double"/>
  <graph id="G" edgedefault="undirected">
`;

  nodes.forEach((node) => {
    graphML += `    <node id="${node.id}">
      <data key="type">${node.type}</data>
      <data key="address">${node.address}</data>
      <data key="name">${node.name}</data>
      <data key="symbol">${node.symbol}</data>
      <data key="totalAumUsdMillion">${node.totalAumUsdMillion}</data>
      <data key="eventCount">${node.eventCount}</data>
    </node>\n`;
  });

  edges.forEach((edge) => {
    graphML += `    <edge source="${edge.source}" target="${edge.target}"/>\n`;
  });

  graphML += "  </graph>\n</graphml>";

  return graphML;
}

function processCSVData(data: VaultAssetData[]): {
  nodes: GraphNode[];
  edges: GraphEdge[];
} {
  const nodesMap = new Map<string, GraphNode>();
  const edges: GraphEdge[] = [];

  data.forEach((row) => {
    // Process vault nodes
    if (!nodesMap.has(row.vault_address)) {
      nodesMap.set(row.vault_address, {
        id: row.vault_address,
        type: "vault",
        address: row.vault_address,
        name: row.vault_name,
        symbol: row.vault_symbol,
        totalAumUsdMillion: row.total_aum_usd_m,
        eventCount: row.event_count,
      });
    }

    // Process asset nodes
    if (nodesMap.has(row.asset_address)) {
      const existingNode = nodesMap.get(row.asset_address)!;
      if (existingNode.type === "vault") {
        existingNode.type = "mixed";
      }
    } else {
      nodesMap.set(row.asset_address, {
        id: row.asset_address,
        type: "asset",
        address: row.asset_address,
        name: row.asset_name,
        symbol: row.asset_symbol,
        totalAumUsdMillion: 0,
        eventCount: 0,
      });
    }

    // Add edges
    edges.push({
      source: row.vault_address,
      target: row.asset_address,
    });
  });

  return { nodes: Array.from(nodesMap.values()), edges };
}

async function main() {
  try {
    const csvData = await readCSVFile("./src/data/vaults-sample.csv");
    const { nodes, edges } = processCSVData(csvData);
    const graphML = prepareGraphML(nodes, edges);
    writeStringToFile(graphML, "./src/data/output.graphml");
  } catch (error) {
    console.error("Error processing CSV data:", error);
  }
}

main();
