import 'package:logger/logger.dart';

class CustomLogger extends Logger {
  CustomLogger() : super(printer: PrettyPrinter(colors: false));
}
