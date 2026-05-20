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
///     -d DEVICE_ID
///
/// Or via the orchestrator script (all configured devices):
///   ./scripts/screenshots.sh
library;

import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/app.dart';
import 'package:hostr/data/sources/calendar/eventide_calendar_port.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/in_app_notification_toast.dart';
import 'package:hostr/presentation/reservation_published_popup_listener.dart';
import 'package:hostr/presentation/screens/guest/explore/explore_view.dart';
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
  orderRequestsPerGuest: 10, // 8 threads
  invalidOrderRate: 0,
  fundProfiles: false,
  setupLnbits: true,
  threadStages: ThreadStageSpec(
    textMessageCount: 4,
    completedRatio: 0.5,
    reviewRatio: 1,
  ),
);

// ── Helpers ─────────────────────────────────────────────────────────────────

/// Pump a deterministic number of frames after route/auth changes.
///
/// Chrome screenshot runs keep several timers and animations alive, so
/// [pumpAndSettle] can time out and leave follow-up pumps racing the test
/// lifecycle. Keep this to immediate pumps so the web test zone owns every
/// frame and transient UI does not linger because of real-time waits.
Future<void> _settle(WidgetTester tester, {int frames = 20}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump();
  }
}

bool _hasKeyPrefix(Widget widget, String prefix) {
  final key = widget.key;
  return key is ValueKey && key.value.toString().startsWith(prefix);
}

Future<void> _waitForReviewsAndStaysSummary(
  WidgetTester tester, {
  required String label,
}) async {
  final loadedReviews = find.byWidgetPredicate(
    (widget) => _hasKeyPrefix(widget, 'loaded-reviews-'),
  );
  final loadedStays = find.byWidgetPredicate(
    (widget) => _hasKeyPrefix(widget, 'loaded-stays-'),
  );
  final loadingReviews = find.byKey(const ValueKey('loading-reviews'));
  final loadingStays = find.byKey(const ValueKey('loading-stays'));

  for (var i = 0; i < 30; i++) {
    await _settle(tester, frames: 5);

    final feedbackLoaded =
        loadedReviews.evaluate().isNotEmpty &&
        loadedStays.evaluate().isNotEmpty &&
        loadingReviews.evaluate().isEmpty &&
        loadingStays.evaluate().isEmpty;
    if (feedbackLoaded) {
      await _settle(tester, frames: 20);
      return;
    }

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
  }

  debugPrint('📸 $label review/stay summary still loading; capturing anyway');
  await _settle(tester, frames: 40);
}

Future<void> _waitForListingFeedback(WidgetTester tester) async {
  await _waitForReviewsAndStaysSummary(tester, label: 'Listing');

  final loadedReviewList = find.byWidgetPredicate(
    (widget) => _hasKeyPrefix(widget, 'loaded-review-list-'),
  );
  final loadingReviewList = find.byKey(const ValueKey('loading-review-list'));

  for (var i = 0; i < 40; i++) {
    await _settle(tester, frames: 5);

    final reviewListLoaded =
        loadedReviewList.evaluate().isNotEmpty &&
        loadingReviewList.evaluate().isEmpty;
    if (reviewListLoaded) {
      await _settle(tester, frames: 20);
      return;
    }

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
  }

  debugPrint('📸 Listing review list still loading; capturing anyway');
  await _settle(tester, frames: 40);
}

Future<void> _waitForPaymentFees(WidgetTester tester) async {
  final loadedFees = find.byKey(const ValueKey('loaded-payment-fees'));
  final loadingFees = find.byKey(const ValueKey('loading-payment-fees'));
  final errorFees = find.byKey(const ValueKey('error-payment-fees'));

  for (var i = 0; i < 60; i++) {
    await _settle(tester, frames: 5);

    if (errorFees.evaluate().isNotEmpty) {
      debugPrint('📸 Payment fee estimate failed; capturing anyway');
      await _settle(tester, frames: 20);
      return;
    }

    final feesLoaded =
        loadedFees.evaluate().isNotEmpty && loadingFees.evaluate().isEmpty;
    if (feesLoaded) {
      await _settle(tester, frames: 20);
      return;
    }

    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
  }

  debugPrint('📸 Payment fees still loading; capturing anyway');
  await _settle(tester, frames: 40);
}

Finder _tripBookedDoneButton() {
  final scopedDone = find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey &&
        key.value.toString().startsWith('trip_booked_done_button_');
  }).hitTestable();
  if (scopedDone.evaluate().isNotEmpty) return scopedDone;

  return find.byKey(const ValueKey('trip_booked_done_button')).hitTestable();
}

bool _hasTripBookedPopup() {
  final scopedPopup = find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey &&
        key.value.toString().startsWith('trip_booked_popup_');
  });
  return scopedPopup.evaluate().isNotEmpty ||
      find.textContaining('Trip booked!').evaluate().isNotEmpty ||
      _tripBookedDoneButton().evaluate().isNotEmpty;
}

Future<void> _waitForTripBookedPopup(
  WidgetTester tester, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await _settle(tester, frames: 2);
    if (_hasTripBookedPopup()) return;
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
  }
}

Future<void> _dismissTripBookedPopupIfPresent(WidgetTester tester) async {
  if (!_hasTripBookedPopup()) return;

  final doneButton = _tripBookedDoneButton();
  if (doneButton.evaluate().isNotEmpty) {
    await tester.tap(doneButton.first, warnIfMissed: false);
  } else {
    final rootNav = tester.state<NavigatorState>(find.byType(Navigator).first);
    if (rootNav.canPop()) rootNav.pop();
  }

  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    await _settle(tester, frames: 2);
    if (!_hasTripBookedPopup()) return;
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
  }
}

Future<void> _showSyntheticTripBookedPopup(
  WidgetTester tester,
  _ScreenshotFixture fixture,
) async {
  final rootNav = tester.state<NavigatorState>(find.byType(Navigator).first);
  final threadMap = getIt<Hostr>().messaging.threads.threads;
  final tradeId = threadMap.keys.isNotEmpty
      ? threadMap.keys.first
      : fixture.listing.getDtag() ?? 'screenshot-trip-booked';
  await rootNav.push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => TripBookedPopupView(
        key: ValueKey('trip_booked_popup_$tradeId'),
        tradeSummary: _ScreenshotTripBookedSummary(listing: fixture.listing),
        doneButtonKey: ValueKey('trip_booked_done_button_$tradeId'),
        onDone: () => Navigator.of(context).pop(),
      ),
    ),
  );
}

Future<void> _captureTripBookedScreenshot(
  WidgetTester tester,
  IntegrationTestWidgetsFlutterBinding binding,
  _ScreenshotFixture fixture,
  String mode,
) async {
  await _waitForTripBookedPopup(tester, timeout: const Duration(seconds: 8));

  if (!_hasTripBookedPopup()) {
    debugPrint('📸 [$mode] Trip Booked popup did not appear; showing fixture');
    unawaited(_showSyntheticTripBookedPopup(tester, fixture));
    await _waitForTripBookedPopup(tester, timeout: const Duration(seconds: 8));
  }

  if (_hasTripBookedPopup()) {
    await _settle(tester, frames: 20);
    debugPrint('📸 [$mode] ✓ trip booked');
    await _takeScreenshot(binding, 'screenshots/$mode/trip_booked.png');
    await _dismissTripBookedPopupIfPresent(tester);
    return;
  }

  debugPrint('📸 [$mode] Trip Booked popup unavailable; continuing');
}

void _refocusExploreMapForScreenshot(WidgetTester tester) {
  final exploreElements = find.byType(ExploreView).evaluate().toList();
  if (exploreElements.length != 1) {
    debugPrint(
      '📸 Explore map refocus skipped; found ${exploreElements.length} views',
    );
    return;
  }

  final state = (exploreElements.single as StatefulElement).state;
  if (state is ExploreViewState) {
    state.refocusMapForScreenshot();
  }
}

Future<void> _waitForExploreMapRefocus(WidgetTester tester) async {
  _refocusExploreMapForScreenshot(tester);
  await _settle(tester, frames: 10);

  // Google Maps on web applies camera bounds inside the platform view. Give it
  // a little real time after focusAll() so all markers finish refitting.
  for (var i = 0; i < 12; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    });
    await _settle(tester, frames: 8);
  }
}

Future<void> _takeScreenshot(
  IntegrationTestWidgetsFlutterBinding binding,
  String path,
) async {
  if (!kIsWeb) {
    debugPrint('SCREENSHOT_EXTERNAL_READY $path');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await binding
        .takeScreenshot(path)
        .timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            debugPrint('📸 Screenshot timed out for $path; continuing');
            return <int>[];
          },
        );
    return;
  }

  await binding.takeScreenshot(path);
}

typedef _ScreenshotFixture = ({SeedUser guest, Listing listing});

class _ScreenshotTripBookedSummary extends StatelessWidget {
  final Listing listing;

  const _ScreenshotTripBookedSummary({required this.listing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.home_rounded,
              color: colorScheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  listing.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Jun 27 - Jul 3',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
  IntegrationTestHarness? harness,
}) async {
  final hostr = getIt<Hostr>();
  debugPrint('📸 [$mode] Starting screenshot suite');

  // ── 0. Sign-in ────────────────────────────────────────────
  // Remove all NWC connections (disposes cubits + wipes storage) while the
  // key is still active, then logout.
  while (hostr.nwc.connections.isNotEmpty) {
    debugPrint('📸 [$mode] Removing NWC connection…');
    await hostr.nwc.remove(hostr.nwc.connections.last);
  }
  debugPrint('📸 [$mode] Logging out…');
  await hostr.auth.logout();
  await _settle(tester);
  appRouter.navigate(SignInRoute());
  await _settle(tester);
  debugPrint('📸 [$mode] ✓ login');
  await _takeScreenshot(binding, 'screenshots/$mode/login.png');

  // ── 1. Log in + connect wallet ────────────────────────────
  // On web, tester.enterText doesn't reliably trigger onChanged so the
  // login button stays disabled.  Call the auth API directly instead —
  // the sign-in screenshot is already captured with the empty form above.
  debugPrint('📸 [$mode] Signing in…');
  await hostr.auth.signin(fixture.guest.keyPair.privateKey!);
  await _settle(tester);
  debugPrint('📸 [$mode] Signed in, connecting NWC…');

  await harness?.connectNwc(
    user: fixture.guest.keyPair,
    appNamePrefix: 'screenshots',
  );
  await _settle(tester);

  await _captureTripBookedScreenshot(tester, binding, fixture, mode);

  // ── 2. Profile ────────────────────────────────────────────
  appRouter.navigate(ProfileRoute());
  await _settle(tester);
  await _dismissTripBookedPopupIfPresent(tester);
  debugPrint('📸 [$mode] ✓ profile');
  await _takeScreenshot(binding, 'screenshots/$mode/profile.png');

  // ── 3. Home / explore ────────────────────────────────────────────
  appRouter.navigate(ExploreRoute());
  await _settle(tester);
  await _waitForReviewsAndStaysSummary(tester, label: 'Explore');
  await _waitForExploreMapRefocus(tester);
  await _dismissTripBookedPopupIfPresent(tester);
  debugPrint('📸 [$mode] ✓ explore');
  await _takeScreenshot(binding, 'screenshots/$mode/explore.png');

  // ── 4. Trips ────────────────────────────────────────────────────
  appRouter.navigate(TripsRoute());
  await _settle(tester);
  await _dismissTripBookedPopupIfPresent(tester);
  debugPrint('📸 [$mode] ✓ trips');
  await _takeScreenshot(binding, 'screenshots/$mode/trips.png');

  // ── 5. Listing detail ───────────────────────────────────────────
  appRouter.navigate(ListingRoute(a: fixture.listing.naddr()!));
  await _settle(tester);
  await _waitForListingFeedback(tester);
  await _dismissTripBookedPopupIfPresent(tester);
  debugPrint('📸 [$mode] ✓ listing');
  await _takeScreenshot(binding, 'screenshots/$mode/listing.png');

  // ── 6. Inbox ────────────────────────────────────────────────────
  appRouter.navigate(InboxRoute());
  await _settle(tester);
  await _dismissTripBookedPopupIfPresent(tester);
  debugPrint('📸 [$mode] ✓ threads');
  await _takeScreenshot(binding, 'screenshots/$mode/threads.png');

  // ── 7. Thread detail ────────────────────────────────────────────
  final threadMap = getIt<Hostr>().messaging.threads.threads;
  if (threadMap.isNotEmpty) {
    appRouter.navigate(ThreadRoute(anchor: threadMap.keys.first));
    await _settle(tester);
    await _dismissTripBookedPopupIfPresent(tester);
    debugPrint('📸 [$mode] ✓ thread');
    await _takeScreenshot(binding, 'screenshots/$mode/thread.png');

    // ── 8. Tap "Pay" → payment modal ──────────────────────────────
    // Find a thread that shows the Pay button (pending threads where
    // the guest hasn't committed yet).
    const payKey = ValueKey('trade_action_pay');
    var payFinder = find.byKey(payKey);
    if (payFinder.evaluate().isEmpty) {
      for (final anchor in threadMap.keys.skip(1)) {
        appRouter.navigate(ThreadRoute(anchor: anchor));
        await _settle(tester);
        payFinder = find.byKey(payKey);
        if (payFinder.evaluate().isNotEmpty) break;
      }
    }

    if (payFinder.evaluate().isNotEmpty) {
      await tester.tap(payFinder.first);
      await _settle(tester);
      await _waitForPaymentFees(tester);
      await _dismissTripBookedPopupIfPresent(tester);
      debugPrint('📸 [$mode] ✓ payment');
      await _takeScreenshot(binding, 'screenshots/$mode/payment.png');

      // The modal is pushed on the root navigator (useRootNavigator: true),
      // so appRouter.navigate() won't dismiss it. Pop via the root navigator.
      final rootNav = tester.state<NavigatorState>(
        find.byType(Navigator).first,
      );
      if (rootNav.canPop()) rootNav.pop();
      await _settle(tester);
    }
  }
  debugPrint('📸 [$mode] Done (${threadMap.length} threads found)');
}

// ── Test ────────────────────────────────────────────────────────────────────
//
// Everything runs in a **single** testWidgets so the widget tree survives
// across screenshots.  `_takeScreenshots` is self-contained per brightness
// mode: it logs out → takes a sign-in screenshot → logs back in → captures
// every authenticated page.
//
// We use `pumpAndSettle` with a timeout so pages render fully before capture.
// If the NDK relay reconnect timers prevent idle, the timeout will expire and
// we proceed with the screenshot regardless.

void main() {
  // Accept the dev CA so HTTPS calls to anvil/boltz through
  // nginx-proxy don't fail with CERTIFICATE_VERIFY_FAILED.
  // main_development.dart does this for the normal app; integration tests
  // bypass that entrypoint so we must set it here.
  configureTestHttpOverrides();

  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('screenshot suite', (tester) async {
    InAppNotificationToast.setSuppressForTesting(true);
    EventideCalendarPort.suppressPermissionRequestsForTesting = true;
    final fixture = _buildFixture();

    // ── Bootstrap ───────────────────────────────────────────────────────
    await initCore(Env.dev);

    // Re-use the app's Hostr singleton so NWC connections land on the same
    // instance the UI reads from.
    // IntegrationTestHarness relies on dart:io (Anvil HTTP, AlbyHub HTTP,
    // Platform.environment) so it's only created on native platforms.
    final IntegrationTestHarness? harness = kIsWeb
        ? null
        : await IntegrationTestHarness.create(
            name: 'screenshots',
            hostr: getIt<Hostr>(),
          );

    final appRouter = AppRouter();
    final app = MyApp(appRouter: appRouter);
    debugPrint('📸 Bootstrap complete (web=$kIsWeb)');

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
      debugPrint('📸 Switching to dark mode');
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      await _settle(tester);

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
      InAppNotificationToast.setSuppressForTesting(false);

      // Tear down AlbyHub app connections (does NOT dispose the app's Hostr).
      await harness?.dispose();
      debugPrint('📸 All screenshots complete');
    });
  }, timeout: const Timeout(Duration(minutes: 6)));
}
