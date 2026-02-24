/// Deterministic screenshot generator using [SeedFactory].
///
/// Runs against in-memory [InMemoryRequests] — no relay, chain, or Docker needed.
/// Data is produced from a fixed seed so output is identical across runs.
///
/// Usage (single device):
///   flutter drive \
///     --driver=test_driver/screenshot_test.dart \
///     --target=integration_test/screenshots.dart \
///     -d <device_id>
///
/// Or via the orchestrator script (all configured devices):
///   ./scripts/screenshots.sh
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/app.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/router.dart';
import 'package:hostr/setup.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/requests/in_memory.requests.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

// ── Seed configuration ──────────────────────────────────────────────────────
// Small dataset — just enough for every screenshot page.

const _config = SeedPipelineConfig(
  seed: 42,
  userCount: 8,
  hostRatio: 0.5, // 4 hosts, 4 guests
  listingsPerHostAvg: 2.0, // ~8 listings
  reservationRequestsPerGuest: 2, // 8 threads
  threadStages: ThreadStageSpec(
    textMessageCount: 4,
    completedRatio: 0.5,
    reviewRatio: 0.5,
  ),
);

// ── Helpers ─────────────────────────────────────────────────────────────────

/// Pump [frames] frames spaced [interval] apart.
///
/// Unlike `pumpAndSettle`, this does NOT wait for the scheduler to go idle.
/// NDK relay-reconnect timers keep scheduling frames indefinitely so
/// `pumpAndSettle` never returns.
Future<void> _settle(
  WidgetTester tester, {
  int frames = 10,
  Duration interval = const Duration(milliseconds: 500),
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(interval);
  }
}

/// Take screenshots for every page in [mode] ("light" or "dark").
///
/// The [appRouter] must already be mounted and the user authenticated.
Future<void> _takeScreenshots(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  AppRouter appRouter,
  SeedPipelineData data,
  String mode,
) async {
  // ── 1. Home / search ────────────────────────────────────────────
  appRouter.navigate(HomeRoute());
  await _settle(tester, frames: 6);
  await binding.takeScreenshot('screenshots/$mode/home.png');

  // ── 2. Listing detail ───────────────────────────────────────────
  appRouter.navigate(ListingRoute(a: data.listings.first.anchor!));
  await _settle(tester, frames: 6);
  await binding.takeScreenshot('screenshots/$mode/listing.png');

  // ── 3. Inbox ────────────────────────────────────────────────────
  appRouter.navigate(InboxRoute());
  await _settle(tester, frames: 6);
  await binding.takeScreenshot('screenshots/$mode/threads.png');

  // ── 4. Thread detail ────────────────────────────────────────────
  final threadMap = getIt<Hostr>().messaging.threads.threads;
  if (threadMap.isNotEmpty) {
    appRouter.navigate(ThreadRoute(anchor: threadMap.keys.first));
    await _settle(tester, frames: 6);
    await binding.takeScreenshot('screenshots/$mode/thread.png');
  }
}

// ── Test ────────────────────────────────────────────────────────────────────
//
// Everything runs in a **single** testWidgets so the widget tree (and auth
// state) survives across screenshots.  Each testWidgets rebuilds the tree
// from scratch which drops the login session — that's why the old multi-test
// approach never navigated past the home page.
//
// We avoid `pumpAndSettle` entirely — the NDK's relay reconnect timers keep
// the frame scheduler permanently busy, so `pumpAndSettle` blocks forever.
//
// After logging in, the suite captures every page in light mode, then
// switches platformBrightness to dark and captures them again.

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot suite', (tester) async {
    // ── Bootstrap ───────────────────────────────────────────────────────
    await setup(Env.test);

    final factory = SeedFactory(config: _config);
    final data = await factory.buildAll();

    final requests = getIt<Requests>() as InMemoryRequests;
    requests.seedEvents(data.allEvents);
    factory.dispose();

    final guest = data.users.firstWhere((u) => !u.isHost);

    final appRouter = AppRouter();
    final app = MyApp(appRouter: appRouter);

    await mockNetworkImages(() async {
      // ── Mount the app once — keep it alive for the whole suite ─────
      // Start in light mode.
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpWidget(app);
      await _settle(tester);

      await binding.convertFlutterSurfaceToImage();
      await tester.pump();

      // ── Sign-in screenshot (light) ────────────────────────────────
      appRouter.navigate(SignInRoute());
      await _settle(tester, frames: 6);
      await binding.takeScreenshot('screenshots/light/login.png');

      // ── Sign-in screenshot (dark) ─────────────────────────────────
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await _settle(tester, frames: 4);
      await binding.takeScreenshot('screenshots/dark/login.png');

      // ── Switch back to light to log in ────────────────────────────
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await _settle(tester, frames: 2);

      // ── Log in as the seeded guest ────────────────────────────────
      final keyField = find.byKey(const ValueKey('key'));
      await tester.enterText(keyField, guest.keyPair.privateKey!);
      await tester.pump();
      final loginButton = find.byKey(const ValueKey('login'));
      await tester.tap(loginButton);
      await _settle(tester, frames: 14); // 7 s — auth + thread sync

      // ── Light mode screenshots ────────────────────────────────────
      await _takeScreenshots(tester, binding, appRouter, data, 'light');

      // ── Switch to dark mode ───────────────────────────────────────
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await _settle(tester, frames: 4); // let the theme rebuild

      // ── Dark mode screenshots ────────────────────────────────────
      await _takeScreenshots(tester, binding, appRouter, data, 'dark');

      // Clean up the test value.
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });
  });
}
