// ignore_for_file: experimental_member_use
import 'dart:math';
import 'dart:typed_data';

import 'package:coinlib/coinlib.dart';
import 'package:convert/convert.dart';
import 'package:models/secp256k1.dart';
import 'package:ndk/data_layer/models/nip_01_event_model.dart';
import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:ndk/shared/nips/nip01/bip340.dart' as ndk_bip340;
import 'package:ndk/shared/nips/nip44/nip44.dart';

import 'crypto_provider.dart';

// NOTE on ECDH performance: NIP-44 requires the raw x-coordinate of
// privKey x pubKey_point (secp256k1_ec_pubkey_tweak_MUL). coinlib's
// WASM binary only exports secp256k1_ec_pubkey_tweak_ADD (point addition)
// and secp256k1_ecdh (SHA-256 hashed, incompatible with NIP-44's copy_x
// hashfn). Therefore NIP-44 conversation-key derivation uses NDK's
// pure-Dart elliptic ECDH, with results cached in [_convKeyCache] to
// avoid repeated scalar multiplications for the same keypair.
//
// The [cryptoProvider] hook allows a platform-specific implementation
// (e.g. noble-secp256k1 via @JS interop on web) to be injected by the
// Flutter app via [setCryptoProvider], making even the first call fast.

// ---------------------------------------------------------------------------
// Conversation-key cache
// ---------------------------------------------------------------------------

/// In-memory cache: "\$privKeyHex:\$xOnlyPubKeyHex" -> NIP-44 conversation key.
///
/// Sized to ~200 entries (a user realistically chats with far fewer people).
/// Call [clearNip44ConvKeyCache] on sign-out to avoid leaking keys across
/// sessions.
final Map<String, Uint8List> _convKeyCache = {};

/// Clears the cached NIP-44 conversation keys.
///
/// Call this when the active keypair changes (sign-out / account switch).
void clearNip44ConvKeyCache() => _convKeyCache.clear();

/// Returns the NIP-44 conversation key for [privKeyHex] x [xOnlyPubKeyHex],
/// using the [cryptoProvider] when available and caching the result.
Future<Uint8List> _conversationKey(
  String privKeyHex,
  String xOnlyPubKeyHex,
) async {
  // Normalise to x-only (64-char hex) for a stable cache key.
  final pubHex = xOnlyPubKeyHex.length == 66
      ? xOnlyPubKeyHex.substring(2)
      : xOnlyPubKeyHex;
  final cacheKey = '$privKeyHex:$pubHex';

  final cached = _convKeyCache[cacheKey];
  if (cached != null) return cached;

  // Try platform-specific fast path first (e.g. noble-secp256k1 on web).
  var convKey = await cryptoProvider.nip44ConversationKey(privKeyHex, pubHex);

  // Fall back to NDK's pure-Dart elliptic ECDH.
  if (convKey == null) {
    final sharedSecret = Nip44.computeSharedSecret(privKeyHex, pubHex);
    convKey = Nip44.deriveConversationKey(sharedSecret);
  }

  // Evict all entries when the cache grows too large.
  if (_convKeyCache.length >= 200) _convKeyCache.clear();
  _convKeyCache[cacheKey] = convKey;
  return convKey;
}

// ---------------------------------------------------------------------------
// NIP-44 encrypt / decrypt
// ---------------------------------------------------------------------------

/// NIP-44 encrypt. The conversation key is derived once per keypair and
/// cached, so repeated calls to the same recipient skip the slow ECDH step.
Future<String> coinlibEncryptNip44(
  String plaintext,
  String privKeyHex,
  String recipientPubKeyHex,
) async {
  final convKey = await _conversationKey(privKeyHex, recipientPubKeyHex);
  return Nip44.encryptMessage(
    plaintext,
    '',
    '',
    customConversationKey: convKey,
  );
}

/// NIP-44 decrypt. The conversation key is derived once per keypair and
/// cached, so repeated calls from the same sender skip the slow ECDH step.
Future<String> coinlibDecryptNip44(
  String ciphertext,
  String privKeyHex,
  String senderPubKeyHex,
) async {
  final convKey = await _conversationKey(privKeyHex, senderPubKeyHex);
  return Nip44.decryptMessage(
    ciphertext,
    '',
    '',
    customConversationKey: convKey,
  );
}

/// Derives the x-only (32-byte hex) public key for [privKeyHex].
///
/// Uses coinlib's WASM-backed key derivation when available, otherwise
/// falls back to NDK's pure-Dart [Bip340.getPublicKey].
String _ephemeralPublicKey(String privKeyHex) {
  if (isFastSecp256k1BackendLoaded()) {
    try {
      return ECPrivateKey.fromHex(privKeyHex).pubkey.xhex;
    } catch (_) {}
  }
  return ndk_bip340.Bip340.getPublicKey(privKeyHex);
}

/// Full NIP-59 giftwrap using coinlib for Schnorr signing.
///
/// Replaces `ndk.giftWrap.toGiftWrap()` on the write path.
///
/// **Why this exists:** NDK's `GiftWrap.wrapEvent` is a `static` method
/// hardcoded to `Bip340EventSigner` (pure-Dart `elliptic` + `bip340`).
/// There is no injection point for the outer ephemeral wrap crypto. The
/// `customSigner` parameter only flows into `sealRumor` (kind-13 layer).
///
/// This implementation uses:
/// - NDK's pure-Dart elliptic ECDH for NIP-44 conversation keys
/// - [signSchnorr] from `models` for Schnorr signatures (WASM on web)
Future<Nip01Event> coinlibToGiftWrap({
  required Nip01Event rumor,
  required String recipientPubkey,
  required String senderPrivKey,
  required String senderPubKey,
}) async {
  // ── Seal (kind 13) ────────────────────────────────────────────────────
  // Encrypt the rumor (unsigned Nostr event) for the recipient using the
  // sender's private key — this is the NIP-44 encrypted "seal".
  final rumorJson = Nip01EventModel.fromEntity(rumor).toJsonString();
  final sealContent = await coinlibEncryptNip44(
    rumorJson,
    senderPrivKey,
    recipientPubkey,
  );

  // The seal is a kind-13 event from the sender. NDK does not sign the seal
  // because it is always embedded inside an encrypted outer wrap and is
  // never published directly. We match that behaviour for compatibility.
  final sealEvent = Nip01Event(
    pubKey: senderPubKey,
    kind: 13,
    tags: [],
    content: sealContent,
  );

  // ── Gift wrap (kind 1059) ─────────────────────────────────────────────
  // Generate a random one-time-use ephemeral keypair.
  final rng = Random.secure();
  final ephPrivKeyBytes = Uint8List.fromList(
    List.generate(32, (_) => rng.nextInt(256)),
  );
  final ephPrivKeyHex = hex.encode(ephPrivKeyBytes);
  final ephPubKeyHex = _ephemeralPublicKey(ephPrivKeyHex);

  // Encrypt the seal using the ephemeral private key.
  final sealJson = Nip01EventModel.fromEntity(sealEvent).toJsonString();
  final wrapContent = await coinlibEncryptNip44(
    sealJson,
    ephPrivKeyHex,
    recipientPubkey,
  );

  // NIP-59 recommends randomising the timestamp to reduce metadata leakage.
  // We only go into the past (up to 2 days back) to avoid relay rejection of
  // future timestamps (most relays enforce a ±1800s window on created_at).
  final ts =
      DateTime.now().millisecondsSinceEpoch ~/ 1000 - rng.nextInt(172800);

  final giftWrap = Nip01Event(
    kind: 1059,
    content: wrapContent,
    tags: [
      ['p', recipientPubkey],
    ],
    createdAt: ts,
    pubKey: ephPubKeyHex,
  );

  // Sign the outer gift wrap with the ephemeral key.
  // [signSchnorr] uses coinlib WASM when loaded, falls back to pure Dart.
  final sig = signSchnorr(privateKey: ephPrivKeyHex, message: giftWrap.id);
  return giftWrap.copyWith(sig: sig);
}
