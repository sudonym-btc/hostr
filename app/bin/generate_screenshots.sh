#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

DEVICE_ID=${DEVICE_ID:-macos}
mkdir -p screenshots

echo "Running integration screenshot suite on device: ${DEVICE_ID}"
flutter test integration_test/screenshot.dart -d "${DEVICE_ID}" "$@"
