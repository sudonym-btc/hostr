#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/../app"

# Run through Flutter so the generator can evaluate the app's real ThemeData.
flutter test tool/generate_map_styles_test.dart
