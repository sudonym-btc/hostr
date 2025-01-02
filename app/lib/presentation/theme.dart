import 'package:flutter/material.dart';

ThemeData getTheme(bool isDark) {
  return isDark ? ThemeData.dark() : ThemeData.light();
}
