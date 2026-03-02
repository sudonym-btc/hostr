import 'dart:developer' as developer;

import 'package:logger/logger.dart';

/// A [LogOutput] that uses [developer.log] which does NOT truncate messages
/// (unlike [print] which cuts off at ~1024 chars on some platforms).
class _DeveloperLogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    for (final line in event.lines) {
      developer.log(line, name: 'hostr');
    }
  }
}

class CustomLogger extends Logger {
  static LogOutput? _outputOverride;
  static Level _levelOverride = Level.trace;

  static void configure({LogOutput? output, Level? level}) {
    _outputOverride = output;
    if (level != null) {
      _levelOverride = level;
    }
  }

  CustomLogger()
    : super(
        printer: PrettyPrinter(colors: true),
        output: _outputOverride ?? _DeveloperLogOutput(),
        level: _levelOverride,
      );
}
