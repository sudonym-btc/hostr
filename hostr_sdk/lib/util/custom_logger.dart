import 'dart:developer' as developer;

import 'package:logger/logger.dart';

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

  /// The resolved tag for this logger instance.
  final String _resolvedTag;

  static void configure({LogOutput? output, Level? level, String? tag}) {
    if (output != null) {
      _outputOverride = output;
    }
    if (level != null) {
      _levelOverride = level;
    }
    if (tag != null) {
      _tag = tag;
    }
  }

  CustomLogger({String? tag})
    : _resolvedTag = tag ?? _tag,
      super(
        printer: SimplePrinter(colors: true),
        output: _outputOverride ?? _DeveloperLogOutput(tag: tag ?? _tag),
        level: _levelOverride,
      );

  /// Creates a child logger whose tag is `parentTag-ns`.
  ///
  /// ```dart
  /// final log = CustomLogger(tag: 'hostr');
  /// final evmLog = log.namespace('usecase-evm');
  /// // evmLog tag → 'hostr-usecase-evm'
  /// ```
  CustomLogger namespace(String ns) => CustomLogger(tag: '$_resolvedTag-$ns');
}
