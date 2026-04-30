@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/deterministic_keys/deterministic_keys.dart';
import 'package:hostr_sdk/usecase/reservations/reservation_participant_keyring.dart';
import 'package:hostr_sdk/usecase/trade_account_allocator/trade_account_allocator.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _FakeAuth extends Fake implements Auth {
  final KeyPair? keyPair;
  final DeterministicKeys deterministicKeys;

  _FakeAuth({required this.deterministicKeys, this.keyPair});

  @override
  KeyPair? get activeKeyPair => keyPair;

  @override
  String? get activePubkey => keyPair?.publicKey;

  @override
  DeterministicKeys get hd => deterministicKeys;
}

class _FakeDeterministicKeys extends Fake implements DeterministicKeys {
  final Map<int, KeyPair> tradeKeys;

  _FakeDeterministicKeys({this.tradeKeys = const {}});

  @override
  Future<KeyPair> getTradeKeyPair({required int accountIndex}) async {
    final key = tradeKeys[accountIndex];
    if (key == null) throw StateError('No trade key for $accountIndex');
    return key;
  }
}

class _FakeTradeAccountAllocator extends Fake implements TradeAccountAllocator {
  final Map<String, int> indicesByTradeId;
  int lookupCalls = 0;

  _FakeTradeAccountAllocator({this.indicesByTradeId = const {}});

  @override
  Future<int?> tryFindTradeAccountIndexByTradeId(
    String tradeId, {
    int maxScan = 20,
  }) async {
    lookupCalls += 1;
    return indicesByTradeId[tradeId];
  }
}

String _authorizationPayload({
  required KeyPair identityKey,
  required String listingAnchor,
  required String tradeId,
  required String participantPubkey,
  required String role,
}) {
  final authorization = TradeKeyAuthorization.create(
    identityPubkey: identityKey.publicKey,
    listingAnchor: listingAnchor,
    tradeId: tradeId,
    participantPubkey: participantPubkey,
    role: role,
  ).signAs(identityKey, TradeKeyAuthorization.fromNostrEvent);

  return ReservationParticipantAuthorizationPayload.fromAuthorizationEvent(
    authorization,
  ).encode();
}

void main() {
  const tradeId = 'trade-keyring';
  final tempBuyer = mockKeys[30];
  final tradeKey = mockKeys[31];
  final listingAnchor = '32121:${MockKeys.hoster.publicKey}:listing-keyring';

  Reservation reservation() => Reservation.create(
    pubKey: tempBuyer.publicKey,
    dTag: tradeId,
    listingAnchor: listingAnchor,
    extraTags: [
      ['p', MockKeys.hoster.publicKey, '', 'seller'],
      ['p', tempBuyer.publicKey, '', 'buyer'],
    ],
  );

  ReservationParticipantProofTag proofTag({
    required String recipientPubkey,
    String role = 'buyer',
    String payload = 'ciphertext',
    String? plaintext,
    String? payloadHash,
  }) {
    return ReservationParticipantProofTag(
      role: role,
      participantPubkey: tempBuyer.publicKey,
      recipientPubkey: recipientPubkey,
      scheme: kReservationParticipantProofSchemeNip44,
      payloadHash:
          payloadHash ??
          ReservationParticipantProofTag.hashPayload(plaintext ?? payload),
      payload: payload,
    );
  }

  group('DefaultReservationParticipantKeyring', () {
    test('controls the active identity pubkey without trade lookup', () async {
      final allocator = _FakeTradeAccountAllocator();
      final keyring = DefaultReservationParticipantKeyring(
        auth: _FakeAuth(
          keyPair: MockKeys.guest,
          deterministicKeys: _FakeDeterministicKeys(),
        ),
        tradeAccountAllocator: allocator,
      );

      expect(
        await keyring.controlsPubkey(
          pubkey: MockKeys.guest.publicKey,
          tradeId: tradeId,
        ),
        isTrue,
      );
      expect(allocator.lookupCalls, 0);
    });

    test('controls the deterministic trade pubkey for the trade id', () async {
      final allocator = _FakeTradeAccountAllocator(
        indicesByTradeId: {tradeId: 7},
      );
      final keyring = DefaultReservationParticipantKeyring(
        auth: _FakeAuth(
          keyPair: MockKeys.guest,
          deterministicKeys: _FakeDeterministicKeys(tradeKeys: {7: tradeKey}),
        ),
        tradeAccountAllocator: allocator,
      );

      expect(
        await keyring.controlsPubkey(
          pubkey: tradeKey.publicKey,
          tradeId: tradeId,
        ),
        isTrue,
      );
      expect(
        await keyring.controlsPubkey(
          pubkey: tradeKey.publicKey,
          tradeId: tradeId,
        ),
        isTrue,
      );
      expect(allocator.lookupCalls, 1);
    });

    test('decrypts and verifies an active local identity proof', () async {
      final plaintext = _authorizationPayload(
        identityKey: MockKeys.guest,
        listingAnchor: listingAnchor,
        tradeId: tradeId,
        participantPubkey: tempBuyer.publicKey,
        role: 'buyer',
      );
      String? decryptedWithPrivateKey;
      String? decryptedSenderPubkey;

      final keyring = DefaultReservationParticipantKeyring(
        auth: _FakeAuth(
          keyPair: MockKeys.guest,
          deterministicKeys: _FakeDeterministicKeys(),
        ),
        tradeAccountAllocator: _FakeTradeAccountAllocator(),
        localDecrypt:
            ({
              required ciphertext,
              required recipientPrivateKey,
              required senderPubkey,
            }) async {
              decryptedWithPrivateKey = recipientPrivateKey;
              decryptedSenderPubkey = senderPubkey;
              return plaintext;
            },
      );

      final resolved = await keyring.tryDecryptParticipantProof(
        reservation: reservation(),
        proof: proofTag(
          recipientPubkey: MockKeys.guest.publicKey,
          plaintext: plaintext,
        ),
      );

      expect(resolved?.participantPubkey, tempBuyer.publicKey);
      expect(resolved?.identityPubkey, MockKeys.guest.publicKey);
      expect(decryptedWithPrivateKey, MockKeys.guest.privateKey);
      expect(decryptedSenderPubkey, tempBuyer.publicKey);
    });

    test(
      'decrypts active bunker-backed identity proofs through signer',
      () async {
        final plaintext = _authorizationPayload(
          identityKey: MockKeys.guest,
          listingAnchor: listingAnchor,
          tradeId: tradeId,
          participantPubkey: tempBuyer.publicKey,
          role: 'buyer',
        );
        var activeSignerCalls = 0;
        var localDecryptCalls = 0;

        final keyring = DefaultReservationParticipantKeyring(
          auth: _FakeAuth(
            keyPair: KeyPair.justPublicKey(MockKeys.guest.publicKey),
            deterministicKeys: _FakeDeterministicKeys(),
          ),
          tradeAccountAllocator: _FakeTradeAccountAllocator(),
          localDecrypt:
              ({
                required ciphertext,
                required recipientPrivateKey,
                required senderPubkey,
              }) async {
                localDecryptCalls += 1;
                return '';
              },
          activeSignerDecrypt:
              ({required ciphertext, required senderPubkey}) async {
                activeSignerCalls += 1;
                expect(senderPubkey, tempBuyer.publicKey);
                return plaintext;
              },
        );

        final resolved = await keyring.tryDecryptParticipantProof(
          reservation: reservation(),
          proof: proofTag(
            recipientPubkey: MockKeys.guest.publicKey,
            plaintext: plaintext,
          ),
        );

        expect(resolved?.identityPubkey, MockKeys.guest.publicKey);
        expect(activeSignerCalls, 1);
        expect(localDecryptCalls, 0);
      },
    );

    test(
      'decrypts deterministic trade-key proofs without active signer',
      () async {
        final plaintext = _authorizationPayload(
          identityKey: MockKeys.guest,
          listingAnchor: listingAnchor,
          tradeId: tradeId,
          participantPubkey: tempBuyer.publicKey,
          role: 'buyer',
        );
        String? decryptedWithPrivateKey;

        final keyring = DefaultReservationParticipantKeyring(
          auth: _FakeAuth(
            keyPair: MockKeys.guest,
            deterministicKeys: _FakeDeterministicKeys(tradeKeys: {9: tradeKey}),
          ),
          tradeAccountAllocator: _FakeTradeAccountAllocator(
            indicesByTradeId: {tradeId: 9},
          ),
          localDecrypt:
              ({
                required ciphertext,
                required recipientPrivateKey,
                required senderPubkey,
              }) async {
                decryptedWithPrivateKey = recipientPrivateKey;
                return plaintext;
              },
        );

        final resolved = await keyring.tryDecryptParticipantProof(
          reservation: reservation(),
          proof: proofTag(
            recipientPubkey: tradeKey.publicKey,
            plaintext: plaintext,
          ),
        );

        expect(resolved?.participantPubkey, tempBuyer.publicKey);
        expect(resolved?.identityPubkey, MockKeys.guest.publicKey);
        expect(decryptedWithPrivateKey, tradeKey.privateKey);
      },
    );

    test('does not decrypt proofs addressed to unowned pubkeys', () async {
      var decryptCalls = 0;
      final keyring = DefaultReservationParticipantKeyring(
        auth: _FakeAuth(
          keyPair: MockKeys.guest,
          deterministicKeys: _FakeDeterministicKeys(),
        ),
        tradeAccountAllocator: _FakeTradeAccountAllocator(),
        localDecrypt:
            ({
              required ciphertext,
              required recipientPrivateKey,
              required senderPubkey,
            }) async {
              decryptCalls += 1;
              return '';
            },
      );

      final resolved = await keyring.tryDecryptParticipantProof(
        reservation: reservation(),
        proof: proofTag(recipientPubkey: mockKeys[32].publicKey),
      );

      expect(resolved, isNull);
      expect(decryptCalls, 0);
    });

    test('rejects proofs with invalid authorization contents', () async {
      final wrongRolePayload = _authorizationPayload(
        identityKey: MockKeys.guest,
        listingAnchor: listingAnchor,
        tradeId: tradeId,
        participantPubkey: tempBuyer.publicKey,
        role: 'seller',
      );
      final keyring = DefaultReservationParticipantKeyring(
        auth: _FakeAuth(
          keyPair: MockKeys.guest,
          deterministicKeys: _FakeDeterministicKeys(),
        ),
        tradeAccountAllocator: _FakeTradeAccountAllocator(),
        localDecrypt:
            ({
              required ciphertext,
              required recipientPrivateKey,
              required senderPubkey,
            }) async {
              return wrongRolePayload;
            },
      );

      final resolved = await keyring.tryDecryptParticipantProof(
        reservation: reservation(),
        proof: proofTag(
          recipientPubkey: MockKeys.guest.publicKey,
          plaintext: wrongRolePayload,
        ),
      );

      expect(resolved, isNull);
    });
  });

  group('KeyPairReservationParticipantKeyring', () {
    test('controls configured keypairs without trade lookup', () async {
      final keyring = KeyPairReservationParticipantKeyring(
        keyPairs: [MockKeys.escrow],
      );

      expect(
        await keyring.controlsPubkey(
          pubkey: MockKeys.escrow.publicKey,
          tradeId: tradeId,
        ),
        isTrue,
      );
      expect(
        await keyring.controlsPubkey(
          pubkey: MockKeys.guest.publicKey,
          tradeId: tradeId,
        ),
        isFalse,
      );
    });

    test(
      'decrypts and verifies proofs addressed to a configured keypair',
      () async {
        final plaintext = _authorizationPayload(
          identityKey: MockKeys.guest,
          listingAnchor: listingAnchor,
          tradeId: tradeId,
          participantPubkey: tempBuyer.publicKey,
          role: 'buyer',
        );
        String? decryptedWithPrivateKey;
        String? decryptedSenderPubkey;

        final keyring = KeyPairReservationParticipantKeyring(
          keyPairs: [MockKeys.escrow],
          localDecrypt:
              ({
                required ciphertext,
                required recipientPrivateKey,
                required senderPubkey,
              }) async {
                decryptedWithPrivateKey = recipientPrivateKey;
                decryptedSenderPubkey = senderPubkey;
                return plaintext;
              },
        );

        final resolved = await keyring.tryDecryptParticipantProof(
          reservation: reservation(),
          proof: proofTag(
            recipientPubkey: MockKeys.escrow.publicKey,
            plaintext: plaintext,
          ),
        );

        expect(resolved?.participantPubkey, tempBuyer.publicKey);
        expect(resolved?.identityPubkey, MockKeys.guest.publicKey);
        expect(decryptedWithPrivateKey, MockKeys.escrow.privateKey);
        expect(decryptedSenderPubkey, tempBuyer.publicKey);
      },
    );

    test('does not decrypt proofs addressed to unknown keypairs', () async {
      var decryptCalls = 0;
      final keyring = KeyPairReservationParticipantKeyring(
        keyPairs: [MockKeys.escrow],
        localDecrypt:
            ({
              required ciphertext,
              required recipientPrivateKey,
              required senderPubkey,
            }) async {
              decryptCalls += 1;
              return '';
            },
      );

      final resolved = await keyring.tryDecryptParticipantProof(
        reservation: reservation(),
        proof: proofTag(recipientPubkey: MockKeys.guest.publicKey),
      );

      expect(resolved, isNull);
      expect(decryptCalls, 0);
    });
  });
}
