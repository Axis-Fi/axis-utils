# FixedPriceBatch - Baseline Allocated Allowlist Testing

## How to Test

1. Create a virtual testnet on Tenderly
2. Store the environment variables in an environment file
3. Deploy the Axis stack
4. Deploy the Baseline v2 stack
   - Record the kernel and reserve token addresses
5. Generate salts for the BaselineAllocatedAllowlist
   - You will need to provide the kernel, owner, and reserveToken
6. Deploy the BaselineAllocatedAllowlist callback contract
   - You will need to provide the kernel, owner, and reserveToken
7. Generate the Merkle root
   - Use the oz-merkle-tree tool for this
8. Create the auction
   - You will need to provide parameters for the auction
   - The `packages/oz-merkle-tree/out/<csv filename>-proofs.json` file should be provided as the input for the `--merkleProofFile` parameter.

## To Settle an Auction

Assumes you are using a Tenderly Virtual Testnet

1. Warp to the timestamp after the auction conclusion using the warp script
2. Run the settle auction script
