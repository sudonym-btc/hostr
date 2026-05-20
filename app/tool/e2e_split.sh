#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

repo_root="$(cd .. && pwd)"
results_file="${HOSTR_DRIVE_RESULTS:-/tmp/hostr_drive_results.tsv}"
summary_file="${HOSTR_DRIVE_SUMMARY:-/tmp/hostr_drive_summary.txt}"
target_timeout_seconds="${HOSTR_DRIVE_TARGET_TIMEOUT_SECONDS:-1800}"
target_attempts="${HOSTR_DRIVE_TARGET_ATTEMPTS:-4}"
poll_interval_seconds="${HOSTR_DRIVE_POLL_INTERVAL_SECONDS:-1}"
post_pass_grace_seconds="${HOSTR_DRIVE_POST_PASS_GRACE_SECONDS:-15}"
web_renderer="${HOSTR_WEB_RENDERER:-}"
browser_headless="${HOSTR_WEB_HEADLESS:-1}"
default_chrome_executable="$(pwd)/tool/chrome_e2e.sh"
installed_chrome_binary="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
fallback_chrome_executable="$installed_chrome_binary"
webdriver_chrome_binary="${HOSTR_WEBDRIVER_CHROME_BINARY:-}"
chromedriver_cache_dir="${HOSTR_CHROMEDRIVER_CACHE_DIR:-$repo_root/.cache/chromedriver}"
browser_cache_dir="${HOSTR_BROWSER_CACHE_DIR:-$repo_root/.cache/chrome-for-testing}"
runner_lock_dir="${HOSTR_E2E_LOCK_DIR:-/tmp/hostr_e2e_runner.lock}"
restart_signet_enabled="${HOSTR_DRIVE_RESTART_SIGNET:-1}"
restart_escrow_enabled="${HOSTR_DRIVE_RESTART_ESCROW:-1}"
chromedriver_pid=""
chromedriver_port=""
chrome_profile_dir=""
flutter_tmp_dir=""
headless_flag=""

remove_profile_dir() {
  local dir="${1:-}"
  local attempt

  if [[ -z "$dir" ]] || [[ ! -d "$dir" ]]; then
    return
  fi

  for attempt in 1 2 3 4 5; do
    rm -rf "$dir" 2>/dev/null && return
    sleep 1
  done

  rm -rf "$dir" 2>/dev/null || true
}

clean_flutter_build_artifacts() {
  local build_dir="$PWD/build"
  local path

  for path in \
    "$build_dir/flutter_assets" \
    "$build_dir/native_assets" \
    "$build_dir/unit_test_assets" \
    "$build_dir/app.dill" \
    "$build_dir/web"; do
    if [[ -e "$path" ]]; then
      remove_profile_dir "$path"
      rm -rf "$path" 2>/dev/null || true
    fi
  done
}

kill_tree() {
  local parent="$1"
  local child

  for child in $(pgrep -P "$parent" 2>/dev/null || true); do
    kill_tree "$child"
  done
  kill "$parent" 2>/dev/null || true
}

kill_matching_processes() {
  local pattern="$1"
  local attempts pid pids

  for attempts in $(seq 1 5); do
    local pids
    pids="$(pgrep -f "$pattern" 2>/dev/null || true)"
    if [[ -z "$pids" ]]; then
      return
    fi
    for pid in $pids; do
      kill_tree "$pid"
    done
    sleep 1
  done

  pids="$(pgrep -f "$pattern" 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    for pid in $pids; do
      kill -9 "$pid" 2>/dev/null || true
    done
  fi
}

kill_repo_chrome_for_testing_processes() {
  local pid cmd

  for pid in $(pgrep -f 'Google Chrome for Testing' 2>/dev/null || true); do
    if [[ "$pid" == "$$" ]]; then
      continue
    fi

    cmd="$(ps -p "$pid" -o command= 2>/dev/null || true)"
    if [[ "$cmd" != *"$browser_cache_dir"* ]]; then
      continue
    fi

    kill_tree "$pid"
  done
}

cleanup_chrome_for_testing_default_profile() {
  local profile_dir="${HOME:-}/Library/Application Support/Google/Chrome for Testing"

  if [[ -z "${HOME:-}" ]] || [[ ! -d "$profile_dir" ]]; then
    return
  fi

  if pgrep -f 'Google Chrome for Testing' >/dev/null 2>&1; then
    return
  fi

  rm -rf "$profile_dir/Default/Sessions" 2>/dev/null || true
  rm -rf "$profile_dir/Default/Session Storage" 2>/dev/null || true
  rm -f "$profile_dir/Default/Current Session" 2>/dev/null || true
  rm -f "$profile_dir/Default/Current Tabs" 2>/dev/null || true
  rm -f "$profile_dir/Default/Last Session" 2>/dev/null || true
  rm -f "$profile_dir/Default/Last Tabs" 2>/dev/null || true
  rm -f "$profile_dir"/Singleton* 2>/dev/null || true
}

acquire_runner_lock() {
  local attempt existing_pid existing_cmd

  for attempt in $(seq 1 10); do
    if mkdir "$runner_lock_dir" 2>/dev/null; then
      printf '%s\n' "$$" > "$runner_lock_dir/pid"
      return
    fi

    existing_pid="$(cat "$runner_lock_dir/pid" 2>/dev/null || true)"
    existing_cmd="$(ps -p "$existing_pid" -o command= 2>/dev/null || true)"
    if [[ -n "$existing_pid" ]] && [[ "$existing_cmd" == *"/app/tool/e2e_"* ]]; then
      kill_tree "$existing_pid"
      sleep 2
    fi

    rm -rf "$runner_lock_dir" 2>/dev/null || true
    sleep 1
  done

  printf 'ERROR: could not acquire Hostr e2e runner lock.\n'
  exit 1
}

release_runner_lock() {
  local existing_pid

  if [[ ! -d "$runner_lock_dir" ]]; then
    return
  fi

  existing_pid="$(cat "$runner_lock_dir/pid" 2>/dev/null || true)"
  if [[ "$existing_pid" == "$$" ]]; then
    rm -rf "$runner_lock_dir" 2>/dev/null || true
  fi
}

cleanup_background_tools() {
  if [[ -n "$chromedriver_pid" ]]; then
    kill_tree "$chromedriver_pid"
    wait "$chromedriver_pid" >/dev/null 2>&1 || true
    chromedriver_pid=""
  fi
  if [[ -n "$chrome_profile_dir" ]] && [[ -d "$chrome_profile_dir" ]]; then
    remove_profile_dir "$chrome_profile_dir"
    chrome_profile_dir=""
  fi
  if [[ -n "$flutter_tmp_dir" ]] && [[ -d "$flutter_tmp_dir" ]]; then
    remove_profile_dir "$flutter_tmp_dir"
    flutter_tmp_dir=""
  fi
  cleanup_stale_flutter_targets
  release_runner_lock
}

trap cleanup_background_tools EXIT

acquire_runner_lock

cleanup_stale_flutter_targets() {
  kill_matching_processes 'flutter_tools\.snapshot drive .*--driver=test_driver/screenshot_test\.dart .*--target=integration_test/'
  kill_matching_processes '/tmp/hostr_(drive|god_suite)_chrome_profile_|/tmp/hostr_flutter_chrome_wrapper_|/tmp/hostr_flutter_tmp_'
  kill_matching_processes "$chromedriver_cache_dir/.*/chromedriver"
  kill_repo_chrome_for_testing_processes

  rm -rf /tmp/hostr_*_chrome_profile_* 2>/dev/null || true
  rm -rf /tmp/hostr_flutter_chrome_wrapper_* 2>/dev/null || true
  rm -rf /tmp/hostr_flutter_tmp_* 2>/dev/null || true
  cleanup_inactive_flutter_chrome_profiles
  cleanup_chrome_for_testing_default_profile
}

cleanup_inactive_flutter_chrome_profiles() {
  local base dir parent escaped_dir
  local temp_roots=()

  if [[ -n "${TMPDIR:-}" ]] && [[ -d "${TMPDIR:-}" ]]; then
    temp_roots+=("${TMPDIR:-}")
  fi
  for base in /var/folders/*/*/T; do
    if [[ -d "$base" ]]; then
      temp_roots+=("$base")
    fi
  done

  for base in "${temp_roots[@]}"; do
    if [[ -z "$base" ]] || [[ ! -d "$base" ]]; then
      continue
    fi

    while IFS= read -r dir; do
      if [[ -z "$dir" ]] || [[ ! -d "$dir" ]]; then
        continue
      fi

      escaped_dir="$(printf '%s' "$dir" | sed 's/[][(){}.^$*+?|\\]/\\&/g')"
      if pgrep -f "$escaped_dir" >/dev/null 2>&1; then
        continue
      fi

      parent="$(dirname "$dir")"
      case "$parent" in
        */flutter_tools.*) remove_profile_dir "$parent" ;;
        *) remove_profile_dir "$dir" ;;
      esac
    done < <(
      find "$base" \
        -maxdepth 2 \
        -path "$base/flutter_tools.*/flutter_tools_chrome_device.*" \
        -type d \
        -prune \
        -print 2>/dev/null || true
    )
  done
}

cleanup_signet_test_keys() {
  local config_file="$repo_root/docker/data/signet/signet.json"

  if [[ ! -f "$config_file" ]] || ! command -v jq >/dev/null 2>&1; then
    return
  fi

  local tmp_file
  tmp_file="$(mktemp)"
  jq '
    def e2e_key:
      startswith("hostr-bunker-") or
      startswith("hostr-login-") or
      startswith("hostr-retry-") or
      startswith("hostr-god-");
    if (.keys | type) == "object" then
      .keys |= with_entries(select(.key | e2e_key | not))
    else
      .
    end
  ' "$config_file" > "$tmp_file"
  mv "$tmp_file" "$config_file"
}

cleanup_signet_test_apps() {
  if ! command -v jq >/dev/null 2>&1 || ! command -v curl >/dev/null 2>&1; then
    return
  fi

  local cookie_file csrf_token app_id
  cookie_file="$(mktemp)"
  csrf_token="$(
    { curl -sk --max-time 5 -c "$cookie_file" \
      https://bunker-nostr.hostr.development/csrf-token || true; } |
      jq -r '(.csrfToken // .token // "") | tostring'
  )"

  if [[ -z "$csrf_token" ]]; then
    rm -f "$cookie_file"
    return
  fi

  while IFS= read -r app_id; do
    if [[ -z "$app_id" ]]; then
      continue
    fi

    curl -sk --max-time 5 \
      -b "$cookie_file" \
      -H "x-csrf-token: $csrf_token" \
      -X POST \
      "https://bunker-nostr.hostr.development/apps/${app_id}/revoke" \
      >/dev/null || true
  done < <(
    { curl -sk --max-time 5 -b "$cookie_file" \
      https://bunker-nostr.hostr.development/apps || true; } |
      jq -r '
        def e2e_key:
          startswith("hostr-bunker-") or
          startswith("hostr-login-") or
          startswith("hostr-retry-") or
          startswith("hostr-god-");
        (.apps // [])
        | .[]
        | select((.keyName // "") | e2e_key)
        | .id
      '
  )

  rm -f "$cookie_file"
}

signet_is_ready() {
  local health_body csrf_body

  health_body="$(curl -sk --max-time 5 https://bunker-nostr.hostr.development/health || true)"
  csrf_body="$(curl -sk --max-time 5 https://bunker-nostr.hostr.development/csrf-token || true)"

  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$health_body" | jq -e \
      '(.status == "ok" or .status == "degraded") and ((.subscriptions // 999) <= 4)' \
      >/dev/null 2>&1 || return 1
    printf '%s' "$csrf_body" | jq -e \
      '((.csrfToken // .token // "") | tostring | length) > 0' \
      >/dev/null 2>&1 || return 1
    return 0
  fi

  printf '%s' "$health_body" | grep -Eq '"status":"(ok|degraded)"' || return 1
  printf '%s' "$csrf_body" | grep -Eq '"(csrfToken|token)"' || return 1
}

restart_signet() {
  cleanup_signet_test_apps
  cleanup_signet_test_keys

  if [[ "$restart_signet_enabled" != "1" ]]; then
    return
  fi

  if ! command -v docker >/dev/null 2>&1; then
    return
  fi

  if ! docker ps --format '{{.Names}}' | grep -qx 'hostr-signet-1'; then
    return
  fi

  docker compose --project-directory "$repo_root" restart signet >/dev/null

  local attempt
  for attempt in $(seq 1 45); do
    if signet_is_ready; then
      return
    fi
    sleep 2
  done

  printf 'WARN: Signet did not report a clean health state before continuing.\n'
}

restart_escrow() {
  if [[ "$restart_escrow_enabled" != "1" ]]; then
    return
  fi

  if ! command -v docker >/dev/null 2>&1; then
    return
  fi

  if ! docker ps --format '{{.Names}}' | grep -qx 'hostr-escrow-1'; then
    return
  fi

  docker compose --project-directory "$repo_root" restart escrow >/dev/null
}

is_startup_failure_log() {
  local log_file="$1"

  if ! [[ -f "$log_file" ]]; then
    return 1
  fi

  grep -aq 'Launching integration_test/' "$log_file" || return 1

  if grep -aq 'Starting application from main method in:' "$log_file"; then
    return 1
  fi

  if grep -aq '00:00 +0:' "$log_file"; then
    return 1
  fi

  return 0
}

log_has_failure() {
  local log_file="$1"

  # `flutter drive` can still print "All tests passed" after an integration
  # test reports a setUpAll/test error on web, so treat Dart test failure
  # counters as authoritative instead of relying only on the final banner.
  grep -aEq \
    'Some tests failed|Test failed\.|AppConnectionException|Failed to launch|Failed to load|Compilation failed|Debugger: Target crashed|Target crashed!|^[0-9][0-9]:[0-9][0-9] \+[0-9]+ -[1-9][0-9]*:|^[0-9][0-9]:[0-9][0-9] \+[0-9]+: .* \[E\]$' \
    "$log_file"
}

log_has_pass() {
  local log_file="$1"

  grep -aq 'All tests passed' "$log_file"
}

detect_chromedriver_platform() {
  case "$(uname -m)" in
    arm64) printf 'mac-arm64\n' ;;
    x86_64) printf 'mac-x64\n' ;;
    *) return 1 ;;
  esac
}

resolve_chromedriver_version() {
  local chrome_version chrome_build

  chrome_version="$("$installed_chrome_binary" --version | awk '{print $3}')"
  chrome_build="$(printf '%s' "$chrome_version" | awk -F. '{printf "%s.%s.%s", $1, $2, $3}')"

  python3 - "$chrome_build" <<'PY'
import json
import sys
import urllib.request

build = sys.argv[1]
url = 'https://googlechromelabs.github.io/chrome-for-testing/latest-patch-versions-per-build.json'
with urllib.request.urlopen(url) as response:
    data = json.load(response)

entry = data['builds'].get(build)
if not entry:
    raise SystemExit(1)

print(entry['version'])
PY
}

ensure_matching_chrome_browser() {
  local platform version version_dir archive_path download_url app_dir final_bin tmpdir extracted_app

  if [[ -n "${HOSTR_WEBDRIVER_CHROME_BINARY:-}" ]] && [[ -x "${HOSTR_WEBDRIVER_CHROME_BINARY}" ]]; then
    printf '%s\n' "${HOSTR_WEBDRIVER_CHROME_BINARY}"
    return
  fi

  platform="$(detect_chromedriver_platform)"
  version="$(resolve_chromedriver_version)"
  version_dir="${browser_cache_dir}/${version}/${platform}"
  app_dir="${version_dir}/Google Chrome for Testing.app"
  final_bin="${app_dir}/Contents/MacOS/Google Chrome for Testing"

  if [[ -x "$final_bin" ]]; then
    printf '%s\n' "$final_bin"
    return
  fi

  mkdir -p "$version_dir"
  archive_path="${version_dir}/chrome.zip"
  download_url="https://storage.googleapis.com/chrome-for-testing-public/${version}/${platform}/chrome-${platform}.zip"
  tmpdir="$(mktemp -d)"

  curl -fsSL "$download_url" -o "$archive_path"
  unzip -oq "$archive_path" -d "$tmpdir"
  extracted_app="$(find "$tmpdir" -type d -name 'Google Chrome for Testing.app' -print -quit)"
  rm -rf "$app_dir"
  cp -R "$extracted_app" "$app_dir"
  rm -rf "$tmpdir"

  printf '%s\n' "$final_bin"
}

ensure_matching_chromedriver() {
  local platform version version_dir archive_path download_url extracted_bin final_bin nested_bin tmpdir

  if [[ -n "${HOSTR_CHROMEDRIVER:-}" ]] && [[ -x "${HOSTR_CHROMEDRIVER}" ]]; then
    printf '%s\n' "${HOSTR_CHROMEDRIVER}"
    return
  fi

  platform="$(detect_chromedriver_platform)"
  version="$(resolve_chromedriver_version)"
  version_dir="${chromedriver_cache_dir}/${version}/${platform}"
  final_bin="${version_dir}/chromedriver"
  nested_bin="${version_dir}/chromedriver-${platform}/chromedriver"

  if [[ -x "$final_bin" ]]; then
    printf '%s\n' "$final_bin"
    return
  fi

  if [[ -x "$nested_bin" ]]; then
    printf '%s\n' "$nested_bin"
    return
  fi

  mkdir -p "$version_dir"
  archive_path="${version_dir}/chromedriver.zip"
  download_url="https://storage.googleapis.com/chrome-for-testing-public/${version}/${platform}/chromedriver-${platform}.zip"
  tmpdir="$(mktemp -d)"

  curl -fsSL "$download_url" -o "$archive_path"
  unzip -oq "$archive_path" -d "$tmpdir"
  extracted_bin="$(find "$tmpdir" -type f -name chromedriver -print -quit)"

  cp "$extracted_bin" "$final_bin"
  chmod +x "$final_bin"
  rm -rf "$tmpdir"

  printf '%s\n' "$final_bin"
}

webdriver_chrome_binary="${webdriver_chrome_binary:-$(ensure_matching_chrome_browser)}"
export HOSTR_CHROME_BIN="$webdriver_chrome_binary"

if [[ -z "${CHROME_EXECUTABLE:-}" ]]; then
  export CHROME_EXECUTABLE="$default_chrome_executable"
fi

if [[ "$browser_headless" == "1" ]]; then
  headless_flag="--web-browser-flag=--headless=new"
fi

allocate_driver_port() {
  python3 - <<'PY'
import socket

sock = socket.socket()
sock.bind(('127.0.0.1', 0))
print(sock.getsockname()[1])
sock.close()
PY
}

start_chromedriver() {
  local chromedriver_bin chromedriver_log attempt

  chromedriver_bin="$(ensure_matching_chromedriver)"
  chromedriver_port="$(allocate_driver_port)"
  chromedriver_log="/tmp/hostr_chromedriver_${chromedriver_port}.log"

  "$chromedriver_bin" \
    --port="$chromedriver_port" \
    --allowed-origins='*' >"$chromedriver_log" 2>&1 &
  chromedriver_pid="$!"

  for attempt in $(seq 1 20); do
    if curl -sf "http://127.0.0.1:${chromedriver_port}/status" >/dev/null 2>&1; then
      return
    fi
    sleep 1
  done

  printf 'WARN: chromedriver did not become healthy on port %s. See %s\n' "$chromedriver_port" "$chromedriver_log"
}

stop_chromedriver() {
  if [[ -n "$chromedriver_pid" ]]; then
    kill_tree "$chromedriver_pid"
    wait "$chromedriver_pid" >/dev/null 2>&1 || true
  fi
  chromedriver_pid=""
  chromedriver_port=""
  if [[ -n "$chrome_profile_dir" ]] && [[ -d "$chrome_profile_dir" ]]; then
    remove_profile_dir "$chrome_profile_dir"
  fi
  chrome_profile_dir=""
  if [[ -n "$flutter_tmp_dir" ]] && [[ -d "$flutter_tmp_dir" ]]; then
    remove_profile_dir "$flutter_tmp_dir"
  fi
  flutter_tmp_dir=""
}

run_target() {
  local index="$1"
  local total="$2"
  local target="$3"
  local name log_file chrome_wrapper_log started now status exit_code attempt

  name="$(basename "$target" .dart)"
  log_file="/tmp/hostr_drive_${index}_${name}.log"
  chrome_wrapper_log="/tmp/hostr_drive_${index}_${name}_chrome_wrapper.log"

  {
    printf '\n[%02d/%02d] %s\n' "$index" "$total" "$target"
    printf 'Log: %s\n' "$log_file"
  } | tee -a "$summary_file"

  status=""
  exit_code=0

  for attempt in $(seq 1 "$target_attempts"); do
    if (( attempt > 1 )); then
      printf 'Retrying %s after startup failure (attempt %d/%d)\n' "$target" "$attempt" "$target_attempts" | tee -a "$summary_file"
    fi

    : > "$log_file"
    : > "$chrome_wrapper_log"
    cleanup_stale_flutter_targets
    clean_flutter_build_artifacts
    restart_signet
    restart_escrow
    start_chromedriver
    chrome_profile_dir="$(mktemp -d "/tmp/hostr_drive_chrome_profile_${name}_${attempt}_XXXXXX")"
    flutter_tmp_dir="$(mktemp -d "/tmp/hostr_flutter_tmp_${name}_${attempt}_XXXXXX")"

    {
      printf 'TARGET=%s\n' "$target"
      printf 'CHROME_WRAPPER_LOG=%s\n' "$chrome_wrapper_log"
      printf 'CHROME_BINARY=%s\n' "$webdriver_chrome_binary"
      printf 'CHROME_PROFILE_DIR=%s\n' "$chrome_profile_dir"
      printf 'FLUTTER_TMP_DIR=%s\n' "$flutter_tmp_dir"
      printf 'CHROMEDRIVER_PORT=%s\n' "$chromedriver_port"
    } >> "$log_file"
    TMPDIR="$flutter_tmp_dir" \
      HOSTR_CHROME_WRAPPER_LOG="$chrome_wrapper_log" \
      flutter drive \
      --driver=test_driver/screenshot_test.dart \
      --target="$target" \
      --driver-port="$chromedriver_port" \
      --browser-name=chrome \
      --chrome-binary="$webdriver_chrome_binary" \
      ${web_renderer:+--web-renderer="$web_renderer"} \
      --web-browser-flag=--user-data-dir="$chrome_profile_dir" \
      --web-browser-flag=--no-first-run \
      --web-browser-flag=--no-default-browser-check \
      --web-browser-flag=--disable-web-security \
      --web-browser-flag=--ignore-certificate-errors \
      --web-browser-flag=--disable-gpu \
      --web-browser-flag=--disable-background-networking \
      --web-browser-flag=--use-mock-keychain \
      --web-browser-flag=--password-store=basic \
      ${headless_flag:+$headless_flag} \
      --no-dds \
      -d chrome >>"$log_file" 2>&1 &

    local pid="$!"
    local chrome_tab_cleaner_pid=""
    python3 "$PWD/tool/close_stale_chrome_tabs.py" \
      --wrapper-log "$chrome_wrapper_log" \
      --timeout 90 >>"$log_file" 2>&1 &
    chrome_tab_cleaner_pid="$!"
    started="$(date +%s)"
    status=""
    exit_code=0
    local pass_seen_at=""

    while kill -0 "$pid" 2>/dev/null; do
      if log_has_failure "$log_file"; then
        status="FAIL"
        kill_tree "$pid"
        break
      fi

      if log_has_pass "$log_file"; then
        if [[ -z "$pass_seen_at" ]]; then
          pass_seen_at="$(date +%s)"
        fi
        now="$(date +%s)"
        if (( now - pass_seen_at >= post_pass_grace_seconds )); then
          status="PASS"
          kill_tree "$pid"
          break
        fi
      fi

      now="$(date +%s)"
      if (( now - started > target_timeout_seconds )); then
        status="TIMEOUT"
        kill_tree "$pid"
        break
      fi

      sleep "$poll_interval_seconds"
    done

    wait "$pid" >/dev/null 2>&1 || exit_code="$?"
    if [[ -n "$chrome_tab_cleaner_pid" ]]; then
      kill "$chrome_tab_cleaner_pid" 2>/dev/null || true
      wait "$chrome_tab_cleaner_pid" >/dev/null 2>&1 || true
    fi
    stop_chromedriver

    if [[ -z "$status" ]]; then
      if log_has_failure "$log_file"; then
        status="FAIL"
      elif log_has_pass "$log_file"; then
        status="PASS"
      elif [[ "$exit_code" -eq 0 ]]; then
        status="PASS"
      else
        status="FAIL"
      fi
    elif [[ "$status" == "PASS" ]] && log_has_failure "$log_file"; then
      status="FAIL"
    fi

    if [[ "$status" == "PASS" ]]; then
      cleanup_stale_flutter_targets
      break
    fi

    if ! grep -aEq 'AppConnectionException|Failed to launch|Failed to load' "$log_file" &&
       ! is_startup_failure_log "$log_file"; then
      cleanup_stale_flutter_targets
      break
    fi

    cleanup_stale_flutter_targets
  done

  printf '%s\t%s\t%s\n' "$status" "$target" "$log_file" >> "$results_file"
  printf '%s\t%s\t%s\n' "$status" "$target" "$log_file" | tee -a "$summary_file"
}

targets=(
  integration_test/bunker_popup_test.dart
  integration_test/search_filter_test.dart
  integration_test/login_routing_nsec_test.dart
  integration_test/login_routing_bunker_test.dart
  integration_test/reservation_usd_nsec_test.dart
  integration_test/reservation_usd_bunker_test.dart
  integration_test/reservation_btc_nsec_test.dart
  integration_test/reservation_btc_bunker_test.dart
  integration_test/reservation_negotiated_usd_nsec_test.dart
  integration_test/reservation_negotiated_usd_bunker_test.dart
  integration_test/reservation_negotiated_btc_nsec_test.dart
  integration_test/reservation_negotiated_btc_bunker_test.dart
  integration_test/cancel_guest_pending_nsec_test.dart
  integration_test/cancel_guest_pending_bunker_test.dart
  integration_test/cancel_guest_live_nsec_test.dart
  integration_test/cancel_guest_live_bunker_test.dart
  integration_test/cancel_host_pending_nsec_test.dart
  integration_test/cancel_host_pending_bunker_test.dart
  integration_test/cancel_host_live_nsec_test.dart
  integration_test/cancel_host_live_bunker_test.dart
  integration_test/host_booking_flows_nsec_test.dart
  integration_test/host_booking_flows_bunker_test.dart
  integration_test/listing_crud_nsec_test.dart
  integration_test/listing_crud_bunker_test.dart
  integration_test/hostings_booking_nsec_test.dart
  integration_test/hostings_booking_bunker_test.dart
  integration_test/review_flow_nsec_test.dart
  integration_test/review_flow_bunker_test.dart
  integration_test/auto_withdraw_nsec_test.dart
  integration_test/auto_withdraw_bunker_test.dart
  integration_test/subscription_lifecycle_test.dart
)

if [[ -n "${HOSTR_DRIVE_ONLY:-}" ]]; then
  filtered_targets=()
  for target in "${targets[@]}"; do
    if [[ "$target" == *"$HOSTR_DRIVE_ONLY"* ]]; then
      filtered_targets+=("$target")
    fi
  done
  if (( ${#filtered_targets[@]} == 0 )); then
    targets=()
  else
    targets=("${filtered_targets[@]}")
  fi
fi

total="${#targets[@]}"
pass_count=0
fail_count=0

: > "$results_file"
: > "$summary_file"

index=1
if (( total > 0 )); then
  for target in "${targets[@]}"; do
    run_target "$index" "$total" "$target"
    case "$(tail -n 1 "$results_file" | cut -f 1)" in
      PASS) pass_count=$((pass_count + 1)) ;;
      *) fail_count=$((fail_count + 1)) ;;
    esac
    printf 'Running total: %d pass / %d fail / %d total\n' "$pass_count" "$fail_count" "$index" | tee -a "$summary_file"
    index=$((index + 1))
  done
fi

printf '\nDrive split summary: %d pass / %d fail / %d total\n' "$pass_count" "$fail_count" "$total" | tee -a "$summary_file"

if (( fail_count > 0 )); then
  exit 1
fi
