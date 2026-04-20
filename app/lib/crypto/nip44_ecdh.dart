/// Non-web stub — native platforms don't need JS interop for ECDH.
///
/// Returns `null` so that the SDK falls back to NDK's pure-Dart path
/// (which is fast enough on native thanks to ahead-of-time compilation).
library;

import 'dart:typed_data';

Uint8List? nip44ConversationKeyWeb(String privKeyHex, String xOnlyPubKeyHex) =>
    null;

String? nip44EncryptWeb(
  String plaintext,
  Uint8List conversationKey, {
  Uint8List? nonce,
}) => null;

String? nip44DecryptWeb(String payload, Uint8List conversationKey) => null;
