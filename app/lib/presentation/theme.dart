import 'package:flutter/material.dart';

ThemeData getTheme(bool isDark) {
  return isDark
      ? ThemeData.dark().copyWith(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
            primary: Colors.deepPurple,
            onPrimary: Colors.white,
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
