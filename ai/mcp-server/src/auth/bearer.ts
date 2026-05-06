import type { Request, Response } from "express";
import type { AppConfig } from "../config.js";
import { verifyAccessToken } from "./jwt.js";
import type { HostrAccessTokenClaims } from "./jwt.js";

export type AccessTokenClaims = HostrAccessTokenClaims & { sub: string };

export const bearerToken = (request: Request): string | null => {
  const header = request.header("authorization");
  if (!header) {
    return null;
  }

  const match = /^Bearer\s+(.+)$/i.exec(header);
  return match?.[1] ?? null;
};

export const bearerChallenge = (config: AppConfig): string =>
  `Bearer resource_metadata="${config.issuer}/.well-known/oauth-protected-resource/mcp", scope="hostr:read hostr:write"`;

export const hasScope = (
  claims: AccessTokenClaims,
  scope: string,
): boolean => claims.scope.split(/\s+/).includes(scope);

export const verifyBearerRequest = async (
  config: AppConfig,
  request: Request,
  response: Response,
): Promise<AccessTokenClaims | null> => {
  const token = bearerToken(request);
  if (!token) {
    response.setHeader("WWW-Authenticate", bearerChallenge(config));
    response.status(401).json({ error: "missing_token" });
    return null;
  }

  try {
    return await verifyAccessToken(config, token);
  } catch {
    response.setHeader("WWW-Authenticate", bearerChallenge(config));
    response.status(401).json({ error: "invalid_token" });
    return null;
  }
};
