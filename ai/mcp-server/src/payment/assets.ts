import { randomUUID } from "node:crypto";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";

type PaymentAsset = {
  invoice: string;
  qrPng: Buffer;
  createdAt: number;
};

export type PaymentAssetListItem = {
  id: string;
  createdAt: string;
  expiresAt: string;
  ageMs: number;
  qrBytes: number;
  textBytes: number;
  invoiceBytes: number;
  textUrlPath: string;
  qrUrlPath?: string;
  invoiceUrlPath: string;
};

const paymentAssets = new Map<string, PaymentAsset>();
const maxAgeMs = 24 * 60 * 60 * 1000;
const paymentAssetDir =
  process.env.HOSTR_MCP_PAYMENT_ASSET_DIR ??
  join(tmpdir(), "hostr-mcp-payment-assets");

const validIdPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const assetPaths = (id: string) => ({
  invoice: join(paymentAssetDir, `${id}.txt`),
  metadata: join(paymentAssetDir, `${id}.json`),
  qr: join(paymentAssetDir, `${id}.png`),
});

const ensurePaymentAssetDir = () => {
  mkdirSync(paymentAssetDir, { recursive: true });
};

const readDiskAsset = (id: string): PaymentAsset | undefined => {
  if (!validIdPattern.test(id)) {
    return undefined;
  }

  const paths = assetPaths(id);
  if (!existsSync(paths.invoice) || !existsSync(paths.metadata)) {
    return undefined;
  }

  try {
    const metadata = JSON.parse(readFileSync(paths.metadata, "utf8")) as {
      createdAt?: unknown;
    };
    const createdAt =
      typeof metadata.createdAt === "number"
        ? metadata.createdAt
        : statSync(paths.invoice).mtimeMs;
    return {
      invoice: readFileSync(paths.invoice, "utf8"),
      qrPng: existsSync(paths.qr) ? readFileSync(paths.qr) : Buffer.alloc(0),
      createdAt,
    };
  } catch {
    return undefined;
  }
};

const writeDiskAsset = (id: string, asset: PaymentAsset) => {
  ensurePaymentAssetDir();
  const paths = assetPaths(id);
  writeFileSync(paths.invoice, asset.invoice, { mode: 0o600 });
  if (asset.qrPng.length > 0) {
    writeFileSync(paths.qr, asset.qrPng, { mode: 0o600 });
  }
  writeFileSync(
    paths.metadata,
    JSON.stringify({ createdAt: asset.createdAt }),
    { mode: 0o600 },
  );
};

const cleanupPaymentAssets = () => {
  const cutoff = Date.now() - maxAgeMs;
  for (const [id, asset] of paymentAssets) {
    if (asset.createdAt < cutoff) {
      paymentAssets.delete(id);
    }
  }
  if (!existsSync(paymentAssetDir)) {
    return;
  }
  for (const name of readdirSync(paymentAssetDir)) {
    const match = /^([0-9a-f-]{36})\.(?:json|png|txt)$/i.exec(name);
    if (!match) {
      continue;
    }
    const id = match[1];
    const asset = readDiskAsset(id);
    if (!asset || asset.createdAt < cutoff) {
      const paths = assetPaths(id);
      rmSync(paths.invoice, { force: true });
      rmSync(paths.metadata, { force: true });
      rmSync(paths.qr, { force: true });
    }
  }
};

export const storeQrTextAsset = (
  qrImage: string | null,
  text: string,
): { id: string; qrUrlPath?: string; textUrlPath: string } => {
  cleanupPaymentAssets();
  const id = randomUUID();
  const match = qrImage ? /^data:image\/png;base64,(.+)$/i.exec(qrImage) : null;
  const asset = {
    invoice: text,
    qrPng: Buffer.from(match?.[1] ?? "", "base64"),
    createdAt: Date.now(),
  };
  paymentAssets.set(id, asset);
  writeDiskAsset(id, asset);
  return {
    id,
    qrUrlPath: match ? `/assets/payment-qr/${id}.png` : undefined,
    textUrlPath: `/assets/qr-text/${id}.txt`,
  };
};

export const storePaymentAsset = (
  qrImage: string | null,
  invoice: string,
): { id: string; qrUrlPath?: string; invoiceUrlPath: string } => {
  const asset = storeQrTextAsset(qrImage, invoice);
  return {
    id: asset.id,
    qrUrlPath: asset.qrUrlPath,
    invoiceUrlPath: `/assets/payment-invoice/${asset.id}.txt`,
  };
};

export const getPaymentAsset = (id: string): PaymentAsset | undefined => {
  cleanupPaymentAssets();
  const memoryAsset = paymentAssets.get(id);
  if (memoryAsset) {
    return memoryAsset;
  }
  const diskAsset = readDiskAsset(id);
  if (diskAsset) {
    paymentAssets.set(id, diskAsset);
  }
  return diskAsset;
};

export const listPaymentAssets = (): PaymentAssetListItem[] => {
  cleanupPaymentAssets();
  ensurePaymentAssetDir();
  const ids = new Set<string>(paymentAssets.keys());
  for (const name of readdirSync(paymentAssetDir)) {
    const match = /^([0-9a-f-]{36})\.json$/i.exec(name);
    if (match) {
      ids.add(match[1]);
    }
  }

  const items: PaymentAssetListItem[] = [];
  for (const id of ids) {
    const asset = getPaymentAsset(id);
    if (!asset) {
      continue;
    }
    const expiresAt = asset.createdAt + maxAgeMs;
    const item: PaymentAssetListItem = {
      id,
      createdAt: new Date(asset.createdAt).toISOString(),
      expiresAt: new Date(expiresAt).toISOString(),
      ageMs: Math.max(0, Date.now() - asset.createdAt),
      qrBytes: asset.qrPng.length,
      textBytes: Buffer.byteLength(asset.invoice),
      invoiceBytes: Buffer.byteLength(asset.invoice),
      textUrlPath: `/assets/qr-text/${id}.txt`,
      invoiceUrlPath: `/assets/payment-invoice/${id}.txt`,
    };
    if (asset.qrPng.length > 0) {
      item.qrUrlPath = `/assets/payment-qr/${id}.png`;
    }
    items.push(item);
  }
  return items.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
};
