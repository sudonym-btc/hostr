#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENVIRONMENT="${1:-test}"
load_managed_relay_env "$ENVIRONMENT" "$0"
docker compose ps rif-relay
