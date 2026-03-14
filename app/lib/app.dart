import 'dart:async';
import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/background_task_type.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr/route/nostr_link_handler.dart';
import 'package:hostr/route/notification_deep_link_handler.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:workmanager/workmanager.dart';

/// The Widget that configures your application.
class MyApp extends StatefulWidget {
  final AppRouter? appRouter;
  const MyApp({super.key, this.appRouter});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AppRouter _appRouter;
  late final NostrLinkHandler _nostrLinkHandler;
  late final NotificationDeepLinkHandler _notificationDeepLinkHandler;

  @override
  void initState() {
    super.initState();
    _appRouter = widget.appRouter ?? AppRouter();
    _nostrLinkHandler = NostrLinkHandler(router: _appRouter);
    _notificationDeepLinkHandler = NotificationDeepLinkHandler(
      router: _appRouter,
    );
    _nostrLinkHandler.init();
    _notificationDeepLinkHandler.init();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nostrLinkHandler.dispose();
    _notificationDeepLinkHandler.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _scheduleOnchainOperations();
    }
  }

  /// When the app goes to background during any active onchain operation
  /// (swap, escrow fund/claim/release, etc.), schedule background work so the
  /// operations can complete and the user gets a notification.
  ///
  /// Two tasks are scheduled:
  ///
  /// 1. **One-off task** — uses `UIApplication.beginBackgroundTask`, which
  ///    runs *immediately* in the current process and gives ~30 s of
  ///    background execution.  Often enough for a single receipt poll cycle.
  ///
  /// 2. **Processing task** — submits a `BGProcessingTaskRequest` with
  ///    `requiresNetworkConnectivity = true`.  iOS schedules this
  ///    opportunistically (could be minutes later) but grants up to several
  ///    minutes of execution with live network.  Acts as a safety-net if the
  ///    one-off window expires before confirmation arrives.
  Future<void> _scheduleOnchainOperations() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    try {
      final hasActive = await getIt<Hostr>().backgroundWorker
          .hasActiveOnchainOperations();
      if (!hasActive) return;

      // Immediate ~30 s background window (runs in current process).
      await Workmanager().registerOneOffTask(
        BackgroundTaskType.onchainOps.identifier,
        BackgroundTaskType.onchainOps.taskName,
        initialDelay: const Duration(seconds: 0),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      // Longer processing window scheduled by iOS when network is available. Scheduler may delay this by minutes, but it's a safety net in case the one-off task expires before the operation completes.
      await Workmanager().registerProcessingTask(
        BackgroundTaskType.onchainOps.identifier,
        BackgroundTaskType.onchainOps.taskName,
        initialDelay: const Duration(seconds: 0),
        constraints: Constraints(networkType: NetworkType.connected),
      );
    } catch (_) {
      // Best-effort — don't crash the lifecycle handler.
    }
  }

  @override
  Widget build(BuildContext context) {
    // Application shell and router configuration
    return MaterialApp.router(
      // Providing a restorationScopeId allows the Navigator built by the
      // MaterialApp to restore the navigation stack when a user leaves and
      // returns to the app after it has been killed while running in the
      // background.
      restorationScopeId: 'app',

      // Provide the generated AppLocalizations to the MaterialApp. This
      // allows descendant Widgets to display the correct translations
      // depending on the user's locale.
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en')],
      debugShowCheckedModeBanner: false,

      // Use AppLocalizations to configure the correct application title
      // depending on the user's locale.
      //
      // The appTitle is defined in .arb files found in the localization
      // directory.
      onGenerateTitle: (BuildContext context) =>
          AppLocalizations.of(context)!.appTitle,

      // Define light and dark color themes and respect system preference.
      theme: getTheme(false),
      darkTheme: getTheme(true),
      themeMode: ThemeMode.system, // Use system theme mode

      routerConfig: _appRouter.config(navigatorObservers: () => [MyObserver()]),
    );
  }
}

class MyObserver extends AutoRouterObserver {
  /// Broadcast stream that fires every time a route is popped.
  /// Screens like [AppShellScreen] listen to this to restore the navbar.
  static final StreamController<void> _onPop =
      StreamController<void>.broadcast();
  static Stream<void> get onPop => _onPop.stream;

  CustomLogger logger = CustomLogger();

  @override
  void didPush(Route route, Route? previousRoute) {
    logger.d('New route pushed: ${route.settings.name}');
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    logger.d('Route popped: ${route.settings.name}');
    _onPop.add(null);
  }

  // only override to observer tab routes
  @override
  void didInitTabRoute(TabPageRoute route, TabPageRoute? previousRoute) {
    logger.d('Tab route visited: ${route.name}');
  }

  @override
  void didChangeTabRoute(TabPageRoute route, TabPageRoute previousRoute) {
    logger.d('Tab route re-visited: ${route.name}');
  }
}
