#!/bin/bash

# Usage:
# ./createAuction.sh --quoteToken <address> --baseToken <address> --callback <address> --poolPercent <uint24> --maxSlippage <uint24> --poolFee <uint24> --envFile <.env> --broadcast <false>
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

# Check that the poolPercent is defined and is a uint24
if [[ ! "$poolPercent" =~ ^[0-9]+$ ]]; then
  echo "Invalid poolPercent specified. Provide a uint24 value after the --poolPercent flag."
  exit 1
fi

# Check that the maxSlippage is defined and is a uint24
if [[ ! "$maxSlippage" =~ ^[0-9]+$ ]]; then
  echo "Invalid maxSlippage specified. Provide a uint24 value after the --maxSlippage flag."
  exit 1
fi

# If the pool fee is not set, set it to 0
if [ -z "$poolFee" ]; then
  poolFee=0
fi

echo "Using chain: $CHAIN"
echo "Using RPC at URL: $RPC_URL"
echo "Deployer: $DEPLOYER_ADDRESS"
echo "Using quote token: $quoteToken"
echo "Using base token: $baseToken"
echo "Using callback: $callback"
echo "Using pool percent: $poolPercent"
echo "Using max slippage: $maxSlippage"
echo "Using pool fee (Uniswap V3 only): $poolFee"

# Set BROADCAST_FLAG based on BROADCAST
BROADCAST_FLAG=""
if [ "$BROADCAST" = "true" ] || [ "$BROADCAST" = "TRUE" ]; then
  BROADCAST_FLAG="--broadcast"
  echo "Broadcast: enabled"
else
  echo "Broadcast: disabled"
fi

# Create auction
forge script ./script/test/FixedPriceBatch-BaseDTL/TestData.s.sol:TestData --sig "createAuction(string,address,address,address,uint24,uint24,uint24)()" $CHAIN $quoteToken $baseToken $callback $poolPercent $maxSlippage $poolFee \
  --rpc-url $RPC_URL --private-key $DEPLOYER_PRIVATE_KEY --froms $DEPLOYER_ADDRESS --slow -vvvv \
  $BROADCAST_FLAG
