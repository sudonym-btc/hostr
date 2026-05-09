# Hostr MCP Server

The Hostr MCP server exposes typed Hostr actions over MCP and delegates Hostr SDK work to the Dart `hostr-daemon`. The action catalog in `hostr_cli/lib/src/actions/hostr_actions.dart` is the source of truth for MCP tool names, input JSON schemas, generated TypeScript types, and workflow documentation.

## One-click client install

Use the hosted endpoint for AI clients that support remote HTTP MCP with OAuth:

```text
https://ai.hostr.development/mcp
```

The server advertises OAuth metadata, so clients should use their built-in OAuth/MCP login flow. Do not mint or paste tokens manually. In Codex, for example:

```sh
codex mcp add hostr https://ai.hostr.development/mcp
codex mcp login hostr
```

For local iteration against this checkout without rebuilding Docker:

```sh
codex mcp add hostr_local http://127.0.0.1:8787/mcp
codex mcp login hostr_local
```

Other clients should be pointed at the same MCP URL and allowed to complete OAuth normally.

## Runtime

Start the HTTP MCP server:

```sh
npm run build
npm start
```

Default URL:

```text
http://127.0.0.1:8787
```

For fast local iteration against real AI clients, run the source-mode server
without rebuilding the Docker image:

```sh
cd ai/mcp-server
npm run dev:local
```

This serves:

```text
http://127.0.0.1:8787/mcp
```

The Docker/proxy endpoint remains available separately at:

```text
https://ai.hostr.development/mcp
```

Use the localhost URL when testing source changes. Use the Docker URL when
testing the prod-like container path.

For foreground hot-reload while actively editing, run:

```sh
cd ai/mcp-server
HOSTR_MCP_WATCH=1 npm run dev:local
```

Health:

```text
GET /health
```

MCP endpoint:

```text
POST /mcp
```

In source/dev mode the server starts the daemon with:

```text
HOSTR_DAEMON_COMMAND=dart
HOSTR_DAEMON_ARGS="bin/hostr_daemon.dart --stdio --env development"
HOSTR_DAEMON_CWD=../hostr_cli
```

The Docker image builds a native-asset CLI bundle with `dart build cli` and runs:

```text
HOSTR_DAEMON_COMMAND=/opt/hostr-daemon/bin/hostr_daemon
HOSTR_DAEMON_CWD=/opt/hostr-daemon
```

Set `HOSTR_DAEMON_STATE_DIR=/data/mcp` (or another mounted directory) when session state must survive container restarts. Dynamic OAuth client registrations are stored atomically at `MCP_OAUTH_CLIENT_STORE_PATH`, defaulting to `$HOSTR_DAEMON_STATE_DIR/oauth-clients.json`.
Cold Dart starts can be slow in development, so MCP waits up to `HOSTR_DAEMON_TIMEOUT_MS` milliseconds per daemon request. The default is `120000`.

## Observability

All MCP HTTP, daemon-client, daemon stderr, and tool audit logs are structured JSON lines. Keep daemon stdout reserved for newline-delimited JSON responses. Every request gets an `x-trace-id`; the same trace id is propagated through HTTP, MCP tool execution, the stdio daemon request, Hostr SDK trace context, and outbound SDK HTTP calls where supported. `/health` and `/ready` include image provenance (`revision`, `created`, and `source`) when the container was built with provenance build args.

If the MCP daemon request timeout fires, the Node bridge sends a cooperative `cancel` message to the daemon. Dart work checks cancellation before and around long waits such as Nostr Connect waits, book-and-pay handoff, and reservation/swap observation. Work already inside a non-cancellable external SDK call may still finish in the background, but the request path stops waiting and logs the cancellation.

## Auth Model

MCP calls require a bearer token issued by the OAuth flow. The token `pubkey` claim selects the daemon session:

```text
runtime.session(pubkey)
```

Tool inputs must not include a pubkey. The daemon rejects authenticated write calls if the active Hostr session pubkey does not match the token pubkey.

OAuth can remain valid even when the underlying NIP-46 signer has gone offline. `hostr_session_status` reports `authenticated`, `signerOnline`, `needsReconnect`, and a `reconnect` hint. If the access token is valid but the Nostr signer session is missing, stale, or needs bunker recovery, write tools return `auth_required` with `sessionAction: "hostr_session_connect"`. The client should call `hostr_session_connect` with `wait: false`, display the returned `nostrconnect` URI or `qrImage`, then call `hostr_session_connect` with `wait: true` after the user approves the signer connection.

## MCP Resources

Clients should read these resources during setup:

```text
hostr://mcp/action-input-types
hostr://mcp/action-catalog.json
ui://widget/listing-card.html
ui://widget/payment-required.html
ui://widget/session-connect.html
ui://widget/profile-card.html
ui://widget/trip.html
ui://widget/hosting.html
```

The first resource contains TypeScript interfaces, JSON schemas, and multi-step workflow playbooks. The second is machine-readable catalog metadata. The `ui://widget/*` resources are optional lightweight MCP Apps HTML renderers for listing cards, Lightning payment QR prompts, Nostr Connect session QR prompts, profile cards, trips, and hosting cards.

Regenerate the TypeScript catalog after editing Dart actions:

```sh
cd hostr_cli
dart run bin/generate_mcp_types.dart /path/to/hostr
```

## Tools

```text
hostr_session_status
hostr_session_connect
hostr_session_accounts
hostr_session_switch
hostr_session_logout
hostr_listings_search
hostr_listings_list
hostr_listings_create
hostr_listings_edit
hostr_listings_availability
hostr_listings_reviews
hostr_listings_reservationGroups
hostr_reservations_negotiateOffer
hostr_reservations_negotiateAccept
hostr_reservations_pay
hostr_reservations_commit
hostr_reservations_cancel
hostr_updates
hostr_thread_view
hostr_thread_message
hostr_escrow_involve
hostr_profile_show
hostr_profile_edit
hostr_trips_list
hostr_bookings_list
hostr_escrow_methods
hostr_swaps_watch
hostr_swaps_recoverAll
hostr_swaps_list
```

Write tools default to preview mode. The app or AI client should call the tool once with `dryRun: true`, show the returned preview to the user, then call again with `dryRun: false` only after explicit approval.

There are no legacy `publish` or `broadcast` write parameters. Every write-style MCP action uses `dryRun`.

## Money units

When a user or listing says `sats`, it means satoshis, not dollars, cents, or whole bitcoin. One sat is exactly `1/100,000,000 BTC`.

For Hostr MCP monetary inputs in sats, use:

```json
{
  "value": "50000",
  "currency": "BTC",
  "unit": "sats",
  "decimals": 0
}
```

The `value` is the satoshi count as a string. Do not convert `50000 sats` to `50000 BTC`, `50000 USD`, or `0.0005` unless the receiving field explicitly asks for BTC decimal notation instead of `unit: "sats"`.

## Image uploads

Remote clients that need to attach user-provided images must upload the original image bytes beside MCP, not inside the JSON-RPC `/mcp` request:

Preferred MCP tool flow:

```text
hostr_images_upload({ file: <file-typed uploaded image> })
  -> structuredContent.usage.image.url

hostr_listings_create({ images: [{ url: structuredContent.usage.image.url }] })

hostr_profile_edit({ image: structuredContent.usage.image.url })
```

The upload response is intentionally generic. `hostr_images_upload` does not know whether the image will be used for a listing, profile, badge, or another image field; callers should use `structuredContent.usage.image.url` or `structuredContent.upload.url` wherever a durable image URL is required.

The `hostr_images_upload` schema marks `file` as `type: "file"` and advertises `_meta["openai/fileParams"] = ["file"]` so clients that support file rewrite/upload handling can stream the original attached file. If a client represents uploaded files as local references such as `/mnt/data/photo.jpg`, those references belong only in the file-typed `hostr_images_upload.file` argument so Hostr can read/download the original bytes and re-upload them to Blossom; never put them directly in listing `images[].url` or profile `image`/`picture`.

Fallback raw HTTP flow for clients that can make HTTP requests:

```text
POST /mcp/uploads/images
Content-Type: multipart/form-data
field: file=<original image file>
```

The endpoint also accepts raw image bytes with an `image/*` or `application/octet-stream` content type. It does not require MCP OAuth, Nostr auth, or a Hostr foreground session, but when a valid MCP bearer token is present it first tries the logged-in Hostr session's Blossom upload path before falling back to the server's direct Blossom upload endpoint. The fallback uploads the original bytes to Blossom with no Authorization header, so the configured Blossom `PUT /upload` endpoint must also allow unauthenticated uploads. The response includes `upload.url`, `sha256`, `size`, and MIME metadata. Pass the returned `upload.url` as `images[].url` to `hostr_listings_create`, or as `image`/`picture` to `hostr_profile_edit`; the MCP listing and profile tools advertise image URLs only.

Do not base64-encode user-uploaded images into `hostr_listings_create` or `hostr_profile_edit`. Do not serve a temporary localhost URL for Hostr to fetch; localhost points at the wrong machine/container for remote MCP. Do not pass client-local paths such as `/mnt/data`, `/mnt/shared`, or `file://` URLs to listing `images[].url` or profile `image`/`picture`. Do not resize, downscale, crop, recompress, transcode, or create thumbnails unless the user explicitly asks for that. If neither `hostr_images_upload` nor the upload POST can be used, stop and ask for a public image URL or for the client to expose an upload capability.

## Workflow driving

Agents should use the workflow docs from `hostr://mcp/action-input-types`, but these are the intended command sequences:

- New listing: call `hostr_profile_edit` if profile details need updating, then `hostr_listings_create` with `dryRun: true`, show the preview, and repeat with `dryRun: false` only after approval. The live listing path ensures seller config is published.
- Edit listing: call `hostr_listings_edit` with `dryRun: true`, review the returned listing/event preview, then repeat with `dryRun: false`.
- Search and reserve: call `hostr_listings_search`, then `hostr_listings_availability`, then `hostr_reservations_negotiateOffer` with `dryRun: true`; repeat with `dryRun: false` to send the private negotiate-stage reservation DM.
- Negotiation: call `hostr_updates` to inspect thread/trade ids. Use `hostr_reservations_negotiateOffer` with `tradeId` and `amount` to send a follow-up offer, `hostr_reservations_negotiateAccept` to accept the latest offer, or `hostr_reservations_cancel` to cancel the private negotiation or committed reservation.
- Payment: for normal instant-book payment, call `hostr_reservations_bookAndPay`. After showing the returned QR/invoice, call the read-only `hostr_swaps_watch` with `swapId`, `tradeId`, and `reservationWaitSeconds`; it has no `dryRun` parameter and does not require approval. Use `hostr_swaps_recoverAll` only for explicit manual recovery/debug flows.
- Messaging: call `hostr_updates`, choose recipient pubkeys from the thread/trade, call `hostr_thread_message` with `dryRun: true`, then repeat with `dryRun: false`.
- Listing management/profile/trips/bookings: call `hostr_listings_list` to inspect listing inventory, `hostr_profile_show` to inspect the current profile, `hostr_profile_edit` to preview/publish profile changes, `hostr_trips_list` for guest-side reservations, and `hostr_bookings_list` for reservations on listings authored by the authenticated user.
- Escrow compatibility: call `hostr_escrow_methods` with a seller pubkey before payment when the agent needs to explain compatible escrow services or ask the user to choose a non-default service.
- Swaps: call `hostr_swaps_list`, then `hostr_swaps_watch` for a specific swap id, and `hostr_swaps_recoverAll` when stale operations need recovery.

## Chat presentation

MCP cannot force every AI client to render native UI cards. The server returns both structured data and Markdown text content. Listing search responses include image-carousel Markdown for each listing:

```md
### Listing Title

**Image carousel:** 3 images

![Listing image 1](https://...)
![Listing image 2](https://...)
![Listing image 3](https://...)
```

Clients that support rich MCP cards can build cards from `structuredContent.listingCards[*]`. Clients that only render Markdown will still show listing sections with inline images.

Listing tools also advertise `ui://widget/listing-card.html` through `_meta.ui.resourceUri`, with `_meta["openai/outputTemplate"]` as the ChatGPT compatibility alias. The widget is intentionally just HTML/CSS/vanilla JS; it reads `window.openai.toolOutput.listingCards` or `window.openai.toolOutput.display.cards` and renders cards. Do not put business logic in it. Keep `structuredContent.listingCards` and `displayMarkdown` as the portable source of truth.

The same optional widget pattern is used for:

- `ui://widget/payment-required.html`: reads `structuredContent.paymentDisplays` or `structuredContent.display.cards` for external Lightning payment QR prompts.
- `ui://widget/session-connect.html`: reads `structuredContent.display` for Nostr Connect login QR prompts.
- `ui://widget/profile-card.html`: reads `structuredContent.profileCards` or `structuredContent.display.cards` for profile show/edit results.
- `ui://widget/trip.html`: reads `structuredContent.tripCards`, `structuredContent.reservationCards`, or `structuredContent.display.cards` for guest trips. Cancelled trips render a bold `Cancelled` marker.
- `ui://widget/hosting.html`: reads `structuredContent.hostingCards`, `structuredContent.reservationCards`, or `structuredContent.display.cards` for host-side reservations, including `Hosting {guest} at: {stay}` text.

All widgets are examples. Generic MCP clients can ignore the UI resources and continue rendering `displayMarkdown` or structured JSON.

## Verification

Run these checks before deploying:

```sh
cd hostr_cli
dart test test/unit/hostr_actions_test.dart
dart analyze lib/src/actions/hostr_actions.dart lib/src/daemon/hostr_daemon.dart

cd ../ai/mcp-server
npm run build
```
