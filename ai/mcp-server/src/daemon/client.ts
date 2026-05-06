import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { EventEmitter } from "node:events";
import { createInterface } from "node:readline";
import type { AppConfig } from "../config.js";
import type { HostrActionId } from "../generated/hostr-actions.js";

type PendingRequest = {
  method: string;
  startedAt: number;
  resolve: (value: unknown) => void;
  reject: (error: Error) => void;
  timeout: NodeJS.Timeout;
};

type HostrDaemonError = {
  code?: string;
  message?: string;
  details?: unknown;
};

export type HostrDaemonCallResult = {
  ok: boolean;
  command: string;
  environment: string;
  dryRun: boolean;
  data?: unknown;
  warnings?: unknown[];
  errors?: unknown[];
};

export type HostrDaemonNotification = {
  method: string;
  params?: Record<string, unknown>;
};

export type OAuthNostrConnectStartResult = HostrDaemonCallResult & {
  data?: {
    requestId?: string;
    pending?: boolean;
    nostrconnect?: string;
    qr?: string;
    qrImage?: string;
  };
};

export type OAuthNostrConnectCompleteResult = HostrDaemonCallResult & {
  data?: {
    authenticated?: boolean;
    pubkey?: string;
    credentialType?: string;
  };
};

export type HostrImageUploadResult = HostrDaemonCallResult & {
  data?: {
    url?: string;
    sha256?: string;
    size?: number;
    type?: string;
    serverUrl?: string;
  };
};

export class HostrDaemonClient {
  private child: ChildProcessWithoutNullStreams | null = null;
  private nextId = 1;
  private readonly pending = new Map<string, PendingRequest>();
  private readonly notifications = new EventEmitter();

  constructor(private readonly config: AppConfig) {}

  async callAction(params: {
    pubkey?: string;
    action: HostrActionId;
    input: Record<string, unknown>;
    notificationToken?: string;
    timeoutMs?: number;
  }): Promise<HostrDaemonCallResult> {
    const { timeoutMs, ...requestParams } = params;
    return (await this.request(
      "callAction",
      requestParams,
      timeoutMs,
    )) as HostrDaemonCallResult;
  }

  onNotification(
    listener: (notification: HostrDaemonNotification) => void,
  ): () => void {
    this.notifications.on("notification", listener);
    return () => this.notifications.off("notification", listener);
  }

  async describe(): Promise<unknown> {
    return this.request("describe", {});
  }

  async visibleActions(params: { pubkey?: string }): Promise<unknown> {
    return this.request("visibleActions", params);
  }

  async uploadImage(params: {
    pubkey?: string;
    base64: string;
    mime?: string;
    filename?: string;
  }): Promise<HostrImageUploadResult> {
    return (await this.request("uploadImage", params)) as HostrImageUploadResult;
  }

  async startOAuthNostrConnect(params: {
    requestId: string;
    regenerate?: boolean;
  }): Promise<OAuthNostrConnectStartResult> {
    return (await this.request(
      "startOAuthNostrConnect",
      params,
    )) as OAuthNostrConnectStartResult;
  }

  async completeOAuthNostrConnect(params: {
    requestId: string;
    timeoutSeconds?: number;
    timeoutMs?: number;
  }): Promise<OAuthNostrConnectCompleteResult> {
    const { timeoutMs, ...requestParams } = params;
    return (await this.request(
      "completeOAuthNostrConnect",
      requestParams,
      timeoutMs,
    )) as OAuthNostrConnectCompleteResult;
  }

  async close(): Promise<void> {
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timeout);
      pending.reject(new Error("Hostr daemon client closed"));
    }
    this.pending.clear();

    const child = this.child;
    this.child = null;
    if (!child || child.killed) {
      return;
    }

    await new Promise<void>((resolve) => {
      child.once("exit", () => resolve());
      child.kill("SIGTERM");
      setTimeout(() => {
        if (!child.killed) {
          child.kill("SIGKILL");
        }
        resolve();
      }, 1_000).unref();
    });
  }

  private async request(
    method: string,
    params: unknown,
    timeoutMs = this.config.hostrDaemonTimeoutMs,
  ): Promise<unknown> {
    const child = this.ensureStarted();
    const id = String(this.nextId++);
    const payload = JSON.stringify({ id, method, params });
    this.log("request", { id, method, params: redactForLog(params) });

    const response = new Promise<unknown>((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.pending.delete(id);
        this.log("timeout", {
          id,
          method,
          timeoutMs,
        });
        reject(new Error(`Hostr daemon request timed out: ${method}`));
      }, timeoutMs);
      this.pending.set(id, {
        method,
        startedAt: Date.now(),
        resolve,
        reject,
        timeout,
      });
    });

    child.stdin.write(`${payload}\n`);
    return response;
  }

  private ensureStarted(): ChildProcessWithoutNullStreams {
    if (this.child && !this.child.killed) {
      return this.child;
    }

    const child = spawn(
      this.config.hostrDaemon.command,
      this.config.hostrDaemon.args,
      {
        cwd: this.config.hostrDaemon.cwd,
        env: {
          ...process.env,
          ...this.config.hostrDaemon.env,
        },
        stdio: ["pipe", "pipe", "pipe"],
      },
    );
    this.child = child;
    this.log("spawn", {
      pid: child.pid,
      command: this.config.hostrDaemon.command,
      args: this.config.hostrDaemon.args,
      cwd: this.config.hostrDaemon.cwd,
      env: redactForLog(this.config.hostrDaemon.env),
    });

    const lines = createInterface({ input: child.stdout });
    lines.on("line", (line) => this.handleLine(line));
    child.stderr.on("data", (chunk) => {
      writePrefixedLines("[hostr-daemon stderr]", chunk.toString());
    });
    child.once("exit", (code, signal) => {
      this.child = null;
      this.log("exit", {
        pid: child.pid,
        code,
        signal,
        pendingRequests: this.pending.size,
      });
      const error = new Error(
        `Hostr daemon exited (${signal ?? `code ${code ?? "unknown"}`})`,
      );
      for (const pending of this.pending.values()) {
        clearTimeout(pending.timeout);
        pending.reject(error);
      }
      this.pending.clear();
    });
    child.once("error", (error) => {
      this.log("spawn-error", {
        pid: child.pid,
        message: error.message,
      });
      for (const pending of this.pending.values()) {
        clearTimeout(pending.timeout);
        pending.reject(error);
      }
      this.pending.clear();
    });

    return child;
  }

  private handleLine(line: string): void {
    let decoded: unknown;
    try {
      decoded = JSON.parse(line);
    } catch {
      writePrefixedLines("[hostr-daemon stdout]", line);
      return;
    }
    if (!decoded || typeof decoded !== "object") {
      return;
    }
    const message = decoded as {
      id?: string | number;
      result?: unknown;
      error?: HostrDaemonError;
      method?: string;
      params?: unknown;
    };
    const id = String(message.id ?? "");
    const pending = this.pending.get(id);
    if (!pending) {
      if (typeof message.method === "string") {
        this.log("notification", {
          method: message.method,
          params: redactForLog(message.params),
        });
        this.notifications.emit("notification", {
          method: message.method,
          params:
            message.params &&
            typeof message.params === "object" &&
            !Array.isArray(message.params)
              ? (message.params as Record<string, unknown>)
              : undefined,
        } satisfies HostrDaemonNotification);
      }
      return;
    }
    clearTimeout(pending.timeout);
    this.pending.delete(id);
    const elapsedMs = Date.now() - pending.startedAt;

    if (message.error) {
      this.log("response-error", {
        id,
        method: pending.method,
        elapsedMs,
        error: redactForLog(message.error),
      });
      const error = new Error(
        message.error.message ?? "Hostr daemon request failed",
      );
      Object.assign(error, {
        code: message.error.code,
        details: message.error.details,
      });
      pending.reject(error);
      return;
    }
    this.log("response", {
      id,
      method: pending.method,
      elapsedMs,
      result: redactForLog(message.result),
    });
    pending.resolve(message.result);
  }

  private log(event: string, data: Record<string, unknown>): void {
    process.stderr.write(
      `[hostr-daemon-client] ${JSON.stringify({ event, ...data })}\n`,
    );
  }
}

export const createHostrDaemonClient = (config: AppConfig) =>
  new HostrDaemonClient(config);

const sensitiveKeyPattern =
  /(secret|token|authorization|cookie|password|private|nsec|jwt|qrImage|nostrconnect)/i;

const redactForLog = (value: unknown): unknown => {
  if (Array.isArray(value)) {
    return value.map((item) => redactForLog(item));
  }
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>).map(([key, entry]) => [
        key,
        sensitiveKeyPattern.test(key) ? "[redacted]" : redactForLog(entry),
      ]),
    );
  }
  if (typeof value === "string" && value.length > 1_000) {
    return `${value.slice(0, 1_000)}... [truncated ${value.length} chars]`;
  }
  return value;
};

const writePrefixedLines = (prefix: string, text: string): void => {
  for (const line of text.split(/\r?\n/)) {
    if (line.length === 0) continue;
    process.stderr.write(`${prefix} ${line}\n`);
  }
};
