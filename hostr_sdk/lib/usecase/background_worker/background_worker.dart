import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

import '../../util/main.dart';
import '../auth/auth.dart';
import '../evm/evm.dart';
import '../evm/operations/auto_withdraw/auto_withdraw_service.dart';
import '../listings/listings.dart';
import '../messaging/threads.dart';
import '../metadata/metadata.dart';
import '../reservations/reservations.dart';
import '../reviews/reviews.dart';

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
    required this.logger,
  });

  /// Runs all background tasks and collects notification messages.
  Future<BackgroundWorkerResult> run() async {
    logger.i('BackgroundWorker: starting run');
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

    // ── 2. Recover pending swaps ──────────────────────────────────────
    await _runSafe('recoverSwaps', () async {
      evm.recoverStaleSwaps();
    });

    // ── 3. Run auto-withdraw ─────────────────────────────────────────
    await _runSafe('autoWithdraw', () async {
      autoWithdraw.checkNow();
    });

    // ── 4. Check for new reservations on my listings ─────────────────
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
          if (reservation.parsedContent.cancelled) continue;
          if (reservation.createdAt <= lastSync) continue;

          final guestName = await _resolveDisplayName(reservation.pubKey);
          final title = listing.parsedContent.title;
          notifications.add('$guestName reserved $title');
        }
      }
    });

    // ── 5. Check for host-confirmed self-signed reservations ─────────
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

        final commitmentHash = ParticipationProof.computeCommitmentHash(
          myPubkey,
          lastRequest.parsedContent.salt,
        );

        final matchingReservations = await reservations.getListingReservations(
          listingAnchor: listingAnchor,
        );

        final hostConfirmed = matchingReservations.any(
          (r) =>
              r.pubKey == hostPubkey &&
              r.parsedTags.commitmentHash == commitmentHash &&
              !r.parsedContent.cancelled,
        );

        if (hostConfirmed) {
          final hostName = await _resolveDisplayName(hostPubkey);
          final listing = await listings.getOneByAnchor(listingAnchor);
          final title = listing?.parsedContent.title ?? 'your stay';
          notifications.add('$hostName confirmed your stay at $title');
        }
      }
    });

    // ── 6. Check for counterparty cancellations ──────────────────────
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
          if (!reservation.parsedContent.cancelled) continue;
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
          if (!reservation.parsedContent.cancelled) continue;
          if (reservation.createdAt <= lastSync) continue;

          final cancellerName = await _resolveDisplayName(hostPubkey);
          notifications.add('$cancellerName cancelled a reservation');
        }
      }
    });

    // ── 7. Check for new reviews on my listings ──────────────────────
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
          final title = listing.parsedContent.title;
          notifications.add('$reviewerName left a review on $title');
        }
      }
    });

    logger.i(
      'BackgroundWorker: completed with ${notifications.length} notifications',
    );
    return BackgroundWorkerResult(notifications: notifications);
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
