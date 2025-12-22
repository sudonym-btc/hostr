import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/workflows/reservation_workflow.dart';
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

/// Cubit managing reservation request state.
/// Business process (create rumor → seal → gift-wrap) delegated to ReservationWorkflow.
/// This cubit only manages state transitions and UI decisions.
class ReservationCubit extends Cubit<ReservationState> {
  final EventPublisherCubit _publisher;
  final ReservationWorkflow _workflow;

  ReservationCubit({
    required Ndk ndk,
    required EventPublisherCubit publisher,
    required ReservationWorkflow workflow,
  })  : _publisher = publisher,
        _workflow = workflow,
        super(ReservationState(status: ReservationStatus.initial));

  Future<String?> createReservation({
    required Listing listing,
    required DateTime startDate,
    required DateTime endDate,
    required Function(String id) onSuccess,
  }) async {
    emit(ReservationState(status: ReservationStatus.loading));
    
    try {
      // Delegate business process to workflow
      // TODO: Get actual sender/recipient pubkeys from auth/context
      final result = await _workflow.createReservationRequest(
        listing: listing,
        startDate: startDate,
        endDate: endDate,
        senderPubkey: MockKeys.hoster.publicKey,
        recipientPubkey: MockKeys.guest.publicKey,
      );

      // Publish the resulting gift-wrapped event
      await _publisher.publishEvents([result.giftWrapEvent]);

      // Business decision: emit success state
      emit(ReservationState(status: ReservationStatus.success));
      onSuccess(result.reservationId);
      return result.reservationId;
    } catch (e) {
      // Business decision: emit error state
      emit(
        ReservationState(status: ReservationStatus.error, error: e.toString()),
      );
      return null;
    }
  }
}
