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

test("listing tool responses include result-level widget metadata", async () => {
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

  assert.equal(response._meta["openai/outputTemplate"], "ui://widget/listing-card.html");
  assert.equal(response._meta["openai/widgetAccessible"], true);
  assert.deepEqual(response._meta.ui, {
    resourceUri: "ui://widget/listing-card.html",
  });
});

test("payment widget keeps waiting for long-running tool output", () => {
  assert.doesNotMatch(
    __testing.paymentRequiredWidgetHtml,
    /No external payment is required/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /document\.documentElement\.hidden = true/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /appendText\(root, "div", "loading", "\.\.\."\)/,
  );
  assert.doesNotMatch(
    __testing.paymentRequiredWidgetHtml,
    /remainingChecks/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /window\.setInterval/,
  );
  assert.match(
    __testing.paymentRequiredWidgetHtml,
    /currentToolOutput/,
  );
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

test("payment responses use the payment widget template", async () => {
  const response = await __testing.toolResponse(
    {
      publicAssetBaseUrl: "https://ai.staging.hostr.network",
      publicAppBaseUrl: "https://staging.hostr.network",
    },
    "hostr.reservations.bookAndPay",
    { ok: true, data: { message: "payment required" } },
    false,
    [{ type: "external-payment", invoice: "lnbc1test" }],
  );

  assert.equal(
    response._meta["openai/outputTemplate"],
    "ui://widget/payment-required.html",
  );
  assert.equal(
    response.structuredContent.display.type,
    "payment-external-required",
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
  assert.equal(response.structuredContent.threadCards[0].unread, true);
  assert.equal(response.structuredContent.threadCards[0].unreadCount, 3);
  assert.equal(response.structuredContent.threadCards[1].unread, false);
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
  assert.equal(
    response._meta["openai/outputTemplate"],
    "ui://widget/profile-card.html",
  );
  assert.equal(response.structuredContent.display.type, "profile-card");
  assert.equal(response.structuredContent.profileCards[0].name, "Alice Host");
});
