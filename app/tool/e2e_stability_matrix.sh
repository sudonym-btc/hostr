#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

iterations="${HOSTR_STABILITY_ITERATIONS:-10}"
results_root="${HOSTR_STABILITY_RESULTS_ROOT:-/tmp/hostr_e2e_stability}"
matrix_tsv="${HOSTR_STABILITY_MATRIX_TSV:-$results_root/matrix.tsv}"
summary_txt="${HOSTR_STABILITY_SUMMARY_TXT:-$results_root/summary.txt}"
only_target="${HOSTR_STABILITY_ONLY:-}"
matrix_lock_dir="${HOSTR_STABILITY_LOCK_DIR:-/tmp/hostr_e2e_stability.lock}"

acquire_matrix_lock() {
  local attempt existing_pid
  for attempt in $(seq 1 10); do
    if mkdir "$matrix_lock_dir" 2>/dev/null; then
      printf '%s\n' "$$" > "$matrix_lock_dir/pid"
      return
    fi
    existing_pid="$(cat "$matrix_lock_dir/pid" 2>/dev/null || true)"
    if [[ -n "$existing_pid" ]] && ! kill -0 "$existing_pid" 2>/dev/null; then
      rm -rf "$matrix_lock_dir" 2>/dev/null || true
      continue
    fi
    sleep 1
  done
  printf 'ERROR: could not acquire Hostr stability matrix lock.\n'
  exit 1
}

release_matrix_lock() {
  local existing_pid
  if [[ ! -d "$matrix_lock_dir" ]]; then
    return
  fi
  existing_pid="$(cat "$matrix_lock_dir/pid" 2>/dev/null || true)"
  if [[ "$existing_pid" == "$$" ]]; then
    rm -rf "$matrix_lock_dir" 2>/dev/null || true
  fi
}

terminate_other_matrix_parents() {
  local pid
  for pid in $(pgrep -f 'bash ./tool/e2e_stability_matrix.sh|tool/e2e_stability_matrix.sh' 2>/dev/null || true); do
    if [[ "$pid" != "$$" ]]; then
      kill "$pid" 2>/dev/null || true
    fi
  done
}

cleanup_matrix_children() {
  pkill -P "$$" 2>/dev/null || true
  release_matrix_lock
}

trap cleanup_matrix_children EXIT INT TERM

acquire_matrix_lock
terminate_other_matrix_parents

mkdir -p "$results_root"
: > "$matrix_tsv"
: > "$summary_txt"

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
)

if [[ -n "$only_target" ]]; then
  targets=("$only_target")
fi

printf 'target\trun\tstatus\tsummary\tresults\tlog\n' >> "$matrix_tsv"

sanitize() {
  local value="$1"
  value="${value#integration_test/}"
  value="${value%.dart}"
  printf '%s\n' "${value//\//_}"
}

for target in "${targets[@]}"; do
  target_key="$(sanitize "$target")"
  pass_count=0
  fail_count=0
  timeout_count=0

  {
    printf '\n=== %s (%s runs) ===\n' "$target" "$iterations"
    printf 'Started: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  } | tee -a "$summary_txt"

  for run in $(seq 1 "$iterations"); do
    run_dir="$results_root/${target_key}/run_${run}"
    mkdir -p "$run_dir"
    run_summary="$run_dir/summary.txt"
    run_results="$run_dir/results.tsv"
    run_log="$run_dir/drive.log"

    rm -f "$run_summary" "$run_results" "$run_log"

    {
      printf '[%s] run %02d/%02d start %s\n' \
        "$target" "$run" "$iterations" "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    } | tee -a "$summary_txt"

    set +e
    HOSTR_DRIVE_ONLY="$target" \
    HOSTR_DRIVE_TARGET_ATTEMPTS=1 \
    HOSTR_DRIVE_SUMMARY="$run_summary" \
    HOSTR_DRIVE_RESULTS="$run_results" \
    ./tool/e2e_split.sh
    exit_code="$?"
    set -e

    cp "/tmp/hostr_drive_1_${target_key}.log" "$run_log" 2>/dev/null || true

    status="$(awk -F '\t' 'NF >= 1 {last=$1} END {print last}' "$run_results" 2>/dev/null)"
    if [[ -z "$status" ]]; then
      if [[ "$exit_code" -eq 0 ]]; then
        status="PASS"
      else
        status="FAIL"
      fi
    fi

    case "$status" in
      PASS) pass_count=$((pass_count + 1)) ;;
      TIMEOUT) timeout_count=$((timeout_count + 1)) ;;
      *) fail_count=$((fail_count + 1)) ;;
    esac

    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$target" "$run" "$status" "$run_summary" "$run_results" "$run_log" \
      >> "$matrix_tsv"

    {
      printf '[%s] run %02d/%02d => %s\n' "$target" "$run" "$iterations" "$status"
    } | tee -a "$summary_txt"
  done

  {
    printf '[%s] final: %d pass / %d fail / %d timeout / %d total\n' \
      "$target" "$pass_count" "$fail_count" "$timeout_count" "$iterations"
  } | tee -a "$summary_txt"
done

{
  printf '\n=== Aggregate ===\n'
  awk -F '\t' '
    NR == 1 { next }
    {
      total[$1]++
      if ($3 == "PASS") pass[$1]++
      else if ($3 == "TIMEOUT") timeout[$1]++
      else fail[$1]++
    }
    END {
      for (target in total) {
        printf "%s\t%d\t%d\t%d\t%d\n",
          target,
          pass[target] + 0,
          fail[target] + 0,
          timeout[target] + 0,
          total[target]
      }
    }
  ' "$matrix_tsv" | sort
} | tee -a "$summary_txt"
