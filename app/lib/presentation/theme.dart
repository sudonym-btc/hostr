import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';

import 'app_spacing_theme.dart';

const _appFontFamily = 'Inter';

ThemeData getTheme(bool isDark) {
  final darkColorScheme =
      ColorScheme.fromSwatch(
        primarySwatch: Colors.grey,
        backgroundColor: Colors.black,
        cardColor: Colors.black,
        accentColor: const Color(0xFF29539B),
        brightness: Brightness.dark,
      ).copyWith(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: const Color(0xFF29539B),
        onSecondary: const Color(0xFFF4F7FF),
        surface: Colors.black,
        onSurface: Colors.white,
        surfaceDim: const Color(0xFF050505),
        surfaceBright: const Color(0xFF1A1A1A),
        surfaceContainerLowest: const Color(0xFF000000),
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainer: const Color(0xFF111111),
        surfaceContainerHigh: const Color(0xFF181818),
        surfaceContainerHighest: const Color(0xFF222222),
        onSurfaceVariant: const Color(0xFFD0D0D0),
        outline: const Color(0xFF6E6E6E),
        outlineVariant: const Color(0xFF3A3A3A),
      );
  final lightColorScheme =
      ColorScheme.fromSwatch(
        primarySwatch: Colors.grey,
        backgroundColor: Colors.white,
        cardColor: Colors.white,
        accentColor: const Color(0xFFDCE8FF),
        brightness: Brightness.light,
      ).copyWith(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: const Color(0xFFDCE8FF),
        onSecondary: const Color(0xFF14386B),
        surface: Colors.white,
        onSurface: Colors.black,
        surfaceDim: const Color(0xFFF5F5F5),
        surfaceBright: const Color(0xFFFFFFFF),
        surfaceContainerLowest: const Color(0xFFFFFFFF),
        surfaceContainerLow: const Color(0xFFFAFAFA),
        surfaceContainer: const Color(0xFFF3F3F3),
        surfaceContainerHigh: const Color(0xFFEDEDED),
        surfaceContainerHighest: const Color(0xFFE6E6E6),
        onSurfaceVariant: const Color(0xFF5F5F5F),
        outline: const Color(0xFF8A8A8A),
        outlineVariant: const Color(0xFFD8D8D8),
      );

  final colorScheme = isDark ? darkColorScheme : lightColorScheme;
  final base = isDark ? ThemeData.dark() : ThemeData.light();
  final textTheme = base.textTheme.apply(
    fontFamily: _appFontFamily,
    bodyColor: colorScheme.onSurface,
    displayColor: colorScheme.onSurface,
  );
  final primaryTextTheme = base.primaryTextTheme.apply(
    fontFamily: _appFontFamily,
    bodyColor: colorScheme.onPrimary,
    displayColor: colorScheme.onPrimary,
  );
  final baseGeneric = base.copyWith(
    textTheme: textTheme,
    primaryTextTheme: primaryTextTheme,
    extensions: const <ThemeExtension<dynamic>>[AppSpacingTheme()],
    appBarTheme: AppBarTheme(
      leadingWidth: kDefaultPadding.toDouble(),
      titleSpacing: kDefaultPadding.toDouble(),
      centerTitle: false,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: textTheme.displayMedium?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(
          color: base.colorScheme.surfaceContainer.withAlpha(0),
        ),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: base.colorScheme.surfaceContainer),
      ),
    ),
    // filledButtonTheme: FilledButtonThemeData(
    //   style: ButtonStyle(
    //     textStyle: WidgetStateProperty.resolveWith((states) {
    //       return base.textTheme.labelMedium?.copyWith();
    //       return const TextStyle(
    //         fontWeight: FontWeight.w600,
    //         // fontSize: 12,
    //         // letterSpacing: 1.2,
    //         // color: Colors.white,
    //       );
    //     }),
    //   ),
    // ),
  );

  final bottomAppBarTheme = BottomAppBarThemeData(
    color: colorScheme.surface,
    elevation: 0,
    padding: EdgeInsets.zero,
  );

  return isDark
      ? baseGeneric.copyWith(
          brightness: Brightness.dark,
          colorScheme: darkColorScheme,
          scaffoldBackgroundColor: bottomAppBarTheme.color,
          bottomAppBarTheme: bottomAppBarTheme,
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: bottomAppBarTheme.color,
            selectedItemColor: darkColorScheme.onSurface,
            elevation: 0,
            unselectedItemColor: darkColorScheme.onSurface.withAlpha(
              153,
            ), // 0.6 * 255 = 153
            type: BottomNavigationBarType.shifting,
          ),
          splashColor:
              darkColorScheme.primary, // Set splash color to match theme
        )
      : baseGeneric.copyWith(
          brightness: Brightness.light,
          colorScheme: lightColorScheme,
          scaffoldBackgroundColor: bottomAppBarTheme.color,
          bottomAppBarTheme: bottomAppBarTheme,
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: bottomAppBarTheme.color,
            selectedItemColor: lightColorScheme.onSurface,
            elevation: 0,
            unselectedItemColor: lightColorScheme.onSurface.withAlpha(
              153,
            ), // 0.6 * 255 = 153
            type: BottomNavigationBarType.shifting,
          ),
          splashColor:
              lightColorScheme.primary, // Set splash color to match theme
        );
}
