import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

enum ReservationStatus { initial, loading, success, error }

class ReservationState {
  final ReservationStatus status;
  final String? error;

  ReservationState({required this.status, this.error});

  ReservationState copyWith({ReservationStatus? status, String? error}) {
    return ReservationState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

class ReservationCubit extends Cubit<ReservationState> {
  ReservationCubit()
    : super(ReservationState(status: ReservationStatus.initial));

  Future<String?> createReservation({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    required Function(String id) onSuccess,
  }) async {
    emit(ReservationState(status: ReservationStatus.loading));
    try {
      ReservationRequest req = ReservationRequest.fromNostrEvent(
        Nip01Event(
          kind: NOSTR_KIND_RESERVATION_REQUEST,
          tags: [
            ['a', MOCK_LISTINGS[0].anchor],
          ],
          content: ReservationRequestContent(
            start: startDate,
            end: endDate,
            quantity: 1,
            amount: listing.cost(startDate, endDate),
            commitmentHash: 'hash',
            commitmentHashPreimageEnc: 'does',
          ).toString(),
          pubKey: MockKeys.hoster.publicKey,
        )..sign(MockKeys.hoster.privateKey!),
      );

      final id =
          '${listing.anchor}/${crypto.sha256.convert(req.toString().codeUnits).bytes}';

      Nip01Event msg = Nip01Event(
        pubKey: MockKeys.hoster.publicKey,
        kind: NOSTR_KIND_DM,
        tags: [
          ['a', id],
          ['p', MockKeys.guest.publicKey],
        ],
        content: req.toString(),
      );

      await getIt<EventPublisherCubit>().publishEvents([
        // giftWrapAndSeal(
        //   listing.nip01Event.pubKey,
        //   getIt<KeyStorage>().getActiveKeyPairSync()!,
        //   msg,
        //   null,
        // ).nip01Event,
        // giftWrapAndSeal(
        //   getIt<KeyStorage>().getActiveKeyPairSync()!.publicKey,
        //   getIt<KeyStorage>().getActiveKeyPairSync()!,
        //   msg,
        //   null,
        // ).nip01Event,
      ]);

      emit(ReservationState(status: ReservationStatus.success));
      onSuccess(id);
      return id;
    } catch (e) {
      emit(
        ReservationState(status: ReservationStatus.error, error: e.toString()),
      );
      return null;
    }
  }
}
