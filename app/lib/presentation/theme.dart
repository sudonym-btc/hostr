import 'package:flutter/material.dart';

ThemeData getTheme(bool isDark) {
  var darkColorScheme = ColorScheme.fromSeed(
    seedColor: Colors.white,
    brightness: Brightness.dark,
  );
  final lightColorScheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);

  final colorScheme = isDark ? darkColorScheme : lightColorScheme;
  final base = isDark ? ThemeData.dark() : ThemeData.light();
  final baseGeneric = base.copyWith(
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
          splashColor: Colors.black, // Set splash color to match theme
        )
      : baseGeneric.copyWith(
          brightness: Brightness.light,
          colorScheme: lightColorScheme,
          scaffoldBackgroundColor: bottomAppBarTheme.color,
          bottomAppBarTheme: bottomAppBarTheme,
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: bottomAppBarTheme.color,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.black54,
            type: BottomNavigationBarType.fixed,
          ),
          splashColor: Colors.deepPurple, // Set splash color to match theme
        );
}
