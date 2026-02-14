import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:models/main.dart';

Color getColorForAmenity(BuildContext context, String amenity) {
  return Theme.of(context).colorScheme.primary.withAlpha(40);
  // final random = Random(amenity.hashCode);
  // return Color.fromARGB(
  //   25,
  //   random.nextInt(256),
  //   random.nextInt(256),
  //   random.nextInt(256),
  // );
}

OutlinedBorder getShapeForAmenity(BuildContext context, String amenity) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(50.0), // Makes the chip perfectly round
    side: BorderSide(
      color: getColorForAmenity(context, amenity), // Sets the border color
      width: 1.0,
    ),
  );
}

class AmenityTagsWidget extends StatelessWidget {
  final Amenities amenities;

  const AmenityTagsWidget({super.key, required this.amenities});

  @override
  Widget build(BuildContext context) {
    final amenitiesMap = amenities.toMap();
    final amenityKeys = amenitiesMap.keys
        .where((key) => amenitiesMap[key] == true)
        .toList();

    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: amenityKeys.map((amenity) {
        return Chip(
          label: Text(convertToTitleCase(amenity)),
          shape: getShapeForAmenity(context, amenity),
          backgroundColor: getColorForAmenity(
            context,
            amenity,
          ), // Makes the background transparent
        );
      }).toList(),
    );
  }
}
