#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
source "$SCRIPT_DIR/lib/hostr-common.sh"
environment="${1:-}"

hostr_validate_environment "$environment" "$0"
shift
hostr_load_env "$REPO_ROOT" "$environment"

cd "$REPO_ROOT"
hostr_compose_cmd "$environment" "$@"
