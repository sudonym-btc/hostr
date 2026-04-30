#!/usr/bin/env bash
set -euo pipefail

chrome_bin="${HOSTR_CHROME_BIN:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
log_file="${HOSTR_CHROME_WRAPPER_LOG:-/tmp/hostr_chrome_wrapper.log}"
args=("$@")
has_user_data_dir=0

for arg in "${args[@]}"; do
  if [[ "$arg" == --user-data-dir=* ]]; then
    has_user_data_dir=1
  fi
  if [[ "$arg" == --version || "$arg" == --product-version ]]; then
    exec "$chrome_bin" "${args[@]}"
  fi
done

if [[ "$has_user_data_dir" -eq 0 ]]; then
  args=(--user-data-dir="$(mktemp -d /tmp/hostr_flutter_chrome_wrapper_XXXXXX)" "${args[@]}")
fi

args=(--new-window "${args[@]}")

{
  printf '\n[%s] chrome_e2e.sh launch\n' "$(date '+%Y-%m-%d %H:%M:%S')"
  printf 'binary=%s\n' "$chrome_bin"
  printf 'args='
  printf '%q ' "${args[@]}"
  printf '\n'
} >>"$log_file"

exec "$chrome_bin" \
  --disable-web-security \
  --ignore-certificate-errors \
  --disable-session-crashed-bubble \
  --hide-crash-restore-bubble \
  --noerrdialogs \
  --use-mock-keychain \
  --password-store=basic \
  "${args[@]}"
