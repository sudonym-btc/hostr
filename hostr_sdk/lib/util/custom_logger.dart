import 'package:logger/logger.dart';

class CustomLogger extends Logger {
  static LogOutput? _outputOverride;

  static void configure({LogOutput? output}) {
    _outputOverride = output;
  }

  CustomLogger()
    : super(
        printer: PrettyPrinter(colors: false),
        output: _outputOverride ?? ConsoleOutput(),
      );
}
