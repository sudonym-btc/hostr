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
