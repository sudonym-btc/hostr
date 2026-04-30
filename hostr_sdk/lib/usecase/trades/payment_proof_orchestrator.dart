import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Nip01EventModel;
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../../config.dart';
import '../../injection.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../listings/listings.dart';
import '../messaging/thread/thread.dart';
import '../messaging/threads.dart';
import '../metadata/metadata.dart';
import '../reservations/reservations.dart';
import '../trade_account_allocator/trade_account_allocator.dart';
import '../user_subscriptions/user_subscriptions.dart';

typedef _ProofBuilder =
    PaymentProof Function(Listing listing, ProfileMetadata profile);

/// Long-running singleton that watches the user-level payment and reservation
/// streams and auto-publishes payment proof (self-signed buyer reservation)
/// when a funded payment event is detected for a trade where:
///
/// - The user is the **guest** (not the listing host).
/// - No buyer reservation has been published yet for that trade.
@Singleton()
class PaymentProofOrchestrator {
  final UserSubscriptions _userSubs;
  final Threads _threads;
  final Auth _auth;
  final Reservations _reservations;
  final Listings _listings;
  final MetadataUseCase _metadata;
  final CustomLogger _logger;

  final Set<String> _processedTradeIds = {};
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

  Future<void> start() => _logger.span('start', () async {
    if (_started) return;
    _started = true;
    _logger.d('PaymentProofOrchestrator starting');

    _subscriptions.add(
      _userSubs.allMyReservations$.stream.stream.listen(_onReservation),
    );

    _subscriptions.add(
      _userSubs.paymentEvents$.replayStream
          .asyncMap(_onPaymentEvent)
          .listen(
            (_) {},
            onError: (e, st) {
              _logger.e('PaymentProofOrchestrator: payment stream error: $e');
              _logger.d('$st');
            },
          ),
    );

    for (final reservation in _userSubs.allMyReservations$.stream.items) {
      _onReservation(reservation);
    }
  });

  void _checkAndMarkExistingBuyerReservation(Reservation reservation) =>
      _logger.spanSync('_checkAndMarkExistingBuyerReservation', () {
        if (!reservation.isCommit) return;

        final tradeId = reservation.getDtag();
        if (tradeId == null || tradeId.isEmpty) return;

        final listingAnchor = reservation.parsedTags.listingAnchor;
        final sellerPubkey = getPubKeyFromAnchor(listingAnchor);
        if (reservation.pubKey != sellerPubkey) {
          _processedTradeIds.add(tradeId);
        }
      });

  void _onReservation(Reservation reservation) =>
      _logger.spanSync('_onReservation', () {
        _checkAndMarkExistingBuyerReservation(reservation);
      });

  Future<void> _onPaymentEvent(PaymentEvent event) =>
      _logger.span('_onPaymentEvent', () async {
        if (event is ZapFundedEvent) {
          await _handleFundedEvent(tradeId: event.tradeId, funded: event);
        } else if (event is EscrowFundedEvent) {
          await _handleFundedEvent(tradeId: event.tradeId, funded: event);
        }
      });

  Future<void> publishEscrowProofForCompletedSwap({
    required String tradeId,
    required String transactionHash,
    required EscrowServiceSelected escrowService,
  }) => _logger.span('publishEscrowProofForCompletedSwap', () async {
    await _publishProofForTrade(
      tradeId: tradeId,
      source: 'completed swap $transactionHash',
      buildProof: (listing, profile) => PaymentProof(
        listing: listing,
        hoster: profile,
        zapProof: null,
        escrowProof: EscrowProof(
          txHash: transactionHash,
          hostsEscrowMethods: escrowService.sellerMethods,
          escrowService: escrowService.service,
        ),
      ),
    );
  });

  Future<void> _handleFundedEvent({
    required String tradeId,
    required PaymentFundedEvent funded,
  }) => _logger.span('_handleFundedEvent', () async {
    _logger.d('PaymentProofOrchestrator: handling payment $tradeId $funded');
    await _publishProofForTrade(
      tradeId: tradeId,
      source: 'payment event $funded',
      buildProof: (listing, profile) => PaymentProof(
        listing: listing,
        hoster: profile,
        zapProof: funded is ZapFundedEvent
            ? ZapProof(receipt: Nip01EventModel.fromEntity(funded.event))
            : null,
        escrowProof: funded is EscrowFundedEvent
            ? EscrowProof(
                txHash: funded.transactionHash,
                hostsEscrowMethods: funded.escrowService!.sellerMethods,
                escrowService: funded.escrowService!.service,
              )
            : null,
      ),
    );
  });

  Future<void> _publishProofForTrade({
    required String tradeId,
    required String source,
    required _ProofBuilder buildProof,
  }) => _logger.span('_publishProofForTrade', () async {
    if (_processedTradeIds.contains(tradeId)) {
      _logger.d(
        'PaymentProofOrchestrator: already processed $tradeId from $source',
      );
      return;
    }
    if (_inFlightTradeIds.contains(tradeId)) {
      _logger.d(
        'PaymentProofOrchestrator: already publishing $tradeId from $source',
      );
      return;
    }

    _logger.d(
      'PaymentProofOrchestrator: publishing proof candidate for '
      '$tradeId from $source',
    );

    // A funded payment without a uniquely resolved reservation thread is the
    // failure mode behind missing self-signed proofs, so keep this visible in
    // e2e logs instead of silently abandoning the publish.
    final thread = _findThreadForTrade(tradeId);
    if (thread == null) {
      _logger.w(
        'PaymentProofOrchestrator: no unique thread found for trade $tradeId',
      );
      return;
    }

    final state = thread.state.valueOrNull;
    if (state == null || state.reservationRequests.isEmpty) {
      _logger.w(
        'PaymentProofOrchestrator: thread ${thread.anchor} has no reservation '
        'requests for trade $tradeId',
      );
      return;
    }

    final lastRequest = state.lastReservationRequest;
    final listingAnchor = lastRequest.parsedTags.listingAnchor;

    final myPubkey = _auth.getActiveKey().publicKey;
    final sellerPubkey = getPubKeyFromAnchor(listingAnchor);
    if (myPubkey == sellerPubkey) {
      _logger.d('PaymentProofOrchestrator: we are host for $tradeId, skipping');
      _processedTradeIds.add(tradeId);
      return;
    }

    _inFlightTradeIds.add(tradeId);

    try {
      if (await _hasBuyerReservation(tradeId, sellerPubkey)) {
        _processedTradeIds.add(tradeId);
        return;
      }

      _logger.d(
        'PaymentProofOrchestrator: publishing proof for trade $tradeId',
      );

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
          'PaymentProofOrchestrator: profile unavailable for ${listing.pubKey}',
        );
        return;
      }

      final proof = buildProof(listing, profile);

      final activeKeyPair = await _deriveKeyPair(
        sellerPubkey: listing.pubKey,
        tradeId: tradeId,
        lastRequest: lastRequest,
      );

      final reservation = await _reservations.createSelfSigned(
        activeKeyPair: activeKeyPair,
        negotiateReservation: lastRequest,
        proof: proof,
      );

      try {
        final show = getIt<HostrConfig>().showNotification;
        if (show != null) {
          await show(
            id: tradeId.hashCode,
            title: 'Hostr',
            body: 'Trip booked! 🎉',
            payload: _threadPayload(thread.anchor),
          );
        }
      } catch (e) {
        _logger.w('PaymentProofOrchestrator: notification failed: $e');
      }

      _logger.d(
        'PaymentProofOrchestrator: published buyer reservation ${reservation.id} for trade $tradeId',
      );
      _processedTradeIds.add(tradeId);
    } catch (e, st) {
      _logger.e(
        'PaymentProofOrchestrator: failed to publish proof for $tradeId: $e',
      );
      _logger.d('$st');
    } finally {
      _inFlightTradeIds.remove(tradeId);
    }
  });

  Future<bool> _hasBuyerReservation(String tradeId, String sellerPubkey) =>
      _logger.span('_hasBuyerReservation', () async {
        final reservations = _userSubs.allMyReservations$.stream.items;
        if (_containsBuyerReservation(reservations, tradeId, sellerPubkey)) {
          return true;
        }

        final queriedReservations = await _reservations.getByTradeId(tradeId);
        _logger.d(
          'existing buyer reservations ${queriedReservations.toString()}',
        );
        return _containsBuyerReservation(
          queriedReservations,
          tradeId,
          sellerPubkey,
        );
      });

  bool _containsBuyerReservation(
    Iterable<Reservation> reservations,
    String tradeId,
    String sellerPubkey,
  ) {
    return reservations.any((r) {
      final rTradeId = r.getDtag();
      return rTradeId == tradeId && r.isCommit && r.pubKey != sellerPubkey;
    });
  }

  Thread? _findThreadForTrade(String tradeId) =>
      _logger.spanSync('_findThreadForTrade', () {
        final matches = _threads.threads.values.where((thread) {
          return thread.state.value.reservationRequests.any(
            (request) => request.getDtag() == tradeId,
          );
        }).toList();
        if (matches.length == 1) return matches.single;
        if (matches.length > 1) {
          _logger.w(
            'PaymentProofOrchestrator: ambiguous threads for trade $tradeId',
          );
        }
        return null;
      });

  String _threadPayload(String threadId) =>
      Uri(scheme: 'hostr', host: 'thread', pathSegments: [threadId]).toString();

  Future<KeyPair> _deriveKeyPair({
    required String sellerPubkey,
    required String tradeId,
    required Reservation lastRequest,
  }) => _logger.span('_deriveKeyPair', () async {
    final myPubkey = _auth.getActiveKey().publicKey;
    if (sellerPubkey == myPubkey) {
      return _auth.getActiveKey();
    }
    final allocator = getIt<TradeAccountAllocator>();
    final accountIndex = await allocator.findTradeAccountIndexByTradeId(
      tradeId,
    );
    return _auth.hd.getTradeKeyPair(accountIndex: accountIndex);
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
