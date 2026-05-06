import type { Request, Response } from "express";
import { randomUUID } from "node:crypto";
import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
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
import { verifyAccessToken } from "../auth/jwt.js";
import type { HostrAccessTokenClaims } from "../auth/jwt.js";
import type { HostrDaemonClient } from "../daemon/client.js";
import type { HostrDaemonNotification } from "../daemon/client.js";
import { storePaymentAsset, storeQrTextAsset } from "../payment/assets.js";
import {
  hostrActionCatalog,
  hostrActionDocumentation,
} from "../generated/hostr-actions.js";

const text = (value: unknown) => JSON.stringify(value, null, 2);

const maxListingImageContentBlocks = 5;
const maxListingImageBytes = 2_500_000;

const listingActionIds = new Set([
  "hostr.listings.search",
  "hostr.listings.list",
  "hostr.listings.create",
  "hostr.listings.edit",
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
          "payment-external-required",
        ]),
        cards: z.array(z.record(z.string(), z.unknown())),
      })
      .optional(),
    reservationCards: z.array(z.record(z.string(), z.unknown())).optional(),
    paymentDisplays: z.array(z.record(z.string(), z.unknown())).optional(),
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

const escrowTradeActionIds = new Set([
  "hostr.escrow.trades.list",
  "hostr.escrow.trades.view",
  "hostr.escrow.trades.audit",
  "hostr.escrow.trades.arbitrate",
]);

const escrowServiceActionIds = new Set([
  "hostr.escrow.service.list",
  "hostr.escrow.service.get",
  "hostr.escrow.service.update",
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

const formatDateTime = (value: unknown): string | null => {
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
  type: "reservation-card";
  tradeId?: string;
  reservationId?: string;
  title: string;
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
): ReservationCardData | null => {
  if (!lookup || lookup.found !== true) {
    return null;
  }
  const group = record(lookup.group);
  const listing = record(lookup.listing);
  const title =
    stringValue(listing?.title) ??
    stringValue(group?.listingTitle) ??
    "Hostr reservation";
  const start = formatDateTime(group?.start);
  const end = formatDateTime(group?.end);
  const stage = stringValue(group?.stage);
  const cancelled = isCancelledStage(stage);
  return {
    type: "reservation-card",
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
    start: start ?? undefined,
    end: end ?? undefined,
    status: cancelled ? (stage ?? "cancelled") : undefined,
    statusLabel: cancelled ? (stage ?? "cancelled") : undefined,
    mode: cancelled ? "cancelled" : "confirmed",
  };
};

const reservationCard = (card: ReservationCardData): string => {
  return [
    card.mode === "cancelled"
      ? "### Reservation Cancelled"
      : "### Reservation Confirmed",
    `**Stay:** ${card.title}`,
    card.start && card.end ? `**Dates:** ${card.start} to ${card.end}` : null,
    card.status ? `**Status:** ${card.statusLabel ?? card.status}` : null,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const absoluteUrl = (config: AppConfig, path: string): string =>
  `${config.publicAssetBaseUrl.replace(/\/+$/, "")}${path}`;

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
    "Use the QR, wallet link, or exact invoice text link above. Do not copy an invoice from assistant-rendered prose.",
  ]
    .filter(Boolean)
    .join("\n\n");
};

const listingUrl = (
  config: AppConfig,
  listing: Record<string, unknown>,
): string | null => {
  const explicit = stringValue(listing.url);
  if (explicit) {
    return explicit;
  }
  const anchor = stringValue(listing.naddr) ?? stringValue(listing.anchor);
  if (!anchor) {
    return null;
  }
  const base =
    config.environmentLabel === "production"
      ? "https://hostr.network"
      : "https://hostr.development";
  return `${base}/listing/${anchor}`;
};

type ListingImage = {
  url: string;
  alt?: string;
};

type ListingCardData = {
  type: "listing-card";
  id?: string;
  anchor?: string;
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

const listingImage = (value: unknown): ListingImage | null => {
  const directUrl = stringValue(value);
  if (directUrl) {
    return { url: directUrl };
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

  return {
    url,
    alt:
      stringValue(image?.alt) ?? stringValue(image?.description) ?? undefined,
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
    .map(listingImage)
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

const listingCard = (
  config: AppConfig,
  listing: Record<string, unknown>,
  index: number | null,
  mode: "result" | "preview" | "published" = "result",
): string => {
  const card = listingCardData(config, listing, index, mode);
  const heading =
    mode === "preview"
      ? `### Preview: ${card.title}`
      : index === null
        ? `### ${card.title}`
        : `### ${index}. ${card.title}`;

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

const reservationCardResponseText = (
  displayMarkdown: string,
  reservationCards: ReservationCardData[],
): string => {
  const count = reservationCards.length;
  return [
    `Hostr reservation-card response: the assistant's final answer must include the Markdown reservation card${count === 1 ? "" : "s"} below exactly as rendered. Do not replace this with raw JSON, do not expose swap state internals, and do not show a Status line unless the reservation is cancelled.`,
    displayMarkdown,
  ].join("\n\n");
};

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
      reservationCardData(record(data.reservationLookup)),
      reservationCardData(record(record(data.state)?.reservationLookup)),
    ].filter((card): card is ReservationCardData => card !== null);
  }

  if (
    actionId === "hostr.trips.list" ||
    actionId === "hostr.bookings.list" ||
    actionId === "hostr.reservations.bookAndPay"
  ) {
    const collectionCards = Array.isArray(data.results)
      ? data.results
          .map(record)
          .flatMap((item) => [
            reservationCardData(item),
            reservationCardData(record(item?.reservationLookup)),
            reservationCardData(record(record(item?.state)?.reservationLookup)),
          ])
          .filter((card): card is ReservationCardData => card !== null)
      : [];
    return [
      ...collectionCards,
      reservationCardData(data),
      reservationCardData(record(data.reservationLookup)),
      reservationCardData(record(record(data.state)?.reservationLookup)),
    ].filter((card): card is ReservationCardData => card !== null);
  }

  return [];
};

type ThreadCardData = {
  type: "thread-card";
  title: string;
  counterparties: string[];
  conversation?: string;
  tradeId?: string;
  start?: string;
  end?: string;
  amount?: string;
  stage?: string;
  unreadCount?: number;
  preview?: string;
  updatedAt?: string;
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
} => {
  const requests = arrayValue(thread.reservationRequests)
    .map(record)
    .filter(isRecord);
  const latest = requests.at(-1);
  if (!latest) {
    return {};
  }
  const content = parseJsonRecord(latest.content);
  const amount = formatAmount(record(content?.amount));
  return {
    title: listingTitleFromEvent(latest) ?? undefined,
    start: formatDateTime(content?.start) ?? undefined,
    end: formatDateTime(content?.end) ?? undefined,
    amount: amount === "price unavailable" ? undefined : amount,
    stage: stringValue(content?.stage) ?? undefined,
    updatedAt: formatDateTime(latest.created_at) ?? undefined,
  };
};

const threadMessagePreview = (
  thread: Record<string, unknown>,
): string | undefined => {
  const textMessages = arrayValue(thread.textMessages)
    .map(record)
    .filter(isRecord);
  const latest = textMessages.at(-1);
  const content = stringValue(latest?.content);
  return content ? truncate(content, 140) : undefined;
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
  const preview = threadMessagePreview(thread);
  const conversation = stringValue(thread.conversation);
  const title =
    reservation.title ??
    preview ??
    (counterparties.length > 0
      ? `Conversation with ${counterparties.join(", ")}`
      : "Hostr thread");
  const unreadCount = Number(thread.unreadCount);
  return {
    type: "thread-card",
    title,
    counterparties,
    conversation: conversation ?? undefined,
    tradeId: conversation ?? undefined,
    start: reservation.start,
    end: reservation.end,
    amount: reservation.amount,
    stage: reservation.stage,
    unreadCount: Number.isFinite(unreadCount) ? unreadCount : undefined,
    preview,
    updatedAt: reservation.updatedAt,
  };
};

const threadCard = (card: ThreadCardData, index: number): string => {
  return [
    `### ${index}. ${card.title}`,
    card.counterparties.length > 0
      ? `**With:** ${card.counterparties.join(", ")}`
      : null,
    card.start && card.end ? `**Dates:** ${card.start} to ${card.end}` : null,
    card.amount ? `**Offer:** ${card.amount}` : null,
    card.stage && card.stage.toLowerCase().includes("cancel")
      ? `**Status:** ${card.stage}`
      : null,
    card.unreadCount && card.unreadCount > 0
      ? `**Unread:** ${card.unreadCount}`
      : null,
    card.preview ? card.preview : null,
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
    .filter((card): card is ThreadCardData => card !== null);
};

const threadCardResponseText = (
  displayMarkdown: string,
  threadCards: ThreadCardData[],
): string => {
  const count = threadCards.length;
  return [
    `Hostr thread-card response: the assistant's final answer must render the Markdown thread card${count === 1 ? "" : "s"} below. Use resolved profile names and stay titles. Do not show raw pubkeys, conversation ids, thread anchors, or event JSON unless the user asks for debugging details.`,
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
    `## ${view.title}`,
    view.counterparties.length > 0
      ? `**With:** ${view.counterparties.join(", ")}`
      : null,
    view.unreadCount && view.unreadCount > 0
      ? `**Unread:** ${view.unreadCount}`
      : null,
    view.requiresMessage
      ? "**Next:** Ask the user what they would like to message the escrow."
      : null,
    "### Messages",
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

const fetchListingImageBlock = async (
  card: ListingCardData,
): Promise<ContentBlock | null> => {
  const imageUrl = card.primaryImageUrl;
  if (!imageUrl || !/^https?:\/\//i.test(imageUrl)) {
    return null;
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 5_000);
  try {
    const response = await fetch(imageUrl, { signal: controller.signal });
    if (!response.ok) {
      return null;
    }
    const mimeType = response.headers.get("content-type") ?? "image/jpeg";
    if (!mimeType.toLowerCase().startsWith("image/")) {
      return null;
    }
    const contentLength = Number(response.headers.get("content-length"));
    if (
      Number.isFinite(contentLength) &&
      contentLength > maxListingImageBytes
    ) {
      return null;
    }
    const bytes = Buffer.from(await response.arrayBuffer());
    if (bytes.byteLength > maxListingImageBytes) {
      return null;
    }
    return {
      type: "image",
      data: bytes.toString("base64"),
      mimeType,
      annotations: {
        audience: ["user", "assistant"],
        priority: 1,
      },
      _meta: {
        "hostr.contentType": "listing-card-image",
        "hostr.listingCard": card,
        "hostr.imageUrl": imageUrl,
        "hostr.alt": `${card.title} photo`,
      },
    };
  } catch {
    return null;
  } finally {
    clearTimeout(timeout);
  }
};

const listingImageBlocks = async (
  listingCards: ListingCardData[],
): Promise<ContentBlock[]> => {
  const blocks = await Promise.all(
    listingCards
      .slice(0, maxListingImageContentBlocks)
      .map((card) => fetchListingImageBlock(card)),
  );
  return blocks.filter((block): block is ContentBlock => block !== null);
};

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
    "Hostr external-payment response: the assistant's final answer must render the fixed payment display below exactly. Do not render the BOLT11 invoice inline; the exact invoice is available only through structuredContent.paymentDisplays[0].copy.text and the exact invoice text URL. Do not expose internal tradeId or swapId in the payment prompt.",
    displayMarkdown,
  ]
    .filter(Boolean)
    .join("\n\n");
};

const criticalNoticeImageBlocks = (
  _notices: HostrCriticalNotice[],
): ContentBlock[] => [];

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

const formatToolContent = (
  config: AppConfig,
  actionId: string,
  result: Record<string, unknown>,
): string => {
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
      "## Recent Hostr Threads",
      threadCards
        .map((card, index) => threadCard(card, index + 1))
        .join("\n\n---\n\n"),
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

  if (actionId === "hostr.session.connect") {
    if (data.authenticated === true) {
      return `Hostr session connected for ${stringValue(data.pubkey) ?? "the token pubkey"}.`;
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
  const safeResult = sanitizeForStructuredContent(result) as Record<
    string,
    unknown
  >;
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
            reservationCards.length === 1
              ? "reservation-card"
              : "reservation-card-list",
          cards: reservationCards,
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
  const imageBlocks = listingCardDisplay
    ? await listingImageBlocks(listingCards)
    : [];
  const safeNotices = notices.map(sanitizeNotice);
  const contentText = listingCardDisplay
    ? listingCardResponseText(displayMarkdown, listingCards)
    : reservationCardDisplay
      ? reservationCardResponseText(displayMarkdown, reservationCards)
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
  const noticeImageBlocks = criticalNoticeImageBlocks(notices);
  const listingCardAssistantInstructions = listingCardDisplay
    ? [
        "When answering the user, render structuredContent.displayMarkdown as Markdown.",
        "Preserve every listing image Markdown tag exactly; do not summarize listing results as text-only prose.",
      ]
    : undefined;
  const reservationCardAssistantInstructions = reservationCardDisplay
    ? [
        "When answering the user, render structuredContent.displayMarkdown as Markdown.",
        "Preserve the reservation card exactly; do not replace it with raw JSON or internal swap state.",
        "Do not show a Status line for committed reservations. Only show status when the reservation is cancelled.",
      ]
    : undefined;
  const paymentAssistantInstructions = notices.some(
    (notice) => notice.type === "external-payment",
  )
    ? [
        "CRITICAL: The Hostr result contains structuredContent.display.type=payment-external-required. Render structuredContent.displayMarkdown exactly so the user sees the QR and exact invoice/copy affordance.",
        "The invoice copy source of truth is structuredContent.paymentDisplays[0].copy.text or the exact invoice text URL. Do not manually retype, display inline, truncate, normalize, wrap, add punctuation to, or otherwise modify the invoice string.",
        "Do not show internal tradeId or swapId in the payment prompt.",
        "Only after the QR and invoice are visible, call hostr_swaps_watch with the returned swapId, tradeId, reservationWaitSeconds, and dryRun=false to monitor payment, proof, and reservation completion.",
        "When watch completes or reports the swap is not found, call hostr_trips_list with the same tradeId until the committed reservation appears, then show the reservation card.",
      ]
    : undefined;
  const sessionConnectPending =
    actionId === "hostr.session.connect" &&
    safeResult.authenticated !== true &&
    safeResult.pending === true;
  const sessionConnectAssistantInstructions = sessionConnectPending
    ? [
        "Render structuredContent.displayMarkdown as Markdown so the user sees the Nostr Connect QR.",
        "Use the exact text: \"Scan this with your Nostr app to log in to your Hostr account.\"",
        "Do not stop after displaying the QR. Immediately call hostr_session_connect with wait=true and regenerate=false to listen for the session connection.",
        "After hostr_session_connect returns authenticated=true, retry or continue the Hostr action that required sign-in.",
      ]
    : undefined;
  const sessionConnectDisplay = sessionConnectPending
    ? {
        type: "nostr-connect" as const,
        title:
          stringValue(safeResult.displayTitle) ??
          "Log in to Hostr",
        message:
          stringValue(safeResult.displayMessage) ??
          "Scan this with your Nostr app to log in to your Hostr account.",
        nextTool: "hostr_session_connect",
        nextInput: record(safeResult.nextInput) ?? {
          wait: true,
          regenerate: false,
        },
      }
    : undefined;
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
      ...safeResult,
      displayMarkdown,
      ...(safeNotices.length > 0 ? { hostrNotices: safeNotices } : {}),
      ...(paymentAssistantInstructions
        ? { assistantInstructions: paymentAssistantInstructions }
        : {}),
      ...(sessionConnectAssistantInstructions
        ? { assistantInstructions: sessionConnectAssistantInstructions }
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
    threadCardDisplay ||
    threadViewDisplay ||
    escrowTradeDisplay ||
    escrowServiceDisplay ||
    escrowBadgeDisplay ||
    paymentDisplay ||
    sessionConnectDisplay ||
    notices.length > 0
      ? {
          _meta: {
            ...(listingCardDisplay
              ? {
                  "hostr.contentType": listingCardDisplay.type,
                  "hostr.display": listingCardDisplay,
                  "hostr.listingCards": listingCards,
                  "hostr.imageBlocks": imageBlocks.length,
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
                  "hostr.preferredRenderer": "reservation-card",
                  "hostr.assistantInstructions":
                    reservationCardAssistantInstructions,
                }
              : {}),
            ...(paymentDisplay
              ? {
                  "hostr.contentType": paymentDisplay.type,
                  "hostr.display": paymentDisplay,
                  "hostr.paymentDisplays": paymentDisplays,
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
            ...(safeNotices.length > 0 ? { "hostr.notices": safeNotices } : {}),
            ...(paymentAssistantInstructions ||
            sessionConnectAssistantInstructions ||
            escrowServiceAssistantInstructions ||
            escrowTradeAssistantInstructions ||
            threadViewAssistantInstructions
              ? {
                  "hostr.assistantInstructions":
                    paymentAssistantInstructions ??
                    sessionConnectAssistantInstructions ??
                    escrowServiceAssistantInstructions ??
                    escrowTradeAssistantInstructions ??
                    threadViewAssistantInstructions,
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
                  threadViewDisplay ??
                  escrowTradeDisplay ??
                  escrowServiceDisplay ??
                  paymentDisplay ??
                  sessionConnectDisplay,
              },
            }
          : {}),
      },
      ...noticeImageBlocks,
      ...imageBlocks,
    ],
  } satisfies CallToolResult;
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
    const result = await server.server.elicitInput(params);
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
      "Use the QR, wallet link, copy affordance, or exact invoice text link from the payment display. Do not copy an invoice from assistant-rendered prose.",
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
  const result = await server.server.elicitInput(params);
  console.error(
    `[hostr-mcp] Hostr elicitation completed: ${key} action=${result.action}`,
  );
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

type AccessTokenClaims = HostrAccessTokenClaims & { sub: string };

const publicActionIds = new Set<string>(["hostr.listings.search"]);

const hasScope = (claims: AccessTokenClaims, scope: string): boolean =>
  claims.scope.split(/\s+/).includes(scope);

const mcpTransports = new Map<string, StreamableHTTPServerTransport>();

const createServer = (
  config: AppConfig,
  daemon: HostrDaemonClient,
  claims: AccessTokenClaims | null,
  visibleActionIds: Set<string> | null,
) => {
  const server = new McpServer(
    {
      name: config.displayName,
      version: "0.0.1",
    },
    {
      capabilities: {
        logging: {},
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

  for (const action of hostrActionCatalog) {
    if (visibleActionIds && !visibleActionIds.has(action.id)) {
      continue;
    }
    const isThreadViewAction =
      action.id === "hostr.thread.view" ||
      action.id === "hostr.thread.message" ||
      action.id === "hostr.escrow.involve";
    server.registerTool(
      action.toolName,
      {
        title: action.title,
        description: `${action.description}${
          listingActionIds.has(action.id)
            ? "\n\nPresentation contract: this listing tool returns visual listing-card output. After calling it, answer with structuredContent.displayMarkdown rendered as Markdown and preserve every ![image](url); do not rewrite listing results as text-only prose."
            : ""
        }${
          reservationActionIds.has(action.id)
            ? "\n\nPresentation contract: this reservation tool may return visual reservation-card output. After calling it, answer with structuredContent.displayMarkdown rendered as Markdown; do not rewrite the reservation as raw JSON. A committed reservation card must not show Status: commit. Only show status when the reservation is cancelled."
            : ""
        }${
          threadActionIds.has(action.id)
            ? "\n\nPresentation contract: this inbox/thread tool returns visual thread-card or thread-view output. After calling it, answer with structuredContent.displayMarkdown rendered as Markdown. Use resolved profile names and stay titles; do not show raw pubkeys, conversation ids, thread anchors, or event JSON unless the user explicitly asks for debugging details."
            : ""
        }${
          escrowTradeActionIds.has(action.id)
            ? "\n\nPresentation contract: this escrow-only tool returns escrow-trade-card output. It is hidden unless the authenticated Hostr pubkey is configured as an escrow. After calling it, answer with structuredContent.displayMarkdown rendered as Markdown and do not show raw event JSON unless the user explicitly asks for debugging details."
            : ""
        }${
          escrowServiceActionIds.has(action.id)
            ? "\n\nPresentation contract: this escrow-only service tool returns escrow-service-card output. It is hidden unless the authenticated Hostr pubkey is configured as an escrow. Keep dryRun=true until the user explicitly approves publishing service settings. Use hostr_profile_edit for profile metadata."
            : ""
        }${
          escrowBadgeActionIds.has(action.id)
            ? "\n\nPresentation contract: this escrow-only badge tool returns escrow-badge-card output. It is hidden unless the authenticated Hostr pubkey is configured as an escrow. Keep dryRun=true until the user explicitly approves publishing or deleting badge events."
            : ""
        }\n\nInput type: ${action.inputTypeName}. Full TypeScript and JSON schema docs are available in hostr://mcp/action-input-types.`,
        inputSchema: action.inputSchema,
        ...(listingActionIds.has(action.id)
          ? {
              outputSchema: listingCardOutputSchema,
              _meta: {
                "hostr.preferredRenderer": "listing-card",
                "hostr.contentType": "listing-card",
              },
            }
          : {}),
        ...(!listingActionIds.has(action.id) &&
        reservationActionIds.has(action.id)
          ? {
              outputSchema: reservationCardOutputSchema,
              _meta: {
                "hostr.preferredRenderer": "reservation-card",
                "hostr.contentType": "reservation-card",
              },
            }
          : {}),
        ...(!listingActionIds.has(action.id) &&
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
        annotations: {
          readOnlyHint: action.readOnly,
          destructiveHint: !action.readOnly,
        },
      },
      async (
        args: Record<string, unknown>,
        extra: RequestHandlerExtra<ServerRequest, ServerNotification>,
      ) => {
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
            ...(claims ? { pubkey: claims.pubkey } : {}),
            action: action.id,
            input: args,
            notificationToken,
            ...(action.id === "hostr.reservations.bookAndPay"
              ? { timeoutMs: bookAndPayTimeoutMs(args) }
              : {}),
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
        } finally {
          unsubscribe();
        }
      },
    );
  }

  return server;
};

const bearerToken = (request: Request): string | null => {
  const header = request.header("authorization");
  if (!header) {
    return null;
  }

  const match = /^Bearer\s+(.+)$/i.exec(header);
  return match?.[1] ?? null;
};

const challenge = (config: AppConfig): string =>
  `Bearer resource_metadata="${config.issuer}/.well-known/oauth-protected-resource/mcp", scope="hostr:read hostr:write"`;

const actionDocumentationFor = (visibleActionIds: Set<string> | null): string => {
  if (!visibleActionIds) {
    return hostrActionDocumentation;
  }
  const visibleActions = hostrActionCatalog.filter((action) =>
    visibleActionIds.has(action.id),
  );
  return [
    "# Hostr MCP action inputs",
    "",
    "This session-specific catalog only includes Hostr tools visible to the authenticated MCP pubkey.",
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

const fallbackVisibleActionIds = (claims: AccessTokenClaims | null) =>
  new Set(
    hostrActionCatalog
      .filter((action) => !("requiredRole" in action) || !action.requiredRole)
      .filter((action) => claims || publicActionIds.has(action.id))
      .map((action) => action.id),
  );

const visibleActionIdsForClaims = async (
  daemon: HostrDaemonClient,
  claims: AccessTokenClaims | null,
): Promise<Set<string>> => {
  if (!claims) {
    return fallbackVisibleActionIds(claims);
  }
  try {
    const result = record(await daemon.visibleActions({ pubkey: claims.pubkey }));
    const ids = arrayValue(result?.visibleActionIds)
      .map(stringValue)
      .filter((id): id is string => id !== null);
    if (ids.length > 0) {
      return new Set(ids);
    }
  } catch (error) {
    console.error("[hostr-mcp] Failed to resolve visible Hostr actions:", error);
  }
  return fallbackVisibleActionIds(claims);
};

export const handleMcpRequest =
  (config: AppConfig, daemon: HostrDaemonClient) =>
  async (request: Request, response: Response) => {
    const token = bearerToken(request);
    let claims: AccessTokenClaims | null = null;
    if (token) {
      try {
        claims = await verifyAccessToken(config, token);
      } catch {
        response.setHeader("WWW-Authenticate", challenge(config));
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
      await existingTransport.handleRequest(request, response, request.body);
      return;
    }

    if (!sessionId && isInitializeRequest(request.body)) {
      let transport: StreamableHTTPServerTransport;
      transport = new StreamableHTTPServerTransport({
        sessionIdGenerator: () => randomUUID(),
        onsessioninitialized: (initializedSessionId) => {
          console.error(
            `[hostr-mcp] MCP session initialized: ${initializedSessionId}`,
          );
          mcpTransports.set(initializedSessionId, transport);
        },
      });
      transport.onclose = () => {
        const closedSessionId = transport.sessionId;
        if (closedSessionId) {
          console.error(`[hostr-mcp] MCP session closed: ${closedSessionId}`);
          mcpTransports.delete(closedSessionId);
        }
      };

      const visibleActionIds = await visibleActionIdsForClaims(daemon, claims);
      const server = createServer(config, daemon, claims, visibleActionIds);
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
