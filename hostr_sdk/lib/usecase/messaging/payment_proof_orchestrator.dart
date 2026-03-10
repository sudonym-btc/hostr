import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01EventModel;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';

import '../../config.dart';
import '../../injection.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../listings/listings.dart';
import '../metadata/metadata.dart';
import '../reservations/reservations.dart';
import 'thread/thread.dart';
import 'threads.dart';
import 'user_subscriptions.dart';

/// Long-running singleton that watches the user-level payment and reservation
/// streams and auto-publishes payment proof (self-signed buyer reservation)
/// when a funded payment event is detected for a trade where:
///
/// - The user is the **guest** (not the listing host).
/// - No buyer reservation has been published yet for that trade.
///
/// Replaces the per-trade [ThreadPaymentProofOrchestrator] by operating
/// across all trades simultaneously from the shared [UserSubscriptions]
/// streams.
@Singleton()
class PaymentProofOrchestrator {
  final UserSubscriptions _userSubs;
  final Threads _threads;
  final Auth _auth;
  final Reservations _reservations;
  final Listings _listings;
  final MetadataUseCase _metadata;
  final CustomLogger _logger;

  /// Trade IDs that already have a buyer reservation — don't re-publish.
  final Set<String> _processedTradeIds = {};

  /// Trade IDs currently being processed (in-flight proof publication).
  final Set<String> _inFlightTradeIds = {};

  final List<StreamSubscription> _subscriptions = [];
  bool _started = false;

  PaymentProofOrchestrator({
    required UserSubscriptions userSubs,
    required Threads threads,
    required Auth auth,
    required Reservations reservations,
    required Listings listings,
    required MetadataUseCase metadata,
    required CustomLogger logger,
  }) : _userSubs = userSubs,
       _threads = threads,
       _auth = auth,
       _reservations = reservations,
       _listings = listings,
       _metadata = metadata,
       _logger = logger.scope('payment-proof');

  /// Start watching. Call after [UserSubscriptions.start].
  ///
  /// Immediately subscribes to zap-receipt and escrow-event **replay**
  /// streams so that events emitted before this call are not lost.
  /// Proof publication is gated on [allMyReservations$] finishing its
  /// initial load so we can check whether a buyer reservation already
  /// exists before publishing.
  void start() => _logger.spanSync('start', () {
    if (_started) return;
    _started = true;
    _logger.d('PaymentProofOrchestrator starting');

    // Track when reservations have finished the initial query.
    // Listen to reservations (replay) to mark trades as processed.
    _subscriptions.add(
      _userSubs.allMyReservations$.stream.replay.listen(_onReservation),
    );

    // Subscribe to payment events via replay so late-starting still gets
    // all previously emitted events.
    _subscriptions.add(_userSubs.paymentEvents$.replay.listen(_onPaymentEvent));
  });

  void _checkAndMarkExistingBuyerReservation(Reservation reservation) =>
      _logger.spanSync('_checkAndMarkExistingBuyerReservation', () {
        if (!reservation.isCommit) return;

        final tradeId = reservation.getDtag();
        if (tradeId == null || tradeId.isEmpty) return;

        // A committed reservation from someone other than the listing host
        // is a buyer reservation — mark as processed.
        final listingAnchor = reservation.parsedTags.listingAnchor;
        final hostPubkey = getPubKeyFromAnchor(listingAnchor);
        if (reservation.pubKey != hostPubkey) {
          _processedTradeIds.add(tradeId);
        }
      });

  void _onReservation(Reservation reservation) =>
      _logger.spanSync('_onReservation', () {
        _checkAndMarkExistingBuyerReservation(reservation);
      });

  void _onPaymentEvent(PaymentEvent event) =>
      _logger.spanSync('_onPaymentEvent', () {
        if (event is ZapFundedEvent) {
          _handleFundedEvent(tradeId: event.tradeId, funded: event);
        } else if (event is EscrowFundedEvent) {
          _handleFundedEvent(tradeId: event.tradeId, funded: event);
        }
      });

  Future<void> _handleFundedEvent({
    required String tradeId,
    required PaymentFundedEvent funded,
  }) => _logger.span('_handleFundedEvent', () async {
    // Re-check after seeding — another funded event may have triggered
    // publication while we were waiting.
    if (_processedTradeIds.contains(tradeId)) return;
    if (_inFlightTradeIds.contains(tradeId)) return;

    _logger.d('PaymentProofOrchestrator: handling payment $tradeId $funded');
    // Wait for reservations to finish loading so we can reliably check
    // whether a buyer reservation already exists before publishing.
    await _userSubs.allMyReservations$.stream.status
        .whereType<StreamStatusLive>()
        .first;
    _logger.d(
      'PaymentProofOrchestrator: finished all reservations fetch $funded',
    );

    // Re-check after await — reservations may have been marked processed
    // while we were waiting for the stream to go live.
    if (_processedTradeIds.contains(tradeId)) return;
    if (_inFlightTradeIds.contains(tradeId)) return;

    // Find the thread for this trade.
    final thread = _findThreadForTrade(tradeId);
    if (thread == null) {
      _logger.d('PaymentProofOrchestrator: no thread found for trade $tradeId');
      return;
    }

    final state = thread.state.valueOrNull;
    if (state == null || state.reservationRequests.isEmpty) return;

    final lastRequest = state.lastReservationRequest;
    final listingAnchor = lastRequest.parsedTags.listingAnchor;

    // Only guests publish payment proof — hosts don't.
    final myPubkey = _auth.getActiveKey().publicKey;
    final hostPubkey = getPubKeyFromAnchor(listingAnchor);
    if (myPubkey == hostPubkey) {
      _logger.d('PaymentProofOrchestrator: we are host for $tradeId, skipping');
      _processedTradeIds.add(tradeId);
      return;
    }

    // Check if a buyer reservation already exists.
    if (_hasBuyerReservation(tradeId, hostPubkey)) {
      _processedTradeIds.add(tradeId);
      return;
    }

    _inFlightTradeIds.add(tradeId);
    _logger.d('PaymentProofOrchestrator: publishing proof for trade $tradeId');

    try {
      final listing = await _listings.getOneByAnchor(listingAnchor);
      if (listing == null) {
        _logger.w(
          'PaymentProofOrchestrator: listing unavailable for $listingAnchor',
        );
        return;
      }

      final profile = await _metadata.loadMetadata(listing.pubKey);
      if (profile == null) {
        _logger.w(
          'PaymentProofOrchestrator: profile unavailable for '
          '${listing.pubKey}',
        );
        return;
      }

      final proof = PaymentProof(
        listing: listing,
        hoster: profile,
        zapProof: funded is ZapFundedEvent
            ? ZapProof(receipt: Nip01EventModel.fromEntity(funded.event))
            : null,
        escrowProof: funded is EscrowFundedEvent
            ? EscrowProof(
                txHash: funded.transactionHash,
                hostsTrustedEscrows: funded.escrowService!.sellerTrusts,
                hostsEscrowMethods: funded.escrowService!.sellerMethods,
                escrowService: funded.escrowService!.service,
              )
            : null,
      );

      final activeKeyPair = _deriveKeyPair(
        hostPubkey: listing.pubKey,
        tradeId: tradeId,
      );

      final reservation = await _reservations.createSelfSigned(
        activeKeyPair: activeKeyPair,
        negotiateReservation: lastRequest,
        proof: proof,
      );

      // Fire a "Trip booked!" notification so the user knows immediately.
      try {
        final show = getIt<HostrConfig>().showNotification;
        if (show != null) {
          await show(
            id: tradeId.hashCode,
            title: 'Hostr',
            body: 'Trip booked! 🎉',
          );
        }
      } catch (e) {
        _logger.w('PaymentProofOrchestrator: notification failed: $e');
      }

      _logger.d(
        'PaymentProofOrchestrator: published buyer reservation '
        '${reservation.id} for trade $tradeId',
      );
      _processedTradeIds.add(tradeId);
    } catch (e, st) {
      _logger.e(
        'PaymentProofOrchestrator: failed to publish proof '
        'for $tradeId: $e',
      );
      _logger.d('$st');
    } finally {
      _inFlightTradeIds.remove(tradeId);
    }
  });

  /// Checks if a buyer reservation already exists for [tradeId] in the
  /// user-level reservation accumulator.
  bool _hasBuyerReservation(String tradeId, String hostPubkey) =>
      _logger.spanSync('_hasBuyerReservation', () {
        final reservations = _userSubs.allMyReservations$.stream.list.value;
        return reservations.any((r) {
          final rTradeId = r.getDtag();
          return rTradeId == tradeId && r.pubKey != hostPubkey;
        });
      });

  /// Finds the [Thread] whose trade matches [tradeId].
  Thread? _findThreadForTrade(String tradeId) =>
      _logger.spanSync('_findThreadForTrade', () {
        if (!_threads.threads.containsKey(tradeId)) {
          return null;
        }
        return _threads.threads[tradeId];
      });

  /// Derives the salted key pair for a guest's self-signed reservation,
  /// mirroring [Trade.activeKeyPair].
  KeyPair _deriveKeyPair({
    required String hostPubkey,
    required String tradeId,
  }) => _logger.spanSync('_deriveKeyPair', () {
    final myPubkey = _auth.getActiveKey().publicKey;
    if (hostPubkey == myPubkey) {
      return _auth.getActiveKey();
    }
    return saltedKey(key: _auth.getActiveKey().privateKey!, salt: tradeId);
  });

  Future<void> reset() => _logger.span('reset', () async {
    if (!_started) return;
    _started = false;
    _logger.d('PaymentProofOrchestrator resetting');

    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _processedTradeIds.clear();
    _inFlightTradeIds.clear();
  });

  Future<void> dispose() => _logger.span('dispose', () async {
    await reset();
  });
}
