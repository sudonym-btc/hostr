import 'package:crypto/crypto.dart' as crypto;
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Ndk, Nip01Event;
import 'package:ndk/shared/nips/nip01/helpers.dart';

import '../crud.usecase.dart';

@Singleton()
class ReservationRequests extends CrudUseCase {
  final Ndk ndk;
  ReservationRequests({required super.requests, required this.ndk})
    : super(kind: ReservationRequest.kinds[0]);

  static String getReservationRequestId({
    required Listing listing,
    required ReservationRequest request,
  }) {
    final hash = crypto.sha256.convert(request.toString().codeUnits);
    return '${listing.anchor}/${hash.bytes}';
  }

  Future<ReservationRequest> createReservationRequest({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    required String recipientPubkey,
  }) async {
    // Generate random salt for this reservation request
    final salt = Helpers.getSecureRandomHex(32);

    logger.d('Creating new reservation request with salt $salt');
    return ReservationRequest.fromNostrEvent(
      await ndk.accounts.sign(
        Nip01Event(
          kind: NOSTR_KIND_RESERVATION_REQUEST,
          tags: [
            ['a', listing.anchor!],
            ['d', Helpers.getSecureRandomHex(32)],
          ],
          content: ReservationRequestContent(
            start: startDate,
            end: endDate,
            quantity: 1,
            amount: listing.cost(startDate, endDate),
            // @todo: salt must be encrypted for me, so that the hoster can't publish a review on my behalf
            salt: salt,
          ).toString(),
          pubKey: ndk.accounts.getPublicKey()!,
        ),
      ),
    );
  }
}
