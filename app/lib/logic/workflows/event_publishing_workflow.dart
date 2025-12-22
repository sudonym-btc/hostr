import 'package:hostr/core/main.dart';
import 'package:hostr/logic/progress/progress.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart';

/// Workflow handling batch event publishing with progress tracking.
/// Iterates through events and publishes them one by one, calculating progress at each step.
@injectable
class EventPublishingWorkflow {
  final CustomLogger _logger = CustomLogger();

  /// Publishes events in sequence with progress callback.
  /// Returns the number of successfully published events.
  Future<int> publishBatch({
    required List<Nip01Event> events,
    required Future<void> Function(Nip01Event event) publishEvent,
    required void Function(ProgressSnapshot progress) onProgress,
    required String operation,
  }) async {
    if (events.isEmpty) {
      _logger.i('No events to publish');
      onProgress(
        ProgressSnapshot.success(
          operation: operation,
          message: 'No events to publish',
        ),
      );
      return 0;
    }

    final total = events.length;
    _logger.i('Starting batch publish of $total events');

    int sent = 0;

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final currentIndex = i + 1;
      final fraction = currentIndex / total;

      try {
        _logger.d('Publishing event $currentIndex/$total: ${event.id}');

        // Emit in-progress state
        onProgress(
          ProgressSnapshot.inProgress(
            operation: operation,
            message: 'Publishing event $currentIndex of $total',
            fraction: fraction,
            context: {'eventId': event.id, 'sent': sent, 'total': total},
          ),
        );

        // Execute publish
        await publishEvent(event);
        sent++;

        _logger.d('Successfully published event ${event.id}');
      } catch (e) {
        _logger.e('Failed to publish event ${event.id}: $e');
        // Continue with next event on failure
        onProgress(
          ProgressSnapshot.failure(
            operation: operation,
            message: 'Failed to publish event $currentIndex: $e',
            context: {
              'eventId': event.id,
              'sent': sent,
              'total': total,
              'error': e.toString(),
            },
          ),
        );
        // Don't throw - continue with remaining events
      }
    }

    // Final success state
    _logger.i('Batch publish completed: $sent/$total events published');
    onProgress(
      ProgressSnapshot.success(
        operation: operation,
        message: 'Published $sent of $total events',
        context: {'sent': sent, 'total': total},
      ),
    );

    return sent;
  }
}
