import 'package:flutter/material.dart';

ThemeData getTheme(bool isDark) {
  return isDark
      ? ThemeData.dark().copyWith(
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
          splashColor: Colors.white, // Set splash color to match theme
        )
      : ThemeData.light().copyWith(
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
