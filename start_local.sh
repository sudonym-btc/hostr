#!/bin/bash
source ./wait_for_healthy.sh

# Ensure hosts entry exists for local development
if ! grep -q "127.0.0.1.*relay.hostr.development" /etc/hosts; then
    echo "Adding relay.hostr.development to /etc/hosts..."
    echo "127.0.0.1  relay.hostr.development" | sudo tee -a /etc/hosts > /dev/null
fi

# Install and configure dnsmasq
if ! brew list dnsmasq &>/dev/null; then
    echo "Installing dnsmasq..."
    brew install dnsmasq
    sh docker/certs.sh
fi

DNSMASQ_CONF=$(brew --prefix)/etc/dnsmasq.conf
if [ -f "$DNSMASQ_CONF" ] && ! grep -q "address=/.hostr.development/" "$DNSMASQ_CONF"; then
    echo "Configuring dnsmasq for .hostr.development..."
    echo 'address=/.hostr.development/127.0.0.1' >> "$DNSMASQ_CONF"
    echo 'port=53' >> "$DNSMASQ_CONF"
fi

# Ensure dnsmasq is running
if ! sudo brew services list | grep -q "dnsmasq.*started"; then
    echo "Starting dnsmasq..."
    sudo brew services start dnsmasq
fi

# Setup resolver for .development domains
if [ ! -f /etc/resolver/development ]; then
    echo "Configuring /etc/resolver/development..."
    sudo mkdir -pv /etc/resolver
    sudo bash -c 'echo "nameserver 127.0.0.1" > /etc/resolver/development'
fi

# Create a shared network if it doesn't exist
docker network inspect shared_network >/dev/null 2>&1 || docker network create shared_network

# Ensure data directories exist
mkdir -p ./docker/data/lightning_data ./docker/data/lightning_shared/{1,2} ./docker/data/relay ./docker/data/bitcoin ./docker/data/blossom ./docker/data/lnbits/{1,2} ./docker/data/albyhub &&
    docker-compose up -d && 
    wait_for_healthy && 
    ./setup_local.sh && 
    (cd models && dart run lib/stubs/seed.dart ws://relay.hostr.development) 
    # &&
    # (
    #     # Deploy Hardhat contracts and capture the output.
    #     # We use Hardhat Ignition as shown in [escrow/contracts/README.md](escrow/contracts/README.md)
    #     cd escrow/contracts
    #     DEPLOY_OUTPUT=$(npx hardhat ignition deploy ./ignition/modules/Escrow.ts --network localhost) &&
    #     echo "$DEPLOY_OUTPUT" &&
    #     # Extract the contract address (assumes the output contains a 0x-prefixed address)
    #     CONTRACT_ADDR=$(echo "$DEPLOY_OUTPUT" | grep -oE '0x[a-fA-F0-9]{40}') &&
    #     echo "Deployed Escrow contract at address: $CONTRACT_ADDR" &&
    #     cd ../.. &&
    #     (cd escrow && dart run lib/cli.dart start) &&
    #     CONTRACT_ADDR=$CONTRACT_ADDR docker-compose up -d escrow 
    # )
    
