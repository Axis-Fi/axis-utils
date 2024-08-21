import fs from "fs";
import csv from "csv-parser";
import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

type Proof = {
  root: string;
  entries: {
    value: string[];
    proofs: string[];
  }[];
};

const generateMerkleTree = (name: string, values: any[][], types: string[]) => {
  const tree = StandardMerkleTree.of(values, types);

  console.log(`Merkle root: ${tree.root}`);

  const proofs: Proof = {
    root: tree.root,
    entries: [],
  };

  for (const [i, v] of tree.entries()) {
    const proof = tree.getProof(i);

    proofs.entries.push({
      value: v as string[],
      proofs: proof,
    });
  }

  Bun.write(`out/${name}-tree.json`, JSON.stringify(tree.dump(), null, 2));
  Bun.write(`out/${name}-proofs.json`, JSON.stringify(proofs, null, 2));

  console.log("");
  console.log(`Merkle tree written to out/${name}-tree.json`);
  console.log(`Proofs written to out/${name}-proofs.json`);
};

const csvFilePath = process.argv[2];

if (!csvFilePath) {
  console.error(
    "Please provide the path to the CSV file as a command-line argument.",
  );
  process.exit(1);
}

let csvHeaders: string[] = [];
let headersValidated = false;
const values: string[][] = [];

// Get the filename from the path, without the file extension
const fileName = csvFilePath.split("/").pop()?.split(".")[0];
if (!fileName) {
  console.error("Could not extract filename from the provided path.");
  process.exit(1);
}

fs.createReadStream(csvFilePath)
  .pipe(csv())
  .on("headers", (headers) => {
    if (
      headers.length < 1 ||
      headers.length > 2 ||
      headers[0] !== "address" ||
      (headers.length === 2 && headers[1] !== "amount")
    ) {
      console.error(
        `CSV headers do not match the expected headers: "address" or "address,amount"`,
      );
      process.exit(1);
    }
    headersValidated = true;
    csvHeaders = headers;
  })
  .on("data", (row) => {
    if (!headersValidated) {
      console.error("Cannot process data without header validation");
      process.exit(1);
    }

    const rowValues =
      csvHeaders.length === 1 ? [row.address] : [row.address, row.amount];
    values.push(rowValues);
  })
  .on("end", () => {
    console.log("CSV file successfully processed");
    const types =
      csvHeaders.length === 1 ? ["address"] : ["address", "uint256"];

    generateMerkleTree(fileName, values, types);
  });
