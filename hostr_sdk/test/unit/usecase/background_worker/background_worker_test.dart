@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/background_worker/background_worker.dart';
import 'package:hostr_sdk/usecase/evm/evm.dart';
import 'package:hostr_sdk/usecase/evm/operations/auto_withdraw/auto_withdraw_service.dart';
import 'package:hostr_sdk/usecase/evm/operations/operation_state_store.dart';
import 'package:hostr_sdk/usecase/heartbeat/heartbeat.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
import 'package:hostr_sdk/usecase/user_subscriptions/user_subscriptions.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _FakeAuth extends Fake implements Auth {
  @override
  KeyPair? activeKeyPair = MockKeys.hoster;

  @override
  KeyPair getActiveKey() => activeKeyPair!;
}

class _FakeUserSubscriptions extends Fake implements UserSubscriptions {
  int startCount = 0;

  @override
  final StreamWithStatus<Message> messages$ = StreamWithStatus<Message>();

  @override
  final StreamWithStatus<Validation<ReservationPair>> myHostings$ =
      StreamWithStatus<Validation<ReservationPair>>();

  @override
  final StreamWithStatus<Validation<ReservationPair>> myTrips$ =
      StreamWithStatus<Validation<ReservationPair>>();

  @override
  Future<void> start() async {
    startCount++;
  }
}

class _FakeHeartbeats extends Fake implements Heartbeats {
  final StreamWithStatus<ReceivedHeartbeat> source =
      StreamWithStatus<ReceivedHeartbeat>();
  int upsertCount = 0;

  @override
  StreamWithStatus<ReceivedHeartbeat> queryUsers(
    Iterable<String> pubkeys, {
    String? name,
  }) => source;

  @override
  StreamWithStatus<ReceivedHeartbeat> subscribeUsers(
    Iterable<String> pubkeys, {
    String? name,
  }) => source;

  @override
  Future<ReceivedHeartbeat> upsertCurrent({
    int? createdAt,
    List<List<String>> extraTags = const [],
  }) async {
    upsertCount++;
    return ReceivedHeartbeat.create(
      pubKey: MockKeys.hoster.publicKey,
      createdAt: createdAt ?? 500,
      extraTags: extraTags,
    ).signAs(MockKeys.hoster, ReceivedHeartbeat.fromNostrEvent);
  }
}

class _FakeEvm extends Fake implements Evm {
  int recoverCount = 0;

  @override
  Future<int> recoverStaleOperations({
    bool isBackground = false,
    OnBackgroundProgress? onProgress,
  }) async {
    recoverCount++;
    return 0;
  }
}

class _FakeAutoWithdrawService extends Fake implements AutoWithdrawService {
  int startCount = 0;
  int stopCount = 0;
  int checkNowCount = 0;

  @override
  void start() {
    startCount++;
  }

  @override
  Future<void> stop() async {
    stopCount++;
  }

  @override
  Future<void> checkNow() async {
    checkNowCount++;
  }
}

class _FakeListings extends Fake implements Listings {
  @override
  Future<Listing?> getOneByAnchor(String anchor) async => null;
}

class _FakeMetadataUseCase extends Fake implements MetadataUseCase {
  @override
  Future<ProfileMetadata?> loadMetadata(String pubkey) async => null;
}

class _FakeOperationStateStore extends Fake implements OperationStateStore {
  @override
  Future<bool> hasNonTerminal(String namespace) async => false;
}

Reservation _reservation({
  required String pubkey,
  required String dTag,
  required String listingAnchor,
  required int createdAt,
  ReservationStage stage = ReservationStage.negotiate,
}) {
  return Reservation.create(
    pubKey: pubkey,
    dTag: dTag,
    listingAnchor: listingAnchor,
    start: DateTime.utc(2026, 1, 1),
    end: DateTime.utc(2026, 1, 2),
    stage: stage,
    createdAt: createdAt,
  );
}

void main() {
  late BackgroundWorker worker;
  late _FakeAuth auth;
  late _FakeUserSubscriptions userSubscriptions;
  late _FakeHeartbeats heartbeats;
  late _FakeEvm evm;
  late _FakeAutoWithdrawService autoWithdraw;

  setUp(() {
    auth = _FakeAuth();
    userSubscriptions = _FakeUserSubscriptions();
    heartbeats = _FakeHeartbeats();
    evm = _FakeEvm();
    autoWithdraw = _FakeAutoWithdrawService();

    worker = BackgroundWorker(
      auth: auth,
      userSubscriptions: userSubscriptions,
      heartbeats: heartbeats,
      evm: evm,
      autoWithdraw: autoWithdraw,
      listings: _FakeListings(),
      metadata: _FakeMetadataUseCase(),
      operationStore: _FakeOperationStateStore(),
      logger: CustomLogger(),
    );
  });

  tearDown(() async {
    await worker.stop();
    await heartbeats.source.close();
    await userSubscriptions.messages$.close();
    await userSubscriptions.myHostings$.close();
    await userSubscriptions.myTrips$.close();
  });

  test(
    'run emits hosting notifications and upserts heartbeat once ready',
    () async {
      final listingAnchor = '32121:${MockKeys.hoster.publicKey}:listing';
      final guestReservation = _reservation(
        pubkey: MockKeys.guest.publicKey,
        dTag: 'trade-1',
        listingAnchor: listingAnchor,
        createdAt: 100,
      );

      userSubscriptions.myHostings$.replaceAll([
        Valid(ReservationPair(buyerReservation: guestReservation)),
      ]);
      userSubscriptions.messages$.addStatus(StreamStatusLive());
      userSubscriptions.myHostings$.addStatus(StreamStatusLive());
      userSubscriptions.myTrips$.addStatus(StreamStatusLive());
      heartbeats.source.addStatus(StreamStatusQueryComplete());

      final result = await worker.run();

      expect(result.hasNotifications, isTrue);
      expect(result.notifications.single, contains('reserved'));
      expect(heartbeats.upsertCount, 1);
      expect(autoWithdraw.checkNowCount, 1);
      expect(evm.recoverCount, 1);
      expect(userSubscriptions.startCount, 1);
    },
  );

  test(
    'watch starts long-running maintenance and stop tears it down',
    () async {
      userSubscriptions.messages$.addStatus(StreamStatusLive());
      userSubscriptions.myHostings$.addStatus(StreamStatusLive());
      userSubscriptions.myTrips$.addStatus(StreamStatusLive());
      heartbeats.source.addStatus(StreamStatusQueryComplete());

      await worker.watch();

      expect(autoWithdraw.startCount, 1);
      expect(heartbeats.upsertCount, 1);

      await worker.stop();

      expect(autoWithdraw.stopCount, greaterThanOrEqualTo(1));
    },
  );
}
