import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/app.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('tap on the floating action button, verify counter',
        (tester) async {
      // Load app widget.
      await tester.pumpWidget(MyApp());
      await binding.convertFlutterSurfaceToImage();

      // await screenshot(tester, config, 'main');
    });
  });
}
