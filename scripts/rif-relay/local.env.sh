#!/usr/bin/env bash

# Local Anvil account reserved for managed `rif-relay` contract deployment and
# registration. This matches Anvil's default funded Account 0, which is the same
# hot account used by the fast relay flow.
export PK=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
export REGISTER_PRIVATE_KEY="$PK"