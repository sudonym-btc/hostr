#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

ENVIRONMENT="${1:-test}"
load_managed_relay_env "$ENVIRONMENT" "$0"

REGISTER_PRIVATE_KEY_VALUE="$(relay_admin_private_key "$0")"

compose_run_rif_relay 'export RIF_RELAY_WORKDIR=/tmp/rif-relay-register && export REGISTER_GAS_PRICE=$(node <<"NODE"
const http = require(process.env.RPC_URL?.startsWith("https") ? "https" : "http");
const rpcUrl = process.env.RIF_RELAY_RSK_NODE_URL || process.env.RPC_URL;
const payload = JSON.stringify({ jsonrpc: "2.0", method: "eth_gasPrice", params: [], id: 1 });
const req = http.request(rpcUrl, {
    method: "POST",
    headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(payload),
    },
}, (res) => {
    let body = "";
    res.on("data", (chunk) => body += chunk);
    res.on("end", () => {
        const json = JSON.parse(body);
        if (!json.result) {
            console.error(body);
            process.exit(1);
        }
        const gasPrice = BigInt(json.result);
        process.stdout.write(String(gasPrice * 2n));
    });
});
req.on("error", (error) => {
    console.error(error.message);
    process.exit(1);
});
req.write(payload);
req.end();
NODE
) && /write_local_config.sh && cd /rif-relay-server && npm run register' -e REGISTER_PRIVATE_KEY="$REGISTER_PRIVATE_KEY_VALUE"
