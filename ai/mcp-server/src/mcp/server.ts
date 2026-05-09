import type { Request, Response } from "express";
import { randomUUID } from "node:crypto";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { fileURLToPath } from "node:url";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import type { RegisteredTool } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/streamableHttp.js";
import type { RequestHandlerExtra } from "@modelcontextprotocol/sdk/shared/protocol.js";
import type {
  CallToolResult,
  ContentBlock,
  ElicitRequestFormParams,
  ServerNotification,
  ServerRequest,
} from "@modelcontextprotocol/sdk/types.js";
import { isInitializeRequest } from "@modelcontextprotocol/sdk/types.js";
import { z } from "zod";
import type { AppConfig } from "../config.js";
import {
  bearerChallenge,
  bearerToken,
  hasScope,
} from "../auth/bearer.js";
import type { AccessTokenClaims } from "../auth/bearer.js";
import { verifyAccessToken } from "../auth/jwt.js";
import { McpSessionStore } from "../auth/session-store.js";
import type { HostrDaemonClient } from "../daemon/client.js";
import type { HostrDaemonNotification } from "../daemon/client.js";
import { auditLog } from "../logging.js";
import {
  uploadImageWithBestAvailableAuth,
  type UploadedImage,
} from "../http/uploads.js";
import { traceIdFromRequest } from "../trace.js";
import { storePaymentAsset, storeQrTextAsset } from "../payment/assets.js";
import {
  hostrActionCatalog,
  hostrActionDocumentation,
} from "../generated/hostr-actions.js";

const text = (value: unknown) => JSON.stringify(value, null, 2);

const listingActionIds = new Set([
  "hostr.listings.search",
  "hostr.listings.list",
  "hostr.listings.create",
  "hostr.listings.edit",
]);

const listingCardWidgetUri = "ui://widget/listing-card.html";
const paymentRequiredWidgetUri = "ui://widget/payment-required.html";
const sessionConnectWidgetUri = "ui://widget/session-connect.html";
const profileCardWidgetUri = "ui://widget/profile-card.html";
const tripWidgetUri = "ui://widget/trip.html";
const hostingWidgetUri = "ui://widget/hosting.html";

const widgetTemplateMeta = (
  resourceUri: string,
  extras: Record<string, unknown> = {},
): Record<string, unknown> => ({
  ui: { resourceUri },
  "openai/outputTemplate": resourceUri,
  "openai/widgetAccessible": true,
  ...extras,
});

const widgetResultMeta = (
  resourceUri: string,
  extras: Record<string, unknown> = {},
): Record<string, unknown> => ({
  ui: { resourceUri },
  "openai/widgetAccessible": true,
  ...extras,
});

const profileActionIds = new Set([
  "hostr.profile.show",
  "hostr.profile.lookup",
  "hostr.profile.edit",
]);

const listingCardOutputSchema = z
  .object({
    assistantInstructions: z.array(z.string()).optional(),
    displayMarkdown: z.string(),
    display: z
      .object({
        type: z.enum(["listing-card", "listing-card-list"]),
        cards: z.array(z.record(z.string(), z.unknown())),
      })
      .optional(),
    listingCards: z.array(z.record(z.string(), z.unknown())).optional(),
  })
  .passthrough();

const reservationCardOutputSchema = z
  .object({
    assistantInstructions: z.array(z.string()).optional(),
    displayMarkdown: z.string(),
    display: z
      .object({
        type: z.enum([
          "reservation-card",
          "reservation-card-list",
          "trip-card",
          "trip-card-list",
          "hosting-card",
          "hosting-card-list",
          "payment-external-required",
        ]),
        cards: z.array(z.record(z.string(), z.unknown())),
      })
      .optional(),
    reservationCards: z.array(z.record(z.string(), z.unknown())).optional(),
    paymentDisplays: z.array(z.record(z.string(), z.unknown())).optional(),
  })
  .passthrough();

const paymentRequiredOutputSchema = z
  .object({
    assistantInstructions: z.array(z.string()).optional(),
    displayMarkdown: z.string(),
    status: z.literal("payment_required"),
    stateName: z.literal("payment_required"),
    paymentRequired: z.literal(true),
    display: z.object({
      type: z.literal("payment-external-required"),
      cards: z.array(z.record(z.string(), z.unknown())),
    }),
    paymentDisplays: z.array(z.record(z.string(), z.unknown())),
  })
  .passthrough();

const sessionConnectOutputSchema = z
  .object({
    assistantInstructions: z.array(z.string()).optional(),
    displayMarkdown: z.string(),
    display: z
      .object({
        type: z.literal("nostr-connect"),
      })
      .passthrough()
      .optional(),
  })
  .passthrough();

const sessionAccountsInputSchema = z.object({}).strict();

const sessionSwitchInputSchema = z
  .object({
    pubkey: z
      .string()
      .describe("Connected account pubkey to make active."),
  })
  .strict();

const sessionLogoutInputSchema = z
  .object({
    pubkey: z
      .string()
      .describe(
        "Connected account pubkey to log out. Defaults to the active account when omitted.",
      )
      .optional(),
    all: z
      .boolean()
      .describe("Log out every connected account in this MCP session.")
      .optional(),
  })
  .strict();

const profileCardOutputSchema = z
  .object({
    assistantInstructions: z.array(z.string()).optional(),
    displayMarkdown: z.string(),
    display: z
      .object({
        type: z.enum(["profile-card", "profile-preview", "profile-result"]),
        cards: z.array(z.record(z.string(), z.unknown())),
      })
      .optional(),
    profileCards: z.array(z.record(z.string(), z.unknown())).optional(),
  })
  .passthrough();

const threadCardOutputSchema = z
  .object({
    assistantInstructions: z.array(z.string()).optional(),
    displayMarkdown: z.string(),
    display: z
      .object({
        type: z.enum(["thread-card-list", "thread-view"]),
        cards: z.array(z.record(z.string(), z.unknown())),
      })
      .optional(),
    threadCards: z.array(z.record(z.string(), z.unknown())).optional(),
    threadViews: z.array(z.record(z.string(), z.unknown())).optional(),
  })
  .passthrough();

const escrowTradeOutputSchema = z
  .object({
    assistantInstructions: z.array(z.string()).optional(),
    displayMarkdown: z.string(),
    display: z
      .object({
        type: z.enum([
          "escrow-trade-list",
          "escrow-trade-view",
          "escrow-arbitration-preview",
          "escrow-arbitration-result",
        ]),
        cards: z.array(z.record(z.string(), z.unknown())),
      })
      .optional(),
    escrowTradeCards: z.array(z.record(z.string(), z.unknown())).optional(),
  })
  .passthrough();

const escrowServiceOutputSchema = z
  .object({
    assistantInstructions: z.array(z.string()).optional(),
    displayMarkdown: z.string(),
    display: z
      .object({
        type: z.enum(["escrow-service-preview", "escrow-service-result"]),
        cards: z.array(z.record(z.string(), z.unknown())),
      })
      .optional(),
    escrowServiceCards: z.array(z.record(z.string(), z.unknown())).optional(),
  })
  .passthrough();

const escrowBadgeOutputSchema = z
  .object({
    assistantInstructions: z.array(z.string()).optional(),
    displayMarkdown: z.string(),
    display: z
      .object({
        type: z.enum([
          "escrow-badge-list",
          "escrow-badge-preview",
          "escrow-badge-result",
        ]),
        cards: z.array(z.record(z.string(), z.unknown())),
      })
      .optional(),
    badgeCards: z.array(z.record(z.string(), z.unknown())).optional(),
  })
  .passthrough();

const reservationActionIds = new Set([
  "hostr.reservations.bookAndPay",
  "hostr.swaps.watch",
  "hostr.trips.list",
  "hostr.bookings.list",
]);

const threadActionIds = new Set([
  "hostr.updates",
  "hostr.thread.view",
  "hostr.thread.message",
  "hostr.escrow.involve",
]);

const nonDestructiveWriteActionIds = new Set([
  "hostr.reservations.bookAndPay",
]);

const chatgptFriendlyReadOnlyActionIds = new Set([
  "hostr.reservations.bookAndPay",
]);

const toolAnnotations = (action: {
  id: string;
  readOnly: boolean;
}): {
  readOnlyHint: boolean;
  destructiveHint: boolean;
  openWorldHint: boolean;
} => {
  const readOnlyHint =
    action.readOnly || chatgptFriendlyReadOnlyActionIds.has(action.id);
  return {
    readOnlyHint,
    destructiveHint:
      !readOnlyHint && !nonDestructiveWriteActionIds.has(action.id),
    openWorldHint: !readOnlyHint,
  };
};

const reservationToolMeta = (actionId: string): Record<string, unknown> => {
  if (actionId === "hostr.reservations.bookAndPay") {
    return {
      ...widgetTemplateMeta(paymentRequiredWidgetUri),
      "hostr.preferredRenderer": "payment-external-required",
      "hostr.contentType": "payment-external-required",
    };
  }
  if (actionId === "hostr.trips.list") {
    return {
      ...widgetTemplateMeta(tripWidgetUri),
      "hostr.preferredRenderer": "trip-card",
      "hostr.contentType": "trip-card",
    };
  }
  if (actionId === "hostr.bookings.list") {
    return {
      ...widgetTemplateMeta(hostingWidgetUri),
      "hostr.preferredRenderer": "hosting-card",
      "hostr.contentType": "hosting-card",
    };
  }
  return {
    "hostr.preferredRenderer": "trip-card",
    "hostr.contentType": "trip-card",
  };
};

const descriptionBoilerplatePrefixes = [
  "MCP driving notes:",
  "Read-only behavior:",
  "Write behavior:",
  "Preview rule:",
  "Escrow role notes:",
];

const conciseActionDescription = (
  action: (typeof hostrActionCatalog)[number],
): string =>
  action.description
    .split(/\n\n+/)
    .map((paragraph) => paragraph.trim())
    .filter(Boolean)
    .filter(
      (paragraph) =>
        !descriptionBoilerplatePrefixes.some((prefix) =>
          paragraph.startsWith(prefix),
        ),
    )
    .join("\n\n");

const presentationContract = (actionId: string): string | null => {
  if (actionId === "hostr.swaps.watch") {
    return "If payment is still awaiting or watch times out, ask whether the user paid. If they answer yes, call hostr_swaps_watch again with the returned retry arguments. If the swap failed, report the failure and stop polling.";
  }
  if (listingActionIds.has(actionId)) {
    return "Returns listing-card output; render structuredContent.displayMarkdown and preserve image Markdown.";
  }
  if (reservationActionIds.has(actionId)) {
    return actionId === "hostr.reservations.bookAndPay"
      ? "May return a payment QR widget. If payment is required, render the QR/invoice and make the next assistant action a hostr_swaps_watch tool call with structuredContent.requiredNextTool.arguments. Do not stop after displaying the invoice."
      : "May return trip-card or hosting-card output; render structuredContent.displayMarkdown instead of raw JSON.";
  }
  if (profileActionIds.has(actionId)) {
    return "Returns profile-card output; render structuredContent.displayMarkdown.";
  }
  if (threadActionIds.has(actionId)) {
    return "Returns thread-card/thread-view output; use resolved names and avoid raw ids unless debugging.";
  }
  if (escrowTradeActionIds.has(actionId)) {
    return "Escrow-only output; render structuredContent.displayMarkdown and avoid raw event JSON unless debugging.";
  }
  if (escrowServiceActionIds.has(actionId)) {
    return "Escrow-only service output; keep live changes behind explicit approval.";
  }
  if (escrowBadgeActionIds.has(actionId)) {
    return "Escrow-only badge output; publish/delete only after explicit approval.";
  }
  return null;
};

const toolDescription = (action: (typeof hostrActionCatalog)[number]): string =>
  [
    conciseActionDescription(action),
    presentationContract(action.id),
    `Input type: ${action.inputTypeName}.`,
  ]
    .filter(Boolean)
    .join("\n\n");

const escrowTradeActionIds = new Set([
  "hostr.escrow.trades.list",
  "hostr.escrow.trades.view",
  "hostr.escrow.trades.audit",
  "hostr.escrow.trades.arbitrate",
]);

const escrowServiceActionIds = new Set([
  "hostr.escrow.service.list",
  "hostr.escrow.service.get",
  "hostr.escrow.service.edit",
  "hostr.escrow.service.delete",
]);

const escrowBadgeActionIds = new Set([
  "hostr.escrow.badges.definitions.list",
  "hostr.escrow.badges.definitions.edit",
  "hostr.escrow.badges.definitions.delete",
  "hostr.escrow.badges.awards.list",
  "hostr.escrow.badges.award",
  "hostr.escrow.badges.revoke",
]);

const record = (value: unknown): Record<string, unknown> | null =>
  value && typeof value === "object" && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null;

const isRecord = (
  value: Record<string, unknown> | null,
): value is Record<string, unknown> => value !== null;

const stringValue = (value: unknown): string | null =>
  typeof value === "string" && value.trim() !== "" ? value.trim() : null;

const arrayValue = (value: unknown): unknown[] =>
  Array.isArray(value) ? value : [];

const boolValue = (value: unknown): boolean | null =>
  typeof value === "boolean" ? value : null;

const truncate = (value: string, max = 180): string =>
  value.length > max ? `${value.slice(0, max - 1)}...` : value;

const numberValue = (value: unknown): number | null => {
  const number = typeof value === "number" ? value : Number(value);
  return Number.isFinite(number) ? number : null;
};

const parseJsonRecord = (value: unknown): Record<string, unknown> | null => {
  const direct = record(value);
  if (direct) {
    return direct;
  }
  const raw = stringValue(value);
  if (!raw) {
    return null;
  }
  try {
    return record(JSON.parse(raw));
  } catch {
    return null;
  }
};

const imageUploadInputSchema = z
  .object({
    file: z
      .any()
      .describe(
        "Required uploaded image file. This is a file-typed MCP argument named file so MCP clients can perform file upload/rewrite handling. If your client represents an attached upload as a local file reference such as /mnt/data/example.jpg, put that reference here, not in images[].url; the client bridge must rewrite or stream the original bytes before the remote Hostr MCP server receives the call. Do not send base64 text.",
      )
      .meta({
        contentMediaType: "image/*",
        "x-hostr-argument-kind": "file",
      }),
    filename: z
      .string()
      .describe(
        "Optional original filename. Use only as metadata; do not put a local path here.",
      )
      .optional(),
    mime: z
      .string()
      .describe("Optional image MIME type, for example image/jpeg or image/png.")
      .optional(),
  })
  .strict();

const imageUploadOutputSchema = z
  .object({
    ok: z.boolean(),
    upload: z
      .object({
        url: z.string().optional(),
        sha256: z.string(),
        size: z.number(),
        mime: z.string().optional(),
        filename: z.string().optional(),
        type: z.string().optional(),
        uploaded: z.union([z.string(), z.number()]).optional(),
        serverUrl: z.string(),
      })
      .passthrough(),
    usage: z.object({
      image: z.object({
        url: z.string().optional(),
      }),
    }),
  })
  .passthrough();

const localPathPattern = /^(?:\/|[a-zA-Z]:[\\/]|file:\/\/|~\/|\.{1,2}\/)/;
const chatUploadPattern = /^chat_upload(?::\/\/|$)/i;

const expandLocalPath = (path: string): string =>
  path === "~" ? homedir() : path.startsWith("~/") ? `${homedir()}${path.slice(1)}` : path;

const readLocalFile = async (
  path: string,
  filename?: string,
  mime?: string,
): Promise<UploadedImage> => {
  const localPath = path.startsWith("file://")
    ? fileURLToPath(path)
    : expandLocalPath(path);
  const bytes = await readFile(localPath);
  if (bytes.length === 0) {
    throw new Error("empty_upload");
  }
  return {
    bytes,
    mime,
    filename: filename ?? localPath.split(/[\\/]/).pop() ?? undefined,
  };
};

const readRemoteFile = async (
  url: string,
  filename?: string,
  mime?: string,
): Promise<UploadedImage> => {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    throw new Error("file_argument_must_be_file_not_path");
  }
  if (parsed.protocol !== "http:" && parsed.protocol !== "https:") {
    throw new Error("file_argument_must_be_file_not_path");
  }
  const response = await fetch(parsed);
  if (!response.ok) {
    throw new Error(`file_fetch_failed_${response.status}`);
  }
  const arrayBuffer = await response.arrayBuffer();
  const bytes = Buffer.from(arrayBuffer);
  if (bytes.length === 0) {
    throw new Error("empty_upload");
  }
  return {
    bytes,
    mime: mime ?? response.headers.get("content-type") ?? undefined,
    filename: filename ?? parsed.pathname.split("/").pop() ?? undefined,
  };
};

const uploadedImageFromFileArgument = async (
  file: unknown,
  filename?: string,
  mime?: string,
): Promise<UploadedImage> => {
  if (file instanceof Uint8Array) {
    return { bytes: Buffer.from(file), filename, mime };
  }
  if (file instanceof ArrayBuffer) {
    return { bytes: Buffer.from(file), filename, mime };
  }
  if (Array.isArray(file) && file.every((value) => Number.isInteger(value))) {
    return { bytes: Buffer.from(file as number[]), filename, mime };
  }

  const direct = stringValue(file);
  if (direct) {
    if (localPathPattern.test(direct)) {
      return readLocalFile(direct, filename, mime);
    }
    if (chatUploadPattern.test(direct)) {
      throw new Error("file_download_url_missing");
    }
    return readRemoteFile(direct, filename, mime);
  }

  const object = record(file);
  if (!object) {
    throw new Error("unsupported_file_argument");
  }

  const path = stringValue(object.path) ?? stringValue(object.filePath);
  if (path) {
    return readLocalFile(
      path,
      filename ??
        stringValue(object.name) ??
        stringValue(object.filename) ??
        stringValue(object.file_name) ??
        undefined,
      mime ??
        stringValue(object.mime) ??
        stringValue(object.type) ??
        stringValue(object.mime_type) ??
        undefined,
    );
  }

  const url =
    stringValue(object.download_url) ??
    stringValue(object.url) ??
    stringValue(object.href) ??
    stringValue(object.uri) ??
    stringValue(object.downloadUrl);
  if (url) {
    if (localPathPattern.test(url)) {
      return readLocalFile(
        url,
        filename ??
          stringValue(object.name) ??
          stringValue(object.filename) ??
          stringValue(object.file_name) ??
          undefined,
        mime ??
          stringValue(object.mime) ??
          stringValue(object.type) ??
          stringValue(object.mime_type) ??
          undefined,
      );
    }
    if (chatUploadPattern.test(url)) {
      throw new Error("file_download_url_missing");
    }
    return readRemoteFile(
      url,
      filename ??
        stringValue(object.name) ??
        stringValue(object.filename) ??
        stringValue(object.file_name) ??
        undefined,
      mime ??
        stringValue(object.mime) ??
        stringValue(object.type) ??
        stringValue(object.mime_type) ??
        undefined,
    );
  }

  if (stringValue(object.file_id)) {
    throw new Error("file_download_url_missing");
  }

  const bytes = object.bytes;
  if (
    Array.isArray(bytes) &&
    bytes.every((value) => Number.isInteger(value))
  ) {
    return {
      bytes: Buffer.from(bytes as number[]),
      filename: filename ?? stringValue(object.name) ?? stringValue(object.filename) ?? undefined,
      mime: mime ?? stringValue(object.mime) ?? stringValue(object.type) ?? undefined,
    };
  }

  throw new Error("unsupported_file_argument");
};

const formatDateTime = (value: unknown): string | null => {
  if (typeof value === "number" && Number.isFinite(value)) {
    const milliseconds = value > 1_000_000_000_000 ? value : value * 1000;
    return new Intl.DateTimeFormat("en", {
      dateStyle: "medium",
      timeStyle: "short",
    }).format(new Date(milliseconds));
  }
  const raw = stringValue(value);
  if (!raw) {
    return null;
  }
  const date = new Date(raw);
  if (Number.isNaN(date.getTime())) {
    return raw;
  }
  return new Intl.DateTimeFormat("en", {
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
};

const timestampMs = (value: unknown): number | null => {
  if (typeof value === "number" && Number.isFinite(value)) {
    return value > 1_000_000_000_000 ? value : value * 1000;
  }
  const raw = stringValue(value);
  if (!raw) {
    return null;
  }
  const numeric = Number(raw);
  if (Number.isFinite(numeric)) {
    return numeric > 1_000_000_000_000 ? numeric : numeric * 1000;
  }
  const date = new Date(raw);
  return Number.isNaN(date.getTime()) ? null : date.getTime();
};

const formatAmount = (amount: Record<string, unknown> | null): string => {
  if (!amount) {
    return "price unavailable";
  }
  const denomination =
    stringValue(amount.denomination) ?? stringValue(amount.currency) ?? "";
  const value = stringValue(amount.value) ?? stringValue(amount.amount) ?? "";
  if (!value || !denomination) {
    return "price unavailable";
  }
  const currency = denomination.toUpperCase();
  if (currency === "BTC") {
    const sats = Number(stringValue(amount.smallestUnitValue) ?? "");
    if (Number.isFinite(sats) && sats > 0) {
      return `₿${Intl.NumberFormat("en", {
        notation: "compact",
        maximumFractionDigits: 2,
      }).format(sats)}`;
    }
  }
  if (currency === "USD") {
    const numeric = Number(value);
    if (Number.isFinite(numeric)) {
      return new Intl.NumberFormat("en-US", {
        style: "currency",
        currency: "USD",
        minimumFractionDigits: Number.isInteger(numeric) ? 0 : 2,
        maximumFractionDigits: 2,
      }).format(numeric);
    }
  }
  return `${value.replace(/(\.\d*?)0+$/, "$1").replace(/\.$/, "")} ${currency}`;
};

const formatPrices = (listing: Record<string, unknown>): string => {
  const prices = arrayValue(listing.prices);
  if (prices.length === 0) {
    return "price unavailable";
  }
  return prices
    .map((price) => {
      const priceRecord = record(price);
      const amount = formatAmount(record(priceRecord?.amount));
      const frequency = stringValue(priceRecord?.frequency);
      if (!frequency) {
        return amount;
      }
      const label =
        frequency === "daily" || frequency === "day" ? "night" : frequency;
      return `${amount} / ${label}`;
    })
    .join(", ");
};

type ReservationCardData = {
  type: "trip-card" | "hosting-card";
  tradeId?: string;
  reservationId?: string;
  title: string;
  guestName?: string;
  start?: string;
  end?: string;
  status?: string;
  statusLabel?: string;
  mode: "confirmed" | "cancelled";
};

const isCancelledStage = (stage: string | null): boolean =>
  stage !== null && stage.toLowerCase().includes("cancel");

const reservationCardData = (
  lookup: Record<string, unknown> | null,
  fallbackType: "trip-card" | "hosting-card" = "trip-card",
): ReservationCardData | null => {
  if (!lookup || lookup.found !== true) {
    return null;
  }
  const group = record(lookup.group);
  const listing = record(lookup.listing);
  const participants = record(lookup.participants);
  const profiles = record(participants?.profiles);
  const buyerProfile = record(profiles?.buyer);
  const guestName =
    stringValue(buyerProfile?.displayName) ??
    stringValue(buyerProfile?.name) ??
    stringValue(buyerProfile?.profileName) ??
    (stringValue(group?.buyerPubkey)
      ? truncate(stringValue(group?.buyerPubkey)!, 12)
      : undefined);
  const cardType =
    stringValue(lookup.mode) === "bookings" ? "hosting-card" : fallbackType;
  const title =
    stringValue(listing?.title) ??
    stringValue(group?.listingTitle) ??
    "Hostr reservation";
  const start = formatDateTime(group?.start);
  const end = formatDateTime(group?.end);
  const stage = stringValue(group?.stage);
  const cancelled =
    group?.cancelled === true ||
    stringValue(group?.status)?.toLowerCase() === "cancelled" ||
    isCancelledStage(stage);
  return {
    type: cardType,
    tradeId:
      stringValue(group?.tradeId) ??
      stringValue(lookup.tradeId) ??
      stringValue(group?.id) ??
      undefined,
    reservationId:
      stringValue(group?.reservationId) ??
      stringValue(group?.eventId) ??
      stringValue(group?.id) ??
      undefined,
    title,
    guestName,
    start: start ?? undefined,
    end: end ?? undefined,
    status: cancelled ? (stage ?? "cancelled") : undefined,
    statusLabel: cancelled ? (stage ?? "cancelled") : undefined,
    mode: cancelled ? "cancelled" : "confirmed",
  };
};

const reservationCard = (card: ReservationCardData): string => {
  if (card.type === "hosting-card") {
    return [
      card.mode === "cancelled" ? "### Hosting Cancelled" : "### Hosting",
      card.mode === "cancelled" ? "**Cancelled**" : null,
      `**Hosting ${card.guestName ?? "guest"} at:** ${card.title}`,
      card.start && card.end ? `**Dates:** ${card.start} to ${card.end}` : null,
    ]
      .filter(Boolean)
      .join("\n\n");
  }

  return [
    card.mode === "cancelled"
      ? "### Trip Cancelled"
      : "### Trip",
    card.mode === "cancelled" ? "**Cancelled**" : null,
    `**Stay:** ${card.title}`,
    card.start && card.end ? `**Dates:** ${card.start} to ${card.end}` : null,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const absoluteUrl = (config: AppConfig, path: string): string =>
  `${config.publicAssetBaseUrl.replace(/\/+$/, "")}${path}`;

const bech32Charset = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";
const bech32Generator = [
  0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3,
];

const bech32Polymod = (values: number[]): number => {
  let chk = 1;
  for (const value of values) {
    const top = chk >>> 25;
    chk = ((((chk & 0x1ffffff) << 5) ^ value) >>> 0);
    for (let index = 0; index < 5; index += 1) {
      if (((top >> index) & 1) === 1) {
        chk = (chk ^ bech32Generator[index]) >>> 0;
      }
    }
  }
  return chk;
};

const bech32HrpExpand = (hrp: string): number[] => [
  ...Array.from(hrp, (char) => char.charCodeAt(0) >> 5),
  0,
  ...Array.from(hrp, (char) => char.charCodeAt(0) & 31),
];

const bech32Checksum = (hrp: string, data: number[]): number[] => {
  const values = [...bech32HrpExpand(hrp), ...data, 0, 0, 0, 0, 0, 0];
  const polymod = bech32Polymod(values) ^ 1;
  return Array.from(
    { length: 6 },
    (_, index) => (polymod >>> (5 * (5 - index))) & 31,
  );
};

const bech32Encode = (hrp: string, data: number[]): string =>
  `${hrp}1${[...data, ...bech32Checksum(hrp, data)]
    .map((value) => bech32Charset[value])
    .join("")}`;

const convertBits = (
  bytes: number[],
  fromBits: number,
  toBits: number,
  pad: boolean,
): number[] => {
  let accumulator = 0;
  let bits = 0;
  const maxValue = (1 << toBits) - 1;
  const result: number[] = [];
  for (const byte of bytes) {
    if (byte < 0 || byte >> fromBits !== 0) {
      throw new Error("Invalid bech32 source byte");
    }
    accumulator = (accumulator << fromBits) | byte;
    bits += fromBits;
    while (bits >= toBits) {
      bits -= toBits;
      result.push((accumulator >> bits) & maxValue);
    }
  }
  if (pad) {
    if (bits > 0) {
      result.push((accumulator << (toBits - bits)) & maxValue);
    }
  } else if (bits >= fromBits || ((accumulator << (toBits - bits)) & maxValue)) {
    throw new Error("Invalid bech32 padding");
  }
  return result;
};

const hexBytes = (hexValue: string): number[] | null => {
  if (!/^[0-9a-f]{64}$/i.test(hexValue)) {
    return null;
  }
  return Array.from(
    { length: 32 },
    (_, index) => Number.parseInt(hexValue.slice(index * 2, index * 2 + 2), 16),
  );
};

const anchorToNaddr = (anchor: string): string | null => {
  if (/^naddr1/i.test(anchor)) {
    return anchor;
  }
  const parts = anchor.split(":");
  if (parts.length < 3) {
    return null;
  }
  const kind = Number.parseInt(parts[0], 10);
  const pubkeyBytes = hexBytes(parts[1]);
  const identifierBytes = Array.from(
    new TextEncoder().encode(parts.slice(2).join(":")),
  );
  if (!Number.isInteger(kind) || kind < 0 || !pubkeyBytes) {
    return null;
  }
  if (identifierBytes.length > 255) {
    return null;
  }
  const tlvBytes = [
    0,
    identifierBytes.length,
    ...identifierBytes,
    2,
    32,
    ...pubkeyBytes,
    3,
    4,
    (kind >> 24) & 0xff,
    (kind >> 16) & 0xff,
    (kind >> 8) & 0xff,
    kind & 0xff,
  ];
  return bech32Encode("naddr", convertBits(tlvBytes, 8, 5, true));
};

const qrImageUrl = (config: AppConfig, data: string): string | null => {
  const template = config.qrImageUrlTemplate;
  if (!template) {
    return null;
  }
  if (template.includes("{data}")) {
    return template.replaceAll("{data}", encodeURIComponent(data));
  }
  const url = new URL(template);
  url.searchParams.set("data", data);
  return url.toString();
};

type PaymentExternalRequiredDisplayData = {
  type: "payment-external-required";
  title: "Pay this invoice to continue";
  prompt: "Pay this invoice to continue:";
  invoice: string;
  qrImageUrl?: string;
  invoiceTextUrl?: string;
  lightningUrl: string;
  copy: {
    label: "Copy invoice";
    text: string;
  };
  actions: Array<{
    type: "copy";
    label: "Copy";
    source: "structuredContent.paymentDisplays[0].copy.text";
    text: string;
  }>;
};

const paymentPromptMarkdown = (
  config: AppConfig,
  externalPayment: { invoice?: unknown; qrImage?: unknown } | null,
): string | null => {
  const display = paymentExternalRequiredDisplay(config, externalPayment);
  return display ? paymentDisplayMarkdown(display) : null;
};

const paymentExternalRequiredDisplay = (
  config: AppConfig,
  externalPayment: { invoice?: unknown; qrImage?: unknown } | null,
): PaymentExternalRequiredDisplayData | null => {
  if (!externalPayment) {
    return null;
  }
  const invoice = stringValue(externalPayment.invoice);
  const qrImage = stringValue(externalPayment.qrImage);
  if (!invoice) {
    return null;
  }
  const remoteQrUrl = qrImageUrl(config, invoice);
  const asset = storePaymentAsset(remoteQrUrl ? null : qrImage, invoice);
  const qrUrl =
    remoteQrUrl ??
    (asset?.qrUrlPath ? absoluteUrl(config, asset.qrUrlPath) : null);
  const invoiceUrl = asset?.invoiceUrlPath
    ? absoluteUrl(config, asset.invoiceUrlPath)
    : null;
  return {
    type: "payment-external-required",
    title: "Pay this invoice to continue",
    prompt: "Pay this invoice to continue:",
    invoice,
    qrImageUrl: qrUrl ?? undefined,
    invoiceTextUrl: invoiceUrl ?? undefined,
    lightningUrl: `lightning:${invoice}`,
    copy: {
      label: "Copy invoice",
      text: invoice,
    },
    actions: [
      {
        type: "copy",
        label: "Copy",
        source: "structuredContent.paymentDisplays[0].copy.text",
        text: invoice,
      },
    ],
  };
};

const paymentDisplayMarkdown = (
  display: PaymentExternalRequiredDisplayData,
): string => {
  return [
    "### Pay this invoice to continue",
    display.qrImageUrl
      ? `![Lightning invoice QR](${display.qrImageUrl})`
      : null,
    `[Open in Lightning wallet](${display.lightningUrl})`,
    display.invoiceTextUrl
      ? `[Copy exact invoice text](${display.invoiceTextUrl})`
      : null,
    "Use the QR, wallet link, or exact invoice text link above.",
  ]
    .filter(Boolean)
    .join("\n\n");
};

type SessionConnectDisplayData = {
  type: "nostr-connect";
  title: string;
  message: string;
  nostrconnect?: string;
  qrImageUrl?: string;
  uriTextUrl?: string;
  nextTool: "hostr_session_connect";
  nextInput: Record<string, unknown>;
};

const sessionConnectDisplayData = (
  config: AppConfig,
  result: Record<string, unknown>,
  safeResultData: Record<string, unknown>,
): SessionConnectDisplayData | undefined => {
  const data = record(result.data);
  if (!data || data.authenticated === true || data.pending !== true) {
    return undefined;
  }
  const nostrconnect = stringValue(data.nostrconnect);
  const remoteQrUrl = nostrconnect ? qrImageUrl(config, nostrconnect) : null;
  const asset = nostrconnect
    ? storeQrTextAsset(remoteQrUrl ? null : stringValue(data.qrImage), nostrconnect)
    : null;
  const qrUrl =
    remoteQrUrl ??
    (asset?.qrUrlPath ? absoluteUrl(config, asset.qrUrlPath) : null);
  const textUrl = asset?.textUrlPath
    ? absoluteUrl(config, asset.textUrlPath)
    : null;
  return {
    type: "nostr-connect",
    title: stringValue(safeResultData.displayTitle) ?? "Log in to Hostr",
    message:
      stringValue(safeResultData.displayMessage) ??
      "Scan this with your Nostr app to log in to your Hostr account.",
    nostrconnect: nostrconnect ?? undefined,
    qrImageUrl: qrUrl ?? undefined,
    uriTextUrl: textUrl ?? undefined,
    nextTool: "hostr_session_connect",
    nextInput: record(safeResultData.nextInput) ?? {
      wait: true,
      regenerate: false,
    },
  };
};

const listingUrl = (
  config: AppConfig,
  listing: Record<string, unknown>,
): string | null => {
  const anchor = stringValue(listing.naddr) ?? stringValue(listing.anchor);
  const naddr = anchor ? anchorToNaddr(anchor) : null;
  if (naddr) {
    return listingRouteUrl(config.publicAppBaseUrl, naddr);
  }

  const explicit = stringValue(listing.url);
  if (explicit) {
    return explicit;
  }
  return null;
};

const listingRouteUrl = (publicAppBaseUrl: string, naddr: string): string =>
  `${publicAppBaseUrl.replace(/\/+$/, "")}/#/listing/${encodeURIComponent(naddr)}`;

type ListingImage = {
  url: string;
  alt?: string;
};

type ListingCardData = {
  type: "listing-card";
  id?: string;
  anchor?: string;
  dTag?: string;
  url?: string;
  title: string;
  description?: string;
  images: ListingImage[];
  primaryImageUrl?: string;
  imageCount: number;
  price: string;
  listingType: string;
  typeLabel: string;
  status: "active" | "inactive" | "not-published";
  statusLabel: string;
  flags: string[];
  index?: number;
  mode: "result" | "preview" | "published";
};

type ProfileCardData = {
  type: "profile-card";
  exists: boolean;
  pubkey?: string;
  name: string;
  about?: string;
  picture?: string;
  nip05?: string;
  lud16?: string;
  website?: string;
  mode: "current" | "preview" | "published";
  statusLabel: string;
};

type HostrCriticalNotice =
  | {
      type: "signer-approval";
      message: string;
      requestId?: string;
      signerMethod?: string;
      eventLabel?: string;
    }
  | {
      type: "external-payment";
      message: string;
      invoice: string;
      qrImage?: string;
      tradeId?: string;
      swapId?: string;
    };

const sanitizeForStructuredContent = (value: unknown): unknown => {
  if (Array.isArray(value)) {
    return value.map(sanitizeForStructuredContent);
  }
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value as Record<string, unknown>)
        .filter(([key]) => key !== "qrImage")
        .map(([key, entry]) => [key, sanitizeForStructuredContent(entry)]),
    );
  }
  if (typeof value === "string" && /^data:image\//i.test(value)) {
    return "[stored image]";
  }
  return value;
};

const sanitizeNotice = (notice: HostrCriticalNotice): HostrCriticalNotice => {
  if (notice.type !== "external-payment") {
    return notice;
  }
  const { qrImage: _qrImage, ...safeNotice } = notice;
  return safeNotice;
};

const isListingImage = (value: ListingImage | null): value is ListingImage =>
  value !== null;

const publicBlossomFileUrl = (
  config: AppConfig,
  value: string,
): string | null => {
  if (/^https?:\/\//i.test(value)) {
    return value;
  }
  if (/^blossom:\/\/dry-run\//i.test(value)) {
    return null;
  }
  if (/^[a-z][a-z0-9+.-]*:/i.test(value)) {
    return value;
  }

  const trimmed = value.replace(/^\/+/, "");
  if (trimmed === "" || /[\s?#]/.test(trimmed)) {
    return null;
  }

  const blossomOrigin = originForUrl(config.blossomUploadUrl);
  if (!blossomOrigin) {
    return null;
  }
  return `${blossomOrigin}/${trimmed
    .split("/")
    .map((part) => encodeURIComponent(part))
    .join("/")}`;
};

const listingImage = (
  config: AppConfig,
  value: unknown,
): ListingImage | null => {
  const directUrl = stringValue(value);
  if (directUrl) {
    const url = publicBlossomFileUrl(config, directUrl);
    return url ? { url } : null;
  }

  const image = record(value);
  const url =
    stringValue(image?.url) ??
    stringValue(image?.src) ??
    stringValue(image?.image) ??
    stringValue(image?.imageUrl);
  if (!url) {
    return null;
  }
  const publicUrl = publicBlossomFileUrl(config, url);
  if (!publicUrl) {
    return null;
  }

  return {
    url: publicUrl,
    alt:
      stringValue(image?.alt) ?? stringValue(image?.description) ?? undefined,
  };
};

const normalizedListingImageValue = (
  config: AppConfig,
  value: unknown,
): unknown => {
  const directUrl = stringValue(value);
  if (directUrl) {
    return publicBlossomFileUrl(config, directUrl) ?? value;
  }

  const image = record(value);
  if (!image) {
    return value;
  }

  const next = { ...image };
  for (const key of ["url", "src", "image", "imageUrl"]) {
    const raw = stringValue(next[key]);
    if (!raw) {
      continue;
    }
    next[key] = publicBlossomFileUrl(config, raw) ?? next[key];
  }
  return next;
};

const normalizeListingImages = (
  config: AppConfig,
  listing: Record<string, unknown>,
): Record<string, unknown> => {
  if (!Array.isArray(listing.images)) {
    return listing;
  }
  return {
    ...listing,
    images: listing.images.map((image) =>
      normalizedListingImageValue(config, image),
    ),
  };
};

const normalizeListingResultImages = (
  config: AppConfig,
  actionId: string,
  result: Record<string, unknown>,
): Record<string, unknown> => {
  if (!listingActionIds.has(actionId)) {
    return result;
  }
  const data = record(result.data);
  if (!data) {
    return result;
  }

  if (
    actionId === "hostr.listings.search" ||
    actionId === "hostr.listings.list"
  ) {
    return {
      ...result,
      data: {
        ...data,
        listings: arrayValue(data.listings)
          .map((listing) => {
            const listingRecord = record(listing);
            return listingRecord
              ? normalizeListingImages(config, listingRecord)
              : listing;
          }),
      },
    };
  }

  const listing = record(data.listing);
  if (!listing) {
    return result;
  }
  return {
    ...result,
    data: {
      ...data,
      listing: normalizeListingImages(config, listing),
    },
  };
};

const imageCarousel = (title: string, images: ListingImage[]): string => {
  if (images.length === 0) {
    return "";
  }

  return images
    .map((image, index) => {
      const alt =
        image.alt ?? `${title} photo ${index + 1} of ${images.length}`;
      return `![${alt}](${image.url})`;
    })
    .join(" ");
};

const listingFlags = (listing: Record<string, unknown>): string[] => {
  const flags: string[] = [];
  if (boolValue(listing.instantBook) === true) {
    flags.push("instant book");
  }
  const negotiable = boolValue(listing.negotiable);
  if (negotiable === true) {
    flags.push("negotiable");
  } else if (negotiable === false) {
    flags.push("not negotiable");
  }
  return flags;
};

const plural = (
  count: number,
  singular: string,
  pluralLabel = `${singular}s`,
) => `${count} ${count === 1 ? singular : pluralLabel}`;

const listingTypeLabel = (listing: Record<string, unknown>): string => {
  const specs = record(listing.specifications) ?? record(listing.specs);
  const parts = [stringValue(listing.type) ?? "listing"];
  const quantity = Number(listing.quantity);
  if (Number.isFinite(quantity) && quantity > 0) {
    parts.push(`${quantity} available`);
  }
  const guests = Number(specs?.max_guests ?? specs?.guests);
  if (Number.isFinite(guests) && guests > 0) {
    parts.push(plural(guests, "guest"));
  }
  const beds = Number(specs?.beds);
  if (Number.isFinite(beds) && beds > 0) {
    parts.push(plural(beds, "bed"));
  }
  const bedrooms = Number(specs?.bedrooms);
  if (Number.isFinite(bedrooms) && bedrooms > 0) {
    parts.push(plural(bedrooms, "bedroom"));
  }
  const bathrooms = Number(specs?.bathrooms);
  if (Number.isFinite(bathrooms) && bathrooms > 0) {
    parts.push(plural(bathrooms, "bath"));
  }
  return parts.join(", ");
};

const listingCardData = (
  config: AppConfig,
  listing: Record<string, unknown>,
  index: number | null,
  mode: "result" | "preview" | "published" = "result",
): ListingCardData => {
  const title = stringValue(listing.title) ?? "Untitled listing";
  const description = stringValue(listing.description);
  const images = arrayValue(listing.images)
    .map((image) => listingImage(config, image))
    .filter(isListingImage);
  const status: ListingCardData["status"] =
    mode === "preview"
      ? "not-published"
      : boolValue(listing.active) === false
        ? "inactive"
        : "active";
  const url = listingUrl(config, listing);
  return {
    type: "listing-card",
    id: stringValue(listing.id) ?? undefined,
    anchor:
      stringValue(listing.anchor) ?? stringValue(listing.naddr) ?? undefined,
    dTag: stringValue(listing.dTag) ?? undefined,
    url: url ?? undefined,
    title,
    description: description ? truncate(description) : undefined,
    images,
    primaryImageUrl: images[0]?.url,
    imageCount: images.length,
    price: formatPrices(listing),
    listingType: stringValue(listing.type) ?? "listing",
    typeLabel: listingTypeLabel(listing),
    status,
    statusLabel: status === "not-published" ? "not published yet" : status,
    flags: listingFlags(listing),
    index: index ?? undefined,
    mode,
  };
};

const listingCardMarkdown = (card: ListingCardData): string => {
  const heading =
    card.mode === "preview"
      ? `### Preview: ${card.title}`
      : card.index === undefined
        ? `### ${card.title}`
        : `### ${card.index}. ${card.title}`;

  return [
    heading,
    imageCarousel(card.title, card.images),
    card.description ?? null,
    `**Price:** ${card.price}`,
    `**Type:** ${card.typeLabel}`,
    card.status === "active" ? null : `**Status:** ${card.statusLabel}`,
    card.flags.length > 0 ? `**Flags:** ${card.flags.join(", ")}` : null,
    card.url ? `**Open:** [Open listing](${card.url})` : null,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const listingCardsMarkdown = (cards: ListingCardData[]): string =>
  cards.map(listingCardMarkdown).join("\n\n---\n\n");

const listingCard = (
  config: AppConfig,
  listing: Record<string, unknown>,
  index: number | null,
  mode: "result" | "preview" | "published" = "result",
): string => listingCardMarkdown(listingCardData(config, listing, index, mode));

const listingCardResponseText = (
  displayMarkdown: string,
  listingCards: ListingCardData[],
): string => {
  const count = listingCards.length;
  return [
    `Hostr listing-card response: the assistant's final answer must include the Markdown listing card${count === 1 ? "" : "s"} below, including every ![image](url). Do not replace this with a text-only summary.`,
    displayMarkdown,
  ].join("\n\n");
};

const listingCardsFromResult = (
  config: AppConfig,
  actionId: string,
  result: Record<string, unknown>,
): ListingCardData[] => {
  if (result.ok === false) {
    return [];
  }
  const data = record(result.data);
  if (!data) {
    return [];
  }

  if (
    actionId === "hostr.listings.search" ||
    actionId === "hostr.listings.list"
  ) {
    return arrayValue(data.listings)
      .map(record)
      .filter(isRecord)
      .map((listing, index) => listingCardData(config, listing, index + 1));
  }

  if (
    actionId === "hostr.listings.create" ||
    actionId === "hostr.listings.edit"
  ) {
    const listing = record(data.listing);
    if (!listing) {
      return [];
    }
    return [
      listingCardData(
        config,
        listing,
        null,
        result.dryRun === true ? "preview" : "published",
      ),
    ];
  }

  return [];
};

const profileCardData = (
  actionId: string,
  result: Record<string, unknown>,
): ProfileCardData | null => {
  if (!profileActionIds.has(actionId) || result.ok === false) {
    return null;
  }
  const data = record(result.data);
  if (!data) {
    return null;
  }
  const metadata = record(data.metadata);
  const exists = data.exists === true || Boolean(metadata);
  const mode =
    result.dryRun === true
      ? "preview"
      : actionId === "hostr.profile.edit"
        ? "published"
        : "current";
  const name =
    stringValue(metadata?.display_name) ??
    stringValue(metadata?.displayName) ??
    stringValue(metadata?.name) ??
    (exists ? "Hostr profile" : "No Hostr profile");
  return {
    type: "profile-card",
    exists,
    pubkey: stringValue(data.pubkey) ?? undefined,
    name,
    about: stringValue(metadata?.about) ?? undefined,
    picture:
      stringValue(metadata?.picture) ??
      stringValue(metadata?.image) ??
      undefined,
    nip05: stringValue(metadata?.nip05) ?? undefined,
    lud16: stringValue(metadata?.lud16) ?? undefined,
    website: stringValue(metadata?.website) ?? undefined,
    mode,
    statusLabel:
      mode === "preview"
        ? "preview"
        : mode === "published"
          ? "published"
          : exists
            ? "current"
            : "not found",
  };
};

const profileCardsFromResult = (
  actionId: string,
  result: Record<string, unknown>,
): ProfileCardData[] => {
  const card = profileCardData(actionId, result);
  return card ? [card] : [];
};

const profileCardMarkdown = (card: ProfileCardData): string => {
  if (!card.exists) {
    return [
      "**Hostr Profile**",
      "No Hostr profile metadata was found.",
    ]
      .filter(Boolean)
      .join("\n\n");
  }
  return [
    `**${card.name}**`,
    card.picture ? `![Profile picture](${card.picture})` : null,
    card.about,
    card.lud16 ? `**Lightning address:** ${card.lud16}` : null,
    card.nip05 ? `**NIP-05:** ${card.nip05}` : null,
    card.website ? `**Website:** ${card.website}` : null,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const profileCardsMarkdown = (cards: ProfileCardData[]): string =>
  cards.map(profileCardMarkdown).join("\n\n---\n\n");

const profileCardResponseText = (displayMarkdown: string): string =>
  [
    "Hostr profile-card response: render structuredContent.displayMarkdown as Markdown, or use structuredContent.profileCards for a compact profile card. Do not expose pubkeys, EVM addresses, or internal ids unless the user specifically asks for debugging details.",
    displayMarkdown,
  ].join("\n\n");

const reservationCardResponseText = (
  displayMarkdown: string,
  reservationCards: ReservationCardData[],
): string => {
  const count = reservationCards.length;
  const hasHosting = reservationCards.some((card) => card.type === "hosting-card");
  const label = hasHosting ? "hosting" : "trip";
  return [
    `Hostr ${label}-card response: the assistant's final answer must include the Markdown ${label} card${count === 1 ? "" : "s"} below exactly as rendered. Do not replace this with raw JSON or expose swap state internals.`,
    displayMarkdown,
  ].join("\n\n");
};

const reservationCardsMarkdown = (cards: ReservationCardData[]): string =>
  cards.map(reservationCard).join("\n\n---\n\n");

const reservationCardsFromResult = (
  actionId: string,
  result: Record<string, unknown>,
): ReservationCardData[] => {
  if (result.ok === false) {
    return [];
  }
  const data = record(result.data);
  if (!data) {
    return [];
  }

  if (actionId === "hostr.swaps.watch") {
    return [
      reservationCardData(record(data.reservationLookup), "trip-card"),
      reservationCardData(
        record(record(data.state)?.reservationLookup),
        "trip-card",
      ),
    ].filter((card): card is ReservationCardData => card !== null);
  }

  if (
    actionId === "hostr.trips.list" ||
    actionId === "hostr.bookings.list" ||
    actionId === "hostr.reservations.bookAndPay"
  ) {
    const fallbackType =
      actionId === "hostr.bookings.list" ? "hosting-card" : "trip-card";
    const collectionCards = Array.isArray(data.results)
      ? data.results
          .map(record)
          .flatMap((item) => [
            reservationCardData(item, fallbackType),
            reservationCardData(record(item?.reservationLookup), fallbackType),
            reservationCardData(
              record(record(item?.state)?.reservationLookup),
              fallbackType,
            ),
          ])
          .filter((card): card is ReservationCardData => card !== null)
      : [];
    return [
      ...collectionCards,
      reservationCardData(data, fallbackType),
      reservationCardData(record(data.reservationLookup), fallbackType),
      reservationCardData(
        record(record(data.state)?.reservationLookup),
        fallbackType,
      ),
    ].filter((card): card is ReservationCardData => card !== null);
  }

  return [];
};

type ThreadCardData = {
  type: "thread-card";
  title: string;
  header: string;
  subtitle?: string;
  counterparties: string[];
  conversation?: string;
  tradeId?: string;
  start?: string;
  end?: string;
  amount?: string;
  stage?: string;
  unread: boolean;
  unreadCount?: number;
  preview?: string;
  updatedAt?: string;
  updatedAtMs?: number;
};

type ThreadMessageData = {
  sender: string;
  content: string;
  time?: string;
  sentByUser?: boolean;
};

type ThreadViewData = {
  type: "thread-view";
  title: string;
  counterparties: string[];
  tradeId?: string;
  unreadCount?: number;
  messageCount: number;
  hasMoreMessages: boolean;
  messages: ThreadMessageData[];
  requiresMessage?: boolean;
};

const profileDisplayName = (profile: Record<string, unknown>): string | null =>
  stringValue(profile.displayName) ??
  stringValue(profile.name) ??
  stringValue(profile.profileName);

const tagValue = (
  tags: unknown[],
  name: string,
  index = 1,
): string | null => {
  for (const tag of tags) {
    const parts = arrayValue(tag);
    if (parts[0] === name) {
      return stringValue(parts[index]);
    }
  }
  return null;
};

const listingTitleFromEvent = (
  event: Record<string, unknown>,
): string | null => {
  const content = parseJsonRecord(event.content);
  const proof = record(content?.proof);
  const listing = record(proof?.listing);
  const tags = arrayValue(listing?.tags);
  return tagValue(tags, "title") ?? stringValue(listing?.title);
};

const threadReservationDetails = (
  thread: Record<string, unknown>,
): {
  title?: string;
  start?: string;
  end?: string;
  amount?: string;
  stage?: string;
  updatedAt?: string;
  updatedAtMs?: number;
  subtitle?: string;
} => {
  const requests = arrayValue(thread.reservationRequests)
    .map(record)
    .filter(isRecord);
  const latest = [...requests]
    .sort(
      (a, b) =>
        (timestampMs(a.created_at) ?? 0) - (timestampMs(b.created_at) ?? 0),
    )
    .at(-1);
  if (!latest) {
    return {};
  }
  const content = parseJsonRecord(latest.content);
  const amount = formatAmount(record(content?.amount));
  const start = formatDateTime(content?.start) ?? undefined;
  const end = formatDateTime(content?.end) ?? undefined;
  const stage = stringValue(content?.stage) ?? undefined;
  const reservationLabel = stage?.toLowerCase().includes("cancel")
    ? "Reservation cancelled"
    : "Reservation offer";
  const subtitleParts = [
    amount === "price unavailable" ? null : amount,
    start && end ? `${start} to ${end}` : null,
  ].filter(Boolean);
  return {
    title: listingTitleFromEvent(latest) ?? undefined,
    start,
    end,
    amount: amount === "price unavailable" ? undefined : amount,
    stage,
    updatedAt: formatDateTime(latest.created_at) ?? undefined,
    updatedAtMs: timestampMs(latest.created_at) ?? undefined,
    subtitle: `${reservationLabel}${
      subtitleParts.length > 0 ? `: ${subtitleParts.join(" · ")}` : ""
    }`,
  };
};

const threadLatestTextDetails = (
  thread: Record<string, unknown>,
): { preview?: string; updatedAt?: string; updatedAtMs?: number } => {
  const textMessages = arrayValue(thread.textMessages)
    .map(record)
    .filter(isRecord);
  const latest = [...textMessages]
    .sort(
      (a, b) =>
        (timestampMs(a.created_at) ?? 0) - (timestampMs(b.created_at) ?? 0),
    )
    .at(-1);
  const content = stringValue(latest?.content);
  return {
    preview: content ? truncate(content, 140) : undefined,
    updatedAt: formatDateTime(latest?.created_at) ?? undefined,
    updatedAtMs: timestampMs(latest?.created_at) ?? undefined,
  };
};

const threadCardData = (
  thread: Record<string, unknown>,
): ThreadCardData | null => {
  const counterparties = arrayValue(thread.counterparties)
    .map(record)
    .filter(isRecord)
    .map(profileDisplayName)
    .filter((name): name is string => name !== null);
  const reservation = threadReservationDetails(thread);
  const textDetails = threadLatestTextDetails(thread);
  const latestIsReservation =
    (reservation.updatedAtMs ?? 0) >= (textDetails.updatedAtMs ?? 0);
  const subtitle = latestIsReservation
    ? reservation.subtitle
    : textDetails.preview;
  const updatedAt = latestIsReservation
    ? reservation.updatedAt
    : textDetails.updatedAt;
  const updatedAtMs = latestIsReservation
    ? reservation.updatedAtMs
    : textDetails.updatedAtMs;
  const conversation = stringValue(thread.conversation);
  const title =
    counterparties.length > 0 ? counterparties.join(", ") : "Hostr thread";
  const unreadCount = Number(thread.unreadCount);
  const unread =
    Number.isFinite(unreadCount) ? unreadCount > 0 : Boolean(thread.unread);
  const normalizedUnreadCount = Number.isFinite(unreadCount)
    ? unreadCount
    : undefined;
  const header =
    normalizedUnreadCount && normalizedUnreadCount > 0
      ? `${title} (${normalizedUnreadCount} Unread)`
      : title;
  return {
    type: "thread-card",
    title,
    header,
    subtitle,
    counterparties,
    conversation: conversation ?? undefined,
    tradeId: conversation ?? undefined,
    start: reservation.start,
    end: reservation.end,
    amount: reservation.amount,
    stage: reservation.stage,
    unread,
    unreadCount: normalizedUnreadCount,
    preview: textDetails.preview,
    updatedAt,
    updatedAtMs,
  };
};

const threadCard = (card: ThreadCardData): string => {
  return [
    `**${card.header}**`,
    card.subtitle ? truncate(card.subtitle, 180) : null,
    card.stage && card.stage.toLowerCase().includes("cancel")
      ? `**Status:** ${card.stage}`
      : null,
    card.unreadCount && card.unreadCount > 0
      ? `**Unread:** ${card.unreadCount}`
      : null,
    card.updatedAt ? `_Updated ${card.updatedAt}_` : null,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const threadCardsFromResult = (
  actionId: string,
  result: Record<string, unknown>,
): ThreadCardData[] => {
  if (actionId !== "hostr.updates" || result.ok === false) {
    return [];
  }
  const data = record(result.data);
  return arrayValue(data?.threads)
    .map(record)
    .filter(isRecord)
    .map(threadCardData)
    .filter((card): card is ThreadCardData => card !== null)
    .sort((a, b) => (b.updatedAtMs ?? 0) - (a.updatedAtMs ?? 0))
    .slice(0, 10);
};

const threadCardResponseText = (
  displayMarkdown: string,
  threadCards: ThreadCardData[],
): string => {
  const count = threadCards.length;
  return [
    `Hostr thread-card response: the assistant's final answer must render the Markdown thread card${count === 1 ? "" : "s"} below. Use each card header exactly, including unread counts like "Participant (1 Unread)" when present. Use resolved profile names and stay titles. Do not show raw pubkeys, conversation ids, thread anchors, or event JSON unless the user asks for debugging details.`,
    displayMarkdown,
  ].join("\n\n");
};

const threadViewData = (
  view: Record<string, unknown>,
  resultData?: Record<string, unknown> | null,
): ThreadViewData | null => {
  const title = stringValue(view.title) ?? "Hostr thread";
  const counterparties = arrayValue(view.counterparties)
    .map(record)
    .filter(isRecord)
    .map(profileDisplayName)
    .filter((name): name is string => name !== null);
  const messages = arrayValue(view.messages)
    .map(record)
    .filter(isRecord)
    .map((message): ThreadMessageData | null => {
      const content = stringValue(message.content);
      if (!content) return null;
      return {
        sender:
          stringValue(message.senderName) ??
          stringValue(message.sender) ??
          "Unknown",
        content,
        time: formatDateTime(message.createdAt) ?? undefined,
        sentByUser: boolValue(message.sentByUser) ?? undefined,
      };
    })
    .filter((message): message is ThreadMessageData => message !== null);
  const unreadCount = Number(view.unreadCount);
  const messageCount = Number(view.messageCount);
  return {
    type: "thread-view",
    title,
    counterparties,
    tradeId:
      stringValue(view.tradeId) ??
      stringValue(view.conversation) ??
      undefined,
    unreadCount: Number.isFinite(unreadCount) ? unreadCount : undefined,
    messageCount: Number.isFinite(messageCount)
      ? messageCount
      : messages.length,
    hasMoreMessages: boolValue(view.hasMoreMessages) ?? false,
    messages,
    requiresMessage: boolValue(resultData?.requiresMessage) ?? undefined,
  };
};

const threadViewsFromResult = (
  actionId: string,
  result: Record<string, unknown>,
): ThreadViewData[] => {
  if (
    !["hostr.thread.view", "hostr.thread.message", "hostr.escrow.involve"].includes(
      actionId,
    ) ||
    result.ok === false
  ) {
    return [];
  }
  const data = record(result.data);
  const direct = record(data?.threadView);
  const views = [
    ...(direct ? [direct] : []),
    ...arrayValue(data?.threadViews).map(record).filter(isRecord),
  ];
  return views
    .map((view) => threadViewData(view, data))
    .filter((view): view is ThreadViewData => view !== null);
};

const threadViewMarkdown = (view: ThreadViewData): string => {
  const title =
    view.counterparties.length > 0
      ? view.counterparties.join(", ")
      : view.title;
  const messageLines =
    view.messages.length > 0
      ? view.messages
          .map((message) =>
            [
              `**${message.sentByUser ? "You" : message.sender}**${
                message.time ? ` · ${message.time}` : ""
              }`,
              message.content,
            ].join("\n\n"),
          )
          .join("\n\n")
      : "_No text messages in this thread yet._";
  return [
    `**${title}**`,
    view.unreadCount && view.unreadCount > 0
      ? `**Unread:** ${view.unreadCount}`
      : null,
    view.requiresMessage
      ? "**Next:** Ask the user what they would like to message the escrow."
      : null,
    "**Messages**",
    messageLines,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const threadViewResponseText = (
  displayMarkdown: string,
  views: ThreadViewData[],
): string => {
  const count = views.length;
  return [
    `Hostr thread-view response: the assistant's final answer must render the Markdown thread view${count === 1 ? "" : "s"} below. Preserve each message as sender, message, and time. Use resolved profile names and do not show raw pubkeys, conversation ids, thread anchors, or event JSON unless the user explicitly asks for debugging details.`,
    displayMarkdown,
  ].join("\n\n");
};

type EscrowTradeCardData = {
  type: "escrow-trade-card";
  tradeId: string;
  title: string;
  status: string;
  amount?: string;
  bondAmount?: string;
  buyerName?: string;
  sellerName?: string;
  nextActions: string[];
  updatedBlockNum?: number;
  updatedAt?: string;
  lastTxHash?: string;
  eventCount?: number;
  audit?: {
    explanation?: string;
    listingTitle?: string;
    buyerStage?: string;
    sellerStage?: string;
    escrowStage?: string;
    formatted?: string;
  };
  arbitrationPreview?: {
    paymentForward?: number;
    bondForward?: number;
    reason?: string;
  };
};

const escrowAmountLabel = (
  value: unknown,
  fallbackTokenLabel?: string,
): string | undefined => {
  const amount = record(value);
  if (!amount) return undefined;
  const rawValue = stringValue(amount.value);
  if (!rawValue) return undefined;
  const token = record(amount.token);
  const tokenLabel =
    stringValue(token?.denomination) ??
    stringValue(token?.symbol) ??
    stringValue(token?.tagId) ??
    fallbackTokenLabel ??
    stringValue(token?.address) ??
    "token";
  return formatAmount({ value: rawValue, currency: tokenLabel });
};

const escrowParticipantName = (
  participants: Record<string, unknown> | null,
  role: "buyer" | "seller",
): string | undefined => {
  const profile = record(participants?.[role]);
  return (
    stringValue(profile?.name) ??
    stringValue(profile?.displayName) ??
    stringValue(profile?.profileName) ??
    (stringValue(profile?.pubkey) ? truncate(stringValue(profile?.pubkey)!, 12) : undefined)
  );
};

const escrowActionLabels = (value: unknown): string[] =>
  arrayValue(value)
    .map(record)
    .filter(isRecord)
    .map((action) => stringValue(action.label))
    .filter((label): label is string => Boolean(label));

const escrowTradeCardData = (
  card: Record<string, unknown>,
): EscrowTradeCardData | null => {
  const tradeId = stringValue(card.tradeId);
  if (!tradeId) return null;
  const lookup = record(card.reservationLookup);
  const group = record(lookup?.group);
  const listing = record(lookup?.listing);
  const title =
    stringValue(listing?.title) ??
    stringValue(group?.listingTitle) ??
    `Escrow trade ${truncate(tradeId, 14)}`;
  const updatedBlockNum = Number(card.updatedBlockNum);
  const preview = record(card.arbitrationPreview);
  const audit = record(card.audit);
  const buyer = record(audit?.buyer);
  const seller = record(audit?.seller);
  const escrow = record(audit?.escrow);
  const participants = record(card.participants);
  return {
    type: "escrow-trade-card",
    tradeId,
    title,
    status: stringValue(card.status) ?? "unknown",
    amount:
      stringValue(card.amountDisplay) ??
      escrowAmountLabel(
        card.amount,
        stringValue(card.tokenSymbol) ?? undefined,
      ),
    bondAmount: escrowAmountLabel(
      card.bondAmount,
      stringValue(card.tokenSymbol) ?? undefined,
    ),
    buyerName: escrowParticipantName(participants, "buyer"),
    sellerName: escrowParticipantName(participants, "seller"),
    nextActions: escrowActionLabels(card.nextActions),
    updatedBlockNum: Number.isFinite(updatedBlockNum)
      ? updatedBlockNum
      : undefined,
    updatedAt: stringValue(card.updatedAt) ?? undefined,
    lastTxHash: stringValue(card.lastTxHash) ?? undefined,
    eventCount: Number.isFinite(Number(card.eventCount))
      ? Number(card.eventCount)
      : undefined,
    audit: audit
      ? {
          explanation: stringValue(audit.explanation) ?? undefined,
          listingTitle: stringValue(audit.listingTitle) ?? undefined,
          buyerStage: stringValue(buyer?.currentStage) ?? undefined,
          sellerStage: stringValue(seller?.currentStage) ?? undefined,
          escrowStage: stringValue(escrow?.currentStage) ?? undefined,
          formatted: stringValue(audit.formatted) ?? undefined,
        }
      : undefined,
    arbitrationPreview: preview
      ? {
          paymentForward: Number(preview.paymentForward),
          bondForward: Number(preview.bondForward),
          reason: stringValue(preview.reason) ?? undefined,
        }
      : undefined,
  };
};

const escrowTradeCardsFromResult = (
  actionId: string,
  result: Record<string, unknown>,
): EscrowTradeCardData[] => {
  if (!escrowTradeActionIds.has(actionId) || result.ok === false) {
    return [];
  }
  const data = record(result.data);
  return arrayValue(data?.escrowTradeCards)
    .map(record)
    .filter(isRecord)
    .map(escrowTradeCardData)
    .filter((card): card is EscrowTradeCardData => card !== null);
};

type EscrowServiceCardData = {
  type: "escrow-service-card";
  title: string;
  pubkey?: string;
  evmAddress?: string;
  chainId?: number;
  contractAddress?: string;
  feePercent?: number;
  maxDurationSeconds?: number;
  tokenFeeHintCount: number;
  changes?: Record<string, unknown>;
  deleted?: boolean;
};

const escrowServiceCardData = (
  card: Record<string, unknown>,
): EscrowServiceCardData | null => {
  if (stringValue(card.type) !== "escrow-service-card") return null;
  const chainId = Number(card.chainId);
  const maxDurationSeconds = Number(card.maxDurationSeconds);
  const tokenFeeHints = record(card.tokenFeeHints);
  return {
    type: "escrow-service-card",
    title: stringValue(card.title) ?? "Escrow service",
    pubkey: stringValue(card.pubkey) ?? undefined,
    evmAddress: stringValue(card.evmAddress) ?? undefined,
    chainId: Number.isFinite(chainId) ? chainId : undefined,
    contractAddress: stringValue(card.contractAddress) ?? undefined,
    feePercent: Number.isFinite(Number(card.feePercent))
      ? Number(card.feePercent)
      : undefined,
    maxDurationSeconds: Number.isFinite(maxDurationSeconds)
      ? maxDurationSeconds
      : undefined,
    tokenFeeHintCount: tokenFeeHints ? Object.keys(tokenFeeHints).length : 0,
    changes: record(card.changes) ?? undefined,
    deleted: boolValue(card.deleted) ?? undefined,
  };
};

const escrowServiceCardsFromResult = (
  actionId: string,
  result: Record<string, unknown>,
): EscrowServiceCardData[] => {
  if (!escrowServiceActionIds.has(actionId) || result.ok === false) {
    return [];
  }
  const data = record(result.data);
  return arrayValue(data?.escrowServiceCards)
    .map(record)
    .filter(isRecord)
    .map(escrowServiceCardData)
    .filter((card): card is EscrowServiceCardData => card !== null);
};

const percentLabel = (value: number | undefined): string | null =>
  Number.isFinite(value) ? `${Math.round((value ?? 0) * 100)}%` : null;

const percentDecimalLabel = (value: number | undefined): string | null =>
  Number.isFinite(value) ? `${value}%` : null;

const durationLabel = (seconds: number | undefined): string | null => {
  if (!Number.isFinite(seconds)) return null;
  const days = Math.floor((seconds ?? 0) / 86400);
  if (days > 0 && days * 86400 === seconds) {
    return `${days} day${days === 1 ? "" : "s"}`;
  }
  return `${seconds} seconds`;
};

const escrowServiceCard = (card: EscrowServiceCardData): string => {
  const changes = card.changes ? Object.keys(card.changes) : [];
  return [
    `### ${card.title}`,
    card.deleted ? "**Deleted:** yes" : null,
    card.feePercent !== undefined
      ? `**Fee:** ${percentDecimalLabel(card.feePercent)}`
      : null,
    card.maxDurationSeconds !== undefined
      ? `**Max duration:** ${durationLabel(card.maxDurationSeconds)}`
      : null,
    `**Token fee hints:** ${card.tokenFeeHintCount}`,
    card.chainId !== undefined ? `**Chain:** ${card.chainId}` : null,
    card.evmAddress ? `**EVM address:** \`${card.evmAddress}\`` : null,
    card.contractAddress
      ? `**Contract:** \`${card.contractAddress}\``
      : null,
    changes.length > 0 ? `**Changes:** ${changes.join(", ")}` : null,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const escrowServiceResponseText = (
  displayMarkdown: string,
  cards: EscrowServiceCardData[],
): string =>
  [
    `Hostr escrow-service response: the assistant's final answer must render the Markdown escrow service card${cards.length === 1 ? "" : "s"} below. Do not replace this with raw JSON.`,
    displayMarkdown,
  ].join("\n\n");

type EscrowBadgeCardData = {
  type: "escrow-badge-definition-card" | "escrow-badge-award-card";
  title: string;
  anchor?: string;
  identifier?: string;
  name?: string;
  description?: string;
  image?: string;
  awardId?: string;
  definitionAnchor?: string;
  recipientPubkeys: string[];
  listingAnchor?: string;
  issuedAt?: string;
  deleted?: boolean;
};

const escrowBadgeCardData = (
  card: Record<string, unknown>,
): EscrowBadgeCardData | null => {
  const type = stringValue(card.type);
  if (
    type !== "escrow-badge-definition-card" &&
    type !== "escrow-badge-award-card"
  ) {
    return null;
  }
  return {
    type,
    title: stringValue(card.title) ?? "Escrow badge",
    anchor: stringValue(card.anchor) ?? undefined,
    identifier: stringValue(card.identifier) ?? undefined,
    name: stringValue(card.name) ?? undefined,
    description: stringValue(card.description) ?? undefined,
    image: stringValue(card.image) ?? undefined,
    awardId: stringValue(card.awardId) ?? undefined,
    definitionAnchor: stringValue(card.definitionAnchor) ?? undefined,
    recipientPubkeys: arrayValue(card.recipientPubkeys)
      .map(stringValue)
      .filter((value): value is string => value !== null),
    listingAnchor: stringValue(card.listingAnchor) ?? undefined,
    issuedAt: formatDateTime(card.issuedAt) ?? undefined,
    deleted: boolValue(card.deleted) ?? undefined,
  };
};

const escrowBadgeCardsFromResult = (
  actionId: string,
  result: Record<string, unknown>,
): EscrowBadgeCardData[] => {
  if (!escrowBadgeActionIds.has(actionId) || result.ok === false) {
    return [];
  }
  const data = record(result.data);
  return arrayValue(data?.badgeCards)
    .map(record)
    .filter(isRecord)
    .map(escrowBadgeCardData)
    .filter((card): card is EscrowBadgeCardData => card !== null);
};

const escrowBadgeCard = (card: EscrowBadgeCardData, index?: number): string => {
  if (card.type === "escrow-badge-definition-card") {
    return [
      `${index ? `### ${index}.` : "###"} ${card.title}`,
      card.deleted ? "**Deleted:** yes" : null,
      card.name ? `**Name:** ${card.name}` : null,
      card.identifier ? `**Identifier:** \`${card.identifier}\`` : null,
      card.anchor ? `**Anchor:** \`${card.anchor}\`` : null,
      card.description ? card.description : null,
      card.image ? `![Badge image](${card.image})` : null,
    ]
      .filter(Boolean)
      .join("\n\n");
  }
  return [
    `${index ? `### ${index}.` : "###"} ${card.title}`,
    card.deleted ? "**Revoked:** yes" : null,
    card.awardId ? `**Award:** \`${card.awardId}\`` : null,
    card.definitionAnchor
      ? `**Definition:** \`${card.definitionAnchor}\``
      : null,
    card.recipientPubkeys.length > 0
      ? `**Recipients:** ${card.recipientPubkeys
          .map((pubkey) => `\`${pubkey}\``)
          .join(", ")}`
      : null,
    card.listingAnchor ? `**Listing:** \`${card.listingAnchor}\`` : null,
    card.issuedAt ? `**Issued:** ${card.issuedAt}` : null,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const escrowBadgeResponseText = (
  displayMarkdown: string,
  cards: EscrowBadgeCardData[],
): string =>
  [
    `Hostr escrow-badge response: the assistant's final answer must render the Markdown badge card${cards.length === 1 ? "" : "s"} below. Do not replace this with raw JSON.`,
    displayMarkdown,
  ].join("\n\n");

const escrowTradeCard = (card: EscrowTradeCardData, index?: number): string => {
  const preview = card.arbitrationPreview;
  const audit = card.audit;
  const nextActions = card.nextActions.length
    ? card.nextActions.join(" or ")
    : card.status === "funded"
      ? "Arbitrate"
      : "View thread";
  return [
    `${index ? `### ${index}.` : "###"} ${card.title}`,
    `**Trade:** \`${card.tradeId}\``,
    `**Status:** ${card.status}`,
    card.amount ? `**Payment:** ${card.amount}` : null,
    card.bondAmount ? `**Bond:** ${card.bondAmount}` : null,
    card.buyerName ? `**Buyer:** ${card.buyerName}` : null,
    card.sellerName ? `**Seller:** ${card.sellerName}` : null,
    `**Next:** ${nextActions}`,
    preview
      ? `**Arbitration preview:** payment ${percentLabel(
          preview.paymentForward,
        )}, bond ${percentLabel(preview.bondForward)}`
      : null,
    preview?.reason ? `**Reason:** ${preview.reason}` : null,
    audit?.explanation ? `**Audit:** ${audit.explanation}` : null,
    audit?.buyerStage ? `**Buyer stage:** ${audit.buyerStage}` : null,
    audit?.sellerStage ? `**Seller stage:** ${audit.sellerStage}` : null,
    audit?.escrowStage ? `**Escrow stage:** ${audit.escrowStage}` : null,
    card.updatedBlockNum ? `**Updated block:** ${card.updatedBlockNum}` : null,
    card.lastTxHash ? `**Last tx:** \`${card.lastTxHash}\`` : null,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const tableCell = (value: string | undefined): string =>
  (value && value.trim().length > 0 ? value : "—").replace(/\|/g, "\\|");

const escrowTradeTable = (
  cards: EscrowTradeCardData[],
  totalCount?: number,
): string => {
  const rows = cards.map((card, index) =>
    [
      `${index + 1}`,
      `\`${truncate(card.tradeId, 10)}\``,
      card.title,
      card.buyerName,
      card.sellerName,
      card.amount,
      card.status,
      card.nextActions[0] ?? (card.status === "funded" ? "Arbitrate" : "View thread"),
    ]
      .map(tableCell)
      .join(" | "),
  );
  return [
    `### Escrow Trades`,
    totalCount !== undefined
      ? `Showing ${cards.length} of ${totalCount} tracked trade${totalCount === 1 ? "" : "s"}.`
      : `Showing ${cards.length} tracked trade${cards.length === 1 ? "" : "s"}.`,
    `| # | Trade | Stay | Buyer | Seller | Payment | Status | Next |`,
    `|---:|---|---|---|---|---:|---|---|`,
    ...rows.map((row) => `| ${row} |`),
  ].join("\n");
};

const escrowTradeResponseText = (
  displayMarkdown: string,
  cards: EscrowTradeCardData[],
): string =>
  [
    `Hostr escrow-trade response: the assistant's final answer must render the Markdown escrow trade ${cards.length === 1 ? "view" : "table/cards"} below. Do not replace this with raw JSON. If a trade view says Next: Arbitrate, ask for or preview arbitration; if it says Next: View thread, call the Hostr escrow-involve/thread-view flow for that trade when the user wants details.`,
    displayMarkdown,
  ].join("\n\n");

const criticalNoticesMarkdown = (
  config: AppConfig,
  notices: HostrCriticalNotice[],
): string => {
  if (notices.length === 0) {
    return "";
  }
  return notices
    .map((notice) => {
      if (notice.type === "signer-approval") {
        return [
          "### Signer Approval Required",
          notice.message,
          notice.signerMethod ? `**Method:** ${notice.signerMethod}` : null,
          notice.eventLabel ? `**Request:** ${notice.eventLabel}` : null,
        ]
          .filter(Boolean)
          .join("\n\n");
      }

      return paymentPromptMarkdown(config, notice) ?? "";
    })
    .join("\n\n");
};

const paymentDisplaysFromNotices = (
  config: AppConfig,
  notices: HostrCriticalNotice[],
): PaymentExternalRequiredDisplayData[] =>
  notices
    .filter((notice) => notice.type === "external-payment")
    .map((notice) => paymentExternalRequiredDisplay(config, notice))
    .filter(
      (display): display is PaymentExternalRequiredDisplayData =>
        display !== null,
    );

const paymentResponseText = (
  displayMarkdown: string,
): string => {
  return [
    "Hostr external-payment response: render the fixed payment display below exactly, then make the next assistant action a hostr_swaps_watch tool call using structuredContent.requiredNextTool.arguments. Do not stop after displaying the invoice, do not ask the user whether they paid first, and do not render the BOLT11 invoice inline. The exact invoice is available only through structuredContent.paymentDisplays[0].copy.text and the exact invoice text URL. Do not expose internal tradeId or swapId in the payment prompt.",
    displayMarkdown,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const compactPaymentRequiredResult = (
  safeResult: Record<string, unknown>,
  safeResultData: Record<string, unknown>,
  resultData: Record<string, unknown>,
): Record<string, unknown> => {
  const state = record(resultData.state);
  const safeState = record(safeResultData.state);
  const swapState = record(state?.swapState) ?? record(safeState?.swapState);
  const externalPayment =
    record(resultData.externalPayment) ??
    record(state?.externalPayment) ??
    record(safeResultData.externalPayment) ??
    record(safeState?.externalPayment);
  const rawNextTool =
    record(resultData.nextTool) ?? record(safeResultData.nextTool);
  const nextToolArguments = record(rawNextTool?.arguments);
  const tradeId =
    stringValue(resultData.tradeId) ??
    stringValue(safeResultData.tradeId) ??
    stringValue(externalPayment?.tradeId) ??
    stringValue(state?.tradeId) ??
    stringValue(safeState?.tradeId) ??
    stringValue(nextToolArguments?.tradeId);
  const swapId =
    stringValue(resultData.swapId) ??
    stringValue(safeResultData.swapId) ??
    stringValue(externalPayment?.swapId) ??
    stringValue(state?.swapId) ??
    stringValue(safeState?.swapId) ??
    stringValue(swapState?.id) ??
    stringValue(nextToolArguments?.swapId);
  const reservationWaitSeconds =
    numberValue(nextToolArguments?.reservationWaitSeconds) ??
    numberValue(resultData.reservationWaitSeconds) ??
    numberValue(safeResultData.reservationWaitSeconds) ??
    300;
  const watchArguments = {
    ...(swapId ? { swapId } : {}),
    ...(tradeId ? { tradeId } : {}),
    reservationWaitSeconds,
  };
  const nextTool =
    swapId || tradeId
      ? {
          name: "hostr_swaps_watch",
          arguments: watchArguments,
        }
      : undefined;

  return {
    ok: safeResult.ok,
    command: safeResult.command,
    environment: safeResult.environment,
    dryRun: safeResult.dryRun,
    traceId: safeResult.traceId,
    status: "payment_required" as const,
    stateName: "payment_required" as const,
    paymentRequired: true,
    externalPaymentRequired: true,
    ...(nextTool
      ? {
          nextTool,
          requiredNextTool: nextTool,
          nextAction:
            "Immediately call hostr_swaps_watch with requiredNextTool.arguments after rendering the payment display.",
        }
      : {}),
    data: {
      mode: stringValue(resultData.mode) ?? "book-and-pay",
      status: "payment_required" as const,
      stateName: "payment_required" as const,
      paymentRequired: true,
      externalPaymentRequired: true,
      ...(tradeId ? { tradeId } : {}),
      ...(swapId ? { swapId } : {}),
      ...(boolValue(resultData.continuesInBackground) !== null
        ? { continuesInBackground: boolValue(resultData.continuesInBackground) }
        : {}),
      ...(nextTool ? { nextTool, requiredNextTool: nextTool } : {}),
    },
  };
};

const retryWatchArguments = (
  data: Record<string, unknown>,
): Record<string, unknown> => {
  const state = record(data.state);
  const retry = record(data.retry);
  const retryArguments = record(retry?.arguments);
  const swapState = record(data.swapState) ?? record(state?.swapState);
  const swapId =
    stringValue(data.swapId) ??
    stringValue(state?.swapId) ??
    stringValue(swapState?.id) ??
    stringValue(retryArguments?.swapId);
  const tradeId =
    stringValue(data.tradeId) ??
    stringValue(state?.tradeId) ??
    stringValue(retryArguments?.tradeId);
  const reservationWaitSeconds =
    numberValue(data.reservationWaitSeconds) ??
    numberValue(retryArguments?.reservationWaitSeconds) ??
    300;
  return {
    ...(swapId ? { swapId } : {}),
    ...(tradeId ? { tradeId } : {}),
    reservationWaitSeconds,
  };
};

const swapWatchInfo = (
  result: Record<string, unknown>,
): Record<string, unknown> | null => {
  const data = record(result.data);
  if (!data) {
    return null;
  }
  const state = record(data.state);
  const swapState = record(data.swapState) ?? record(state?.swapState);
  const reservationLookup =
    record(data.reservationLookup) ?? record(state?.reservationLookup);
  const stateName =
    stringValue(data.stateName) ??
    stringValue(state?.state) ??
    stringValue(swapState?.state) ??
    (result.ok === false ? "failed" : "unknown");
  const retryArguments = retryWatchArguments(data);
  const isTerminal =
    boolValue(data.isTerminal) ??
    boolValue(state?.isTerminal) ??
    boolValue(swapState?.isTerminal) ??
    false;
  const error = record(arrayValue(result.errors)[0]);
  const errorCode = stringValue(error?.code);
  const failureReason =
    stringValue(data.failureReason) ??
    stringValue(data.error) ??
    stringValue(state?.error) ??
    stringValue(swapState?.error) ??
    stringValue(error?.message);
  const lowerState = stateName.toLowerCase();
  const timedOut =
    data.watchTimedOut === true ||
    errorCode === "hostr_swap_watch_timeout" ||
    lowerState === "watch_timeout";
  const failed =
    !timedOut &&
    (result.ok === false ||
      /\b(fail|failed|failure|error|expired|cancelled|canceled|refund)\b/i.test(
        stateName,
      ));
  const foundReservation = reservationLookup?.found === true;
  const reservationPending =
    !foundReservation &&
    !failed &&
    isTerminal &&
    /\b(complet|settled|claimed|paid|proof)\b/i.test(stateName);
  const paymentAwaiting =
    !foundReservation && !failed && !reservationPending;
  const status = failed
    ? "swap_failed"
    : reservationPending
      ? "reservation_pending"
      : paymentAwaiting
        ? "payment_awaiting"
        : "completed";

  return {
    status,
    stateName,
    isTerminal,
    paymentAwaiting,
    reservationPending,
    swapFailed: failed,
    watchTimedOut: timedOut,
    ...(failureReason ? { failureReason } : {}),
    retry: {
      name: "hostr_swaps_watch",
      arguments: retryArguments,
    },
  };
};

const compactSwapWatchResult = (
  safeResult: Record<string, unknown>,
  safeResultData: Record<string, unknown>,
  info: Record<string, unknown>,
): Record<string, unknown> => ({
  ...safeResult,
  status: info.status,
  stateName: info.stateName,
  paymentAwaiting: info.paymentAwaiting,
  reservationPending: info.reservationPending,
  swapFailed: info.swapFailed,
  watchTimedOut: info.watchTimedOut,
  retry: info.retry,
  data: {
    ...safeResultData,
    status: info.status,
    stateName: info.stateName,
    paymentAwaiting: info.paymentAwaiting,
    reservationPending: info.reservationPending,
    swapFailed: info.swapFailed,
    watchTimedOut: info.watchTimedOut,
    retry: info.retry,
    ...(info.failureReason ? { failureReason: info.failureReason } : {}),
  },
});

const swapWatchTimeoutResult = (
  actionId: string,
  args: Record<string, unknown>,
  error: unknown,
): Record<string, unknown> => ({
  ok: true,
  command: actionId,
  data: {
    status: "payment_awaiting",
    stateName: "watch_timeout",
    paymentAwaiting: true,
    watchTimedOut: true,
    message: "Payment is still being awaited. Did you pay the invoice?",
    retry: {
      name: "hostr_swaps_watch",
      arguments: retryWatchArguments({
        swapId: args.swapId,
        tradeId: args.tradeId,
        reservationWaitSeconds: args.reservationWaitSeconds,
      }),
    },
    warning:
      error instanceof Error
        ? error.message
        : "Hostr swap watch timed out before payment completion.",
  },
});

const paymentQrImageBlock = (
  config: AppConfig,
  notice: HostrCriticalNotice,
): ContentBlock | null => {
  if (notice.type !== "external-payment") {
    return null;
  }
  const display = paymentExternalRequiredDisplay(config, notice);
  if (!display?.qrImageUrl) {
    return null;
  }

  const qrImage = stringValue(notice.qrImage);
  const match = /^data:image\/png;base64,(.+)$/i.exec(qrImage ?? "");
  if (!match) {
    return null;
  }

  return {
    type: "image",
    data: match[1],
    mimeType: "image/png",
    annotations: {
      audience: ["user", "assistant"],
      priority: 1,
    },
    _meta: {
      "hostr.contentType": "payment-qr",
      "hostr.display": display,
      "hostr.alt": "Lightning invoice QR",
    },
  };
};

const criticalNoticeImageBlocks = (
  config: AppConfig,
  notices: HostrCriticalNotice[],
): ContentBlock[] =>
  notices
    .map((notice) => paymentQrImageBlock(config, notice))
    .filter((block): block is ContentBlock => block !== null);

const sessionConnectQrImageBlock = (
  result: Record<string, unknown>,
  display: Record<string, unknown> | undefined,
): ContentBlock | null => {
  const data = record(result.data);
  const qrImage = stringValue(data?.qrImage);
  const match = /^data:image\/png;base64,(.+)$/i.exec(qrImage ?? "");
  if (!match) {
    return null;
  }

  return {
    type: "image",
    data: match[1],
    mimeType: "image/png",
    annotations: {
      audience: ["user", "assistant"],
      priority: 1,
    },
    _meta: {
      "hostr.contentType": "nostr-connect-qr",
      ...(display ? { "hostr.display": display } : {}),
      "hostr.alt": "Nostr Connect QR",
    },
  };
};

const formatError = (result: Record<string, unknown>): string => {
  const first = record(arrayValue(result.errors)[0]);
  const message = stringValue(first?.message) ?? "The Hostr action failed.";
  const code = stringValue(first?.code);
  const hint = stringValue(first?.hint);
  return [
    `Hostr action failed${code ? ` (${code})` : ""}: ${message}`,
    hint ? `Hint: ${hint}` : null,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const errorAssistantInstructions = (
  result: Record<string, unknown>,
): string[] | undefined => {
  const errors = arrayValue(result.errors).map(record).filter(isRecord);
  const instructions: string[] = [];
  for (const error of errors) {
    const details = record(error.details);
    const detailInstructions = arrayValue(details?.assistantInstructions)
      .map(stringValue)
      .filter((instruction): instruction is string => instruction !== null);
    instructions.push(...detailInstructions);

    const code = stringValue(error.code);
    if (code === "auth_required") {
      instructions.push(
        "Call hostr_session_connect to reconnect the Hostr/Nostr session, complete the sign-in flow, then retry the original Hostr action with the same user-approved intent.",
      );
    }
    if (code === "profile_required") {
      instructions.push(
        "Ask for any missing profile fields needed to continue, call hostr_profile_edit with dryRun=true, publish with dryRun=false after explicit approval, then retry the original Hostr action.",
      );
    }
  }

  return instructions.length > 0 ? Array.from(new Set(instructions)) : undefined;
};

const formatToolContent = (
  config: AppConfig,
  actionId: string,
  result: Record<string, unknown>,
): string => {
  if (actionId === "hostr.swaps.watch") {
    const info = swapWatchInfo(result);
    if (info?.status === "payment_awaiting") {
      return "Payment is still being awaited. Did you pay the invoice?";
    }
    if (info?.status === "swap_failed") {
      return [
        "### Swap Failed",
        info.failureReason
          ? `The payment swap failed: ${stringValue(info.failureReason)}`
          : "The payment swap failed.",
        "The invoice should not be treated as payable for this booking. Check the swap details or run recovery before trying again.",
      ]
        .filter(Boolean)
        .join("\n\n");
    }
    if (info?.status === "reservation_pending") {
      return "Payment has been detected, but the reservation is still being finalized. I'll check for the reservation again.";
    }
  }

  if (result.ok === false) {
    return formatError(result);
  }

  const data = record(result.data);
  if (!data) {
    return "Done.";
  }

  if (
    actionId === "hostr.listings.search" ||
    actionId === "hostr.listings.list"
  ) {
    const listings = arrayValue(data.listings).map(record).filter(isRecord);
    if (listings.length === 0) {
      return "No matching Hostr listings found.";
    }
    return listings
      .map((listing, index) => listingCard(config, listing, index + 1))
      .join("\n\n---\n\n");
  }

  if (actionId === "hostr.listings.create") {
    const listing = record(data.listing);
    if (listing) {
      return listingCard(
        config,
        listing,
        null,
        result.dryRun === true ? "preview" : "published",
      );
    }
  }

  if (actionId === "hostr.listings.edit") {
    const listing = record(data.listing);
    if (listing) {
      return listingCard(
        config,
        listing,
        null,
        result.dryRun === true ? "preview" : "published",
      );
    }
  }

  if (actionId === "hostr.reservations.negotiateOffer") {
    const listing = record(data.listing);
    const tradeId = stringValue(data.tradeId);
    const mode = result.dryRun === true ? "Preview" : "Broadcast";
    return [
      `### Reservation ${mode}`,
      listing
        ? `**Listing:** ${stringValue(listing.title) ?? "Untitled listing"}`
        : null,
      tradeId ? `**Trade ID:** ${tradeId}` : null,
      `**Delivery:** ${stringValue(data.delivery) ?? "giftwrap"}`,
    ]
      .filter(Boolean)
      .join("\n\n");
  }

  if (actionId === "hostr.reservations.bookAndPay") {
    const state = record(data.state);
    const stateName = stringValue(state?.state) ?? stringValue(data.stateName);
    const externalPayment =
      record(data.externalPayment) ?? record(state?.externalPayment);
    const reservation = record(state?.reservation);
    const eventId = stringValue(reservation?.id);
    const continuesInBackground = data.continuesInBackground === true;
    const paymentPrompt = paymentPromptMarkdown(config, externalPayment);
    if (paymentPrompt) {
      return paymentPrompt;
    }
    return [
      stateName === "completed"
        ? "### Reservation Booked And Paid"
        : "### Reservation Book And Pay",
      stateName ? `**State:** ${stateName}` : null,
      eventId ? `**Reservation Event:** ${eventId}` : null,
      continuesInBackground
        ? "**Background:** Hostr daemon is continuing book-and-pay."
        : null,
    ]
      .filter(Boolean)
      .join("\n\n");
  }

  if (actionId === "hostr.swaps.watch") {
    const lookup = record(data.reservationLookup);
    const confirmed = reservationCardData(lookup);
    if (confirmed) {
      return reservationCard(confirmed);
    }
    const externalPayment = record(data.externalPayment);
    const state = record(data.state);
    const stateName = stringValue(data.stateName) ?? stringValue(state?.state);
    const paymentPrompt = paymentPromptMarkdown(config, externalPayment);
    if (paymentPrompt) {
      return paymentPrompt;
    }
    if (externalPayment) {
      return "External Lightning payment required.";
    }
    const info = swapWatchInfo(result);
    if (info?.status === "payment_awaiting") {
      return "Payment is still being awaited. Did you pay the invoice?";
    }
    if (info?.status === "swap_failed") {
      return [
        "### Swap Failed",
        stringValue(info.failureReason)
          ? `The payment swap failed: ${stringValue(info.failureReason)}`
          : "The payment swap failed.",
      ]
        .filter(Boolean)
        .join("\n\n");
    }
    return [
      "### Swap Watch",
      stateName ? `**State:** ${stateName}` : null,
      `**Terminal:** ${data.isTerminal === true ? "yes" : "no"}`,
      lookup && lookup.found !== true
        ? "Reservation is still being finalized."
        : null,
    ]
      .filter(Boolean)
      .join("\n\n");
  }

  if (actionId === "hostr.trips.list" || actionId === "hostr.bookings.list") {
    const confirmed = reservationCardData(data);
    if (confirmed) {
      return reservationCard(confirmed);
    }
    if (stringValue(data.tradeId)) {
      return "Reservation is still being finalized.";
    }
  }

  if (actionId === "hostr.updates") {
    const threadCards = threadCardsFromResult(actionId, result);
    if (threadCards.length === 0) {
      return "No recent Hostr threads found.";
    }
    return [
      "**Recent Hostr Threads**",
      threadCards.map((card) => threadCard(card)).join("\n\n---\n\n"),
    ].join("\n\n");
  }

  if (
    ["hostr.thread.view", "hostr.thread.message", "hostr.escrow.involve"].includes(
      actionId,
    )
  ) {
    const threadViews = threadViewsFromResult(actionId, result);
    if (threadViews.length === 0) {
      return stringValue(data.message) ?? "No Hostr thread found.";
    }
    return threadViews.map(threadViewMarkdown).join("\n\n---\n\n");
  }

  if (profileActionIds.has(actionId)) {
    const card = profileCardData(actionId, result);
    return card ? profileCardMarkdown(card) : "No Hostr profile found.";
  }

  if (actionId === "hostr.session.connect") {
    if (data.authenticated === true) {
      return `Hostr session connected for ${stringValue(data.pubkey) ?? "the active Hostr account"}.`;
    }
    const nostrconnect = stringValue(data.nostrconnect);
    const displayTitle = stringValue(data.displayTitle) ?? "Log in to Hostr";
    const displayMessage =
      stringValue(data.displayMessage) ??
      "Scan this with your Nostr app to log in to your Hostr account.";
    const qrImage = stringValue(data.qrImage);
    const remoteQrUrl = nostrconnect ? qrImageUrl(config, nostrconnect) : null;
    const asset = nostrconnect
      ? storeQrTextAsset(remoteQrUrl ? null : qrImage, nostrconnect)
      : null;
    const qrUrl =
      remoteQrUrl ??
      (asset?.qrUrlPath ? absoluteUrl(config, asset.qrUrlPath) : null);
    const textUrl = asset?.textUrlPath
      ? absoluteUrl(config, asset.textUrlPath)
      : null;
    return [
      `### ${displayTitle}`,
      displayMessage,
      qrUrl ? `![Nostr Connect QR](${qrUrl})` : null,
      textUrl ? `[Open exact nostrconnect URI](${textUrl})` : null,
      nostrconnect ? "```text" : null,
      nostrconnect,
      nostrconnect ? "```" : null,
      stringValue(data.nextStep),
    ]
      .filter(Boolean)
      .join("\n\n");
  }

  if (escrowTradeActionIds.has(actionId)) {
    const cards = escrowTradeCardsFromResult(actionId, result);
    if (cards.length === 0) {
      return "No escrow trades found.";
    }
    if (actionId === "hostr.escrow.trades.list") {
      const data = record(result.data);
      const totalCount = Number(data?.totalCount);
      return escrowTradeTable(
        cards,
        Number.isFinite(totalCount) ? totalCount : undefined,
      );
    }
    return cards
      .map((card, index) =>
        escrowTradeCard(card, cards.length > 1 ? index + 1 : undefined),
      )
      .join("\n\n---\n\n");
  }

  if (escrowServiceActionIds.has(actionId)) {
    const cards = escrowServiceCardsFromResult(actionId, result);
    if (cards.length === 0) {
      return "No escrow service settings returned.";
    }
    return cards.map(escrowServiceCard).join("\n\n---\n\n");
  }

  if (escrowBadgeActionIds.has(actionId)) {
    const cards = escrowBadgeCardsFromResult(actionId, result);
    if (cards.length === 0) {
      return "No escrow badges found.";
    }
    return cards
      .map((card, index) =>
        escrowBadgeCard(card, cards.length > 1 ? index + 1 : undefined),
      )
      .join("\n\n---\n\n");
  }

  return text(result);
};

const toolResponse = async (
  config: AppConfig,
  actionId: string,
  result: Record<string, unknown>,
  isError: boolean,
  notices: HostrCriticalNotice[] = [],
) => {
  const displayMarkdown = formatToolContent(config, actionId, result);
  const structuredResultSource = normalizeListingResultImages(
    config,
    actionId,
    result,
  );
  const safeResult = sanitizeForStructuredContent(
    structuredResultSource,
  ) as Record<string, unknown>;
  const resultData = record(result.data) ?? {};
  const safeResultData = record(safeResult.data) ?? {};
  const listingCards = listingCardsFromResult(config, actionId, result);
  const listingCardDisplay =
    listingCards.length > 0
      ? {
          type:
            listingCards.length === 1 ? "listing-card" : "listing-card-list",
          cards: listingCards,
        }
      : undefined;
  const reservationCards = reservationCardsFromResult(actionId, result);
  const reservationCardDisplay =
    reservationCards.length > 0
      ? {
          type:
            reservationCards[0]?.type === "hosting-card"
              ? reservationCards.length === 1
                ? "hosting-card"
                : "hosting-card-list"
              : reservationCards.length === 1
                ? "trip-card"
                : "trip-card-list",
          cards: reservationCards,
        }
      : undefined;
  const profileCards = profileCardsFromResult(actionId, result);
  const profileCardDisplay =
    profileCards.length > 0
      ? {
          type:
            safeResult.dryRun === true
              ? ("profile-preview" as const)
              : actionId === "hostr.profile.edit"
                ? ("profile-result" as const)
                : ("profile-card" as const),
          cards: profileCards,
        }
      : undefined;
  const threadCards = threadCardsFromResult(actionId, result);
  const threadCardDisplay =
    threadCards.length > 0
      ? {
          type: "thread-card-list" as const,
          cards: threadCards,
        }
      : undefined;
  const threadViews = threadViewsFromResult(actionId, result);
  const threadViewDisplay =
    threadViews.length > 0
      ? {
          type: "thread-view" as const,
          cards: threadViews,
        }
      : undefined;
  const escrowTradeCards = escrowTradeCardsFromResult(actionId, result);
  const escrowTradeDisplay =
    escrowTradeCards.length > 0
      ? {
          type:
            actionId === "hostr.escrow.trades.list"
              ? ("escrow-trade-list" as const)
              : actionId === "hostr.escrow.trades.arbitrate" &&
                  safeResult.dryRun === true
                ? ("escrow-arbitration-preview" as const)
                : actionId === "hostr.escrow.trades.arbitrate"
                  ? ("escrow-arbitration-result" as const)
                  : ("escrow-trade-view" as const),
          cards: escrowTradeCards,
        }
      : undefined;
  const escrowServiceCards = escrowServiceCardsFromResult(actionId, result);
  const escrowServiceDisplay =
    escrowServiceCards.length > 0
      ? {
          type:
            safeResult.dryRun === true
              ? ("escrow-service-preview" as const)
              : ("escrow-service-result" as const),
          cards: escrowServiceCards,
        }
      : undefined;
  const escrowBadgeCards = escrowBadgeCardsFromResult(actionId, result);
  const escrowBadgeDisplay =
    escrowBadgeCards.length > 0
      ? {
          type:
            safeResult.dryRun === true
              ? ("escrow-badge-preview" as const)
              : actionId.endsWith(".list")
                ? ("escrow-badge-list" as const)
                : ("escrow-badge-result" as const),
          cards: escrowBadgeCards,
        }
      : undefined;
  const paymentDisplays = paymentDisplaysFromNotices(config, notices);
  const paymentDisplay =
    paymentDisplays.length > 0 &&
    !listingCardDisplay &&
    !reservationCardDisplay &&
    !threadCardDisplay &&
    !threadViewDisplay
      ? {
          type: "payment-external-required" as const,
          cards: paymentDisplays,
        }
      : undefined;
  const errorInstructions =
    safeResult.ok === false ? errorAssistantInstructions(safeResult) : undefined;
  const compactThreadResult =
    actionId === "hostr.updates"
      ? {
          ok: safeResult.ok,
          command: safeResult.command,
          environment: safeResult.environment,
          dryRun: safeResult.dryRun,
          traceId: safeResult.traceId,
          data: {
            count: Number.isFinite(Number(resultData.count))
              ? Number(resultData.count)
              : undefined,
            threadCount: threadCards.length,
            hasMoreThreads:
              arrayValue(resultData.threads).length > threadCards.length,
          },
        }
      : safeResult;
  const safeNotices = notices.map(sanitizeNotice);
  const presentationMarkdown = listingCardDisplay
    ? listingCardsMarkdown(listingCards)
    : reservationCardDisplay
      ? reservationCardsMarkdown(reservationCards)
      : profileCardDisplay
        ? profileCardsMarkdown(profileCards)
        : displayMarkdown;
  const contentText = listingCardDisplay
    ? listingCardResponseText(presentationMarkdown, listingCards)
    : reservationCardDisplay
      ? reservationCardResponseText(presentationMarkdown, reservationCards)
      : profileCardDisplay
        ? profileCardResponseText(presentationMarkdown)
        : threadViewDisplay
          ? threadViewResponseText(displayMarkdown, threadViews)
          : escrowTradeDisplay
            ? escrowTradeResponseText(displayMarkdown, escrowTradeCards)
            : escrowServiceDisplay
              ? escrowServiceResponseText(displayMarkdown, escrowServiceCards)
              : escrowBadgeDisplay
                ? escrowBadgeResponseText(displayMarkdown, escrowBadgeCards)
                : threadCardDisplay
                  ? threadCardResponseText(displayMarkdown, threadCards)
                  : paymentDisplay
                    ? paymentResponseText(
                        paymentDisplayMarkdown(paymentDisplays[0]),
                      )
                    : [
                        criticalNoticesMarkdown(config, notices),
                        displayMarkdown,
                      ]
                        .filter(Boolean)
                        .join("\n\n");
  const noticeImageBlocks = paymentDisplay
    ? []
    : criticalNoticeImageBlocks(config, notices);
  const daemonAssistantInstructions = arrayValue(
    resultData.assistantInstructions,
  )
    .map(stringValue)
    .filter((instruction): instruction is string => Boolean(instruction));
  const nextInput = record(resultData.nextInput);
  const listingCreatePreviewDTag =
    actionId === "hostr.listings.create" && safeResult.dryRun === true
      ? (stringValue(resultData.dTag) ??
        stringValue(nextInput?.dTag) ??
        stringValue(record(resultData.listing)?.dTag) ??
        listingCards[0]?.dTag)
      : undefined;
  const listingCardAssistantInstructions = listingCardDisplay
    ? [
        "When answering the user, render structuredContent.displayMarkdown as Markdown.",
        "Preserve every listing image Markdown tag exactly; do not summarize listing results as text-only prose.",
        ...daemonAssistantInstructions,
        ...(listingCreatePreviewDTag
          ? [
              `When the user explicitly approves this create-listing preview, call hostr_listings_create again with dryRun=false and dTag="${listingCreatePreviewDTag}". Reuse that exact dTag on any retry so the publish updates the same replaceable listing instead of creating a duplicate.`,
            ]
          : []),
      ]
    : undefined;
  const reservationCardAssistantInstructions = reservationCardDisplay
    ? [
        "When answering the user, render structuredContent.displayMarkdown as Markdown.",
        "Preserve the trip or hosting card exactly; do not replace it with raw JSON or internal swap state.",
        "For cancelled trips, preserve the bold **Cancelled** line.",
      ]
    : undefined;
  const profileCardAssistantInstructions = profileCardDisplay
    ? [
        "When answering the user, render structuredContent.displayMarkdown as Markdown.",
        "Preserve the profile card exactly; do not replace it with raw JSON or expose pubkeys, EVM addresses, or internal ids.",
      ]
    : undefined;
  const paymentAssistantInstructions = notices.some(
    (notice) => notice.type === "external-payment",
  )
    ? [
      "CRITICAL: The Hostr result contains structuredContent.display.type=payment-external-required. Render structuredContent.displayMarkdown exactly so the user sees the QR and exact invoice/copy affordance.",
      "The invoice copy source of truth is structuredContent.paymentDisplays[0].copy.text or the exact invoice text URL. Do not manually retype, display inline, truncate, normalize, wrap, add punctuation to, or otherwise modify the invoice string.",
      "Do not show internal tradeId or swapId in the payment prompt.",
      "The next assistant action after rendering this payment display MUST be a tool call to the read-only hostr_swaps_watch using structuredContent.requiredNextTool.arguments. Do not end the turn, ask the user whether they paid, or wait for user confirmation before making this watch call.",
      "When watch completes or reports the swap is not found, call hostr_trips_list with the same tradeId until the committed reservation appears, then show the trip card.",
    ]
    : undefined;
  const bookAndPayPaymentRequired =
    actionId === "hostr.reservations.bookAndPay" && Boolean(paymentDisplay);
  const swapWatchStatus =
    actionId === "hostr.swaps.watch" ? swapWatchInfo(safeResult) : null;
  const structuredResult = bookAndPayPaymentRequired
    ? compactPaymentRequiredResult(safeResult, safeResultData, resultData)
    : swapWatchStatus
      ? compactSwapWatchResult(safeResult, safeResultData, swapWatchStatus)
    : compactThreadResult;
  const requiredNextTool = bookAndPayPaymentRequired
    ? (record(structuredResult.requiredNextTool) ??
      record(structuredResult.nextTool) ??
      record(record(structuredResult.data)?.requiredNextTool) ??
      record(record(structuredResult.data)?.nextTool))
    : undefined;
  const sessionConnectPending =
    actionId === "hostr.session.connect" &&
    resultData.authenticated !== true &&
    resultData.pending === true;
  const sessionConnectAssistantInstructions = sessionConnectPending
    ? [
        "Render structuredContent.displayMarkdown as Markdown so the user sees the Nostr Connect QR.",
        "Use the exact text: \"Scan this with your Nostr app to log in to your Hostr account.\"",
        "Do not stop after displaying the QR. Immediately call hostr_session_connect with wait=true and regenerate=false to listen for the session connection.",
        "After hostr_session_connect returns authenticated=true, retry or continue the Hostr action that required sign-in.",
      ]
    : undefined;
  const sessionConnectDisplay = sessionConnectPending
    ? sessionConnectDisplayData(config, result, safeResultData)
    : undefined;
  const sessionConnectImageBlock = sessionConnectPending
    ? sessionConnectQrImageBlock(result, sessionConnectDisplay)
    : null;
  const swapWatchAssistantInstructions = swapWatchStatus
    ? swapWatchStatus.status === "payment_awaiting"
      ? [
          "Tell the user exactly: \"Payment is still being awaited. Did you pay the invoice?\"",
          "If the user replies yes, paid, done, sent, or otherwise indicates they paid, immediately call hostr_swaps_watch again with structuredContent.retry.arguments. Do not ask for swapId or tradeId.",
          "If the user says they have not paid, tell them to pay the visible Lightning invoice and reply yes once paid.",
        ]
      : swapWatchStatus.status === "swap_failed"
        ? [
            "Tell the user the swap failed, using structuredContent.data.failureReason when present.",
            "Do not keep polling a failed swap automatically. Offer to inspect swaps or run the explicit recovery workflow if the user wants debugging or recovery.",
          ]
        : swapWatchStatus.status === "reservation_pending"
          ? [
              "Tell the user payment has been detected but the reservation is still being finalized.",
              "Call hostr_trips_list with the same tradeId if available, or call hostr_swaps_watch again with structuredContent.retry.arguments.",
            ]
          : undefined
    : undefined;
  const responseWidgetUri = paymentDisplay
    ? paymentRequiredWidgetUri
    : sessionConnectDisplay
      ? sessionConnectWidgetUri
      : listingCardDisplay
        ? listingCardWidgetUri
        : profileCardDisplay
          ? profileCardWidgetUri
          : reservationCardDisplay
            ? reservationCardDisplay.type.startsWith("hosting")
              ? hostingWidgetUri
              : tripWidgetUri
            : undefined;
  const responseDisplay =
    paymentDisplay ??
    sessionConnectDisplay ??
    listingCardDisplay ??
    profileCardDisplay ??
    reservationCardDisplay;
  const responseDisplayType = stringValue(record(responseDisplay)?.type);
  const responseWidgetMeta = responseWidgetUri
    ? widgetResultMeta(responseWidgetUri, {
        ...(paymentDisplay
          ? { "openai/outputTemplate": paymentRequiredWidgetUri }
          : {}),
        ...(responseDisplayType
          ? { "hostr.contentType": responseDisplayType }
          : {}),
      })
    : undefined;
  const responseNotices = bookAndPayPaymentRequired ? [] : safeNotices;
  const threadCardAssistantInstructions = threadCardDisplay
    ? [
        "When answering the user, render structuredContent.displayMarkdown as Markdown.",
        "Preserve the thread cards exactly; do not replace them with raw JSON.",
        "Use resolved profile names and stay titles. Do not show raw pubkeys, conversation ids, thread anchors, event ids, or event JSON unless the user explicitly asks for debugging details.",
      ]
    : undefined;
  const threadViewAssistantInstructions = threadViewDisplay
    ? [
        "When answering the user, render structuredContent.displayMarkdown as Markdown.",
        "Preserve the thread view exactly, including each message sender, message, and time.",
        "Use resolved profile names. Do not show raw pubkeys, conversation ids, thread anchors, event ids, or event JSON unless the user explicitly asks for debugging details.",
        "If structuredContent.requiresMessage or the thread view asks for a next message, ask the user what they want to send before calling a send tool.",
      ]
    : undefined;
  const escrowTradeAssistantInstructions = escrowTradeDisplay
    ? [
        "When answering the user, render structuredContent.displayMarkdown as Markdown.",
        "Preserve the escrow trade table or card exactly; do not replace it with raw JSON.",
        "For an escrow trade view, prompt the escrow user to arbitrate when the trade is not terminal, otherwise prompt them to view the trade thread.",
        "For arbitration, keep dryRun=true until the user explicitly approves the preview.",
      ]
    : undefined;
  const escrowServiceAssistantInstructions = escrowServiceDisplay
    ? [
        "When answering the user, render structuredContent.displayMarkdown as Markdown.",
        "Preserve the escrow service card exactly; do not replace it with raw JSON.",
        "For service updates, keep dryRun=true until the user explicitly approves publishing the new settings.",
        "Use hostr_profile_edit for escrow profile metadata; this escrow service tool only changes service parameters.",
      ]
    : undefined;
  const escrowBadgeAssistantInstructions = escrowBadgeDisplay
    ? [
        "When answering the user, render structuredContent.displayMarkdown as Markdown.",
        "Preserve the escrow badge cards exactly; do not replace them with raw JSON.",
        "For badge writes or deletions, keep dryRun=true until the user explicitly approves the preview.",
      ]
    : undefined;
  return {
    isError,
    structuredContent: {
      ...structuredResult,
      displayMarkdown: presentationMarkdown,
      ...(responseNotices.length > 0 ? { hostrNotices: responseNotices } : {}),
      ...(paymentAssistantInstructions
        ? { assistantInstructions: paymentAssistantInstructions }
        : {}),
      ...(requiredNextTool
        ? {
            nextTool: requiredNextTool,
            requiredNextTool,
            nextAction:
              "Immediately call hostr_swaps_watch with requiredNextTool.arguments after rendering the payment display.",
          }
        : {}),
      ...(errorInstructions ? { assistantInstructions: errorInstructions } : {}),
      ...(sessionConnectAssistantInstructions
        ? { assistantInstructions: sessionConnectAssistantInstructions }
        : {}),
      ...(swapWatchAssistantInstructions
        ? { assistantInstructions: swapWatchAssistantInstructions }
        : {}),
      ...(sessionConnectDisplay
        ? { display: sessionConnectDisplay }
        : {}),
      ...(listingCardDisplay
        ? {
            assistantInstructions: listingCardAssistantInstructions,
            display: listingCardDisplay,
            listingCards,
          }
        : {}),
      ...(reservationCardDisplay
        ? {
            assistantInstructions: reservationCardAssistantInstructions,
            display: reservationCardDisplay,
            reservationCards,
            ...(reservationCardDisplay.type.startsWith("hosting")
              ? { hostingCards: reservationCards }
              : { tripCards: reservationCards }),
          }
        : {}),
      ...(profileCardDisplay
        ? {
            assistantInstructions: profileCardAssistantInstructions,
            display: profileCardDisplay,
            profileCards,
          }
        : {}),
      ...(threadCardDisplay
        ? {
            assistantInstructions: threadCardAssistantInstructions,
            display: threadCardDisplay,
            threadCards,
          }
        : {}),
      ...(threadViewDisplay
        ? {
            assistantInstructions: threadViewAssistantInstructions,
            display: threadViewDisplay,
            threadViews,
          }
        : {}),
      ...(escrowTradeDisplay
        ? {
            assistantInstructions: escrowTradeAssistantInstructions,
            display: escrowTradeDisplay,
            escrowTradeCards,
          }
        : {}),
      ...(escrowServiceDisplay
        ? {
            assistantInstructions: escrowServiceAssistantInstructions,
            display: escrowServiceDisplay,
            escrowServiceCards,
          }
        : {}),
      ...(escrowBadgeDisplay
        ? {
            assistantInstructions: escrowBadgeAssistantInstructions,
            display: escrowBadgeDisplay,
            badgeCards: escrowBadgeCards,
          }
        : {}),
      ...(paymentDisplay
        ? {
            assistantInstructions: paymentAssistantInstructions,
            display: paymentDisplay,
            paymentDisplays,
          }
        : {}),
    },
    ...(listingCardDisplay ||
    reservationCardDisplay ||
    profileCardDisplay ||
    threadCardDisplay ||
    threadViewDisplay ||
    escrowTradeDisplay ||
    escrowServiceDisplay ||
    escrowBadgeDisplay ||
    paymentDisplay ||
    sessionConnectDisplay ||
    swapWatchAssistantInstructions ||
    notices.length > 0 ||
    responseWidgetMeta ||
    errorInstructions
      ? {
          _meta: {
            ...(responseWidgetMeta ?? {}),
            ...(listingCardDisplay
              ? {
                  "hostr.contentType": listingCardDisplay.type,
                  "hostr.display": listingCardDisplay,
                  "hostr.listingCards": listingCards,
                  "hostr.preferredRenderer": "listing-card",
                  "hostr.assistantInstructions":
                    listingCardAssistantInstructions,
                }
              : {}),
            ...(reservationCardDisplay
              ? {
                  "hostr.contentType": reservationCardDisplay.type,
                  "hostr.display": reservationCardDisplay,
                  "hostr.reservationCards": reservationCards,
                  ...(reservationCardDisplay.type.startsWith("hosting")
                    ? { "hostr.hostingCards": reservationCards }
                    : { "hostr.tripCards": reservationCards }),
                  "hostr.preferredRenderer":
                    reservationCardDisplay.type.startsWith("hosting")
                      ? "hosting-card"
                      : "trip-card",
                  "hostr.assistantInstructions":
                    reservationCardAssistantInstructions,
                }
              : {}),
            ...(profileCardDisplay
              ? {
                  "hostr.contentType": profileCardDisplay.type,
                  "hostr.display": profileCardDisplay,
                  "hostr.profileCards": profileCards,
                  "hostr.preferredRenderer": "profile-card",
                  "hostr.assistantInstructions": profileCardAssistantInstructions,
                }
              : {}),
            ...(paymentDisplay
              ? {
                  "hostr.contentType": paymentDisplay.type,
                  "hostr.display": paymentDisplay,
                  "hostr.paymentDisplays": paymentDisplays,
                  ...(requiredNextTool
                    ? {
                        "hostr.nextTool": requiredNextTool,
                        "hostr.requiredNextTool": requiredNextTool,
                        "hostr.nextAction":
                          "Immediately call hostr_swaps_watch with requiredNextTool.arguments after rendering the payment display.",
                      }
                    : {}),
                  "hostr.copyActions": paymentDisplays.flatMap(
                    (display) => display.actions,
                  ),
                  "hostr.preferredRenderer": "payment-external-required",
                  "hostr.assistantInstructions": paymentAssistantInstructions,
                }
              : {}),
            ...(threadCardDisplay
              ? {
                  "hostr.contentType": threadCardDisplay.type,
                  "hostr.display": threadCardDisplay,
                  "hostr.threadCards": threadCards,
                  "hostr.preferredRenderer": "thread-card",
                  "hostr.assistantInstructions": threadCardAssistantInstructions,
                }
              : {}),
            ...(threadViewDisplay
              ? {
                  "hostr.contentType": threadViewDisplay.type,
                  "hostr.display": threadViewDisplay,
                  "hostr.threadViews": threadViews,
                  "hostr.preferredRenderer": "thread-view",
                  "hostr.assistantInstructions": threadViewAssistantInstructions,
                }
              : {}),
            ...(escrowTradeDisplay
              ? {
                  "hostr.contentType": escrowTradeDisplay.type,
                  "hostr.display": escrowTradeDisplay,
                  "hostr.escrowTradeCards": escrowTradeCards,
                  "hostr.preferredRenderer": "escrow-trade-card",
                  "hostr.assistantInstructions":
                    escrowTradeAssistantInstructions,
                }
              : {}),
            ...(escrowServiceDisplay
              ? {
                  "hostr.contentType": escrowServiceDisplay.type,
                  "hostr.display": escrowServiceDisplay,
                  "hostr.escrowServiceCards": escrowServiceCards,
                  "hostr.preferredRenderer": "escrow-service-card",
                  "hostr.assistantInstructions":
                    escrowServiceAssistantInstructions,
                }
              : {}),
            ...(escrowBadgeDisplay
              ? {
                  "hostr.contentType": escrowBadgeDisplay.type,
                  "hostr.display": escrowBadgeDisplay,
                  "hostr.badgeCards": escrowBadgeCards,
                  "hostr.preferredRenderer": "escrow-badge-card",
                  "hostr.assistantInstructions":
                    escrowBadgeAssistantInstructions,
                }
              : {}),
            ...(sessionConnectDisplay
              ? {
                  "hostr.contentType": sessionConnectDisplay.type,
                  "hostr.display": sessionConnectDisplay,
                  "hostr.preferredRenderer": "nostr-connect",
                  "hostr.assistantInstructions":
                    sessionConnectAssistantInstructions,
                }
              : {}),
            ...(safeNotices.length > 0 && !paymentDisplay
              ? { "hostr.notices": safeNotices }
              : {}),
            ...(paymentAssistantInstructions ||
            swapWatchAssistantInstructions ||
            profileCardAssistantInstructions ||
            sessionConnectAssistantInstructions ||
            escrowServiceAssistantInstructions ||
            escrowTradeAssistantInstructions ||
            threadViewAssistantInstructions ||
            errorInstructions
              ? {
                  "hostr.assistantInstructions":
                    paymentAssistantInstructions ??
                    swapWatchAssistantInstructions ??
                    profileCardAssistantInstructions ??
                    sessionConnectAssistantInstructions ??
                    escrowServiceAssistantInstructions ??
                    escrowTradeAssistantInstructions ??
                    threadViewAssistantInstructions ??
                    errorInstructions,
                }
              : {}),
          },
        }
      : {}),
    content: [
      {
        type: "text" as const,
        text: contentText,
        annotations: {
          audience: ["user", "assistant"],
          priority: 1,
        },
        ...(listingCardDisplay ||
        reservationCardDisplay ||
        profileCardDisplay ||
        threadViewDisplay ||
        escrowTradeDisplay ||
        escrowServiceDisplay ||
        paymentDisplay ||
        sessionConnectDisplay
          ? {
              _meta: {
                "hostr.display":
                  listingCardDisplay ??
                  reservationCardDisplay ??
                  profileCardDisplay ??
                  threadViewDisplay ??
                  escrowTradeDisplay ??
                  escrowServiceDisplay ??
                  paymentDisplay ??
                  sessionConnectDisplay,
              },
            }
          : {}),
      },
      ...(sessionConnectImageBlock ? [sessionConnectImageBlock] : []),
      ...noticeImageBlocks,
    ],
  } satisfies CallToolResult;
};

const auditToolCall = ({
  actionId,
  pubkey,
  traceId,
  result,
}: {
  actionId: string;
  pubkey?: string;
  traceId: string;
  result: { ok: boolean; dryRun?: boolean; data?: unknown; errors?: unknown[] };
}) => {
  const data = record(result.data);
  const audit = {
    event: "tool_call",
    traceId,
    actionId,
    pubkey,
    ok: result.ok,
    dryRun: result.dryRun,
    listingAnchor: stringValue(data?.anchor) ?? stringValue(data?.listingAnchor),
    tradeId: stringValue(data?.tradeId),
    swapId: stringValue(data?.swapId),
    errorCodes: Array.isArray(result.errors)
      ? result.errors
          .map(record)
          .map((error) => stringValue(error?.code))
          .filter((code): code is string => Boolean(code))
      : undefined,
  };
  auditLog("mcp.tool.call", audit);
};

const signerNotificationMessage = (
  notification: HostrDaemonNotification,
): string | null => {
  if (notification.method !== "hostr.signer.pending") {
    return null;
  }
  const params = record(notification.params);
  return (
    stringValue(params?.message) ??
    "Waiting for signer approval: approve the request in your Nostr signer."
  );
};

const bookingNotificationMessage = (
  config: AppConfig,
  notification: HostrDaemonNotification,
): string | null => {
  if (notification.method !== "hostr.booking.state") {
    return null;
  }
  const params = record(notification.params);
  const state = stringValue(params?.state) ?? "unknown";
  const externalPayment = record(params?.externalPayment);
  const swapState = record(params?.swapState);
  const paymentState = record(swapState?.paymentState);
  const callbackDetails = record(paymentState?.callbackDetails);
  const invoice =
    stringValue(externalPayment?.invoice) ??
    stringValue(callbackDetails?.paymentRequest);
  const qrImage = stringValue(externalPayment?.qrImage);

  if (invoice) {
    return [
      `Hostr booking state: ${state}.`,
      paymentPromptMarkdown(config, {
        invoice,
        qrImage,
      }),
    ]
      .filter(Boolean)
      .join("\n");
  }

  if (state === "completed") {
    return "Hostr booking completed.";
  }

  if (state === "failed") {
    return `Hostr booking failed: ${stringValue(params?.error) ?? "unknown error"}`;
  }

  return `Hostr booking state: ${state}.`;
};

const criticalNoticeFromNotification = (
  notification: HostrDaemonNotification,
): HostrCriticalNotice | null => {
  if (notification.method === "hostr.signer.pending") {
    const params = record(notification.params);
    return {
      type: "signer-approval",
      message:
        stringValue(params?.message) ??
        "Waiting for signer approval: approve the request in your Nostr signer.",
      requestId: stringValue(params?.requestId) ?? undefined,
      signerMethod: stringValue(params?.signerMethod) ?? undefined,
      eventLabel: stringValue(params?.eventLabel) ?? undefined,
    };
  }
  if (notification.method === "hostr.booking.state") {
    const params = record(notification.params);
    return externalPaymentNoticeFromState(params);
  }
  return null;
};

const criticalNoticesFromToolResult = (
  result: Record<string, unknown>,
): HostrCriticalNotice[] => {
  const data = record(result.data);
  const directNotice = externalPaymentNoticeFromState(data);
  const stateNotice = externalPaymentNoticeFromState(record(data?.state));
  const states = arrayValue(data?.states).map(record).filter(isRecord);
  const notices = states
    .map((state) => externalPaymentNoticeFromState(state))
    .filter(isHostrCriticalNotice);
  if (directNotice) {
    notices.push(directNotice);
  }
  if (stateNotice) {
    notices.push(stateNotice);
  }
  return dedupeCriticalNotices(notices);
};

const externalPaymentNoticeFromState = (
  state: Record<string, unknown> | null,
): HostrCriticalNotice | null => {
  if (!state) {
    return null;
  }
  const externalPayment = record(state.externalPayment);
  const swapState = record(state.swapState);
  const paymentState =
    record(swapState?.paymentState) ?? record(state.paymentState);
  const paymentStateName = stringValue(paymentState?.state);
  const paymentParams = record(paymentState?.params);
  const callbackDetails = record(paymentState?.callbackDetails);
  if (!externalPayment && paymentStateName !== "externalRequired") {
    return null;
  }
  const invoice =
    stringValue(externalPayment?.invoice) ??
    stringValue(callbackDetails?.paymentRequest) ??
    stringValue(paymentParams?.to);
  if (!invoice) {
    return null;
  }
  return {
    type: "external-payment",
    message:
      stringValue(externalPayment?.message) ??
      "External Lightning payment required. Pay this invoice to continue the Hostr booking.",
    invoice,
    qrImage: stringValue(externalPayment?.qrImage) ?? undefined,
    tradeId:
      stringValue(externalPayment?.tradeId) ??
      stringValue(state.tradeId) ??
      undefined,
    swapId:
      stringValue(externalPayment?.swapId) ??
      stringValue(state.swapId) ??
      stringValue(swapState?.id) ??
      stringValue(state.id) ??
      undefined,
  };
};

const isHostrCriticalNotice = (
  notice: HostrCriticalNotice | null,
): notice is HostrCriticalNotice => notice !== null;

const dedupeCriticalNotices = (
  notices: HostrCriticalNotice[],
): HostrCriticalNotice[] => {
  const seen = new Set<string>();
  const deduped: HostrCriticalNotice[] = [];
  for (const notice of notices) {
    const key = criticalNoticeKey(notice);
    if (seen.has(key)) {
      continue;
    }
    seen.add(key);
    deduped.push(notice);
  }
  return deduped;
};

const criticalNoticeKey = (notice: HostrCriticalNotice): string =>
  notice.type === "external-payment"
    ? `${notice.type}:${notice.invoice}`
    : `${notice.type}:${notice.requestId ?? notice.message}`;

const hostrElicitationTimeoutMs = 10_000;
const hostrElicitationsInFlight = new Set<string>();
const hostrElicitationUnsupportedLogged = new Set<string>();

const bookAndPayTimeoutMs = (args: Record<string, unknown>): number => {
  const proofTimeoutSeconds = Number(args.proofTimeoutSeconds);
  const proofTimeoutMs =
    Number.isFinite(proofTimeoutSeconds) && proofTimeoutSeconds > 0
      ? proofTimeoutSeconds * 1000
      : 300_000;
  return Math.max(60 * 60 * 1000, proofTimeoutMs + 30 * 60 * 1000);
};

const sendHostrElicitation = async (
  server: McpServer,
  notice: HostrCriticalNotice,
) => {
  const key = criticalNoticeKey(notice);
  const capabilities = server.server.getClientCapabilities();
  if (!capabilities?.elicitation?.form) {
    if (!hostrElicitationUnsupportedLogged.has(key)) {
      hostrElicitationUnsupportedLogged.add(key);
      console.error(
        `[hostr-mcp] Skipping Hostr elicitation: client does not advertise form elicitation support (${key})`,
      );
    }
    return;
  }
  if (hostrElicitationsInFlight.has(key)) {
    console.error(
      `[hostr-mcp] Skipping duplicate Hostr elicitation already in flight: ${key}`,
    );
    return;
  }
  hostrElicitationsInFlight.add(key);
  try {
    if (notice.type === "signer-approval") {
      const params: ElicitRequestFormParams = {
        mode: "form",
        message: [
          "USER ACTION REQUIRED: approve this Hostr signer request now.",
          notice.message,
          notice.signerMethod ? `Signer method: ${notice.signerMethod}` : null,
          notice.eventLabel ? `Request: ${notice.eventLabel}` : null,
        ]
          .filter(Boolean)
          .join("\n\n"),
        requestedSchema: {
          type: "object",
          properties: {
            approved: {
              type: "boolean",
              title: "I approved it",
              description:
                "Acknowledge after approving the pending request in your Nostr signer.",
              default: false,
            },
          },
          required: ["approved"],
        },
      };
      console.error(
        `[hostr-mcp] Sending Hostr elicitation: ${key} ${JSON.stringify({
          mode: params.mode,
          requestedSchema: params.requestedSchema,
        })}`,
      );
      const result = await server.server.elicitInput(params, {
        timeout: hostrElicitationTimeoutMs,
      });
      console.error(
        `[hostr-mcp] Hostr elicitation completed: ${key} action=${result.action}`,
      );
      return;
    }

    const params: ElicitRequestFormParams = {
      mode: "form",
      message: [
        "USER ACTION REQUIRED: pay the Lightning invoice shown in the Hostr payment display.",
        notice.message,
        "Use the QR, wallet link, copy affordance, or exact invoice text link from the payment display.",
        "Keep this Hostr request running while Hostr watches for payment, swap settlement, and the committed reservation.",
      ]
        .filter(Boolean)
        .join("\n\n"),
      requestedSchema: {
        type: "object",
        properties: {
          paid: {
            type: "boolean",
            title: "I have paid the invoice",
            description:
              "Confirm after paying the Lightning invoice. Hostr still verifies the payment and reservation automatically.",
            default: false,
          },
        },
        required: ["paid"],
      },
    };
    console.error(
      `[hostr-mcp] Sending Hostr elicitation: ${key} ${JSON.stringify({
        mode: params.mode,
        requestedSchema: params.requestedSchema,
      })}`,
    );
    const result = await server.server.elicitInput(params, {
      timeout: hostrElicitationTimeoutMs,
    });
    console.error(
      `[hostr-mcp] Hostr elicitation completed: ${key} action=${result.action}`,
    );
  } catch (error) {
    const code =
      error && typeof error === "object" && "code" in error
        ? String((error as { code?: unknown }).code)
        : undefined;
    const message = error instanceof Error ? error.message : String(error);
    console.error(
      `[hostr-mcp] Hostr elicitation failed: ${key}${code ? ` code=${code}` : ""} message=${message}`,
    );
  } finally {
    hostrElicitationsInFlight.delete(key);
  }
};

const sendHostrProgress = async (
  config: AppConfig,
  extra: RequestHandlerExtra<ServerRequest, ServerNotification>,
  notification: HostrDaemonNotification,
) => {
  const message =
    signerNotificationMessage(notification) ??
    bookingNotificationMessage(config, notification);
  if (!message) {
    return;
  }
  const progressToken = extra._meta?.progressToken;
  if (progressToken !== undefined) {
    await extra.sendNotification({
      method: "notifications/progress",
      params: {
        progressToken,
        progress: 0,
        total: 1,
        message,
      },
    });
  }

  await extra.sendNotification({
    method: "notifications/message",
    params: {
      level: "info",
      logger: notification.method,
      data: message,
    },
  });
};

const publicActionIds = new Set<string>([
  "hostr.listings.search",
  "hostr.profile.lookup",
]);

const sessionManagedActionIds = new Set<string>([
  "hostr.session.status",
  "hostr.session.connect",
]);

const activePubkeyForClaims = (
  sessionStore: McpSessionStore,
  claims: AccessTokenClaims | null,
): string | undefined =>
  claims ? sessionStore.get(claims.sessionId).activePubkey : undefined;

const refreshSessionToolVisibility = (
  customToolHandles: Map<string, RegisteredTool>,
  sessionStore: McpSessionStore,
  claims: AccessTokenClaims | null,
) => {
  const accountCount = claims
    ? sessionStore.get(claims.sessionId).accounts.length
    : 0;
  const visibility = new Map<string, boolean>([
    ["hostr_session_accounts", Boolean(claims)],
    ["hostr_session_switch", Boolean(claims) && accountCount > 0],
    ["hostr_session_logout", Boolean(claims) && accountCount > 0],
  ]);

  for (const [toolName, shouldEnable] of visibility) {
    const handle = customToolHandles.get(toolName);
    if (!handle) {
      continue;
    }
    if (shouldEnable && !handle.enabled) {
      handle.enable();
    } else if (!shouldEnable && handle.enabled) {
      handle.disable();
    }
  }
};

const refreshToolVisibility = async (
  server: McpServer,
  toolHandles: Map<string, RegisteredTool>,
  customToolHandles: Map<string, RegisteredTool>,
  visibleActionIds: Set<string>,
  sessionStore: McpSessionStore,
  claims: AccessTokenClaims | null,
) => {
  for (const action of hostrActionCatalog) {
    const handle = toolHandles.get(action.toolName);
    if (!handle) {
      continue;
    }
    const shouldEnable = visibleActionIds.has(action.id);
    if (shouldEnable && !handle.enabled) {
      handle.enable();
    } else if (!shouldEnable && handle.enabled) {
      handle.disable();
    }
  }
  refreshSessionToolVisibility(customToolHandles, sessionStore, claims);
  server.sendToolListChanged();
};

const toolListChangedResult = { toolsChanged: true };

const sessionAccountMetadataFromResult = (
  result: Record<string, unknown>,
): Record<string, unknown> | undefined => {
  const data = record(result.data);
  const metadata = record(data?.metadata);
  if (!metadata) {
    return undefined;
  }
  return {
    ...metadata,
    pubkey: stringValue(data?.pubkey) ?? undefined,
    npub: stringValue(data?.npub) ?? undefined,
  };
};

const sessionAccountSummary = async (
  daemon: HostrDaemonClient,
  pubkey: string,
  activePubkey: string | undefined,
  traceId: string,
  storedMetadata?: Record<string, unknown>,
): Promise<Record<string, unknown>> => {
  const [profileResult, statusResult] = await Promise.allSettled([
    daemon.callAction({
      pubkey,
      action: "hostr.profile.show",
      input: {},
      traceId,
    }),
    daemon.callAction({
      pubkey,
      action: "hostr.session.status",
      input: {},
      traceId,
    }),
  ]);
  const profile =
    profileResult.status === "fulfilled" && profileResult.value.ok
      ? sessionAccountMetadataFromResult(profileResult.value as Record<string, unknown>)
      : storedMetadata;
  const statusOk =
    statusResult.status === "fulfilled" && statusResult.value.ok;
  const statusData =
    statusOk
      ? record((statusResult.value as Record<string, unknown>).data)
      : null;
  const authenticated = boolValue(statusData?.authenticated) ?? false;
  const signerOnline = boolValue(statusData?.signerOnline) ?? false;
  const needsReconnect = statusOk ? Boolean(statusData?.reconnect) : true;
  return {
    pubkey,
    active: pubkey === activePubkey,
    metadata: profile,
    signerStatus: {
      authenticated,
      signerOnline,
      needsReconnect,
      status: statusOk
        ? needsReconnect
          ? "needs_reconnect"
          : signerOnline
            ? "online"
            : "offline"
        : "unknown",
    },
  };
};

const sessionAccountsPayload = async (
  sessionStore: McpSessionStore,
  daemon: HostrDaemonClient,
  claims: AccessTokenClaims,
  traceId: string,
): Promise<Record<string, unknown>> => {
  const session = sessionStore.get(claims.sessionId);
  const accounts = await Promise.all(
    session.accounts.map((account) =>
      sessionAccountSummary(
        daemon,
        account.pubkey,
        session.activePubkey,
        traceId,
        account.metadata,
      ),
    ),
  );
  for (const account of accounts) {
    sessionStore.updateAccountMetadata(
      claims.sessionId,
      stringValue(account.pubkey)!,
      record(account.metadata) ?? undefined,
    );
  }
  return {
    sessionId: claims.sessionId,
    activePubkey: sessionStore.get(claims.sessionId).activePubkey,
    accounts,
  };
};

const sessionStatusPayload = async (
  sessionStore: McpSessionStore,
  daemon: HostrDaemonClient,
  claims: AccessTokenClaims,
  args: Record<string, unknown>,
  traceId: string,
): Promise<Record<string, unknown>> => {
  const session = sessionStore.get(claims.sessionId);
  const activeAccount = session.accounts.find(
    (account) => account.pubkey === session.activePubkey,
  );
  const summary = activeAccount
    ? await sessionAccountSummary(
        daemon,
        activeAccount.pubkey,
        session.activePubkey,
        traceId,
        activeAccount.metadata,
      )
    : undefined;
  const signerStatus = record(summary?.signerStatus);
  return {
    sessionId: claims.sessionId,
    activePubkey: session.activePubkey,
    accountCount: session.accounts.length,
    authenticated: boolValue(signerStatus?.authenticated) ?? false,
    signerOnline: boolValue(signerStatus?.signerOnline) ?? false,
    needsReconnect: boolValue(signerStatus?.needsReconnect) ?? false,
    activeAccount: summary,
    ...(boolValue(args.includeStorageDetails) === true
      ? {
          storage: {
            scope: `mcp-session/${claims.sessionId}`,
            accountPubkeys: session.accounts.map((account) => account.pubkey),
          },
        }
      : {}),
  };
};

const sessionToolResponse = (
  payload: Record<string, unknown>,
  message: string,
): CallToolResult => ({
  structuredContent: payload,
  content: [
    {
      type: "text" as const,
      text: message,
    },
  ],
});

const mcpTransports = new Map<string, StreamableHTTPServerTransport>();
const mcpSessionTraceIds = new Map<string, string>();

const imageUploadToolDocumentation = [
  "## `hostr_images_upload`",
  "",
  "Upload an original user-provided image file to Hostr Blossom and return a generic durable public image URL.",
  "",
  "Use this before any Hostr tool that needs an image URL. The required `file` argument is marked with `x-hostr-argument-kind: file`; put the client-provided uploaded file/blob/reference here so the MCP client bridge can rewrite or stream the original bytes. Reachable local filesystem paths and file:// URLs are accepted here and will be read, then re-uploaded to Blossom. Never put `/mnt/data`, `/mnt/shared`, `file://`, ChatGPT file mount paths, local filesystem paths, or base64 text directly in listing/profile image URL fields. Do not resize, downscale, crop, recompress, transcode, or create thumbnails unless the user explicitly asks.",
  "",
  "When an authenticated Hostr session is available, the tool first tries that session's Blossom upload path. If it cannot use session auth, it falls back to the server's direct Blossom upload endpoint. After it succeeds, use the generic `structuredContent.usage.image.url`: pass it as `images[].url` for listing creation or as `image`/`picture` for profile edits.",
  "",
  "JSON schema:",
  "",
  "```json",
  JSON.stringify(
    {
      type: "object",
      additionalProperties: false,
      required: ["file"],
      properties: {
        file: {
          contentMediaType: "image/*",
          "x-hostr-argument-kind": "file",
          description:
            "Required uploaded image file. Send the original image as the file-typed MCP argument so the client bridge can rewrite or stream bytes.",
        },
        filename: {
          type: "string",
          description:
            "Optional original filename metadata. Do not put a local path here.",
        },
        mime: {
          type: "string",
          description: "Optional MIME type, for example image/jpeg.",
        },
      },
    },
    null,
    2,
  ),
  "```",
].join("\n");

const originForUrl = (value: string | undefined): string | null => {
  if (!value) {
    return null;
  }
  try {
    return new URL(value).origin;
  } catch {
    return null;
  }
};

const listingCardWidgetResourceDomains = (config: AppConfig): string[] =>
  Array.from(
    new Set(
      [
        originForUrl(config.blossomUploadUrl),
        originForUrl(config.publicAppBaseUrl),
        originForUrl(config.publicAssetBaseUrl),
      ].filter((origin): origin is string => Boolean(origin)),
    ),
  );

const qrWidgetResourceDomains = (config: AppConfig): string[] =>
  Array.from(
    new Set(
      [
        originForUrl(config.publicAssetBaseUrl),
        originForUrl(config.qrImageUrlTemplate),
      ].filter((origin): origin is string => Boolean(origin)),
    ),
  );

const profileCardWidgetResourceDomains = (config: AppConfig): string[] =>
  Array.from(
    new Set(
      [
        originForUrl(config.blossomUploadUrl),
        originForUrl(config.publicAssetBaseUrl),
        originForUrl(config.publicAppBaseUrl),
      ].filter((origin): origin is string => Boolean(origin)),
    ),
  );

const sharedWidgetCss = `
      :root {
        color-scheme: light dark;
        font-family: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        --hostr-surface: color-mix(in srgb, Canvas 96%, CanvasText 4%);
        --hostr-surface-strong: color-mix(in srgb, Canvas 90%, CanvasText 10%);
        --hostr-border: color-mix(in srgb, CanvasText 16%, transparent);
        --hostr-border-strong: color-mix(in srgb, CanvasText 22%, transparent);
        --hostr-muted: color-mix(in srgb, CanvasText 72%, transparent);
        --hostr-chip: color-mix(in srgb, CanvasText 8%, transparent);
        --hostr-radius: 8px;
        --hostr-gap: 10px;
      }

      * {
        box-sizing: border-box;
      }

      html,
      body {
        margin: 0;
        color: CanvasText;
        background: Canvas;
      }

      .hostr-root {
        display: grid;
        gap: var(--hostr-gap);
        padding: 2px;
      }

      .hostr-card {
        border: 1px solid var(--hostr-border);
        border-radius: var(--hostr-radius);
        background: var(--hostr-surface);
      }

      .hostr-title {
        margin: 0;
        overflow-wrap: anywhere;
        font-size: 16px;
        line-height: 1.25;
        font-weight: 700;
        letter-spacing: 0;
      }

      .hostr-subtitle,
      .hostr-text {
        margin: 0;
        color: var(--hostr-muted);
        overflow-wrap: anywhere;
        font-size: 13px;
        line-height: 1.35;
        letter-spacing: 0;
      }

      .hostr-pill {
        max-width: 100%;
        overflow-wrap: anywhere;
        padding: 3px 7px;
        border-radius: 999px;
        color: color-mix(in srgb, CanvasText 88%, transparent);
        background: var(--hostr-chip);
        font-size: 12px;
        line-height: 1.3;
        letter-spacing: 0;
      }

      .hostr-status {
        flex: none;
        padding: 2px 6px;
        border-radius: 999px;
        color: color-mix(in srgb, CanvasText 78%, transparent);
        background: var(--hostr-chip);
        font-size: 11px;
        line-height: 1.35;
        letter-spacing: 0;
      }

      .hostr-button,
      .hostr-link {
        display: inline-flex;
        width: fit-content;
        align-items: center;
        justify-content: center;
        gap: 6px;
        min-height: 32px;
        padding: 0 10px;
        border: 1px solid var(--hostr-border);
        border-radius: 6px;
        color: CanvasText;
        background: var(--hostr-surface-strong);
        font: 650 13px/1 Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
        letter-spacing: 0;
        text-decoration: none;
        cursor: pointer;
      }

      .hostr-link {
        color: LinkText;
        background: transparent;
      }

      .hostr-button:hover,
      .hostr-link:hover {
        border-color: var(--hostr-border-strong);
        text-decoration: none;
      }

      .hostr-button:active {
        transform: translateY(1px);
      }

      .hostr-empty {
        padding: 10px;
        color: var(--hostr-muted);
        font-size: 13px;
        line-height: 1.35;
      }
`;

const listingCardWidgetHtml = `
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
${sharedWidgetCss}

      .card {
        display: grid;
        grid-template-columns: minmax(132px, 34%) minmax(0, 1fr);
        gap: 12px;
        min-width: 0;
        padding: 10px;
      }

      .media {
        display: grid;
        grid-auto-flow: column;
        grid-auto-columns: 100%;
        gap: 6px;
        overflow-x: auto;
        overscroll-behavior-inline: contain;
        aspect-ratio: 4 / 3;
        border-radius: 7px;
        background: var(--hostr-chip);
        scroll-snap-type: x mandatory;
      }

      .media img {
        width: 100%;
        height: 100%;
        object-fit: cover;
        scroll-snap-align: start;
      }

      .body {
        display: grid;
        align-content: start;
        gap: 6px;
        min-width: 0;
      }

      .topline {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 8px;
        min-width: 0;
      }

      .meta {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
      }

      @media (max-width: 520px) {
        .card {
          grid-template-columns: 1fr;
        }
      }
    </style>
  </head>
  <body>
    <main id="root" class="hostr-root"></main>
    <script>
      (function () {
        var root = document.getElementById("root");

        function text(value, fallback) {
          return typeof value === "string" && value.trim() ? value : fallback;
        }

        function toolData(output) {
          if (!output || typeof output !== "object") return output;
          if (output.structuredContent && typeof output.structuredContent === "object") {
            return output.structuredContent;
          }
          return output;
        }

        function cardsFrom(output) {
          if (!output || typeof output !== "object") return [];
          if (Array.isArray(output.listingCards)) return output.listingCards;
          if (
            output.display &&
            typeof output.display === "object" &&
            Array.isArray(output.display.cards)
          ) {
            return output.display.cards;
          }
          return [];
        }

        function safeUrl(value) {
          if (typeof value !== "string") return null;
          try {
            var url = new URL(value);
            return url.protocol === "http:" || url.protocol === "https:" ? url.href : null;
          } catch (_error) {
            return null;
          }
        }

        function appendText(parent, tag, className, value) {
          if (!value) return null;
          var el = document.createElement(tag);
          el.className = className;
          el.textContent = value;
          parent.appendChild(el);
          return el;
        }

        function renderImages(card, parent) {
          var images = Array.isArray(card.images) ? card.images : [];
          var media = document.createElement("div");
          media.className = "media";

          images.slice(0, 5).forEach(function (image, index) {
            var url = safeUrl(image && image.url);
            if (!url) return;
            var img = document.createElement("img");
            img.src = url;
            img.alt = text(image.alt, text(card.title, "Listing image"));
            img.loading = index === 0 ? "eager" : "lazy";
            media.appendChild(img);
          });

          if (media.childNodes.length === 0) {
            media.setAttribute("aria-label", "No listing image");
          }

          parent.appendChild(media);
        }

        function renderCard(card) {
          var article = document.createElement("article");
          article.className = "card hostr-card";
          renderImages(card, article);

          var body = document.createElement("div");
          body.className = "body";

          var top = document.createElement("div");
          top.className = "topline";
          appendText(top, "h2", "hostr-title", text(card.title, "Untitled listing"));
          var status = text(card.statusLabel, "");
          if (status && status !== "active") appendText(top, "span", "status hostr-status", status);
          body.appendChild(top);

          appendText(body, "p", "description hostr-subtitle", text(card.description, ""));

          var meta = document.createElement("div");
          meta.className = "meta";
          appendText(meta, "span", "pill hostr-pill", text(card.price, ""));
          appendText(meta, "span", "pill hostr-pill", text(card.typeLabel, ""));
          if (Array.isArray(card.flags)) {
            card.flags.slice(0, 4).forEach(function (flag) {
              appendText(meta, "span", "pill hostr-pill", text(flag, ""));
            });
          }
          if (meta.childNodes.length > 0) body.appendChild(meta);

          var url = safeUrl(card.url);
          if (url) {
            var link = document.createElement("a");
            link.href = url;
            link.target = "_blank";
            link.rel = "noreferrer";
            link.className = "hostr-link";
            link.textContent = "Open listing";
            body.appendChild(link);
          }

          article.appendChild(body);
          return article;
        }

        function render(output) {
          if (output === undefined || output === null) {
            root.replaceChildren();
            return;
          }
          var cards = cardsFrom(toolData(output)).filter(Boolean);
          root.replaceChildren();
          if (cards.length === 0) {
            appendText(root, "div", "empty hostr-empty", "No listings found.");
            return;
          }
          cards.forEach(function (card) {
            root.appendChild(renderCard(card));
          });
        }

        function currentToolOutput() {
          return window.openai && window.openai.toolOutput;
        }

        render(currentToolOutput());

        var remainingChecks = 40;
        var pollId = window.setInterval(function () {
          var output = currentToolOutput();
          if (output === undefined || output === null) {
            remainingChecks -= 1;
            if (remainingChecks <= 0) window.clearInterval(pollId);
            return;
          }
          window.clearInterval(pollId);
          render(output);
        }, 250);

        window.addEventListener(
          "openai:set_globals",
          function (event) {
            var globals = event.detail && event.detail.globals;
            var output = (globals && globals.toolOutput) || currentToolOutput();
            if (output !== undefined && output !== null) {
              window.clearInterval(pollId);
              render(output);
            }
          },
          { passive: true },
        );
      })();
    </script>
  </body>
</html>
`.trim();

const paymentRequiredWidgetHtml = `
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
${sharedWidgetCss}

      .wrap {
        display: grid;
        gap: 10px;
        width: fit-content;
        max-width: min(320px, 100%);
        padding: 10px;
      }

      img {
        display: block;
        width: min(260px, 100%);
        aspect-ratio: 1;
        object-fit: contain;
        border-radius: 6px;
        background: white;
      }

      .copy-row {
        display: grid;
        grid-template-columns: minmax(0, 1fr) auto;
        gap: 8px;
        align-items: center;
      }

      .invoice {
        min-width: 0;
        height: 32px;
        padding: 0 9px;
        border: 1px solid var(--hostr-border);
        border-radius: 6px;
        color: CanvasText;
        background: var(--hostr-surface);
        font: 12px/1 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
        letter-spacing: 0;
        overflow: hidden;
        text-overflow: ellipsis;
      }

      .copy {
        height: 32px;
      }

      [hidden] {
        display: none !important;
      }
    </style>
  </head>
  <body hidden>
    <main id="root" class="hostr-root"></main>
    <script>
      (function () {
        var root = document.getElementById("root");

        function toolData(output) {
          if (!output || typeof output !== "object") return output;
          if (output.structuredContent && typeof output.structuredContent === "object") {
            return output.structuredContent;
          }
          return output;
        }

        function firstPaymentCard(value) {
          if (!Array.isArray(value)) return null;
          for (var i = 0; i < value.length; i += 1) {
            var card = value[i];
            if (card && typeof card === "object" && card.qrImageUrl) {
              return card;
            }
          }
          return value[0] || null;
        }

        function paymentDisplayCard(display) {
          if (!display || typeof display !== "object") return null;
          if (display.type !== "payment-external-required") return null;
          if (Array.isArray(display.cards)) return firstPaymentCard(display.cards);
          return display.qrImageUrl ? display : null;
        }

        function metaValue(output, key) {
          if (!output || typeof output !== "object") return undefined;
          if (output[key] !== undefined) return output[key];
          var meta = output._meta || output.meta;
          if (meta && typeof meta === "object" && meta[key] !== undefined) {
            return meta[key];
          }
          var sdk = output.chatgpt_sdk;
          if (sdk && typeof sdk === "object") {
            var responseMeta =
              sdk.tool_response_metadata ||
              sdk.toolResponseMetadata ||
              sdk.responseMetadata;
            if (
              responseMeta &&
              typeof responseMeta === "object" &&
              responseMeta[key] !== undefined
            ) {
              return responseMeta[key];
            }
          }
          var metadata = output.metadata;
          if (metadata && typeof metadata === "object") {
            return metaValue(metadata, key);
          }
          return undefined;
        }

        function paymentFrom(output) {
          if (!output || typeof output !== "object") return null;
          if (Array.isArray(output)) {
            for (var i = 0; i < output.length; i += 1) {
              var fromItem = paymentFrom(output[i]);
              if (fromItem) return fromItem;
            }
            return null;
          }

          var fromDisplays = firstPaymentCard(output.paymentDisplays);
          if (fromDisplays) return fromDisplays;

          var fromDisplay = paymentDisplayCard(output.display);
          if (fromDisplay) return fromDisplay;

          var fromMetaDisplays = firstPaymentCard(metaValue(output, "hostr.paymentDisplays"));
          if (fromMetaDisplays) return fromMetaDisplays;

          var fromMetaDisplay = paymentDisplayCard(metaValue(output, "hostr.display"));
          if (fromMetaDisplay) return fromMetaDisplay;

          var fromStructured = output.structuredContent
            ? paymentFrom(output.structuredContent)
            : null;
          if (fromStructured) return fromStructured;

          if (output.toolOutput !== undefined) return paymentFrom(output.toolOutput);
          if (output.tool_output !== undefined) return paymentFrom(output.tool_output);
          if (output.toolResponseMetadata !== undefined) {
            return paymentFrom(output.toolResponseMetadata);
          }
          if (output.tool_response_metadata !== undefined) {
            return paymentFrom(output.tool_response_metadata);
          }
          if (output.responseMetadata !== undefined) {
            return paymentFrom(output.responseMetadata);
          }
          if (output.response_metadata !== undefined) {
            return paymentFrom(output.response_metadata);
          }
          if (output.metadata !== undefined) return paymentFrom(output.metadata);
          if (output.output !== undefined) return paymentFrom(output.output);
          if (output.result !== undefined) return paymentFrom(output.result);
          if (output.payload !== undefined) return paymentFrom(output.payload);
          if (output.data !== undefined) return paymentFrom(output.data);
          return null;
        }

        function invoiceFromPayment(payment) {
          if (!payment || typeof payment !== "object") return null;
          if (typeof payment.invoice === "string") return payment.invoice;
          if (payment.copy && typeof payment.copy.text === "string") {
            return payment.copy.text;
          }
          if (Array.isArray(payment.actions)) {
            for (var i = 0; i < payment.actions.length; i += 1) {
              var action = payment.actions[i];
              if (action && typeof action.text === "string") return action.text;
            }
          }
          if (typeof payment.lightningUrl === "string") {
            return payment.lightningUrl.replace(/^lightning:/i, "");
          }
          return null;
        }

        function invoiceFromQrUrl(value) {
          if (typeof value !== "string") return null;
          try {
            var url = new URL(value);
            var data = url.searchParams.get("data");
            return data && /^lnbc/i.test(data) ? data : null;
          } catch (_error) {
            return null;
          }
        }

        function invoiceFromText(value) {
          if (typeof value !== "string") return null;
          var match = /(lnbc[0-9a-z]+)/i.exec(value);
          return match ? match[1] : null;
        }

        function invoiceFromOutput(output) {
          if (output === undefined || output === null) return null;
          if (typeof output === "string") return invoiceFromText(output);
          if (Array.isArray(output)) {
            for (var i = 0; i < output.length; i += 1) {
              var fromItem = invoiceFromOutput(output[i]);
              if (fromItem) return fromItem;
            }
            return null;
          }
          if (typeof output !== "object") return null;

          var payment = paymentFrom(output);
          var fromPayment = invoiceFromPayment(payment);
          if (fromPayment) return fromPayment;

          if (Array.isArray(output.parts)) {
            for (var j = 0; j < output.parts.length; j += 1) {
              var fromPart = invoiceFromOutput(output.parts[j]);
              if (fromPart) return fromPart;
            }
          }

          return (
            invoiceFromText(output.text) ||
            invoiceFromText(output.markdown) ||
            invoiceFromOutput(output.structuredContent) ||
            invoiceFromOutput(output.toolOutput) ||
            invoiceFromOutput(output.toolResponseMetadata) ||
            invoiceFromOutput(output.tool_response_metadata) ||
            invoiceFromOutput(output.responseMetadata) ||
            invoiceFromOutput(output.response_metadata) ||
            invoiceFromOutput(output.metadata) ||
            invoiceFromOutput(output.output) ||
            invoiceFromOutput(output.result) ||
            invoiceFromOutput(output.payload) ||
            invoiceFromOutput(output.data)
          );
        }

        function redactForLog(value, depth) {
          if (depth > 3) return "[depth]";
          if (value === undefined) return "[undefined]";
          if (value === null || typeof value === "number" || typeof value === "boolean") {
            return value;
          }
          if (typeof value === "string") {
            if (/^lnbc/i.test(value)) return value.slice(0, 16) + "...(" + value.length + " chars)";
            if (value.length > 180) return value.slice(0, 180) + "...(" + value.length + " chars)";
            return value;
          }
          if (Array.isArray(value)) {
            return value.slice(0, 8).map(function (item) {
              return redactForLog(item, depth + 1);
            });
          }
          if (typeof value !== "object") return String(value);
          var result = {};
          var keys = Object.keys(value).slice(0, 24);
          for (var i = 0; i < keys.length; i += 1) {
            var key = keys[i];
            result[key] = redactForLog(value[key], depth + 1);
          }
          if (Object.keys(value).length > keys.length) {
            result.__moreKeys = Object.keys(value).length - keys.length;
          }
          return result;
        }

        function debugLog(label, value) {
          try {
            if (!window.__HOSTR_PAYMENT_WIDGET_DEBUG) {
              return;
            }
            window.__hostrPaymentWidgetDebugCounts =
              window.__hostrPaymentWidgetDebugCounts || {};
            var counts = window.__hostrPaymentWidgetDebugCounts;
            counts[label] = (counts[label] || 0) + 1;
            if (
              counts[label] > 8 &&
              label !== "render: QR displayed" &&
              label !== "openai:set_globals" &&
              label !== "message event"
            ) {
              return;
            }
            console.debug("[Hostr payment widget] " + label, redactForLog(value, 0));
          } catch (_error) {}
        }

        function safeImageUrl(value) {
          if (typeof value !== "string") return null;
          if (/^data:image\\/(png|jpeg|jpg|webp|gif);base64,/i.test(value)) {
            return value;
          }
          try {
            var url = new URL(value);
            return url.protocol === "http:" || url.protocol === "https:" ? url.href : null;
          } catch (_error) {
            return null;
          }
        }

        function qrFromText(value) {
          if (typeof value !== "string") return null;
          var markdownMatch = /!\\[[^\\]]*Lightning invoice QR[^\\]]*\\]\\(([^)]+)\\)/i.exec(value);
          if (markdownMatch) return safeImageUrl(markdownMatch[1]);
          var fieldMatch = /"qrImageUrl"\\s*:\\s*"([^"]+)"/.exec(value);
          if (fieldMatch) {
            try {
              return safeImageUrl(JSON.parse('"' + fieldMatch[1] + '"'));
            } catch (_error) {
              return safeImageUrl(fieldMatch[1]);
            }
          }
          return null;
        }

        function qrFromPart(part) {
          if (typeof part === "string") return qrFromText(part);
          if (!part || typeof part !== "object") return null;
          if (part.content_type === "image" && part.encoding === "base64" && part.payload) {
            var format = typeof part.format === "string" ? part.format : "png";
            return safeImageUrl("data:image/" + format + ";base64," + part.payload);
          }
          return (
            qrFromText(part.text) ||
            qrFromText(part.content) ||
            qrFromText(part.payload) ||
            qrFromOutput(part.structuredContent) ||
            qrFromOutput(part.data)
          );
        }

        function qrFromOutput(output) {
          if (output === undefined || output === null) return null;
          if (typeof output === "string") return qrFromText(output);
          if (Array.isArray(output)) {
            for (var i = 0; i < output.length; i += 1) {
              var fromItem = qrFromOutput(output[i]);
              if (fromItem) return fromItem;
            }
            return null;
          }
          if (typeof output !== "object") return null;

          var payment = paymentFrom(output);
          var fromPayment = safeImageUrl(payment && payment.qrImageUrl);
          if (fromPayment) return fromPayment;

          if (Array.isArray(output.parts)) {
            for (var j = 0; j < output.parts.length; j += 1) {
              var fromPart = qrFromPart(output.parts[j]);
              if (fromPart) return fromPart;
            }
          }

          if (Array.isArray(output.content)) {
            var fromContent = qrFromOutput(output.content);
            if (fromContent) return fromContent;
          }

          return (
            qrFromText(output.text) ||
            qrFromText(output.markdown) ||
            qrFromOutput(output.structuredContent) ||
            qrFromOutput(output.toolOutput) ||
            qrFromOutput(output.tool_output) ||
            qrFromOutput(output.toolResponseMetadata) ||
            qrFromOutput(output.tool_response_metadata) ||
            qrFromOutput(output.responseMetadata) ||
            qrFromOutput(output.response_metadata) ||
            qrFromOutput(output.metadata) ||
            qrFromOutput(output.output) ||
            qrFromOutput(output.result) ||
            qrFromOutput(output.payload) ||
            qrFromOutput(output.data)
          );
        }

        function extractToolOutput(value) {
          if (value === undefined || value === null) return value;
          if (typeof value !== "object") return value;
          if (value.structuredContent !== undefined) return value.structuredContent;
          if (value.toolOutput !== undefined) return extractToolOutput(value.toolOutput);
          if (value.tool_output !== undefined) return extractToolOutput(value.tool_output);
          if (value.output !== undefined) return extractToolOutput(value.output);
          if (value.result !== undefined) return extractToolOutput(value.result);
          return value;
        }

        function copyText(value, button) {
          if (!value) return;
          function markCopied() {
            if (!button) return;
            var original = button.textContent;
            button.textContent = "Copied";
            window.setTimeout(function () {
              button.textContent = original || "Copy";
            }, 1200);
          }
          if (navigator.clipboard && navigator.clipboard.writeText) {
            navigator.clipboard.writeText(value).then(markCopied, function () {});
            return;
          }
          var textarea = document.createElement("textarea");
          textarea.value = value;
          textarea.setAttribute("readonly", "readonly");
          textarea.style.position = "fixed";
          textarea.style.opacity = "0";
          document.body.appendChild(textarea);
          textarea.select();
          try {
            document.execCommand("copy");
            markCopied();
          } catch (_error) {}
          textarea.remove();
        }

        function render(output) {
          var extracted = extractToolOutput(output);
          var payment =
            paymentFrom(output) ||
            paymentFrom(extracted) ||
            paymentFrom(toolData(extracted));
          var qrUrl =
            safeImageUrl(payment && payment.qrImageUrl) ||
            qrFromOutput(output) ||
            qrFromOutput(extracted);
          var invoice =
            invoiceFromPayment(payment) ||
            invoiceFromOutput(output) ||
            invoiceFromOutput(extracted) ||
            invoiceFromQrUrl(qrUrl);
          root.replaceChildren();

          if (!qrUrl) {
            debugLog("render: no QR found", output);
            document.documentElement.hidden = true;
            document.body.hidden = true;
            return false;
          }

          var wrap = document.createElement("section");
          wrap.className = "wrap hostr-card";
          var prompt = document.createElement("p");
          prompt.className = "prompt hostr-title";
          prompt.textContent = "Pay this lightning invoice to continue";
          wrap.appendChild(prompt);
          var image = document.createElement("img");
          image.src = qrUrl;
          image.alt = "Lightning invoice QR";
          image.loading = "eager";
          wrap.appendChild(image);
          if (invoice) {
            var row = document.createElement("div");
            row.className = "copy-row";
            var invoiceInput = document.createElement("input");
            invoiceInput.className = "invoice";
            invoiceInput.type = "text";
            invoiceInput.readOnly = true;
            invoiceInput.value = invoice;
            invoiceInput.setAttribute("aria-label", "Lightning invoice");
            var button = document.createElement("button");
            button.className = "copy hostr-button";
            button.type = "button";
            button.textContent = "Copy";
            button.addEventListener("click", function () {
              copyText(invoice, button);
            });
            row.appendChild(invoiceInput);
            row.appendChild(button);
            wrap.appendChild(row);
          }
          root.appendChild(wrap);
          document.documentElement.hidden = false;
          document.body.hidden = false;
          debugLog("render: QR displayed", { qrUrl: qrUrl, payment: payment });
          return true;
        }

        function appendCandidate(list, value) {
          if (value === undefined || value === null) return;
          if (Array.isArray(value)) {
            for (var i = 0; i < value.length; i += 1) appendCandidate(list, value[i]);
            return;
          }
          list.push(value);
        }

        function candidatesFromOpenAI(openai) {
          var list = [];
          if (!openai || typeof openai !== "object") return list;
          var keys = [];
          try {
            keys = Object.keys(openai);
          } catch (_error) {}
          var wanted = [
            "toolOutput",
            "tool_output",
            "toolResponseMetadata",
            "tool_response_metadata",
            "responseMetadata",
            "response_metadata",
            "metadata",
            "result",
            "output",
            "payload",
          ];
          for (var i = 0; i < wanted.length; i += 1) {
            var key = wanted[i];
            if (keys.indexOf(key) === -1) continue;
            try {
              appendCandidate(list, openai[key]);
            } catch (_error) {}
          }
          appendCandidate(list, openai);
          return list;
        }

        function candidatesFromMessage(data) {
          var list = [];
          if (!data || typeof data !== "object") return list;
          appendCandidate(list, data.toolOutput);
          appendCandidate(list, data.tool_output);
          appendCandidate(list, data.toolResponseMetadata);
          appendCandidate(list, data.tool_response_metadata);
          appendCandidate(list, data.responseMetadata);
          appendCandidate(list, data.response_metadata);
          appendCandidate(list, data.metadata);
          appendCandidate(list, data.output);
          appendCandidate(list, data.result);
          appendCandidate(list, data.payload);
          appendCandidate(list, data.data);
          appendCandidate(list, candidatesFromOpenAI(data.globals));
          appendCandidate(list, candidatesFromOpenAI(data.openai));
          if (data.payload && typeof data.payload === "object") {
            appendCandidate(list, candidatesFromMessage(data.payload));
          }
          return list;
        }

        function candidatesFromDocument() {
          var list = [];
          try {
            appendCandidate(list, document.body && document.body.dataset);
            appendCandidate(list, document.documentElement && document.documentElement.dataset);
            var scripts = document.querySelectorAll('script[type="application/json"], script[type="application/ld+json"]');
            for (var i = 0; i < scripts.length; i += 1) {
              var text = scripts[i].textContent || "";
              if (text.length > 0 && text.length < 200000) {
                try {
                  appendCandidate(list, JSON.parse(text));
                } catch (_error) {
                  appendCandidate(list, text);
                }
              }
            }
          } catch (_error) {}
          return list;
        }

        function candidatesFromLocation() {
          var list = [];
          try {
            var text = decodeURIComponent(
              String(window.location.search || "") + String(window.location.hash || ""),
            );
            appendCandidate(list, text);
          } catch (_error) {}
          return list;
        }

        function currentToolOutput() {
          var output = [
            candidatesFromOpenAI(window.openai),
            candidatesFromOpenAI(window.__OPENAI__),
            candidatesFromOpenAI(window.__openai),
            candidatesFromOpenAI(window.__oai),
            candidatesFromOpenAI(window.__hostr),
            candidatesFromDocument(),
            candidatesFromLocation(),
          ];
          debugLog("current bridge snapshot", {
            hasOpenAI: Boolean(window.openai),
            hasUpperOpenAI: Boolean(window.__OPENAI__),
            hasLowerOpenAI: Boolean(window.__openai),
            openAIKeys: window.openai && typeof window.openai === "object"
              ? Object.keys(window.openai)
              : [],
            candidateGroups: output.map(function (group) {
              return Array.isArray(group) ? group.length : 1;
            }),
            candidates: output,
          });
          return output;
        }

        render(currentToolOutput());

        var remainingChecks = 80;
        var pollId = window.setInterval(function () {
          if (render(currentToolOutput())) {
            window.clearInterval(pollId);
            return;
          }
          remainingChecks -= 1;
          if (remainingChecks <= 0) window.clearInterval(pollId);
        }, 250);

        window.addEventListener(
          "openai:set_globals",
          function (event) {
            var detail = event.detail || {};
            var globals = detail.globals || detail;
            var output = [
              candidatesFromOpenAI(globals),
              candidatesFromMessage(detail),
              currentToolOutput(),
            ];
            debugLog("openai:set_globals", output);
            if (render(output)) {
              window.clearInterval(pollId);
            }
          },
          { passive: true },
        );

        window.addEventListener(
          "message",
          function (event) {
            var data = event.data || {};
            var output = candidatesFromMessage(data);
            debugLog("message event", {
              origin: event.origin,
              type: data && data.type,
              output: output,
            });
            if (render(output)) {
              window.clearInterval(pollId);
            }
          },
          { passive: true },
        );
      })();
    </script>
  </body>
</html>
`.trim();

const sessionConnectWidgetHtml = `
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
${sharedWidgetCss}

      .wrap {
        display: grid;
        gap: 10px;
        padding: 10px;
      }

      img {
        width: min(240px, 100%);
        aspect-ratio: 1;
        object-fit: contain;
        border-radius: 6px;
        background: white;
      }

    </style>
  </head>
  <body>
    <main id="root" class="hostr-root"></main>
    <script>
      (function () {
        var root = document.getElementById("root");

        function toolData(output) {
          if (!output || typeof output !== "object") return output;
          if (output.structuredContent && typeof output.structuredContent === "object") {
            return output.structuredContent;
          }
          return output;
        }

        function displayFrom(output) {
          if (!output || typeof output !== "object") return null;
          return output.display && output.display.type === "nostr-connect" ? output.display : null;
        }

        function safeHttpUrl(value) {
          if (typeof value !== "string") return null;
          try {
            var url = new URL(value);
            return url.protocol === "http:" || url.protocol === "https:" ? url.href : null;
          } catch (_error) {
            return null;
          }
        }

        function render(output) {
          if (output === undefined || output === null) {
            root.replaceChildren();
            return;
          }
          var display = displayFrom(toolData(output));
          root.replaceChildren();
          if (!display) {
            var empty = document.createElement("div");
            empty.className = "empty hostr-empty";
            empty.textContent = "No session QR is pending.";
            root.appendChild(empty);
            return;
          }

          var wrap = document.createElement("section");
          wrap.className = "wrap hostr-card";
          var title = document.createElement("h2");
          title.className = "hostr-title";
          title.textContent = display.title || "Log in to Hostr";
          wrap.appendChild(title);
          var message = document.createElement("p");
          message.className = "hostr-subtitle";
          message.textContent = display.message || "Scan this with your Nostr app to log in to your Hostr account.";
          wrap.appendChild(message);

          var qrUrl = safeHttpUrl(display.qrImageUrl);
          if (qrUrl) {
            var image = document.createElement("img");
            image.src = qrUrl;
            image.alt = "Nostr Connect QR";
            wrap.appendChild(image);
          }

          var textUrl = safeHttpUrl(display.uriTextUrl);
          if (textUrl) {
            var link = document.createElement("a");
            link.href = textUrl;
            link.target = "_blank";
            link.rel = "noreferrer";
            link.className = "hostr-link";
            link.textContent = "Open exact nostrconnect URI";
            wrap.appendChild(link);
          }

          root.appendChild(wrap);
        }

        function currentToolOutput() {
          return window.openai && window.openai.toolOutput;
        }

        render(currentToolOutput());

        var remainingChecks = 40;
        var pollId = window.setInterval(function () {
          var output = currentToolOutput();
          if (output === undefined || output === null) {
            remainingChecks -= 1;
            if (remainingChecks <= 0) window.clearInterval(pollId);
            return;
          }
          window.clearInterval(pollId);
          render(output);
        }, 250);

        window.addEventListener("openai:set_globals", function (event) {
          var globals = event.detail && event.detail.globals;
          var output = (globals && globals.toolOutput) || currentToolOutput();
          if (output !== undefined && output !== null) {
            window.clearInterval(pollId);
            render(output);
          }
        }, { passive: true });
      })();
    </script>
  </body>
</html>
`.trim();

const profileCardWidgetHtml = `
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
${sharedWidgetCss}

      .card {
        display: grid;
        grid-template-columns: 56px minmax(0, 1fr);
        gap: 10px;
        padding: 10px;
      }

      .avatar {
        width: 56px;
        height: 56px;
        border-radius: 50%;
        object-fit: cover;
        background: var(--hostr-chip);
      }

      .body {
        display: grid;
        gap: 5px;
        min-width: 0;
      }

      .topline {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 8px;
        min-width: 0;
      }

      .meta {
        display: flex;
        flex-wrap: wrap;
        gap: 6px;
      }

    </style>
  </head>
  <body>
    <main id="root" class="hostr-root"></main>
    <script>
      (function () {
        var root = document.getElementById("root");

        function toolData(output) {
          if (!output || typeof output !== "object") return output;
          if (output.structuredContent && typeof output.structuredContent === "object") {
            return output.structuredContent;
          }
          return output;
        }

        function cardFrom(output) {
          if (!output || typeof output !== "object") return null;
          if (Array.isArray(output.profileCards) && output.profileCards[0]) return output.profileCards[0];
          if (output.display && Array.isArray(output.display.cards)) return output.display.cards[0] || null;
          return null;
        }

        function safeHttpUrl(value) {
          if (typeof value !== "string") return null;
          try {
            var url = new URL(value);
            return url.protocol === "http:" || url.protocol === "https:" ? url.href : null;
          } catch (_error) {
            return null;
          }
        }

        function appendText(parent, tag, className, value) {
          if (!value) return null;
          var el = document.createElement(tag);
          el.className = className;
          el.textContent = value;
          parent.appendChild(el);
          return el;
        }

        function render(output) {
          if (output === undefined || output === null) {
            root.replaceChildren();
            return;
          }
          var card = cardFrom(toolData(output));
          root.replaceChildren();
          if (!card || card.exists === false) {
            appendText(root, "div", "empty hostr-empty", "No Hostr profile metadata was found.");
            return;
          }

          var article = document.createElement("article");
          article.className = "card hostr-card";
          var picture = safeHttpUrl(card.picture);
          var avatar = document.createElement(picture ? "img" : "div");
          avatar.className = "avatar";
          if (picture) {
            avatar.src = picture;
            avatar.alt = "Profile picture";
          }
          article.appendChild(avatar);

          var body = document.createElement("div");
          body.className = "body";
          var top = document.createElement("div");
          top.className = "topline";
          appendText(top, "h2", "hostr-title", card.name || "Hostr profile");
          appendText(top, "span", "status hostr-status", card.statusLabel || "current");
          body.appendChild(top);
          appendText(body, "p", "hostr-subtitle", card.about || "");

          var meta = document.createElement("div");
          meta.className = "meta";
          appendText(meta, "span", "pill hostr-pill", card.lud16 || "");
          appendText(meta, "span", "pill hostr-pill", card.nip05 || "");
          appendText(meta, "span", "pill hostr-pill", card.website || "");
          if (meta.childNodes.length > 0) body.appendChild(meta);

          article.appendChild(body);
          root.appendChild(article);
        }

        function currentToolOutput() {
          return window.openai && window.openai.toolOutput;
        }

        render(currentToolOutput());

        var remainingChecks = 40;
        var pollId = window.setInterval(function () {
          var output = currentToolOutput();
          if (output === undefined || output === null) {
            remainingChecks -= 1;
            if (remainingChecks <= 0) window.clearInterval(pollId);
            return;
          }
          window.clearInterval(pollId);
          render(output);
        }, 250);

        window.addEventListener("openai:set_globals", function (event) {
          var globals = event.detail && event.detail.globals;
          var output = (globals && globals.toolOutput) || currentToolOutput();
          if (output !== undefined && output !== null) {
            window.clearInterval(pollId);
            render(output);
          }
        }, { passive: true });
      })();
    </script>
  </body>
</html>
`.trim();

const tripHostingWidgetHtml = (variant: "trip" | "hosting") => `
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <style>
${sharedWidgetCss}

      .card {
        display: grid;
        gap: 8px;
        padding: 10px;
      }

      .topline {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 8px;
      }

      .cancelled {
        font-weight: 800;
      }

    </style>
  </head>
  <body>
    <main id="root" class="hostr-root"></main>
    <script>
      (function () {
        var root = document.getElementById("root");
        var variant = "${variant}";

        function toolData(output) {
          if (!output || typeof output !== "object") return output;
          if (output.structuredContent && typeof output.structuredContent === "object") {
            return output.structuredContent;
          }
          return output;
        }

        function cardsFrom(output) {
          if (!output || typeof output !== "object") return [];
          if (variant === "hosting" && Array.isArray(output.hostingCards)) return output.hostingCards;
          if (variant === "trip" && Array.isArray(output.tripCards)) return output.tripCards;
          if (Array.isArray(output.reservationCards)) return output.reservationCards;
          if (output.display && Array.isArray(output.display.cards)) return output.display.cards;
          return [];
        }

        function appendText(parent, tag, className, value) {
          if (!value) return null;
          var el = document.createElement(tag);
          el.className = className;
          el.textContent = value;
          parent.appendChild(el);
          return el;
        }

        function renderCard(card) {
          var article = document.createElement("article");
          article.className = "card hostr-card";
          var top = document.createElement("div");
          top.className = "topline";
          appendText(top, "h2", "hostr-title", variant === "hosting" ? "Hosting" : "Trip");
          appendText(top, "span", "pill hostr-status", card.mode === "cancelled" ? "cancelled" : "confirmed");
          article.appendChild(top);

          if (card.mode === "cancelled") {
            appendText(article, "p", "line cancelled hostr-text", "Cancelled");
          }

          if (variant === "hosting" || card.type === "hosting-card") {
            appendText(article, "p", "line hostr-text", "Hosting " + (card.guestName || "guest") + " at: " + (card.title || "Hostr stay"));
          } else {
            appendText(article, "p", "line hostr-text", card.title || "Hostr stay");
          }

          if (card.start && card.end) {
            appendText(article, "p", "line muted hostr-subtitle", card.start + " to " + card.end);
          }

          return article;
        }

        function render(output) {
          if (output === undefined || output === null) {
            root.replaceChildren();
            return;
          }
          var cards = cardsFrom(toolData(output)).filter(Boolean);
          root.replaceChildren();
          if (cards.length === 0) {
            appendText(root, "div", "empty hostr-empty", variant === "hosting" ? "No hosting reservations found." : "No trips found.");
            return;
          }
          cards.forEach(function (card) {
            root.appendChild(renderCard(card));
          });
        }

        function currentToolOutput() {
          return window.openai && window.openai.toolOutput;
        }

        render(currentToolOutput());

        var remainingChecks = 40;
        var pollId = window.setInterval(function () {
          var output = currentToolOutput();
          if (output === undefined || output === null) {
            remainingChecks -= 1;
            if (remainingChecks <= 0) window.clearInterval(pollId);
            return;
          }
          window.clearInterval(pollId);
          render(output);
        }, 250);

        window.addEventListener("openai:set_globals", function (event) {
          var globals = event.detail && event.detail.globals;
          var output = (globals && globals.toolOutput) || currentToolOutput();
          if (output !== undefined && output !== null) {
            window.clearInterval(pollId);
            render(output);
          }
        }, { passive: true });
      })();
    </script>
  </body>
</html>
`.trim();

const createServer = (
  config: AppConfig,
  daemon: HostrDaemonClient,
  claims: AccessTokenClaims | null,
  sessionStore: McpSessionStore,
  visibleActionIds: Set<string> | null,
  currentTraceId: () => string,
) => {
  const server = new McpServer(
    {
      name: config.displayName,
      version: "0.0.1",
    },
    {
      capabilities: {
        logging: {},
        tools: { listChanged: true },
      },
    },
  );

  server.registerResource(
    "hostr-action-input-types",
    "hostr://mcp/action-input-types",
    {
      title: "Hostr MCP Action Input Types",
      description:
        "TypeScript interfaces and JSON schemas for every Hostr MCP tool input.",
      mimeType: "text/markdown",
    },
    async (uri) => ({
      contents: [
        {
          uri: uri.href,
          mimeType: "text/markdown",
          text: actionDocumentationFor(visibleActionIds),
        },
      ],
    }),
  );

  server.registerResource(
    "hostr-action-catalog",
    "hostr://mcp/action-catalog.json",
    {
      title: "Hostr MCP Action Catalog",
      description:
        "Machine-readable Hostr daemon action catalog, including input JSON schemas.",
      mimeType: "application/json",
    },
    async (uri) => ({
      contents: [
        {
          uri: uri.href,
          mimeType: "application/json",
          text: text(
            hostrActionCatalog
              .filter((action) => !visibleActionIds || visibleActionIds.has(action.id))
              .map(
              ({ inputSchema: _inputSchema, ...action }) => action,
            ),
          ),
        },
      ],
    }),
  );

  server.registerResource(
    "hostr-listing-card-widget",
    listingCardWidgetUri,
    {
      title: "Hostr Listing Card Widget",
      description:
        "Example lightweight HTML renderer for structured Hostr listing cards.",
      mimeType: "text/html;profile=mcp-app",
    },
    async () => ({
      contents: [
        {
          uri: listingCardWidgetUri,
          mimeType: "text/html;profile=mcp-app",
          text: listingCardWidgetHtml,
          _meta: {
            ui: {
              prefersBorder: true,
              csp: {
                resourceDomains: listingCardWidgetResourceDomains(config),
              },
            },
            "openai/widgetDescription":
              "Renders Hostr listing-card structuredContent as lightweight cards with images, price, type, status, and open links.",
            "openai/widgetPrefersBorder": true,
            "openai/widgetAccessible": true,
          },
        },
      ],
    }),
  );

  server.registerResource(
    "hostr-payment-required-widget",
    paymentRequiredWidgetUri,
    {
      title: "Hostr Payment Required Widget",
      description:
        "Example lightweight HTML renderer for external Lightning payment QR prompts.",
      mimeType: "text/html;profile=mcp-app",
    },
    async () => ({
      contents: [
        {
          uri: paymentRequiredWidgetUri,
          mimeType: "text/html;profile=mcp-app",
          text: paymentRequiredWidgetHtml,
          _meta: {
            ui: {
              prefersBorder: true,
              csp: {
                resourceDomains: qrWidgetResourceDomains(config),
              },
            },
            "openai/widgetDescription":
              "Renders Hostr external-payment structuredContent as a Lightning invoice QR, wallet link, and copy action.",
            "openai/widgetPrefersBorder": true,
            "openai/widgetAccessible": true,
          },
        },
      ],
    }),
  );

  server.registerResource(
    "hostr-session-connect-widget",
    sessionConnectWidgetUri,
    {
      title: "Hostr Session Connect Widget",
      description:
        "Example lightweight HTML renderer for Nostr Connect login QR prompts.",
      mimeType: "text/html;profile=mcp-app",
    },
    async () => ({
      contents: [
        {
          uri: sessionConnectWidgetUri,
          mimeType: "text/html;profile=mcp-app",
          text: sessionConnectWidgetHtml,
          _meta: {
            ui: {
              prefersBorder: true,
              csp: {
                resourceDomains: qrWidgetResourceDomains(config),
              },
            },
            "openai/widgetDescription":
              "Renders Hostr session initialization structuredContent as a Nostr Connect QR and exact URI link.",
            "openai/widgetPrefersBorder": true,
            "openai/widgetAccessible": true,
          },
        },
      ],
    }),
  );

  server.registerResource(
    "hostr-profile-card-widget",
    profileCardWidgetUri,
    {
      title: "Hostr Profile Card Widget",
      description:
        "Example lightweight HTML renderer for Hostr profile structured output.",
      mimeType: "text/html;profile=mcp-app",
    },
    async () => ({
      contents: [
        {
          uri: profileCardWidgetUri,
          mimeType: "text/html;profile=mcp-app",
          text: profileCardWidgetHtml,
          _meta: {
            ui: {
              prefersBorder: true,
              csp: {
                resourceDomains: profileCardWidgetResourceDomains(config),
              },
            },
            "openai/widgetDescription":
              "Renders Hostr profile structuredContent as a compact profile card with avatar and identity fields.",
            "openai/widgetPrefersBorder": true,
            "openai/widgetAccessible": true,
          },
        },
      ],
    }),
  );

  server.registerResource(
    "hostr-trip-widget",
    tripWidgetUri,
    {
      title: "Hostr Trip Widget",
      description:
        "Example lightweight HTML renderer for Hostr guest trip structured output.",
      mimeType: "text/html;profile=mcp-app",
    },
    async () => ({
      contents: [
        {
          uri: tripWidgetUri,
          mimeType: "text/html;profile=mcp-app",
          text: tripHostingWidgetHtml("trip"),
          _meta: {
            ui: { prefersBorder: true },
            "openai/widgetDescription":
              "Renders Hostr trip structuredContent, including a bold Cancelled state when present.",
            "openai/widgetPrefersBorder": true,
            "openai/widgetAccessible": true,
          },
        },
      ],
    }),
  );

  server.registerResource(
    "hostr-hosting-widget",
    hostingWidgetUri,
    {
      title: "Hostr Hosting Widget",
      description:
        "Example lightweight HTML renderer for Hostr hosting structured output.",
      mimeType: "text/html;profile=mcp-app",
    },
    async () => ({
      contents: [
        {
          uri: hostingWidgetUri,
          mimeType: "text/html;profile=mcp-app",
          text: tripHostingWidgetHtml("hosting"),
          _meta: {
            ui: { prefersBorder: true },
            "openai/widgetDescription":
              "Renders Hostr hosting structuredContent with the guest and stay location text.",
            "openai/widgetPrefersBorder": true,
            "openai/widgetAccessible": true,
          },
        },
      ],
    }),
  );

  server.registerTool(
    "hostr_images_upload",
    {
      title: "Upload Hostr Listing Image",
      description:
        "Upload an original user-provided image file to Hostr Blossom and return a generic durable public image URL. Use this before any Hostr tool that needs an image URL, such as hostr_listings_create or hostr_profile_edit. The required `file` argument is schema type `file` and must be sent as a real uploaded file/blob/reference through the MCP client bridge so the bridge can rewrite or stream the original bytes. Reachable local filesystem paths and file:// URLs are accepted here and will be read, then re-uploaded to Blossom. Do not pass /mnt/data, /mnt/shared, file://, local filesystem paths, ChatGPT file mount paths, or base64 text directly to listing/profile image URL fields. Do not resize, downscale, crop, recompress, transcode, or create thumbnails unless the user explicitly asks. When an authenticated Hostr session is available, this tool first tries that session's Blossom upload path; otherwise it falls back to the server's direct Blossom upload endpoint. After it succeeds, use structuredContent.usage.image.url as the generic image URL: pass it as images[].url to hostr_listings_create, or as image/picture to hostr_profile_edit.",
      inputSchema: imageUploadInputSchema,
      outputSchema: imageUploadOutputSchema,
      annotations: {
        readOnlyHint: false,
        destructiveHint: false,
        idempotentHint: true,
        openWorldHint: true,
      },
      _meta: {
        "openai/fileParams": ["file"],
        "hostr.contentType": "image-upload",
        "hostr.uploadEndpoint": "/mcp/uploads/images",
        "hostr.fileArgument": "file",
      },
    },
    async (args: Record<string, unknown>) => {
      const traceId = currentTraceId();
      let upload: UploadedImage;
      try {
        upload = await uploadedImageFromFileArgument(
          args.file,
          stringValue(args.filename) ?? undefined,
          stringValue(args.mime) ?? undefined,
        );
      } catch (error) {
        const code =
          error instanceof Error ? error.message : "unsupported_file_argument";
        const message =
          code === "file_argument_must_be_file_not_path"
            ? "The `file` argument must be a file-typed upload/blob, not a local path, /mnt/data path, file:// URL, or ChatGPT file mount string."
            : code === "file_download_url_missing"
              ? "The `file` argument is a client upload reference without a downloadable URL. Use a client that can provide download_url/file_id file params, or pass a reachable local path on the MCP server host."
            : "Could not read the file argument. Send the original image as the MCP file-typed `file` argument.";
        return {
          isError: true,
          content: [
            {
              type: "text" as const,
              text: JSON.stringify(
                {
                  ok: false,
                  error: code,
                  error_description: message,
                },
                null,
                2,
              ),
            },
          ],
        };
      }

      try {
        const result = await uploadImageWithBestAvailableAuth(
          config,
          daemon,
          activePubkeyForClaims(sessionStore, claims),
          upload,
          traceId,
        );
        return {
          structuredContent: { ...result, traceId },
          content: [
            {
              type: "text" as const,
              text: [
                "Uploaded the original image to Hostr Blossom.",
                "",
                `Use this URL in Hostr image URL fields: ${result.usage.image.url}`,
              ].join("\n"),
            },
          ],
        };
      } catch (error) {
        const message =
          error instanceof Error ? error.message : "Blossom upload failed.";
        return {
          isError: true,
          content: [
            {
              type: "text" as const,
              text: JSON.stringify(
                {
                  ok: false,
                  error: "blossom_upload_failed",
                  error_description: message,
                },
                null,
                2,
              ),
            },
          ],
        };
      }
    },
  );

  const toolHandles = new Map<string, RegisteredTool>();
  const customToolHandles = new Map<string, RegisteredTool>();

  customToolHandles.set(
    "hostr_session_accounts",
    server.registerTool(
      "hostr_session_accounts",
      {
        title: "Hostr Session Accounts",
        description:
          "List the Hostr/NIP-46 accounts connected to this MCP session, including profile metadata, active account, and signer status.",
        inputSchema: sessionAccountsInputSchema,
        annotations: {
          readOnlyHint: true,
          destructiveHint: false,
          openWorldHint: false,
        },
      },
      async () => {
        const traceId = currentTraceId();
        if (!claims) {
          return sessionToolResponse(
            { ok: false, error: "auth_required" },
            "Connect Hostr MCP with OAuth first.",
          );
        }
        const payload = await sessionAccountsPayload(
          sessionStore,
          daemon,
          claims,
          traceId,
        );
        return sessionToolResponse(payload, JSON.stringify(payload, null, 2));
      },
    ),
  );

  customToolHandles.set(
    "hostr_session_switch",
    server.registerTool(
      "hostr_session_switch",
      {
        title: "Switch Hostr Account",
        description:
          "Make one of this MCP session's connected Hostr accounts the active account. This changes which account future Hostr tools use.",
        inputSchema: sessionSwitchInputSchema,
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          openWorldHint: false,
        },
      },
      async (args: Record<string, unknown>) => {
        const traceId = currentTraceId();
        if (!claims) {
          return sessionToolResponse(
            { ok: false, error: "auth_required" },
            "Connect Hostr MCP with OAuth first.",
          );
        }
        const pubkey = stringValue(args.pubkey);
        if (!pubkey) {
          return sessionToolResponse(
            { ok: false, error: "pubkey_required" },
            "Choose a connected Hostr account pubkey to switch to.",
          );
        }
        try {
          sessionStore.switchActive(claims.sessionId, pubkey);
        } catch {
          return sessionToolResponse(
            { ok: false, error: "unknown_session_account", pubkey },
            "That pubkey is not connected to this MCP session. Call hostr_session_accounts, or connect it with hostr_session_connect first.",
          );
        }
        const visible = await visibleActionIdsForPubkey(daemon, pubkey, traceId);
        await refreshToolVisibility(
          server,
          toolHandles,
          customToolHandles,
          visible,
          sessionStore,
          claims,
        );
        const payload = {
          ok: true,
          activePubkey: pubkey,
          ...toolListChangedResult,
        };
        return sessionToolResponse(
          payload,
          `Switched active Hostr account to ${pubkey}.`,
        );
      },
    ),
  );

  customToolHandles.set(
    "hostr_session_logout",
    server.registerTool(
      "hostr_session_logout",
      {
        title: "Log Out Hostr Account",
        description:
          "Log out one or all Hostr/NIP-46 accounts connected to this MCP session. If no pubkey is supplied, logs out the active account.",
        inputSchema: sessionLogoutInputSchema,
        annotations: {
          readOnlyHint: false,
          destructiveHint: false,
          openWorldHint: false,
        },
      },
      async (args: Record<string, unknown>) => {
        const traceId = currentTraceId();
        if (!claims) {
          return sessionToolResponse(
            { ok: false, error: "auth_required" },
            "Connect Hostr MCP with OAuth first.",
          );
        }
        const session = sessionStore.get(claims.sessionId);
        const all = boolValue(args.all) === true;
        const targets = all
          ? session.accounts.map((account) => account.pubkey)
          : [stringValue(args.pubkey) ?? session.activePubkey].filter(
              (pubkey): pubkey is string => Boolean(pubkey),
            );
        if (targets.length === 0) {
          return sessionToolResponse(
            { ok: false, error: "no_active_account" },
            "No Hostr account is active in this MCP session.",
          );
        }
        for (const pubkey of targets) {
          await daemon.logoutSession({ pubkey, traceId });
          sessionStore.removeAccount(claims.sessionId, pubkey);
        }
        const activePubkey = sessionStore.get(claims.sessionId).activePubkey;
        const visible = activePubkey
          ? await visibleActionIdsForPubkey(daemon, activePubkey, traceId)
          : fallbackVisibleActionIds(claims, undefined);
        await refreshToolVisibility(
          server,
          toolHandles,
          customToolHandles,
          visible,
          sessionStore,
          claims,
        );
        const payload = {
          ok: true,
          loggedOutPubkeys: targets,
          activePubkey,
          ...toolListChangedResult,
        };
        return sessionToolResponse(
          payload,
          activePubkey
            ? `Logged out ${targets.length} Hostr account${targets.length === 1 ? "" : "s"}. Active account is now ${activePubkey}.`
            : `Logged out ${targets.length} Hostr account${targets.length === 1 ? "" : "s"}. No Hostr account is active.`,
        );
      },
    ),
  );
  refreshSessionToolVisibility(customToolHandles, sessionStore, claims);

  for (const action of hostrActionCatalog) {
    const initiallyVisible = !visibleActionIds || visibleActionIds.has(action.id);
    const isThreadViewAction =
      action.id === "hostr.thread.view" ||
      action.id === "hostr.thread.message" ||
      action.id === "hostr.escrow.involve";
    const registeredTool = server.registerTool(
      action.toolName,
      {
        title: action.title,
        description: toolDescription(action),
        inputSchema: action.inputSchema,
        ...(listingActionIds.has(action.id)
          ? {
              outputSchema: listingCardOutputSchema,
              _meta: {
                ...widgetTemplateMeta(listingCardWidgetUri),
                "hostr.preferredRenderer": "listing-card",
                "hostr.contentType": "listing-card",
              },
            }
          : {}),
        ...(!listingActionIds.has(action.id) &&
        action.id === "hostr.session.connect"
          ? {
              outputSchema: sessionConnectOutputSchema,
              _meta: {
                ...widgetTemplateMeta(sessionConnectWidgetUri),
                "hostr.preferredRenderer": "nostr-connect",
                "hostr.contentType": "nostr-connect",
              },
            }
          : {}),
        ...(!listingActionIds.has(action.id) &&
        action.id !== "hostr.session.connect" &&
        profileActionIds.has(action.id)
          ? {
              outputSchema: profileCardOutputSchema,
              _meta: {
                ...widgetTemplateMeta(profileCardWidgetUri),
                "hostr.preferredRenderer": "profile-card",
                "hostr.contentType": "profile-card",
              },
            }
          : {}),
        ...(!listingActionIds.has(action.id) &&
        action.id !== "hostr.session.connect" &&
        !profileActionIds.has(action.id) &&
        reservationActionIds.has(action.id)
          ? {
              outputSchema:
                action.id === "hostr.reservations.bookAndPay"
                  ? paymentRequiredOutputSchema
                  : reservationCardOutputSchema,
              _meta: reservationToolMeta(action.id),
            }
          : {}),
        ...(!listingActionIds.has(action.id) &&
        action.id !== "hostr.session.connect" &&
        !profileActionIds.has(action.id) &&
        !reservationActionIds.has(action.id) &&
        threadActionIds.has(action.id)
          ? {
              outputSchema: threadCardOutputSchema,
              _meta: {
                "hostr.preferredRenderer": isThreadViewAction
                  ? "thread-view"
                  : "thread-card",
                "hostr.contentType": isThreadViewAction
                  ? "thread-view"
                  : "thread-card-list",
              },
            }
          : {}),
        ...(!listingActionIds.has(action.id) &&
        action.id !== "hostr.session.connect" &&
        !profileActionIds.has(action.id) &&
        !reservationActionIds.has(action.id) &&
        !threadActionIds.has(action.id) &&
        escrowTradeActionIds.has(action.id)
          ? {
              outputSchema: escrowTradeOutputSchema,
              _meta: {
                "hostr.preferredRenderer": "escrow-trade-card",
                "hostr.contentType": "escrow-trade-card",
              },
            }
          : {}),
        ...(!listingActionIds.has(action.id) &&
        action.id !== "hostr.session.connect" &&
        !profileActionIds.has(action.id) &&
        !reservationActionIds.has(action.id) &&
        !threadActionIds.has(action.id) &&
        !escrowTradeActionIds.has(action.id) &&
        escrowServiceActionIds.has(action.id)
          ? {
              outputSchema: escrowServiceOutputSchema,
              _meta: {
                "hostr.preferredRenderer": "escrow-service-card",
                "hostr.contentType": "escrow-service-card",
              },
            }
          : {}),
        ...(!listingActionIds.has(action.id) &&
        action.id !== "hostr.session.connect" &&
        !profileActionIds.has(action.id) &&
        !reservationActionIds.has(action.id) &&
        !threadActionIds.has(action.id) &&
        !escrowTradeActionIds.has(action.id) &&
        !escrowServiceActionIds.has(action.id) &&
        escrowBadgeActionIds.has(action.id)
          ? {
              outputSchema: escrowBadgeOutputSchema,
              _meta: {
                "hostr.preferredRenderer": "escrow-badge-card",
                "hostr.contentType": "escrow-badge-card",
              },
            }
          : {}),
        annotations: toolAnnotations(action),
      },
      async (
        args: Record<string, unknown>,
        extra: RequestHandlerExtra<ServerRequest, ServerNotification>,
      ) => {
        const traceId = currentTraceId();
        const publicAction = publicActionIds.has(action.id);
        const requiredScope = action.readOnly ? "hostr:read" : "hostr:write";
        if (!publicAction && !claims) {
          const result = {
            ok: false,
            errors: [
              {
                code: "auth_required",
                message: `Tool requires ${requiredScope}.`,
                hint: "Connect Hostr MCP with OAuth, then retry this tool.",
              },
            ],
          };
          return toolResponse(config, action.id, result, true);
        }
        if (!publicAction && claims && !hasScope(claims, requiredScope)) {
          const result = {
            ok: false,
            errors: [
              {
                code: "insufficient_scope",
                message: `Tool requires ${requiredScope}.`,
              },
            ],
          };
          return toolResponse(config, action.id, result, true);
        }

        const activePubkey = activePubkeyForClaims(sessionStore, claims);
        if (action.id === "hostr.session.status" && claims) {
          const payload = await sessionStatusPayload(
            sessionStore,
            daemon,
            claims,
            args,
            traceId,
          );
          return sessionToolResponse(payload, JSON.stringify(payload, null, 2));
        }
        if (
          !publicAction &&
          !sessionManagedActionIds.has(action.id) &&
          claims &&
          !activePubkey
        ) {
          const result = {
            ok: false,
            errors: [
              {
                code: "login_required",
                message:
                  "No Hostr account is active for this MCP session. Call hostr_session_connect first.",
              },
            ],
          };
          return toolResponse(config, action.id, result, true);
        }
        const actionPubkey =
          action.id === "hostr.session.connect"
            ? claims?.sessionId
            : publicAction
              ? undefined
              : activePubkey;

        const notificationToken = randomUUID();
        const seenSignerRequestIds = new Set<string>();
        const seenCriticalNoticeKeys = new Set<string>();
        const criticalNotices: HostrCriticalNotice[] = [];
        const unsubscribe = daemon.onNotification((notification) => {
          const params = record(notification.params);
          if (stringValue(params?.operationToken) !== notificationToken) {
            return;
          }
          const requestId = stringValue(params?.requestId);
          if (requestId && seenSignerRequestIds.has(requestId)) {
            return;
          }
          if (requestId) {
            seenSignerRequestIds.add(requestId);
          }
          const criticalNotice = criticalNoticeFromNotification(notification);
          if (criticalNotice) {
            const key = criticalNoticeKey(criticalNotice);
            if (!seenCriticalNoticeKeys.has(key)) {
              seenCriticalNoticeKeys.add(key);
              criticalNotices.push(criticalNotice);
              if (criticalNotice.type === "signer-approval") {
                void sendHostrElicitation(server, criticalNotice).catch(
                  (error) => {
                    console.error("Failed to elicit Hostr action:", error);
                  },
                );
              }
            }
          }
          void sendHostrProgress(config, extra, notification).catch((error) => {
            console.error("Failed to send Hostr notification:", error);
          });
        });

        try {
          const result = await daemon.callAction({
            ...(actionPubkey ? { pubkey: actionPubkey } : {}),
            action: action.id,
            input: args,
            notificationToken,
          ...(action.id === "hostr.reservations.bookAndPay"
            ? { timeoutMs: bookAndPayTimeoutMs(args) }
            : {}),
            traceId,
          });
          if (
            claims &&
            action.id === "hostr.session.connect" &&
            result.ok &&
            record(result.data)?.authenticated === true
          ) {
            const connectedPubkey = stringValue(record(result.data)?.pubkey);
            if (connectedPubkey) {
              const profileResult = await daemon.callAction({
                pubkey: connectedPubkey,
                action: "hostr.profile.show",
                input: {},
                traceId,
              });
              sessionStore.addOrUpdateAccount({
                sessionId: claims.sessionId,
                pubkey: connectedPubkey,
                metadata: profileResult.ok
                  ? sessionAccountMetadataFromResult(
                      profileResult as Record<string, unknown>,
                    )
                  : undefined,
              });
              const visible = await visibleActionIdsForPubkey(
                daemon,
                connectedPubkey,
                traceId,
              );
              await refreshToolVisibility(
                server,
                toolHandles,
                customToolHandles,
                visible,
                sessionStore,
                claims,
              );
              result.data = {
                ...(record(result.data) ?? {}),
                activePubkey: connectedPubkey,
                ...toolListChangedResult,
              };
            }
          }
          auditToolCall({
            actionId: action.id,
            pubkey: actionPubkey,
            traceId,
            result,
          });
          const resultNotices = criticalNoticesFromToolResult({ ...result });
          const notices = dedupeCriticalNotices([
            ...criticalNotices,
            ...resultNotices,
          ]);
          return toolResponse(
            config,
            action.id,
            { ...result },
            !result.ok,
            notices,
          );
        } catch (error) {
          const message =
            error instanceof Error ? error.message : String(error);
          if (
            action.id === "hostr.swaps.watch" &&
            /timed out|timeout/i.test(message)
          ) {
            const result = swapWatchTimeoutResult(action.id, args, error);
            auditToolCall({
              actionId: action.id,
              pubkey: actionPubkey,
              traceId,
              result: {
                ok: true,
                data: result.data,
              },
            });
            return toolResponse(config, action.id, result, false);
          }
          throw error;
        } finally {
          unsubscribe();
        }
      },
    );
    toolHandles.set(action.toolName, registeredTool);
    if (!initiallyVisible) {
      registeredTool.disable();
    }
  }

  return server;
};

const actionDocumentationFor = (visibleActionIds: Set<string> | null): string => {
  if (!visibleActionIds) {
    return `${hostrActionDocumentation}\n\n${imageUploadToolDocumentation}`;
  }
  const visibleActions = hostrActionCatalog.filter((action) =>
    visibleActionIds.has(action.id),
  );
  return [
    "# Hostr MCP action inputs",
    "",
    "This session-specific catalog only includes Hostr tools visible to the authenticated MCP pubkey.",
    "",
    imageUploadToolDocumentation,
    "",
    ...visibleActions.map((action) =>
      [
        `## \`${action.toolName}\``,
        "",
        action.description,
        "",
        `Action id: \`${action.id}\``,
        "",
        `Input type: \`${action.inputTypeName}\``,
        "",
        "JSON schema:",
        "",
        "```json",
        JSON.stringify(action.inputJsonSchema, null, 2),
        "```",
      ].join("\n"),
    ),
  ].join("\n");
};

const fallbackVisibleActionIds = (
  claims: AccessTokenClaims | null,
  activePubkey: string | undefined,
) =>
  new Set(
    hostrActionCatalog
      .filter((action) => !("requiredRole" in action) || !action.requiredRole)
      .filter(
        (action) =>
          publicActionIds.has(action.id) ||
          (claims &&
            (sessionManagedActionIds.has(action.id) || Boolean(activePubkey))),
      )
      .map((action) => action.id),
  );

const visibleActionIdsForPubkey = async (
  daemon: HostrDaemonClient,
  pubkey: string,
  traceId?: string,
): Promise<Set<string>> => {
  try {
    const result = record(
      await daemon.visibleActions({ pubkey, traceId }),
    );
    const ids = arrayValue(result?.visibleActionIds)
      .map(stringValue)
      .filter((id): id is string => id !== null);
    if (ids.length > 0) {
      return new Set(ids);
    }
  } catch (error) {
    console.error("[hostr-mcp] Failed to resolve visible Hostr actions:", error);
  }
  return fallbackVisibleActionIds(
    { sessionId: pubkey, scope: "hostr:read hostr:write", sub: pubkey },
    pubkey,
  );
};

const visibleActionIdsForClaims = async (
  daemon: HostrDaemonClient,
  sessionStore: McpSessionStore,
  claims: AccessTokenClaims | null,
  traceId?: string,
): Promise<Set<string>> => {
  const activePubkey = activePubkeyForClaims(sessionStore, claims);
  if (!claims || !activePubkey) {
    return fallbackVisibleActionIds(claims, activePubkey);
  }
  return visibleActionIdsForPubkey(daemon, activePubkey, traceId);
};

export const handleMcpRequest =
  (config: AppConfig, daemon: HostrDaemonClient) =>
  async (request: Request, response: Response) => {
    const traceId = request.hostrTraceId ?? traceIdFromRequest(request);
    const token = bearerToken(request);
    let claims: AccessTokenClaims | null = null;
    if (token) {
      try {
        claims = await verifyAccessToken(config, token);
      } catch {
        response.setHeader("WWW-Authenticate", bearerChallenge(config));
        return response.status(401).json({ error: "invalid_token" });
      }
    }

    const sessionIdHeader = request.header("mcp-session-id");
    const sessionId = Array.isArray(sessionIdHeader)
      ? sessionIdHeader[0]
      : sessionIdHeader;
    const existingTransport = sessionId
      ? mcpTransports.get(sessionId)
      : undefined;
    if (existingTransport) {
      mcpSessionTraceIds.set(sessionId!, traceId);
      await existingTransport.handleRequest(request, response, request.body);
      return;
    }

    if (!sessionId && isInitializeRequest(request.body)) {
      const sessionStore = new McpSessionStore(config.oauthClientStorePath);
      let transport: StreamableHTTPServerTransport;
      transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: () => randomUUID(),
        onsessioninitialized: (initializedSessionId) => {
          console.error(
            `[hostr-mcp] MCP session initialized: ${initializedSessionId} traceId=${traceId}`,
          );
          mcpTransports.set(initializedSessionId, transport);
          mcpSessionTraceIds.set(initializedSessionId, traceId);
        },
      });
      transport.onclose = () => {
        const closedSessionId = transport.sessionId;
        if (closedSessionId) {
          console.error(
            `[hostr-mcp] MCP session closed: ${closedSessionId} traceId=${traceId}`,
          );
          mcpTransports.delete(closedSessionId);
          mcpSessionTraceIds.delete(closedSessionId);
        }
      };

      const visibleActionIds = await visibleActionIdsForClaims(
        daemon,
        sessionStore,
        claims,
        traceId,
      );
      const server = createServer(
        config,
        daemon,
        claims,
        sessionStore,
        visibleActionIds,
        () =>
          (transport.sessionId
            ? mcpSessionTraceIds.get(transport.sessionId)
            : undefined) ?? traceId,
      );
      await server.connect(transport);
      await transport.handleRequest(request, response, request.body);
      return;
    }

    response.status(400).json({
      jsonrpc: "2.0",
      error: {
        code: -32000,
        message: "Bad Request: No valid MCP session ID provided.",
      },
      id: null,
    });
  };

export const __testing = {
  anchorToNaddr,
  listingCardWidgetHtml,
  listingCardsFromResult,
  listingCardsMarkdown,
  listingRouteUrl,
  profileCardWidgetHtml,
  profileCardsFromResult,
  profileCardsMarkdown,
  paymentRequiredWidgetHtml,
  reservationCardsFromResult,
  reservationCardsMarkdown,
  reservationToolMeta,
  sessionConnectWidgetHtml,
  toolResponse,
  toolAnnotations,
  toolDescription,
  tripHostingWidgetHtml,
  widgetTemplateMeta,
};
