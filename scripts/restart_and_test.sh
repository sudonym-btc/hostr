
# USED FOR DEBUGGING ONLY, WHEN WE NEED TO JUMP FROM A DOCKER RESTART RIGHT INTO TESTS.  NOT INTENDED FOR NORMAL USE.

# !/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Shadow sudo with a no-op so trust-dev-ca.sh fails instantly without
# prompting for a password.  start.sh already treats that step as non-fatal.
FAKE_SUDO_DIR=$(mktemp -d)
printf '#!/bin/sh\nexit 1\n' > "$FAKE_SUDO_DIR/sudo"
chmod +x "$FAKE_SUDO_DIR/sudo"
export PATH="$FAKE_SUDO_DIR:$PATH"
trap 'rm -rf "$FAKE_SUDO_DIR"' EXIT

echo ">>> Restarting stack..."
bash "$SCRIPT_DIR/restart.sh" test

echo ""
echo ">>> Running integration tests..."
cd "$REPO_ROOT/hostr_sdk"

dart test test/integration \
    --timeout 120s \
    --concurrency=1 \
    --reporter expanded
