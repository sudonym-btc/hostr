import fs from "node:fs";
import path from "node:path";

export type RegisteredClient = {
  clientId: string;
  clientName?: string;
  redirectUris: string[];
  scope: string;
  grantTypes: string[];
  responseTypes: string[];
  tokenEndpointAuthMethod: "none";
  clientIdIssuedAt: number;
};

type ClientStoreFile = {
  version: 1;
  clients: RegisteredClient[];
};

const isStringArray = (value: unknown): value is string[] =>
  Array.isArray(value) && value.every((entry) => typeof entry === "string");

const sanitizeRegisteredClient = (value: unknown): RegisteredClient | null => {
  if (!value || typeof value !== "object" || Array.isArray(value)) {
    return null;
  }
  const client = value as Record<string, unknown>;
  if (
    typeof client.clientId !== "string" ||
    client.clientId.trim() === "" ||
    !isStringArray(client.redirectUris) ||
    typeof client.scope !== "string" ||
    !isStringArray(client.grantTypes) ||
    !isStringArray(client.responseTypes) ||
    client.tokenEndpointAuthMethod !== "none" ||
    typeof client.clientIdIssuedAt !== "number"
  ) {
    return null;
  }
  return {
    clientId: client.clientId,
    clientName:
      typeof client.clientName === "string" ? client.clientName : undefined,
    redirectUris: client.redirectUris,
    scope: client.scope,
    grantTypes: client.grantTypes,
    responseTypes: client.responseTypes,
    tokenEndpointAuthMethod: "none",
    clientIdIssuedAt: client.clientIdIssuedAt,
  };
};

export const loadRegisteredClients = (
  filePath: string,
): Map<string, RegisteredClient> => {
  let decoded: unknown;
  try {
    decoded = JSON.parse(fs.readFileSync(filePath, "utf8"));
  } catch (error) {
    if ((error as NodeJS.ErrnoException).code === "ENOENT") {
      return new Map();
    }
    throw error;
  }

  const clients = Array.isArray((decoded as ClientStoreFile).clients)
    ? (decoded as ClientStoreFile).clients
    : [];
  const result = new Map<string, RegisteredClient>();
  for (const entry of clients) {
    const client = sanitizeRegisteredClient(entry);
    if (client) {
      result.set(client.clientId, client);
    }
  }
  return result;
};

export const saveRegisteredClientsAtomic = (
  filePath: string,
  clients: Iterable<RegisteredClient>,
): void => {
  const directory = path.dirname(filePath);
  fs.mkdirSync(directory, { recursive: true });
  const tempPath = path.join(
    directory,
    `.${path.basename(filePath)}.${process.pid}.${Date.now()}.tmp`,
  );
  const payload: ClientStoreFile = {
    version: 1,
    clients: Array.from(clients).sort((a, b) =>
      a.clientId.localeCompare(b.clientId),
    ),
  };
  fs.writeFileSync(tempPath, `${JSON.stringify(payload, null, 2)}\n`, {
    mode: 0o600,
  });
  fs.renameSync(tempPath, filePath);
};
