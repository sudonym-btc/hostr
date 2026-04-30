import fs from 'node:fs';
import path from 'node:path';

const distRoot = '/app/apps/signet/dist';
const rateLimitGuard =
  'if (process.env.SIGNET_DISABLE_RATE_LIMIT === "1") return { allowed: true };';
const deleteKeyCleanupSnippet =
  `    // Local e2e runs create and delete many temporary bunker keys. Upstream
    // Signet deletes the active key record without notifying the daemon, which
    // leaves the old NIP-46 relay subscription running until the process
    // eventually hits the relay subscription cap.
    if (isUnlocked && this.config.onKeyLocked) {
      this.config.onKeyLocked(keyName);
    }
`;

function* jsFiles(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      yield* jsFiles(fullPath);
    } else if (entry.isFile() && entry.name.endsWith('.js')) {
      yield fullPath;
    }
  }
}

let rateLimitPatched = 0;
let rateLimitAlreadyPatched = false;
let deleteKeyPatched = 0;
let deleteKeyAlreadyPatched = false;

for (const file of jsFiles(distRoot)) {
  const source = fs.readFileSync(file, 'utf8');
  let next = source;

  if (next.includes(rateLimitGuard)) {
    rateLimitAlreadyPatched = true;
  } else if (next.includes('checkRateLimit')) {
    next = next.replace(
      /(function\s+checkRateLimit\s*\([^)]*\)\s*\{)/,
      `$1\n    ${rateLimitGuard}`,
    );

    if (next !== source) {
      rateLimitPatched++;
    }
  }

  if (next.includes('Local e2e runs create and delete many temporary bunker keys')) {
    deleteKeyAlreadyPatched = true;
  } else if (
    next.includes('async deleteKey(keyName, passphrase)') &&
    next.includes('const isUnlocked = !!this.activeKeys[keyName];') &&
    next.includes('delete this.activeKeys[keyName];')
  ) {
    const beforeDeleteActiveKey =
      '    delete this.activeKeys[keyName];\n' +
      '    delete this.config.allKeys[keyName];';
    next = next.replace(
      beforeDeleteActiveKey,
      `${deleteKeyCleanupSnippet}${beforeDeleteActiveKey}`,
    );

    if (next !== source) {
      deleteKeyPatched++;
    }
  }

  if (next !== source) {
    fs.writeFileSync(file, next);
  }
}

if (rateLimitPatched === 0 && !rateLimitAlreadyPatched) {
  console.warn('[signet] rate-limit patch did not find checkRateLimit()');
} else {
  console.log(
    rateLimitPatched > 0
      ? `[signet] disabled REST API rate limiting in ${rateLimitPatched} file(s)`
      : '[signet] REST API rate limiting was already disabled',
  );
}

if (deleteKeyPatched === 0 && !deleteKeyAlreadyPatched) {
  console.warn('[signet] delete-key cleanup patch did not find target');
} else {
  console.log(
    deleteKeyPatched > 0
      ? `[signet] patched delete-key backend cleanup in ${deleteKeyPatched} file(s)`
      : '[signet] delete-key backend cleanup was already patched',
  );
}
