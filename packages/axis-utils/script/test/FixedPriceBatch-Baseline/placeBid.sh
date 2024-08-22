#!/bin/bash

# Usage:
# ./placeBid.sh --lotId <uint96> --amount <uint256> --allocatedAmount <uint256> --merkleProofFile <path> --envFile <.env>
#
# Expects the following environment variables:
# CHAIN: The chain to deploy to, based on values from the ./script/env.json file.

# Iterate through named arguments
# Source: https://unix.stackexchange.com/a/388038
while [ $# -gt 0 ]; do
  if [[ $1 == *"--"* ]]; then
    v="${1/--/}"
    declare $v="$2"
  fi

  shift
done

# If DEBUG is set, print the commands
if [ ! -z "$DEBUG" ]; then
  set -x
fi

# Get the name of the .env file or use the default
ENV_FILE=${envFile:-".env"}
echo "Sourcing environment variables from $ENV_FILE"

# Load environment file
set -a  # Automatically export all variables
source $ENV_FILE
set +a  # Disable automatic export

# Apply defaults to command-line arguments
BROADCAST=${broadcast:-false}

# Check that the CHAIN is defined
if [ -z "$CHAIN" ]
then
  echo "No chain specified. Set the CHAIN environment variable."
  exit 1
fi

# Check that the lotId is defined and is an integer
if [[ ! "$lotId" =~ ^[0-9]+$ ]]
then
  echo "Invalid lotId specified. Provide the integer value after the --lotId flag."
  exit 1
fi

# Check that the amount is defined and is an integer
if [[ ! "$amount" =~ ^[0-9]+$ ]]
then
  echo "Invalid amount specified. Provide the integer value after the --amount flag."
  exit 1
fi

# Check that the allocated amount is defined and is an integer
if [[ ! "$allocatedAmount" =~ ^[0-9]+$ ]]
then
  echo "Invalid allocated amount specified. Provide the integer value after the --allocatedAmount flag."
  exit 1
fi

# Check that the merkle proof file is defined and exists
if [ ! -f "$merkleProofFile" ]
then
  echo "Invalid merkle proof file path specified. Provide the path after the --merkleProofFile flag."
  exit 1
fi

# Read the merkle proofs from the file using the deployer address and allocated amount
# Expected format:
# {
#   root: string;
#   entries: {
#     value: string[];
#     proofs: string[];
#   }[];
# }
merkleProofs=$(jq -r --arg deployer "$DEPLOYER_ADDRESS" --arg allocatedAmount "$allocatedAmount" '.entries[] | select(.value[0] == $deployer and .value[1] == $allocatedAmount) | .proofs' $merkleProofFile)
# Strip spacing, newlines, single quotes, double quotes
merkleProofs=$(echo $merkleProofs | tr -d '[:space:]' | tr -d "'" | tr -d '"')

# Check that the merkle proof was found
if [ -z "$merkleProofs" ]
then
  echo "No merkle proof found for the deployer address $DEPLOYER_ADDRESS and allocated amount $allocatedAmount in the merkle proof file at $merkleProofFile"
  exit 1
fi

# Check that the merkle proof is defined and is an array of bytes32 strings
# Expected format: [0x...,0x...,...]
if [[ ! "$merkleProofs" =~ ^\[0x[a-fA-F0-9]{64}(,0x[a-fA-F0-9]{64})*\]$ ]]
then
  echo "Invalid merkle proofs in the merkle proof file at $merkleProofFile"
  echo "The merkle proofs should be located at the top-level key 'entries' and contain an array of objects with the keys 'value' and 'proofs'."
  echo "Actual value: $merkleProofs"
  exit 1
fi

echo "Using chain: $CHAIN"
echo "Using RPC at URL: $RPC_URL"
echo "Deployer: $DEPLOYER_ADDRESS"
echo "Lot ID: $lotId"
echo "Amount: $amount"
echo "Allocated amount: $allocatedAmount"
echo "Allowlist merkle proof file: $merkleProofFile"
echo "Allowlist merkle proofs: $merkleProofs"

# Set BROADCAST_FLAG based on BROADCAST
BROADCAST_FLAG=""
if [ "$BROADCAST" = "true" ] || [ "$BROADCAST" = "TRUE" ]; then
  BROADCAST_FLAG="--broadcast"
  echo "Broadcast: enabled"
else
  echo "Broadcast: disabled"
fi

# Create auction
forge script ./script/test/FixedPriceBatch-Baseline/TestData.s.sol:TestData --sig "placeBid(string,uint96,uint256,bytes32[],uint256)()" $CHAIN $lotId $amount $merkleProofs $allocatedAmount \
--rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --froms $DEPLOYER_ADDRESS --slow -vvvv \
$BROADCAST_FLAG
