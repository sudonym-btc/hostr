import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/app.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/router.dart';
import 'package:hostr/setup.dart';
import 'package:integration_test/integration_test.dart';

appWrapper(Widget child) {
  return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GlobalProviderWidget(child: Center(child: child)));
}

loadWidgetAndTakeScreenshot(
    WidgetTester tester,
    IntegrationTestWidgetsFlutterBinding binding,
    Widget child,
    String name) async {
  await tester.pumpWidget(appWrapper(child));
  await binding.convertFlutterSurfaceToImage();
  await tester.pumpAndSettle(Duration(seconds: 1));
  await tester.pumpAndSettle(Duration(seconds: 1));
  await tester.pumpAndSettle(Duration(seconds: 1));
  await binding.takeScreenshot('screenshots/$name.png');
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('screenshots', () {
    AppRouter appRouter = AppRouter();
    MyApp app = MyApp(
      appRouter: appRouter,
    );
    setUpAll(() async {
      await setup(Env.test);
      await seed();
    });
    testWidgets('home', (tester) async {
      await loadWidgetAndTakeScreenshot(tester, binding, app, 'home');
    });
    testWidgets('listing', (tester) async {
      appRouter.navigate(ListingRoute(a: MOCK_LISTINGS[0].anchor));
      await loadWidgetAndTakeScreenshot(tester, binding, app, 'listing');
    });
  });
}
