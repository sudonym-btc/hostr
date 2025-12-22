import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/logic/progress/progress.dart';
import 'package:hostr/logic/workflows/event_publishing_workflow.dart';
import 'package:ndk/ndk.dart';

const String _operation = 'publish_events';

class EventPublisherState extends Equatable {
  final ProgressSnapshot progress;
  final int total;
  final int sent;

  const EventPublisherState({
    required this.progress,
    this.total = 0,
    this.sent = 0,
  });

  factory EventPublisherState.initial() => EventPublisherState(
    progress: ProgressSnapshot.idle(operation: _operation),
  );

  EventPublisherState copyWith({
    ProgressSnapshot? progress,
    int? total,
    int? sent,
  }) {
    return EventPublisherState(
      progress: progress ?? this.progress,
      total: total ?? this.total,
      sent: sent ?? this.sent,
    );
  }

  @override
  List<Object?> get props => [progress, total, sent];
}

/// Cubit managing event publishing state.
/// Business process (batch iteration, progress tracking) delegated to EventPublishingWorkflow.
/// This cubit only manages state transitions and UI decisions.
class EventPublisherCubit extends Cubit<EventPublisherState> {
  EventPublisherCubit({
    required NostrService nostrService,
    required EventPublishingWorkflow workflow,
  }) : _nostrService = nostrService,
       _workflow = workflow,
       super(EventPublisherState.initial());

  final NostrService _nostrService;
  final EventPublishingWorkflow _workflow;
  final CustomLogger logger = CustomLogger();

  Future<void> publishEvents(List<Nip01Event> events) async {
    // Delegate business process to workflow
    final sent = await _workflow.publishBatch(
      events: events,
      publishEvent: (event) => _nostrService.broadcast(event: event),
      onProgress: (progress) {
        // Business decision: update state based on workflow progress
        emit(
          state.copyWith(
            progress: progress,
            total: progress.context['total'] as int? ?? state.total,
            sent: progress.context['sent'] as int? ?? state.sent,
          ),
        );
      },
      operation: _operation,
    );

    logger.d('Publishing complete: $sent/${events.length} events sent');
  }

  void reset() => emit(EventPublisherState.initial());
}
