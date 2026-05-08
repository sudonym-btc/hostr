# Hostr Daemon

The Hostr daemon is the Dart process behind the MCP server. It is not the public HTTP service. It is a local child process that the Node MCP bridge starts and talks to over stdio.

## Entry Point

```bash
cd hostr_cli
dart run bin/hostr_daemon.dart --stdio --env development
```

The entry point is [`hostr_cli/bin/hostr_daemon.dart`](../../source/hostr_cli/bin/hostr_daemon.dart). It parses CLI options, creates a `HostrCliRuntimeContext`, and starts `HostrDaemonStdioServer`.

Important options:

| Option | Purpose |
| ------ | ------- |
| `--stdio` | Serve newline-delimited JSON requests on stdin/stdout. This is the MCP mode. |
| `--env` | Select `development`, `test`, `staging`, or `production` Hostr config. |
| `--relay` | Override the Hostr relay URL. |
| `--state-dir` | Directory for SQLite state and session/secret storage. |
| `--allow-insecure-file-secrets` | Local-only file-backed secret storage escape hatch. |

## Runtime State

`HostrCliRuntimeContext` builds the SDK runtime in [`hostr_cli/lib/src/context/hostr_cli_context.dart`](../../source/hostr_cli/lib/src/context/hostr_cli_context.dart).

It creates:

- a per-environment SQLite database at `<state-dir>/<env>.sqlite3`
- file-backed key/value storage under `<state-dir>/<env>`
- Hostr SDK config for relays, Blossom servers, escrow pubkeys, EVM config, event signing, NIP-44 crypto, and NDK
- a `HostrRuntime` that can open one foreground session or keyed sessions by pubkey

For MCP deployments the state directory is persistent:

```text
local source: docker/data/mcp-local
Docker:       /data/mcp
```

That persistence is what keeps OAuth/Nostr Connect session state useful across MCP restarts.

## Stdio Protocol

The Node bridge sends one JSON object per line:

```json
{
  "id": "1",
  "method": "callAction",
  "traceId": "trace-id",
  "params": {
    "pubkey": "optional-token-pubkey",
    "action": "hostr.listings.search",
    "input": {}
  }
}
```

The daemon writes one JSON response per line:

```json
{
  "id": "1",
  "traceId": "trace-id",
  "result": {
    "ok": true,
    "command": "hostr.listings.search",
    "environment": "development",
    "dryRun": false,
    "data": {}
  }
}
```

Errors use the same `id` with an `error` object. Notifications omit `id` and include `method` plus `params`.

The supported daemon methods are implemented in [`hostr_cli/lib/src/daemon/stdio_daemon.dart`](../../source/hostr_cli/lib/src/daemon/stdio_daemon.dart):

| Method | Purpose |
| ------ | ------- |
| `describe` | Return the action catalog used by MCP resources and generated types. |
| `visibleActions` | Return actions visible for an optional pubkey/session. |
| `callAction` | Execute a Hostr action from the generated catalog. |
| `uploadImage` | Upload image bytes through the best available Hostr/Blossom path. |
| `startOAuthNostrConnect` | Start a Nostr Connect flow for OAuth login. |
| `completeOAuthNostrConnect` | Wait for Nostr Connect approval and return the authenticated pubkey. |
| `cancel` | Cooperatively cancel an in-flight request by request id. |

## Action Execution

`HostrDaemon` in [`hostr_cli/lib/src/daemon/hostr_daemon.dart`](../../source/hostr_cli/lib/src/daemon/hostr_daemon.dart) owns action dispatch.

The daemon:

1. Looks up the action in `HostrActionCatalog`.
2. Chooses a session: public actions can run without a token, authenticated actions use `runtime.session(pubkey)`.
3. Hydrates authenticated sessions in the background when possible.
4. Validates role-specific actions, including escrow-only operations.
5. Parses typed input objects from `hostr_actions.dart`.
6. Calls Hostr SDK use cases and returns a `HostrCliResult`.

Public unauthenticated actions are intentionally narrow:

```text
hostr.listings.search
hostr.profile.lookup
```

Most read/write tools require an authenticated session. Write-style actions use `dryRun` previews where the action schema requires approval before publishing or sending.

## Cancellation and Logging

The daemon can process up to 16 requests concurrently. Each non-cancel request gets a `HostrCancellationToken`. If the Node side times out, it writes a separate `cancel` request:

```json
{
  "id": "cancel-1",
  "method": "cancel",
  "params": { "requestId": "1" }
}
```

Long-running Dart work checks the token around waits such as Nostr Connect approval, payment handoff, and reservation/swap observation.

Stdout is protocol-only. Stderr carries structured logs. Sensitive keys such as tokens, secrets, private keys, `nsec`, JWTs, QR images, and Nostr Connect URIs are redacted before logging.
