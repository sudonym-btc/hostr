import fs from "node:fs";
import path from "node:path";

export type HostrSessionAccount = {
  pubkey: string;
  metadata?: Record<string, unknown>;
  connectedAt: number;
  updatedAt: number;
};

export type HostrMcpSession = {
  sessionId: string;
  activePubkey?: string;
  accounts: HostrSessionAccount[];
  createdAt: number;
  updatedAt: number;
};

type SessionStoreFile = {
  version: 1;
  sessions: HostrMcpSession[];
};

const sessions = new Map<string, HostrMcpSession>();
let loadedFrom: string | null = null;

const sessionStorePath = (oauthClientStorePath: string): string =>
  path.join(path.dirname(oauthClientStorePath), "mcp-sessions.json");

const sanitizeMetadata = (
  value: unknown,
): Record<string, unknown> | undefined =>
  value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;

const sanitizeAccount = (value: unknown): HostrSessionAccount | null => {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  const account = value as Record<string, unknown>;
  if (typeof account.pubkey !== "string" || account.pubkey.trim() === "") {
    return null;
  }
  const now = Date.now();
  return {
    pubkey: account.pubkey,
    metadata: sanitizeMetadata(account.metadata),
    connectedAt:
      typeof account.connectedAt === "number" ? account.connectedAt : now,
    updatedAt: typeof account.updatedAt === "number" ? account.updatedAt : now,
  };
};

const sanitizeSession = (value: unknown): HostrMcpSession | null => {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  const session = value as Record<string, unknown>;
  if (
    typeof session.sessionId !== "string" ||
    session.sessionId.trim() === ""
  ) {
    return null;
  }
  const accounts = Array.isArray(session.accounts)
    ? session.accounts.map(sanitizeAccount).filter((entry) => entry !== null)
    : [];
  const activePubkey =
    typeof session.activePubkey === "string" &&
    accounts.some((account) => account.pubkey === session.activePubkey)
      ? session.activePubkey
      : accounts[0]?.pubkey;
  const now = Date.now();
  return {
    sessionId: session.sessionId,
    activePubkey,
    accounts,
    createdAt:
      typeof session.createdAt === "number" ? session.createdAt : now,
    updatedAt:
      typeof session.updatedAt === "number" ? session.updatedAt : now,
  };
};

export const loadMcpSessions = (filePath: string): Map<string, HostrMcpSession> => {
  if (loadedFrom === filePath) {
    return sessions;
  }
  sessions.clear();
  loadedFrom = filePath;

  let decoded: unknown;
  try {
    decoded = JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return sessions;
    }
    throw error;
  }

  const stored = Array.isArray((decoded as SessionStoreFile).sessions)
    ? (decoded as SessionStoreFile).sessions
    : [];
  for (const entry of stored) {
    const session = sanitizeSession(entry);
    if (session) {
      sessions.set(session.sessionId, session);
    }
  }
  return sessions;
};

export const saveMcpSessionsAtomic = (
  filePath: string,
  values: Iterable<HostrMcpSession>,
): void => {
  const directory = path.dirname(filePath);
  fs.mkdirSync(directory, { recursive: true });
  const tempPath = path.join(
    directory,
    `.${path.basename(filePath)}.${process.pid}.${Date.now()}.tmp`,
  );
  const payload: SessionStoreFile = {
    version: 1,
    sessions: Array.from(values).sort((a, b) =>
      a.sessionId.localeCompare(b.sessionId),
    ),
  };
  fs.writeFileSync(tempPath, `${JSON.stringify(payload, null, 2)}\n`, {
    mode: 0o600,
  });
  fs.renameSync(tempPath, filePath);
};

export class McpSessionStore {
  private readonly filePath: string;

  constructor(oauthClientStorePath: string) {
    this.filePath = sessionStorePath(oauthClientStorePath);
    loadMcpSessions(this.filePath);
  }

  get(sessionId: string): HostrMcpSession {
    const existing = sessions.get(sessionId);
    if (existing) {
      return existing;
    }
    const now = Date.now();
    const created: HostrMcpSession = {
      sessionId,
      accounts: [],
      createdAt: now,
      updatedAt: now,
    };
    sessions.set(sessionId, created);
    this.persist();
    return created;
  }

  addOrUpdateAccount(params: {
    sessionId: string;
    pubkey: string;
    metadata?: Record<string, unknown>;
  }): HostrMcpSession {
    const session = this.get(params.sessionId);
    const now = Date.now();
    const existing = session.accounts.find(
      (account) => account.pubkey === params.pubkey,
    );
    if (existing) {
      existing.metadata = params.metadata ?? existing.metadata;
      existing.updatedAt = now;
    } else {
      session.accounts.push({
        pubkey: params.pubkey,
        metadata: params.metadata,
        connectedAt: now,
        updatedAt: now,
      });
    }
    session.activePubkey = params.pubkey;
    session.updatedAt = now;
    this.persist();
    return session;
  }

  updateAccountMetadata(
    sessionId: string,
    pubkey: string,
    metadata: Record<string, unknown> | undefined,
  ): HostrMcpSession {
    const session = this.get(sessionId);
    const account = session.accounts.find((entry) => entry.pubkey === pubkey);
    if (account) {
      account.metadata = metadata ?? account.metadata;
      account.updatedAt = Date.now();
      session.updatedAt = account.updatedAt;
      this.persist();
    }
    return session;
  }

  switchActive(sessionId: string, pubkey: string): HostrMcpSession {
    const session = this.get(sessionId);
    if (!session.accounts.some((account) => account.pubkey === pubkey)) {
      throw new Error("unknown_session_account");
    }
    session.activePubkey = pubkey;
    session.updatedAt = Date.now();
    this.persist();
    return session;
  }

  removeAccount(sessionId: string, pubkey: string): HostrMcpSession {
    const session = this.get(sessionId);
    session.accounts = session.accounts.filter(
      (account) => account.pubkey !== pubkey,
    );
    if (session.activePubkey === pubkey) {
      session.activePubkey = session.accounts[0]?.pubkey;
    }
    session.updatedAt = Date.now();
    this.persist();
    return session;
  }

  clear(sessionId: string): HostrMcpSession {
    const session = this.get(sessionId);
    session.accounts = [];
    session.activePubkey = undefined;
    session.updatedAt = Date.now();
    this.persist();
    return session;
  }

  private persist(): void {
    saveMcpSessionsAtomic(this.filePath, sessions.values());
  }
}
