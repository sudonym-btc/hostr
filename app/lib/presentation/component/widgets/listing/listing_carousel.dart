import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';
import 'package:models/main.dart';

class ListingCarousel extends StatelessWidget {
  final Listing listing;

  const ListingCarousel({required this.listing, super.key});
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : null;

        return CarouselSlider(
          options: CarouselOptions(
            viewportFraction: 1,
            padEnds: false,
            enableInfiniteScroll: false,
            height: height,
          ),
          items: listing.parsedContent.images.map((i) {
            return SizedBox.expand(
              child: BlossomImage(
                image: i,
                pubkey: listing.pubKey,
                fit: BoxFit.cover,
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
