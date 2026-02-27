import 'package:crypto/crypto.dart' as crypto;
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Ndk, Nip01Event;
import 'package:ndk/shared/nips/nip01/helpers.dart';

import '../auth/auth.dart';
import '../crud.usecase.dart';

/// Use-case for creating negotiate-stage [Reservation] events (formerly
/// "reservation requests"). The class name is kept for DI compatibility but
/// now produces [Reservation] instances with `stage = negotiate`.
@Singleton()
class ReservationRequests extends CrudUseCase {
  final Ndk ndk;
  final Auth auth;
  ReservationRequests({
    required super.requests,
    required super.logger,
    required this.ndk,
    required this.auth,
  }) : super(kind: Reservation.kinds[0]);

  static String getReservationRequestId({
    required Listing listing,
    required Reservation request,
  }) {
    final hash = crypto.sha256.convert(request.toString().codeUnits);
    return '${listing.anchor}/${hash.bytes}';
  }

  /// Creates a negotiate-stage [Reservation] (replaces the old
  /// `createReservationRequest`). The returned event is a full [Reservation]
  /// with `stage = negotiate` and a `commit` object.
  Future<Reservation> createReservationRequest({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    required String recipientPubkey,
  }) async {
    // Generate random nonce for this reservation request
    final nonce = Helpers.getSecureRandomHex(32);
    final salt = Helpers.getSecureRandomHex(32);

    logger.d('Creating negotiate reservation with nonce $nonce');

    // should sign as temp key
    return Reservation.fromNostrEvent(
      await ndk.accounts.sign(
        Nip01Event(
          kind: kNostrKindReservation,
          tags: [
            [kListingRefTag, listing.anchor!],
            ['d', nonce],
          ],
          content: ReservationContent.negotiate(
            start: startDate,
            end: endDate,
            quantity: 1,
            amount: listing.cost(startDate, endDate),
            salt: salt,
            recipient: recipientPubkey,
          ).toString(),
          pubKey: ndk.accounts.getPublicKey()!,
        ),
      ),
    );
  }
}
