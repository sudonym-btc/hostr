import 'dart:convert';

import 'package:flutter/material.dart';

String _colorToHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b';
}

String _lerpHex(Color a, Color b, double t) =>
    _colorToHex(Color.lerp(a, b, t)!);

({
  String water,
  String land,
  String road,
  String park,
  String labelFill,
  String labelStroke,
  String outline,
})
_mapPalette(BuildContext context, bool isDarkMode) {
  final cs = Theme.of(context).colorScheme;

  if (isDarkMode) {
    return (
      water: _lerpHex(cs.surface, cs.surfaceContainerLowest, 1 / 6),
      land: _colorToHex(cs.surfaceContainer),
      road: _lerpHex(cs.surface, cs.surfaceContainerLowest, 4 / 9),
      park: _colorToHex(cs.surfaceContainerLow),
      labelFill: _lerpHex(cs.surface, cs.onSurface, 80 / 255),
      labelStroke: _lerpHex(cs.surface, cs.surfaceContainerLowest, 1 / 6),
      outline: _lerpHex(cs.surfaceBright, cs.outlineVariant, 2 / 17),
    );
  }

  return (
    water: _colorToHex(cs.surfaceContainerLowest),
    land: _colorToHex(cs.surfaceContainerHighest),
    road: _colorToHex(cs.surfaceContainerHigh),
    park: _colorToHex(cs.surfaceContainerLow),
    labelFill: _colorToHex(cs.onSurfaceVariant),
    labelStroke: _colorToHex(cs.surface),
    outline: _colorToHex(cs.outlineVariant),
  );
}

String getMapStyle(BuildContext context, bool isDarkMode) {
  final palette = _mapPalette(context, isDarkMode);
  final water = palette.water;
  final land = palette.land;
  final road = palette.road;
  final park = palette.park;
  final labelFill = palette.labelFill;
  final labelStroke = palette.labelStroke;
  final outline = palette.outline;

  return '''
[
  {
    "elementType": "geometry",
    "stylers": [{ "color": "$land" }]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "$labelFill" }]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{ "color": "$labelStroke" }]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{ "color": "$water" }]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "$outline" }]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{ "color": "$land" }]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{ "color": "$land" }]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "$outline" }]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{ "color": "$park" }]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "$outline" }]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.stroke",
    "stylers": [{ "color": "$park" }]
  },
  {
    "featureType": "road",
    "elementType": "labels",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "$road" }]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "$outline" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{ "color": "$road" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{ "color": "$land" }, { "weight": 1 }]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "road.arterial",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "road.local",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "$land" }]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "administrative.land_parcel",
    "stylers": [{ "visibility": "off" }]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{ "color": "$land" }]
  },
  {
    "featureType": "transit",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "$outline" }]
  }
]
''';
}

String getCloudMapStyle(BuildContext context, bool isDarkMode) {
  final palette = _mapPalette(context, isDarkMode);

  return jsonEncode({
    'monochrome': true,
    'variant': isDarkMode ? 'dark' : 'light',
    'backgroundColor': palette.land,
    'styles': [
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
          'textFillColor': palette.outline,
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
  });
}
