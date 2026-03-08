import 'package:flutter/material.dart';

String _colorToHex(Color color) {
  final r = (color.r * 255).round().toRadixString(16).padLeft(2, '0');
  final g = (color.g * 255).round().toRadixString(16).padLeft(2, '0');
  final b = (color.b * 255).round().toRadixString(16).padLeft(2, '0');
  return '#$r$g$b';
}

String getMapStyle(BuildContext context, bool isDarkMode) {
  final cs = Theme.of(context).colorScheme;
  final water = _colorToHex(cs.surfaceContainerLowest);
  final land = _colorToHex(cs.surfaceContainerHighest);
  final road = _colorToHex(cs.surfaceContainerHigh);
  final park = _colorToHex(cs.surfaceContainerLow);
  final labelFill = _colorToHex(cs.onSurfaceVariant);
  final labelStroke = _colorToHex(cs.surface);
  final outline = _colorToHex(cs.outlineVariant);

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
    "stylers": [{ "color": "$land" }, { "weight": 0.2 }]
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
    "stylers": [{ "color": "$outline" }, { "weight": 1.2 }]
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
