import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/presentation/component/widgets/explore/cloud_map_style.dart';
import 'package:hostr/presentation/theme.dart';

final _prettyJson = const JsonEncoder.withIndent('  ');

void main() {
  test('writes cloud map style import files from app theme data', () {
    final outputDir = Directory('../infrastructure/maps');

    _writeStyle(
      file: File('${outputDir.path}/hostr-light-map-style.json'),
      isDarkMode: false,
    );
    _writeStyle(
      file: File('${outputDir.path}/hostr-dark-map-style.json'),
      isDarkMode: true,
    );
  });
}

void _writeStyle({required File file, required bool isDarkMode}) {
  final theme = getTheme(isDarkMode);
  final palette = cloudMapPaletteFromTheme(theme, isDarkMode: isDarkMode);
  final style = buildCloudMapStyle(isDarkMode: isDarkMode, palette: palette);

  file.writeAsStringSync('${_prettyJson.convert(style)}\n');
  stdout.writeln('Wrote ${file.path}');
}
