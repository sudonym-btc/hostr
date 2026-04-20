/// Web implementation of NIP-44 conversation key derivation via JS interop
/// to `@noble/curves` (secp256k1 ECDH) + `@noble/hashes` (HKDF-extract).
///
/// The JS function is loaded by `web/nostr_crypto.js` and exposed on
/// `globalThis.nip44ConversationKey`.
library;

import 'dart:js_interop';
import 'dart:typed_data';

@JS('nip44ConversationKey')
external JSUint8Array? _nip44ConversationKey(
  JSString privKeyHex,
  JSString pubKeyHex,
);

@JS('nip44EncryptMessage')
external JSString? _nip44EncryptMessage(
  JSString plaintext,
  JSUint8Array conversationKey,
  JSUint8Array? nonce,
);

@JS('nip44DecryptMessage')
external JSString? _nip44DecryptMessage(
  JSString payload,
  JSUint8Array conversationKey,
);

/// Computes the NIP-44 conversation key using the noble-curves JS library.
///
/// Returns `null` if the JS function is not yet loaded (module still fetching).
Uint8List? nip44ConversationKeyWeb(String privKeyHex, String xOnlyPubKeyHex) {
  try {
    final result = _nip44ConversationKey(privKeyHex.toJS, xOnlyPubKeyHex.toJS);
    return result?.toDart;
  } catch (_) {
    // JS module not loaded yet, or unexpected error — fall back to pure-Dart.
    return null;
  }
}

/// Encrypts a NIP-44 payload using the browser-loaded noble implementation.
///
/// Returns `null` if the JS module is not ready so callers can keep using the
/// pure-Dart fallback.
String? nip44EncryptWeb(
  String plaintext,
  Uint8List conversationKey, {
  Uint8List? nonce,
}) {
  try {
    final result = _nip44EncryptMessage(
      plaintext.toJS,
      conversationKey.toJS,
      nonce?.toJS,
    );
    return result?.toDart;
  } catch (_) {
    return null;
  }
}

/// Decrypts a NIP-44 payload using the browser-loaded noble implementation.
String? nip44DecryptWeb(String payload, Uint8List conversationKey) {
  try {
    final result = _nip44DecryptMessage(payload.toJS, conversationKey.toJS);
    return result?.toDart;
  } catch (_) {
    return null;
  }
}
