import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

import '../../util/main.dart';
import '../auth/auth.dart';
import '../evm/evm.dart';
import '../evm/operations/auto_withdraw/auto_withdraw_service.dart';
import '../evm/operations/operation_state_store.dart';
import '../listings/listings.dart';
import '../messaging/threads.dart';
import '../metadata/metadata.dart';
import '../reservations/reservations.dart';
import '../reviews/reviews.dart';

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

/// Orchestrates all background sync tasks that should run while the app is
/// suspended. Each task is isolated and fault-tolerant — a failure in one
/// does not prevent the others from executing.
///
/// Usage from the callback dispatcher:
/// ```dart
/// final result = await getIt<Hostr>().backgroundWorker.run();
/// for (final notification in result.notifications) {
///   FlutterLocalNotificationsPlugin().show(..., body: notification);
/// }
/// ```
@Singleton()
class BackgroundWorker {
  final Auth auth;
  final Threads threads;
  final Evm evm;
  final AutoWithdrawService autoWithdraw;
  final Reservations reservations;
  final Reviews reviews;
  final Listings listings;
  final MetadataUseCase metadata;
  final OperationStateStore operationStore;
  final CustomLogger logger;

  BackgroundWorker({
    required this.auth,
    required this.threads,
    required this.evm,
    required this.autoWithdraw,
    required this.reservations,
    required this.reviews,
    required this.listings,
    required this.metadata,
    required this.operationStore,
    required CustomLogger logger,
  }) : logger = logger.namespace('bg-worker');

  /// Runs the periodic background sync: messages, reservations, reviews,
  /// cancellations, and auto-withdraw.
  ///
  /// Does **not** recover onchain operations — use
  /// [recoverOnchainOperations] for that (typically triggered when the app
  /// goes to background with active operations).
  Future<BackgroundWorkerResult> run() async {
    logger.i('BackgroundWorker: starting periodic sync');
    final notifications = <String>[];

    if (auth.activeKeyPair == null) {
      logger.d('BackgroundWorker: no active key pair, skipping');
      return const BackgroundWorkerResult();
    }

    final myPubkey = auth.getActiveKey().publicKey;

    // ── 1. Sync new messages ──────────────────────────────────────────
    await _runSafe('syncMessages', () async {
      final newMessages = await threads.refresh();
      if (newMessages.isNotEmpty) {
        notifications.add('You have ${newMessages.length} new messages');
      }
    });

    // ── 2. Run auto-withdraw ─────────────────────────────────────────
    await _runSafe('autoWithdraw', () async {
      autoWithdraw.checkNow();
    });

    // ── 3. Check for new reservations on my listings ─────────────────
    await _runSafe('checkNewReservations', () async {
      final myListings = await listings.list(
        Filter(kinds: Listing.kinds, authors: [myPubkey]),
      );

      for (final listing in myListings) {
        if (listing.anchor == null) continue;

        final listingReservations = await reservations.getListingReservations(
          listingAnchor: listing.anchor!,
        );

        // Find reservations made by others (guests) that are recent
        // and not yet seen. "Recent" is approximated as created after
        // the most recent message timestamp, which represents the last
        // sync boundary.
        final lastSync = threads.getMostRecentTimestamp() ?? 0;

        for (final reservation in listingReservations) {
          if (reservation.pubKey == myPubkey) continue;
          if (reservation.cancelled) continue;
          if (reservation.createdAt <= lastSync) continue;

          final guestName = await _resolveDisplayName(reservation.pubKey);
          final title = listing.title;
          notifications.add('$guestName reserved $title');
        }
      }
    });

    // ── 4. Check for host-confirmed self-signed reservations ─────────
    await _runSafe('checkHostConfirmations', () async {
      // Look through threads for reservation requests we sent, and check
      // whether the host has now published a matching reservation.
      for (final thread in threads.threads.values) {
        final threadState = thread.state.valueOrNull;
        if (threadState == null) continue;
        if (threadState.reservationRequests.isEmpty) continue;

        final lastRequest = threadState.lastReservationRequest;

        // Only care about requests WE made (as guest).
        if (lastRequest.pubKey != myPubkey) continue;

        final listingAnchor = lastRequest.parsedTags.listingAnchor;
        final hostPubkey = getPubKeyFromAnchor(listingAnchor);

        final matchingReservations = await reservations.getListingReservations(
          listingAnchor: listingAnchor,
        );

        final hostConfirmed = matchingReservations.any(
          (r) =>
              r.pubKey == hostPubkey &&
              r.getDtag() == lastRequest.getDtag() &&
              !r.cancelled,
        );

        if (hostConfirmed) {
          final hostName = await _resolveDisplayName(hostPubkey);
          final listing = await listings.getOneByAnchor(listingAnchor);
          final title = listing?.title ?? 'your stay';
          notifications.add('$hostName confirmed your stay at $title');
        }
      }
    });

    // ── 5. Check for counterparty cancellations ──────────────────────
    await _runSafe('checkCancellations', () async {
      final myListings = await listings.list(
        Filter(kinds: Listing.kinds, authors: [myPubkey]),
      );

      for (final listing in myListings) {
        if (listing.anchor == null) continue;

        final listingReservations = await reservations.getListingReservations(
          listingAnchor: listing.anchor!,
        );

        final lastSync = threads.getMostRecentTimestamp() ?? 0;

        for (final reservation in listingReservations) {
          if (reservation.pubKey == myPubkey) continue;
          if (!reservation.cancelled) continue;
          if (reservation.createdAt <= lastSync) continue;

          final cancellerName = await _resolveDisplayName(reservation.pubKey);
          notifications.add('$cancellerName cancelled a reservation');
        }
      }

      // Also check cancellations on reservations where I'm the guest.
      for (final thread in threads.threads.values) {
        final threadState = thread.state.valueOrNull;
        if (threadState == null) continue;
        if (threadState.reservationRequests.isEmpty) continue;

        final lastRequest = threadState.lastReservationRequest;
        if (lastRequest.pubKey != myPubkey) continue;

        final listingAnchor = lastRequest.parsedTags.listingAnchor;
        final hostPubkey = getPubKeyFromAnchor(listingAnchor);

        final matchingReservations = await reservations.getListingReservations(
          listingAnchor: listingAnchor,
        );

        final lastSync = threads.getMostRecentTimestamp() ?? 0;

        for (final reservation in matchingReservations) {
          if (reservation.pubKey != hostPubkey) continue;
          if (!reservation.cancelled) continue;
          if (reservation.createdAt <= lastSync) continue;

          final cancellerName = await _resolveDisplayName(hostPubkey);
          notifications.add('$cancellerName cancelled a reservation');
        }
      }
    });

    // ── 6. Check for new reviews on my listings ──────────────────────
    await _runSafe('checkNewReviews', () async {
      final myListings = await listings.list(
        Filter(kinds: Listing.kinds, authors: [myPubkey]),
      );

      final lastSync = threads.getMostRecentTimestamp() ?? 0;

      for (final listing in myListings) {
        if (listing.anchor == null) continue;

        final listingReviews = await reviews.list(
          Filter(
            kinds: Review.kinds,
            tags: {
              kListingRefTag: [listing.anchor!],
            },
          ),
        );

        for (final review in listingReviews) {
          if (review.pubKey == myPubkey) continue;
          if (review.createdAt <= lastSync) continue;

          final reviewerName = await _resolveDisplayName(review.pubKey);
          final title = listing.title;
          notifications.add('$reviewerName left a review on $title');
        }
      }
    });

    logger.i(
      'BackgroundWorker: completed with ${notifications.length} notifications',
    );
    return BackgroundWorkerResult(notifications: notifications);
  }

  /// Recovers all pending onchain operations (swaps, escrow fund/claim/
  /// release, auto-withdraw).
  ///
  /// This is meant to be triggered as a one-off background task when the
  /// app goes into the background with active operations, so they can
  /// complete without the user staring at a spinner.
  ///
  /// When [onProgress] is provided, recovery operations will fire real-time
  /// notifications (e.g. "Swap funds received", "Deposit completed") using
  /// a stable [BackgroundNotification.operationId] so the OS notification
  /// is updated in-place across progressive state changes.
  Future<BackgroundWorkerResult> recoverOnchainOperations({
    OnBackgroundProgress? onProgress,
  }) async {
    logger.i('BackgroundWorker: starting onchain recovery');
    final notifications = <String>[];

    if (auth.activeKeyPair == null) {
      logger.d('BackgroundWorker: no active key pair, skipping');
      return const BackgroundWorkerResult();
    }

    // ── Recover pending onchain operations (swaps + escrow) ───────────
    await _runSafe('recoverOnchainOps', () async {
      final swapToTradeId = await _buildSwapToTradeMapping();
      await evm.recoverStaleOperations(
        onProgress: onProgress,
        swapToTradeId: swapToTradeId,
      );
    });

    // ── Auto-withdraw ─────────────────────────────────────────────────
    await _runSafe('autoWithdraw', () async {
      autoWithdraw.checkNow();
    });

    logger.i(
      'BackgroundWorker: onchain recovery completed '
      'with ${notifications.length} notifications',
    );
    return BackgroundWorkerResult(notifications: notifications);
  }

  /// All operation namespaces that should trigger a background task.
  static const _onchainNamespaces = [
    'swap_in',
    'swap_out',
    'escrow_fund',
    'escrow_claim',
    'escrow_release',
  ];

  /// Whether there are any non-terminal onchain operations (swaps, escrow
  /// fund/claim/release, etc.).
  ///
  /// The app layer uses this to schedule a background task when the app is
  /// paused so that pending operations can complete.
  Future<bool> hasActiveOnchainOperations() async {
    for (final ns in _onchainNamespaces) {
      if (await operationStore.hasNonTerminal(ns)) return true;
    }
    return false;
  }

  /// Builds a mapping from swap `boltzId` → escrow `tradeId` so that
  /// notifications for a nested swap use the same stable ID as the parent
  /// escrow operation.
  Future<Map<String, String>> _buildSwapToTradeMapping() async {
    final mapping = <String, String>{};
    for (final ns in ['escrow_fund', 'escrow_claim', 'escrow_release']) {
      final entries = await operationStore.readAll(ns);
      for (final entry in entries) {
        final swapId = entry['swapId'] as String?;
        final tradeId = entry['id'] as String?;
        if (swapId != null && tradeId != null) {
          mapping[swapId] = tradeId;
        }
      }
    }
    return mapping;
  }

  /// Resolves a human-readable display name for a pubkey.
  /// Falls back to a truncated hex key if no profile metadata is available.
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

  /// Runs [task] catching and logging any errors without re-throwing,
  /// so that one failing task does not prevent subsequent tasks.
  Future<void> _runSafe(String name, Future<void> Function() task) async {
    try {
      await task();
    } catch (e, st) {
      logger.e('BackgroundWorker[$name] failed', error: e, stackTrace: st);
    }
  }
}
