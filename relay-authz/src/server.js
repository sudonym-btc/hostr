import grpc from '@grpc/grpc-js';
import protoLoader from '@grpc/proto-loader';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

import {
  DEFAULT_ALLOWED_KINDS,
  Decision,
  decideEventAdmission,
  normalizeHex,
} from './policy.js';

const defaultAuthorMismatchKinds = [1059, 32122, 1326];
const defaultAuthOptionalKinds = [24133, 13194, 23194, 23195, 23196, 23197];

const __dirname = dirname(fileURLToPath(import.meta.url));
const protoPath = join(__dirname, '..', 'proto', 'nauthz.proto');

const packageDefinition = protoLoader.loadSync(protoPath, {
  bytes: Buffer,
  defaults: true,
  enums: Number,
  keepCase: false,
  longs: Number,
  oneofs: true,
});

const nauthz = grpc.loadPackageDefinition(packageDefinition).nauthz;
const host = process.env.RELAY_AUTHZ_HOST || '0.0.0.0';
const port = Number.parseInt(process.env.RELAY_AUTHZ_PORT || '50051', 10);
const requireAuthorMatch = parseBool(
  process.env.RELAY_AUTHZ_REQUIRE_AUTHOR_MATCH,
  true,
);
const authorMismatchKinds = parseKindList(
  process.env.RELAY_AUTHZ_AUTHOR_MISMATCH_KINDS,
  defaultAuthorMismatchKinds,
);
const authOptionalKinds = parseKindList(
  process.env.RELAY_AUTHZ_PUBLIC_WRITE_KINDS ??
    process.env.RELAY_AUTHZ_AUTH_OPTIONAL_KINDS,
  defaultAuthOptionalKinds,
);
const allowedKinds = parseKindList(
  process.env.RELAY_AUTHZ_ALLOWED_KINDS,
  DEFAULT_ALLOWED_KINDS,
);

function eventAdmit(call, callback) {
  const reply = decideEventAdmission(call.request, {
    allowedKinds,
    authorMismatchKinds,
    authOptionalKinds,
    requireAuthorMatch,
  });
  logDecision(call.request, reply);
  callback(null, reply);
}

function logDecision(request, reply) {
  const event = request?.event;
  const id = normalizeHex(event?.id).slice(0, 12) || '<missing>';
  const pubkey = normalizeHex(event?.pubkey).slice(0, 12) || '<missing>';
  const authPubkey = normalizeHex(
    request?.authPubkey ?? request?.auth_pubkey,
  ).slice(0, 12) || '<none>';
  const outcome = reply.decision === Decision.PERMIT ? 'permit' : 'deny';
  const reason = reply.message ? ` reason="${reply.message}"` : '';
  console.log(
    `event_admit ${outcome} id=${id} kind=${event?.kind ?? '<missing>'} pubkey=${pubkey} auth=${authPubkey}${reason}`,
  );
}

function parseBool(value, fallback) {
  if (value == null || value === '') return fallback;
  return ['1', 'true', 'yes', 'on'].includes(value.trim().toLowerCase());
}

const server = new grpc.Server();
server.addService(nauthz.Authorization.service, { eventAdmit });

const bindAddress = `${host}:${port}`;
server.bindAsync(bindAddress, grpc.ServerCredentials.createInsecure(), (err) => {
  if (err) {
    console.error(`failed to bind relay authz server on ${bindAddress}`, err);
    process.exit(1);
  }
  console.log(
    `relay authz listening on ${bindAddress}; requireAuthorMatch=${requireAuthorMatch}; allowedKinds=${[...allowedKinds].join(',')}; authorMismatchKinds=${[...authorMismatchKinds].join(',')}; authOptionalKinds=${[...authOptionalKinds].join(',')}`,
  );
});

function parseKindList(value, fallback) {
  const input = value == null || value === '' ? fallback : value.split(',');
  return new Set(
    input
      .map((item) => Number.parseInt(String(item).trim(), 10))
      .filter((item) => Number.isFinite(item)),
  );
}
