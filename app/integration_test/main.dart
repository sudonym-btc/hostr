//test_driver/foo_test.dart
import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final FlutterDriver driver = await FlutterDriver.connect();
  await integrationDriver(
    driver: driver,
    onScreenshot: (String name, List<int> bytes,
        [Map<String, Object?>? args]) async {
      print('Screenshot: $name');
      final File image = await File(name).create(recursive: true);
      image.writeAsBytesSync(bytes);
      return true;
    },
  );
}
