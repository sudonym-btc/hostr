import crypto from "node:crypto";
import type { Request, Response } from "express";
import type { AppConfig } from "../config.js";
import { bearerToken } from "../auth/bearer.js";
import { verifyAccessToken } from "../auth/jwt.js";
import type { HostrDaemonClient } from "../daemon/client.js";
import { traceHeaders, traceIdFromRequest } from "../trace.js";

export type UploadedImage = {
  bytes: Buffer;
  mime?: string;
  filename?: string;
};

export type BlossomDescriptor = {
  url?: string;
  sha256?: string;
  size?: number;
  type?: string;
  uploaded?: string | number;
};

export type HostrImageUploadResult = {
  ok: true;
  upload: BlossomDescriptor & {
    sha256: string;
    size: number;
    mime?: string;
    filename?: string;
    serverUrl: string;
  };
  usage: {
    image: {
      url?: string;
    };
    listingImage: {
      url?: string;
    };
    profileImage: {
      url?: string;
    };
  };
};

const record = (value: unknown): Record<string, unknown> | null =>
  value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;

const stringValue = (value: unknown): string | undefined =>
  typeof value === "string" && value.trim() !== "" ? value.trim() : undefined;

const numberValue = (value: unknown): number | undefined =>
  typeof value === "number" && Number.isFinite(value) ? value : undefined;

const parseByteLimit = (value: string, fallback: number): number => {
  const match = /^(\d+(?:\.\d+)?)\s*(b|kb|mb|gb)?$/i.exec(value.trim());
  if (!match) {
    return fallback;
  }
  const amount = Number(match[1]);
  const unit = (match[2] ?? "b").toLowerCase();
  const multiplier =
    unit === "gb"
      ? 1024 * 1024 * 1024
      : unit === "mb"
        ? 1024 * 1024
        : unit === "kb"
          ? 1024
          : 1;
  return Math.floor(amount * multiplier);
};

const contentTypeHeader = (request: Request): string =>
  request.header("content-type") ?? "";

const boundaryFromContentType = (contentType: string): string | null => {
  const match = /(?:^|;)\s*boundary=(?:"([^"]+)"|([^;]+))/i.exec(contentType);
  return match?.[1] ?? match?.[2]?.trim() ?? null;
};

const readRequestBuffer = async (
  request: Request,
  maxBytes: number,
): Promise<Buffer> =>
  new Promise((resolve, reject) => {
    const chunks: Buffer[] = [];
    let size = 0;
    request.on("data", (chunk: Buffer) => {
      size += chunk.length;
      if (size > maxBytes) {
        reject(new Error("request_too_large"));
        request.destroy();
        return;
      }
      chunks.push(chunk);
    });
    request.on("end", () => resolve(Buffer.concat(chunks, size)));
    request.on("error", reject);
  });

const headerValue = (headers: string, name: string): string | null => {
  const pattern = new RegExp(`^${name}:\\s*(.+)$`, "im");
  return pattern.exec(headers)?.[1]?.trim() ?? null;
};

const dispositionParam = (
  disposition: string | null,
  name: string,
): string | null => {
  if (!disposition) {
    return null;
  }
  const pattern = new RegExp(`${name}="([^"]*)"`, "i");
  return pattern.exec(disposition)?.[1] ?? null;
};

const trimMultipartBody = (body: Buffer): Buffer => {
  let start = 0;
  let end = body.length;
  if (body.subarray(0, 2).toString("latin1") === "\r\n") {
    start = 2;
  }
  if (body.subarray(end - 2).toString("latin1") === "\r\n") {
    end -= 2;
  }
  return body.subarray(start, end);
};

const parseMultipartImage = async (
  request: Request,
  maxBytes: number,
): Promise<UploadedImage> => {
  const boundary = boundaryFromContentType(contentTypeHeader(request));
  if (!boundary) {
    throw new Error("multipart_boundary_missing");
  }

  const payload = await readRequestBuffer(request, maxBytes);
  const delimiter = Buffer.from(`--${boundary}`, "latin1");
  let cursor = 0;
  while (cursor < payload.length) {
    const partStart = payload.indexOf(delimiter, cursor);
    if (partStart < 0) {
      break;
    }
    const nextPartStart = payload.indexOf(delimiter, partStart + delimiter.length);
    if (nextPartStart < 0) {
      break;
    }
    cursor = nextPartStart;
    let part = payload.subarray(partStart + delimiter.length, nextPartStart);
    const marker = part.subarray(0, 2).toString("latin1");
    if (marker === "--") {
      break;
    }
    part = trimMultipartBody(part);
    const headerEnd = part.indexOf(Buffer.from("\r\n\r\n", "latin1"));
    if (headerEnd < 0) {
      continue;
    }
    const headers = part.subarray(0, headerEnd).toString("latin1");
    const disposition = headerValue(headers, "content-disposition");
    const fieldName = dispositionParam(disposition, "name");
    const filename = dispositionParam(disposition, "filename") ?? undefined;
    if (fieldName !== "file" && fieldName !== "image") {
      continue;
    }
    const bytes = part.subarray(headerEnd + 4);
    if (bytes.length === 0) {
      throw new Error("empty_upload");
    }
    return {
      bytes,
      mime: headerValue(headers, "content-type") ?? undefined,
      filename,
    };
  }

  throw new Error("multipart_file_missing");
};

const parseRawImage = async (
  request: Request,
  maxBytes: number,
): Promise<UploadedImage> => {
  const bytes = await readRequestBuffer(request, maxBytes);
  if (bytes.length === 0) {
    throw new Error("empty_upload");
  }
  return {
    bytes,
    mime: contentTypeHeader(request) || undefined,
    filename: request.header("x-filename") ?? undefined,
  };
};

const uploadError = (response: Response, status: number, code: string) => {
  response.status(status).json({
    error: code,
    error_description:
      code === "request_too_large"
        ? "The uploaded image is too large for this Hostr MCP upload endpoint."
        : "Could not parse the image upload. Send multipart/form-data with a file field named file, or send raw image bytes with an image/* content type.",
  });
};

const uploadToBlossom = async (
  config: AppConfig,
  upload: UploadedImage,
  sha256: string,
  traceId?: string,
): Promise<BlossomDescriptor> => {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 60_000);
  let response: globalThis.Response;
  let text: string;
  try {
    response = await fetch(config.blossomUploadUrl, {
      method: "PUT",
      headers: {
        "content-type": upload.mime ?? "application/octet-stream",
        "content-length": String(upload.bytes.length),
        "x-sha-256": sha256,
        ...(traceId ? traceHeaders(traceId) : {}),
        ...(upload.filename ? { "x-filename": upload.filename } : {}),
      },
      body: new Uint8Array(upload.bytes),
      signal: controller.signal,
    });
    text = await response.text();
  } finally {
    clearTimeout(timeout);
  }
  let data: unknown;
  try {
    data = text.trim() === "" ? undefined : JSON.parse(text);
  } catch {
    data = text;
  }
  if (!response.ok) {
    const detail =
      typeof data === "object" && data !== null ? data : { body: data };
    throw new Error(
      `Blossom upload failed with HTTP ${response.status}: ${JSON.stringify(detail)}`,
    );
  }
  if (!data || typeof data !== "object") {
    throw new Error("Blossom upload returned an empty or non-object response.");
  }
  return data as BlossomDescriptor;
};

export const uploadImageToBlossom = async (
  config: AppConfig,
  upload: UploadedImage,
  traceId?: string,
): Promise<HostrImageUploadResult> => {
  const sha256 = crypto.createHash("sha256").update(upload.bytes).digest("hex");
  const descriptor = await uploadToBlossom(config, upload, sha256, traceId);
  return {
    ok: true,
    upload: {
      ...descriptor,
      sha256,
      size: upload.bytes.length,
      mime: upload.mime,
      filename: upload.filename,
      serverUrl: config.blossomUploadUrl,
    },
    usage: {
      image: {
        url: descriptor.url,
      },
      listingImage: {
        url: descriptor.url,
      },
      profileImage: {
        url: descriptor.url,
      },
    },
  };
};

const uploadImageThroughDaemonSession = async (
  daemon: HostrDaemonClient | undefined,
  pubkey: string | undefined,
  upload: UploadedImage,
  traceId?: string,
): Promise<HostrImageUploadResult | null> => {
  if (!daemon || !pubkey) {
    return null;
  }

  try {
    const result = await daemon.uploadImage({
      pubkey,
      base64: upload.bytes.toString("base64"),
      mime: upload.mime,
      filename: upload.filename,
      traceId,
    });
    if (!result.ok) {
      return null;
    }
    const data = record(result.data);
    const url = stringValue(data?.url);
    if (!data || !url) {
      return null;
    }
    const sha256 =
      stringValue(data.sha256) ??
      crypto.createHash("sha256").update(upload.bytes).digest("hex");
    const size = numberValue(data.size) ?? upload.bytes.length;
    const type = stringValue(data.type) ?? upload.mime;
    return {
      ok: true,
      upload: {
        url,
        sha256,
        size,
        mime: upload.mime,
        filename: upload.filename,
        type,
        uploaded: stringValue(data.uploaded) ?? numberValue(data.uploaded),
        serverUrl: stringValue(data.serverUrl) ?? "hostr-daemon-session",
      },
      usage: {
        image: { url },
        listingImage: { url },
        profileImage: { url },
      },
    };
  } catch {
    return null;
  }
};

export const uploadImageWithBestAvailableAuth = async (
  config: AppConfig,
  daemon: HostrDaemonClient | undefined,
  pubkey: string | undefined,
  upload: UploadedImage,
  traceId?: string,
): Promise<HostrImageUploadResult> =>
  (await uploadImageThroughDaemonSession(daemon, pubkey, upload, traceId)) ??
  uploadImageToBlossom(config, upload, traceId);

export const handleImageUpload =
  (config: AppConfig, daemon?: HostrDaemonClient) =>
  async (request: Request, response: Response) => {
    const traceId = request.hostrTraceId ?? traceIdFromRequest(request);
    const contentType = contentTypeHeader(request);
    const contentTypeLower = contentType.toLowerCase();
    if (
      !contentTypeLower.startsWith("multipart/form-data") &&
      !contentTypeLower.startsWith("image/") &&
      !contentTypeLower.startsWith("application/octet-stream")
    ) {
      response.status(415).json({
        error: "unsupported_media_type",
        error_description:
          "Send multipart/form-data with a file field named file, or send raw image bytes with an image/* or application/octet-stream content type.",
      });
      return;
    }
    const maxBytes = parseByteLimit(config.requestBodyLimit, 100 * 1024 * 1024);
    let upload: UploadedImage;
    try {
      upload = contentTypeLower.startsWith("multipart/form-data")
        ? await parseMultipartImage(request, maxBytes)
        : await parseRawImage(request, maxBytes);
    } catch (error) {
      uploadError(
        response,
        error instanceof Error && error.message === "request_too_large"
          ? 413
          : 400,
        error instanceof Error ? error.message : "invalid_upload",
      );
      return;
    }

    let pubkey: string | undefined;
    const token = bearerToken(request);
    if (daemon && token) {
      try {
        pubkey = (await verifyAccessToken(config, token)).pubkey;
      } catch {
        pubkey = undefined;
      }
    }

    let result: HostrImageUploadResult;
    try {
      result = await uploadImageWithBestAvailableAuth(
        config,
        daemon,
        pubkey,
        upload,
        traceId,
      );
    } catch (error) {
      response.status(502).json({
        ok: false,
        traceId,
        error: "blossom_upload_failed",
        error_description:
          error instanceof Error ? error.message : "Blossom upload failed.",
      });
      return;
    }

    response.json({ ...result, traceId });
  };
