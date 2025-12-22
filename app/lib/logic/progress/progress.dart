import 'package:equatable/equatable.dart';

enum ProgressStatus { idle, inProgress, success, failure }

class ProgressSnapshot extends Equatable {
  final String operation;
  final ProgressStatus status;
  final String? message;
  final double? fraction;
  final Object? error;
  final StackTrace? stackTrace;
  final Map<String, Object?> context;

  const ProgressSnapshot({
    required this.operation,
    required this.status,
    this.message,
    this.fraction,
    this.error,
    this.stackTrace,
    this.context = const {},
  });

  factory ProgressSnapshot.idle({required String operation, String? message}) {
    return ProgressSnapshot(
      operation: operation,
      status: ProgressStatus.idle,
      message: message,
    );
  }

  factory ProgressSnapshot.inProgress({
    required String operation,
    String? message,
    double? fraction,
    Map<String, Object?> context = const {},
  }) {
    return ProgressSnapshot(
      operation: operation,
      status: ProgressStatus.inProgress,
      message: message,
      fraction: fraction,
      context: context,
    );
  }

  factory ProgressSnapshot.success({
    required String operation,
    String? message,
    Map<String, Object?> context = const {},
  }) {
    return ProgressSnapshot(
      operation: operation,
      status: ProgressStatus.success,
      message: message,
      context: context,
    );
  }

  factory ProgressSnapshot.failure({
    required String operation,
    Object? error,
    StackTrace? stackTrace,
    String? message,
    Map<String, Object?> context = const {},
  }) {
    return ProgressSnapshot(
      operation: operation,
      status: ProgressStatus.failure,
      error: error,
      stackTrace: stackTrace,
      message: message,
      context: context,
    );
  }

  ProgressSnapshot copyWith({
    String? operation,
    ProgressStatus? status,
    String? message,
    double? fraction,
    Object? error = _noChange,
    Object? stackTrace = _noChangeStack,
    Map<String, Object?>? context,
  }) {
    return ProgressSnapshot(
      operation: operation ?? this.operation,
      status: status ?? this.status,
      message: message ?? this.message,
      fraction: fraction ?? this.fraction,
      error: error == _noChange ? this.error : error,
      stackTrace: stackTrace == _noChangeStack
          ? this.stackTrace
          : stackTrace as StackTrace?,
      context: context ?? this.context,
    );
  }

  @override
  List<Object?> get props => [operation, status, message, fraction, error];
}

const _noChange = Object();
const _noChangeStack = Object();
