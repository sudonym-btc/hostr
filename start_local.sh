#!/bin/bash
source ./wait_for_healthy.sh

rm -rf ./docker/data &&
    docker-compose up -d && 
    wait_for_healthy && 
    ./setup_local.sh && 
    (cd models && dart run lib/stubs/seed.dart ws://relay.hostr.development) &&
    
        # Deploy Hardhat contracts and capture the output.
        # We use Hardhat Ignition as shown in [escrow/contracts/README.md](escrow/contracts/README.md)
        cd escrow/contracts
        DEPLOY_OUTPUT=$(npx hardhat ignition deploy ./ignition/modules/Escrow.ts --network localhost)
        echo "$DEPLOY_OUTPUT"
        # Extract the contract address (assumes the output contains a 0x-prefixed address)
        CONTRACT_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[a-fA-F0-9]{40}')
        echo "Deployed Escrow contract at address: $CONTRACT_ADDR"
        export CONTRACT_ADDR 
        cd ../..

    echo $CONTRACT_ADDR &&
    (cd escrow && dart run lib/cli.dart start) &&
    CONTRACT_ADDR=$CONTRACT_ADDR docker-compose up -d escrow 
