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
