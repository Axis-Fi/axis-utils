import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

// 0x4 and 0x5
const values = [
  ["0x0000000000000000000000000000000000000004"],
  ["0x0000000000000000000000000000000000000005"],
];

const tree = StandardMerkleTree.of(values, ["address"]);

console.log(`Merkle root: ${tree.root}`);

console.log("Proofs");

for (const [i, v] of tree.entries()) {
  const proof = tree.getProof(i);
  console.log('Value:', v);
  console.log('Proof:', proof);
}

Bun.write("out/merkle-tree.json", JSON.stringify(tree.dump(), null, 2));
