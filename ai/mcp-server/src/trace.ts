import crypto from "node:crypto";
import type { Request } from "express";

const traceIdPattern = /^[a-zA-Z0-9._:-]{8,128}$/;
const w3cTraceparentPattern = /^[\da-f]{2}-([\da-f]{32})-[\da-f]{16}-[\da-f]{2}$/i;

const sanitizeTraceId = (value: string | undefined): string | null => {
  const trimmed = value?.trim();
  if (!trimmed) return null;

  const traceparent = w3cTraceparentPattern.exec(trimmed);
  if (traceparent?.[1] && !/^0+$/.test(traceparent[1])) {
    return traceparent[1].toLowerCase();
  }

  return traceIdPattern.test(trimmed) ? trimmed : null;
};

export const createTraceId = (): string => crypto.randomBytes(16).toString("hex");

export const traceIdFromRequest = (request: Request): string => {
  const traceparent = sanitizeTraceId(request.header("traceparent"));
  if (traceparent) return traceparent;

  const explicit =
    sanitizeTraceId(request.header("x-trace-id")) ??
    sanitizeTraceId(request.header("x-request-id")) ??
    sanitizeTraceId(request.header("cf-ray"));
  return explicit ?? createTraceId();
};

const traceparentTraceId = (traceId: string): string =>
  /^[\da-f]{32}$/i.test(traceId)
    ? traceId.toLowerCase()
    : crypto.createHash("sha256").update(traceId).digest("hex").slice(0, 32);

export const traceHeaders = (traceId: string): Record<string, string> => ({
  "x-trace-id": traceId,
  traceparent: `00-${traceparentTraceId(traceId)}-${crypto.randomBytes(8).toString("hex")}-01`,
});

declare global {
  namespace Express {
    interface Request {
      hostrTraceId?: string;
    }
  }
}
