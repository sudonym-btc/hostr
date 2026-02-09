import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

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
