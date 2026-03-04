import 'package:crypto/crypto.dart' as crypto;
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Ndk;
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
  ///
  /// The `recipient` field is automatically set to the salted (tweaked) public
  /// key derived from the active user's private key and the generated salt.
  /// This allows later review verification via [ParticipationProof].
  Future<Reservation> createReservationRequest({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Generate random nonce for this reservation request
    final nonce = Helpers.getSecureRandomHex(32);
    final salt = Helpers.getSecureRandomHex(32);

    logger.d('Creating negotiate reservation with nonce $nonce');

    final recipientKey = saltedKey(
      key: auth.getActiveKey().privateKey!,
      salt: salt,
    );

    // should sign as temp key
    return Reservation.create(
      pubKey: recipientKey.publicKey,
      dTag: nonce,
      listingAnchor: listing.anchor!,
      start: startDate,
      end: endDate,
      stage: ReservationStage.negotiate,
      quantity: 1,
      amount: listing.cost(startDate, endDate),
      salt: salt,
      recipient: recipientKey.publicKey,
    ).signAs(recipientKey, Reservation.fromNostrEvent);
  }
}
