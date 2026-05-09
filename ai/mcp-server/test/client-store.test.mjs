import assert from "node:assert/strict";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {
  loadRegisteredClients,
  saveRegisteredClientsAtomic,
} from "../dist/auth/client-store.js";
import { hostrActionCatalog } from "../dist/generated/hostr-actions.js";
import { __testing } from "../dist/mcp/server.js";

test("registered OAuth clients survive an atomic save/load round trip", () => {
  const directory = fs.mkdtempSync(path.join(os.tmpdir(), "hostr-mcp-clients-"));
  const filePath = path.join(directory, "oauth-clients.json");
  const client = {
    clientId: "client-a",
    clientName: "Client A",
    redirectUris: ["https://chatgpt.com/aip/callback"],
    scope: "hostr:read hostr:write",
    grantTypes: ["authorization_code"],
    responseTypes: ["code"],
    tokenEndpointAuthMethod: "none",
    clientIdIssuedAt: 1_776_000_000,
  };

  saveRegisteredClientsAtomic(filePath, [client]);
  const loaded = loadRegisteredClients(filePath);

  assert.equal(loaded.size, 1);
  assert.deepEqual(loaded.get("client-a"), client);
  assert.equal(fs.readdirSync(directory).filter((name) => name.endsWith(".tmp")).length, 0);
});

test("missing OAuth client store loads as empty", () => {
  const loaded = loadRegisteredClients(
    path.join(os.tmpdir(), `hostr-missing-${Date.now()}.json`),
  );

  assert.equal(loaded.size, 0);
});

test("read-only Hostr MCP tools do not expose dryRun inputs", () => {
  const offenders = hostrActionCatalog
    .filter((action) => action.readOnly)
    .filter((action) => action.inputSchema?.properties?.dryRun)
    .map((action) => action.id);

  assert.deepEqual(offenders, []);
});

test("listing links use the Flutter hash route with encoded naddrs", () => {
  const naddr =
    "naddr1qq9xs6tpvyunjaesdfnsyg8mt0ed4ge0ull6wffplfr4leqf7ytzeas9ht67u54avegma27h7upsgqqq04usgezq5w";

  assert.equal(
    __testing.listingRouteUrl("https://staging.hostr.network/", naddr),
    `https://staging.hostr.network/#/listing/${naddr}`,
  );

  const naddrFromAnchor = __testing.anchorToNaddr(
    "30402:0000000000000000000000000000000000000000000000000000000000000000:listing:with:colons",
  );

  assert.match(naddrFromAnchor, /^naddr1/);
  assert.equal(
    __testing.listingRouteUrl("https://staging.hostr.network", naddrFromAnchor),
    `https://staging.hostr.network/#/listing/${naddrFromAnchor}`,
  );
});

test("trip collection lookup items render compact trip cards", () => {
  const result = {
    ok: true,
    data: {
      mode: "trips",
      count: 1,
      results: [
        {
          found: true,
          mode: "trips",
          tradeId: "trade-secret",
          group: {
            tradeId: "trade-secret",
            listingTitle: "San Salvador Modern Apartment",
            buyerPubkey: "fb5bf2daa32fe7ffa72521fa475fe409f1162cf605baf5ee52bd6651beabd7f7",
            stage: "commit",
            start: "2026-05-07T00:00:00.000Z",
            end: "2026-05-08T00:00:00.000Z",
          },
          participants: {
            profiles: {
              buyer: { name: "Staging Guest" },
            },
          },
        },
      ],
    },
  };

  const cards = __testing.reservationCardsFromResult("hostr.trips.list", result);
  const markdown = __testing.reservationCardsMarkdown(cards);

  assert.equal(cards.length, 1);
  assert.equal(cards[0].type, "trip-card");
  assert.match(markdown, /^### Trip/);
  assert.match(markdown, /\*\*Stay:\*\* San Salvador Modern Apartment/);
  assert.doesNotMatch(markdown, /trade-secret|Guest:|Status: commit/);
});

test("listing cards turn Blossom hashes into visible absolute image URLs", () => {
  const hash = "7d24fa683979cd913338f1945201382de81a4e5ead47537fde68808aaadf0908";
  const result = {
    ok: true,
    data: {
      listings: [
        {
          title: "Sunny Private Room",
          description: "GPT created this",
          type: "room",
          active: true,
          images: [hash],
          prices: [{ amount: 50000, currency: "SAT", unit: "night" }],
          specifications: { max_guests: 1, beds: 1, bathrooms: 1 },
        },
      ],
    },
  };

  const cards = __testing.listingCardsFromResult(
    {
      blossomUploadUrl: "https://blossom.staging.hostr.network/upload",
      publicAppBaseUrl: "https://staging.hostr.network",
    },
    "hostr.listings.list",
    result,
  );
  const markdown = __testing.listingCardsMarkdown(cards);

  assert.equal(cards.length, 1);
  assert.equal(
    cards[0].primaryImageUrl,
    `https://blossom.staging.hostr.network/${hash}`,
  );
  assert.match(
    markdown,
    /!\[Sunny Private Room photo 1 of 1\]\(https:\/\/blossom\.staging\.hostr\.network\//,
  );
});

test("listing cards upgrade configured Blossom image URLs to HTTPS", () => {
  const hash = "dc518f2abcd1cdce61fbc1fb95e3c12f3ee1a31457916b87e08a467e8b0f53e8";
  const result = {
    ok: true,
    data: {
      listings: [
        {
          title: "Modern Apartment in San Salvador",
          description: "A modern apartment",
          type: "room",
          active: true,
          images: [`http://blossom.hostr.network/${hash}.webp`],
        },
      ],
    },
  };

  const cards = __testing.listingCardsFromResult(
    {
      blossomUploadUrl: "https://blossom.hostr.network/upload",
      publicAppBaseUrl: "https://hostr.network",
    },
    "hostr.listings.search",
    result,
  );
  const markdown = __testing.listingCardsMarkdown(cards);

  assert.equal(
    cards[0].primaryImageUrl,
    `https://blossom.hostr.network/${hash}.webp`,
  );
  assert.match(
    markdown,
    /!\[Modern Apartment in San Salvador photo 1 of 1\]\(https:\/\/blossom\.hostr\.network\//,
  );
  assert.doesNotMatch(markdown, /http:\/\/blossom\.hostr\.network/);
});

test("listing tool responses include result-level widget context without remount template", async () => {
  const hash = "7d24fa683979cd913338f1945201382de81a4e5ead47537fde68808aaadf0908";
  const result = {
    ok: true,
    data: {
      listings: [
        {
          title: "Sunny Private Room",
          type: "room",
          active: true,
          images: [hash],
        },
      ],
    },
  };

  const response = await __testing.toolResponse(
    {
      blossomUploadUrl: "https://blossom.staging.hostr.network/upload",
      publicAppBaseUrl: "https://staging.hostr.network",
    },
    "hostr.listings.list",
    result,
    false,
  );

  assert.equal(response._meta["openai/outputTemplate"], undefined);
  assert.equal(response._meta["openai/widgetAccessible"], true);
  assert.deepEqual(response._meta.ui, {
    resourceUri: "ui://widget/listing-card.html",
  });
  assert.deepEqual(response.structuredContent.data.listings[0].images, [
    `https://blossom.staging.hostr.network/${hash}`,
  ]);
  assert.equal(
    response.structuredContent.display.cards[0].primaryImageUrl,
    `https://blossom.staging.hostr.network/${hash}`,
  );
});

test("listing tool responses normalize raw object image fields for non-widget renderers", async () => {
  const hash = "8d24fa683979cd913338f1945201382de81a4e5ead47537fde68808aaadf0908";
  const result = {
    ok: true,
    data: {
      listing: {
        title: "Modern Apartment",
        type: "room",
        active: true,
        images: [
          { url: hash, alt: "Living room" },
          { src: "https://cdn.example/photo.jpg", alt: "Kitchen" },
        ],
      },
    },
  };

  const response = await __testing.toolResponse(
    {
      blossomUploadUrl: "https://blossom.hostr.network/upload",
      publicAppBaseUrl: "https://hostr.network",
    },
    "hostr.listings.create",
    result,
    false,
  );

  assert.equal(
    response.structuredContent.data.listing.images[0].url,
    `https://blossom.hostr.network/${hash}`,
  );
  assert.equal(
    response.structuredContent.data.listing.images[1].src,
    "https://cdn.example/photo.jpg",
  );
  assert.match(
    response.structuredContent.displayMarkdown,
    /!\[Living room\]\(https:\/\/blossom\.hostr\.network\//,
  );
});

test("payment widget stays empty until it can show the QR", () => {
  assert.doesNotMatch(
    __testing.paymentRequiredWidgetHtml,
    /No external payment is required/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /document\.documentElement\.hidden = true/,
  );
  assert.doesNotMatch(__testing.paymentRequiredWidgetHtml, />\.\.\.</);
  assert.doesNotMatch(__testing.paymentRequiredWidgetHtml, /\.loading\s*\{/);
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /var remainingChecks = 80/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /window\.setInterval/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /currentToolOutput/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /function render\(output\)/,
  );
  assert.doesNotMatch(__testing.paymentRequiredWidgetHtml, /window\.parent\.postMessage/);
  assert.doesNotMatch(__testing.paymentRequiredWidgetHtml, /ui\/initialize/);
  assert.match(__testing.paymentRequiredWidgetHtml, /\[Hostr payment widget\]/);
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /__HOSTR_PAYMENT_WIDGET_DEBUG/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /var globals = detail\.globals \|\| detail;/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /hostr\.paymentDisplays/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /toolResponseMetadata/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /tool_response_metadata/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /function candidatesFromOpenAI/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /function candidatesFromMessage/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /function candidatesFromDocument/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /function candidatesFromLocation/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /window\.__OPENAI__/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /Pay this lightning invoice to continue/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /className = "copy-row"/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /navigator\.clipboard\.writeText/,
  );
  assert.doesNotMatch(__testing.paymentRequiredWidgetHtml, /toolResult/);
  assert.doesNotMatch(__testing.paymentRequiredWidgetHtml, /tool_result/);
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /window\.addEventListener\(\s+"message"/,
  );
});

test("card widgets share title subtitle and button styling hooks", () => {
  const widgetHtml = [
    __testing.listingCardWidgetHtml,
    __testing.paymentRequiredWidgetHtml,
    __testing.sessionConnectWidgetHtml,
    __testing.profileCardWidgetHtml,
    __testing.tripHostingWidgetHtml("trip"),
    __testing.tripHostingWidgetHtml("hosting"),
  ];

  for (const html of widgetHtml) {
    assert.match(html, /\.hostr-title/);
    assert.match(html, /\.hostr-subtitle/);
    assert.match(html, /\.hostr-button/);
    assert.match(html, /\.hostr-card/);
  }
});

test("widgets poll for delayed ChatGPT tool output injection", () => {
  const widgetHtml = [
    __testing.listingCardWidgetHtml,
    __testing.paymentRequiredWidgetHtml,
    __testing.sessionConnectWidgetHtml,
    __testing.profileCardWidgetHtml,
    __testing.tripHostingWidgetHtml("trip"),
    __testing.tripHostingWidgetHtml("hosting"),
  ];

  for (const html of widgetHtml) {
    assert.match(html, /window\.setInterval/);
    assert.match(html, /currentToolOutput/);
    assert.match(html, /structuredContent/);
    assert.match(html, /openai:set_globals/);
  }
});

test("card widgets stay visually empty until tool output is injected", () => {
  const widgetHtml = [
    __testing.listingCardWidgetHtml,
    __testing.sessionConnectWidgetHtml,
    __testing.profileCardWidgetHtml,
    __testing.tripHostingWidgetHtml("trip"),
    __testing.tripHostingWidgetHtml("hosting"),
  ];

  for (const html of widgetHtml) {
    assert.match(
      html,
      /if \(output === undefined \|\| output === null\) \{\s+root\.replaceChildren\(\);\s+return;\s+\}/,
    );
  }
});

test("session connect QR markdown uses short hosted asset URL", async () => {
  const response = await __testing.toolResponse(
    {
      publicAssetBaseUrl: "https://ai.staging.hostr.network",
      publicAppBaseUrl: "https://staging.hostr.network",
      qrImageUrlTemplate:
        "https://api.qrserver.com/v1/create-qr-code/?size=240x240&data={data}",
    },
    "hostr.session.connect",
    {
      ok: true,
      command: "hostr.session.connect",
      environment: "staging",
      dryRun: false,
      data: {
        pending: true,
        nostrconnect:
          "nostrconnect://0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef?relay=wss%3A%2F%2Frelay.hostr.network&secret=test",
        qrImage:
          "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=",
      },
    },
    false,
  );

  assert.match(
    response.structuredContent.displayMarkdown,
    /!\[Nostr Connect QR\]\(https:\/\/ai\.staging\.hostr\.network\/assets\/payment-qr\/[0-9a-f-]{36}\.png\)/,
  );
  assert.doesNotMatch(
    response.structuredContent.displayMarkdown,
    /api\.qrserver\.com/,
  );
  assert.match(
    response.structuredContent.display.qrImageUrl,
    /^https:\/\/ai\.staging\.hostr\.network\/assets\/payment-qr\/[0-9a-f-]{36}\.png$/,
  );
  assert.equal(
    response.content.some((part) => part.type === "image" && part.mimeType === "image/png"),
    true,
  );
});

test("payment responses include a result-bound payment widget", async () => {
  const response = await __testing.toolResponse(
    {
      publicAssetBaseUrl: "https://ai.staging.hostr.network",
      publicAppBaseUrl: "https://staging.hostr.network",
      qrImageUrlTemplate:
        "https://api.qrserver.com/v1/create-qr-code/?size=240x240&data={data}",
    },
    "hostr.reservations.bookAndPay",
    {
      ok: true,
      command: "hostr.reservations.bookAndPay",
      environment: "staging",
      dryRun: false,
      traceId: "trace-payment",
      data: {
        message: "payment required",
        mode: "book-and-pay",
        continuesInBackground: true,
        externalPayment: {
          invoice: "lnbc1test",
          tradeId: "trade-123",
          swapId: "swap-123",
          params: { noisy: true },
        },
        state: {
          state: "swap.paymentProgress",
          tradeId: "trade-123",
          swapState: {
            id: "swap-123",
            postClaimCalls: [{ data: "0xdeadbeef" }],
          },
          reservation: { id: "event-123" },
        },
        states: [{ state: "validating" }, { state: "swap.paymentProgress" }],
        nextTool: {
          name: "hostr_swaps_watch",
          arguments: {
            swapId: "swap-123",
            tradeId: "trade-123",
            reservationWaitSeconds: 300,
          },
        },
      },
    },
    false,
    [{ type: "external-payment", invoice: "lnbc1test" }],
  );

  assert.equal(
    response._meta["openai/outputTemplate"],
    "ui://widget/payment-required.html",
  );
  assert.deepEqual(response._meta.ui, {
    resourceUri: "ui://widget/payment-required.html",
  });
  assert.equal(
    response.structuredContent.display.type,
    "payment-external-required",
  );
  assert.equal(
    response.structuredContent.paymentDisplays[0].qrImageUrl,
    "https://api.qrserver.com/v1/create-qr-code/?size=240x240&data=lnbc1test",
  );
  assert.deepEqual(
    response._meta["hostr.paymentDisplays"],
    response.structuredContent.paymentDisplays,
  );
  assert.equal(response.structuredContent.status, "payment_required");
  assert.equal(response.structuredContent.stateName, "payment_required");
  assert.equal(response.structuredContent.paymentRequired, true);
  assert.equal(response.structuredContent.data.status, "payment_required");
  assert.equal(response.structuredContent.data.paymentRequired, true);
  assert.equal(response.structuredContent.data.tradeId, "trade-123");
  assert.equal(response.structuredContent.data.swapId, "swap-123");
  assert.deepEqual(response.structuredContent.data.nextTool, {
    name: "hostr_swaps_watch",
    arguments: {
      swapId: "swap-123",
      tradeId: "trade-123",
      reservationWaitSeconds: 300,
    },
  });
  assert.equal(response.structuredContent.data.state, undefined);
  assert.equal(response.structuredContent.data.states, undefined);
  assert.equal(response.structuredContent.data.externalPayment, undefined);
  assert.equal(response.structuredContent.hostrNotices, undefined);
  assert.equal(response._meta["hostr.notices"], undefined);
  assert.equal(
    response.content.some((block) => block.type === "image"),
    false,
  );
});

test("book and pay advertises the payment widget at tool registration time", () => {
  const bookAndPayMeta = __testing.reservationToolMeta(
    "hostr.reservations.bookAndPay",
  );
  assert.equal(
    bookAndPayMeta["openai/outputTemplate"],
    "ui://widget/payment-required.html",
  );
  assert.equal(
    bookAndPayMeta["hostr.preferredRenderer"],
    "payment-external-required",
  );

  const swapWatchMeta = __testing.reservationToolMeta("hostr.swaps.watch");
  assert.equal(swapWatchMeta["openai/outputTemplate"], undefined);
  assert.equal(swapWatchMeta["hostr.preferredRenderer"], "trip-card");
});

test("payment widget can read ChatGPT multimodal payment output", () => {
  assert.match(__testing.paymentRequiredWidgetHtml, /content_type === "image"/);
  assert.match(__testing.paymentRequiredWidgetHtml, /function qrFromText/);
  assert.match(__testing.paymentRequiredWidgetHtml, /Lightning invoice QR/);
  assert.match(__testing.paymentRequiredWidgetHtml, /"qrImageUrl"/);
  assert.match(__testing.paymentRequiredWidgetHtml, /Array\.isArray\(output\.parts\)/);
  assert.match(__testing.paymentRequiredWidgetHtml, /output\[key\] !== undefined/);
  assert.match(__testing.paymentRequiredWidgetHtml, /responseMetadata/);
  assert.match(__testing.paymentRequiredWidgetHtml, /metadata/);
  assert.match(__testing.paymentRequiredWidgetHtml, /function invoiceFromPayment/);
  assert.match(__testing.paymentRequiredWidgetHtml, /function invoiceFromQrUrl/);
  assert.match(__testing.paymentRequiredWidgetHtml, /function invoiceFromOutput/);
});

test("tool descriptions omit repeated boilerplate", () => {
  const description = __testing.toolDescription({
    id: "hostr.reservations.bookAndPay",
    description: [
      "Book and pay for an instant-book reservation.",
      "MCP driving notes: long common notes.",
      "Read-only behavior: common read notes.",
      "Write behavior: common write notes.",
      "Preview rule: common preview notes.",
      "Specific workflow note.",
    ].join("\n\n"),
    inputTypeName: "HostrReservationsBookAndPayInput",
  });

  assert.match(description, /Book and pay/);
  assert.match(description, /Specific workflow note/);
  assert.match(description, /May return a payment QR widget/);
  assert.doesNotMatch(description, /MCP driving notes/);
  assert.doesNotMatch(description, /Write behavior/);
  assert.doesNotMatch(description, /Full TypeScript/);
});

test("book and pay uses friendly ChatGPT annotations", () => {
  assert.deepEqual(
    __testing.toolAnnotations({
      id: "hostr.reservations.bookAndPay",
      readOnly: false,
    }),
    {
      readOnlyHint: true,
      destructiveHint: false,
      openWorldHint: false,
    },
  );
});

test("swap watch does not advertise a static payment widget", async () => {
  const response = await __testing.toolResponse(
    {
      publicAssetBaseUrl: "https://ai.staging.hostr.network",
      publicAppBaseUrl: "https://staging.hostr.network",
    },
    "hostr.swaps.watch",
    { ok: true, data: { stateName: "pending" } },
    false,
  );

  assert.equal(response._meta?.["openai/outputTemplate"], undefined);
});

test("swap watch timeout asks whether payment was sent and preserves retry args", async () => {
  const response = await __testing.toolResponse(
    {
      publicAssetBaseUrl: "https://ai.staging.hostr.network",
      publicAppBaseUrl: "https://staging.hostr.network",
    },
    "hostr.swaps.watch",
    {
      ok: true,
      command: "hostr.swaps.watch",
      data: {
        status: "payment_awaiting",
        stateName: "watch_timeout",
        paymentAwaiting: true,
        watchTimedOut: true,
        swapId: "swap-123",
        tradeId: "trade-123",
        reservationWaitSeconds: 300,
      },
    },
    false,
  );

  assert.match(
    response.structuredContent.displayMarkdown,
    /Payment is still being awaited\. Did you pay the invoice\?/,
  );
  assert.equal(response.structuredContent.status, "payment_awaiting");
  assert.equal(response.structuredContent.paymentAwaiting, true);
  assert.deepEqual(response.structuredContent.retry, {
    name: "hostr_swaps_watch",
    arguments: {
      swapId: "swap-123",
      tradeId: "trade-123",
      reservationWaitSeconds: 300,
    },
  });
  assert.match(
    response.structuredContent.assistantInstructions.join("\n"),
    /If the user replies yes/,
  );
});

test("swap watch failure is explicit and does not ask to keep polling", async () => {
  const response = await __testing.toolResponse(
    {
      publicAssetBaseUrl: "https://ai.staging.hostr.network",
      publicAppBaseUrl: "https://staging.hostr.network",
    },
    "hostr.swaps.watch",
    {
      ok: true,
      command: "hostr.swaps.watch",
      data: {
        stateName: "swap.failed",
        isTerminal: true,
        failureReason: "invoice expired",
        swapId: "swap-123",
        tradeId: "trade-123",
      },
    },
    false,
  );

  assert.match(response.structuredContent.displayMarkdown, /Swap Failed/);
  assert.match(response.structuredContent.displayMarkdown, /invoice expired/);
  assert.equal(response.structuredContent.status, "swap_failed");
  assert.equal(response.structuredContent.swapFailed, true);
  assert.doesNotMatch(
    response.structuredContent.assistantInstructions.join("\n"),
    /If the user replies yes/,
  );
});

test("updates responses omit raw inbox events and cap visible thread cards", async () => {
  const threads = Array.from({ length: 20 }, (_, index) => ({
    conversation: `trade-${index}`,
    counterparties: [{ name: `Person ${index}` }],
    unreadCount: index === 19 ? 3 : 0,
    textMessages: [
      {
        content: `Message ${index}`,
        created_at: `2026-05-${String(index + 1).padStart(2, "0")}T12:00:00Z`,
      },
    ],
  }));
  const hugeEvent = { content: "x".repeat(10_000), tags: [["p", "abc"]] };
  const response = await __testing.toolResponse(
    {
      publicAssetBaseUrl: "https://ai.staging.hostr.network",
      publicAppBaseUrl: "https://staging.hostr.network",
    },
    "hostr.updates",
    {
      ok: true,
      command: "hostr.updates",
      data: {
        count: 50,
        events: Array.from({ length: 50 }, () => hugeEvent),
        threads,
      },
    },
    false,
  );

  assert.equal(response.structuredContent.data.events, undefined);
  assert.equal(response.structuredContent.data.threads, undefined);
  assert.equal(response.structuredContent.data.threadCount, 10);
  assert.equal(response.structuredContent.data.hasMoreThreads, true);
  assert.equal(response.structuredContent.threadCards.length, 10);
  assert.equal(response.structuredContent.threadCards[0].title, "Person 19");
  assert.equal(response.structuredContent.threadCards[0].header, "Person 19 (3 Unread)");
  assert.equal(response.structuredContent.threadCards[0].unread, true);
  assert.equal(response.structuredContent.threadCards[0].unreadCount, 3);
  assert.equal(response.structuredContent.threadCards[1].unread, false);
  assert.match(response.structuredContent.displayMarkdown, /\*\*Person 19 \(3 Unread\)\*\*/);
  assert.doesNotMatch(JSON.stringify(response.structuredContent), /xxxxx/);
});

test("profile card markdown stays compact and hides internals", () => {
  const result = {
    ok: true,
    data: {
      exists: true,
      pubkey: "fb5bf2daa32fe7ffa72521fa475fe409f1162cf605baf5ee52bd6651beabd7f7",
      evmAddress: "0x2BFCDD9a2eC0D06E35eE3ab9ADE0350c0686749a",
      metadata: {
        name: "Staging Guest",
        lud16: "paco@walletofsatoshi.com",
      },
    },
  };

  const cards = __testing.profileCardsFromResult("hostr.profile.show", result);
  const markdown = __testing.profileCardsMarkdown(cards);

  assert.equal(cards.length, 1);
  assert.match(markdown, /^\*\*Staging Guest\*\*/);
  assert.match(markdown, /\*\*Lightning address:\*\* paco@walletofsatoshi\.com/);
  assert.doesNotMatch(markdown, /Pubkey|EVM|0x2BFCDD|fb5bf2|Status:/);
});

test("public profile lookup renders a compact profile widget response", async () => {
  const result = {
    ok: true,
    data: {
      exists: true,
      pubkey: "fb5bf2daa32fe7ffa72521fa475fe409f1162cf605baf5ee52bd6651beabd7f7",
      npub: "npub1lddl9k4r9lnllfe9y8aywhlyp8c3vt8kqka0tmjjh4n9r04t6lmse3s57g",
      metadata: {
        name: "Alice Host",
        about: "Sunny rooms and quiet mornings.",
        picture: "https://blossom.staging.hostr.network/alice.jpg",
        lud16: "alice@example.com",
        nip05: "alice@example.com",
      },
    },
  };

  const cards = __testing.profileCardsFromResult("hostr.profile.lookup", result);
  const markdown = __testing.profileCardsMarkdown(cards);
  const response = await __testing.toolResponse(
    {
      publicAssetBaseUrl: "https://ai.staging.hostr.network",
      publicAppBaseUrl: "https://staging.hostr.network",
    },
    "hostr.profile.lookup",
    result,
    false,
  );

  assert.equal(cards.length, 1);
  assert.equal(cards[0].name, "Alice Host");
  assert.equal(cards[0].statusLabel, "current");
  assert.match(markdown, /^\*\*Alice Host\*\*/);
  assert.match(markdown, /Sunny rooms and quiet mornings\./);
  assert.equal(response._meta["openai/outputTemplate"], undefined);
  assert.deepEqual(response._meta.ui, {
    resourceUri: "ui://widget/profile-card.html",
  });
  assert.equal(response.structuredContent.display.type, "profile-card");
  assert.equal(response.structuredContent.profileCards[0].name, "Alice Host");
});
