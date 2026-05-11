const trimTrailingSlash = (value: string): string => value.replace(/\/+$/, "");

const readBaseUrl = (): string => {
  const explicit = process.env.MCP_PUBLIC_BASE_URL;
  if (explicit && explicit.trim() !== "") {
    return trimTrailingSlash(explicit);
  }

  const domain = process.env.DOMAIN || "hostr.development";
  const scheme = domain.endsWith(".development") ? "https" : "https";
  return `${scheme}://ai.${domain}`;
};

const readPublicAssetBaseUrl = (baseUrl: string): string => {
  const explicit = process.env.MCP_PUBLIC_ASSET_BASE_URL;
  if (explicit && explicit.trim() !== "") {
    return trimTrailingSlash(explicit);
  }

  const domain = process.env.DOMAIN || "hostr.development";
  if (/^https?:\/\/(?:127\.0\.0\.1|localhost)(?::\d+)?$/i.test(baseUrl)) {
    return `https://ai.${domain}`;
  }

  return baseUrl;
};

const readPublicAppBaseUrl = (): string => {
  const explicit = process.env.HOSTR_PUBLIC_APP_BASE_URL;
  if (explicit && explicit.trim() !== "") {
    return trimTrailingSlash(explicit);
  }

  const domain = process.env.DOMAIN || "hostr.development";
  if (domain === "hostr.network") {
    return "https://hostr.network";
  }
  if (domain.includes("staging.")) {
    return `https://${domain}`;
  }
  return `https://${domain}`;
};

const readQrImageUrlTemplate = (): string | undefined => {
  const explicit = process.env.HOSTR_QR_IMAGE_URL_TEMPLATE;
  if (explicit !== undefined) {
    const value = explicit.trim();
    return value === "" || value.toLowerCase() === "local" ? undefined : value;
  }

  return "https://api.qrserver.com/v1/create-qr-code/?size=240x240&data={data}";
};

const readEnvironmentLabel = (): "production" | "staging" | "development" => {
  const profile = process.env.COMPOSE_PROFILES || "";
  const domain = process.env.DOMAIN || "hostr.development";

  if (profile.includes("prod") || domain === "hostr.network") {
    return "production";
  }
  if (profile.includes("staging") || domain.includes("staging.")) {
    return "staging";
  }
  return "development";
};

const readBlossomUploadUrl = (): string => {
  const explicit = process.env.HOSTR_BLOSSOM_UPLOAD_URL;
  if (explicit && explicit.trim() !== "") {
    return trimTrailingSlash(explicit);
  }

  const domain = process.env.DOMAIN || "hostr.development";
  return `https://blossom.${domain}/upload`;
};

const readOAuthClientStorePath = (): string => {
  const explicit = process.env.MCP_OAUTH_CLIENT_STORE_PATH;
  if (explicit && explicit.trim() !== "") {
    return explicit;
  }

  const stateDir = process.env.HOSTR_DAEMON_STATE_DIR;
  if (stateDir && stateDir.trim() !== "") {
    return `${trimTrailingSlash(stateDir)}/oauth-clients.json`;
  }

  return "/tmp/hostr-mcp/oauth-clients.json";
};

const environmentDescriptionFor = (
  environmentLabel: "production" | "staging" | "development",
): string | undefined => {
  switch (environmentLabel) {
    case "production":
      return undefined;
    case "staging":
      return "Staging";
    case "development":
      return "Development";
  }
};

const repoRoot = new URL("../../../", import.meta.url);

const defaultDaemonArgs = (
  command: string,
  environmentLabel: "production" | "staging" | "development",
  stateDir: string | undefined,
): string[] => {
  const environmentArgs = ["--stdio", "--env", environmentLabel];
  const stateArgs =
    stateDir && stateDir.trim() !== "" ? ["--state-dir", stateDir] : [];

  if (
    command.endsWith("hostr-daemon") ||
    command.endsWith("hostr-daemon.exe") ||
    command.endsWith("hostr_daemon") ||
    command.endsWith("hostr_daemon.exe")
  ) {
    return [...environmentArgs, ...stateArgs];
  }
  return ["bin/hostr_daemon.dart", ...environmentArgs, ...stateArgs];
};

const parseDaemonArgs = (
  command: string,
  value: string | undefined,
  environmentLabel: "production" | "staging" | "development",
  stateDir: string | undefined,
): string[] => {
  if (!value || value.trim() === "") {
    return defaultDaemonArgs(command, environmentLabel, stateDir);
  }
  return value
    .split(/\s+/)
    .map((part) => part.trim())
    .filter((part) => part !== "");
};

export type AppConfig = {
  issuer: string;
  mcpResource: string;
  publicAssetBaseUrl: string;
  publicAppBaseUrl: string;
  qrImageUrlTemplate?: string;
  devProxyTarget?: string;
  environmentLabel: "production" | "staging" | "development";
  displayName: string;
  environmentDescription?: string;
  port: number;
  requestBodyLimit: string;
  blossomUploadUrl: string;
  oauthClientStorePath: string;
  jwtSecret: Uint8Array;
  accessTokenTtlSeconds: number;
  refreshTokenTtlSeconds: number;
  imageRevision?: string;
  imageCreated?: string;
  imageSource?: string;
  hostrDaemon: {
    command: string;
    args: string[];
    cwd: string;
    env: Record<string, string>;
  };
  hostrDaemonTimeoutMs: number;
};

const environmentLabel = readEnvironmentLabel();
const hostrDaemonCommand = process.env.HOSTR_DAEMON_COMMAND || "dart";
const baseUrl = readBaseUrl();
const hostrDaemonStorage =
  process.env.HOSTR_CLI_STORAGE ||
  (environmentLabel === "development" ? "insecure-file" : "file");

export const config: AppConfig = {
  issuer: baseUrl,
  mcpResource: `${baseUrl}/mcp`,
  publicAssetBaseUrl: readPublicAssetBaseUrl(baseUrl),
  publicAppBaseUrl: readPublicAppBaseUrl(),
  qrImageUrlTemplate: readQrImageUrlTemplate(),
  devProxyTarget:
    process.env.HOSTR_MCP_DEV_PROXY_TARGET &&
    process.env.HOSTR_MCP_DEV_PROXY_TARGET.trim() !== ""
      ? trimTrailingSlash(process.env.HOSTR_MCP_DEV_PROXY_TARGET)
      : undefined,
  environmentLabel,
  displayName: "Hostr",
  environmentDescription: environmentDescriptionFor(environmentLabel),
  port: Number.parseInt(process.env.PORT || "8787", 10),
  requestBodyLimit: process.env.MCP_REQUEST_BODY_LIMIT || "100mb",
  blossomUploadUrl: readBlossomUploadUrl(),
  oauthClientStorePath: readOAuthClientStorePath(),
  jwtSecret: new TextEncoder().encode(
    process.env.MCP_JWT_SECRET || "hostr-development-mcp-secret-change-me",
  ),
  accessTokenTtlSeconds: Number.parseInt(
    process.env.MCP_ACCESS_TOKEN_TTL_SECONDS || "3600",
    10,
  ),
  refreshTokenTtlSeconds: Number.parseInt(
    process.env.MCP_REFRESH_TOKEN_TTL_SECONDS || "2592000",
    10,
  ),
  hostrDaemon: {
    command: hostrDaemonCommand,
    args: parseDaemonArgs(
      hostrDaemonCommand,
      process.env.HOSTR_DAEMON_ARGS,
      environmentLabel,
      process.env.HOSTR_DAEMON_STATE_DIR,
    ),
    cwd:
      process.env.HOSTR_DAEMON_CWD || new URL("hostr_cli/", repoRoot).pathname,
    env: {
      HOSTR_CLI_ALLOW_INSECURE_STORAGE:
        process.env.HOSTR_CLI_ALLOW_INSECURE_STORAGE ||
        (environmentLabel === "production" ? "0" : "1"),
      HOSTR_CLI_STORAGE: hostrDaemonStorage,
    },
  },
  hostrDaemonTimeoutMs: Number.parseInt(
    process.env.HOSTR_DAEMON_TIMEOUT_MS || "120000",
    10,
  ),
  imageRevision:
    process.env.HOSTR_IMAGE_REVISION && process.env.HOSTR_IMAGE_REVISION.trim() !== ""
      ? process.env.HOSTR_IMAGE_REVISION
      : undefined,
  imageCreated:
    process.env.HOSTR_IMAGE_CREATED && process.env.HOSTR_IMAGE_CREATED.trim() !== ""
      ? process.env.HOSTR_IMAGE_CREATED
      : undefined,
  imageSource:
    process.env.HOSTR_IMAGE_SOURCE && process.env.HOSTR_IMAGE_SOURCE.trim() !== ""
      ? process.env.HOSTR_IMAGE_SOURCE
      : undefined,
};

export const scopesSupported = ["hostr:read", "hostr:write"];
