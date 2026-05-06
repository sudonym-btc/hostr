import 'dart:convert';
import 'dart:io';

class HostrCliIssue {
  const HostrCliIssue({
    required this.code,
    required this.message,
    this.path,
    this.hint,
    this.retryable = false,
    this.details,
  });

  final String code;
  final String message;
  final String? path;
  final String? hint;
  final bool retryable;
  final Object? details;

  Map<String, Object?> toJson() => {
    'code': code,
    'message': message,
    if (path != null) 'path': path,
    if (hint != null) 'hint': hint,
    'retryable': retryable,
    if (details != null) 'details': details,
  };
}

class HostrCliException implements Exception {
  HostrCliException(
    this.code,
    this.message, {
    this.path,
    this.hint,
    this.retryable = false,
    this.details,
    this.exitCode = 1,
  });

  final String code;
  final String message;
  final String? path;
  final String? hint;
  final bool retryable;
  final Object? details;
  final int exitCode;

  HostrCliIssue toIssue() => HostrCliIssue(
    code: code,
    message: message,
    path: path,
    hint: hint,
    retryable: retryable,
    details: details,
  );

  @override
  String toString() => '$code: $message';
}

class HostrCliResult {
  const HostrCliResult({
    required this.ok,
    required this.command,
    required this.environment,
    required this.dryRun,
    this.traceId,
    this.data,
    this.warnings = const [],
    this.errors = const [],
  });

  final bool ok;
  final String command;
  final String environment;
  final bool dryRun;
  final String? traceId;
  final Object? data;
  final List<HostrCliIssue> warnings;
  final List<HostrCliIssue> errors;

  Map<String, Object?> toJson() => {
    'ok': ok,
    'command': command,
    'environment': environment,
    'dryRun': dryRun,
    if (traceId != null) 'traceId': traceId,
    if (data != null) 'data': data,
    if (warnings.isNotEmpty)
      'warnings': warnings.map((warning) => warning.toJson()).toList(),
    if (errors.isNotEmpty)
      'errors': errors.map((error) => error.toJson()).toList(),
  };

  void writeTo(IOSink sink, {required bool json}) {
    if (json) {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(toJson()));
      return;
    }

    if (!ok) {
      for (final error in errors) {
        sink.writeln('Error: ${error.message}');
        if (error.hint != null) sink.writeln('Hint: ${error.hint}');
      }
      return;
    }

    if (data == null) {
      sink.writeln('OK');
      return;
    }

    if (data is String) {
      sink.writeln(data);
    } else {
      sink.writeln(const JsonEncoder.withIndent('  ').convert(data));
    }
  }
}
