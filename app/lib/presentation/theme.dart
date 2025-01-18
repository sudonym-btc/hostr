import 'package:flutter/material.dart';

ThemeData getTheme(bool isDark) {
  return isDark
      ? ThemeData.dark().copyWith(
          appBarTheme: AppBarTheme(
              iconTheme: IconThemeData(color: Colors.white),
              backgroundColor: Colors.black,
              titleTextStyle: TextStyle(color: Colors.white)),
          bottomAppBarTheme: BottomAppBarTheme(color: Colors.black),
          bottomSheetTheme: BottomSheetThemeData(
              backgroundColor: Colors.black,
              modalBackgroundColor: Colors.black),
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          chipTheme: ChipThemeData(labelStyle: TextStyle(color: Colors.white)),
          listTileTheme: ListTileThemeData(
              iconColor: Colors.white,
              titleTextStyle: TextStyle(color: Colors.white),
              subtitleTextStyle: TextStyle(color: Colors.white)),
        )
      : ThemeData.dark().copyWith(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        );
}
