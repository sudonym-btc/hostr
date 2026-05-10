# ChatGPT App Submission Prep

This checklist is scoped to making the production Hostr MCP server review-ready for the ChatGPT Apps Directory.

## Production Connector

- App name: `Hostr`
- MCP URL: `https://ai.hostr.network/mcp`
- Health URL: `https://ai.hostr.network/health`
- Readiness URL: `https://ai.hostr.network/ready`
- Auth: OAuth through the MCP server metadata
- Public app URL: `https://hostr.network`
- Privacy policy URL: `https://hostr.network/privacy/`
- Terms of service URL: `https://hostr.network/terms/`
- Image/upload origin: `https://blossom.hostr.network`
- Payment assets origin: `https://ai.hostr.network`

## Codex Marketplace

Production testers can add the public Hostr Codex marketplace from the default `main` branch:

```sh
codex plugin marketplace add sudonym-btc/hostr-codex
```

The `main` branch exposes only `hostr-production`. The `development` branch exposes `hostr-development`, `hostr-staging`, and `hostr-production` for local debugging:

```sh
codex plugin marketplace add sudonym-btc/hostr-codex@development
```

This monorepo pins the marketplace repo as a submodule at `ai/codex-marketplace` on the `development` branch.

## OpenAI Dashboard Fields

The submission form asks for:

- App name, logo, short description, and long description.
- Company/developer name under a verified OpenAI organization.
- Public website URL.
- Privacy policy URL.
- Terms of service URL.
- MCP URL and OAuth credentials, if OAuth is selected.
- Tool information and action-label justifications.
- Screenshots.
- Test prompts and expected responses.
- Localization/country availability details.

Privacy policy source: `app/web/privacy/index.html`.
Terms source: `app/web/terms/index.html`.

## Suggested Store Copy

Short description:

> Find and book places to stay on Hostr, a Nostr-based accommodation marketplace with Lightning and escrow-backed payments.

Long description:

> Hostr lets ChatGPT help guests search accommodation listings, check availability, start reservations, monitor payment status, and manage trips or hosting workflows through Hostr's Nostr marketplace. Users can connect a Nostr signer, manage listings, upload listing images, message about stays, and use Hostr's escrow-aware payment flow. Write actions are previewed where supported and should only be published or sent after explicit user approval.

## Golden Prompts

Use these in ChatGPT developer mode on web and mobile before submitting:

1. `Find me a place to stay in San Salvador`
   Expected: calls `hostr_listings_search`; shows listing cards with images; no login required if public search is available.

2. `Show availability for this listing from August 1 to August 3`
   Expected: calls `hostr_listings_availability`; preserves date-only values as `2026-08-01T00:00:00Z` style values when dates are in 2026.

3. `Book this instant-book stay for two nights`
   Expected: asks for missing listing/date/price details if needed; calls `hostr_reservations_bookAndPay` only after intent is concrete; if payment is required, shows only the QR/invoice to the user and then calls `hostr_swaps_watch`.

4. `Create a listing for my spare room`
   Expected: asks for missing required fields; uploads images through `hostr_images_upload`; previews with `hostr_listings_create` and `dryRun: true`; does not publish until explicit approval.

5. `Message the host that I will arrive late`
   Expected: identifies the relevant thread/trade; previews with `hostr_thread_message` and `dryRun: true`; sends only after explicit approval.

6. `Cancel my reservation`
   Expected: identifies the reservation, previews cancellation, and treats the live action as destructive.

7. `What happens when I send money?`
   Expected: explains that Hostr swaps the payment over Lightning into smart-contract escrow, and that escrow can only settle according to the trade outcome.

8. `Search Airbnb for a hotel in Paris`
   Expected: does not call Hostr unless the user wants Hostr listings.

## Tool Annotation Justifications

- Read-only search/list/status tools set `readOnlyHint: true`.
- Non-destructive writes such as listing creation previews, signer connect, thread messages, negotiation offers, and starting reservation payment set `readOnlyHint: false`, `destructiveHint: false`, and `openWorldHint: false`.
- Destructive or irreversible writes such as listing/profile edits, payment/commit/cancel, escrow arbitration, service deletion, badge deletion/revocation, and swap recovery set `destructiveHint: true`.
- `hostr_images_upload` is non-destructive but uses `openWorldHint: true` because it uploads a user-provided file to a public Blossom media endpoint.

## Review Risks To Clear

- Deploy the static privacy policy at `https://hostr.network/privacy/` and confirm the URL is reachable after the next web build.
- Deploy the static terms page at `https://hostr.network/terms/` and confirm the URL is reachable after the next web build.
- Prepare a fully featured demo account that does not require MFA, SMS, email verification, or manual out-of-band setup during review.
- Confirm `https://ai.hostr.network/mcp` is reachable from outside your network and that OAuth dynamic client registration works.
- Capture screenshots from ChatGPT web and mobile for listing search, Nostr connect, payment QR, trip card, and listing preview.
- Keep CSP domains exact for widgets: production uses `https://ai.hostr.network`, `https://hostr.network`, `https://blossom.hostr.network`, and the QR image origin if `HOSTR_QR_IMAGE_URL_TEMPLATE` is enabled.
