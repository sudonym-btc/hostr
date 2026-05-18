import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event;
import 'package:rxdart/rxdart.dart';

import '../../datasources/notification_log.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import '../evm/evm.dart';
import '../evm/operations/funds_monitor/funds_monitor_service.dart';
import '../evm/operations/operation_state_store.dart';
import '../heartbeat/heartbeat.dart';
import '../listings/listings.dart';
import '../metadata/metadata.dart';
import '../reservation_groups/reservation_group_participant_resolver.dart';
import '../user_subscriptions/user_subscriptions.dart';

/// A single notification to show or update in the OS notification tray.
class BackgroundNotification {
  static const String fallbackPayload = 'hostr://root';

  /// Stable identifier for this notification — used to update the same OS
  /// notification across progressive state changes (e.g. swap → deposit).
  final String operationId;

  /// Human-readable body text.
  final String body;

  /// Opaque deep-link payload forwarded to the app when the user taps the
  /// notification.
  final String payload;

  const BackgroundNotification({
    required this.operationId,
    required this.body,
    this.payload = fallbackPayload,
  });
}

/// Callback for real-time notification updates during background recovery.
typedef OnBackgroundProgress =
    void Function(BackgroundNotification notification);

/// Result of a single background worker run, containing all notifications
/// that should be surfaced to the user.
class BackgroundWorkerResult {
  final List<BackgroundNotification> notificationDetails;

  const BackgroundWorkerResult({this.notificationDetails = const []});

  List<String> get notifications =>
      notificationDetails.map((notification) => notification.body).toList();

  bool get hasNotifications => notificationDetails.isNotEmpty;
}

enum _BackgroundWorkerMode { run, watch }

class _BackgroundSignal {
  final String id;
  final String body;
  final int createdAt;
  final String payload;

  const _BackgroundSignal({
    required this.id,
    required this.body,
    required this.createdAt,
    this.payload = BackgroundNotification.fallbackPayload,
  });
}

@Singleton()
class BackgroundWorker {
  final Auth _auth;
  final UserSubscriptions _userSubscriptions;
  final Heartbeats _heartbeats;
  final Evm _evm;
  final FundsMonitorService _fundsMonitor;
  final Listings _listings;
  final MetadataUseCase _metadata;
  final OperationStateStore _operationStore;
  final NotificationLog _notificationLog;
  final CustomLogger _logger;

  final StreamWithStatus<_BackgroundSignal> _messagesProcessor$ =
      StreamWithStatus<_BackgroundSignal>();
  final StreamWithStatus<_BackgroundSignal> _myHostingsProcessor$ =
      StreamWithStatus<_BackgroundSignal>();
  final StreamWithStatus<_BackgroundSignal> _myTripsProcessor$ =
      StreamWithStatus<_BackgroundSignal>();
  final StreamWithStatus<_BackgroundSignal> _autoWithdrawProcessor$ =
      StreamWithStatus<_BackgroundSignal>();
  final StreamWithStatus<_BackgroundSignal>
  _onchainOperationsRecoveryProcessor$ = StreamWithStatus<_BackgroundSignal>();

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
    required FundsMonitorService fundsMonitor,
    required Listings listings,
    required MetadataUseCase metadata,
    required OperationStateStore operationStore,
    required NotificationLog notificationLog,
    required CustomLogger logger,
  }) : _auth = auth,
       _userSubscriptions = userSubscriptions,
       _heartbeats = heartbeats,
       _evm = evm,
       _fundsMonitor = fundsMonitor,
       _listings = listings,
       _metadata = metadata,
       _operationStore = operationStore,
       _notificationLog = notificationLog,
       _logger = logger.scope('bg-worker');

  Future<void> watch({OnBackgroundProgress? onProgress}) =>
      _logger.span('watch', () async {
        if (_auth.activeKeyPair == null) {
          _logger.d('no active key pair, skipping watch');
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
      _logger.span('run', () async {
        if (_auth.activeKeyPair == null) {
          _logger.d('no active key pair, skipping');
          return const BackgroundWorkerResult();
        }

        final startedHere = !_started;
        if (startedHere) {
          await _start(mode: _BackgroundWorkerMode.run, onProgress: onProgress);
        }

        final notifications = <BackgroundNotification>[];
        final notificationSub = _notifications.replayStream.listen((
          notification,
        ) {
          notifications.add(notification);
        });

        try {
          await _waitUntilReady();
          await _maintenanceFuture;
          return BackgroundWorkerResult(notificationDetails: notifications);
        } finally {
          await notificationSub.cancel();
          if (startedHere && _mode == _BackgroundWorkerMode.run) {
            await stop();
          }
        }
      });

  Future<void> stop() => _logger.span('stop', () async {
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

    await _messagesProcessor$.reset();
    await _myHostingsProcessor$.reset();
    await _myTripsProcessor$.reset();
    await _autoWithdrawProcessor$.reset();
    await _onchainOperationsRecoveryProcessor$.reset();
    await _notifications.reset();
  });

  Future<void> _start({
    required _BackgroundWorkerMode mode,
    OnBackgroundProgress? onProgress,
  }) => _logger.span('_start', () async {
    if (_started) return;
    _started = true;
    _mode = mode;
    _watchProgress = onProgress;
    _ready.add(false);
    _emittedNotificationIds.clear();
    _listingTitleCache.clear();

    await _userSubscriptions.start();
    await _bootstrapHeartbeatBoundary(mode);
    _wireProcessors();
    if (mode == _BackgroundWorkerMode.run) {
      await _seedInitialNotifications();
    }

    _maintenanceFuture = _startMaintenanceProcessors(
      mode: mode,
      onProgress: onProgress,
    );
    if (mode == _BackgroundWorkerMode.watch) {
      unawaited(_maintenanceFuture);
    }
  });

  Future<void> _bootstrapHeartbeatBoundary(_BackgroundWorkerMode mode) =>
      _logger.span('_bootstrapHeartbeatBoundary', () async {
        final myPubkey = _auth.getActiveKey().publicKey;

        _heartbeatSubscription = mode == _BackgroundWorkerMode.watch
            ? _heartbeats.subscribeUsers([
                myPubkey,
              ], name: 'background-worker-heartbeat-watch')
            : _heartbeats.queryUsers([
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
              _logger.e(
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
    _bindTripReviewProcessor();
    _bindReadinessBarrier();

    for (final processor in <StreamWithStatus<_BackgroundSignal>>[
      _messagesProcessor$,
      _myHostingsProcessor$,
      _myTripsProcessor$,
    ]) {
      _sessionSubscriptions.add(
        processor.replayStream.listen(
          _emitSignal,
          onError: (Object e, StackTrace st) {
            _logger.e(
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
    final processed = _userSubscriptions.giftwraps$
        .asyncMap(_signalFromEvent)
        .where((signal) => signal != null)
        .map((signal) => signal!);
    _messagesProcessor$.pipeFrom(processed);
  }

  void _bindHostingsProcessor() {
    final processed = _userSubscriptions.myResolvedHostings$
        .asyncMap(_signalFromHosting)
        .where((signal) => signal != null)
        .map<_BackgroundSignal>((signal) => signal!);
    _myHostingsProcessor$.pipeFrom(processed);
  }

  void _bindTripsProcessor() {
    final processed = _userSubscriptions.myResolvedTrips$
        .asyncMap(_signalFromTrip)
        .where((signal) => signal != null)
        .map<_BackgroundSignal>((signal) => signal!);
    _myTripsProcessor$.pipeFrom(processed);
  }

  Future<void> _seedInitialNotifications() async {
    for (final raw in _userSubscriptions.giftwraps$.items) {
      final signal = await _signalFromEvent(raw);
      if (signal != null) _emitSignal(signal);
    }

    for (final group in _userSubscriptions.myResolvedHostings$.items) {
      final signal = await _signalFromHosting(group);
      if (signal != null) _emitSignal(signal);
    }

    for (final group in _userSubscriptions.myResolvedTrips$.items) {
      final signal = await _signalFromTrip(group);
      if (signal != null) _emitSignal(signal);
    }
  }

  /// Listens to completed trips and fires a one-time "leave a review"
  /// notification per trade. Uses [NotificationLog] for persistent
  /// deduplication so the notification is shown at most once per device,
  /// even across app restarts.
  void _bindTripReviewProcessor() {
    _sessionSubscriptions.add(
      _userSubscriptions.myTrips$.replayStream
          .asyncMap(_signalFromTripReview)
          .where((signal) => signal != null)
          .cast<_BackgroundSignal>()
          .listen(
            _emitSignal,
            onError: (Object e, StackTrace st) {
              _logger.e(
                'BackgroundWorker trip-review processor failed',
                error: e,
                stackTrace: st,
              );
            },
          ),
    );
  }

  Future<_BackgroundSignal?> _signalFromTripReview(
    Validation<ReservationGroup> validation,
  ) async {
    final group = validation.event;
    if (group.cancelled) return null;
    if (!group.isCompleted) return null;

    final notificationId = 'trip-review-request:${group.tradeId}';
    if (!_notificationLog.tryMarkDisplayed(notificationId)) return null;

    final title = await _resolveListingTitle(
      group.listingAnchor,
      fallback: 'your stay',
    );

    return _BackgroundSignal(
      id: notificationId,
      body: 'How was your stay? Leave a review for $title',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      payload: _threadPayload(group.tradeId),
    );
  }

  void _bindReadinessBarrier() {
    _sessionSubscriptions.add(
      Rx.combineLatestList<StreamStatus>([
        _messagesProcessor$.status,
        _myHostingsProcessor$.status,
        _myTripsProcessor$.status,
      ]).listen((statuses) async {
        if (_heartbeatPublished) return;
        if (!statuses.every(_isReadyStatus)) return;

        _heartbeatPublished = true;
        _publishHeartbeat();
        _ready.add(true);
      }),
    );
  }

  Future<void> _startMaintenanceProcessors({
    required _BackgroundWorkerMode mode,
    OnBackgroundProgress? onProgress,
  }) => _logger.span('_startMaintenanceProcessors', () async {
    await Future.wait([
      _runAutoWithdrawProcessor(mode),
      _runOnchainRecoveryProcessor(mode, onProgress: onProgress),
    ]);
  });

  Future<void> _runAutoWithdrawProcessor(_BackgroundWorkerMode mode) =>
      _logger.span('_runAutoWithdrawProcessor', () async {
        _autoWithdrawProcessor$.addStatus(StreamStatusQuerying());
        await _fundsMonitor.start();
        if (mode == _BackgroundWorkerMode.watch) {
          _logger.d('funds monitor started for watch run');
        } else {
          await _runSafe('autoWithdraw', () async {
            await _fundsMonitor.checkNow();
          });
        }
        _autoWithdrawProcessor$.addStatus(StreamStatusLive());
      });

  Future<void> _runOnchainRecoveryProcessor(
    _BackgroundWorkerMode mode, {
    OnBackgroundProgress? onProgress,
  }) => _logger.span('_runOnchainRecoveryProcessor', () async {
    _onchainOperationsRecoveryProcessor$.addStatus(StreamStatusQuerying());
    await _runSafe('recoverOnchainOps', () async {
      await _evm.recoverStaleOperations(
        isBackground: mode == _BackgroundWorkerMode.run,
        onProgress: onProgress,
      );
    });
    _onchainOperationsRecoveryProcessor$.addStatus(StreamStatusLive());
  });

  Future<_BackgroundSignal?> _signalFromEvent(Nip01Event raw) async {
    if (raw is! Message) return null;
    final message = raw;
    final myPubkey = _auth.activePubkey ?? _auth.getActiveKey().publicKey;
    if (_isSelfNotification(message, myPubkey)) return null;
    if (!_isAfterHeartbeatBoundary(message.createdAt)) return null;

    final notificationId = 'message:${message.id}';
    if (!_notificationLog.tryMarkDisplayed(notificationId)) return null;

    final senderName = await _resolveDisplayName(message.pubKey);
    final label = message.child is Reservation
        ? 'reservation proposal'
        : 'message';
    return _BackgroundSignal(
      id: notificationId,
      body: '$senderName sent you a $label',
      createdAt: message.createdAt,
    );
  }

  bool _isSelfNotification(Message message, String myPubkey) {
    if (message.pubKey == myPubkey) return true;
    final participants = <String>{message.pubKey, ...message.pTags}
      ..removeWhere((pubkey) => pubkey.isEmpty || pubkey == myPubkey);
    return participants.isEmpty;
  }

  Future<_BackgroundSignal?> _signalFromHosting(
    ResolvedValidatedReservationGroupParticipants item,
  ) async {
    final myPubkey = _auth.getActiveKey().publicKey;
    final group = item.group;
    final guestReservation = group.buyerReservation;
    if (guestReservation == null) return null;
    if (guestReservation.pubKey == myPubkey) return null;
    if (!_isAfterHeartbeatBoundary(guestReservation.createdAt)) return null;

    final guestPubkey = _resolveHostingGuestPubkey(item);
    final guestName = await _resolveDisplayName(guestPubkey);
    final title = await _resolveListingTitle(
      group.listingAnchor,
      fallback: 'your listing',
    );

    if (guestReservation.cancelled) {
      return _BackgroundSignal(
        id: 'hosting-cancel:${guestReservation.id}',
        body: '$guestName cancelled a reservation',
        createdAt: guestReservation.createdAt,
        payload: _threadPayload(group.tradeId),
      );
    }

    return _BackgroundSignal(
      id: 'hosting-reservation:${guestReservation.id}',
      body: '$guestName reserved $title',
      createdAt: guestReservation.createdAt,
      payload: _threadPayload(group.tradeId),
    );
  }

  String _resolveHostingGuestPubkey(
    ResolvedValidatedReservationGroupParticipants item,
  ) {
    final resolved = item.participants.resolvedParticipantPubkeyForRole(
      'buyer',
    );
    if (resolved != null && resolved.isNotEmpty) {
      return resolved;
    }

    final fallback = item.participants.rawParticipantPubkeyForRole('buyer');
    if (fallback == null || fallback.isEmpty) {
      throw StateError(
        'Cannot resolve guest pubkey without a buyer participant',
      );
    }
    return fallback;
  }

  Future<_BackgroundSignal?> _signalFromTrip(
    ResolvedValidatedReservationGroupParticipants item,
  ) async {
    final myPubkey = _auth.getActiveKey().publicKey;
    final group = item.group;
    final sellerReservation = group.sellerReservation;
    if (sellerReservation == null) return null;
    if (sellerReservation.pubKey == myPubkey) return null;
    if (!_isAfterHeartbeatBoundary(sellerReservation.createdAt)) return null;

    if (!sellerReservation.cancelled && !sellerReservation.isCommit) {
      return null;
    }

    final hostPubkey =
        item.participants.resolvedParticipantPubkeyForRole('seller') ??
        sellerReservation.pubKey;
    final hostName = await _resolveDisplayName(hostPubkey);
    final title = await _resolveListingTitle(
      group.listingAnchor,
      fallback: 'your stay',
    );

    if (sellerReservation.cancelled) {
      return _BackgroundSignal(
        id: 'trip-cancel:${sellerReservation.id}',
        body: '$hostName cancelled a reservation',
        createdAt: sellerReservation.createdAt,
        payload: _threadPayload(group.tradeId),
      );
    }

    return _BackgroundSignal(
      id: 'trip-confirm:${sellerReservation.id}',
      body: '$hostName confirmed your stay at $title',
      createdAt: sellerReservation.createdAt,
      payload: _threadPayload(group.tradeId),
    );
  }

  void _emitSignal(_BackgroundSignal signal) {
    if (!_isAfterHeartbeatBoundary(signal.createdAt)) return;
    if (!_emittedNotificationIds.add(signal.id)) return;

    final notification = BackgroundNotification(
      operationId: signal.id,
      body: signal.body,
      payload: signal.payload,
    );

    _notifications.add(notification);
    _watchProgress?.call(notification);
  }

  void _publishHeartbeat() {
    unawaited(
      _logger.span('_publishHeartbeat', () async {
        await _runSafe('upsertHeartbeat', () async {
          final heartbeat = await _heartbeats.requestUpsertCurrent();
          if (heartbeat.createdAt > _latestHeartbeatCreatedAt) {
            _latestHeartbeatCreatedAt = heartbeat.createdAt;
          }
        });
      }),
    );
  }

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
      final listing = await _listings.getOneByAnchor(listingAnchor);
      final title = listing?.title ?? fallback;
      _listingTitleCache[listingAnchor] = title;
      return title;
    } catch (_) {
      return fallback;
    }
  }

  Future<BackgroundWorkerResult> recoverOnchainOperations({
    OnBackgroundProgress? onProgress,
  }) => _logger.span('recoverOnchainOperations', () async {
    _logger.i('starting onchain recovery');
    final notifications = <BackgroundNotification>[];

    if (_auth.activeKeyPair == null) {
      _logger.d('no active key pair, skipping');
      return const BackgroundWorkerResult();
    }

    await _runSafe('recoverOnchainOps', () async {
      await _evm.recoverStaleOperations(
        isBackground: true,
        onProgress: (notification) {
          notifications.add(notification);
          onProgress?.call(notification);
        },
      );
    });

    await _runSafe('autoWithdraw', () async {
      await _fundsMonitor.checkNow();
    });

    _logger.i(
      'onchain recovery completed '
      'with ${notifications.length} notifications',
    );
    return BackgroundWorkerResult(notificationDetails: notifications);
  });

  String _threadPayload(String threadId) =>
      Uri(scheme: 'hostr', host: 'thread', pathSegments: [threadId]).toString();

  static const _onchainNamespaces = ['swap_in', 'swap_out', 'escrow_fund'];

  Future<bool> hasActiveOnchainOperations() =>
      _logger.span('hasActiveOnchainOperations', () async {
        for (final ns in _onchainNamespaces) {
          final hasNonTerminal = await _operationStore.hasNonTerminal(ns);
          if (hasNonTerminal) return true;
        }
        return false;
      });

  Future<String> _resolveDisplayName(String pubkey) async {
    try {
      final profile = await _metadata.loadMetadata(pubkey);
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
    await _logger.span('task.$name', () async {
      try {
        await task();
      } catch (e, st) {
        _logger.e('BackgroundWorker[$name] failed', error: e, stackTrace: st);
      }
    });
  }
}
