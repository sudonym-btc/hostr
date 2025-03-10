import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/data/sources/local/mode_storage.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/setup.dart';
import 'package:models/main.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// This file does not exist yet,
// it will be generated in the next step
import 'main.directories.g.dart';

void main() async {
  await setup(Env.test); // Call the setup function to register dependencies
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
          devices: [
            Devices.ios.iPhone12,
            Devices.ios.iPhone13,
          ],
          initialDevice: Devices.ios.iPhone13,
        ),
        MaterialThemeAddon(
          themes: [
            WidgetbookTheme(
              name: 'Light',
              data: getTheme(false),
            ),
            WidgetbookTheme(
              name: 'Dark',
              data: getTheme(true),
            ),
          ],
        ),
        LocalizationAddon(
          locales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          initialLocale: AppLocalizations.supportedLocales.last,
        ),
      ],
      appBuilder: (context, child) {
        final authValue = context.knobs
            .list(label: 'Auth', options: ['Guest', 'Host', 'Anon']);

        getIt<KeyStorage>().set(authValue == 'Guest'
            ? MockKeys.guest.privateKey!
            : MockKeys.hoster.privateKey!);

        getIt<ModeStorage>().set(authValue.toLowerCase());
        getIt<ModeCubit>().get();

        print('Auth value: $authValue');

        return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SafeArea(
                child: GlobalProviderWidget(
                    child: Scaffold(
                        body: Center(
              child: child,
            )))));
      },
      // The [directories] variable does not exist yet,
      // it will be generated in the next step
      directories: directories,
    );
  }
}
