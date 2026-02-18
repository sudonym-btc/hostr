import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

enum ReservationCubitStatus { initial, loading, success, error }

class ReservationCubitState {
  final ReservationCubitStatus status;
  final String? error;

  ReservationCubitState({required this.status, this.error});

  ReservationCubitState copyWith({
    ReservationCubitStatus? status,
    String? error,
  }) {
    return ReservationCubitState(
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }
}

/// Cubit managing reservation request state.
/// This cubit only manages state transitions and UI decisions.
class ReservationCubit extends Cubit<ReservationCubitState> {
  final Hostr hostr = getIt<Hostr>();
  ReservationCubit()
    : super(ReservationCubitState(status: ReservationCubitStatus.initial));

  Future<ReservationRequest?> createReservationRequest({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    required Function(ReservationRequest reservationRequest) onSuccess,
  }) async {
    emit(ReservationCubitState(status: ReservationCubitStatus.loading));

    try {
      final result = await hostr.reservationRequests.createReservationRequest(
        listing: listing,
        startDate: startDate,
        endDate: endDate,
        recipientPubkey: listing.pubKey,
      );
      await hostr.messaging.broadcastEventAndWait(
        event: result,
        tags: [
          [kThreadRefTag, result.getDtag()!],
        ],
        recipientPubkeys: [listing.pubKey],
      );
      // Business decision: emit success state
      emit(ReservationCubitState(status: ReservationCubitStatus.success));
      onSuccess(result);
      return result;
    } catch (e) {
      // Business decision: emit error state
      emit(
        ReservationCubitState(
          status: ReservationCubitStatus.error,
          error: e.toString(),
        ),
      );
      return null;
    }
  }
}
