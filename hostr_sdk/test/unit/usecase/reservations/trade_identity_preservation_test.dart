@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/messaging/messaging.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/usecase/reservation_requests/reservation_requests.dart';
import 'package:hostr_sdk/usecase/reservation_transitions/reservation_transitions.dart';
import 'package:hostr_sdk/usecase/reservations/reservations.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, Nip01Event, Nip01Utils;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _FakeRequests extends Fake implements Requests {
  final List<Nip01Event> broadcastedEvents = [];

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) async {
    broadcastedEvents.add(event);
    return const <RelayBroadcastResponse>[];
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
    String? name,
  }) => const Stream.empty();

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
  }) => StreamWithStatus<T>();
}

class _FakeAuth extends Fake implements Auth {
  _FakeAuth(this._activeKeyPair);

  final KeyPair _activeKeyPair;

  @override
  KeyPair getActiveKey() => _activeKeyPair;

  @override
  Future<int> reserveNextTradeIndex() async => 7;

  @override
  String getTradeId({required int accountIndex}) => 'trade-id-$accountIndex';

  @override
  String getTradeSalt({required int accountIndex}) =>
      'trade-salt-$accountIndex';
}

class _FakeMessaging extends Fake implements Messaging {}

class _FakeListings extends Fake implements Listings {}

class _FakeReservationTransitions extends Fake
    implements ReservationTransitions {
  int recordCalls = 0;

  @override
  Future<ReservationTransition> record({
    required Reservation reservation,
    required ReservationTransitionType transitionType,
    required ReservationStage fromStage,
    required ReservationStage toStage,
    String? commitTermsHash,
    String? reason,
    Map<String, dynamic>? updatedFields,
    String? prevTransitionId,
  }) async {
    recordCalls += 1;
    final unsigned = Nip01Event(
      kind: kNostrKindReservationTransition,
      pubKey: reservation.pubKey,
      tags: [
        ['d', reservation.getDtag() ?? ''],
      ],
      content: ReservationTransitionContent(
        transitionType: transitionType,
        fromStage: fromStage,
        toStage: toStage,
        commitTermsHash: commitTermsHash,
        reason: reason,
        updatedFields: updatedFields,
      ).toString(),
    );

    return ReservationTransition.fromNostrEvent(
      Nip01Utils.signWithPrivateKey(
        event: unsigned,
        privateKey: MockKeys.hoster.privateKey!,
      ),
    );
  }
}

Listing _listing() {
  return Listing.create(
    pubKey: MockKeys.hoster.publicKey,
    dTag: 'listing-trade-identity',
    title: 'Trade Identity Test Listing',
    description: 'Listing used for trade identity regression tests',
    images: const ['https://picsum.photos/seed/trade/800/600'],
    price: [
      Price(
        amount: Amount(currency: Currency.BTC, value: BigInt.from(100000)),
        frequency: Frequency.daily,
      ),
    ],
    location: 'test-location',
    type: ListingType.house,
    amenities: Amenities(),
    allowBarter: true,
    allowSelfSignedReservation: true,
  ).signAs(MockKeys.hoster, Listing.fromNostrEvent);
}

PaymentProof _paymentProof(Listing listing) {
  final hoster = Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      kind: 0,
      pubKey: listing.pubKey,
      tags: const [],
      content: '',
    ),
    privateKey: MockKeys.hoster.privateKey!,
  );

  return PaymentProof(
    hoster: hoster,
    listing: listing,
    zapProof: null,
    escrowProof: null,
  );
}

void main() {
  late _FakeRequests requests;
  late _FakeAuth auth;
  late ReservationRequests reservationRequests;
  late Reservations reservations;
  late _FakeReservationTransitions transitions;

  setUp(() {
    requests = _FakeRequests();
    auth = _FakeAuth(MockKeys.guest);
    transitions = _FakeReservationTransitions();

    reservationRequests = ReservationRequests(
      requests: requests,
      logger: CustomLogger(),
      auth: auth,
    );

    reservations = Reservations(
      requests: requests,
      logger: CustomLogger(),
      messaging: _FakeMessaging(),
      auth: auth,
      transitions: transitions,
      listings: _FakeListings(),
    );
  });

  test(
    'counter-offers and self-signed commits preserve the original trade identity',
    () async {
      final listing = _listing();

      final initialRequest = await reservationRequests.createReservationRequest(
        listing: listing,
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 4),
      );

      final hostCounter = await reservationRequests.createCounterOffer(
        listing: listing,
        previousRequest: initialRequest,
        amount: Amount(currency: Currency.BTC, value: BigInt.from(90000)),
        signerKeyPair: MockKeys.hoster,
      );

      final guestTradeKey = tweakKeyPair(
        privateKey: MockKeys.guest.privateKey!,
        salt: hostCounter.tweakMaterial!.salt,
      );

      final commit = await reservations.createSelfSigned(
        activeKeyPair: guestTradeKey.keyPair,
        negotiateReservation: hostCounter,
        proof: _paymentProof(listing),
      );

      expect(initialRequest.getDtag(), 'trade-id-7');
      expect(initialRequest.tweakMaterial?.salt, 'trade-salt-7');

      expect(hostCounter.getDtag(), initialRequest.getDtag());
      expect(
        hostCounter.tweakMaterial?.salt,
        initialRequest.tweakMaterial?.salt,
      );
      expect(hostCounter.recipient, initialRequest.recipient);
      expect(
        hostCounter.parsedTags.listingAnchor,
        initialRequest.parsedTags.listingAnchor,
      );
      expect(hostCounter.signatures.keys, contains(MockKeys.hoster.publicKey));

      expect(commit.getDtag(), initialRequest.getDtag());
      expect(commit.tweakMaterial, isNull);
      expect(commit.recipient, initialRequest.recipient);
      expect(
        commit.parsedTags.listingAnchor,
        initialRequest.parsedTags.listingAnchor,
      );
      expect(commit.signatures, hostCounter.signatures);
      expect(commit.pubKey, guestTradeKey.publicKey);

      expect(requests.broadcastedEvents, isNotEmpty);
      expect(requests.broadcastedEvents.last, same(commit));
      expect(transitions.recordCalls, 1);
    },
  );
}
