# Tailscale & Split DNS for Local Development

## Overview

The local dev stack uses Tailscale to make services running on your dev Mac (via Docker) accessible from other devices — primarily an iPhone for real-device testing.

DNS resolution for `*.hostr.development` is handled by **dnsmasq** running on the dev Mac, with Tailscale providing the network path and split DNS routing for remote devices.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Dev Mac (100.95.205.9)                                 │
│                                                         │
│  dnsmasq ──► address=/.hostr.development/100.95.205.9   │
│     ▲                                                   │
│     │ :53                                               │
│     │                                                   │
│  Docker ──► nginx (TLS :443) ──► nostr_rs_relay         │
│              ▲                                          │
└──────────────┼──────────────────────────────────────────┘
               │ Tailscale tunnel (WireGuard)
               │
┌──────────────┼──────────┐
│  Client Device          │
│  (iPhone / other Mac)   │
│                         │
│  DNS query              │
│    ↓                    │
│  Tailscale DNS proxy    │
│  (100.100.100.100)      │
│    ↓ split DNS route    │
│  forwards to            │
│  100.95.205.9:53        │
│    ↓                    │
│  dnsmasq answers        │
│    ↓                    │
│  TCP/TLS via tunnel     │
└─────────────────────────┘
```

## DNS Resolution Paths

### Dev Mac (fast, ~1ms)

1. App/curl asks OS to resolve `relay.hostr.development`
2. macOS sees `/etc/resolver/development` → sends query to `127.0.0.1:53`
3. Local dnsmasq answers immediately from its `address=` config
4. TCP connection to `100.95.205.9` goes over Tailscale for transport

Tailscale is only involved for **transport**, not DNS.

### iPhone via Tailscale (slow cold start, ~6–20s)

1. App asks OS to resolve `relay.hostr.development`
2. iOS tries its default DNS resolvers first (ISP/Wi-Fi/cellular)
3. `.development` is not a public TLD → NXDOMAIN or timeout
4. iOS eventually falls through to Tailscale's DNS proxy (`100.100.100.100`)
5. Tailscale sees the split DNS route → forwards to `100.95.205.9:53`
6. dnsmasq answers in ~25ms
7. TCP/TLS connection via Tailscale tunnel
8. **Total wall time: 6–20s** (dominated by tunnel wake-up, not DNS)

### Simulator (fast, ~1ms)

The iOS Simulator runs on the dev Mac and uses the Mac's resolver chain. Behaves identically to "Dev Mac" path above.

### Other Mac on tailnet (depends on setup)

- **With dnsmasq installed locally** (`/etc/resolver/development` → `127.0.0.1`): will fail completely if dnsmasq isn't running on that machine. Remove `/etc/resolver/development` to let Tailscale handle it.
- **Without `/etc/resolver/development`**: uses Tailscale split DNS. Same behavior as iPhone but typically faster (macOS Tailscale daemon is less aggressively suspended than iOS Network Extension).

## Why the iPhone Cold Start is Slow

The ~6–20s delay on first connect is **not** dnsmasq or relay performance. Benchmarks show:

| Segment                           | Time       |
| --------------------------------- | ---------- |
| dnsmasq query processing          | ~25ms      |
| Tailscale LAN ping                | ~35ms      |
| TLS handshake                     | ~100–200ms |
| WebSocket upgrade                 | instant    |
| Relay query execution             | instant    |
| **iOS resolver + tunnel wake-up** | **6–20s**  |

The delay is caused by:

1. **iOS suspends the Tailscale Network Extension** to save battery. When the app launches, the extension must wake up, re-establish the WireGuard tunnel, and negotiate a direct peer path.
2. **iOS resolver fallback ordering.** The system resolver tries default DNS servers before falling through to Tailscale's split DNS proxy.
3. **DERP relay bootstrap.** Until Tailscale establishes a direct LAN path (hole-punching), traffic routes through a DERP relay server, adding latency.

The delay improves with repeated launches as Tailscale keeps more state warm:

- First launch after long idle: ~20s
- Second launch: ~11s
- Third launch: ~6s
- Warm tunnel: ~2–3s (floor = WireGuard rekey + TLS)

After extended phone idle, it resets back to ~20s.

## Configuration

### dnsmasq (on dev Mac)

Config location: `/opt/homebrew/etc/dnsmasq.conf`

Active settings (appended at end of file):

```
address=/.hostr.development/100.95.205.9
port=53
listen-address=127.0.0.1,100.95.205.9
local-ttl=300
log-queries=extra
log-facility=-
```

Key points:

- `address=/.hostr.development/...` — wildcard match for all `*.hostr.development` subdomains
- `listen-address` includes the Tailscale IP so remote devices can query it
- `local-ttl=300` — 5-minute TTL so clients cache the response (was 0 by default, which prevented any caching)
- `log-facility=-` — logs to system log (use `log stream --predicate 'process == "dnsmasq"'` to view)

### macOS resolver (on dev Mac only)

`/etc/resolver/development` contains:

```
nameserver 127.0.0.1
```

This is created by `scripts/install.sh`. It tells macOS to route all `.development` queries to local dnsmasq. **Only needed on the machine running dnsmasq.**

### Tailscale admin console

Split DNS route configured:

```
hostr.development → 100.95.205.9
```

This tells all tailnet devices to forward `*.hostr.development` DNS queries to the dev Mac's dnsmasq.

### iPhone

- Tailscale app installed with "Connect on Demand" enabled
- No special DNS configuration needed — split DNS is pushed from the tailnet admin

## Troubleshooting

### Other Mac can't resolve `relay.hostr.development`

Most likely cause: `/etc/resolver/development` exists pointing to `127.0.0.1`, but no dnsmasq is running locally.

```bash
# Check
cat /etc/resolver/development

# Fix — let Tailscale split DNS handle it
sudo rm /etc/resolver/development
```

### Verify dnsmasq is working

```bash
# Direct query to dnsmasq
dig @127.0.0.1 relay.hostr.development A

# Should return 100.95.205.9 with TTL 300
```

### Verify Tailscale split DNS

```bash
# On any tailnet device
tailscale dns status

# Should show:
# Split DNS Routes:
#   - hostr.development → 100.95.205.9
```

### Verify end-to-end (bypassing DNS)

```bash
# TLS check
openssl s_client -connect 100.95.205.9:443 -servername relay.hostr.development -brief </dev/null

# WebSocket upgrade check
curl -vk --resolve relay.hostr.development:443:100.95.205.9 \
  -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" -H "Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==" \
  https://relay.hostr.development/
```

### Watch DNS queries arrive at dnsmasq

```bash
# System log
log stream --style compact --predicate 'process == "dnsmasq"'

# Or packet capture
sudo tcpdump -ni any -tttt 'port 53 and (udp or tcp)'
```

### Restart dnsmasq after config changes

```bash
dnsmasq --test -C /opt/homebrew/etc/dnsmasq.conf
sudo brew services restart dnsmasq
```

## Production Differences

In production, none of this applies:

- Relay runs on a public server with a real domain and valid TLS certificate
- DNS is handled by a normal public DNS provider with standard TTLs
- No Tailscale, no split DNS, no tunnel wake-up delay
- Cold-start connect time will be dominated by TLS handshake (~100–200ms)

The slow iOS cold start is strictly a **dev-environment constraint** caused by the Tailscale VPN tunnel lifecycle on iOS.

## Diagnostic Experiments

### Experiment 1: Seed script broadcast isolate

**Hypothesis:** The main Dart event loop is overloaded by hundreds of parallel EVM transactions during seeding, starving NDK's WebSocket.

**Setup:** Moved NDK event broadcasting into a dedicated `Isolate` with its own event loop (`broadcast_isolate.dart`). The isolate creates its own NDK instance, connects to the relay independently, and broadcasts events received via `SendPort`/`ReceivePort`.

**Result:** ✅ Every event broadcast succeeded on **attempt #1** — zero retries. This proves the seed script failures were caused by event-loop starvation on the main isolate, not relay/DNS issues.

**Fix:** The seed pipeline now uses `BroadcastIsolate` permanently. See `hostr_sdk/bin/seed/broadcast_isolate.dart`.

### Experiment 2: App cold-start relay probe isolate

**Hypothesis:** If event-loop overload causes the seed script issue, maybe the same thing explains the ~6s cold-start delay in the Flutter app on iPhone.

**Setup:** Added a diagnostic isolate probe in `setup.dart` that spawns immediately after `configureInjection`. The isolate creates its own NDK instance in a completely separate event loop with zero contention — the main isolate does nothing (even `runApp` was removed, just a 100-second sleep).

**Result:** ❌ The probe isolate **still took 6178ms** to connect via NDK. Even with an empty main isolate and a dedicated event loop, the delay persists. This rules out event-loop overload as the cause for the app's cold-start delay.

```
[relay-probe] 01:43:36.181 Starting relay probe for wss://relay.hostr.development
[relay-probe] 01:43:36.214 NDK instance created in 32 ms
[WARNING]    timed out connecting to relay wss://relay.hostr.development
[relay-probe] 01:43:42.360 NDK relay connected in 6178 ms ✓
[relay-probe] 01:43:42.366 Probe complete.
```

**Conclusion:** The ~6s app cold-start delay on iPhone is confirmed to be a **network-level issue** (DNS resolution via Tailscale split DNS / tunnel wake-up), not Dart event-loop contention. NDK's 4s timeout fires because the underlying WebSocket connect is blocked waiting for DNS/tunnel, regardless of how idle the event loop is.

### Summary

| Symptom                         | Root cause                                  | Fix                                  |
| ------------------------------- | ------------------------------------------- | ------------------------------------ |
| Seed script broadcast failures  | Main isolate event-loop starved by EVM txns | Broadcast isolate (permanent)        |
| App cold-start ~6–20s on iPhone | iOS Tailscale tunnel wake-up + DNS          | Dev-only; production uses public DNS |
