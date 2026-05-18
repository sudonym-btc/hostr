import crypto from "node:crypto";
import type { Request, Response, Router } from "express";
import express from "express";
import { z } from "zod";
import type { AppConfig } from "../config.js";
import type { HostrDaemonClient } from "../daemon/client.js";
import { scopesSupported } from "../config.js";
import { writeStructuredLog } from "../logging.js";
import { storeQrTextAsset } from "../payment/assets.js";
import { traceIdFromRequest } from "../trace.js";
import {
  loadRegisteredClients,
  saveRegisteredClientsAtomic,
  type RegisteredClient,
} from "./client-store.js";
import { signAccessToken } from "./jwt.js";
import { RefreshTokenStore } from "./refresh-token-store.js";
import { McpSessionStore } from "./session-store.js";

type PendingAuthorization = {
  id: string;
  clientId: string;
  redirectUri: string;
  state?: string;
  scope: string;
  resource: string;
  codeChallenge: string;
  codeChallengeMethod: "S256";
  createdAt: number;
};

type AuthorizationCode = PendingAuthorization & {
  code: string;
  sessionId: string;
  initialPubkey: string;
  expiresAt: number;
};

const pendingAuthorizations = new Map<string, PendingAuthorization>();
const authorizationCodes = new Map<string, AuthorizationCode>();
const registeredClients = new Map<string, RegisteredClient>();
let loadedRegisteredClientsFrom: string | null = null;
const authorizationRequestIds = new Map<string, string>();
const pendingAuthorizationTtlMs = 10 * 60 * 1000;

const authorizationQuerySchema = z.object({
  response_type: z.literal("code"),
  client_id: z.string().min(1),
  redirect_uri: z.string().url(),
  state: z.string().optional(),
  scope: z.string().optional(),
  resource: z.string().url().optional(),
  code_challenge: z.string().min(32),
  code_challenge_method: z.literal("S256"),
});

const tokenBodySchema = z.discriminatedUnion("grant_type", [
  z.object({
    grant_type: z.literal("authorization_code"),
    code: z.string().min(1),
    redirect_uri: z.string().url(),
    client_id: z.string().min(1),
    code_verifier: z.string().min(43),
    resource: z.string().url().optional(),
  }),
  z.object({
    grant_type: z.literal("refresh_token"),
    refresh_token: z.string().min(1),
    client_id: z.string().min(1),
    scope: z.string().optional(),
    resource: z.string().url().optional(),
  }),
]);

const registrationBodySchema = z
  .object({
    redirect_uris: z.array(z.string().url()).min(1),
    client_name: z.string().min(1).optional(),
    scope: z.string().optional(),
    grant_types: z.array(z.string()).optional(),
    response_types: z.array(z.string()).optional(),
    token_endpoint_auth_method: z.string().optional(),
  })
  .passthrough();

const nostrConnectCompleteSchema = z.object({
  request_id: z.string().min(1),
});

const nsecCompleteSchema = z.object({
  request_id: z.string().min(1),
  nsec: z.string().trim().regex(/^nsec1[023456789acdefghjklmnpqrstuvwxyz]+$/),
});

const cancelQuerySchema = z.object({
  request_id: z.string().min(1),
});

const randomToken = (): string => crypto.randomBytes(32).toString("base64url");

const authorizationRequestKey = (request: {
  client_id: string;
  redirect_uri: string;
  state?: string;
  scope?: string;
  resource: string;
  code_challenge: string;
  code_challenge_method: string;
}): string =>
  JSON.stringify({
    clientId: request.client_id,
    redirectUri: request.redirect_uri,
    state: request.state ?? "",
    scope: request.scope ?? "",
    resource: request.resource,
    codeChallenge: request.code_challenge,
    codeChallengeMethod: request.code_challenge_method,
  });

const oauthError = (
  response: Response,
  status: number,
  error: string,
  description: string,
  meta: Record<string, unknown> = {},
) =>
  response
    .status(status)
    .json({ error, error_description: description, ...meta });

const messageFromError = (error: unknown): string =>
  error instanceof Error ? error.message : String(error);

const pkceChallenge = (verifier: string): string =>
  crypto.createHash("sha256").update(verifier).digest("base64url");

const validateResource = (config: AppConfig, resource: string): boolean =>
  resource.replace(/\/+$/, "") === config.mcpResource;

const absoluteUrl = (config: AppConfig, path: string): string =>
  `${config.publicAssetBaseUrl.replace(/\/+$/, "")}${path}`;

const qrImageUrl = (config: AppConfig, data: string): string | null => {
  const template = config.qrImageUrlTemplate;
  if (!template) {
    return null;
  }
  if (template.includes("{data}")) {
    return template.replaceAll("{data}", encodeURIComponent(data));
  }
  try {
    const url = new URL(template);
    url.searchParams.set("data", data);
    return url.toString();
  } catch {
    return null;
  }
};

const clientAllowsRedirect = (clientId: string, redirectUri: string): boolean => {
  const client = registeredClients.get(clientId);
  return Boolean(client && client.redirectUris.includes(redirectUri));
};

const ensureRegisteredClientsLoaded = (config: AppConfig): void => {
  if (loadedRegisteredClientsFrom === config.oauthClientStorePath) {
    return;
  }
  registeredClients.clear();
  try {
    for (const [clientId, client] of loadRegisteredClients(
      config.oauthClientStorePath,
    )) {
      registeredClients.set(clientId, client);
    }
    loadedRegisteredClientsFrom = config.oauthClientStorePath;
    writeStructuredLog("info", "oauth.clients.loaded", {
      count: registeredClients.size,
      path: config.oauthClientStorePath,
    });
  } catch (error) {
    loadedRegisteredClientsFrom = config.oauthClientStorePath;
    writeStructuredLog("error", "oauth.clients.load_failed", {
      path: config.oauthClientStorePath,
      error: error instanceof Error ? error.message : String(error),
    });
  }
};

const persistRegisteredClients = (config: AppConfig): void => {
  saveRegisteredClientsAtomic(
    config.oauthClientStorePath,
    registeredClients.values(),
  );
};

const requestedScopes = (scope: string | undefined): string[] =>
  (scope ?? scopesSupported.join(" "))
    .split(/\s+/)
    .map((entry) => entry.trim())
    .filter(Boolean);

const validateScopes = (scope: string | undefined): boolean =>
  requestedScopes(scope).every((entry) => scopesSupported.includes(entry));

const clientAllowsScopes = (
  clientId: string,
  scope: string | undefined,
): boolean => {
  const client = registeredClients.get(clientId);
  if (!client) return false;
  const allowed = new Set(requestedScopes(client.scope));
  return requestedScopes(scope).every((entry) => allowed.has(entry));
};

const clientAllowsGrant = (clientId: string, grantType: string): boolean => {
  const client = registeredClients.get(clientId);
  return Boolean(client && client.grantTypes.includes(grantType));
};

const scopeIsSubset = (requested: string, allowed: string): boolean => {
  const allowedScopes = new Set(requestedScopes(allowed));
  return requestedScopes(requested).every((entry) => allowedScopes.has(entry));
};

const oauthGrantTypesSupported = ["authorization_code", "refresh_token"];

const sweepExpiredOAuthState = () => {
  const now = Date.now();
  for (const [code, authorizationCode] of authorizationCodes) {
    if (authorizationCode.expiresAt < now) authorizationCodes.delete(code);
  }
  for (const [id, authorization] of pendingAuthorizations) {
    if (now - authorization.createdAt <= pendingAuthorizationTtlMs) continue;
    pendingAuthorizations.delete(id);
    for (const [key, mappedId] of authorizationRequestIds) {
      if (mappedId === id) authorizationRequestIds.delete(key);
    }
  }
};

const escapeHtml = (value: string): string =>
  value
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#39;");

const firstErrorMessage = (errors: unknown[] | undefined): string | null => {
  const first = errors?.[0];
  if (!first || typeof first !== "object") return null;
  const message = (first as { message?: unknown }).message;
  return typeof message === "string" ? message : null;
};

const firstErrorCode = (errors: unknown[] | undefined): string | null => {
  const first = errors?.[0];
  if (!first || typeof first !== "object") return null;
  const code = (first as { code?: unknown }).code;
  return typeof code === "string" ? code : null;
};

const scopeDescription = (scope: string): string => {
  switch (scope) {
    case "hostr:read":
      return "Read Hostr profile, listings, trips, bookings, messages, and payment status.";
    case "hostr:write":
      return "Request Hostr actions such as creating listings, editing your profile, sending messages, or booking stays.";
    default:
      return `Use the ${scope} permission.`;
  }
};

const authorizationDeniedRedirectUrl = (
  request: PendingAuthorization,
): string => {
  const redirectUrl = new URL(request.redirectUri);
  redirectUrl.searchParams.set("error", "access_denied");
  redirectUrl.searchParams.set(
    "error_description",
    "The user cancelled authorization.",
  );
  if (request.state) {
    redirectUrl.searchParams.set("state", request.state);
  }
  return redirectUrl.toString();
};

const removePendingAuthorization = (request: PendingAuthorization): void => {
  pendingAuthorizations.delete(request.id);
  for (const [key, pendingId] of authorizationRequestIds.entries()) {
    if (pendingId === request.id) {
      authorizationRequestIds.delete(key);
    }
  }
};

const pendingAuthorizationIsActive = (request: PendingAuthorization): boolean =>
  pendingAuthorizations.get(request.id) === request;

const renderAuthorizePage = (
  config: AppConfig,
  request: PendingAuthorization,
  connect: {
    nostrconnect: string;
    qrImage: string;
  },
): string => {
  const clientName = registeredClients.get(request.clientId)?.clientName?.trim();
  const clientLabel = clientName
    ? `<strong>${escapeHtml(clientName)}</strong>`
    : `<code>${escapeHtml(request.clientId)}</code>`;
  const escapedCancelUrl = escapeHtml(
    `${config.issuer}/oauth/cancel?request_id=${encodeURIComponent(request.id)}`,
  );
  const escapedNostrConnect = escapeHtml(connect.nostrconnect);
  const escapedQrImage = escapeHtml(connect.qrImage);
  const environmentNotice = config.environmentDescription
    ? ` <span class="muted">Environment: ${escapeHtml(config.environmentDescription)}.</span>`
    : "";
  const scopeItems = request.scope
    .split(/\s+/)
    .filter((scope) => scope !== "")
    .map((scope) => `<li>${escapeHtml(scopeDescription(scope))}</li>`)
    .join("");
  const nostrConnectSection = `<div class="brand">
        <span class="brand-mark" aria-hidden="true">H</span>
        <span>${escapeHtml(config.displayName)}</span>
      </div>
      <p>${clientLabel} wants access to ${escapeHtml(config.displayName)}.${environmentNotice}</p>
      <section class="permissions" aria-label="Requested access">
        <p class="section-label">Requested access</p>
        <ul>${scopeItems}</ul>
      </section>
      <p>Scan this code with your Nostr signer to approve.</p>
      <div class="qr"><img alt="Nostr Connect QR code" src="${escapedQrImage}" /></div>
      <div class="copy-row">
        <input readonly id="nostrconnect" aria-label="Nostr Connect URI" value="${escapedNostrConnect}" />
        <button type="button" id="copy">Copy</button>
      </div>
      <p id="status" class="status">Waiting for signer connection...</p>
      <details class="advanced-login">
        <summary>Advanced options</summary>
        <div class="advanced-panel">
          <p class="nsec-warning">Not recommended. This sends your private nsec to the Hostr MCP server so it can sign actions for this session.</p>
          <form id="nsec-form" class="nsec-form">
            <label for="nsec">Private nsec</label>
            <div class="nsec-row">
              <input id="nsec" name="nsec" type="password" inputmode="text" autocomplete="off" autocapitalize="none" spellcheck="false" placeholder="nsec1..." />
              <button type="submit">Sign in</button>
            </div>
          </form>
        </div>
      </details>
      <a class="cancel-link" href="${escapedCancelUrl}">Cancel</a>`;
  const nostrConnectScript = `<script>
      const requestId = ${JSON.stringify(request.id)};
      const status = document.getElementById("status");
      const copyButton = document.getElementById("copy");
      const uriBox = document.getElementById("nostrconnect");
      const nsecForm = document.getElementById("nsec-form");
      const nsecInput = document.getElementById("nsec");
      const qr = document.querySelector(".qr");
      const copyRow = document.querySelector(".copy-row");
      let stopped = false;

      copyButton.addEventListener("click", async () => {
        try {
          await navigator.clipboard.writeText(uriBox.value);
        } catch {
          uriBox.select();
          document.execCommand("copy");
        }
        status.textContent = "Copied sign-in link.";
      });

      function friendlyStatus(payload) {
        const message = typeof payload?.error_description === "string"
          ? payload.error_description
          : typeof payload?.message === "string"
            ? payload.message
            : "";
        if (message.includes("get_public_key")) {
          return "Signer connected. Waiting for public key...";
        }
        if (payload?.retryable === false || payload?.error === "invalid_request") {
          return message || "This sign-in code is no longer active.";
        }
        return "Waiting for signer connection...";
      }

      function stopWithExpired(message) {
        stopped = true;
        status.textContent = message;
        if (qr) qr.style.display = "none";
        if (copyRow) copyRow.style.display = "none";
      }

      nsecForm.addEventListener("submit", async (event) => {
        event.preventDefault();
        const nsec = nsecInput.value.trim();
        if (!nsec.startsWith("nsec1")) {
          status.textContent = "Enter a valid nsec key.";
          nsecInput.focus();
          return;
        }
        stopped = true;
        status.textContent = "Signing in...";
        try {
          const response = await fetch("/oauth/nsec/complete", {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ request_id: requestId, nsec }),
          });
          const contentType = response.headers.get("content-type") || "";
          const payload = contentType.includes("application/json")
            ? await response.json()
            : { error_description: await response.text() };
          nsecInput.value = "";
          if (!response.ok || !payload.redirectUrl) {
            stopped = false;
            status.textContent = friendlyStatus(payload) || "Could not sign in with that nsec.";
            setTimeout(() => void complete(), 1500);
            return;
          }
          status.textContent = "Connected. Redirecting...";
          window.location.href = payload.redirectUrl;
        } catch (error) {
          stopped = false;
          nsecInput.value = "";
          status.textContent = friendlyStatus(error) || "Could not sign in with that nsec.";
          setTimeout(() => void complete(), 1500);
        }
      });

      async function complete() {
        if (stopped) return;
        status.textContent = "Waiting for signer connection...";
        try {
          const response = await fetch("/oauth/nostr-connect/complete", {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ request_id: requestId }),
          });
          if (stopped) return;
          const contentType = response.headers.get("content-type") || "";
          const payload = contentType.includes("application/json")
            ? await response.json()
            : { error_description: await response.text() };
          if (stopped) return;
          if (!response.ok || !payload.redirectUrl) {
            if (payload.retryable === false || payload.error === "invalid_request") {
              stopWithExpired(friendlyStatus(payload));
              return;
            }
            throw payload;
          }
          status.textContent = "Connected. Redirecting...";
          window.location.href = payload.redirectUrl;
        } catch (error) {
          if (stopped) return;
          status.textContent = friendlyStatus(error);
          setTimeout(() => void complete(), 1500);
        }
      }

      void complete();
    </script>`;

  return `<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <title>Connect Hostr</title>
    <style>
      :root {
        color-scheme: dark;
        font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        background: #121212;
        color: #ffffff;
        --surface: #121212;
        --surface-low: #151515;
        --surface-high: #222222;
        --on-surface: #ffffff;
        --on-surface-variant: #d0d0d0;
        --outline: #6e6e6e;
        --outline-variant: #3a3a3a;
        --primary: #ffffff;
        --on-primary: #000000;
        --secondary-container: #102a55;
        --on-secondary-container: #dce8ff;
        --tertiary: #10b981;
      }
      * { box-sizing: border-box; }
      body {
        margin: 0;
        min-height: 100vh;
        display: grid;
        place-items: center;
        background: var(--surface);
        color: var(--on-surface);
      }
      main {
        width: min(100% - 40px, 408px);
        padding: 24px 0;
      }
      .brand {
        display: flex;
        align-items: center;
        justify-content: center;
        gap: 8px;
        margin-bottom: 32px;
        color: var(--on-surface-variant);
        font-size: 15px;
        font-weight: 700;
      }
      .brand-mark {
        width: 28px;
        height: 28px;
        display: inline-grid;
        place-items: center;
        border-radius: 8px;
        background: var(--primary);
        color: var(--on-primary);
        font-size: 15px;
        line-height: 1;
      }
      h1 {
        font-size: 20px;
        line-height: 1.2;
        margin: 0;
        font-weight: 700;
        letter-spacing: 0;
      }
      p {
        line-height: 1.5;
        margin: 0 0 20px;
        color: var(--on-surface-variant);
        text-align: center;
      }
      code {
        color: var(--on-surface);
        font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        font-size: 0.9em;
      }
      .permissions {
        margin: 0 0 20px;
        padding: 16px;
        border: 1px solid var(--outline-variant);
        border-radius: 8px;
        background: var(--surface-low);
      }
      .section-label {
        margin: 0 0 12px;
        color: var(--on-surface);
        font-size: 14px;
        font-weight: 700;
        text-align: left;
      }
      ul {
        margin: 0;
        padding: 0;
        display: grid;
        gap: 10px;
        list-style: none;
      }
      li {
        position: relative;
        padding-left: 18px;
        color: var(--on-surface-variant);
        font-size: 14px;
        line-height: 1.45;
      }
      li::before {
        content: "";
        position: absolute;
        left: 0;
        top: 0.58em;
        width: 6px;
        height: 6px;
        border-radius: 999px;
        background: var(--tertiary);
      }
      .qr {
        width: min(100%, 384px);
        aspect-ratio: 1;
        display: grid;
        place-items: center;
        padding: 16px;
        border-radius: 14px;
        background: #ffffff;
        color: #000000;
        margin: 24px auto 20px;
        overflow: hidden;
      }
      .qr img {
        width: 100%;
        height: 100%;
        image-rendering: pixelated;
        display: block;
      }
      label {
        display: grid;
        gap: 8px;
        color: var(--on-surface-variant);
        font-size: 14px;
        font-weight: 600;
      }
      input {
        min-width: 0;
        height: 40px;
        padding: 0 12px;
        border: 1px solid var(--outline-variant);
        border-radius: 8px;
        background: var(--surface-low);
        color: var(--on-surface);
        font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
        font-size: 12px;
        outline: none;
      }
      input:focus {
        border-color: var(--outline);
      }
      button {
        min-height: 40px;
        padding: 0 14px;
        border: 1px solid var(--outline);
        border-radius: 8px;
        background: transparent;
        color: var(--primary);
        font: inherit;
        font-size: 14px;
        font-weight: 700;
        cursor: pointer;
      }
      button:hover,
      button:focus-visible {
        background: var(--surface-high);
        outline: none;
      }
      .muted {
        color: var(--outline);
        font-size: 14px;
      }
      .status {
        min-height: 24px;
        margin-top: 16px;
        color: var(--on-surface-variant);
        text-align: center;
      }
      .status::before {
        content: "";
        width: 8px;
        height: 8px;
        display: inline-block;
        margin-right: 8px;
        border-radius: 999px;
        background: var(--tertiary);
        vertical-align: 1px;
      }
      .copy-row {
        display: grid;
        grid-template-columns: minmax(0, 1fr) auto;
        gap: 8px;
      }
      .advanced-login {
        margin-top: 18px;
        border-top: 1px solid var(--outline-variant);
        padding-top: 12px;
      }
      .advanced-login summary {
        width: max-content;
        margin: 0 auto;
        color: var(--outline);
        font-size: 13px;
        font-weight: 700;
        cursor: pointer;
      }
      .advanced-login summary:hover,
      .advanced-login summary:focus-visible {
        color: var(--on-surface-variant);
        outline: none;
      }
      .advanced-panel {
        margin-top: 14px;
        padding: 14px;
        border: 1px solid var(--outline-variant);
        border-radius: 8px;
        background: var(--surface-low);
      }
      .nsec-form {
        display: grid;
        gap: 10px;
      }
      .nsec-row {
        display: grid;
        grid-template-columns: minmax(0, 1fr) auto;
        gap: 8px;
      }
      .nsec-warning {
        margin: 0 0 12px;
        color: var(--on-surface-variant);
        font-size: 12px;
        line-height: 1.45;
        text-align: left;
      }
      .cancel-link {
        display: block;
        width: max-content;
        margin: 10px auto 0;
        padding: 10px 14px;
        border-radius: 8px;
        color: var(--outline);
        font-size: 14px;
        font-weight: 700;
        text-decoration: none;
      }
      .cancel-link:hover,
      .cancel-link:focus-visible {
        color: var(--on-surface);
        background: var(--surface-high);
        outline: none;
      }
      @media (max-width: 420px) {
        main {
          width: min(100% - 32px, 408px);
        }
        .brand {
          margin-bottom: 24px;
        }
        .copy-row {
          grid-template-columns: 1fr;
        }
        .nsec-row {
          grid-template-columns: 1fr;
        }
        button {
          width: 100%;
        }
      }
    </style>
  </head>
  <body>
    <main>
      ${nostrConnectSection}
    </main>
    ${nostrConnectScript}
  </body>
</html>`;
};

const authorizationRedirectUrl = (
  config: AppConfig,
  request: PendingAuthorization,
  pubkey: string,
): string => {
  const code = randomToken();
  const sessionId = randomToken();
  new McpSessionStore(config.oauthClientStorePath).addOrUpdateAccount({
    sessionId,
    pubkey,
  });
  authorizationCodes.set(code, {
    ...request,
    code,
    sessionId,
    initialPubkey: pubkey,
    expiresAt: Date.now() + 5 * 60 * 1000,
  });
  removePendingAuthorization(request);

  const redirectUrl = new URL(request.redirectUri);
  redirectUrl.searchParams.set("code", code);
  if (request.state) {
    redirectUrl.searchParams.set("state", request.state);
  }

  return redirectUrl.toString();
};

export const createOAuthRouter = (
  config: AppConfig,
  daemon: HostrDaemonClient,
): Router => {
  ensureRegisteredClientsLoaded(config);
  const router = express.Router();

  router.use((_request, response, next) => {
    response.setHeader("Cache-Control", "no-store");
    response.setHeader("Pragma", "no-cache");
    next();
  });

  router.get("/.well-known/oauth-protected-resource", (_request, response) => {
    response.json({
      resource: config.mcpResource,
      resource_name: config.displayName,
      authorization_servers: [config.issuer],
      bearer_methods_supported: ["header"],
      scopes_supported: scopesSupported,
    });
  });

  router.get(
    "/.well-known/oauth-protected-resource/mcp",
    (_request, response) => {
      response.json({
        resource: config.mcpResource,
        resource_name: config.displayName,
        authorization_servers: [config.issuer],
        bearer_methods_supported: ["header"],
        scopes_supported: scopesSupported,
      });
    },
  );

  router.get(
    "/.well-known/oauth-authorization-server",
    (_request, response) => {
      response.json({
        issuer: config.issuer,
        authorization_endpoint: `${config.issuer}/oauth/authorize`,
        token_endpoint: `${config.issuer}/oauth/token`,
        registration_endpoint: `${config.issuer}/oauth/register`,
        response_types_supported: ["code"],
        grant_types_supported: oauthGrantTypesSupported,
        code_challenge_methods_supported: ["S256"],
        token_endpoint_auth_methods_supported: ["none"],
        scopes_supported: scopesSupported,
        resource_indicators_supported: true,
      });
    },
  );

  router.get(
    "/.well-known/oauth-authorization-server/mcp",
    (_request, response) => {
      response.json({
        issuer: config.issuer,
        authorization_endpoint: `${config.issuer}/oauth/authorize`,
        token_endpoint: `${config.issuer}/oauth/token`,
        registration_endpoint: `${config.issuer}/oauth/register`,
        response_types_supported: ["code"],
        grant_types_supported: oauthGrantTypesSupported,
        code_challenge_methods_supported: ["S256"],
        token_endpoint_auth_methods_supported: ["none"],
        scopes_supported: scopesSupported,
        resource_indicators_supported: true,
      });
    },
  );

  router.post("/oauth/register", (request: Request, response: Response) => {
    sweepExpiredOAuthState();
    const parsed = registrationBodySchema.safeParse(request.body);
    if (!parsed.success) {
      return oauthError(
        response,
        400,
        "invalid_client_metadata",
        "Malformed dynamic client registration request.",
      );
    }

    const grantTypes = parsed.data.grant_types ?? ["authorization_code"];
    const responseTypes = parsed.data.response_types ?? ["code"];
    const authMethod = parsed.data.token_endpoint_auth_method ?? "none";
    if (!validateScopes(parsed.data.scope)) {
      return oauthError(
        response,
        400,
        "invalid_client_metadata",
        "Requested scopes are not supported by this MCP server.",
      );
    }

    const unsupportedGrant = grantTypes.some(
      (grantType) => !oauthGrantTypesSupported.includes(grantType),
    );
    if (
      !grantTypes.includes("authorization_code") ||
      unsupportedGrant ||
      !responseTypes.includes("code") ||
      authMethod !== "none"
    ) {
      return oauthError(
        response,
        400,
        "invalid_client_metadata",
        "Hostr MCP only supports public authorization-code PKCE clients with optional refresh-token rotation.",
      );
    }

    const client: RegisteredClient = {
      clientId: `hostr-dcr-${randomToken()}`,
      clientName: parsed.data.client_name,
      redirectUris: parsed.data.redirect_uris,
      scope: parsed.data.scope || scopesSupported.join(" "),
      grantTypes: grantTypes.filter((grantType) =>
        oauthGrantTypesSupported.includes(grantType),
      ),
      responseTypes: ["code"],
      tokenEndpointAuthMethod: "none",
      clientIdIssuedAt: Math.floor(Date.now() / 1000),
    };
    registeredClients.set(client.clientId, client);
    try {
      persistRegisteredClients(config);
      writeStructuredLog("info", "oauth.client.registered", {
        traceId: request.hostrTraceId ?? traceIdFromRequest(request),
        clientId: client.clientId,
        redirectUriCount: client.redirectUris.length,
        scope: client.scope,
      });
    } catch (error) {
      registeredClients.delete(client.clientId);
      writeStructuredLog("error", "oauth.client.persist_failed", {
        traceId: request.hostrTraceId ?? traceIdFromRequest(request),
        clientId: client.clientId,
        error: error instanceof Error ? error.message : String(error),
      });
      return oauthError(
        response,
        500,
        "server_error",
        "Could not persist dynamic client registration.",
      );
    }

    response.status(201).json({
      client_id: client.clientId,
      client_id_issued_at: client.clientIdIssuedAt,
      client_name: client.clientName,
      redirect_uris: client.redirectUris,
      scope: client.scope,
      grant_types: client.grantTypes,
      response_types: client.responseTypes,
      token_endpoint_auth_method: client.tokenEndpointAuthMethod,
    });
  });

  router.get(
    "/oauth/authorize",
    async (request: Request, response: Response) => {
      sweepExpiredOAuthState();
      const traceId = request.hostrTraceId ?? traceIdFromRequest(request);
      const parsed = authorizationQuerySchema.safeParse(request.query);
      if (!parsed.success) {
        return oauthError(
          response,
          400,
          "invalid_request",
          "Malformed authorization request.",
        );
      }
      const resource = parsed.data.resource ?? config.mcpResource;
      if (!validateResource(config, resource)) {
        return oauthError(
          response,
          400,
          "invalid_target",
          "The resource parameter must match this MCP server.",
        );
      }
      if (
        !clientAllowsRedirect(parsed.data.client_id, parsed.data.redirect_uri)
      ) {
        return oauthError(
          response,
          400,
          "invalid_request",
          "The redirect_uri is not registered for this client.",
        );
      }
      if (
        !validateScopes(parsed.data.scope) ||
        !clientAllowsScopes(parsed.data.client_id, parsed.data.scope)
      ) {
        return oauthError(
          response,
          400,
          "invalid_scope",
          "Requested scopes are not registered for this client.",
        );
      }

      const requestKey = authorizationRequestKey({
        ...parsed.data,
        resource,
      });
      const existingPendingId = authorizationRequestIds.get(requestKey);
      const existingPending = existingPendingId
        ? pendingAuthorizations.get(existingPendingId)
        : undefined;
      const pending: PendingAuthorization =
        existingPending ??
        {
          id: randomToken(),
          clientId: parsed.data.client_id,
          redirectUri: parsed.data.redirect_uri,
          state: parsed.data.state,
          scope: parsed.data.scope || scopesSupported.join(" "),
          resource,
          codeChallenge: parsed.data.code_challenge,
          codeChallengeMethod: parsed.data.code_challenge_method,
          createdAt: Date.now(),
        };

      pendingAuthorizations.set(pending.id, pending);
      authorizationRequestIds.set(requestKey, pending.id);
      const connect = await daemon.startOAuthNostrConnect({
        requestId: pending.id,
        regenerate: !existingPending,
        traceId,
      });
      if (
        !connect.ok ||
        !connect.data?.nostrconnect ||
        !connect.data?.qrImage
      ) {
        pendingAuthorizations.delete(pending.id);
        authorizationRequestIds.delete(requestKey);
        return oauthError(
          response,
          500,
          "server_error",
          firstErrorMessage(connect.errors) ??
            "Could not create a Nostr Connect request.",
        );
      }

      const remoteQrUrl = qrImageUrl(config, connect.data.nostrconnect);
      const qrAsset = storeQrTextAsset(
        remoteQrUrl ? null : connect.data.qrImage,
        connect.data.nostrconnect,
      );

      response.type("html").send(
        renderAuthorizePage(config, pending, {
          nostrconnect: connect.data.nostrconnect,
          qrImage:
            remoteQrUrl ??
            (qrAsset.qrUrlPath
              ? absoluteUrl(config, qrAsset.qrUrlPath)
              : connect.data.qrImage),
        }),
      );
    },
  );

  router.get("/oauth/cancel", (request: Request, response: Response) => {
    sweepExpiredOAuthState();
    const parsed = cancelQuerySchema.safeParse(request.query);
    if (!parsed.success) {
      return oauthError(
        response,
        400,
        "invalid_request",
        "Malformed cancellation request.",
      );
    }

    const pending = pendingAuthorizations.get(parsed.data.request_id);
    if (!pending) {
      return oauthError(
        response,
        400,
        "invalid_request",
        "Unknown or expired authorization request.",
      );
    }

    const redirectUrl = authorizationDeniedRedirectUrl(pending);
    removePendingAuthorization(pending);
    response.redirect(302, redirectUrl);
  });

  router.post(
    "/oauth/nostr-connect/complete",
    async (request: Request, response: Response) => {
      sweepExpiredOAuthState();
      const traceId = request.hostrTraceId ?? traceIdFromRequest(request);
      const parsed = nostrConnectCompleteSchema.safeParse(request.body);
      if (!parsed.success) {
        return oauthError(
          response,
          400,
          "invalid_request",
          "Malformed Nostr Connect completion request.",
          { retryable: false },
        );
      }

      const pending = pendingAuthorizations.get(parsed.data.request_id);
      if (!pending) {
        return oauthError(
          response,
          400,
          "invalid_request",
          "Unknown or expired authorization request.",
          { retryable: false },
        );
      }

      const timeoutSeconds = 180;
      let completed;
      try {
        completed = await daemon.completeOAuthNostrConnect({
          requestId: pending.id,
          timeoutSeconds,
          timeoutMs: timeoutSeconds * 1000 + 15_000,
          traceId,
        });
      } catch (error) {
        return oauthError(
          response,
          504,
          "authorization_pending",
          messageFromError(error),
          { retryable: true },
        );
      }
      const pubkey = completed.data?.pubkey;
      if (!completed.ok || !pubkey) {
        const code = firstErrorCode(completed.errors);
        const message =
          firstErrorMessage(completed.errors) ??
          "Nostr Connect approval is not complete yet.";
        if (code === "unknown_oauth_request") {
          removePendingAuthorization(pending);
          return oauthError(response, 410, "invalid_request", message, {
            retryable: false,
          });
        }
        return oauthError(
          response,
          400,
          "authorization_pending",
          message,
          { retryable: true },
        );
      }
      if (!pendingAuthorizationIsActive(pending)) {
        return oauthError(
          response,
          410,
          "invalid_request",
          "This authorization request was already completed.",
          { retryable: false },
        );
      }

      response.json({
        pubkey,
        redirectUrl: authorizationRedirectUrl(config, pending, pubkey),
      });
    },
  );

  router.post(
    "/oauth/nsec/complete",
    async (request: Request, response: Response) => {
      sweepExpiredOAuthState();
      const traceId = request.hostrTraceId ?? traceIdFromRequest(request);
      const parsed = nsecCompleteSchema.safeParse(request.body);
      if (!parsed.success) {
        return oauthError(
          response,
          400,
          "invalid_request",
          "Malformed nsec completion request.",
          { retryable: true },
        );
      }

      const pending = pendingAuthorizations.get(parsed.data.request_id);
      if (!pending) {
        return oauthError(
          response,
          400,
          "invalid_request",
          "Unknown or expired authorization request.",
          { retryable: false },
        );
      }

      let completed;
      try {
        completed = await daemon.completeOAuthNsec({
          requestId: pending.id,
          nsec: parsed.data.nsec,
          traceId,
        });
      } catch (error) {
        return oauthError(
          response,
          500,
          "server_error",
          messageFromError(error),
          { retryable: true },
        );
      }

      const pubkey = completed.data?.pubkey;
      if (!completed.ok || !pubkey) {
        return oauthError(
          response,
          400,
          "invalid_request",
          firstErrorMessage(completed.errors) ??
            "Could not sign in with that nsec.",
          { retryable: true },
        );
      }
      if (!pendingAuthorizationIsActive(pending)) {
        return oauthError(
          response,
          410,
          "invalid_request",
          "This authorization request was already completed.",
          { retryable: false },
        );
      }

      response.json({
        pubkey,
        redirectUrl: authorizationRedirectUrl(config, pending, pubkey),
      });
    },
  );

  router.post("/oauth/token", async (request: Request, response: Response) => {
    sweepExpiredOAuthState();
    const parsed = tokenBodySchema.safeParse(request.body);
    if (!parsed.success) {
      return oauthError(
        response,
        400,
        "invalid_request",
        "Malformed token request.",
      );
    }

    if (parsed.data.grant_type === "refresh_token") {
      const refreshStore = new RefreshTokenStore(config.oauthClientStorePath);
      const lookup = refreshStore.lookup(parsed.data.refresh_token);
      if (lookup.status === "consumed" || lookup.status === "revoked") {
        if (lookup.record) {
          refreshStore.revokeFamily(lookup.record.familyId);
        }
        return oauthError(
          response,
          400,
          "invalid_grant",
          "Refresh token has already been used or revoked.",
        );
      }
      if (lookup.status !== "valid" || !lookup.record) {
        return oauthError(
          response,
          400,
          "invalid_grant",
          "Refresh token is invalid or expired.",
        );
      }

      const token = lookup.record;
      const resource = parsed.data.resource ?? token.resource;
      const scope = parsed.data.scope ?? token.scope;
      if (
        token.clientId !== parsed.data.client_id ||
        !clientAllowsGrant(parsed.data.client_id, "refresh_token") ||
        !validateResource(config, resource) ||
        resource !== token.resource ||
        !validateScopes(scope) ||
        !clientAllowsScopes(parsed.data.client_id, scope) ||
        !scopeIsSubset(scope, token.scope)
      ) {
        return oauthError(
          response,
          400,
          "invalid_grant",
          "Refresh token binding did not match.",
        );
      }

      const consumed = refreshStore.consume(token.id);
      if (!consumed) {
        refreshStore.revokeFamily(token.familyId);
        return oauthError(
          response,
          400,
          "invalid_grant",
          "Refresh token has already been used or revoked.",
        );
      }

      const accessToken = await signAccessToken(
        config,
        token.sessionId,
        scope,
      );
      const rotated = refreshStore.issue({
        clientId: token.clientId,
        sessionId: token.sessionId,
        scope,
        resource: token.resource,
        ttlSeconds: config.refreshTokenTtlSeconds,
        familyId: token.familyId,
      });

      return response.json({
        access_token: accessToken,
        token_type: "Bearer",
        expires_in: config.accessTokenTtlSeconds,
        refresh_token: rotated.refreshToken,
        scope,
      });
    }

    const code = authorizationCodes.get(parsed.data.code);
    if (!code || code.expiresAt < Date.now()) {
      authorizationCodes.delete(parsed.data.code);
      return oauthError(
        response,
        400,
        "invalid_grant",
        "Authorization code is invalid or expired.",
      );
    }

    if (
      code.redirectUri !== parsed.data.redirect_uri ||
      code.clientId !== parsed.data.client_id ||
      !validateResource(config, parsed.data.resource ?? config.mcpResource) ||
      code.resource !== (parsed.data.resource ?? config.mcpResource)
    ) {
      return oauthError(
        response,
        400,
        "invalid_grant",
        "Authorization code binding did not match.",
      );
    }

    if (pkceChallenge(parsed.data.code_verifier) !== code.codeChallenge) {
      return oauthError(
        response,
        400,
        "invalid_grant",
        "PKCE verifier did not match the authorization request.",
      );
    }

    authorizationCodes.delete(parsed.data.code);
    const accessToken = await signAccessToken(
      config,
      code.sessionId,
      code.scope,
    );
    const refreshToken = clientAllowsGrant(code.clientId, "refresh_token")
      ? new RefreshTokenStore(config.oauthClientStorePath).issue({
          clientId: code.clientId,
          sessionId: code.sessionId,
          scope: code.scope,
          resource: code.resource,
          ttlSeconds: config.refreshTokenTtlSeconds,
        }).refreshToken
      : undefined;

    response.json({
      access_token: accessToken,
      token_type: "Bearer",
      expires_in: config.accessTokenTtlSeconds,
      ...(refreshToken ? { refresh_token: refreshToken } : {}),
      scope: code.scope,
    });
  });

  return router;
};
