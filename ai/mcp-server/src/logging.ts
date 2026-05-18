const sensitiveKeyPattern =
  /(authorization|access[_-]?token|refresh[_-]?token|id[_-]?token|jwt|secret|password|passwd|private[_-]?key|nsec|seed|mnemonic|preimage|signature|qrImage|nostrconnect)/i;

const maxLoggedStringLength = 1_000;

export type LogLevel = "debug" | "info" | "warn" | "error";

export const redactForLog = (value: unknown): unknown => {
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

  if (typeof value === "string" && value.length > maxLoggedStringLength) {
    return `${value.slice(0, maxLoggedStringLength)}... [truncated ${value.length} chars]`;
  }

  return value;
};

export const writeStructuredLog = (
  level: LogLevel,
  event: string,
  data: Record<string, unknown> = {},
): void => {
  const sink = level === "error" || level === "warn" ? process.stderr : process.stdout;
  sink.write(
    `${JSON.stringify({
      level,
      service: "hostr-mcp",
      event,
      time: new Date().toISOString(),
      ...(redactForLog(data) as Record<string, unknown>),
    })}\n`,
  );
};

export const auditLog = (
  event: string,
  data: Record<string, unknown> = {},
): void => {
  writeStructuredLog("info", event, { audit: true, ...data });
};
