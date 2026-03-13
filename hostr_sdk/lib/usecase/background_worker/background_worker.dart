import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../../util/main.dart';
import '../auth/auth.dart';
import '../evm/evm.dart';
import '../evm/operations/auto_withdraw/auto_withdraw_service.dart';
import '../evm/operations/operation_state_store.dart';
import '../heartbeat/heartbeat.dart';
import '../listings/listings.dart';
import '../metadata/metadata.dart';
import '../user_subscriptions/user_subscriptions.dart';

/// A single notification to show or update in the OS notification tray.
class BackgroundNotification {
  /// Stable identifier for this notification — used to update the same OS
  /// notification across progressive state changes (e.g. swap → deposit).
  final String operationId;

  /// Human-readable body text.
  final String body;

  const BackgroundNotification({required this.operationId, required this.body});
}

/// Callback for real-time notification updates during background recovery.
typedef OnBackgroundProgress =
    void Function(BackgroundNotification notification);

/// Result of a single background worker run, containing all notifications
/// that should be surfaced to the user.
class BackgroundWorkerResult {
  final List<String> notifications;

  const BackgroundWorkerResult({this.notifications = const []});

  bool get hasNotifications => notifications.isNotEmpty;
}

enum _BackgroundWorkerMode { run, watch }

class _BackgroundSignal {
  final String id;
  final String body;
  final int createdAt;

  const _BackgroundSignal({
    required this.id,
    required this.body,
    required this.createdAt,
  });
}

@Singleton()
class BackgroundWorker {
  final Auth _auth;
  final UserSubscriptions _userSubscriptions;
  final Heartbeats _heartbeats;
  final Evm _evm;
  final AutoWithdrawService _autoWithdraw;
  final Listings _listings;
  final MetadataUseCase _metadata;
  final OperationStateStore _operationStore;
  final CustomLogger _logger;
  Auth get auth => _auth;
  UserSubscriptions get userSubscriptions => _userSubscriptions;
  Heartbeats get heartbeats => _heartbeats;
  Evm get evm => _evm;
  AutoWithdrawService get autoWithdraw => _autoWithdraw;
  Listings get listings => _listings;
  MetadataUseCase get metadata => _metadata;
  OperationStateStore get operationStore => _operationStore;
  CustomLogger get logger => _logger;

  final StreamWithStatus<_BackgroundSignal> messagesProcessor$ =
      StreamWithStatus<_BackgroundSignal>();
  final StreamWithStatus<_BackgroundSignal> myHostingsProcessor$ =
      StreamWithStatus<_BackgroundSignal>();
  final StreamWithStatus<_BackgroundSignal> myTripsProcessor$ =
      StreamWithStatus<_BackgroundSignal>();
  final StreamWithStatus<_BackgroundSignal> autoWithdrawProcessor$ =
      StreamWithStatus<_BackgroundSignal>();
  final StreamWithStatus<_BackgroundSignal>
  onchainOperationsRecoveryProcessor$ = StreamWithStatus<_BackgroundSignal>();

  final StreamWithStatus<BackgroundNotification> _notifications =
      StreamWithStatus<BackgroundNotification>();
  final BehaviorSubject<bool> _ready = BehaviorSubject<bool>.seeded(false);

  final List<StreamSubscription> _sessionSubscriptions = [];
  final Set<String> _emittedNotificationIds = <String>{};
  final Map<String, String> _listingTitleCache = <String, String>{};

  StreamWithStatus<ReceivedHeartbeat>? _heartbeatSubscription;
  _BackgroundWorkerMode? _mode;
  OnBackgroundProgress? _watchProgress;
  Future<void>? _maintenanceFuture;
  bool _started = false;
  bool _heartbeatPublished = false;
  int _notificationBoundary = 0;
  int _latestHeartbeatCreatedAt = 0;

  BackgroundWorker({
    required Auth auth,
    required UserSubscriptions userSubscriptions,
    required Heartbeats heartbeats,
    required Evm evm,
    required AutoWithdrawService autoWithdraw,
    required Listings listings,
    required MetadataUseCase metadata,
    required OperationStateStore operationStore,
    required CustomLogger logger,
  }) : _auth = auth,
       _userSubscriptions = userSubscriptions,
       _heartbeats = heartbeats,
       _evm = evm,
       _autoWithdraw = autoWithdraw,
       _listings = listings,
       _metadata = metadata,
       _operationStore = operationStore,
       _logger = logger.scope('bg-worker');

  Future<void> watch({OnBackgroundProgress? onProgress}) =>
      logger.span('watch', () async {
        if (auth.activeKeyPair == null) {
          logger.d('no active key pair, skipping watch');
          return;
        }

        if (_started) {
          _watchProgress = onProgress ?? _watchProgress;
          return;
        }

        await _start(mode: _BackgroundWorkerMode.watch, onProgress: onProgress);
        await _waitUntilReady();
      });

  Future<BackgroundWorkerResult> run({OnBackgroundProgress? onProgress}) =>
      logger.span('run', () async {
        if (auth.activeKeyPair == null) {
          logger.d('no active key pair, skipping');
          return const BackgroundWorkerResult();
        }

        final startedHere = !_started;
        if (startedHere) {
          await _start(mode: _BackgroundWorkerMode.run, onProgress: onProgress);
        }

        final notifications = <String>[];
        final notificationSub = _notifications.replayStream.listen((
          notification,
        ) {
          notifications.add(notification.body);
        });

        try {
          await _waitUntilReady();
          await _maintenanceFuture;
          return BackgroundWorkerResult(notifications: notifications);
        } finally {
          await notificationSub.cancel();
          if (startedHere && _mode == _BackgroundWorkerMode.run) {
            await stop();
          }
        }
      });

  Future<void> stop() => logger.span('stop', () async {
    if (!_started) return;

    _started = false;
    _mode = null;
    _watchProgress = null;
    _maintenanceFuture = null;
    _heartbeatPublished = false;
    _notificationBoundary = 0;
    _latestHeartbeatCreatedAt = 0;
    _emittedNotificationIds.clear();
    _listingTitleCache.clear();
    _ready.add(false);

    for (final sub in _sessionSubscriptions) {
      await sub.cancel();
    }
    _sessionSubscriptions.clear();

    await _heartbeatSubscription?.close();
    _heartbeatSubscription = null;

    await messagesProcessor$.reset();
    await myHostingsProcessor$.reset();
    await myTripsProcessor$.reset();
    await autoWithdrawProcessor$.reset();
    await onchainOperationsRecoveryProcessor$.reset();
    await _notifications.reset();

    await autoWithdraw.stop();
  });

  Future<void> _start({
    required _BackgroundWorkerMode mode,
    OnBackgroundProgress? onProgress,
  }) => logger.span('_start', () async {
    if (_started) return;
    _started = true;
    _mode = mode;
    _watchProgress = onProgress;
    _ready.add(false);
    _emittedNotificationIds.clear();
    _listingTitleCache.clear();

    await userSubscriptions.start();
    await _bootstrapHeartbeatBoundary(mode);
    _wireProcessors();

    _maintenanceFuture = _startMaintenanceProcessors(
      mode: mode,
      onProgress: onProgress,
    );
    if (mode == _BackgroundWorkerMode.watch) {
      unawaited(_maintenanceFuture);
    }
  });

  Future<void> _bootstrapHeartbeatBoundary(_BackgroundWorkerMode mode) =>
      logger.span('_bootstrapHeartbeatBoundary', () async {
        final myPubkey = auth.getActiveKey().publicKey;

        _heartbeatSubscription = mode == _BackgroundWorkerMode.watch
            ? heartbeats.subscribeUsers([
                myPubkey,
              ], name: 'background-worker-heartbeat-watch')
            : heartbeats.queryUsers([
                myPubkey,
              ], name: 'background-worker-heartbeat-run');

        _sessionSubscriptions.add(
          _heartbeatSubscription!.replayStream.listen(
            (heartbeat) {
              if (heartbeat.pubKey != myPubkey) return;
              if (heartbeat.createdAt > _latestHeartbeatCreatedAt) {
                _latestHeartbeatCreatedAt = heartbeat.createdAt;
                if (!_heartbeatPublished) {
                  _notificationBoundary = heartbeat.createdAt;
                }
              }
            },
            onError: (Object e, StackTrace st) {
              logger.e(
                'BackgroundWorker heartbeat stream failed',
                error: e,
                stackTrace: st,
              );
            },
          ),
        );

        await _heartbeatSubscription!.status.firstWhere(_isReadyStatus);
      });

  void _wireProcessors() {
    _bindMessagesProcessor();
    _bindHostingsProcessor();
    _bindTripsProcessor();
    _bindReadinessBarrier();

    for (final processor in <StreamWithStatus<_BackgroundSignal>>[
      messagesProcessor$,
      myHostingsProcessor$,
      myTripsProcessor$,
    ]) {
      _sessionSubscriptions.add(
        processor.replayStream.listen(
          _emitSignal,
          onError: (Object e, StackTrace st) {
            logger.e(
              'BackgroundWorker processor failed',
              error: e,
              stackTrace: st,
            );
          },
        ),
      );
    }
  }

  void _bindMessagesProcessor() {
    _mirrorStatus(userSubscriptions.messages$, messagesProcessor$);
    messagesProcessor$.addSubscription(
      userSubscriptions.messages$.replayStream
          .asyncMap(_signalFromMessage)
          .where((signal) => signal != null)
          .cast<_BackgroundSignal>()
          .listen(messagesProcessor$.add, onError: messagesProcessor$.addError),
    );
  }

  void _bindHostingsProcessor() {
    _mirrorStatus(userSubscriptions.myHostings$, myHostingsProcessor$);
    myHostingsProcessor$.addSubscription(
      userSubscriptions.myHostings$.itemsStream
          .asyncMap(_signalsFromHostings)
          .listen(
            myHostingsProcessor$.addAll,
            onError: myHostingsProcessor$.addError,
          ),
    );
  }

  void _bindTripsProcessor() {
    _mirrorStatus(userSubscriptions.myTrips$, myTripsProcessor$);
    myTripsProcessor$.addSubscription(
      userSubscriptions.myTrips$.itemsStream
          .asyncMap(_signalsFromTrips)
          .listen(
            myTripsProcessor$.addAll,
            onError: myTripsProcessor$.addError,
          ),
    );
  }

  void _bindReadinessBarrier() {
    _sessionSubscriptions.add(
      Rx.combineLatestList<StreamStatus>([
        messagesProcessor$.status,
        myHostingsProcessor$.status,
        myTripsProcessor$.status,
      ]).listen((statuses) async {
        if (_heartbeatPublished) return;
        if (!statuses.every(_isReadyStatus)) return;

        _heartbeatPublished = true;
        await _publishHeartbeat();
        _ready.add(true);
      }),
    );
  }

  Future<void> _startMaintenanceProcessors({
    required _BackgroundWorkerMode mode,
    OnBackgroundProgress? onProgress,
  }) => logger.span('_startMaintenanceProcessors', () async {
    await Future.wait([
      _runAutoWithdrawProcessor(mode),
      _runOnchainRecoveryProcessor(mode, onProgress: onProgress),
    ]);
  });

  Future<void> _runAutoWithdrawProcessor(_BackgroundWorkerMode mode) =>
      logger.span('_runAutoWithdrawProcessor', () async {
        autoWithdrawProcessor$.addStatus(StreamStatusQuerying());
        if (mode == _BackgroundWorkerMode.watch) {
          autoWithdraw.start();
        } else {
          await _runSafe('autoWithdraw', () async {
            await autoWithdraw.checkNow();
          });
        }
        autoWithdrawProcessor$.addStatus(StreamStatusLive());
      });

  Future<void> _runOnchainRecoveryProcessor(
    _BackgroundWorkerMode mode, {
    OnBackgroundProgress? onProgress,
  }) => logger.span('_runOnchainRecoveryProcessor', () async {
    onchainOperationsRecoveryProcessor$.addStatus(StreamStatusQuerying());
    await _runSafe('recoverOnchainOps', () async {
      await evm.recoverStaleOperations(
        isBackground: mode == _BackgroundWorkerMode.run,
        onProgress: onProgress,
      );
    });
    onchainOperationsRecoveryProcessor$.addStatus(StreamStatusLive());
  });

  Future<_BackgroundSignal?> _signalFromMessage(Message message) async {
    final myPubkey = auth.getActiveKey().publicKey;
    if (message.pubKey == myPubkey) return null;
    if (message.child is Reservation) return null;
    if (!_isAfterHeartbeatBoundary(message.createdAt)) return null;

    final senderName = await _resolveDisplayName(message.pubKey);
    return _BackgroundSignal(
      id: 'message:${message.id}',
      body: '$senderName sent you a message',
      createdAt: message.createdAt,
    );
  }

  Future<List<_BackgroundSignal>> _signalsFromHostings(
    List<Validation<ReservationPair>> validations,
  ) async {
    final myPubkey = auth.getActiveKey().publicKey;
    final signals = <_BackgroundSignal>[];

    for (final validation in validations) {
      final pair = validation.event;
      final guestReservation = pair.buyerReservation;
      if (guestReservation == null) continue;
      if (guestReservation.pubKey == myPubkey) continue;
      if (!_isAfterHeartbeatBoundary(guestReservation.createdAt)) continue;

      final guestName = await _resolveDisplayName(guestReservation.pubKey);
      final title = await _resolveListingTitle(
        pair.listingAnchor,
        fallback: 'your listing',
      );

      if (guestReservation.cancelled) {
        signals.add(
          _BackgroundSignal(
            id: 'hosting-cancel:${guestReservation.id}',
            body: '$guestName cancelled a reservation',
            createdAt: guestReservation.createdAt,
          ),
        );
      } else {
        signals.add(
          _BackgroundSignal(
            id: 'hosting-reservation:${guestReservation.id}',
            body: '$guestName reserved $title',
            createdAt: guestReservation.createdAt,
          ),
        );
      }
    }

    return signals;
  }

  Future<List<_BackgroundSignal>> _signalsFromTrips(
    List<Validation<ReservationPair>> validations,
  ) async {
    final myPubkey = auth.getActiveKey().publicKey;
    final signals = <_BackgroundSignal>[];

    for (final validation in validations) {
      final pair = validation.event;
      final sellerReservation = pair.sellerReservation;
      if (sellerReservation == null) continue;
      if (sellerReservation.pubKey == myPubkey) continue;
      if (!_isAfterHeartbeatBoundary(sellerReservation.createdAt)) continue;

      if (!sellerReservation.cancelled && !sellerReservation.isCommit) {
        continue;
      }

      final hostName = await _resolveDisplayName(sellerReservation.pubKey);
      final title = await _resolveListingTitle(
        pair.listingAnchor,
        fallback: 'your stay',
      );

      if (sellerReservation.cancelled) {
        signals.add(
          _BackgroundSignal(
            id: 'trip-cancel:${sellerReservation.id}',
            body: '$hostName cancelled a reservation',
            createdAt: sellerReservation.createdAt,
          ),
        );
      } else {
        signals.add(
          _BackgroundSignal(
            id: 'trip-confirm:${sellerReservation.id}',
            body: '$hostName confirmed your stay at $title',
            createdAt: sellerReservation.createdAt,
          ),
        );
      }
    }

    return signals;
  }

  void _mirrorStatus<T>(
    StreamWithStatus<T> source,
    StreamWithStatus<_BackgroundSignal> target,
  ) {
    target.addSubscription(
      source.status
          .distinct((a, b) => a.runtimeType == b.runtimeType)
          .listen(target.addStatus, onError: target.addError),
    );
  }

  void _emitSignal(_BackgroundSignal signal) {
    if (!_isAfterHeartbeatBoundary(signal.createdAt)) return;
    if (!_emittedNotificationIds.add(signal.id)) return;

    final notification = BackgroundNotification(
      operationId: signal.id,
      body: signal.body,
    );

    _notifications.add(notification);
    _watchProgress?.call(notification);
  }

  Future<void> _publishHeartbeat() =>
      logger.span('_publishHeartbeat', () async {
        await _runSafe('upsertHeartbeat', () async {
          final heartbeat = await heartbeats.upsertCurrent();
          if (heartbeat.createdAt > _latestHeartbeatCreatedAt) {
            _latestHeartbeatCreatedAt = heartbeat.createdAt;
          }
        });
      });

  bool _isReadyStatus(StreamStatus status) =>
      status is StreamStatusLive || status is StreamStatusQueryComplete;

  bool _isAfterHeartbeatBoundary(int createdAt) =>
      createdAt > _notificationBoundary;

  Future<void> _waitUntilReady() async {
    if (_ready.value) return;
    await _ready.stream.firstWhere((ready) => ready);
  }

  Future<String> _resolveListingTitle(
    String listingAnchor, {
    required String fallback,
  }) async {
    final cached = _listingTitleCache[listingAnchor];
    if (cached != null) return cached;

    try {
      final listing = await listings.getOneByAnchor(listingAnchor);
      final title = listing?.title ?? fallback;
      _listingTitleCache[listingAnchor] = title;
      return title;
    } catch (_) {
      return fallback;
    }
  }

  Future<BackgroundWorkerResult> recoverOnchainOperations({
    OnBackgroundProgress? onProgress,
  }) => logger.span('recoverOnchainOperations', () async {
    logger.i('starting onchain recovery');
    final notifications = <String>[];

    if (auth.activeKeyPair == null) {
      logger.d('no active key pair, skipping');
      return const BackgroundWorkerResult();
    }

    await _runSafe('recoverOnchainOps', () async {
      await evm.recoverStaleOperations(
        isBackground: true,
        onProgress: (notification) {
          notifications.add(notification.body);
          onProgress?.call(notification);
        },
      );
    });

    await _runSafe('autoWithdraw', () async {
      await autoWithdraw.checkNow();
    });

    logger.i(
      'onchain recovery completed '
      'with ${notifications.length} notifications',
    );
    return BackgroundWorkerResult(notifications: notifications);
  });

  static const _onchainNamespaces = ['swap_in', 'swap_out', 'escrow_fund'];

  Future<bool> hasActiveOnchainOperations() =>
      logger.span('hasActiveOnchainOperations', () async {
        for (final ns in _onchainNamespaces) {
          final hasNonTerminal = await operationStore.hasNonTerminal(ns);
          if (hasNonTerminal) return true;
        }
        return false;
      });

  Future<String> _resolveDisplayName(String pubkey) async {
    try {
      final profile = await metadata.loadMetadata(pubkey);
      if (profile != null) {
        final m = profile.metadata;
        if (m.name != null && m.name!.isNotEmpty) return m.name!;
        if (m.displayName != null && m.displayName!.isNotEmpty) {
          return m.displayName!;
        }
      }
    } catch (_) {
      // Fall through to truncated key.
    }
    return '${pubkey.substring(0, 8)}…';
  }

  Future<void> _runSafe(String name, Future<void> Function() task) async {
    await logger.span('task.$name', () async {
      try {
        await task();
      } catch (e, st) {
        logger.e('BackgroundWorker[$name] failed', error: e, stackTrace: st);
      }
    });
  }
}
