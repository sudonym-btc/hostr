// NIP-44 conversation key derivation using @noble/curves (secp256k1 ECDH)
// and @noble/hashes (HKDF-extract with SHA-256).
//
// Exposes a single global function consumed by Dart via JS interop:
//   window.nip44ConversationKey(privKeyHex, xOnlyPubKeyHex) → Uint8Array(32)

import { secp256k1 } from 'https://esm.sh/@noble/curves@1.8.2/secp256k1';
import { extract as hkdfExtract } from 'https://esm.sh/@noble/hashes@1.7.2/hkdf';
import { sha256 } from 'https://esm.sh/@noble/hashes@1.7.2/sha256';

/**
 * Computes the NIP-44 conversation key:
 *   shared_x = x_coord( privKey × pubKeyPoint )
 *   conv_key  = HKDF-extract(salt="nip44-v2", ikm=shared_x)
 *
 * @param {string} privKeyHex   – 64-char hex private key
 * @param {string} pubKeyHex    – 64-char hex x-only public key
 * @returns {Uint8Array}        – 32-byte conversation key
 */
function nip44ConversationKey(privKeyHex, pubKeyHex) {
  // getSharedSecret returns 33-byte compressed point (02 || x); strip prefix.
  const sharedPoint = secp256k1.getSharedSecret(privKeyHex, '02' + pubKeyHex);
  const sharedX = sharedPoint.subarray(1, 33);

  const salt = new TextEncoder().encode('nip44-v2');
  return hkdfExtract(sha256, sharedX, salt);
}

// Expose to Dart's globalContext / window.
globalThis.nip44ConversationKey = nip44ConversationKey;
