import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  // Set SCREENSHOT_DEVICE to route output into a device-specific subdirectory.
  // e.g. SCREENSHOT_DEVICE=iphone_16_pro_max → screenshots/iphone_16_pro_max/
  final device = Platform.environment['SCREENSHOT_DEVICE'];

  final FlutterDriver driver = await FlutterDriver.connect();
  await integrationDriver(
    driver: driver,
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final path = device != null
              ? name.replaceFirst('screenshots/', 'screenshots/$device/')
              : name;
          final File image = await File(path).create(recursive: true);
          image.writeAsBytesSync(bytes);
          return true;
        },
  );
}
