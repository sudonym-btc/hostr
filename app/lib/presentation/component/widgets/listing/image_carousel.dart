import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';

class ImageCarouselWidget extends StatelessWidget {
  final Listing item;

  const ImageCarouselWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
          viewportFraction: 1,
          padEnds: false,
          height: MediaQuery.of(context).size.height / 3),
      items: item.parsedContent.images.map<Widget>((i) {
        return Builder(
          builder: (BuildContext context) {
            return Image.network(
              i,
              fit: BoxFit.cover,
              width: MediaQuery.of(context).size.width,
            );
          },
        );
      }).toList(),
    );
  }
}
