import 'package:logger/logger.dart';

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
        printer: PrettyPrinter(colors: false),
        output: _outputOverride ?? ConsoleOutput(),
        level: _levelOverride,
      );
}
