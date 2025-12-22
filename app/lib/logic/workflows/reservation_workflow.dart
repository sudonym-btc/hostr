import 'package:crypto/crypto.dart' as crypto;
import 'package:hostr/core/main.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

/// Workflow handling the multi-step reservation request creation process.
/// Steps: create rumor → seal → gift-wrap → publish
@injectable
class ReservationWorkflow {
  final Ndk _ndk;
  final CustomLogger _logger = CustomLogger();

  ReservationWorkflow({required Ndk ndk}) : _ndk = ndk;

  /// Generates unique reservation ID from listing anchor and request content.
  String generateReservationId({
    required String listingAnchor,
    required ReservationRequest request,
  }) {
    final hash = crypto.sha256.convert(request.toString().codeUnits);
    return '$listingAnchor/${hash.bytes}';
  }

  /// Creates the reservation request event (rumor).
  Future<Nip01Event> createReservationRumor({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    required String reservationId,
    required String senderPubkey,
    required String recipientPubkey,
  }) async {
    _logger.d('Creating reservation rumor for listing ${listing.anchor}');

    final request = ReservationRequest.fromNostrEvent(
      Nip01Event(
        kind: NOSTR_KIND_RESERVATION_REQUEST,
        tags: [
          ['a', listing.anchor],
        ],
        content: ReservationRequestContent(
          start: startDate,
          end: endDate,
          quantity: 1,
          amount: listing.cost(startDate, endDate),
          commitmentHash: 'hash',
          commitmentHashPreimageEnc: 'does',
        ).toString(),
        pubKey: senderPubkey,
      )..sign(await _getPrivateKey(senderPubkey)),
    );

    final rumor = await _ndk.giftWrap.createRumor(
      customPubkey: senderPubkey,
      kind: NOSTR_KIND_DM,
      tags: [
        ['a', reservationId],
        ['p', recipientPubkey],
      ],
      content: request.toString(),
    );

    _logger.d('Created rumor: ${rumor.id}');
    return rumor;
  }

  /// Seals the rumor with encryption.
  Future<Nip01Event> sealRumor({
    required Nip01Event rumor,
    required String recipientPubkey,
  }) async {
    _logger.d('Sealing rumor ${rumor.id}');

    final seal = await _ndk.giftWrap.sealRumor(
      rumor: rumor,
      recipientPubkey: recipientPubkey,
    );

    _logger.d('Sealed rumor: ${seal.id}');
    return seal;
  }

  /// Wraps the sealed rumor in a gift wrap event.
  Future<Nip01Event> giftWrapSeal({
    required Nip01Event seal,
    required String recipientPubkey,
  }) async {
    _logger.d('Gift-wrapping seal ${seal.id}');

    final giftWrap = await _ndk.giftWrap.toGiftWrap(
      rumor: seal,
      recipientPubkey: recipientPubkey,
    );

    _logger.d('Gift-wrapped event: ${giftWrap.id}');
    return giftWrap;
  }

  /// Executes the full reservation creation workflow.
  Future<ReservationWorkflowResult> createReservationRequest({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    required String senderPubkey,
    required String recipientPubkey,
  }) async {
    _logger.i('Starting reservation workflow for ${listing.anchor}');

    try {
      // Generate reservation ID
      final tempRequest = ReservationRequest.fromNostrEvent(
        Nip01Event(
          kind: NOSTR_KIND_RESERVATION_REQUEST,
          tags: [
            ['a', listing.anchor],
          ],
          content: ReservationRequestContent(
            start: startDate,
            end: endDate,
            quantity: 1,
            amount: listing.cost(startDate, endDate),
            commitmentHash: 'hash',
            commitmentHashPreimageEnc: 'does',
          ).toString(),
          pubKey: senderPubkey,
        ),
      );
      final reservationId = generateReservationId(
        listingAnchor: listing.anchor,
        request: tempRequest,
      );

      // Step 1: Create rumor
      final rumor = await createReservationRumor(
        listing: listing,
        startDate: startDate,
        endDate: endDate,
        reservationId: reservationId,
        senderPubkey: senderPubkey,
        recipientPubkey: recipientPubkey,
      );

      // Step 2: Seal rumor
      final seal = await sealRumor(
        rumor: rumor,
        recipientPubkey: recipientPubkey,
      );

      // Step 3: Gift wrap
      final giftWrap = await giftWrapSeal(
        seal: seal,
        recipientPubkey: recipientPubkey,
      );

      _logger.i('Reservation workflow completed: $reservationId');

      return ReservationWorkflowResult(
        reservationId: reservationId,
        giftWrapEvent: giftWrap,
      );
    } catch (e) {
      _logger.e('Reservation workflow failed: $e');
      rethrow;
    }
  }

  // Helper to get private key (TODO: integrate with KeyStorage)
  Future<String> _getPrivateKey(String pubkey) async {
    // This is a temporary implementation - should use KeyStorage
    throw UnimplementedError('Private key retrieval not implemented');
  }
}

class ReservationWorkflowResult {
  final String reservationId;
  final Nip01Event giftWrapEvent;

  ReservationWorkflowResult({
    required this.reservationId,
    required this.giftWrapEvent,
  });
}
