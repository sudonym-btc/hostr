import { jwtVerify, SignJWT } from "jose";
import type { AppConfig } from "../config.js";

export type HostrAccessTokenClaims = {
  pubkey: string;
  scope: string;
};

export const signAccessToken = async (
  config: AppConfig,
  pubkey: string,
  scope: string,
): Promise<string> => {
  const now = Math.floor(Date.now() / 1000);

  return new SignJWT({ pubkey, scope })
    .setProtectedHeader({ alg: "HS256", typ: "JWT" })
    .setIssuer(config.issuer)
    .setAudience(config.mcpResource)
    .setSubject(pubkey)
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
  if (typeof payload.pubkey !== "string" || payload.pubkey.length === 0) {
    throw new Error("Missing pubkey claim");
  }
  if (typeof payload.scope !== "string") {
    throw new Error("Missing scope claim");
  }

  return {
    sub: payload.sub,
    pubkey: payload.pubkey,
    scope: payload.scope,
  };
};
