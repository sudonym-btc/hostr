import 'dart:developer' as developer;

import 'package:logger/logger.dart';

import 'telemetry.dart';

/// A [LogOutput] that uses [developer.log] which does NOT truncate messages
/// (unlike [print] which cuts off at ~1024 chars on some platforms).
class _DeveloperLogOutput extends LogOutput {
  final String tag;
  _DeveloperLogOutput({this.tag = 'hostr'});

  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      developer.log(line, name: tag);
    }
  }
}

class CustomLogger extends Logger {
  static LogOutput? _outputOverride;
  static Level _levelOverride = Level.trace;
  static String _tag = 'hostr';

  /// Shared [Telemetry] instance.  Set once via [configure] at startup.
  static Telemetry? _telemetry;

  /// The resolved tag for this logger instance.
  final String _resolvedTag;

  static void configure({
    LogOutput? output,
    Level? level,
    String? tag,
    Telemetry? telemetry,
  }) {
    if (output != null) {
      _outputOverride = output;
    }
    if (level != null) {
      _levelOverride = level;
    }
    if (tag != null) {
      _tag = tag;
    }
    if (telemetry != null) {
      _telemetry = telemetry;
    }
  }

  /// Returns the [Telemetry] instance attached to the logger system.
  static Telemetry get telemetry => _telemetry ?? Telemetry.noop();

  CustomLogger({String? tag})
    : _resolvedTag = tag ?? _tag,
      super(
        printer: SimplePrinter(colors: true),
        output: _outputOverride ?? _DeveloperLogOutput(tag: tag ?? _tag),
        level: _levelOverride,
      );

  /// Creates a child logger scoped to `parentTag-scopeName`.
  ///
  /// Maps to the OpenTelemetry concept of an *instrumentation scope* —
  /// the logical module or component producing telemetry.  The scope
  /// name is used to prefix span names (`<tag>.<operation>`) and as the
  /// `log.tag` attribute on span events, making traces easy to filter
  /// by component.
  ///
  /// ```dart
  /// final log = CustomLogger(tag: 'hostr');
  /// final evmLog = log.scope('evm');
  /// // evmLog tag → 'hostr-evm'
  /// ```
  CustomLogger scope(String scopeName) =>
      CustomLogger(tag: '$_resolvedTag.$scopeName');

  String get tag => _resolvedTag;

  // ---------------------------------------------------------------------------
  // Span convenience methods
  //
  // Wrap any function in a named span with automatic zone-based parent
  // propagation.  The span name is prefixed with this logger's tag so
  // that traces are easy to navigate.
  // ---------------------------------------------------------------------------

  /// Runs [fn] inside a new child span named `<tag>.<name>`.
  Future<T> span<T>(
    String name,
    Future<T> Function() fn, {
    Map<String, Object>? attributes,
  }) {
    return telemetry.runInSpan(
      '$_resolvedTag.$name',
      fn,
      attributes: attributes,
    );
  }

  /// Synchronous variant of [span].
  T spanSync<T>(
    String name,
    T Function() fn, {
    Map<String, Object>? attributes,
  }) {
    return telemetry.runInSpanSync(
      '$_resolvedTag.$name',
      fn,
      attributes: attributes,
    );
  }

  // ---------------------------------------------------------------------------
  // OTel-aware log overrides
  //
  // Every log call:
  //  1. Emits an event on the currently-active OTel span (from zone context).
  //  2. Delegates to the standard `Logger` output for local terminal display.
  // ---------------------------------------------------------------------------

  @override
  void t(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emitSpanEvent('TRACE', message, error: error, stackTrace: stackTrace);
    super.t(message, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void d(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emitSpanEvent('DEBUG', message, error: error, stackTrace: stackTrace);
    super.d(message, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void i(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emitSpanEvent('INFO', message, error: error, stackTrace: stackTrace);
    super.i(message, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void w(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emitSpanEvent('WARN', message, error: error, stackTrace: stackTrace);
    super.w(message, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void e(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emitSpanEvent('ERROR', message, error: error, stackTrace: stackTrace);
    super.e(message, time: time, error: error, stackTrace: stackTrace);
  }

  @override
  void f(
    dynamic message, {
    DateTime? time,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _emitSpanEvent('FATAL', message, error: error, stackTrace: stackTrace);
    super.f(message, time: time, error: error, stackTrace: stackTrace);
  }

  /// Attaches a log entry as an event on whatever span is currently
  /// active in the zone-propagated OTel context.
  void _emitSpanEvent(
    String level,
    dynamic message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _telemetry?.addEvent(
      'log',
      attributes: {
        'log.level': level,
        'log.tag': _resolvedTag,
        'log.message': message.toString(),
        if (error != null) 'log.error': error.toString(),
        if (stackTrace != null) 'log.stackTrace': stackTrace.toString(),
      },
    );
  }
}
