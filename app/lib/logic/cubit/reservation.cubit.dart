import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/main.dart';
import 'package:models/main.dart';

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

/// Cubit managing reservation request state.
/// This cubit only manages state transitions and UI decisions.
class ReservationCubit extends Cubit<ReservationState> {
  final EventPublisherCubit _publisher;
  final Hostr _nostrService;

  ReservationCubit({
    required Hostr nostrService,
    required EventPublisherCubit publisher,
  }) : _publisher = publisher,
       _nostrService = nostrService,
       super(ReservationState(status: ReservationStatus.initial));

  Future<String?> createReservation({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    required Function(String id) onSuccess,
  }) async {
    emit(ReservationState(status: ReservationStatus.loading));

    try {
      print('Creating reservation for listing ${listing.id}');
      final result = await _nostrService.reservationRequests
          .createReservationRequest(
            listing: listing,
            startDate: startDate,
            endDate: endDate,
            recipientPubkey: listing.pubKey,
          );
      print(
        await _nostrService.messaging.broadcastMessageAndAwait(
          content: result.toString(),
          tags: [
            ['a', result.anchor],
          ],
          recipientPubkey: listing.pubKey,
        ),
      );
      print('FOUND MSD');
      // Business decision: emit success state
      emit(ReservationState(status: ReservationStatus.success));
      onSuccess(result.anchor);
      return result.anchor;
    } catch (e) {
      print(e.toString());
      // Business decision: emit error state
      emit(
        ReservationState(status: ReservationStatus.error, error: e.toString()),
      );
      return null;
    }
  }
}
