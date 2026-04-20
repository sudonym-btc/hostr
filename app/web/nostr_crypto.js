// NIP-44 helpers backed by noble crypto through nostr-tools.
//
// Exposes globals consumed by Dart via JS interop:
//   window.nip44ConversationKey(privKeyHex, xOnlyPubKeyHex) → Uint8Array(32)
//   window.nip44EncryptMessage(plaintext, conversationKey, nonce?) → string
//   window.nip44DecryptMessage(payload, conversationKey) → string

import {
  decrypt as nip44Decrypt,
  encrypt as nip44Encrypt,
  getConversationKey,
} from 'https://esm.sh/nostr-tools@2.23.3/nip44';

function hexToBytes(hex) {
  if (hex.length % 2 !== 0) {
    throw new Error('Invalid hex string length');
  }
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = Number.parseInt(hex.slice(i * 2, i * 2 + 2), 16);
  }
  return bytes;
}

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
  return getConversationKey(hexToBytes(privKeyHex), pubKeyHex);
}

function nip44EncryptMessage(plaintext, conversationKey, nonce = undefined) {
  return nip44Encrypt(plaintext, conversationKey, nonce ?? undefined);
}

function nip44DecryptMessage(payload, conversationKey) {
  return nip44Decrypt(payload, conversationKey);
}

// Expose to Dart's globalContext / window.
globalThis.nip44ConversationKey = nip44ConversationKey;
globalThis.nip44EncryptMessage = nip44EncryptMessage;
globalThis.nip44DecryptMessage = nip44DecryptMessage;
