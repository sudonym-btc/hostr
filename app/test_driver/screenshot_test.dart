import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  // Set SCREENSHOT_DEVICE to route output into a device-specific subdirectory.
  // e.g. SCREENSHOT_DEVICE=iphone_16_pro_max → screenshots/iphone_16_pro_max/
  final device = Platform.environment['SCREENSHOT_DEVICE'];
  final simulatorUdid = Platform.environment['SCREENSHOT_SIMULATOR_UDID'];

  final FlutterDriver driver = await FlutterDriver.connect();
  var count = 0;
  await integrationDriver(
    driver: driver,
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final path = device != null
              ? name.replaceFirst('screenshots/', 'screenshots/$device/')
              : name;
          final File image = await File(path).create(recursive: true);
          var sizeBytes = bytes.length;
          if (simulatorUdid != null && simulatorUdid.isNotEmpty) {
            // iOS Flutter surface screenshots can arrive as blank white PNGs
            // on some simulator/engine combinations. The shell script captures
            // the live simulator framebuffer when the app emits its screenshot
            // marker, so the deferred driver callback must not overwrite it.
            if (image.existsSync() && image.lengthSync() > 0) {
              sizeBytes = image.lengthSync();
            } else {
              image.writeAsBytesSync(bytes);
            }
          } else {
            image.writeAsBytesSync(bytes);
          }
          count++;
          final sizeKB = (sizeBytes / 1024).toStringAsFixed(0);
          stdout.writeln('📸 [$count] $path (${sizeKB}KB)');
          return true;
        },
  );
}
