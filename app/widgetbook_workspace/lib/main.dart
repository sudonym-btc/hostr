import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/data/sources/local/mode_storage.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/setup.dart';
import 'package:hostr_sdk/hostr.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// This file does not exist yet,
// it will be generated in the next step
import 'main.directories.g.dart';
import 'seed_data.dart';

void main() async {
  await setup(Env.mock); // Call the setup function to register dependencies
  await initSeedData();
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      addons: [
        DeviceFrameAddon(
          devices: [Devices.ios.iPhone12, Devices.ios.iPhone13],
          initialDevice: Devices.ios.iPhone13,
        ),
        BuilderAddon(
          name: 'Use case layout',
          builder: (context, child) {
            final path =
                WidgetbookState.maybeOf(context)?.path?.toLowerCase() ?? '';
            final isScreenUseCase = path.contains('/screens/');
            if (isScreenUseCase) {
              return child;
            }

            return Padding(padding: const EdgeInsets.all(16), child: child);
          },
        ),
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Light', data: getTheme(false)),
            WidgetbookTheme(name: 'Dark', data: getTheme(true)),
          ],
        ),
        LocalizationAddon(
          locales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          initialLocale: AppLocalizations.supportedLocales.last,
        ),
      ],
      appBuilder: (context, child) {
        final authValue = context.knobs.object.dropdown<String>(
          label: 'Auth',
          options: ['Guest', 'Host', 'Anon'],
        );

        final mode = authValue.toLowerCase();
        getIt<ModeStorage>().set(mode);
        getIt<ModeCubit>().get();

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: SafeArea(
            child: GlobalProviderWidget(
              child: AuthLoader(
                mode: mode,
                child: Scaffold(body: child),
              ),
            ),
          ),
        );
      },
      // The [directories] variable does not exist yet,
      // it will be generated in the next step
      directories: directories,
    );
  }
}

class AuthLoader extends StatefulWidget {
  final String mode;
  final Widget child;
  const AuthLoader({super.key, required this.mode, required this.child});

  @override
  State<AuthLoader> createState() => _AuthLoaderState();
}

class _AuthLoaderState extends State<AuthLoader> {
  bool _ready = false;
  String? _lastMode;

  @override
  void initState() {
    super.initState();
    _syncAuth(widget.mode);
  }

  @override
  void didUpdateWidget(covariant AuthLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode) {
      _syncAuth(widget.mode);
    }
  }

  Future<void> _syncAuth(String mode) async {
    if (_lastMode == mode) return;
    _lastMode = mode;
    setState(() {
      _ready = false;
    });

    if (mode == 'anon') {
      await getIt<Hostr>().auth.logout();
      if (!mounted) return;
      setState(() {
        _ready = true;
      });
      return;
    }

    final privateKey = mode == 'guest'
        ? MockKeys.guest.privateKey!
        : MockKeys.hoster.privateKey!;
    print('Signing in with mode: $mode, privateKey: $privateKey');
    await getIt<Hostr>().auth.signin(privateKey);
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }
    return widget.child;
  }
}
