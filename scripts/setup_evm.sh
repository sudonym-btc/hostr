#!/bin/bash

setup_evm() {
    # Deploy Hardhat contracts and capture the output.
    # We use Hardhat Ignition as shown in [escrow/contracts/README.md](escrow/contracts/README.md)
    cd escrow/contracts
    DEPLOY_OUTPUT=$(HARDHAT_IGNITION_CONFIRM_DEPLOYMENT=false npx hardhat ignition deploy ./ignition/modules/Escrow.ts --network localhost)
    echo "$DEPLOY_OUTPUT" >&2
    # Extract the contract address (assumes the output contains a 0x-prefixed address)
    CONTRACT_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[a-fA-F0-9]{40}')
    echo "Deployed Escrow contract at address: $CONTRACT_ADDR" >&2
    cd ../..
    # Return the contract address
    echo "$CONTRACT_ADDR"
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_evm
fi