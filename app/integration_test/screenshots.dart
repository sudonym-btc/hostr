/// Deterministic screenshot generator backed by pre-seeded relay data.
///
/// The screenshot shell script resets and seeds the local relay/chain stack
/// before launching this test. This file only derives the deterministic login
/// key + listing anchor locally, then drives the real app against that seeded
/// infrastructure.
///
/// **Requirements:** Docker must be running with at least `anvil` and
/// `escrow-contract-deploy` services up so the contract address can be
/// resolved and EVM transactions can land.
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
import 'package:hostr_sdk/testing/integration_test_harness.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';
import 'package:models/main.dart' show Listing;

import 'support/http_overrides_stub.dart'
    if (dart.library.io) 'support/http_overrides_io.dart';

// ── Seed configuration ──────────────────────────────────────────────────────
// Small dataset — just enough for every screenshot page.

const _config = SeedPipelineConfig(
  seed: 42,
  userCount: 8,
  hostRatio: 0.5, // 4 hosts, 4 guests
  listingsPerHostAvg: 2.0, // ~8 listings
  reservationRequestsPerGuest: 10, // 8 threads
  invalidReservationRate: 0,
  fundProfiles: true,
  setupLnbits: true,
  threadStages: ThreadStageSpec(
    textMessageCount: 4,
    completedRatio: 0.5,
    reviewRatio: 1,
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

typedef _ScreenshotFixture = ({SeedUser guest, Listing listing});

_ScreenshotFixture _buildFixture() {
  final factory = SeedFactory(config: _config);
  final users = factory.buildUsers();
  final hosts = users.where((user) => user.isHost).toList(growable: false);
  final guests = users.where((user) => !user.isHost).toList(growable: false);
  final listings = factory.buildListings(hosts);

  if (guests.isEmpty || listings.isEmpty) {
    throw StateError('Screenshot fixture generation produced no guest/listing');
  }

  return (guest: guests.first, listing: listings.first);
}

/// Take all screenshots for [mode] ("light" or "dark").
///
/// Self-contained: logs out → sign-in screenshot → logs in → connects NWC
/// → captures every authenticated page.  Call once per brightness mode.
Future<void> _takeScreenshots(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  AppRouter appRouter,
  _ScreenshotFixture fixture,
  String mode, {
  required IntegrationTestHarness harness,
}) async {
  // ── 0. Sign-in ────────────────────────────────────────────
  // Remove all NWC connections (disposes cubits + wipes storage) while the
  // key is still active, then logout.
  while (harness.hostr.nwc.connections.isNotEmpty) {
    await harness.hostr.nwc.remove(harness.hostr.nwc.connections.last);
  }
  await harness.hostr.auth.logout();
  await _settle(tester, frames: 2);
  appRouter.navigate(SignInRoute());
  await _settle(tester, frames: 6);
  await binding.takeScreenshot('screenshots/$mode/login.png');

  // ── 1. Log in + connect wallet ────────────────────────────
  final keyField = find.byKey(const ValueKey('key'));
  await tester.enterText(keyField, fixture.guest.keyPair.privateKey!);
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('login')));
  await _settle(tester, frames: 24); // 12 s — auth + thread sync

  await harness.connectNwc(
    user: fixture.guest.keyPair,
    appNamePrefix: 'screenshots',
  );
  await _settle(tester, frames: 6); // let the NWC cubit propagate

  // ── 2. Profile ────────────────────────────────────────────
  appRouter.navigate(ProfileRoute());
  await _settle(tester, frames: 6);
  await binding.takeScreenshot('screenshots/$mode/profile.png');

  // ── 3. Home / search ────────────────────────────────────────────
  appRouter.navigate(SearchRoute());
  await _settle(tester, frames: 6);
  await binding.takeScreenshot('screenshots/$mode/search.png');

  // ── 4. Listing detail ───────────────────────────────────────────
  appRouter.navigate(ListingRoute(a: fixture.listing.naddr()!));
  await _settle(tester, frames: 6);
  await binding.takeScreenshot('screenshots/$mode/listing.png');

  // ── 5. Inbox ────────────────────────────────────────────────────
  appRouter.navigate(InboxRoute());
  await _settle(tester, frames: 6);
  await binding.takeScreenshot('screenshots/$mode/threads.png');

  // ── 6. Thread detail ────────────────────────────────────────────
  final threadMap = getIt<Hostr>().messaging.threads.threads;
  if (threadMap.isNotEmpty) {
    appRouter.navigate(ThreadRoute(anchor: threadMap.keys.first));
    await _settle(tester, frames: 6);
    await binding.takeScreenshot('screenshots/$mode/thread.png');

    // ── 7. Tap "Pay" → payment modal ──────────────────────────────
    // Find a thread that shows the Pay button (pending threads where
    // the guest hasn't committed yet).
    const payKey = ValueKey('trade_action_pay');
    var payFinder = find.byKey(payKey);
    if (payFinder.evaluate().isEmpty) {
      for (final anchor in threadMap.keys.skip(1)) {
        appRouter.navigate(ThreadRoute(anchor: anchor));
        await _settle(tester, frames: 6);
        payFinder = find.byKey(payKey);
        if (payFinder.evaluate().isNotEmpty) break;
      }
    }

    if (payFinder.evaluate().isNotEmpty) {
      await tester.tap(payFinder.first);
      await _settle(tester, frames: 8); // give the modal time to load
      await binding.takeScreenshot('screenshots/$mode/payment.png');

      // The modal is pushed on the root navigator (useRootNavigator: true),
      // so appRouter.navigate() won't dismiss it. Pop via the root navigator.
      final rootNav = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      if (rootNav.canPop()) rootNav.pop();
      await _settle(tester, frames: 4);
    }
  }
}

// ── Test ────────────────────────────────────────────────────────────────────
//
// Everything runs in a **single** testWidgets so the widget tree survives
// across screenshots.  `_takeScreenshots` is self-contained per brightness
// mode: it logs out → takes a sign-in screenshot → logs back in → captures
// every authenticated page.
//
// We avoid `pumpAndSettle` entirely — the NDK's relay reconnect timers keep
// the frame scheduler permanently busy, so `pumpAndSettle` blocks forever.

void main() {
  // Accept the dev CA so HTTPS calls to anvil/rifrelay/boltz through
  // nginx-proxy don't fail with CERTIFICATE_VERIFY_FAILED.
  // main_development.dart does this for the normal app; integration tests
  // bypass that entrypoint so we must set it here.
  configureTestHttpOverrides();

  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot suite', (tester) async {
    final fixture = _buildFixture();

    // ── Bootstrap ───────────────────────────────────────────────────────
    await initCore(Env.dev);

    // Re-use the app's Hostr singleton so NWC connections land on the same
    // instance the UI reads from.
    final harness = await IntegrationTestHarness.create(
      name: 'screenshots',
      hostr: getIt<Hostr>(),
    );

    final appRouter = AppRouter();
    final app = MyApp(appRouter: appRouter);

    await mockNetworkImages(() async {
      // ── Mount the app once — keep it alive for the whole suite ─────
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
      await tester.pumpWidget(app);
      await _settle(tester);

      await binding.convertFlutterSurfaceToImage();
      await tester.pump();

      // ── Light mode ────────────────────────────────────────────────
      await _takeScreenshots(
        tester,
        binding,
        appRouter,
        fixture,
        'light',
        harness: harness,
      );

      // ── Dark mode ─────────────────────────────────────────────────
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await _settle(tester, frames: 4); // let the theme rebuild

      await _takeScreenshots(
        tester,
        binding,
        appRouter,
        fixture,
        'dark',
        harness: harness,
      );

      // Clean up the test value.
      tester.platformDispatcher.clearPlatformBrightnessTestValue();

      // Tear down AlbyHub app connections (does NOT dispose the app's Hostr).
      await harness.dispose();
    });
  });
}
