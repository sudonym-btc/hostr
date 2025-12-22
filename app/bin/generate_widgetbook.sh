#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
pushd "${SCRIPT_DIR}/../widgetbook_workspace" > /dev/null
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs "$@"
popd > /dev/null
