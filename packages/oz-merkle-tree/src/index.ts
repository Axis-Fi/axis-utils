import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

// TODOs
// - Specify the types of the values
// - Pass in the values from the CLI or file

const generateMerkleTree = (name: string, values: any[][], types: string[]) => {
  const tree = StandardMerkleTree.of(values, types);

  console.log(name);

  console.log(`Merkle root: ${tree.root}`);

  console.log("Proofs");

  for (const [i, v] of tree.entries()) {
    const proof = tree.getProof(i);
    console.log("Value:", v);
    console.log("Proof:", proof);
  }

  Bun.write(`out/${name}.json`, JSON.stringify(tree.dump(), null, 2));

  console.log("");
};

const addressValues = [
  ["0x0000000000000000000000000000000000000004"],
  ["0x0000000000000000000000000000000000000005"],
];

const allocatedAddressValues = [
  ["0x0000000000000000000000000000000000000004", "5000000000000000000"],
  ["0x0000000000000000000000000000000000000020", "0"],
];

generateMerkleTree("address", addressValues, ["address"]);
generateMerkleTree("allocated-address", allocatedAddressValues, [
  "address",
  "uint256",
]);
