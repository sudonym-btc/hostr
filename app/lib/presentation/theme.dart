import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';

ThemeData getTheme(bool isDark) {
  var darkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.white,
    brightness: Brightness.dark,
  );
  final lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.white);

  final colorScheme = isDark ? darkColorScheme : lightColorScheme;
  final base = isDark ? ThemeData.dark() : ThemeData.light();
  final baseGeneric = base.copyWith(
    appBarTheme: AppBarTheme(
      titleSpacing: kDefaultPadding.toDouble(),
      centerTitle: false,
      foregroundColor: colorScheme.onSurface,
      titleTextStyle: base.textTheme.titleLarge?.copyWith(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      actionsPadding: EdgeInsets.only(right: kDefaultPadding.toDouble()),
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
