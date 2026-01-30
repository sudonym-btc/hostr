#!/bin/bash

# Seed the relay with mock data
seed_relay() {
    local contract_addr="${1:-}"
    local relay_url="${2:-ws://relay.hostr.development}"
    
    echo "Seeding relay at $relay_url with contract address: $contract_addr"
    (cd models && dart run lib/stubs/seed.dart "$relay_url" "$contract_addr")
}

# If script is run directly (not sourced), execute the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    seed_relay "$@"
fi
