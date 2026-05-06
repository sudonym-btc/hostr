import express from "express";
import http from "node:http";
import https from "node:https";
import type { NextFunction, Request, Response } from "express";
import type { AppConfig } from "../config.js";
import type { HostrDaemonClient } from "../daemon/client.js";
import { createOAuthRouter } from "../auth/oauth.js";
import { handleMcpRequest } from "../mcp/server.js";
import { handleImageUpload } from "./uploads.js";
import { getPaymentAsset, listPaymentAssets } from "../payment/assets.js";
import { traceHeaders, traceIdFromRequest } from "../trace.js";
import { redactForLog, writeStructuredLog } from "../logging.js";

const hasLoggableFields = (value: unknown) =>
  Boolean(value && typeof value === "object" && Object.keys(value).length > 0);

const canReachDevProxyTarget = async (target: string): Promise<boolean> => {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 350);
  try {
    const response = await fetch(new URL("/health", target), {
      signal: controller.signal,
    });
    return response.ok;
  } catch {
    return false;
  } finally {
    clearTimeout(timeout);
  }
};

const proxyToDevTarget = (
  target: string,
  request: Request,
  response: Response,
  next: NextFunction,
) => {
  const destination = new URL(request.originalUrl, target);
  const client = destination.protocol === "https:" ? https : http;
  const traceId = request.hostrTraceId ?? traceIdFromRequest(request);
  const headers = {
    ...request.headers,
    host: destination.host,
    "x-forwarded-host": request.headers.host ?? destination.host,
    "x-forwarded-proto": request.protocol,
    "x-hostr-dev-proxy": "1",
    ...traceHeaders(traceId),
  };
  const proxyRequest = client.request(
    destination,
    {
      method: request.method,
      headers,
    },
    (proxyResponse) => {
      response.status(proxyResponse.statusCode ?? 502);
      for (const [key, value] of Object.entries(proxyResponse.headers)) {
        if (value !== undefined) {
          response.setHeader(key, value);
        }
      }
      proxyResponse.pipe(response);
    },
  );

  proxyRequest.on("error", () => next());
  request.pipe(proxyRequest);
};

const attachTrace = (
  request: Request,
  response: Response,
  next: NextFunction,
) => {
  const traceId = traceIdFromRequest(request);
  request.hostrTraceId = traceId;
  response.setHeader("x-trace-id", traceId);
  next();
};

const devProxy = (config: AppConfig) => {
  const target = config.devProxyTarget;
  return async (request: Request, response: Response, next: NextFunction) => {
    if (
      !target ||
      config.environmentLabel !== "development" ||
      request.header("x-hostr-dev-proxy")
    ) {
      next();
      return;
    }

    if (!(await canReachDevProxyTarget(target))) {
      next();
      return;
    }

    proxyToDevTarget(target, request, response, next);
  };
};

const logRequest = (
  request: Request,
  response: Response,
  next: NextFunction,
) => {
  const startedAt = Date.now();

  response.on("finish", () => {
    const durationMs = Date.now() - startedAt;
    const requestDetails = {
      traceId: request.hostrTraceId,
      ...(hasLoggableFields(request.params)
        ? { params: redactForLog(request.params) }
        : {}),
      ...(hasLoggableFields(request.query)
        ? { query: redactForLog(request.query) }
        : {}),
      ...(hasLoggableFields(request.body)
        ? { body: redactForLog(request.body) }
        : {}),
    };
    writeStructuredLog("info", "http.request", {
      method: request.method,
      path: request.path,
      statusCode: response.statusCode,
      durationMs,
      ...requestDetails,
    });
  });

  next();
};

const requestBodyErrorHandler = (
  error: unknown,
  _request: Request,
  response: Response,
  next: NextFunction,
) => {
  if (
    error &&
    typeof error === "object" &&
    "type" in error &&
    error.type === "entity.too.large"
  ) {
    response.status(413).json({
      error: "request_body_too_large",
      error_description:
        "The MCP request body is too large. Use a public image URL or reduce the number of original images in this request.",
    });
    return;
  }

  next(error);
};

export const createApp = (config: AppConfig, daemon: HostrDaemonClient) => {
  const app = express();

  app.disable("x-powered-by");
  app.use(attachTrace);
  app.use(devProxy(config));
  app.use(logRequest);
  app.use(express.urlencoded({ extended: false, limit: config.requestBodyLimit }));
  app.use(express.json({ limit: config.requestBodyLimit }));
  app.use(requestBodyErrorHandler);

  app.get("/health", (_request, response) => {
    response.json({
      status: "ok",
      service: "hostr-mcp",
      name: config.displayName,
      environment: config.environmentLabel,
      image: {
        revision: config.imageRevision,
        created: config.imageCreated,
        source: config.imageSource,
      },
    });
  });

  app.get("/ready", async (request, response) => {
    const traceId = request.hostrTraceId ?? traceIdFromRequest(request);
    const startedAt = Date.now();
    const checks: Record<string, unknown> = {
      config: {
        ok: Boolean(config.mcpResource && config.issuer && config.blossomUploadUrl),
      },
    };
    let ready = true;

    try {
      await daemon.describe({ traceId, timeoutMs: 2_500 });
      checks.daemon = { ok: true };
    } catch (error) {
      ready = false;
      checks.daemon = {
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      };
    }

    response.status(ready ? 200 : 503).json({
      status: ready ? "ready" : "not_ready",
      service: "hostr-mcp",
      name: config.displayName,
      environment: config.environmentLabel,
      image: {
        revision: config.imageRevision,
        created: config.imageCreated,
        source: config.imageSource,
      },
      traceId,
      elapsedMs: Date.now() - startedAt,
      checks,
    });
  });

  app.get("/assets/payment-qr/:id.png", (request, response) => {
    const id = request.params.id;
    const asset = id ? getPaymentAsset(id) : undefined;
    if (!asset || asset.qrPng.length === 0) {
      response.sendStatus(404);
      return;
    }
    response
      .type("image/png")
      .set("Cache-Control", "private, max-age=86400")
      .send(asset.qrPng);
  });

  app.get("/assets/payment-invoice/:id.txt", (request, response) => {
    const id = request.params.id;
    const asset = id ? getPaymentAsset(id) : undefined;
    if (!asset) {
      response.sendStatus(404);
      return;
    }
    response
      .type("text/plain")
      .set("Cache-Control", "private, max-age=86400")
      .send(asset.invoice);
  });

  app.get("/assets/qr-text/:id.txt", (request, response) => {
    const id = request.params.id;
    const asset = id ? getPaymentAsset(id) : undefined;
    if (!asset) {
      response.sendStatus(404);
      return;
    }
    response
      .type("text/plain")
      .set("Cache-Control", "private, max-age=86400")
      .send(asset.invoice);
  });

  if (config.environmentLabel !== "production") {
    app.get("/assets/payment", (_request, response) => {
      const assets = listPaymentAssets();
      const baseUrl = config.publicAssetBaseUrl.replace(/\/+$/, "");
      response.json({
        count: assets.length,
        assets: assets.map((asset) => ({
          ...asset,
          ...(asset.qrUrlPath ? { qrUrl: `${baseUrl}${asset.qrUrlPath}` } : {}),
          textUrl: `${baseUrl}${asset.textUrlPath}`,
          invoiceUrl: `${baseUrl}${asset.invoiceUrlPath}`,
        })),
      });
    });
  }

  app.use(createOAuthRouter(config, daemon));

  app.post("/mcp/uploads/images", handleImageUpload(config));
  app.post("/upload/images", handleImageUpload(config));

  app.all("/mcp", handleMcpRequest(config, daemon));

  return app;
};
