import express from "express";
import http from "node:http";
import https from "node:https";
import type { NextFunction, Request, Response } from "express";
import type { AppConfig } from "../config.js";
import type { HostrDaemonClient } from "../daemon/client.js";
import { createOAuthRouter } from "../auth/oauth.js";
import { handleMcpRequest } from "../mcp/server.js";
import { getPaymentAsset, listPaymentAssets } from "../payment/assets.js";

const sensitiveKeyPattern =
  /(authorization|access[_-]?token|refresh[_-]?token|id[_-]?token|jwt|secret|password|passwd|private[_-]?key|seed|mnemonic|preimage|signature)/i;
const maxLoggedStringLength = 500;

const redactForLog = (value: unknown): unknown => {
  if (Array.isArray(value)) {
    return value.map((item) => redactForLog(item));
  }

  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([key, nestedValue]) => [
        key,
        sensitiveKeyPattern.test(key)
          ? "[redacted]"
          : redactForLog(nestedValue),
      ]),
    );
  }

  if (typeof value === "string" && value.length > maxLoggedStringLength) {
    return `${value.slice(0, maxLoggedStringLength)}...[truncated ${value.length - maxLoggedStringLength} chars]`;
  }

  return value;
};

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
  const headers = {
    ...request.headers,
    host: destination.host,
    "x-forwarded-host": request.headers.host ?? destination.host,
    "x-forwarded-proto": request.protocol,
    "x-hostr-dev-proxy": "1",
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
    const details =
      Object.keys(requestDetails).length > 0
        ? ` ${JSON.stringify(requestDetails)}`
        : "";

    console.log(
      `[hostr-mcp] ${request.method} ${request.path} -> ${response.statusCode} ${durationMs}ms${details}`,
    );
  });

  next();
};

export const createApp = (config: AppConfig, daemon: HostrDaemonClient) => {
  const app = express();

  app.disable("x-powered-by");
  app.use(devProxy(config));
  app.use(logRequest);
  app.use(express.urlencoded({ extended: false }));
  app.use(express.json({ limit: "1mb" }));

  app.get("/health", (_request, response) => {
    response.json({
      status: "ok",
      service: "hostr-mcp",
      name: config.displayName,
      environment: config.environmentLabel,
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

  app.all("/mcp", handleMcpRequest(config, daemon));

  return app;
};
