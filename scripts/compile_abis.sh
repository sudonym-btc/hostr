#!/usr/bin/env bash
# NMDK owns contract/OpenAPI inputs and both language bindings.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root/dependencies/nmdk"
node scripts/generate-driver-bindings.mjs --dart
