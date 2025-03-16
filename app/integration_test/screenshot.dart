import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/app.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/router.dart';
import 'package:hostr/setup.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:models/main.dart';

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
  await mockNetworkImages(
      () async => await tester.pumpWidget(appWrapper(child)));
  await binding.convertFlutterSurfaceToImage();
  await tester.pumpAndSettle(Duration(seconds: 5));
  await takeScreenshot(binding, name);
}

takeScreenshot(
    IntegrationTestWidgetsFlutterBinding binding, String name) async {
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
    });
    testWidgets('login', (tester) async {
      /// Navigate to the login screen
      appRouter.navigate(SignInRoute());
      await loadWidgetAndTakeScreenshot(tester, binding, app, 'login');

      /// Find the nsec field and enter private key
      final keyField = find.byKey(ValueKey('key'));
      await tester.enterText(keyField, MockKeys.guest.privateKey!);

      /// Find the login button and tap it
      final loginButton = find.byKey(ValueKey('login'));
      await tester.tap(loginButton);
      await tester.pumpAndSettle(); // Wait for the login process to complete
    });
    testWidgets('home', (tester) async {
      /// Screenshot the home page
      await loadWidgetAndTakeScreenshot(tester, binding, app, 'home');
    });
    testWidgets('listing', (tester) async {
      /// Navigate to the listing screen and screenshot
      appRouter.navigate(ListingRoute(a: MOCK_LISTINGS[0].anchor));
      await loadWidgetAndTakeScreenshot(tester, binding, app, 'listing');
    });
    testWidgets('thread', (tester) async {
      /// Navigate to the inbox screen and screenshot
      appRouter.navigate(InboxRoute());
      await loadWidgetAndTakeScreenshot(tester, binding, app, 'threads');

      /// Navigate to a thread screen and screenshot
      appRouter.navigate(
          ThreadRoute(id: guestRequest.tags.firstWhere((i) => i[0] == 'a')[1]));
      await tester.pumpAndSettle(Duration(seconds: 1));
      await takeScreenshot(binding, 'thread');

      /// Find the pay button and tap it
      final buttonFinder = find.byKey(ValueKey('pay'));
      await tester.tap(buttonFinder);
      await tester.pumpAndSettle(Duration(seconds: 2));
      await takeScreenshot(binding, 'thread_pay');
    });
  });
}
