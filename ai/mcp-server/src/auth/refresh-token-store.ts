import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";

export type RefreshTokenRecord = {
  id: string;
  tokenHash: string;
  familyId: string;
  clientId: string;
  sessionId: string;
  scope: string;
  resource: string;
  issuedAt: number;
  expiresAt: number;
  consumedAt?: number;
  revokedAt?: number;
};

type RefreshTokenStoreFile = {
  version: 1;
  refreshTokens: RefreshTokenRecord[];
};

export type RefreshTokenStatus =
  | "valid"
  | "invalid"
  | "expired"
  | "consumed"
  | "revoked";

export type RefreshTokenLookup = {
  status: RefreshTokenStatus;
  record?: RefreshTokenRecord;
};

const refreshTokens = new Map<string, RefreshTokenRecord>();
let loadedFrom: string | null = null;

const tokenPrefix = "hostr_rt_";

const refreshTokenStorePath = (oauthClientStorePath: string): string =>
  path.join(path.dirname(oauthClientStorePath), "oauth-refresh-tokens.json");

const randomTokenPart = (): string => crypto.randomBytes(32).toString("base64url");

const hashToken = (token: string): string =>
  crypto.createHash("sha256").update(token).digest("hex");

const timingSafeEqualHex = (left: string, right: string): boolean => {
  const leftBuffer = Buffer.from(left, "hex");
  const rightBuffer = Buffer.from(right, "hex");
  return (
    leftBuffer.length === rightBuffer.length &&
    crypto.timingSafeEqual(leftBuffer, rightBuffer)
  );
};

const parseTokenId = (token: string): string | null => {
  if (!token.startsWith(tokenPrefix)) {
    return null;
  }
  const dotIndex = token.indexOf(".");
  if (dotIndex <= tokenPrefix.length) {
    return null;
  }
  return token.slice(tokenPrefix.length, dotIndex);
};

const sanitizeRefreshTokenRecord = (
  value: unknown,
): RefreshTokenRecord | null => {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  const token = value as Record<string, unknown>;
  if (
    typeof token.id !== "string" ||
    token.id.trim() === "" ||
    typeof token.tokenHash !== "string" ||
    token.tokenHash.trim() === "" ||
    typeof token.familyId !== "string" ||
    token.familyId.trim() === "" ||
    typeof token.clientId !== "string" ||
    token.clientId.trim() === "" ||
    typeof token.sessionId !== "string" ||
    token.sessionId.trim() === "" ||
    typeof token.scope !== "string" ||
    typeof token.resource !== "string" ||
    token.resource.trim() === "" ||
    typeof token.issuedAt !== "number" ||
    typeof token.expiresAt !== "number"
  ) {
    return null;
  }
  return {
    id: token.id,
    tokenHash: token.tokenHash,
    familyId: token.familyId,
    clientId: token.clientId,
    sessionId: token.sessionId,
    scope: token.scope,
    resource: token.resource,
    issuedAt: token.issuedAt,
    expiresAt: token.expiresAt,
    consumedAt:
      typeof token.consumedAt === "number" ? token.consumedAt : undefined,
    revokedAt: typeof token.revokedAt === "number" ? token.revokedAt : undefined,
  };
};

export const loadRefreshTokens = (
  filePath: string,
): Map<string, RefreshTokenRecord> => {
  if (loadedFrom === filePath) {
    return refreshTokens;
  }
  refreshTokens.clear();
  loadedFrom = filePath;

  let decoded: unknown;
  try {
    decoded = JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return refreshTokens;
    }
    throw error;
  }

  const stored = Array.isArray((decoded as RefreshTokenStoreFile).refreshTokens)
    ? (decoded as RefreshTokenStoreFile).refreshTokens
    : [];
  for (const entry of stored) {
    const token = sanitizeRefreshTokenRecord(entry);
    if (token) {
      refreshTokens.set(token.id, token);
    }
  }
  return refreshTokens;
};

export const saveRefreshTokensAtomic = (
  filePath: string,
  values: Iterable<RefreshTokenRecord>,
): void => {
  const directory = path.dirname(filePath);
  fs.mkdirSync(directory, { recursive: true });
  const tempPath = path.join(
    directory,
    `.${path.basename(filePath)}.${process.pid}.${Date.now()}.tmp`,
  );
  const payload: RefreshTokenStoreFile = {
    version: 1,
    refreshTokens: Array.from(values).sort((a, b) => a.id.localeCompare(b.id)),
  };
  fs.writeFileSync(tempPath, `${JSON.stringify(payload, null, 2)}\n`, {
    mode: 0o600,
  });
  fs.renameSync(tempPath, filePath);
};

export class RefreshTokenStore {
  private readonly filePath: string;

  constructor(oauthClientStorePath: string) {
    this.filePath = refreshTokenStorePath(oauthClientStorePath);
    loadRefreshTokens(this.filePath);
  }

  issue(params: {
    clientId: string;
    sessionId: string;
    scope: string;
    resource: string;
    ttlSeconds: number;
    familyId?: string;
  }): { refreshToken: string; record: RefreshTokenRecord } {
    const id = randomTokenPart();
    const secret = randomTokenPart();
    const refreshToken = `${tokenPrefix}${id}.${secret}`;
    const now = Date.now();
    const record: RefreshTokenRecord = {
      id,
      tokenHash: hashToken(refreshToken),
      familyId: params.familyId ?? randomTokenPart(),
      clientId: params.clientId,
      sessionId: params.sessionId,
      scope: params.scope,
      resource: params.resource,
      issuedAt: now,
      expiresAt: now + params.ttlSeconds * 1000,
    };
    refreshTokens.set(id, record);
    this.persist();
    return { refreshToken, record };
  }

  lookup(refreshToken: string, now = Date.now()): RefreshTokenLookup {
    const id = parseTokenId(refreshToken);
    if (!id) {
      return { status: "invalid" };
    }
    const record = refreshTokens.get(id);
    if (!record || !timingSafeEqualHex(hashToken(refreshToken), record.tokenHash)) {
      return { status: "invalid" };
    }
    if (record.revokedAt !== undefined) {
      return { status: "revoked", record };
    }
    if (record.consumedAt !== undefined) {
      return { status: "consumed", record };
    }
    if (record.expiresAt < now) {
      return { status: "expired", record };
    }
    return { status: "valid", record };
  }

  consume(id: string, now = Date.now()): RefreshTokenRecord | null {
    const record = refreshTokens.get(id);
    if (!record || record.consumedAt !== undefined || record.revokedAt !== undefined) {
      return null;
    }
    record.consumedAt = now;
    this.persist();
    return record;
  }

  revokeFamily(familyId: string, now = Date.now()): void {
    for (const record of refreshTokens.values()) {
      if (record.familyId === familyId && record.revokedAt === undefined) {
        record.revokedAt = now;
      }
    }
    this.persist();
  }

  private persist(): void {
    saveRefreshTokensAtomic(this.filePath, refreshTokens.values());
  }
}
