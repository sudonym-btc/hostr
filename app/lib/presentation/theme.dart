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
            selectedItemColor: Colors.white, // Use white for selected item
            unselectedItemColor: Colors.grey, // Use grey for unselected item
          ),
        )
      : ThemeData.dark().copyWith(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        );
}
