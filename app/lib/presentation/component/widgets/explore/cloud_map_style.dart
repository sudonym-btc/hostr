import 'dart:convert';

import 'package:flutter/material.dart';

class CloudMapPalette {
  final String water;
  final String land;
  final String road;
  final String park;
  final String labelFill;
  final String labelStroke;
  final String outline;

  const CloudMapPalette({
    required this.water,
    required this.land,
    required this.road,
    required this.park,
    required this.labelFill,
    required this.labelStroke,
    required this.outline,
  });
}

String _colorToHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b';
}

String _lerpHex(Color a, Color b, double t) =>
    _colorToHex(Color.lerp(a, b, t)!);

CloudMapPalette cloudMapPaletteFromTheme(
  ThemeData theme, {
  required bool isDarkMode,
}) {
  final cs = theme.colorScheme;

  if (isDarkMode) {
    return CloudMapPalette(
      water: _colorToHex(cs.surfaceContainerLowest),
      land: _colorToHex(cs.surfaceBright),
      road: _colorToHex(cs.surfaceContainer),
      park: _colorToHex(cs.surfaceContainerLow),
      labelFill: _colorToHex(cs.onSurfaceVariant),
      labelStroke: _colorToHex(cs.surfaceContainerLowest),
      outline: _lerpHex(cs.surfaceBright, cs.outlineVariant, 2 / 17),
    );
  }

  return CloudMapPalette(
    water: _colorToHex(cs.surfaceContainerLowest),
    land: _colorToHex(cs.surfaceContainerHighest),
    road: _colorToHex(cs.surfaceContainerHigh),
    park: _colorToHex(cs.surfaceContainerLow),
    labelFill: _colorToHex(cs.onSurfaceVariant),
    labelStroke: _colorToHex(cs.surface),
    outline: _colorToHex(cs.outlineVariant),
  );
}

Map<String, Object?> buildCloudMapStyle({
  required bool isDarkMode,
  required CloudMapPalette palette,
}) {
  return {
    'monochrome': true,
    'variant': isDarkMode ? 'dark' : 'light',
    'backgroundColor': isDarkMode ? palette.water : palette.land,
    'styles': [
      {
        'id': 'infrastructure',
        'geometry': {'visible': false},
        'label': {'visible': false},
      },
      {
        'id': 'infrastructure.railwayTrack',
        'geometry': {'visible': false},
      },
      {
        'id': 'infrastructure.roadNetwork.road',
        'geometry': {
          'fillColor': palette.road,
          'strokeColor': palette.outline,
          'strokeWidth': 1,
        },
        'label': {'visible': false},
      },
      {
        'id': 'infrastructure.roadNetwork.road.arterial',
        'geometry': {'visible': false},
        'label': {'visible': false},
      },
      {
        'id': 'infrastructure.roadNetwork.road.highway',
        'geometry': {
          'visible': true,
          'fillColor': palette.road,
          'strokeColor': palette.outline,
          'strokeWidth': 1,
        },
        'label': {'visible': false},
      },
      {
        'id': 'infrastructure.roadNetwork.road.local',
        'geometry': {'visible': false},
        'label': {'visible': false},
      },
      {
        'id': 'infrastructure.roadNetwork.roadShield',
        'label': {'visible': false},
      },
      {
        'id': 'infrastructure.transitStation',
        'label': {'visible': false},
      },
      {
        'id': 'infrastructure.urbanArea',
        'geometry': {'visible': false},
      },
      {
        'id': 'natural.land',
        'geometry': {
          'visible': true,
          'fillOpacity': 1,
          'fillColor': palette.land,
        },
      },
      {
        'id': 'natural.land.landCover',
        'geometry': {'fillOpacity': 1, 'fillColor': palette.land},
      },
      {
        'id': 'natural.land.landCover.ice',
        'geometry': {
          'visible': false,
          'fillOpacity': 1,
          'fillColor': palette.land,
        },
      },
      {
        'id': 'natural.water',
        'geometry': {'fillColor': palette.water},
        'label': {
          'textFillColor': isDarkMode ? palette.labelFill : palette.outline,
          'textStrokeColor': palette.water,
        },
      },
      {
        'id': 'pointOfInterest',
        'geometry': {'fillColor': palette.road},
        'label': {
          'visible': false,
          'pinFillColor': palette.outline,
          'textFillColor': palette.labelFill,
          'textStrokeColor': palette.water,
        },
      },
      {
        'id': 'pointOfInterest.recreation.park',
        'geometry': {'visible': false, 'fillColor': palette.park},
        'label': {
          'visible': false,
          'textFillColor': palette.labelFill,
          'textStrokeColor': palette.park,
        },
      },
      {
        'id': 'political',
        'geometry': {'fillColor': palette.water},
        'label': {
          'textFillColor': palette.labelFill,
          'textStrokeColor': palette.water,
        },
      },
      {
        'id': 'political.border',
        'geometry': {'visible': false},
      },
      {
        'id': 'political.landParcel',
        'geometry': {'visible': false},
      },
    ],
  };
}

String encodeCloudMapStyle({
  required bool isDarkMode,
  required CloudMapPalette palette,
}) {
  return jsonEncode(
    buildCloudMapStyle(isDarkMode: isDarkMode, palette: palette),
  );
}
