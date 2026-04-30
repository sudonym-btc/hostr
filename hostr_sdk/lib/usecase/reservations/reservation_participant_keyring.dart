import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Ndk;
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../util/coinlib_gift_wrap.dart';
import '../../util/custom_logger.dart';
import '../auth/auth.dart';
import '../trade_account_allocator/trade_account_allocator.dart';
import 'reservation_participant_tags.dart';

typedef ReservationParticipantLocalDecryptor =
    Future<String> Function({
      required String ciphertext,
      required String recipientPrivateKey,
      required String senderPubkey,
    });

typedef ReservationParticipantActiveSignerDecryptor =
    Future<String?> Function({
      required String ciphertext,
      required String senderPubkey,
    });

abstract class ReservationParticipantKeyring {
  Future<bool> controlsPubkey({
    required String pubkey,
    required String tradeId,
  });

  Future<ResolvedReservationParticipantProof?> tryDecryptParticipantProof({
    required Reservation reservation,
    required ReservationParticipantProofTag proof,
  });
}

class KeyPairReservationParticipantKeyring
    implements ReservationParticipantKeyring {
  final List<KeyPair> _keyPairs;
  final CustomLogger? _logger;
  final ReservationParticipantLocalDecryptor _localDecrypt;

  KeyPairReservationParticipantKeyring({
    required Iterable<KeyPair> keyPairs,
    CustomLogger? logger,
    ReservationParticipantLocalDecryptor? localDecrypt,
  }) : _keyPairs = keyPairs.toList(growable: false),
       _logger = logger?.scope('reservation-participant-keypair-keyring'),
       _localDecrypt =
           localDecrypt ??
           (({
             required ciphertext,
             required recipientPrivateKey,
             required senderPubkey,
           }) => coinlibDecryptNip44(
             ciphertext,
             recipientPrivateKey,
             senderPubkey,
           ));

  @override
  Future<bool> controlsPubkey({
    required String pubkey,
    required String tradeId,
  }) async {
    if (pubkey.isEmpty) return false;
    return _keyPairs.any((keyPair) => keyPair.publicKey == pubkey);
  }

  @override
  Future<ResolvedReservationParticipantProof?> tryDecryptParticipantProof({
    required Reservation reservation,
    required ReservationParticipantProofTag proof,
  }) async {
    if (proof.scheme != kReservationParticipantProofSchemeNip44) {
      return null;
    }
    if (proof.recipientPubkey.isEmpty || proof.participantPubkey.isEmpty) {
      return null;
    }

    final tradeId = reservation.getDtag();
    if (tradeId == null || tradeId.isEmpty) return null;

    KeyPair? recipientKeyPair;
    for (final keyPair in _keyPairs) {
      if (keyPair.publicKey == proof.recipientPubkey) {
        recipientKeyPair = keyPair;
        break;
      }
    }
    final recipientPrivateKey = recipientKeyPair?.privateKey;
    if (recipientPrivateKey == null || recipientPrivateKey.isEmpty) {
      return null;
    }

    try {
      final plaintext = await _localDecrypt(
        ciphertext: proof.payload,
        recipientPrivateKey: recipientPrivateKey,
        senderPubkey: reservation.pubKey,
      );
      if (plaintext.isEmpty) return null;
      if (!proof.matchesPayload(plaintext)) return null;

      final payload = ReservationParticipantAuthorizationPayload.tryDecode(
        plaintext,
      );
      if (payload == null) return null;

      final isValid = payload.verifiesForReservation(
        tradeId: tradeId,
        listingAnchor: reservation.parsedTags.listingAnchor,
        participantPubkey: proof.participantPubkey,
        role: proof.role,
      );
      if (!isValid) return null;

      return ResolvedReservationParticipantProof(
        participantPubkey: proof.participantPubkey,
        identityPubkey: payload.pubkey,
      );
    } catch (error, stackTrace) {
      _logger?.w(
        'Failed to decrypt participant proof for ${proof.recipientPubkey}',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}

class DefaultReservationParticipantKeyring
    implements ReservationParticipantKeyring {
  final Auth _auth;
  final TradeAccountAllocator _tradeAccountAllocator;
  final Ndk? _ndk;
  final CustomLogger? _logger;
  final ReservationParticipantLocalDecryptor _localDecrypt;
  final ReservationParticipantActiveSignerDecryptor? _activeSignerDecrypt;
  final Map<String, Future<KeyPair?>> _tradeKeyCache = {};

  DefaultReservationParticipantKeyring({
    required Auth auth,
    required TradeAccountAllocator tradeAccountAllocator,
    Ndk? ndk,
    CustomLogger? logger,
    ReservationParticipantLocalDecryptor? localDecrypt,
    ReservationParticipantActiveSignerDecryptor? activeSignerDecrypt,
  }) : _auth = auth,
       _tradeAccountAllocator = tradeAccountAllocator,
       _ndk = ndk,
       _logger = logger?.scope('reservation-participant-keyring'),
       _localDecrypt =
           localDecrypt ??
           (({
             required ciphertext,
             required recipientPrivateKey,
             required senderPubkey,
           }) => coinlibDecryptNip44(
             ciphertext,
             recipientPrivateKey,
             senderPubkey,
           )),
       _activeSignerDecrypt = activeSignerDecrypt;

  @override
  Future<bool> controlsPubkey({
    required String pubkey,
    required String tradeId,
  }) async {
    if (pubkey.isEmpty) return false;
    if (pubkey == _auth.activePubkey) return true;
    if (tradeId.isEmpty) return false;

    final tradeKey = await _tradeKeyForTradeId(tradeId);
    return tradeKey?.publicKey == pubkey;
  }

  @override
  Future<ResolvedReservationParticipantProof?> tryDecryptParticipantProof({
    required Reservation reservation,
    required ReservationParticipantProofTag proof,
  }) async {
    if (proof.scheme != kReservationParticipantProofSchemeNip44) {
      return null;
    }
    if (proof.recipientPubkey.isEmpty || proof.participantPubkey.isEmpty) {
      return null;
    }

    final tradeId = reservation.getDtag();
    if (tradeId == null || tradeId.isEmpty) return null;

    if (!await controlsPubkey(
      pubkey: proof.recipientPubkey,
      tradeId: tradeId,
    )) {
      return null;
    }

    final plaintext = await _decryptForRecipient(
      ciphertext: proof.payload,
      senderPubkey: reservation.pubKey,
      recipientPubkey: proof.recipientPubkey,
      tradeId: tradeId,
    );
    if (plaintext == null || plaintext.isEmpty) return null;
    if (!proof.matchesPayload(plaintext)) return null;

    final payload = ReservationParticipantAuthorizationPayload.tryDecode(
      plaintext,
    );
    if (payload == null) return null;

    final isValid = payload.verifiesForReservation(
      tradeId: tradeId,
      listingAnchor: reservation.parsedTags.listingAnchor,
      participantPubkey: proof.participantPubkey,
      role: proof.role,
    );
    if (!isValid) return null;

    return ResolvedReservationParticipantProof(
      participantPubkey: proof.participantPubkey,
      identityPubkey: payload.pubkey,
    );
  }

  Future<String?> _decryptForRecipient({
    required String ciphertext,
    required String senderPubkey,
    required String recipientPubkey,
    required String tradeId,
  }) async {
    try {
      final activePubkey = _auth.activePubkey;
      if (recipientPubkey == activePubkey) {
        final privateKey = _auth.activeKeyPair?.privateKey;
        if (privateKey != null && privateKey.isNotEmpty) {
          return _localDecrypt(
            ciphertext: ciphertext,
            recipientPrivateKey: privateKey,
            senderPubkey: senderPubkey,
          );
        }
        return _decryptWithActiveSigner(
          ciphertext: ciphertext,
          senderPubkey: senderPubkey,
        );
      }

      final tradeKey = await _tradeKeyForTradeId(tradeId);
      final privateKey = tradeKey?.privateKey;
      if (tradeKey?.publicKey == recipientPubkey &&
          privateKey != null &&
          privateKey.isNotEmpty) {
        return _localDecrypt(
          ciphertext: ciphertext,
          recipientPrivateKey: privateKey,
          senderPubkey: senderPubkey,
        );
      }
    } catch (error, stackTrace) {
      _logger?.w(
        'Failed to decrypt participant proof for $recipientPubkey',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
  }

  Future<String?> _decryptWithActiveSigner({
    required String ciphertext,
    required String senderPubkey,
  }) async {
    final injected = _activeSignerDecrypt;
    if (injected != null) {
      return injected(ciphertext: ciphertext, senderPubkey: senderPubkey);
    }

    final signer = _ndk?.accounts.getLoggedAccount()?.signer;
    if (signer == null) return null;
    return signer.decryptNip44(
      ciphertext: ciphertext,
      senderPubKey: senderPubkey,
    );
  }

  Future<KeyPair?> _tradeKeyForTradeId(String tradeId) {
    final cacheKey = '${_auth.activePubkey ?? ''}:$tradeId';
    return _tradeKeyCache.putIfAbsent(cacheKey, () async {
      try {
        final accountIndex = await _tradeAccountAllocator
            .tryFindTradeAccountIndexByTradeId(tradeId);
        if (accountIndex == null) return null;
        return _auth.hd.getTradeKeyPair(accountIndex: accountIndex);
      } catch (error, stackTrace) {
        _logger?.w(
          'Failed to resolve participant trade key for $tradeId',
          error: error,
          stackTrace: stackTrace,
        );
        return null;
      }
    });
  }
}
