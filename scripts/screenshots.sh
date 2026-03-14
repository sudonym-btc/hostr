#!/usr/bin/env bash
set -euo pipefail

# ─── Hostr Screenshot Generator ─────────────────────────────────────────────
#
# Generates deterministic screenshots for every configured device.
# Data is seeded via SeedFactory into in-memory TestRequests — no relay,
# chain, or Docker needed.
#
# Usage:
#   ./scripts/screenshots.sh                   # all configured devices
#   DEVICES="iPhone 17 Pro Max" ./scripts/screenshots.sh  # override
#   CHROME_SCREENSHOTS=0 ./scripts/screenshots.sh          # skip Chrome
#   CHROME_WINDOW_SIZE=1600,1200 ./scripts/screenshots.sh  # resize Chrome
#   RECORD_VIDEO=1 ./scripts/screenshots.sh    # also record screen video
#
# Output:  app/screenshots/<device_slug>/light/*.png
#          app/screenshots/<device_slug>/dark/*.png
#          app/screenshots/<device_slug>/recording.mp4  (when RECORD_VIDEO=1)
# ─────────────────────────────────────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$REPO_ROOT/app"
RECORD_VIDEO="${RECORD_VIDEO:-0}"
CHROME_SCREENSHOTS="${CHROME_SCREENSHOTS:-1}"
CHROME_WINDOW_SIZE="${CHROME_WINDOW_SIZE:-1440,1024}"

# ── Device list (override with DEVICES env var) ─────────────────────────────
# Each entry must match an available `xcrun simctl list devices` name.
# Add more entries for additional App Store screenshot sizes:
#   "iPhone 17 Pro Max"    → 6.9″ (required)
#   "iPhone 17 Pro"        → 6.3″
#   "iPhone 16e"           → 4.7″
#   "iPad Pro 13-inch (M4)"→ 13″
if [[ -z "${DEVICES:-}" ]]; then
  DEVICES=(
    "iPhone 17 Pro Max"
  )
else
  # Allow DEVICES="A,B" override
  IFS=',' read -ra DEVICES <<< "$DEVICES"
fi

# ── Helpers ─────────────────────────────────────────────────────────────────

sanitize() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

# Resolve a device name → UDID of an available iOS simulator.
resolve_simulator() {
  local name="$1"
  xcrun simctl list devices available -j 2>/dev/null \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devs in data.get('devices', {}).items():
    if 'iOS' not in runtime:
        continue
    for d in devs:
        if d['name'] == '$name' and d['isAvailable']:
            print(d['udid'])
            sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

# Boot a simulator if it isn't already running.
ensure_booted() {
  local udid="$1"
  local state
  state=$(xcrun simctl list devices -j 2>/dev/null \
    | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devs in data.get('devices', {}).items():
    for d in devs:
        if d['udid'] == '$udid':
            print(d['state'])
            sys.exit(0)
" 2>/dev/null || echo "Unknown")

  if [[ "$state" != "Booted" ]]; then
    echo "   ⏳ Booting simulator…"
    xcrun simctl boot "$udid" 2>/dev/null || true
    # Wait for the runtime to finish launching.
    sleep 5
  fi
}

# Pre-grant every permission the app may trigger so no dialogs appear.
# Safe to call repeatedly — already-granted permissions are a no-op.
grant_permissions() {
  local udid="$1"
  local bundle_id="com.sudonym.hostr"

  echo "   🔓 Pre-granting permissions…"
  for service in notifications camera photos photos-add location location-always microphone; do
    xcrun simctl privacy "$udid" grant "$service" "$bundle_id" 2>/dev/null || true
  done
}

# Start recording the simulator screen (background process).
# Sets VIDEO_PID for stop_recording to use.
VIDEO_PID=""
start_recording() {
  local udid="$1"
  local output_path="$2"
  mkdir -p "$(dirname "$output_path")"
  echo "   🎬 Recording → $output_path"
  xcrun simctl io "$udid" recordVideo --codec h264 --force "$output_path" &
  VIDEO_PID=$!
}

# Stop a running recording gracefully (SIGINT lets simctl finalise the file).
stop_recording() {
  if [[ -n "$VIDEO_PID" ]] && kill -0 "$VIDEO_PID" 2>/dev/null; then
    kill -INT "$VIDEO_PID" 2>/dev/null || true
    wait "$VIDEO_PID" 2>/dev/null || true
    echo "   🎬 Recording saved"
    VIDEO_PID=""
  fi
}

sync_landing_page_screenshots() {
  local slug="$1"
  local source_dir="$APP_DIR/screenshots/$slug/dark"
  local dest_dir="$REPO_ROOT/landing-page/assets/screenshot"

  if [[ ! -d "$source_dir" ]]; then
    echo "   ⚠️  No dark-mode screenshots found at $source_dir"
    return 1
  fi

  mkdir -p "$dest_dir"

  if ! find "$source_dir" -maxdepth 1 -name '*.png' | grep -q .; then
    echo "   ⚠️  No PNG screenshots found at $source_dir"
    return 1
  fi

  cp "$source_dir"/*.png "$dest_dir"/
  echo "   🖼️  Synced dark screenshots to landing-page/assets/screenshot/"
}

run_chrome_screenshots() {
  local slug="chrome"

  echo "🌐 Chrome → screenshots/$slug/"
  echo "   Window size: $CHROME_WINDOW_SIZE"
  echo "   🏃 Running screenshot suite…"

  if SCREENSHOT_DEVICE="$slug" flutter drive \
    --driver=test_driver/screenshot_test.dart \
    --target=integration_test/screenshots.dart \
    --dart-define-from-file="$REPO_ROOT/.env.local" \
    -d chrome \
    --web-browser-flag="--window-size=$CHROME_WINDOW_SIZE" \
    --no-pub 2>&1 | sed 's/^/   /'; then
    echo "   ✅ Done"
  else
    echo "   ❌ Flutter drive failed for Chrome"
    FAILED+=("Chrome")
  fi

  echo ""
}

# ── Main ────────────────────────────────────────────────────────────────────

echo ""
echo "📸 Hostr Screenshot Generator"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

cd "$APP_DIR"

"$REPO_ROOT/scripts/sync-contract-env.sh" local

set -a
source "$REPO_ROOT/.env"
source "$REPO_ROOT/.env.local"
set +a

if [[ -z "$ESCROW_CONTRACT_ADDRESS" ]]; then
  echo "❌ Could not resolve escrow contract address."
  echo "   Set ESCROW_CONTRACT_ADDRESS in .env.local or re-run scripts/sync-contract-env.sh local."
  exit 1
fi
echo "📝 Contract address: $ESCROW_CONTRACT_ADDRESS"
echo ""

FAILED=()

for device_name in "${DEVICES[@]}"; do
  slug=$(sanitize "$device_name")
  echo "📱 $device_name → screenshots/$slug/"

  # Resolve simulator
  udid=$(resolve_simulator "$device_name") || {
    echo "   ❌ No available simulator matching '$device_name'."
    echo "   Available iOS simulators:"
    xcrun simctl list devices available | grep -i "iphone\|ipad" | head -10
    FAILED+=("$device_name")
    continue
  }
  echo "   UDID: $udid"

  # Boot if needed
  ensure_booted "$udid"

  # Grant permissions so no system dialogs block the test
  grant_permissions "$udid"

  # Start video recording if requested
  if [[ "$RECORD_VIDEO" == "1" ]]; then
    start_recording "$udid" "screenshots/$slug/recording.mp4"
  fi

  # Run the integration test via flutter drive.
  # The test_driver reads SCREENSHOT_DEVICE to route output into the right
  # subdirectory (screenshots/<slug>/*.png).
  echo "   🏃 Running screenshot suite…"
    if SCREENSHOT_DEVICE="$slug" flutter drive \
      --driver=test_driver/screenshot_test.dart \
      --target=integration_test/screenshots.dart \
      --dart-define-from-file="$REPO_ROOT/.env.local" \
      -d "$udid" \
      --no-pub 2>&1 | sed 's/^/   /'; then
    echo "   ✅ Done"
    if [[ "$device_name" == iPhone* ]]; then
      if ! sync_landing_page_screenshots "$slug"; then
        echo "   ❌ Failed to sync screenshots into landing-page assets"
        FAILED+=("$device_name (landing-page sync)")
      fi
    fi
  else
    echo "   ❌ Flutter drive failed for $device_name"
    FAILED+=("$device_name")
  fi

  # Stop video recording
  if [[ "$RECORD_VIDEO" == "1" ]]; then
    stop_recording
  fi
  echo ""
done

if [[ "$CHROME_SCREENSHOTS" == "1" ]]; then
  run_chrome_screenshots
fi

# ── Summary ─────────────────────────────────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "⚠️  Some devices failed: ${FAILED[*]}"
else
  echo "✅ All screenshots generated!"
fi

# Clean simulator build artifacts so the next device build starts fresh.
# Without this, cached simulator-signed frameworks (e.g. objective_c.framework)
# cause "invalid signature" errors when deploying to a physical device.
# echo "🧹 Cleaning simulator build cache…"
# (cd "$APP_DIR" && flutter clean --suppress-analytics >/dev/null 2>&1) || true

echo ""
echo "Output:"
for device_name in "${DEVICES[@]}"; do
  slug=$(sanitize "$device_name")
  dir="screenshots/$slug"
  if [[ -d "$dir" ]]; then
    count=$(find "$dir" -name '*.png' 2>/dev/null | wc -l | tr -d ' ')
    echo "  📁 app/$dir/ ($count screenshots)"
    for mode in light dark; do
      if [[ -d "$dir/$mode" ]]; then
        mode_count=$(find "$dir/$mode" -name '*.png' 2>/dev/null | wc -l | tr -d ' ')
        echo "     $mode/ ($mode_count)"
        find "$dir/$mode" -name '*.png' -exec basename {} \; 2>/dev/null | sort | sed 's/^/       /'
      fi
    done
    if [[ -f "$dir/recording.mp4" ]]; then
      size=$(du -h "$dir/recording.mp4" | cut -f1 | tr -d ' ')
      echo "  🎬 app/$dir/recording.mp4 ($size)"
    fi
  fi
done

if [[ "$CHROME_SCREENSHOTS" == "1" ]]; then
  dir="screenshots/chrome"
  if [[ -d "$dir" ]]; then
    count=$(find "$dir" -name '*.png' 2>/dev/null | wc -l | tr -d ' ')
    echo "  📁 app/$dir/ ($count screenshots)"
    for mode in light dark; do
      if [[ -d "$dir/$mode" ]]; then
        mode_count=$(find "$dir/$mode" -name '*.png' 2>/dev/null | wc -l | tr -d ' ')
        echo "     $mode/ ($mode_count)"
        find "$dir/$mode" -name '*.png' -exec basename {} \; 2>/dev/null | sort | sed 's/^/       /'
      fi
    done
  fi
fi
echo ""
