import assert from "node:assert/strict";
import crypto from "node:crypto";
import fs from "node:fs";
import http from "node:http";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { jwtVerify } from "jose";
import { signAccessToken, verifyAccessToken } from "../dist/auth/jwt.js";
import { McpSessionStore } from "../dist/auth/session-store.js";
import { createApp } from "../dist/http/app.js";

const testConfig = (directory) => ({
  issuer: "http://127.0.0.1:9999",
  mcpResource: "http://127.0.0.1:9999/mcp",
  publicAssetBaseUrl: "http://127.0.0.1:9999",
  publicAppBaseUrl: "https://hostr.test",
  environmentLabel: "development",
  displayName: "Hostr Test",
  port: 0,
  requestBodyLimit: "1mb",
  blossomUploadUrl: "https://blossom.hostr.network/upload",
  oauthClientStorePath: path.join(directory, "oauth-clients.json"),
  jwtSecret: new TextEncoder().encode("test-secret"),
  accessTokenTtlSeconds: 3600,
  refreshTokenTtlSeconds: 2_592_000,
  hostrDaemon: {
    command: "node",
    args: [],
    cwd: ".",
    env: {},
  },
  hostrDaemonTimeoutMs: 1000,
});

const tempDirectory = () =>
  fs.mkdtempSync(path.join(os.tmpdir(), "hostr-mcp-session-test-"));

test("JWT access tokens bind to an MCP session id, not a pubkey", async () => {
  const config = testConfig(tempDirectory());
  const token = await signAccessToken(
    config,
    "session-id-1",
    "hostr:read hostr:write",
  );

  const claims = await verifyAccessToken(config, token);
  const { payload } = await jwtVerify(token, config.jwtSecret, {
    issuer: config.issuer,
    audience: config.mcpResource,
  });

  assert.equal(claims.sessionId, "session-id-1");
  assert.equal(claims.sub, "session-id-1");
  assert.equal(payload.sid, "session-id-1");
  assert.equal(payload.sub, "session-id-1");
  assert.equal(payload.pubkey, undefined);
});

test("MCP session store keeps multiple accounts and a mutable active pubkey", () => {
  const config = testConfig(tempDirectory());
  const store = new McpSessionStore(config.oauthClientStorePath);

  store.addOrUpdateAccount({
    sessionId: "session-id-1",
    pubkey: "pubkey-1",
    metadata: { name: "One" },
  });
  store.addOrUpdateAccount({
    sessionId: "session-id-1",
    pubkey: "pubkey-2",
    metadata: { name: "Two" },
  });

  assert.equal(store.get("session-id-1").activePubkey, "pubkey-2");
  assert.deepEqual(
    store.get("session-id-1").accounts.map((account) => account.pubkey),
    ["pubkey-1", "pubkey-2"],
  );

  store.switchActive("session-id-1", "pubkey-1");
  assert.equal(store.get("session-id-1").activePubkey, "pubkey-1");

  store.removeAccount("session-id-1", "pubkey-1");
  assert.equal(store.get("session-id-1").activePubkey, "pubkey-2");

  const persisted = JSON.parse(
    fs.readFileSync(
      path.join(path.dirname(config.oauthClientStorePath), "mcp-sessions.json"),
      "utf8",
    ),
  );
  assert.deepEqual(persisted.sessions[0].accounts.map((account) => account.pubkey), [
    "pubkey-2",
  ]);
});

test("ordinary Hostr tools are discoverable without MCP OAuth", async () => {
  const directory = tempDirectory();
  const config = testConfig(directory);
  const calls = [];
  const daemon = {
    visibleActions: async () => {
      calls.push(["visibleActions"]);
      return { visibleActionIds: [] };
    },
    callAction: async ({ action }) => {
      calls.push(["callAction", action]);
      return {
        ok: true,
        command: action,
        environment: "test",
        dryRun: false,
        data: {},
      };
    },
    logoutSession: async () => ({ ok: true }),
    uploadImage: async () => ({
      ok: true,
      command: "hostr.upload.image",
      environment: "test",
      dryRun: false,
      data: {},
    }),
    onNotification: () => () => {},
  };

  const client = await startMcpClient(config, daemon);
  try {
    const tools = await client.call("tools/list");
    assert.equal(hasTool(tools, "hostr_session_status"), true);
    assert.equal(hasTool(tools, "hostr_session_connect"), true);
    assert.equal(hasTool(tools, "hostr_listings_create"), true);
    assert.equal(hasTool(tools, "hostr_profile_edit"), true);
    assert.equal(hasTool(tools, "hostr_escrow_service_edit"), false);
    assert.equal(hasTool(tools, "hostr_session_accounts"), false);

    const status = await client.call("tools/call", {
      name: "hostr_session_status",
      arguments: { includeStorageDetails: true },
    });
    assert.deepEqual(status.result.structuredContent, {
      mcpAuthenticated: false,
      accountCount: 0,
      authenticated: false,
      signerOnline: false,
      needsReconnect: false,
      storage: { accountPubkeys: [] },
    });

    const createListing = await client.call("tools/call", {
      name: "hostr_listings_create",
      arguments: {
        title: "Test Room",
        description: "A test listing.",
        address: "San Salvador, El Salvador",
        images: [{ url: "https://example.com/listing.jpg" }],
        prices: [
          {
            amount: {
              value: "1000",
              currency: "BTC",
              unit: "sats",
              decimals: 0,
            },
            frequency: "daily",
          },
        ],
      },
    });
    assert.equal(createListing.result.isError, true);
    assert.equal(createListing.result.structuredContent.ok, false);
    assert.equal(
      createListing.result.structuredContent.errors[0].code,
      "auth_required",
    );
    assert.deepEqual(calls, []);
  } finally {
    await client.close();
  }
});

test("stale MCP transport sessions return recoverable session-not-found errors", async () => {
  const config = testConfig(tempDirectory());
  const daemon = {
    visibleActions: async () => ({ visibleActionIds: [] }),
    callAction: async ({ action }) => ({
      ok: true,
      command: action,
      environment: "test",
      dryRun: false,
      data: {},
    }),
    logoutSession: async () => ({ ok: true }),
    uploadImage: async () => ({
      ok: true,
      command: "hostr.upload.image",
      environment: "test",
      dryRun: false,
      data: {},
    }),
    onNotification: () => () => {},
  };
  const server = await startHttpServer(config, daemon);
  const initializeRequest = (id) => ({
    jsonrpc: "2.0",
    id,
    method: "initialize",
    params: {
      protocolVersion: "2025-06-18",
      capabilities: {},
      clientInfo: { name: "hostr-stale-session-test", version: "1.0.0" },
    },
  });

  try {
    const initialized = await requestText(server, "/mcp", {
      method: "POST",
      headers: { accept: "application/json, text/event-stream" },
      body: initializeRequest(1),
    });
    assert.equal(initialized.status, 200, initialized.text);
    assert.ok(initialized.headers.get("mcp-session-id"));

    const stale = await requestJson(server, "/mcp", {
      method: "POST",
      headers: {
        accept: "application/json, text/event-stream",
        "mcp-session-id": "stale-session-id",
      },
      body: { jsonrpc: "2.0", id: 99, method: "tools/list" },
    });
    assert.equal(stale.status, 404);
    assert.equal(stale.body.id, 99);
    assert.equal(stale.body.error.code, -32001);
    assert.equal(stale.body.error.message, "Session not found");

    const reinitialized = await requestText(server, "/mcp", {
      method: "POST",
      headers: {
        accept: "application/json, text/event-stream",
        "mcp-session-id": "stale-session-id",
      },
      body: initializeRequest(100),
    });
    assert.equal(reinitialized.status, 200, reinitialized.text);
    assert.ok(reinitialized.headers.get("mcp-session-id"));
    assert.notEqual(
      reinitialized.headers.get("mcp-session-id"),
      "stale-session-id",
    );
  } finally {
    await server.close();
  }
});

test("OAuth authorization code exchange issues rotating refresh tokens", async () => {
  const directory = tempDirectory();
  const config = testConfig(directory);
  const daemon = {
    startOAuthNostrConnect: async ({ requestId }) => ({
      ok: true,
      command: "hostr.session.connect",
      environment: "test",
      dryRun: false,
      data: {
        nostrconnect: `nostrconnect://test?request=${requestId}`,
        qrImage: "data:image/png;base64,test",
      },
    }),
    completeOAuthNostrConnect: async () => ({
      ok: true,
      command: "hostr.session.connect",
      environment: "test",
      dryRun: false,
      data: { pubkey: "pubkey-refresh" },
    }),
    visibleActions: async () => ({ visibleActionIds: [] }),
    callAction: async ({ action }) => ({
      ok: true,
      command: action,
      environment: "test",
      dryRun: false,
      data: {},
    }),
    logoutSession: async () => ({ ok: true }),
    uploadImage: async () => ({
      ok: true,
      command: "hostr.upload.image",
      environment: "test",
      dryRun: false,
      data: {},
    }),
    onNotification: () => () => {},
  };

  const server = await startHttpServer(config, daemon);
  try {
    const redirectUri = "http://127.0.0.1/callback";
    const registered = await requestJson(server, "/oauth/register", {
      method: "POST",
      body: {
        client_name: "Refresh Test",
        redirect_uris: [redirectUri],
        grant_types: ["authorization_code", "refresh_token"],
        response_types: ["code"],
        token_endpoint_auth_method: "none",
        scope: "hostr:read hostr:write",
      },
    });
    assert.equal(registered.status, 201);
    assert.deepEqual(registered.body.grant_types, [
      "authorization_code",
      "refresh_token",
    ]);

    const verifier = "a".repeat(43);
    const challenge = crypto
      .createHash("sha256")
      .update(verifier)
      .digest("base64url");
    const authorize = await requestText(
      server,
      `/oauth/authorize?${new URLSearchParams({
        response_type: "code",
        client_id: registered.body.client_id,
        redirect_uri: redirectUri,
        scope: "hostr:read hostr:write",
        code_challenge: challenge,
        code_challenge_method: "S256",
      })}`,
    );
    assert.equal(authorize.status, 200);
    const requestIdMatch = /const requestId = "([^"]+)"/.exec(authorize.text);
    assert.ok(requestIdMatch, authorize.text);

    const completed = await requestJson(
      server,
      "/oauth/nostr-connect/complete",
      {
        method: "POST",
        body: { request_id: requestIdMatch[1] },
      },
    );
    assert.equal(completed.status, 200);
    const code = new URL(completed.body.redirectUrl).searchParams.get("code");
    assert.ok(code);

    const token = await requestJson(server, "/oauth/token", {
      method: "POST",
      body: {
        grant_type: "authorization_code",
        code,
        redirect_uri: redirectUri,
        client_id: registered.body.client_id,
        code_verifier: verifier,
      },
    });
    assert.equal(token.status, 200);
    assert.equal(token.body.token_type, "Bearer");
    assert.equal(token.body.expires_in, config.accessTokenTtlSeconds);
    assert.equal(typeof token.body.refresh_token, "string");
    const initialClaims = await verifyAccessToken(config, token.body.access_token);
    assert.equal(initialClaims.sessionId.length > 0, true);

    const refreshed = await requestJson(server, "/oauth/token", {
      method: "POST",
      body: {
        grant_type: "refresh_token",
        refresh_token: token.body.refresh_token,
        client_id: registered.body.client_id,
      },
    });
    assert.equal(refreshed.status, 200);
    assert.equal(typeof refreshed.body.access_token, "string");
    assert.equal(typeof refreshed.body.refresh_token, "string");
    assert.notEqual(refreshed.body.refresh_token, token.body.refresh_token);
    const refreshedClaims = await verifyAccessToken(
      config,
      refreshed.body.access_token,
    );
    assert.equal(refreshedClaims.sessionId, initialClaims.sessionId);

    const replay = await requestJson(server, "/oauth/token", {
      method: "POST",
      body: {
        grant_type: "refresh_token",
        refresh_token: token.body.refresh_token,
        client_id: registered.body.client_id,
      },
    });
    assert.equal(replay.status, 400);
    assert.equal(replay.body.error, "invalid_grant");

    const familyRevoked = await requestJson(server, "/oauth/token", {
      method: "POST",
      body: {
        grant_type: "refresh_token",
        refresh_token: refreshed.body.refresh_token,
        client_id: registered.body.client_id,
      },
    });
    assert.equal(familyRevoked.status, 400);
    assert.equal(familyRevoked.body.error, "invalid_grant");
  } finally {
    await server.close();
  }
});

test("OAuth authorization page can complete login with nsec", async () => {
  const directory = tempDirectory();
  const config = testConfig(directory);
  const calls = [];
  const daemon = {
    startOAuthNostrConnect: async ({ requestId }) => ({
      ok: true,
      command: "hostr.session.connect",
      environment: "test",
      dryRun: false,
      data: {
        nostrconnect: `nostrconnect://test?request=${requestId}`,
        qrImage: "data:image/png;base64,test",
      },
    }),
    completeOAuthNsec: async ({ requestId, nsec }) => {
      calls.push(["completeOAuthNsec", requestId, nsec]);
      return {
        ok: true,
        command: "oauth.nsec.complete",
        environment: "test",
        dryRun: false,
        data: { pubkey: "pubkey-nsec", credentialType: "private_key" },
      };
    },
    visibleActions: async () => ({ visibleActionIds: [] }),
    callAction: async ({ action }) => ({
      ok: true,
      command: action,
      environment: "test",
      dryRun: false,
      data: {},
    }),
    logoutSession: async () => ({ ok: true }),
    uploadImage: async () => ({
      ok: true,
      command: "hostr.upload.image",
      environment: "test",
      dryRun: false,
      data: {},
    }),
    onNotification: () => () => {},
  };

  const server = await startHttpServer(config, daemon);
  try {
    const redirectUri = "http://127.0.0.1/callback";
    const registered = await requestJson(server, "/oauth/register", {
      method: "POST",
      body: {
        client_name: "Nsec Test",
        redirect_uris: [redirectUri],
        grant_types: ["authorization_code"],
        response_types: ["code"],
        token_endpoint_auth_method: "none",
        scope: "hostr:read hostr:write",
      },
    });
    assert.equal(registered.status, 201);

    const verifier = "b".repeat(43);
    const challenge = crypto
      .createHash("sha256")
      .update(verifier)
      .digest("base64url");
    const authorize = await requestText(
      server,
      `/oauth/authorize?${new URLSearchParams({
        response_type: "code",
        client_id: registered.body.client_id,
        redirect_uri: redirectUri,
        scope: "hostr:read hostr:write",
        code_challenge: challenge,
        code_challenge_method: "S256",
      })}`,
    );
    assert.equal(authorize.status, 200);
    assert.match(authorize.text, /id="nsec"/);
    assert.match(authorize.text, /\/oauth\/nsec\/complete/);
    const requestIdMatch = /const requestId = "([^"]+)"/.exec(authorize.text);
    assert.ok(requestIdMatch, authorize.text);

    const nsec =
      "nsec1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqq";
    const completed = await requestJson(server, "/oauth/nsec/complete", {
      method: "POST",
      body: { request_id: requestIdMatch[1], nsec },
    });
    assert.equal(completed.status, 200);
    assert.deepEqual(calls, [["completeOAuthNsec", requestIdMatch[1], nsec]]);
    const code = new URL(completed.body.redirectUrl).searchParams.get("code");
    assert.ok(code);

    const token = await requestJson(server, "/oauth/token", {
      method: "POST",
      body: {
        grant_type: "authorization_code",
        code,
        redirect_uri: redirectUri,
        client_id: registered.body.client_id,
        code_verifier: verifier,
      },
    });
    assert.equal(token.status, 200);
    const claims = await verifyAccessToken(config, token.body.access_token);
    const session = new McpSessionStore(config.oauthClientStorePath).get(
      claims.sessionId,
    );
    assert.equal(session.activePubkey, "pubkey-nsec");
  } finally {
    await server.close();
  }
});

test("MCP session tools connect, list, switch, and logout backend accounts", async () => {
  const directory = tempDirectory();
  const config = testConfig(directory);
  const calls = [];
  const traceIds = [];
  const connectedPubkeys = ["pubkey-1", "pubkey-2"];

  let connectCount = 0;
  const daemon = {
    visibleActions: async ({ pubkey, traceId }) => {
      traceIds.push(["visibleActions", traceId]);
      calls.push(["visibleActions", pubkey]);
      return {
        visibleActionIds: [
          "hostr.session.status",
          "hostr.session.connect",
          "hostr.listings.list",
          "hostr.thread.message",
          "hostr.escrow.service.edit",
        ],
      };
    },
    callAction: async ({ pubkey, action, input, traceId }) => {
      traceIds.push(["callAction", traceId]);
      calls.push(["callAction", pubkey, action, input]);
      if (action === "hostr.session.connect") {
        const connected = connectedPubkeys[connectCount++];
        return {
          ok: true,
          command: action,
          environment: "test",
          dryRun: false,
          data: { authenticated: true, pubkey: connected },
        };
      }
      if (action === "hostr.profile.show") {
        if (pubkey === "pubkey-1" && connectCount >= 2) {
          return {
            ok: false,
            command: action,
            environment: "test",
            dryRun: false,
            errors: [{ code: "auth_required", message: "stale signer" }],
          };
        }
        return {
          ok: true,
          command: action,
          environment: "test",
          dryRun: false,
          data: {
            pubkey,
            npub: `npub-${pubkey}`,
            metadata: { name: `Name ${pubkey}` },
          },
        };
      }
      if (action === "hostr.session.status") {
        return {
          ok: true,
          command: action,
          environment: "test",
          dryRun: false,
          data: {
            authenticated: true,
            signerOnline: pubkey === "pubkey-2",
            reconnect: pubkey === "pubkey-1",
          },
        };
      }
      return {
        ok: true,
        command: action,
        environment: "test",
        dryRun: false,
        data: {},
      };
    },
    logoutSession: async ({ pubkey, traceId }) => {
      traceIds.push(["logoutSession", traceId]);
      calls.push(["logoutSession", pubkey]);
      return {
        ok: true,
        command: "hostr.session.logout",
        environment: "test",
        dryRun: false,
        data: { pubkey, signedOut: true },
      };
    },
    uploadImage: async () => ({
      ok: true,
      command: "hostr.upload.image",
      environment: "test",
      dryRun: false,
      data: {},
    }),
    onNotification: () => () => {},
  };

  const token = await signAccessToken(
    config,
    "session-id-1",
    "hostr:read hostr:write",
  );
  const client = await startMcpClient(config, daemon, token);
  try {
    const initialTools = await client.call("tools/list");
    assert.equal(hasTool(initialTools, "hostr_session_status"), true);
    assert.equal(hasTool(initialTools, "hostr_session_connect"), true);
    assert.equal(hasTool(initialTools, "hostr_session_accounts"), true);
    assert.equal(hasTool(initialTools, "hostr_session_switch"), false);
    assert.equal(hasTool(initialTools, "hostr_session_logout"), false);
    assert.equal(hasTool(initialTools, "hostr_listings_list"), true);
    assert.equal(hasTool(initialTools, "hostr_listings_create"), true);
    assert.equal(hasTool(initialTools, "hostr_escrow_service_edit"), false);
    assert.deepEqual(calls, []);

    const firstConnect = await client.call("tools/call", {
      name: "hostr_session_connect",
      arguments: { wait: true },
    });
    assert.equal(
      firstConnect.result.structuredContent.data.activePubkey,
      "pubkey-1",
    );
    assert.equal(firstConnect.result.structuredContent.data.toolsChanged, true);

    const postConnectTools = await client.call("tools/list");
    assert.equal(hasTool(postConnectTools, "hostr_listings_list"), true);
    assert.equal(hasTool(postConnectTools, "hostr_session_switch"), true);
    assert.equal(hasTool(postConnectTools, "hostr_session_logout"), true);
    assert.equal(hasTool(postConnectTools, "hostr_reply"), false);
    assert.equal(hasTool(postConnectTools, "hostr_escrow_service_edit"), true);

    const secondConnect = await client.call("tools/call", {
      name: "hostr_session_connect",
      arguments: { wait: true },
    });
    assert.equal(
      secondConnect.result.structuredContent.data.activePubkey,
      "pubkey-2",
    );

    const accounts = await client.call("tools/call", {
      name: "hostr_session_accounts",
      arguments: {},
    });
    assert.equal(accounts.result.structuredContent.activePubkey, "pubkey-2");
    assert.deepEqual(
      accounts.result.structuredContent.accounts.map((account) => ({
        pubkey: account.pubkey,
        active: account.active,
        name: account.metadata.name,
        signerOnline: account.signerStatus.signerOnline,
        needsReconnect: account.signerStatus.needsReconnect,
      })),
      [
        {
          pubkey: "pubkey-1",
          active: false,
          name: "Name pubkey-1",
          signerOnline: false,
          needsReconnect: true,
        },
        {
          pubkey: "pubkey-2",
          active: true,
          name: "Name pubkey-2",
          signerOnline: true,
          needsReconnect: false,
        },
      ],
    );

    const status = await client.call("tools/call", {
      name: "hostr_session_status",
      arguments: { includeStorageDetails: true },
    });
    assert.equal(status.result.structuredContent.activePubkey, "pubkey-2");
    assert.equal(status.result.structuredContent.accountCount, 2);
    assert.equal(status.result.structuredContent.activeAccount.pubkey, "pubkey-2");
    assert.deepEqual(status.result.structuredContent.storage.accountPubkeys, [
      "pubkey-1",
      "pubkey-2",
    ]);

    const switched = await client.call("tools/call", {
      name: "hostr_session_switch",
      arguments: { pubkey: "pubkey-1" },
    });
    assert.deepEqual(switched.result.structuredContent, {
      ok: true,
      activePubkey: "pubkey-1",
      toolsChanged: true,
    });

    const logout = await client.call("tools/call", {
      name: "hostr_session_logout",
      arguments: { pubkey: "pubkey-1" },
    });
    assert.deepEqual(logout.result.structuredContent, {
      ok: true,
      loggedOutPubkeys: ["pubkey-1"],
      activePubkey: "pubkey-2",
      toolsChanged: true,
    });

    const session = new McpSessionStore(config.oauthClientStorePath).get(
      "session-id-1",
    );
    assert.equal(session.activePubkey, "pubkey-2");
    assert.deepEqual(
      session.accounts.map((account) => account.pubkey),
      ["pubkey-2"],
    );
    assert.deepEqual(
      calls.filter((call) => call[0] === "callAction" && call[2] === "hostr.session.connect"),
      [
        [
          "callAction",
          "session-id-1",
          "hostr.session.connect",
          { wait: true, timeoutSeconds: 180, regenerate: false },
        ],
        [
          "callAction",
          "session-id-1",
          "hostr.session.connect",
          { wait: true, timeoutSeconds: 180, regenerate: false },
        ],
      ],
    );
    assert.deepEqual(
      calls.filter((call) => call[0] === "logoutSession"),
      [["logoutSession", "pubkey-1"]],
    );
    assert.deepEqual(
      calls.filter((call) => call[0] === "visibleActions").map((call) => call[1]),
      ["pubkey-1", "pubkey-2", "pubkey-1", "pubkey-2"],
    );
    assert.equal(traceIds.length > 0, true);
    assert.equal(
      traceIds.every(([, traceId]) => typeof traceId === "string" && traceId.length >= 8),
      true,
    );
  } finally {
    await client.close();
  }
});

test("MCP logout keeps accounts connected when swaps are in progress", async () => {
  const directory = tempDirectory();
  const config = testConfig(directory);
  const store = new McpSessionStore(config.oauthClientStorePath);
  store.addOrUpdateAccount({
    sessionId: "session-id-1",
    pubkey: "pubkey-with-swap",
    metadata: { name: "Pending Guest" },
  });

  const calls = [];
  const daemon = {
    visibleActions: async () => ({
      visibleActionIds: [
        "hostr.session.status",
        "hostr.session.connect",
        "hostr.swaps.list",
      ],
    }),
    callAction: async ({ action }) => ({
      ok: true,
      command: action,
      environment: "test",
      dryRun: false,
      data: {},
    }),
    logoutSession: async ({ pubkey }) => {
      calls.push(["logoutSession", pubkey]);
      const error = new Error("Cannot log out while swaps are in progress.");
      error.code = "pending_swaps";
      error.details = {
        pubkey,
        pendingSwapCount: 1,
        pendingSwaps: [
          {
            namespace: "swap_in",
            state: { id: "swap-1", state: "requestCreated", isTerminal: false },
          },
        ],
      };
      throw error;
    },
    uploadImage: async () => ({
      ok: true,
      command: "hostr.upload.image",
      environment: "test",
      dryRun: false,
      data: {},
    }),
    onNotification: () => () => {},
  };

  const token = await signAccessToken(
    config,
    "session-id-1",
    "hostr:read hostr:write",
  );
  const client = await startMcpClient(config, daemon, token);
  try {
    const logout = await client.call("tools/call", {
      name: "hostr_session_logout",
      arguments: { pubkey: "pubkey-with-swap" },
    });
    assert.equal(logout.result.structuredContent.ok, false);
    assert.equal(logout.result.structuredContent.error, "pending_swaps");
    assert.equal(
      logout.result.structuredContent.details.pendingSwapCount,
      1,
    );
    assert.match(
      logout.result.content[0].text,
      /still has swaps in progress/,
    );

    const session = new McpSessionStore(config.oauthClientStorePath).get(
      "session-id-1",
    );
    assert.equal(session.activePubkey, "pubkey-with-swap");
    assert.deepEqual(
      session.accounts.map((account) => account.pubkey),
      ["pubkey-with-swap"],
    );
    assert.deepEqual(calls, [["logoutSession", "pubkey-with-swap"]]);
  } finally {
    await client.close();
  }
});

const hasTool = (toolsResponse, name) =>
  toolsResponse.result.tools.some((tool) => tool.name === name);

const startHttpServer = async (config, daemon) => {
  const server = http.createServer(createApp(config, daemon));
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const port = server.address().port;
  return {
    url: `http://127.0.0.1:${port}`,
    close: () => new Promise((resolve) => server.close(resolve)),
  };
};

const requestText = async (server, pathOrUrl, options = {}) => {
  const response = await fetch(`${server.url}${pathOrUrl}`, {
    method: options.method ?? "GET",
    headers: {
      ...(options.body ? { "content-type": "application/json" } : {}),
      ...(options.headers ?? {}),
    },
    body: options.body ? JSON.stringify(options.body) : undefined,
  });
  return {
    status: response.status,
    headers: response.headers,
    text: await response.text(),
  };
};

const requestJson = async (server, pathOrUrl, options = {}) => {
  const response = await requestText(server, pathOrUrl, options);
  return {
    ...response,
    body: response.text === "" ? undefined : JSON.parse(response.text),
  };
};

const startMcpClient = async (config, daemon, token) => {
  const server = http.createServer(createApp(config, daemon));
  await new Promise((resolve) => server.listen(0, "127.0.0.1", resolve));
  const port = server.address().port;
  const url = `http://127.0.0.1:${port}/mcp`;
  let nextId = 1;
  let mcpSessionId;

  const post = async (body) => {
    const headers = {
      accept: "application/json, text/event-stream",
      "content-type": "application/json",
      ...(mcpSessionId ? { "mcp-session-id": mcpSessionId } : {}),
      ...(token ? { authorization: `Bearer ${token}` } : {}),
    };
    const response = await fetch(url, {
      method: "POST",
      headers,
      body: JSON.stringify(body),
    });
    if (response.headers.get("mcp-session-id")) {
      mcpSessionId = response.headers.get("mcp-session-id");
    }
    const text = await response.text();
    if (response.status === 202 && text === "") {
      return undefined;
    }
    assert.equal(response.status, 200, text);
    return parseSseJson(text);
  };

  await post({
    jsonrpc: "2.0",
    id: nextId++,
    method: "initialize",
    params: {
      protocolVersion: "2025-06-18",
      capabilities: {},
      clientInfo: { name: "hostr-session-test", version: "1.0.0" },
    },
  });
  await post({ jsonrpc: "2.0", method: "notifications/initialized" });

  return {
    call: (method, params = {}) =>
      post({ jsonrpc: "2.0", id: nextId++, method, params }),
    close: () => new Promise((resolve) => server.close(resolve)),
  };
};

const parseSseJson = (text) => {
  const match = /^data: (.*)$/m.exec(text);
  assert.ok(match, text);
  return JSON.parse(match[1]);
};
