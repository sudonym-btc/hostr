#!/usr/bin/env bash
set -euo pipefail

export RIF_RELAY_WORKDIR="${RIF_RELAY_WORKDIR:-/tmp/rif-relay-register}"
mkdir -p "$RIF_RELAY_WORKDIR"
rm -f "$RIF_RELAY_WORKDIR/txstore.db"

/write_local_config.sh

cd /rif-relay-server
exec npm run register