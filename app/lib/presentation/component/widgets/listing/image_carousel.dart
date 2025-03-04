import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';

class ImageCarouselWidget extends StatefulWidget {
  final Listing item;

  const ImageCarouselWidget({super.key, required this.item});

  @override
  State createState() => ImageCarouselWIdgetState();
}

class ImageCarouselWIdgetState extends State<ImageCarouselWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Preload images
      for (var imageUrl in widget.item.parsedContent.images) {
        precacheImage(NetworkImage(imageUrl), context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      options: CarouselOptions(
          viewportFraction: 1,
          padEnds: false,
          height: MediaQuery.of(context).size.height / 3),
      items: widget.item.parsedContent.images.map<Widget>((i) {
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
