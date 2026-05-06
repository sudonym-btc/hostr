#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MCP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_ROOT="$(cd "${MCP_DIR}/../.." && pwd)"
NODE_BIN="${NODE_BIN:-/Applications/Codex.app/Contents/Resources/node}"

if [[ ! -x "${NODE_BIN}" ]]; then
  NODE_BIN="$(command -v node)"
fi

export PORT="${PORT:-8787}"
export DOMAIN="${DOMAIN:-hostr.development}"
export MCP_PUBLIC_BASE_URL="${MCP_PUBLIC_BASE_URL:-http://127.0.0.1:${PORT}}"
export MCP_PUBLIC_ASSET_BASE_URL="${MCP_PUBLIC_ASSET_BASE_URL:-https://ai.${DOMAIN}}"
export HOSTR_QR_IMAGE_URL_TEMPLATE="${HOSTR_QR_IMAGE_URL_TEMPLATE:-https://api.qrserver.com/v1/create-qr-code/?size=240x240&data={data}}"
export MCP_JWT_SECRET="${MCP_JWT_SECRET:-hostr-development-mcp-secret-change-me}"
export HOSTR_DAEMON_COMMAND="${HOSTR_DAEMON_COMMAND:-dart}"
export HOSTR_DAEMON_ARGS="${HOSTR_DAEMON_ARGS:-bin/hostr_daemon.dart --stdio --env development}"
export HOSTR_DAEMON_CWD="${HOSTR_DAEMON_CWD:-${REPO_ROOT}/hostr_cli}"
export HOSTR_DAEMON_STATE_DIR="${HOSTR_DAEMON_STATE_DIR:-${REPO_ROOT}/docker/data/mcp-local}"
export HOSTR_DAEMON_TIMEOUT_MS="${HOSTR_DAEMON_TIMEOUT_MS:-120000}"
export HOSTR_DAEMON_LOGS="${HOSTR_DAEMON_LOGS:-1}"
export HOSTR_DAEMON_LOG_LEVEL="${HOSTR_DAEMON_LOG_LEVEL:-trace}"
export HOSTR_DAEMON_NDK_LOG_LEVEL="${HOSTR_DAEMON_NDK_LOG_LEVEL:-trace}"

CA_BUNDLE="${REPO_ROOT}/docker/tls/ca/ca-bundle.crt"
if [[ -f "${CA_BUNDLE}" ]]; then
  export SSL_CERT_FILE="${SSL_CERT_FILE:-${CA_BUNDLE}}"
  export NODE_EXTRA_CA_CERTS="${NODE_EXTRA_CA_CERTS:-${CA_BUNDLE}}"
fi

mkdir -p "${HOSTR_DAEMON_STATE_DIR}"

cd "${MCP_DIR}"
echo "[hostr-mcp dev:local] MCP_PUBLIC_BASE_URL=${MCP_PUBLIC_BASE_URL}" >&2
echo "[hostr-mcp dev:local] HOSTR_DAEMON_COMMAND=${HOSTR_DAEMON_COMMAND}" >&2
echo "[hostr-mcp dev:local] HOSTR_DAEMON_ARGS=${HOSTR_DAEMON_ARGS}" >&2
echo "[hostr-mcp dev:local] HOSTR_DAEMON_CWD=${HOSTR_DAEMON_CWD}" >&2
echo "[hostr-mcp dev:local] HOSTR_DAEMON_STATE_DIR=${HOSTR_DAEMON_STATE_DIR}" >&2
echo "[hostr-mcp dev:local] HOSTR_DAEMON_LOGS=${HOSTR_DAEMON_LOGS} HOSTR_DAEMON_LOG_LEVEL=${HOSTR_DAEMON_LOG_LEVEL} HOSTR_DAEMON_NDK_LOG_LEVEL=${HOSTR_DAEMON_NDK_LOG_LEVEL}" >&2
echo "[hostr-mcp dev:local] compiling TypeScript before launch" >&2
"${NODE_BIN}" ./node_modules/typescript/bin/tsc -p tsconfig.json
if [[ "${HOSTR_MCP_WATCH:-0}" == "1" ]]; then
  exec "${NODE_BIN}" ./node_modules/.bin/tsx watch src/index.ts
fi

exec "${NODE_BIN}" ./node_modules/.bin/tsx src/index.ts
