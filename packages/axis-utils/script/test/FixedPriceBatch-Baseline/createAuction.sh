#!/bin/bash

# Usage:
# ./createAuction.sh --quoteToken <address> --baseToken <address> --callback <address> --merkleProofFile <path> --poolPercent <uint24> --floorReservesPercent <uint24> --floorRangeGap <int24> --anchorTickUpper <int24> --anchorTickWidth <int24> --envFile <.env>
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

# Get the name of the .env file or use the default
ENV_FILE=${envFile:-".env"}
echo "Sourcing environment variables from $ENV_FILE"

# Load environment file
set -a # Automatically export all variables
source $ENV_FILE
set +a # Disable automatic export

# Apply defaults to command-line arguments
BROADCAST=${broadcast:-false}

# Check that the CHAIN is defined
if [ -z "$CHAIN" ]; then
  echo "No chain specified. Set the CHAIN environment variable."
  exit 1
fi

# Check that the quote token is defined and is an address
if [[ ! "$quoteToken" =~ ^0x[0-9a-fA-F]{40}$ ]]; then
  echo "Invalid quote token specified. Provide the address after the --quoteToken flag."
  exit 1
fi

# Check that the base token is defined and is an address
if [[ ! "$baseToken" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
  echo "Invalid base token specified. Provide the address after the --baseToken flag."
  exit 1
fi

# Check that the callback is defined and is an address
if [[ ! "$callback" =~ ^0x[a-fA-F0-9]{40}$ ]]; then
  echo "Invalid callback specified. Provide the address after the --callback flag."
  exit 1
fi

# Check that the path for the allowlist merkle proofs is defined and exists
if [ ! -f "$merkleProofFile" ]; then
  echo "Invalid allowlist merkle proof path specified. Provide the path after the --merkleProofFile flag."
  exit 1
fi

# Attempt to read the merkle root from the allowlist merkle proof
merkleRoot=$(jq -r '.root' $merkleProofFile)

# Check that the allowlist merkle root is defined and is a bytes32 string
if [[ ! "$merkleRoot" =~ ^0x[a-fA-F0-9]{64}$ ]]; then
  echo "Invalid allowlist merkle root in the allowlist merkle proof at $merkleProofFile"
  echo "The merkle root should be located at the top-level key 'root'."
  echo "Actual value: $merkleRoot"
  exit 1
fi

# Check that the poolPercent is defined and is a number
if [[ ! "$poolPercent" =~ ^[0-9]+$ ]]; then
  echo "Invalid pool percent specified. Provide the number after the --poolPercent flag."
  exit 1
fi

# Check that the floorReservesPercent is defined and is a number
if [[ ! "$floorReservesPercent" =~ ^[0-9]+$ ]]; then
  echo "Invalid floor reserves percent specified. Provide the number after the --floorReservesPercent flag."
  exit 1
fi

# Check that the floorRangeGap is defined and is a number
if [[ ! "$floorRangeGap" =~ ^[0-9]+$ ]]; then
  echo "Invalid floor range gap specified. Provide the number after the --floorRangeGap flag."
  exit 1
fi

# Check that the anchorTickUpper is defined and is a number
if [[ ! "$anchorTickUpper" =~ ^[0-9]+$ ]]; then
  echo "Invalid anchor tick upper specified. Provide the number after the --anchorTickUpper flag."
  exit 1
fi

# Check that the anchorTickWidth is defined and is a number
if [[ ! "$anchorTickWidth" =~ ^[0-9]+$ ]]; then
  echo "Invalid anchor tick width specified. Provide the number after the --anchorTickWidth flag."
  exit 1
fi

echo "Using chain: $CHAIN"
echo "Using RPC at URL: $RPC_URL"
echo "Deployer: $DEPLOYER_ADDRESS"
echo "Using quote token: $quoteToken"
echo "Using base token: $baseToken"
echo "Using callback: $callback"
echo "Using allowlist merkle proof file: $merkleProofFile"
echo "Using allowlist merkle root: $merkleRoot"
echo "Using pool percent: $poolPercent"
echo "Using floor reserves percent: $floorReservesPercent"
echo "Using floor range gap: $floorRangeGap"
echo "Using anchor tick upper: $anchorTickUpper"
echo "Using anchor tick width: $anchorTickWidth"

# Set BROADCAST_FLAG based on BROADCAST
BROADCAST_FLAG=""
if [ "$BROADCAST" = "true" ] || [ "$BROADCAST" = "TRUE" ]; then
  BROADCAST_FLAG="--broadcast"
  echo "Broadcast: enabled"
else
  echo "Broadcast: disabled"
fi

# Create auction
forge script ./script/test/FixedPriceBatch-Baseline/TestData.s.sol:TestData --sig "createAuction(string,address,address,address,bytes32,uint24,uint24,int24,int24,int24)()" $CHAIN $quoteToken $baseToken $callback $merkleRoot $poolPercent $floorReservesPercent $floorRangeGap $anchorTickUpper $anchorTickWidth \
  --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --froms $DEPLOYER_ADDRESS --slow -vvvv \
  $BROADCAST_FLAG
