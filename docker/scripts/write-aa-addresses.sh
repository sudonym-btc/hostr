#!/bin/sh
# Wrapper for ghcr.io/pimlicolabs/mock-contract-deployer
# Runs the upstream deployer then writes the deterministic AA contract addresses
# to the mounted output file so sync-contract-env.sh can pick them up.
set -e

cd /app

echo "==> Deploying AA contracts..."
pnpm run start

echo "==> Writing AA contract addresses to /output/contract-addresses.json..."
cat > /output/contract-addresses.json << 'JSON'
{
  "regtest.412346": {
    "EntryPoint": "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
    "SimpleAccountFactory": "0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985",
    "VerifyingPaymaster": "0x38aef040CEB057B62E1598F5C265946A4E4BaB4C"
  },
  "mainnet.42161": {
    "EntryPoint": "0x0000000071727De22E5E9d8BAf0edAc6f37da032",
    "SimpleAccountFactory": "0x91E60e0613810449d098b0b5Ec8b51A0FE8c8985",
    "VerifyingPaymaster": ""
  }
}
JSON
echo "==> Done. AA contract addresses written."
