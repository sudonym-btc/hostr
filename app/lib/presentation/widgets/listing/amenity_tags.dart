import 'dart:math';

import 'package:flutter/material.dart';
import 'package:hostr/main.dart';

class AmenityTags extends StatelessWidget {
  final Amenities amenities;

  const AmenityTags({
    Key? super.key,
    required this.amenities,
  });

  Color _getColorForAmenity(BuildContext context, String amenity) {
    return Theme.of(context).primaryColor.withAlpha(20);
    final random = Random(amenity.hashCode);
    return Color.fromARGB(
      25,
      random.nextInt(256),
      random.nextInt(256),
      random.nextInt(256),
    );
  }

  @override
  Widget build(BuildContext context) {
    final amenitiesMap = amenities.toMap();
    final amenityKeys =
        amenitiesMap.keys.where((key) => amenitiesMap[key] == true).toList();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: amenityKeys.map((amenity) {
        return Chip(
          label: Text(convertToTitleCase(amenity)),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(50.0), // Makes the chip perfectly round
            side: BorderSide(
              color: _getColorForAmenity(
                  context, amenity), // Sets the border color
              width: 1.0,
            ),
          ),
          backgroundColor: _getColorForAmenity(
              context, amenity), // Makes the background transparent
        );
      }).toList(),
    );
  }
}
