import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';

class AppController {
  CustomLogger logger = CustomLogger();

  late Hostr hostrService;

  AppController() {
    hostrService = getIt<Hostr>();
    hostrService.start();
  }

  void dispose() {
    hostrService.dispose();
  }
}
