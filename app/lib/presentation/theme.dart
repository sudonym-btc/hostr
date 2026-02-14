import 'package:flutter/material.dart';

ThemeData getTheme(bool isDark) {
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
  return isDark
      ? baseGeneric.copyWith(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.white,
            brightness: Brightness.dark,
            primary: Colors.white,
            onPrimary: Colors.black,
            surface: Colors.black,
            onSurface: Colors.white,
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
          ),
          splashColor: Colors.black, // Set splash color to match theme
        )
      : baseGeneric.copyWith(
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Colors.deepPurple,
            unselectedItemColor: Colors.black54,
            type: BottomNavigationBarType.fixed,
          ),
          splashColor: Colors.deepPurple, // Set splash color to match theme
        );
}
