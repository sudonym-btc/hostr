import 'package:crypto/crypto.dart' as crypto;
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Ndk, Nip01Event;

import '../crud.usecase.dart';

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
    print(ndk.accounts.getLoggedAccount());
    // Generate reservation ID
    return ReservationRequest.fromNostrEvent(
      await ndk.accounts.sign(
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
          pubKey: ndk.accounts.getPublicKey()!,
        ),
      ),
    );
  }
}
