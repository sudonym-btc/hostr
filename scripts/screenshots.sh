#!/usr/bin/env bash
set -euo pipefail

# ─── Hostr Screenshot Generator ─────────────────────────────────────────────
#
# Generates deterministic screenshots for every configured device.
# Data is seeded into the local relay/chain stack before capture so every
# device sees the same deterministic dataset.
#
# Usage:
#   ./scripts/screenshots.sh                   # all configured devices
#   DEVICES="iPhone 17 Pro Max" ./scripts/screenshots.sh  # override
#   CHROME_SCREENSHOTS=0 ./scripts/screenshots.sh          # skip Chrome
#   CHROME_WINDOW_SIZE=1600,1200 ./scripts/screenshots.sh  # target captured viewport
#   CHROME_DEVICE_SCALE_FACTOR=2 ./scripts/screenshots.sh   # Retina DPR
#   CHROMEDRIVER_PORT=4445 ./scripts/screenshots.sh        # fixed WebDriver port
#   CHROMEDRIVER_AUTO_DOWNLOAD=0 ./scripts/screenshots.sh   # disable local driver cache
#   SCREENSHOT_TRADE_SPONSOR_PRIVATE_KEY=0x... ./scripts/screenshots.sh
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
CHROME_WINDOW_SIZE="${CHROME_WINDOW_SIZE:-}"
CHROME_DEVICE_SCALE_FACTOR="${CHROME_DEVICE_SCALE_FACTOR:-2}"
CHROME_START_FULLSCREEN="${CHROME_START_FULLSCREEN:-1}"
CHROMEDRIVER_AUTOSTART="${CHROMEDRIVER_AUTOSTART:-1}"
CHROMEDRIVER_PORT="${CHROMEDRIVER_PORT:-}"
CHROMEDRIVER_LOG="${CHROMEDRIVER_LOG:-}"
CHROME_FLUTTER_DRIVE_TIMEOUT="${CHROME_FLUTTER_DRIVE_TIMEOUT:-360}"
CHROME_EXPECTED_SCREENSHOTS="${CHROME_EXPECTED_SCREENSHOTS:-16}"
CHROMEDRIVER_ALLOW_VERSION_MISMATCH="${CHROMEDRIVER_ALLOW_VERSION_MISMATCH:-0}"
CHROMEDRIVER_AUTO_DOWNLOAD="${CHROMEDRIVER_AUTO_DOWNLOAD:-1}"
CHROMEDRIVER_CACHE_DIR="${CHROMEDRIVER_CACHE_DIR:-$REPO_ROOT/.cache/chromedriver}"

if [[ -z "${CHROME_FLUTTER_DRIVE_ARGS+x}" ]]; then
  CHROME_FLUTTER_DRIVE_ARGS=(--no-dds)
elif [[ -z "$CHROME_FLUTTER_DRIVE_ARGS" ]]; then
  CHROME_FLUTTER_DRIVE_ARGS=()
else
  read -ra CHROME_FLUTTER_DRIVE_ARGS <<< "$CHROME_FLUTTER_DRIVE_ARGS"
fi

# ── Device list (override with DEVICES env var) ─────────────────────────────
# Each entry must match an available `xcrun simctl list devices` name.
# Add more entries for additional App Store screenshot sizes:
#   "iPhone 17 Pro Max"    → 6.9″ (required)
#   "iPhone 17 Pro"        → 6.3″
#   "iPhone 16e"           → 4.7″
#   "iPad Pro 13-inch (M4)"→ 13″
if [[ -z "${DEVICES+x}" ]]; then
  # No DEVICES env var at all → use default set.
  DEVICES=(
    "iPhone 17 Pro Max"
  )
elif [[ -z "$DEVICES" ]]; then
  # DEVICES="" → explicitly empty, skip iOS.
  DEVICES=()
else
  # Allow DEVICES="A,B" override
  IFS=',' read -ra DEVICES <<< "$DEVICES"
fi

# ── Helpers ─────────────────────────────────────────────────────────────────

sanitize() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '_' | tr -cd '[:alnum:]_-'
}

detect_chrome_window_size() {
  if [[ "$(uname -s)" == "Darwin" ]]; then
    osascript -e 'tell application "Finder" to get bounds of window of desktop' 2>/dev/null \
      | awk -F', ' '{ width=$3-$1; height=$4-$2; if (width > 0 && height > 0) printf "%d,%d\n", width, height }'
  fi
}

validate_chrome_screenshot_dimensions() {
  local slug="$1"
  local viewport_size="$2"
  local first_png=""
  local actual_width=""
  local actual_height=""
  local expected_width=""
  local expected_height=""
  local viewport_width="${viewport_size%,*}"
  local viewport_height="${viewport_size#*,}"

  if ! command -v sips >/dev/null 2>&1; then
    return 0
  fi

  if [[ ! "$CHROME_DEVICE_SCALE_FACTOR" =~ ^[0-9]+$ ]]; then
    return 0
  fi

  first_png="$(find "$APP_DIR/screenshots/$slug" -name '*.png' -print -quit 2>/dev/null || true)"
  if [[ -z "$first_png" ]]; then
    return 0
  fi

  actual_width="$(sips -g pixelWidth "$first_png" 2>/dev/null | awk '/pixelWidth/ {print $2}')"
  actual_height="$(sips -g pixelHeight "$first_png" 2>/dev/null | awk '/pixelHeight/ {print $2}')"
  expected_width="$((viewport_width * CHROME_DEVICE_SCALE_FACTOR))"
  expected_height="$((viewport_height * CHROME_DEVICE_SCALE_FACTOR))"

  echo "   Captured PNG size: ${actual_width}x${actual_height}"
  echo "   Expected PNG size: ${expected_width}x${expected_height}"

  if [[ "$actual_width" != "$expected_width" || "$actual_height" != "$expected_height" ]]; then
    echo "   ❌ Chrome screenshot dimensions do not match the target viewport."
    echo "   Adjust CHROME_WINDOW_SIZE or CHROME_DEVICE_SCALE_FACTOR if the target changes."
    return 1
  fi
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
CHROMEDRIVER_PID=""
CHROMEDRIVER_STARTED=0

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

webdriver_ready() {
  curl -fsS "http://127.0.0.1:$CHROMEDRIVER_PORT/status" >/dev/null 2>&1
}

find_free_port() {
  python3 - <<'PY'
import socket

with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
}

find_chromedriver() {
  local candidate=""

  if [[ -n "${CHROMEDRIVER_BIN:-}" ]] && [[ -x "$CHROMEDRIVER_BIN" ]]; then
    echo "$CHROMEDRIVER_BIN"
    return 0
  fi

  candidate="$(command -v chromedriver 2>/dev/null || true)"
  if [[ -n "$candidate" ]] && [[ -x "$candidate" ]]; then
    echo "$candidate"
    return 0
  fi

  for candidate in \
    "$REPO_ROOT/node_modules/.bin/chromedriver" \
    "$APP_DIR/node_modules/.bin/chromedriver"
  do
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  done

  return 1
}

chrome_version() {
  if [[ -n "${CHROME_EXECUTABLE:-}" ]] && [[ -x "$CHROME_EXECUTABLE" ]]; then
    "$CHROME_EXECUTABLE" --version | awk '{print $NF}'
  elif [[ "$(uname -s)" == "Darwin" ]] \
    && [[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --version \
      | awk '{print $NF}'
  elif command -v google-chrome >/dev/null 2>&1; then
    google-chrome --version | awk '{print $NF}'
  elif command -v chromium >/dev/null 2>&1; then
    chromium --version | awk '{print $NF}'
  fi
}

chromedriver_version() {
  local chromedriver_bin="$1"
  "$chromedriver_bin" --version 2>/dev/null | awk '{print $2}'
}

version_major() {
  echo "$1" | cut -d. -f1
}

chromedriver_platform() {
  local os_name
  local arch_name

  os_name="$(uname -s)"
  arch_name="$(uname -m)"

  case "$os_name:$arch_name" in
    Darwin:arm64) echo "mac-arm64" ;;
    Darwin:x86_64) echo "mac-x64" ;;
    Linux:x86_64) echo "linux64" ;;
    Linux:amd64) echo "linux64" ;;
    *)
      return 1
      ;;
  esac
}

download_matching_chromedriver() {
  local browser_version=""
  local browser_major=""
  local platform=""
  local resolution=""
  local driver_version=""
  local driver_url=""
  local driver_dir=""
  local driver_bin=""
  local tmpdir=""
  local extracted_bin=""

  browser_version="$(chrome_version)"
  if [[ -z "$browser_version" ]]; then
    echo "   ❌ Could not determine the local Chrome version." >&2
    return 1
  fi

  browser_major="$(version_major "$browser_version")"
  platform="$(chromedriver_platform)" || {
    echo "   ❌ Automatic ChromeDriver download is not supported on $(uname -s)/$(uname -m)." >&2
    return 1
  }

  if ! command -v python3 >/dev/null 2>&1; then
    echo "   ❌ python3 is required to resolve Chrome-for-Testing metadata." >&2
    return 1
  fi
  if ! command -v curl >/dev/null 2>&1; then
    echo "   ❌ curl is required to download ChromeDriver." >&2
    return 1
  fi
  if ! command -v unzip >/dev/null 2>&1; then
    echo "   ❌ unzip is required to unpack ChromeDriver." >&2
    return 1
  fi

  resolution="$(
    CHROME_VERSION="$browser_version" \
    CHROME_MAJOR="$browser_major" \
    CHROMEDRIVER_PLATFORM="$platform" \
    python3 - <<'PY'
import json
import os
import sys
import urllib.request

metadata_url = "https://googlechromelabs.github.io/chrome-for-testing/known-good-versions-with-downloads.json"
browser_version = os.environ["CHROME_VERSION"]
browser_major = os.environ["CHROME_MAJOR"]
platform = os.environ["CHROMEDRIVER_PLATFORM"]

try:
    with urllib.request.urlopen(metadata_url, timeout=30) as response:
        payload = json.load(response)
except Exception as exc:
    print(f"failed to fetch Chrome-for-Testing metadata: {exc}", file=sys.stderr)
    sys.exit(1)

matches = []
for version in payload.get("versions", []):
    if version.get("version", "").split(".", 1)[0] != browser_major:
        continue
    downloads = version.get("downloads", {}).get("chromedriver", [])
    for download in downloads:
        if download.get("platform") == platform:
            matches.append((version["version"], download["url"]))
            break

if not matches:
    print(f"no ChromeDriver found for Chrome major {browser_major} on {platform}", file=sys.stderr)
    sys.exit(1)

exact = next((match for match in matches if match[0] == browser_version), None)
chosen = exact or matches[-1]
print(f"{chosen[0]}\t{chosen[1]}")
PY
  )" || {
    echo "   ❌ Could not resolve a matching ChromeDriver download." >&2
    return 1
  }

  driver_version="$(printf '%s' "$resolution" | awk -F '\t' '{print $1}')"
  driver_url="$(printf '%s' "$resolution" | awk -F '\t' '{print $2}')"
  driver_dir="$CHROMEDRIVER_CACHE_DIR/$driver_version/$platform"
  driver_bin="$driver_dir/chromedriver"

  if [[ -x "$driver_bin" ]]; then
    echo "   📦 Using cached ChromeDriver $driver_version ($driver_bin)" >&2
    echo "$driver_bin"
    return 0
  fi

  echo "   ⬇️  Downloading ChromeDriver $driver_version for $platform..." >&2
  tmpdir="$(mktemp -d)"
  curl -fsSL "$driver_url" -o "$tmpdir/chromedriver.zip" || {
    rm -rf "$tmpdir"
    echo "   ❌ ChromeDriver download failed: $driver_url" >&2
    return 1
  }
  unzip -q "$tmpdir/chromedriver.zip" -d "$tmpdir" || {
    rm -rf "$tmpdir"
    echo "   ❌ ChromeDriver unzip failed." >&2
    return 1
  }

  extracted_bin="$(find "$tmpdir" -type f -name chromedriver -print -quit)"
  if [[ -z "$extracted_bin" ]]; then
    rm -rf "$tmpdir"
    echo "   ❌ Downloaded archive did not contain a chromedriver binary." >&2
    return 1
  fi

  mkdir -p "$driver_dir"
  cp "$extracted_bin" "$driver_bin"
  chmod +x "$driver_bin"
  xattr -d com.apple.quarantine "$driver_bin" 2>/dev/null || true
  rm -rf "$tmpdir"

  echo "   ✅ Cached ChromeDriver at $driver_bin" >&2
  echo "$driver_bin"
}

validate_chromedriver_version() {
  local chromedriver_bin="$1"
  local driver_version=""
  local browser_version=""
  local driver_major=""
  local browser_major=""

  driver_version="$(chromedriver_version "$chromedriver_bin")"
  browser_version="$(chrome_version)"

  if [[ -z "$driver_version" || -z "$browser_version" ]]; then
    return 0
  fi

  driver_major="$(version_major "$driver_version")"
  browser_major="$(version_major "$browser_version")"

  echo "   Chrome: $browser_version"
  echo "   ChromeDriver: $driver_version ($chromedriver_bin)"

  if [[ "$driver_major" != "$browser_major" ]]; then
    echo "   ❌ ChromeDriver major version $driver_major does not match Chrome major version $browser_major."
    echo "   Set CHROMEDRIVER_BIN to a matching ChromeDriver, or set CHROMEDRIVER_ALLOW_VERSION_MISMATCH=1 to bypass."
    [[ "$CHROMEDRIVER_ALLOW_VERSION_MISMATCH" == "1" ]]
    return
  fi
}

ensure_chromedriver() {
  local chromedriver_bin=""

  if [[ -z "$CHROMEDRIVER_PORT" ]]; then
    if [[ "$CHROMEDRIVER_AUTOSTART" == "1" ]]; then
      CHROMEDRIVER_PORT="$(find_free_port)"
    else
      CHROMEDRIVER_PORT="4444"
    fi
  fi

  if [[ -z "$CHROMEDRIVER_LOG" ]]; then
    CHROMEDRIVER_LOG="$REPO_ROOT/logs/chromedriver-$CHROMEDRIVER_PORT.log"
  fi

  if webdriver_ready; then
    echo "   🚗 Using existing WebDriver server on port $CHROMEDRIVER_PORT"
    return 0
  fi

  if [[ "$CHROMEDRIVER_AUTOSTART" != "1" ]]; then
    echo "   ❌ No WebDriver server is listening on port $CHROMEDRIVER_PORT"
    echo "   Start ChromeDriver manually or set CHROMEDRIVER_AUTOSTART=1."
    return 1
  fi

  chromedriver_bin="$(find_chromedriver || true)"
  if [[ -n "$chromedriver_bin" ]]; then
    if ! validate_chromedriver_version "$chromedriver_bin"; then
      if [[ "$CHROMEDRIVER_AUTO_DOWNLOAD" != "1" ]]; then
        return 1
      fi
      echo "   ↻ Resolving a matching ChromeDriver automatically..."
      chromedriver_bin="$(download_matching_chromedriver)" || return 1
      validate_chromedriver_version "$chromedriver_bin" || return 1
    fi
  elif [[ "$CHROMEDRIVER_AUTO_DOWNLOAD" == "1" ]]; then
    echo "   ↻ ChromeDriver not found; resolving a matching local driver automatically..."
    chromedriver_bin="$(download_matching_chromedriver)" || return 1
    validate_chromedriver_version "$chromedriver_bin" || return 1
  else
    echo "   ❌ ChromeDriver is not installed."
    echo "   Install it with Homebrew: brew install --cask chromedriver"
    echo "   Or set CHROMEDRIVER_BIN to an existing ChromeDriver binary."
    return 1
  fi

  mkdir -p "$(dirname "$CHROMEDRIVER_LOG")"

  echo "   🚗 Starting ChromeDriver on port ${CHROMEDRIVER_PORT}..."

  local port_pid
  port_pid=$(lsof -ti :"$CHROMEDRIVER_PORT" 2>/dev/null || true)
  if [[ -n "$port_pid" ]]; then
    echo "   ❌ Port $CHROMEDRIVER_PORT is already in use by PID $port_pid."
    echo "   Set CHROMEDRIVER_PORT to a free port, or unset it to auto-select one."
    return 1
  fi

  "$chromedriver_bin" --port="$CHROMEDRIVER_PORT" >"$CHROMEDRIVER_LOG" 2>&1 &
  CHROMEDRIVER_PID=$!

  for _ in {1..20}; do
    if webdriver_ready; then
      CHROMEDRIVER_STARTED=1
      echo "   ✅ ChromeDriver ready"
      return 0
    fi

    if ! kill -0 "$CHROMEDRIVER_PID" 2>/dev/null; then
      break
    fi

    sleep 1
  done

  echo "   ❌ ChromeDriver failed to start. Recent log output:"
  tail -n 20 "$CHROMEDRIVER_LOG" 2>/dev/null | sed 's/^/      /' || true
  return 1
}

stop_chromedriver() {
  if [[ "$CHROMEDRIVER_STARTED" == "1" ]] \
    && [[ -n "$CHROMEDRIVER_PID" ]] \
    && kill -0 "$CHROMEDRIVER_PID" 2>/dev/null; then
    kill "$CHROMEDRIVER_PID" 2>/dev/null || true
    wait "$CHROMEDRIVER_PID" 2>/dev/null || true
    CHROMEDRIVER_PID=""
    CHROMEDRIVER_STARTED=0
  fi
}

prepare_screenshot_output() {
  local slug="$1"

  rm -rf "$APP_DIR/screenshots/$slug/light" "$APP_DIR/screenshots/$slug/dark"
}

cleanup() {
  stop_recording
  stop_chromedriver
}

trap cleanup EXIT

seed_screenshot_relay() {
  local config_file="$REPO_ROOT/logs/screenshot_seed_config.json"
  local trade_sponsor_private_key="${SCREENSHOT_TRADE_SPONSOR_PRIVATE_KEY:-${SEED_TRADE_SPONSOR_PRIVATE_KEY:-0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d}}"

  mkdir -p "$(dirname "$config_file")"

  cat >"$config_file" <<JSON
{
  "seed": 42,
  "userCount": 8,
  "hostRatio": 0.5,
  "listingsPerHostAvg": 2.0,
  "reservationRequestsPerGuest": 10,
  "invalidReservationRate": 0,
  "fundProfiles": false,
  "tradeSponsorPrivateKey": "$trade_sponsor_private_key",
  "setupLnbits": true,
  "messagesPerThreadAvg": 4,
  "completedRatio": 0.5,
  "paidViaEscrowRatio": 1.0,
  "paidViaEscrowArbitrateRatio": 0.15,
  "paidViaEscrowClaimedRatio": 0.7,
  "reviewRatio": 1.0
}
JSON

  echo "🌱 Seeding relay for screenshots…"
  echo "   Using dedicated trade sponsor; generated user profiles are not funded."
  "$REPO_ROOT/scripts/seed_relay.sh" --config-file="$config_file" \
    2>&1 | sed -l 's/^/   /'
  echo ""
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

  find "$dest_dir" -maxdepth 1 -type f -name '*.png' -delete
  cp "$source_dir"/*.png "$dest_dir"/
  echo "   🖼️  Synced dark screenshots to landing-page/assets/screenshot/"
}

run_chrome_screenshots() {
  local slug="chrome"
  local chrome_viewport_size="${CHROME_WINDOW_SIZE:-$(detect_chrome_window_size)}"
  chrome_viewport_size="${chrome_viewport_size:-1440,1024}"
  local browser_dimension="${chrome_viewport_size/,/x}"
  local chrome_flags=()
  local chrome_binary_args=()
  local screenshot_count=0
  local drive_status=0
  local dimension_status=0

  if [[ -n "${CHROME_EXECUTABLE:-}" ]]; then
    chrome_binary_args=(--chrome-binary="$CHROME_EXECUTABLE")
  fi

  if [[ -n "$CHROME_DEVICE_SCALE_FACTOR" ]]; then
    browser_dimension="${browser_dimension}@${CHROME_DEVICE_SCALE_FACTOR}"
  fi

  if [[ "$CHROME_START_FULLSCREEN" == "1" ]]; then
    chrome_flags+=("--start-fullscreen")
  fi

  echo "🌐 Chrome → screenshots/$slug/"
  echo "   Target viewport: $chrome_viewport_size"
  echo "   Device scale factor: ${CHROME_DEVICE_SCALE_FACTOR:-system}"
  echo "   Browser dimension: $browser_dimension"
  echo "   Fullscreen: $CHROME_START_FULLSCREEN"
  echo "   Flutter drive mode: debug"

  if ! ensure_chromedriver; then
    FAILED+=("Chrome")
    echo ""
    return 1
  fi

  prepare_screenshot_output "$slug"

  echo "   🏃 Running screenshot suite…"

  set +e
  SCREENSHOT_DEVICE="$slug" flutter drive \
    --driver=test_driver/screenshot_test.dart \
    --target=integration_test/screenshots.dart \
    -d chrome \
    ${chrome_binary_args[@]+"${chrome_binary_args[@]}"} \
    --driver-port="$CHROMEDRIVER_PORT" \
    --browser-dimension="$browser_dimension" \
    --timeout="$CHROME_FLUTTER_DRIVE_TIMEOUT" \
    ${chrome_flags[@]+"${chrome_flags[@]/#/--web-browser-flag=}"} \
    ${CHROME_FLUTTER_DRIVE_ARGS[@]+"${CHROME_FLUTTER_DRIVE_ARGS[@]}"} \
    --no-pub 2>&1 | sed -l 's/^/   /'
  drive_status=${PIPESTATUS[0]}
  set -e

  if [[ "$drive_status" -ne 0 ]]; then
    echo "   ❌ Flutter drive failed for Chrome (exit $drive_status)"
    FAILED+=("Chrome")
  fi

  screenshot_count=$(find "$APP_DIR/screenshots/$slug" -name '*.png' 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$screenshot_count" -lt "$CHROME_EXPECTED_SCREENSHOTS" ]]; then
    echo "   ❌ Chrome produced $screenshot_count screenshot(s); expected at least $CHROME_EXPECTED_SCREENSHOTS."
    if [[ "$drive_status" -eq 0 ]]; then
      FAILED+=("Chrome")
    fi
  elif [[ "$drive_status" -eq 0 ]]; then
    validate_chrome_screenshot_dimensions "$slug" "$chrome_viewport_size" || dimension_status=$?
    if [[ "$dimension_status" -ne 0 ]]; then
      FAILED+=("Chrome")
    else
      echo "   📁 Captured $screenshot_count Chrome screenshots"
      echo "   ✅ Done"
    fi
  fi

  if [[ "$drive_status" -ne 0 || "$screenshot_count" -lt "$CHROME_EXPECTED_SCREENSHOTS" || "$dimension_status" -ne 0 ]]; then
    echo "   ❌ Chrome screenshot run failed"
    echo ""
    return 1
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

seed_screenshot_relay

FAILED=()

for device_name in ${DEVICES[@]+"${DEVICES[@]}"}; do
  slug=$(sanitize "$device_name")
  echo "📱 $device_name → screenshots/$slug/"
  prepare_screenshot_output "$slug"

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
      -d "$udid" \
      --no-pub 2>&1 | sed -l 's/^/   /'; then
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
  run_chrome_screenshots || true
fi

# ── Summary ─────────────────────────────────────────────────────────────────

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ${#FAILED[@]} -gt 0 ]]; then
  echo "⚠️  Some devices failed: ${FAILED[*]+${FAILED[*]}}"
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
for device_name in ${DEVICES[@]+"${DEVICES[@]}"}; do
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

if [[ ${#FAILED[@]} -gt 0 ]]; then
  exit 1
fi
