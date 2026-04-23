@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/deterministic_keys/deterministic_keys.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/usecase/reservation_requests/reservation_requests.dart';
import 'package:hostr_sdk/usecase/reservations/reservation_pubkey_proofs.dart';
import 'package:hostr_sdk/usecase/trade_account_allocator/trade_account_allocator.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Nip01Event;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../../support/fakes.dart';

class _FakeAuth extends Fake implements Auth {
  @override
  KeyPair getActiveKey() => MockKeys.guest;

  @override
  DeterministicKeys get hd => _FakeDeterministicKeys();
}

class _FakeDeterministicKeys extends Fake implements DeterministicKeys {
  @override
  Future<String> getTradeId({required int accountIndex}) async =>
      'trade-id-$accountIndex';

  @override
  Future<String> getTradeSalt({required int accountIndex}) async =>
      'trade-salt-$accountIndex';
}

class _FakeTradeAccountAllocator extends Fake implements TradeAccountAllocator {
  @override
  Future<int> reserveNextTradeIndex() async => 7;
}

class _FakeRequests extends Fake implements Requests {
  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) async => const [];

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) => const Stream.empty();
}

Reservation _reservation({
  required KeyPair author,
  String tradeId = 'trade-123',
  bool includeEscrow = true,
  List<ReservationPubkeyProofTag> pubkeyProofs = const [],
}) {
  return Reservation.create(
    pubKey: author.publicKey,
    dTag: tradeId,
    listingAnchor: '32121:${MockKeys.hoster.publicKey}:listing-1',
    pTags: [
      PTag.seller(MockKeys.hoster.publicKey),
      PTag.buyer(author.publicKey),
      if (includeEscrow) PTag.escrow(MockKeys.escrow.publicKey),
    ],
    pubkeyProofs: pubkeyProofs,
  );
}

Listing _listing() => Listing.create(
  pubKey: MockKeys.hoster.publicKey,
  dTag: 'listing-1',
  title: 'Proof Cottage',
  description: 'Fixture',
  images: const [],
  price: [
    Price(
      amount: DenominatedAmount(
        value: BigInt.from(100000),
        denomination: 'BTC',
        decimals: 8,
      ),
      frequency: Frequency.daily,
    ),
  ],
  location: 'Test',
  type: ListingType.house,
  specifications: Specifications(),
).signAs(MockKeys.hoster, Listing.fromNostrEvent);

void main() {
  group('ReservationPubkeyProofAttachment', () {
    late KeyPair disposableBuyer;

    setUp(() {
      disposableBuyer = mockKeys[20];
    });

    test('infers seller and escrow recipients for buyer proofs', () {
      final reservation = _reservation(author: disposableBuyer);

      expect(reservation.pubkeyProofRecipientsFor('buyer'), {
        MockKeys.hoster.publicKey,
        MockKeys.escrow.publicKey,
      });
    });

    test('infers only seller recipient for buyer proof without escrow', () {
      final reservation = _reservation(
        author: disposableBuyer,
        includeEscrow: false,
      );

      expect(reservation.pubkeyProofRecipientsFor('buyer'), {
        MockKeys.hoster.publicKey,
      });
    });

    test('encrypts buyer proof to seller and escrow', () async {
      final reservation = _reservation(author: disposableBuyer);

      final attached = await reservation.attachPubkeyProof(
        role: 'buyer',
        proofKeyPair: MockKeys.guest,
        encryptionKeyPair: disposableBuyer,
      );

      expect(attached.sig, isNull);
      expect(attached.parsedTags.pubkeyProofs, hasLength(2));
      expect(
        attached.parsedTags.pubkeyProofs.map((p) => p.recipientPubkey).toSet(),
        {MockKeys.hoster.publicKey, MockKeys.escrow.publicKey},
      );
      expect(
        attached.parsedTags.pubkeyProofs.every(
          (p) => p.scheme == kReservationPubkeyProofSchemeNip44V1,
        ),
        isTrue,
      );

      final sellerProof = await attached.resolvePubkeyProof(
        role: 'buyer',
        recipientKeyPair: MockKeys.hoster,
      );
      final escrowProof = await attached.resolvePubkeyProof(
        role: 'buyer',
        recipientKeyPair: MockKeys.escrow,
      );

      expect(sellerProof?.pubkey, MockKeys.guest.publicKey);
      expect(escrowProof?.pubkey, MockKeys.guest.publicKey);
    });

    test('does not resolve proof for a non-recipient', () async {
      final attached = await _reservation(author: disposableBuyer)
          .attachPubkeyProof(
            role: 'buyer',
            proofKeyPair: MockKeys.guest,
            encryptionKeyPair: disposableBuyer,
          );

      expect(
        await attached.resolvePubkeyProof(
          role: 'buyer',
          recipientKeyPair: MockKeys.reviewer,
        ),
        isNull,
      );
    });

    test('rejects a proof when the trade id is changed', () async {
      final attached = await _reservation(author: disposableBuyer)
          .attachPubkeyProof(
            role: 'buyer',
            proofKeyPair: MockKeys.guest,
            encryptionKeyPair: disposableBuyer,
          );
      final tampered = attached.copy(
        id: null,
        sig: null,
        tags: ReservationTags([
          for (final tag in attached.parsedTags.tags)
            if (tag.isNotEmpty && tag.first == 'd') ['d', 'trade-456'] else tag,
        ]),
      );

      expect(
        await tampered.resolvePubkeyProof(
          role: 'buyer',
          recipientKeyPair: MockKeys.hoster,
        ),
        isNull,
      );
    });

    test('replaces same role and recipient proof tags', () async {
      final existing = ReservationPubkeyProofTag(
        role: 'buyer',
        recipientPubkey: MockKeys.hoster.publicKey,
        scheme: kReservationPubkeyProofSchemeNip44V1,
        ciphertext: 'old-ciphertext',
      );
      final otherRole = ReservationPubkeyProofTag(
        role: 'seller',
        recipientPubkey: MockKeys.hoster.publicKey,
        scheme: kReservationPubkeyProofSchemeNip44V1,
        ciphertext: 'keep-me',
      );
      final reservation = _reservation(
        author: disposableBuyer,
        includeEscrow: false,
        pubkeyProofs: [existing, otherRole],
      );

      final attached = await reservation.attachPubkeyProof(
        role: 'buyer',
        proofKeyPair: MockKeys.guest,
        encryptionKeyPair: disposableBuyer,
      );

      final proofs = attached.parsedTags.pubkeyProofs;
      expect(proofs, hasLength(2));
      expect(proofs.where((p) => p.ciphertext == 'old-ciphertext'), isEmpty);
      expect(proofs.where((p) => p.ciphertext == 'keep-me'), hasLength(1));
      expect(
        await attached.resolvePubkeyProof(
          role: 'buyer',
          recipientKeyPair: MockKeys.hoster,
        ),
        isNotNull,
      );
    });

    test('supports explicit recipients for future roles', () async {
      final attached =
          await _reservation(
            author: disposableBuyer,
            includeEscrow: false,
          ).attachPubkeyProof(
            role: 'arbiter',
            proofKeyPair: MockKeys.guest,
            encryptionKeyPair: disposableBuyer,
            recipientPubkeys: [MockKeys.reviewer.publicKey],
          );

      final proof = await attached.resolvePubkeyProof(
        role: 'arbiter',
        recipientKeyPair: MockKeys.reviewer,
      );

      expect(proof?.pubkey, MockKeys.guest.publicKey);
    });

    test('throws when encryption key does not match reservation author', () {
      expect(
        () => _reservation(author: disposableBuyer).attachPubkeyProof(
          role: 'buyer',
          proofKeyPair: MockKeys.guest,
          encryptionKeyPair: MockKeys.guest,
        ),
        throwsStateError,
      );
    });

    test('throws when default recipients cannot be inferred', () {
      expect(
        () => _reservation(author: disposableBuyer).attachPubkeyProof(
          role: 'arbiter',
          proofKeyPair: MockKeys.guest,
          encryptionKeyPair: disposableBuyer,
        ),
        throwsUnsupportedError,
      );
    });
  });

  group('ReservationRequests pubkey proof integration', () {
    test(
      'createReservationRequest attaches a buyer proof to the seller',
      () async {
        final usecase = ReservationRequests(
          requests: _FakeRequests(),
          logger: CustomLogger(),
          auth: _FakeAuth(),
          tradeAccountAllocator: _FakeTradeAccountAllocator(),
          relays: FakeRelays(),
        );

        final reservation = await usecase.createReservationRequest(
          listing: _listing(),
          startDate: DateTime(2026, 5, 1),
          endDate: DateTime(2026, 5, 3),
        );

        expect(reservation.pubKey, isNot(MockKeys.guest.publicKey));
        expect(reservation.parsedTags.pubkeyProofs, hasLength(1));
        expect(
          reservation.parsedTags.pubkeyProofs.single.recipientPubkey,
          MockKeys.hoster.publicKey,
        );

        final proof = await reservation.resolvePubkeyProof(
          role: 'buyer',
          recipientKeyPair: MockKeys.hoster,
        );

        expect(proof?.pubkey, MockKeys.guest.publicKey);
      },
    );
  });
}
