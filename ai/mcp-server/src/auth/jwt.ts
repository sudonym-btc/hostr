import { jwtVerify, SignJWT } from "jose";
import type { AppConfig } from "../config.js";

export type HostrAccessTokenClaims = {
  sessionId: string;
  scope: string;
  authorizedParty?: string;
  clientId?: string;
};

export const signAccessToken = async (
  config: AppConfig,
  sessionId: string,
  scope: string,
  options: {
    /**
     * OAuth client identifier for the party authorized to use this access token.
     * Stored as the JWT `azp` claim so future MCP policy can make
     * client-specific decisions without overloading the session subject.
     */
    authorizedParty?: string;
  } = {},
): Promise<string> => {
  const now = Math.floor(Date.now() / 1000);
  const authorizedParty = options.authorizedParty?.trim();

  return new SignJWT({
    sid: sessionId,
    scope,
    ...(authorizedParty ? { azp: authorizedParty } : {}),
  })
    .setProtectedHeader({ alg: "HS256", typ: "JWT" })
    .setIssuer(config.issuer)
    .setAudience(config.mcpResource)
    .setSubject(sessionId)
    .setIssuedAt(now)
    .setExpirationTime(now + config.accessTokenTtlSeconds)
    .sign(config.jwtSecret);
};

export const verifyAccessToken = async (
  config: AppConfig,
  token: string,
): Promise<HostrAccessTokenClaims & { sub: string }> => {
  const { payload } = await jwtVerify(token, config.jwtSecret, {
    issuer: config.issuer,
    audience: config.mcpResource,
  });

  if (typeof payload.sub !== "string" || payload.sub.length === 0) {
    throw new Error("Missing token subject");
  }
  const sessionId =
    typeof payload.sid === "string" && payload.sid.length > 0
      ? payload.sid
      : payload.sub;
  if (!sessionId) {
    throw new Error("Missing session id claim");
  }
  if (typeof payload.scope !== "string") {
    throw new Error("Missing scope claim");
  }
  const authorizedParty =
    typeof payload.azp === "string" && payload.azp.length > 0
      ? payload.azp
      : typeof payload.client_id === "string" && payload.client_id.length > 0
        ? payload.client_id
        : undefined;

  return {
    sub: payload.sub,
    sessionId,
    scope: payload.scope,
    ...(authorizedParty
      ? { authorizedParty, clientId: authorizedParty }
      : {}),
  };
};
