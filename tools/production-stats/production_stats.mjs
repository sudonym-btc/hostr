#!/usr/bin/env node

const RELAY = "wss://relay.hostr.network";
const RPC = "https://arb1.arbitrum.io/rpc";
const CHAIN_ID = 42161;
const ESCROW = "0xdb591e79BF14112Ff5CC606585221022b2fB64fa";
const ESCROW_PUBKEY = "807dbcdedc31a47cea61e7331e691df29320506a245eb5df89ff54b7c4f09cec";
const KINDS = {
  profile: 0,
  textNote: 1,
  contacts: 3,
  repost: 6,
  reaction: 7,
  badgeAward: 8,
  seal: 13,
  dm: 14,
  seenStatus: 16,
  nip65: 10002,
  giftWrap: 1059,
  zapRequest: 9734,
  zapReceipt: 9735,
  heartbeat: 10017,
  typing: 10018,
  nwcInfo: 13194,
  nwcRequest: 23194,
  nwcResponse: 23195,
  nwcNotification: 23196,
  profileBadges: 30008,
  badgeDefinition: 30009,
  seenMessages: 30010,
  escrowTrust: 30300,
  escrowMethod: 30301,
  escrowSelected: 30302,
  escrowService: 30303,
  listing: 32121,
  reservation: 32122,
  review: 32124,
  reservationTransition: 32126,
};

const KIND_LABELS = new Map(Object.entries(KINDS).map(([k, v]) => [v, k]));
const HOSTR_KINDS = [
  KINDS.listing,
  KINDS.reservation,
  KINDS.review,
  KINDS.reservationTransition,
  KINDS.escrowService,
  KINDS.escrowTrust,
  KINDS.escrowMethod,
  KINDS.escrowSelected,
  KINDS.giftWrap,
  KINDS.seal,
  KINDS.seenStatus,
  KINDS.heartbeat,
  KINDS.typing,
  KINDS.seenMessages,
  KINDS.badgeAward,
  KINDS.badgeDefinition,
  KINDS.profileBadges,
];

const EVENT_TOPICS = {
  TradeCreated: "0xfd8752e4e049ee02b8549097455a8a38b6efe978ff5e89e91760cc6cd9c33073",
  Arbitrated: "0x04e2ff8542352e4f8e62c6deb046b9feb94d4b5dcd073d65ca2bca9700f91a73",
  Claimed: "0xb763f92e82e910990fe3838dcc63b5da01a54f37c07ced5384f1297294b332bd",
  ReleasedToCounterparty: "0x07ef9f79b306ce9a89bf8e1f834a172a0a005ac528a32962db99b24acb9933ab",
  Withdrawn: "0xa4195c37c2947bbe89165f03e320b6903116f0b10d8cfdb522330f7ce6f9fa24",
};

const TOKENS = {
  "0x0000000000000000000000000000000000000000": { symbol: "ETH", decimals: 18 },
  "0x6c84a8f1c29108f47a79964b5fe888d4f4d0de40": { symbol: "tBTC", decimals: 18 },
  "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9": { symbol: "USDT", decimals: 6 },
};

const now = new Date();
const daySeconds = 86400;
const days = 30;
const weeks = 8;

function die(section, msg) {
  console.log(`# Production Stats\n\n## ERROR\n\n${section}: ${msg}`);
  process.exit(0);
}

function unix(d) {
  return Math.floor(d.getTime() / 1000);
}

function dayStart(d) {
  return new Date(Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()));
}

function addDays(d, n) {
  const x = new Date(d);
  x.setUTCDate(x.getUTCDate() + n);
  return x;
}

function isoDay(ts) {
  return new Date(ts * 1000).toISOString().slice(0, 10);
}

function weekStart(d) {
  const x = dayStart(d);
  const day = x.getUTCDay() || 7;
  x.setUTCDate(x.getUTCDate() - day + 1);
  return x;
}

function weekLabel(d) {
  return d.toISOString().slice(0, 10);
}

function mermaidString(s) {
  return String(s).replace(/\\/g, "\\\\").replace(/"/g, '\\"');
}

function chartMax(values) {
  const max = Math.max(0, ...values);
  if (max <= 0) return 1;
  return Math.max(1, Math.ceil(max * 1.15));
}

function amountChartMax(values) {
  const max = Math.max(0, ...values);
  if (max <= 0) return 1;
  if (max < 1) return Number((max * 1.15).toPrecision(6));
  return Math.max(1, Math.ceil(max * 1.15));
}

function chartNumber(n) {
  return Number(n).toLocaleString("en-US", { useGrouping: false, maximumSignificantDigits: 12 });
}

function tagsOf(ev, name) {
  return (ev.tags || []).filter((t) => t[0] === name).map((t) => t[1]).filter(Boolean);
}

function hasTag(ev, name, value) {
  return tagsOf(ev, name).includes(value);
}

function normalizeAddressTopic(topic) {
  return `0x${topic.slice(-40)}`.toLowerCase();
}

function hexToBigInt(hex) {
  if (!hex || hex === "0x") return 0n;
  return BigInt(hex);
}

function word(data, i) {
  return `0x${data.slice(2 + i * 64, 2 + (i + 1) * 64)}`;
}

function fmtUnits(v, decimals) {
  const neg = v < 0n;
  const x = neg ? -v : v;
  const base = 10n ** BigInt(decimals);
  const whole = x / base;
  const frac = x % base;
  const fracStr = frac.toString().padStart(decimals, "0").slice(0, Math.min(decimals, 6)).replace(/0+$/, "");
  return `${neg ? "-" : ""}${whole.toString()}${fracStr ? `.${fracStr}` : ""}`;
}

function tokenInfo(addr) {
  return TOKENS[(addr || "").toLowerCase()] || { symbol: addr.slice(0, 10), decimals: 18 };
}

function addAmount(bucket, status, token, amount) {
  const key = `${status}:${token.toLowerCase()}`;
  bucket[key] = (bucket[key] || 0n) + amount;
}

function parseZapMsat(ev) {
  const desc = (ev.tags || []).find((t) => t[0] === "description")?.[1];
  if (!desc) return 0n;
  try {
    const req = JSON.parse(desc);
    const amount = (req.tags || []).find((t) => t[0] === "amount")?.[1];
    return amount ? BigInt(amount) : 0n;
  } catch {
    return 0n;
  }
}

const BECH32 = "qpzry9x8gf2tvdw0s3jn54khce6mua7l";
function bech32Decode(bech) {
  const s = bech.toLowerCase();
  const pos = s.lastIndexOf("1");
  if (pos < 1) throw new Error(`invalid bech32: ${bech}`);
  const hrp = s.slice(0, pos);
  const words = [...s.slice(pos + 1)].map((c) => {
    const v = BECH32.indexOf(c);
    if (v < 0) throw new Error(`invalid bech32 char ${c}`);
    return v;
  });
  let acc = 0, bits = 0;
  const out = [];
  for (const value of words.slice(0, -6)) {
    acc = (acc << 5) | value;
    bits += 5;
    while (bits >= 8) {
      bits -= 8;
      out.push((acc >> bits) & 0xff);
    }
  }
  return { hrp, hex: Buffer.from(out).toString("hex") };
}

const HOSTR_SOCIAL_HEX = (() => {
  const fromEnv = process.env.HOSTR_SOCIAL_NPUB;
  const npub = fromEnv || "npub1ltsyzs4ldxjr8n60dgg27ap4d4rzgsdyrmx4dh3tk3e2csyrtzws87qksx";
  return bech32Decode(npub).hex;
})();

function relaySend(message, { timeoutMs = 45000 } = {}) {
  return new Promise((resolve, reject) => {
    const ws = new WebSocket(RELAY);
    const events = [];
    let count = null;
    const subId = message[1];
    const timer = setTimeout(() => {
      try { ws.close(); } catch {}
      reject(new Error(`timeout waiting for ${message[0]} ${subId}`));
    }, timeoutMs);
    ws.onopen = () => ws.send(JSON.stringify(message));
    ws.onerror = () => {
      clearTimeout(timer);
      reject(new Error(`cannot connect to ${RELAY}`));
    };
    ws.onmessage = (raw) => {
      let msg;
      try { msg = JSON.parse(raw.data); } catch { return; }
      if (msg[0] === "EVENT" && msg[1] === subId) events.push(msg[2]);
      if (msg[0] === "COUNT" && msg[1] === subId) {
        count = Number(msg[2]?.count ?? 0);
        clearTimeout(timer);
        ws.close();
        resolve({ count, events });
      }
      if (msg[0] === "EOSE" && msg[1] === subId) {
        clearTimeout(timer);
        ws.send(JSON.stringify(["CLOSE", subId]));
        ws.close();
        resolve({ count, events });
      }
      if (msg[0] === "CLOSED" && msg[1] === subId) {
        clearTimeout(timer);
        ws.close();
        reject(new Error(msg[2] || `relay closed ${subId}`));
      }
    };
  });
}

let seq = 0;
async function countFilter(filter) {
  const id = `c${++seq}`;
  try {
    const out = await relaySend(["COUNT", id, filter], { timeoutMs: 25000 });
    if (Number.isFinite(out.count)) return out.count;
  } catch {
    // fall through to REQ for relays without NIP-45 COUNT
  }
  const out = await relaySend(["REQ", id, filter], { timeoutMs: 45000 });
  return out.events.length;
}

async function eventsFilter(filter, timeoutMs = 45000) {
  const id = `e${++seq}`;
  return (await relaySend(["REQ", id, filter], { timeoutMs })).events;
}

async function eventsFilters(filters, timeoutMs = 45000) {
  const id = `e${++seq}`;
  return (await relaySend(["REQ", id, ...filters], { timeoutMs })).events;
}

async function rpc(method, params) {
  const res = await fetch(RPC, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ jsonrpc: "2.0", id: ++seq, method, params }),
  });
  if (!res.ok) throw new Error(`${method} HTTP ${res.status}`);
  const json = await res.json();
  if (json.error) throw new Error(`${method}: ${json.error.message}`);
  return json.result;
}

async function ethCall(data, block = "latest") {
  return rpc("eth_call", [{ to: ESCROW, data }, block]);
}

function encodeAddress(addr) {
  return addr.toLowerCase().replace(/^0x/, "").padStart(64, "0");
}

async function getLogsChunked(fromBlock, toBlock) {
  try {
    return await rpc("eth_getLogs", [{
      address: ESCROW,
      fromBlock: `0x${fromBlock.toString(16)}`,
      toBlock: `0x${toBlock.toString(16)}`,
      topics: [[...Object.values(EVENT_TOPICS)]],
    }]);
  } catch {
    // Fall back to smaller ranges if the RPC rejects a full indexed scan.
  }
  const logs = [];
  let from = fromBlock;
  let step = 100000;
  while (from <= toBlock) {
    const to = Math.min(toBlock, from + step - 1);
    try {
      const part = await rpc("eth_getLogs", [{
        address: ESCROW,
        fromBlock: `0x${from.toString(16)}`,
        toBlock: `0x${to.toString(16)}`,
        topics: [[...Object.values(EVENT_TOPICS)]],
      }]);
      logs.push(...part);
      from = to + 1;
      if (part.length === 0 && step < 500000) step *= 2;
    } catch (e) {
      if (step <= 1000) throw e;
      step = Math.floor(step / 2);
    }
  }
  return logs;
}

const blockTimeCache = new Map();
async function blockTimestamp(blockHex) {
  if (!blockTimeCache.has(blockHex)) {
    const b = await rpc("eth_getBlockByNumber", [blockHex, false]);
    blockTimeCache.set(blockHex, Number.parseInt(b.timestamp, 16));
  }
  return blockTimeCache.get(blockHex);
}

function decodeEscrowLog(log) {
  const topic0 = log.topics[0].toLowerCase();
  const data = log.data;
  if (topic0 === EVENT_TOPICS.TradeCreated) {
    const token = normalizeAddressTopic(log.topics[2]);
    return { type: "in_progress_opened", token, amount: hexToBigInt(word(data, 2)) + hexToBigInt(word(data, 3)) };
  }
  if (topic0 === EVENT_TOPICS.Arbitrated) {
    const token = normalizeAddressTopic(log.topics[2]);
    return { type: "arbitrated", token, amount: hexToBigInt(word(data, 2)) + hexToBigInt(word(data, 3)) };
  }
  if (topic0 === EVENT_TOPICS.Claimed) {
    const token = normalizeAddressTopic(log.topics[2]);
    return { type: "claimed", token, amount: hexToBigInt(word(data, 2)) + hexToBigInt(word(data, 3)) };
  }
  if (topic0 === EVENT_TOPICS.ReleasedToCounterparty) {
    const token = normalizeAddressTopic(log.topics[2]);
    return { type: "released", token, amount: hexToBigInt(word(data, 2)) };
  }
  if (topic0 === EVENT_TOPICS.Withdrawn) {
    const token = normalizeAddressTopic(log.topics[2]);
    return { type: "withdrawn", token, amount: hexToBigInt(word(data, 1)) };
  }
  return null;
}

async function relayStats() {
  const today = dayStart(now);
  const dailyStart = addDays(today, -days + 1);
  const weeklyStart = addDays(weekStart(today), -(weeks - 1) * 7);

  const allKinds = [...new Set([...HOSTR_KINDS, KINDS.profile, KINDS.nip65, KINDS.zapReceipt])];
  const allEvents = await eventsFilter({ kinds: allKinds }, 120000);
  const recentEvents = allEvents.filter((e) => e.created_at >= unix(dailyStart) && e.created_at < unix(addDays(today, 1)));
  const countKind = (kind, source = allEvents) => source.filter((e) => e.kind === kind).length;
  const countKinds = (kinds, source = allEvents) => source.filter((e) => kinds.includes(e.kind)).length;
  const totals = {
    listing: countKind(KINDS.listing),
    reservation: countKind(KINDS.reservation),
    userProfiles: countKind(KINDS.profile),
    uniqueProfileAuthors: new Set(allEvents.filter((e) => e.kind === KINDS.profile).map((e) => e.pubkey)).size,
    nip65: countKind(KINDS.nip65),
    giftwrap: countKind(KINDS.giftWrap),
    hostrDomain: countKinds(HOSTR_KINDS),
    escrowService: countKind(KINDS.escrowService),
    escrowMethod: countKind(KINDS.escrowMethod),
    escrowTrust: countKind(KINDS.escrowTrust),
    reviews: countKind(KINDS.review),
    badges: countKind(KINDS.badgeAward),
    zaps: countKind(KINDS.zapReceipt),
  };
  totals.recentUniqueAuthors = new Set(recentEvents.map((e) => e.pubkey)).size;

  const daily = [];
  for (let i = 0; i < days; i++) {
    const d = addDays(dailyStart, i);
    const since = unix(d);
    const until = since + daySeconds;
    const row = { label: d.toISOString().slice(0, 10) };
    const slice = allEvents.filter((e) => e.created_at >= since && e.created_at < until);
    row.listings = countKind(KINDS.listing, slice);
    row.reservations = countKind(KINDS.reservation, slice);
    row.users = countKind(KINDS.profile, slice);
    row.nip65 = countKind(KINDS.nip65, slice);
    row.giftwrap = countKind(KINDS.giftWrap, slice);
    row.domain = countKinds(HOSTR_KINDS, slice);
    daily.push(row);
  }

  const weekly = [];
  for (let i = 0; i < weeks; i++) {
    const d = addDays(weeklyStart, i * 7);
    const since = unix(d);
    const until = since + 7 * daySeconds;
    const slice = allEvents.filter((e) => e.created_at >= since && e.created_at < until);
    weekly.push({
      label: weekLabel(d),
      listings: countKind(KINDS.listing, slice),
      reservations: countKind(KINDS.reservation, slice),
      users: countKind(KINDS.profile, slice),
      nip65: countKind(KINDS.nip65, slice),
      giftwrap: countKind(KINDS.giftWrap, slice),
      domain: countKinds(HOSTR_KINDS, slice),
    });
  }

  const byKind = {};
  for (const kind of HOSTR_KINDS) byKind[KIND_LABELS.get(kind)] = countKind(kind);

  return { totals, daily, weekly, byKind };
}

async function escrowServiceStats() {
  const events = await eventsFilter({ kinds: [KINDS.escrowService], authors: [ESCROW_PUBKEY], limit: 5 }, 30000);
  const latest = events.sort((a, b) => b.created_at - a.created_at)[0];
  let service = {};
  if (latest) {
    try { service = JSON.parse(latest.content || "{}"); } catch {}
  }
  const giftwrapsReceived = (await eventsFilter({ kinds: [KINDS.giftWrap], "#p": [ESCROW_PUBKEY] }, 60000)).length;
  return { latest, service, giftwrapsReceived };
}

async function evmStats() {
  const chainHex = await rpc("eth_chainId", []);
  const chainId = Number.parseInt(chainHex, 16);
  if (chainId !== CHAIN_ID) throw new Error(`expected chainId ${CHAIN_ID}, got ${chainId}`);
  const latest = Number.parseInt(await rpc("eth_blockNumber", []), 16);
  const activeTradeCount = Number(hexToBigInt(await ethCall("0xcedc4478")));
  const pending = {};
  for (const [addr, info] of Object.entries(TOKENS)) {
    const raw = hexToBigInt(await ethCall(`0xc1b64f74${encodeAddress(addr)}`));
    if (raw > 0n) pending[info.symbol] = fmtUnits(raw, info.decimals);
  }
  const logs = await getLogsChunked(0, latest);
  const deployBlock = logs.length
    ? Math.min(...logs.map((log) => Number.parseInt(log.blockNumber, 16)))
    : null;
  const daily = {};
  const weekly = {};
  const totals = {};
  const counts = {};
  for (const log of logs) {
    const decoded = decodeEscrowLog(log);
    if (!decoded) continue;
    const ts = await blockTimestamp(log.blockNumber);
    const d = isoDay(ts);
    const w = weekLabel(weekStart(new Date(ts * 1000)));
    daily[d] ||= {};
    weekly[w] ||= {};
    addAmount(daily[d], decoded.type, decoded.token, decoded.amount);
    addAmount(weekly[w], decoded.type, decoded.token, decoded.amount);
    addAmount(totals, decoded.type, decoded.token, decoded.amount);
    counts[decoded.type] = (counts[decoded.type] || 0) + 1;
  }
  return { latest, deployBlock, activeTradeCount, pending, logsCount: logs.length, totals, counts, daily, weekly };
}

async function socialStats() {
  const today = dayStart(now);
  const dailyStart = addDays(today, -days + 1);
  const weeklyStart = addDays(weekStart(today), -(weeks - 1) * 7);

  const since90 = unix(addDays(today, -90));
  const socialEvents = await eventsFilters([
    { kinds: [KINDS.textNote], authors: [HOSTR_SOCIAL_HEX], since: since90 },
    { kinds: [KINDS.contacts, KINDS.repost, KINDS.reaction, KINDS.textNote, KINDS.zapReceipt, KINDS.giftWrap, KINDS.dm], "#p": [HOSTR_SOCIAL_HEX], since: since90 },
    { kinds: [KINDS.dm], authors: [HOSTR_SOCIAL_HEX], since: since90 },
  ], 90000);
  const posts = socialEvents.filter((e) => e.kind === KINDS.textNote && e.pubkey === HOSTR_SOCIAL_HEX);
  const postIds = posts.map((e) => e.id);
  const recentPostIds = postIds.slice(0, 1000);
  const pTagged = (kind) => socialEvents.filter((e) => e.kind === kind && hasTag(e, "p", HOSTR_SOCIAL_HEX));
  const reactions = pTagged(KINDS.reaction).length;
  const comments = pTagged(KINDS.textNote).filter((e) => e.pubkey !== HOSTR_SOCIAL_HEX).length;
  const reposts = pTagged(KINDS.repost).length;
  const followEvents = pTagged(KINDS.contacts);
  const followAuthors = new Set(followEvents.map((e) => e.pubkey)).size;
  const zaps = pTagged(KINDS.zapReceipt);
  const receivedGw = pTagged(KINDS.giftWrap).length;
  const sentLegacy = socialEvents.filter((e) => e.kind === KINDS.dm && e.pubkey === HOSTR_SOCIAL_HEX).length;
  const receivedLegacy = pTagged(KINDS.dm).length;
  const postEngagement = recentPostIds.length
    ? socialEvents.filter((e) => [KINDS.repost, KINDS.reaction, KINDS.textNote, KINDS.zapReceipt].includes(e.kind) && tagsOf(e, "e").some((id) => recentPostIds.includes(id))).length
    : 0;
  const zapMsat = zaps.reduce((sum, ev) => sum + parseZapMsat(ev), 0n);

  const daily = [];
  for (let i = 0; i < days; i++) {
    const d = addDays(dailyStart, i);
    const since = unix(d);
    const until = since + daySeconds;
    const slice = socialEvents.filter((e) => e.created_at >= since && e.created_at < until);
    const sliceP = (kind) => slice.filter((e) => e.kind === kind && hasTag(e, "p", HOSTR_SOCIAL_HEX));
    const zapEvents = sliceP(KINDS.zapReceipt);
    daily.push({
      label: d.toISOString().slice(0, 10),
      posts: slice.filter((e) => e.kind === KINDS.textNote && e.pubkey === HOSTR_SOCIAL_HEX).length,
      reactions: sliceP(KINDS.reaction).length,
      comments: sliceP(KINDS.textNote).filter((e) => e.pubkey !== HOSTR_SOCIAL_HEX).length,
      reposts: sliceP(KINDS.repost).length,
      follows: new Set(sliceP(KINDS.contacts).map((e) => e.pubkey)).size,
      zaps: zapEvents.length,
      zapMsat: zapEvents.reduce((sum, ev) => sum + parseZapMsat(ev), 0n),
      dmReceivedGiftwrap: sliceP(KINDS.giftWrap).length,
      dmSentLegacy: slice.filter((e) => e.kind === KINDS.dm && e.pubkey === HOSTR_SOCIAL_HEX).length,
      dmReceivedLegacy: sliceP(KINDS.dm).length,
    });
  }

  const weekly = [];
  for (let i = 0; i < weeks; i++) {
    const d = addDays(weeklyStart, i * 7);
    const since = unix(d);
    const until = since + 7 * daySeconds;
    const slice = socialEvents.filter((e) => e.created_at >= since && e.created_at < until);
    const sliceP = (kind) => slice.filter((e) => e.kind === kind && hasTag(e, "p", HOSTR_SOCIAL_HEX));
    const zapEvents = sliceP(KINDS.zapReceipt);
    weekly.push({
      label: weekLabel(d),
      posts: slice.filter((e) => e.kind === KINDS.textNote && e.pubkey === HOSTR_SOCIAL_HEX).length,
      reactions: sliceP(KINDS.reaction).length,
      comments: sliceP(KINDS.textNote).filter((e) => e.pubkey !== HOSTR_SOCIAL_HEX).length,
      reposts: sliceP(KINDS.repost).length,
      follows: new Set(sliceP(KINDS.contacts).map((e) => e.pubkey)).size,
      zaps: zapEvents.length,
      zapMsat: zapEvents.reduce((sum, ev) => sum + parseZapMsat(ev), 0n),
      dmReceivedGiftwrap: sliceP(KINDS.giftWrap).length,
      dmSentLegacy: slice.filter((e) => e.kind === KINDS.dm && e.pubkey === HOSTR_SOCIAL_HEX).length,
      dmReceivedLegacy: sliceP(KINDS.dm).length,
    });
  }

  return {
    pubkey: HOSTR_SOCIAL_HEX,
    totals: {
      posts90d: posts.length,
      postEngagement90d: postEngagement,
      reactions90d: reactions,
      comments90d: comments,
      reposts90d: reposts,
      followEvents90d: followEvents.length,
      uniqueFollowAuthors90d: followAuthors,
      zaps90d: zaps.length,
      zapSats90d: Number(zapMsat / 1000n),
      dmReceivedGiftwrap90d: receivedGw,
      dmSentLegacy90d: sentLegacy,
      dmReceivedLegacy90d: receivedLegacy,
    },
    daily,
    weekly,
  };
}

function mdTable(rows, headers) {
  const out = [];
  out.push(`| ${headers.join(" | ")} |`);
  out.push(`| ${headers.map(() => "---").join(" | ")} |`);
  for (const row of rows) out.push(`| ${headers.map((h) => row[h] ?? "").join(" | ")} |`);
  return out.join("\n");
}

function renderTrend(rows, fields, title) {
  const totals = rows.map((r) => fields.reduce((s, f) => s + Number(r[f] || 0), 0));
  const labels = rows.map((r) => r.label);
  const lines = [
    `### ${title}`,
    "",
    "```mermaid",
    "xychart-beta",
    `    title "${mermaidString(title)}"`,
    `    x-axis [${labels.map((label) => `"${mermaidString(label)}"`).join(", ")}]`,
    `    y-axis "Events" 0 --> ${chartMax(totals)}`,
    `    bar [${totals.join(", ")}]`,
    "```",
    "",
    "| Period | " + fields.join(" | ") + " | total |",
    "| --- | " + fields.map(() => "---").join(" | ") + " | --- |",
  ];
  for (let i = 0; i < rows.length; i++) {
    const r = rows[i];
    lines.push(`| ${r.label} | ${fields.map((f) => r[f] ?? 0).join(" | ")} | ${totals[i]} |`);
  }
  return lines.join("\n");
}

function renderLineSeriesTrend(rows, series, title) {
  const labels = rows.map((r) => r.label);
  const valuesBySeries = series.map((s) => ({
    ...s,
    values: rows.map((r) => Number(r[s.key] || 0)),
  }));
  const lines = [`### ${title}`];
  for (const s of valuesBySeries) {
    lines.push(
      "",
      "```mermaid",
      "xychart-beta",
      `    title "${mermaidString(`${title}: ${s.label}`)}"`,
      `    x-axis [${labels.map((label) => `"${mermaidString(label)}"`).join(", ")}]`,
      `    y-axis "Events" 0 --> ${chartMax(s.values)}`,
      `    line [${s.values.join(", ")}]`,
      "```",
    );
  }
  lines.push(
    "",
    "| Period | " + series.map((s) => s.label).join(" | ") + " | total |",
    "| --- | " + series.map(() => "---").join(" | ") + " | --- |",
  );
  for (const r of rows) {
    const values = series.map((s) => Number(r[s.key] || 0));
    lines.push(`| ${r.label} | ${values.join(" | ")} | ${values.reduce((a, b) => a + b, 0)} |`);
  }
  return lines.join("\n");
}

function renderAmountMap(map) {
  const rows = [];
  for (const [key, amount] of Object.entries(map)) {
    const [status, token] = key.split(":");
    const info = tokenInfo(token);
    rows.push({ Status: status, Token: info.symbol, Amount: fmtUnits(amount, info.decimals) });
  }
  return rows.length ? mdTable(rows, ["Status", "Token", "Amount"]) : "_No escrow token events found._";
}

function renderAmountTrend(map, title) {
  const periods = Object.keys(map).sort().slice(-12);
  const tokenKeys = [...new Set(periods.flatMap((p) => Object.keys(map[p] || {}).map((key) => key.split(":")[1])))].sort();
  const lines = [`### ${title}`];
  for (const token of tokenKeys) {
    const info = tokenInfo(token);
    const rawValues = periods.map((p) => Object.entries(map[p] || {})
      .filter(([key]) => key.split(":")[1] === token)
      .reduce((sum, [, amount]) => sum + amount, 0n));
    const values = rawValues.map((amount) => Number.parseFloat(fmtUnits(amount, info.decimals)));
    lines.push(
      "",
      "```mermaid",
      "xychart-beta",
      `    title "${mermaidString(`${title}: ${info.symbol} Total Volume`)}"`,
      `    x-axis [${periods.map((label) => `"${mermaidString(label)}"`).join(", ")}]`,
      `    y-axis "${mermaidString(info.symbol)}" 0 --> ${chartNumber(amountChartMax(values))}`,
      `    bar [${values.map(chartNumber).join(", ")}]`,
      "```",
    );
  }
  lines.push("", "| Period | Token | Total Volume |", "| --- | --- | --- |");
  for (const p of periods) {
    const tokenAmounts = tokenKeys.map((token) => ({
      token,
      amount: Object.entries(map[p] || {})
        .filter(([key]) => key.split(":")[1] === token)
        .reduce((sum, [, amount]) => sum + amount, 0n),
    }));
    if (!tokenAmounts.length) {
      lines.push(`| ${p} | - | 0 |`);
      continue;
    }
    for (const { token, amount } of tokenAmounts) {
      const info = tokenInfo(token);
      lines.push(`| ${p} | ${info.symbol} | ${fmtUnits(amount, info.decimals)} |`);
    }
  }
  return lines.join("\n");
}

const SOCIAL_TREND_SERIES = [
  { key: "posts", label: "posts" },
  { key: "reactions", label: "reactions" },
  { key: "comments", label: "comments" },
  { key: "reposts", label: "reposts" },
  { key: "follows", label: "follows" },
  { key: "zaps", label: "zaps" },
  { key: "dmReceivedGiftwrap", label: "giftwrap DMs received" },
  { key: "dmSentLegacy", label: "legacy DMs sent" },
  { key: "dmReceivedLegacy", label: "legacy DMs received" },
];

function renderReport(relay, escrowSvc, evm, social) {
  const lines = [];
  lines.push("# Production Stats");
  lines.push("");
  lines.push(`Generated: ${now.toISOString()}`);
  lines.push("");
  lines.push("Sources: production relay `wss://relay.hostr.network`; production Arbitrum RPC `https://arb1.arbitrum.io/rpc`; chainId `42161`; MultiEscrow `0xdb591e79BF14112Ff5CC606585221022b2fB64fa`.");
  lines.push("");
  lines.push("## Relay Totals");
  lines.push("");
  lines.push(mdTable([
    { Metric: "Listings", Count: relay.totals.listing },
    { Metric: "Reservations", Count: relay.totals.reservation },
    { Metric: "User profile events", Count: relay.totals.userProfiles },
    { Metric: "Unique profile authors", Count: relay.totals.uniqueProfileAuthors },
    { Metric: "Recent unique authors, 30d", Count: relay.totals.recentUniqueAuthors },
    { Metric: "NIP-65 relay lists", Count: relay.totals.nip65 },
    { Metric: "Giftwraps", Count: relay.totals.giftwrap },
    { Metric: "Hostr domain events", Count: relay.totals.hostrDomain },
    { Metric: "Escrow services", Count: relay.totals.escrowService },
    { Metric: "Escrow methods", Count: relay.totals.escrowMethod },
    { Metric: "Escrow trust", Count: relay.totals.escrowTrust },
    { Metric: "Reviews", Count: relay.totals.reviews },
    { Metric: "Badge awards", Count: relay.totals.badges },
    { Metric: "Zap receipts", Count: relay.totals.zaps },
  ], ["Metric", "Count"]));
  lines.push("");
  lines.push(renderTrend(relay.weekly, ["listings", "reservations", "users", "nip65", "giftwrap"], "Weekly Relay Trend"));
  lines.push("");
  lines.push(renderTrend(relay.daily.slice(-14), ["listings", "reservations", "users", "nip65", "giftwrap"], "Daily Relay Trend (last 14 days)"));
  lines.push("");
  lines.push("### Hostr Kind Breakdown");
  lines.push("");
  lines.push(mdTable(Object.entries(relay.byKind).map(([Kind, Count]) => ({ Kind, Count })), ["Kind", "Count"]));
  lines.push("");
  lines.push("## Escrow Relay");
  lines.push("");
  lines.push(mdTable([
    { Metric: "Escrow Nostr pubkey", Value: ESCROW_PUBKEY },
    { Metric: "Escrow service event", Value: escrowSvc.latest ? `${escrowSvc.latest.id.slice(0, 12)}... @ ${new Date(escrowSvc.latest.created_at * 1000).toISOString()}` : "not found" },
    { Metric: "Service EVM address", Value: escrowSvc.service.evmAddress || escrowSvc.service.evm_address || "not found in service content" },
    { Metric: "Giftwraps received by escrow pubkey", Value: escrowSvc.giftwrapsReceived },
  ], ["Metric", "Value"]));
  lines.push("");
  lines.push("## Escrow On-Chain");
  lines.push("");
  lines.push(mdTable([
    { Metric: "Arbitrum latest block", Value: evm.latest },
    { Metric: "First escrow event block", Value: evm.deployBlock ?? "no logs" },
    { Metric: "Escrow logs scanned", Value: evm.logsCount },
    { Metric: "Current active trades", Value: evm.activeTradeCount },
    { Metric: "Current pending withdrawals", Value: Object.entries(evm.pending).map(([k, v]) => `${v} ${k}`).join(", ") || "0" },
    { Metric: "Created/opened events", Value: evm.counts.in_progress_opened || 0 },
    { Metric: "Arbitrated events", Value: evm.counts.arbitrated || 0 },
    { Metric: "Claimed events", Value: evm.counts.claimed || 0 },
    { Metric: "Released events", Value: evm.counts.released || 0 },
    { Metric: "Withdrawn events", Value: evm.counts.withdrawn || 0 },
  ], ["Metric", "Value"]));
  lines.push("");
  lines.push("### Escrow Amount Totals");
  lines.push("");
  lines.push(renderAmountMap(evm.totals));
  lines.push("");
  lines.push(renderAmountTrend(evm.weekly, "Weekly Escrow Amount Trend"));
  lines.push("");
  lines.push(renderAmountTrend(evm.daily, "Daily Escrow Amount Trend"));
  lines.push("");
  lines.push("## Hostr Social Account");
  lines.push("");
  lines.push(`Account pubkey: \`${social.pubkey}\``);
  lines.push("");
  lines.push(mdTable([
    { Metric: "Posts, 90d", Count: social.totals.posts90d },
    { Metric: "Post engagements on recent posts, 90d", Count: social.totals.postEngagement90d },
    { Metric: "Reactions mentioning account, 90d", Count: social.totals.reactions90d },
    { Metric: "Comments mentioning account, 90d", Count: social.totals.comments90d },
    { Metric: "Reposts mentioning account, 90d", Count: social.totals.reposts90d },
    { Metric: "Follow-list events mentioning account, 90d", Count: social.totals.followEvents90d },
    { Metric: "Unique follow-list authors, 90d", Count: social.totals.uniqueFollowAuthors90d },
    { Metric: "Zap receipts, 90d", Count: social.totals.zaps90d },
    { Metric: "Zap sats parsed, 90d", Count: social.totals.zapSats90d },
    { Metric: "Giftwrap DMs received, 90d", Count: social.totals.dmReceivedGiftwrap90d },
    { Metric: "Legacy kind 14 DMs sent, 90d", Count: social.totals.dmSentLegacy90d },
    { Metric: "Legacy kind 14 DMs received, 90d", Count: social.totals.dmReceivedLegacy90d },
  ], ["Metric", "Count"]));
  lines.push("");
  lines.push("Note: NIP-59 giftwrap sender identity and sent-DM counts are not publicly queryable from relay metadata alone; received giftwraps are counted by `#p` tag from the production relay.");
  lines.push("");
  lines.push(renderLineSeriesTrend(social.weekly, SOCIAL_TREND_SERIES, "Weekly Social Trend"));
  lines.push("");
  lines.push(renderLineSeriesTrend(social.daily.slice(-14), SOCIAL_TREND_SERIES, "Daily Social Trend (last 14 days)"));
  return lines.join("\n");
}

async function main() {
  let relay, escrowSvc, evm, social;
  try {
    relay = await relayStats();
    escrowSvc = await escrowServiceStats();
    social = await socialStats();
  } catch (e) {
    die("Production relay unavailable", e.message);
  }
  try {
    evm = await evmStats();
  } catch (e) {
    die("Production Arbitrum unavailable", e.message);
  }
  console.log(renderReport(relay, escrowSvc, evm, social));
}

main().catch((e) => die("Unhandled error", e.stack || e.message));
