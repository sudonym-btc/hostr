import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/presentation/component/widgets/explore/cloud_map_style.dart';
import 'package:hostr/presentation/theme.dart';

final _prettyJson = const JsonEncoder.withIndent('  ');

void main() {
  test('dark cloud map palette keeps water on the app background', () {
    final theme = getTheme(true);
    final palette = cloudMapPaletteFromTheme(theme, isDarkMode: true);

    expect(palette.water, '#121212');
    expect(palette.labelStroke, palette.water);
    expect(palette.land, '#252525');
    expect(palette.road, '#191919');

    final style = buildCloudMapStyle(isDarkMode: true, palette: palette);
    expect(style['backgroundColor'], palette.water);
  });

  test('light cloud map style keeps its land background', () {
    final theme = getTheme(false);
    final palette = cloudMapPaletteFromTheme(theme, isDarkMode: false);
    final style = buildCloudMapStyle(isDarkMode: false, palette: palette);

    expect(style['backgroundColor'], palette.land);
  });

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
