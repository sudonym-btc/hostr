import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/ndk.dart';

enum EventPublisherStatus { initial, loading, success, error }

class EventPublisherState {
  final EventPublisherStatus status;
  final String? error;
  EventPublisherState({required this.status, this.error});
}

class EventPublisherCubit extends Cubit<EventPublisherState> {
  EventPublisherCubit()
      : super(EventPublisherState(status: EventPublisherStatus.initial));

  Future<void> publishEvents(List<Nip01Event> events) async {
    emit(EventPublisherState(status: EventPublisherStatus.loading));
    try {
      for (Nip01Event event in events) {
        await getIt<NostrService>().broadcast(event: event);
      }
      emit(EventPublisherState(status: EventPublisherStatus.success));
    } catch (e) {
      emit(EventPublisherState(
          status: EventPublisherStatus.error, error: e.toString()));
    }
  }
}
