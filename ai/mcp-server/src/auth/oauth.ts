import crypto from "node:crypto";
import type { Request, Response, Router } from "express";
import express from "express";
import { z } from "zod";
import type { AppConfig } from "../config.js";
import type { HostrDaemonClient } from "../daemon/client.js";
import { scopesSupported } from "../config.js";
import { storeQrTextAsset } from "../payment/assets.js";
import { signAccessToken } from "./jwt.js";

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

type RegisteredClient = {
  clientId: string;
  clientName?: string;
  redirectUris: string[];
  scope: string;
  grantTypes: string[];
  responseTypes: string[];
  tokenEndpointAuthMethod: "none";
  clientIdIssuedAt: number;
};

type AuthorizationCode = PendingAuthorization & {
  code: string;
  pubkey: string;
  expiresAt: number;
};

const pendingAuthorizations = new Map<string, PendingAuthorization>();
const authorizationCodes = new Map<string, AuthorizationCode>();
const registeredClients = new Map<string, RegisteredClient>();

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

const tokenBodySchema = z.object({
  grant_type: z.literal("authorization_code"),
  code: z.string().min(1),
  redirect_uri: z.string().url(),
  client_id: z.string().min(1),
  code_verifier: z.string().min(43),
  resource: z.string().url().optional(),
});

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

const randomToken = (): string => crypto.randomBytes(32).toString("base64url");

const oauthError = (
  response: Response,
  status: number,
  error: string,
  description: string,
) => response.status(status).json({ error, error_description: description });

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
  const url = new URL(template);
  url.searchParams.set("data", data);
  return url.toString();
};

const requestedResource = (
  config: AppConfig,
  resource: string | undefined,
): string => resource ?? config.mcpResource;

const clientAllowsRedirect = (
  clientId: string,
  redirectUri: string,
): boolean => {
  const client = registeredClients.get(clientId);
  return !client || client.redirectUris.includes(redirectUri);
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

const renderAuthorizePage = (
  config: AppConfig,
  request: PendingAuthorization,
  connect: {
    nostrconnect: string;
    qrImage: string;
  },
): string => {
  const escapedClientId = escapeHtml(request.clientId);
  const escapedNostrConnect = escapeHtml(connect.nostrconnect);
  const escapedQrImage = escapeHtml(connect.qrImage);
  const nostrConnectSection = `<p>Please scan this code to login with your existing nostr app and authorize <code>${escapedClientId}</code> for ${escapeHtml(config.displayName)}.</p>
      <div class="qr"><img alt="Nostr Connect QR code" src="${escapedQrImage}" /></div>
      <label>
        Nostrconnect uri
        <span class="copy-row">
          <input readonly id="nostrconnect" value="${escapedNostrConnect}" />
          <button type="button" id="copy">Copy</button>
        </span>
      </label>
      <p id="status" class="status">Waiting for signer approval...</p>`;
  const nostrConnectScript = `<script>
      const requestId = ${JSON.stringify(request.id)};
      const status = document.getElementById("status");
      const copyButton = document.getElementById("copy");
      const uriBox = document.getElementById("nostrconnect");

      copyButton.addEventListener("click", async () => {
        try {
          await navigator.clipboard.writeText(uriBox.value);
        } catch {
          uriBox.select();
          document.execCommand("copy");
        }
        status.textContent = "Copied nostrconnect URI.";
      });

      async function complete() {
        status.textContent = "Waiting for get_public_key from your signer...";
        try {
          const response = await fetch("/oauth/nostr-connect/complete", {
            method: "POST",
            headers: { "content-type": "application/json" },
            body: JSON.stringify({ request_id: requestId }),
          });
          const payload = await response.json();
          if (!response.ok || !payload.redirectUrl) {
            throw new Error(payload.error_description || "Nostr Connect approval is not complete yet.");
          }
          status.textContent = "Connected. Redirecting...";
          window.location.href = payload.redirectUrl;
        } catch (error) {
          status.textContent = error instanceof Error ? error.message : String(error);
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
      :root { color-scheme: light dark; font-family: Inter, ui-sans-serif, system-ui, sans-serif; }
      body { margin: 0; min-height: 100vh; display: grid; place-items: center; background: #0f172a; color: #f8fafc; }
      main { width: min(92vw, 520px); padding: 32px; }
      h1 { font-size: 24px; margin: 0 0 12px; }
      p { line-height: 1.5; margin: 0 0 20px; color: #cbd5e1; }
      .qr { width: min(100%, 360px); aspect-ratio: 1; display: grid; place-items: center; border: 1px solid #475569; background: #f8fafc; color: #0f172a; margin: 24px auto; }
      .qr img { width: 100%; height: 100%; image-rendering: pixelated; }
      form { display: grid; gap: 12px; }
      label { display: grid; gap: 6px; color: #cbd5e1; }
      input { min-width: 0; padding: 10px 12px; border: 1px solid #475569; border-radius: 6px; background: #020617; color: #f8fafc; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 12px; }
      button { padding: 10px 12px; border: 0; border-radius: 6px; background: #38bdf8; color: #082f49; font-weight: 700; cursor: pointer; }
      .muted { color: #94a3b8; font-size: 14px; }
      .status { min-height: 24px; margin-top: 12px; color: #bae6fd; }
      .copy-row { display: grid; grid-template-columns: minmax(0, 1fr) auto; gap: 8px; }
    </style>
  </head>
  <body>
    <main>
      <h1>Connect Hostr</h1>
      ${nostrConnectSection}
    </main>
    ${nostrConnectScript}
  </body>
</html>`;
};

const authorizationRedirectUrl = (
  request: PendingAuthorization,
  pubkey: string,
): string => {
  const code = randomToken();
  authorizationCodes.set(code, {
    ...request,
    code,
    pubkey,
    expiresAt: Date.now() + 5 * 60 * 1000,
  });
  pendingAuthorizations.delete(request.id);

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
  const router = express.Router();

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
        grant_types_supported: ["authorization_code"],
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
        grant_types_supported: ["authorization_code"],
        code_challenge_methods_supported: ["S256"],
        token_endpoint_auth_methods_supported: ["none"],
        scopes_supported: scopesSupported,
        resource_indicators_supported: true,
      });
    },
  );

  router.post("/oauth/register", (request: Request, response: Response) => {
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

    if (
      !grantTypes.includes("authorization_code") ||
      !responseTypes.includes("code") ||
      authMethod !== "none"
    ) {
      return oauthError(
        response,
        400,
        "invalid_client_metadata",
        "Hostr MCP only supports public authorization-code PKCE clients.",
      );
    }

    const client: RegisteredClient = {
      clientId: `hostr-dcr-${randomToken()}`,
      clientName: parsed.data.client_name,
      redirectUris: parsed.data.redirect_uris,
      scope: parsed.data.scope || scopesSupported.join(" "),
      grantTypes: ["authorization_code"],
      responseTypes: ["code"],
      tokenEndpointAuthMethod: "none",
      clientIdIssuedAt: Math.floor(Date.now() / 1000),
    };
    registeredClients.set(client.clientId, client);

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
      const parsed = authorizationQuerySchema.safeParse(request.query);
      if (!parsed.success) {
        return oauthError(
          response,
          400,
          "invalid_request",
          "Malformed authorization request.",
        );
      }
      const resource = requestedResource(config, parsed.data.resource);
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

      const pending: PendingAuthorization = {
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
      const connect = await daemon.startOAuthNostrConnect({
        requestId: pending.id,
        regenerate: true,
      });
      if (
        !connect.ok ||
        !connect.data?.nostrconnect ||
        !connect.data?.qrImage
      ) {
        pendingAuthorizations.delete(pending.id);
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

  router.post(
    "/oauth/nostr-connect/complete",
    async (request: Request, response: Response) => {
      const parsed = nostrConnectCompleteSchema.safeParse(request.body);
      if (!parsed.success) {
        return oauthError(
          response,
          400,
          "invalid_request",
          "Malformed Nostr Connect completion request.",
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

      const completed = await daemon.completeOAuthNostrConnect({
        requestId: pending.id,
        timeoutSeconds: 180,
      });
      const pubkey = completed.data?.pubkey;
      if (!completed.ok || !pubkey) {
        return oauthError(
          response,
          400,
          "authorization_pending",
          firstErrorMessage(completed.errors) ??
            "Nostr Connect approval is not complete yet.",
        );
      }

      response.json({
        pubkey,
        redirectUrl: authorizationRedirectUrl(pending, pubkey),
      });
    },
  );

  router.post("/oauth/token", async (request: Request, response: Response) => {
    const parsed = tokenBodySchema.safeParse(request.body);
    if (!parsed.success) {
      return oauthError(
        response,
        400,
        "invalid_request",
        "Malformed token request.",
      );
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
      !validateResource(config, requestedResource(config, parsed.data.resource))
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
    const accessToken = await signAccessToken(config, code.pubkey, code.scope);

    response.json({
      access_token: accessToken,
      token_type: "Bearer",
      expires_in: config.accessTokenTtlSeconds,
      scope: code.scope,
    });
  });

  return router;
};
