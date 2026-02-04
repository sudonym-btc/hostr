import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';
import 'package:models/main.dart';

class ListingCarousel extends StatelessWidget {
  final Listing listing;

  const ListingCarousel({required this.listing, super.key});
  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(viewportFraction: 1, padEnds: false),
      items: listing.parsedContent.images.map((i) {
        return Builder(
          builder: (BuildContext context) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: BlossomImage(
                image: i,
                pubkey: listing.pubKey,
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(
                  context,
                ).size.height, // Match the height of the SizedBox
                fit: BoxFit.cover,
                alignment: Alignment.topLeft,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
