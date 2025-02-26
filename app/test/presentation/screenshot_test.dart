import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/app.dart';
import 'package:integration_test/integration_test.dart';

Future<void> captureScreenshot(
  WidgetTester tester,
  String screenshotName,
) async {
  await tester.pumpAndSettle();
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized()
      as IntegrationTestWidgetsFlutterBinding;

  final List<int> image = await binding.takeScreenshot(screenshotName);

  final file = File('screenshots/$screenshotName.png');
  await file.create(recursive: true);
  await file.writeAsBytes(image);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Define multiple screen sizes (width x height).
  final List<Size> sizes = [
    Size(320, 568), // iPhone SE
    Size(375, 667), // iPhone 8
    Size(414, 896), // iPhone 11 Pro Max
    Size(768, 1024), // iPad
  ];

  for (final size in sizes) {
    testWidgets('Screenshot at ${size.width.toInt()}x${size.height.toInt()}',
        (WidgetTester tester) async {
      // Set the simulated screen size.
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;

      // Launch the app (or the Widgetbook screen).
      await tester.pumpWidget(MyApp());
      await tester.pumpAndSettle();

      // Capture and save screenshot.
      await captureScreenshot(
          tester, 'screenshot_${size.width.toInt()}x${size.height.toInt()}');

      // Clear the test values.
      addTearDown(() {
        tester.view.resetPhysicalConstraints();
        tester.view.resetDevicePixelRatio();
      });
    });
  }
}
