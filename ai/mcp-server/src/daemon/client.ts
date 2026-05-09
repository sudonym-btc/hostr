import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";
import { EventEmitter } from "node:events";
import { createInterface } from "node:readline";
import type { AppConfig } from "../config.js";
import type { HostrActionId } from "../generated/hostr-actions.js";
import { redactForLog, writeStructuredLog } from "../logging.js";

type PendingRequest = {
  method: string;
  traceId?: string;
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
    traceId?: string;
  }): Promise<HostrDaemonCallResult> {
    const { timeoutMs, traceId, ...requestParams } = params;
    return (await this.request(
      "callAction",
      requestParams,
      timeoutMs,
      traceId,
    )) as HostrDaemonCallResult;
  }

  onNotification(
    listener: (notification: HostrDaemonNotification) => void,
  ): () => void {
    this.notifications.on("notification", listener);
    return () => this.notifications.off("notification", listener);
  }

  async describe(options: { traceId?: string; timeoutMs?: number } = {}): Promise<unknown> {
    return this.request("describe", {}, options.timeoutMs, options.traceId);
  }

  async visibleActions(params: { pubkey?: string; traceId?: string }): Promise<unknown> {
    const { traceId, ...requestParams } = params;
    return this.request("visibleActions", requestParams, undefined, traceId);
  }

  async logoutSession(params: {
    pubkey: string;
    traceId?: string;
  }): Promise<HostrDaemonCallResult> {
    const { traceId, ...requestParams } = params;
    return (await this.request(
      "logoutSession",
      requestParams,
      undefined,
      traceId,
    )) as HostrDaemonCallResult;
  }

  async uploadImage(params: {
    pubkey?: string;
    base64: string;
    mime?: string;
    filename?: string;
    traceId?: string;
  }): Promise<HostrImageUploadResult> {
    const { traceId, ...requestParams } = params;
    return (await this.request(
      "uploadImage",
      requestParams,
      undefined,
      traceId,
    )) as HostrImageUploadResult;
  }

  async startOAuthNostrConnect(params: {
    requestId: string;
    regenerate?: boolean;
    traceId?: string;
  }): Promise<OAuthNostrConnectStartResult> {
    const { traceId, ...requestParams } = params;
    return (await this.request(
      "startOAuthNostrConnect",
      requestParams,
      undefined,
      traceId,
    )) as OAuthNostrConnectStartResult;
  }

  async completeOAuthNostrConnect(params: {
    requestId: string;
    timeoutSeconds?: number;
    timeoutMs?: number;
    traceId?: string;
  }): Promise<OAuthNostrConnectCompleteResult> {
    const { timeoutMs, traceId, ...requestParams } = params;
    return (await this.request(
      "completeOAuthNostrConnect",
      requestParams,
      timeoutMs,
      traceId,
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
    traceId?: string,
  ): Promise<unknown> {
    const child = this.ensureStarted();
    const id = String(this.nextId++);
    const payload = JSON.stringify({ id, method, traceId, params });
    this.log("request", { id, method, traceId, params: redactForLog(params) });

    const response = new Promise<unknown>((resolve, reject) => {
      const timeout = setTimeout(() => {
        this.pending.delete(id);
        this.log("timeout", {
          id,
          method,
          traceId,
          timeoutMs,
        });
        this.cancelDaemonRequest(id, method, traceId);
        reject(new Error(`Hostr daemon request timed out: ${method}`));
      }, timeoutMs);
      this.pending.set(id, {
        method,
        traceId,
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
          traceId: stringValue(
            message.params &&
              typeof message.params === "object" &&
              !Array.isArray(message.params)
              ? (message.params as Record<string, unknown>).traceId
              : undefined,
          ),
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
        traceId: pending.traceId,
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
      traceId: pending.traceId,
      elapsedMs,
      result: redactForLog(message.result),
    });
    pending.resolve(message.result);
  }

  private log(event: string, data: Record<string, unknown>): void {
    writeStructuredLog("debug", `daemon.${event}`, data);
  }

  private cancelDaemonRequest(
    requestId: string,
    method: string,
    traceId?: string,
  ): void {
    const child = this.child;
    if (!child || child.killed) {
      return;
    }
    const cancelId = `cancel-${requestId}`;
    const payload = JSON.stringify({
      id: cancelId,
      method: "cancel",
      traceId,
      params: { requestId },
    });
    this.log("cancel", { id: cancelId, requestId, method, traceId });
    child.stdin.write(`${payload}\n`);
  }
}

export const createHostrDaemonClient = (config: AppConfig) =>
  new HostrDaemonClient(config);

const writePrefixedLines = (prefix: string, text: string): void => {
  for (const line of text.split(/\r?\n/)) {
    if (line.length === 0) continue;
    writeStructuredLog("debug", "daemon.child.stderr", {
      prefix,
      line: redactForLog(line),
    });
  }
};

const stringValue = (value: unknown): string | undefined =>
  typeof value === "string" && value.trim() !== "" ? value : undefined;
