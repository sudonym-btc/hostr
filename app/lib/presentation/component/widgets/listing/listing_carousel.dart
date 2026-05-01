import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/data/sources/blossom_image_variant.dart';
import 'package:hostr/presentation/component/widgets/ui/app_carousel.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';
import 'package:models/main.dart';

class ListingCarousel extends StatefulWidget {
  final Listing listing;
  final BlossomImageVariantHint variantHint;
  final bool showArrows;

  const ListingCarousel({
    required this.listing,
    this.variantHint = BlossomImageVariantHint.none,
    this.showArrows = false,
    super.key,
  });

  @override
  State<ListingCarousel> createState() => _ListingCarouselState();
}

class _ListingCarouselState extends State<ListingCarousel> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _currentIndex = 0;

  void _goTo(int index) {
    _controller.animateToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : null;
        final canGoLeft = _currentIndex > 0;
        final canGoRight = _currentIndex < widget.listing.images.length - 1;

        return Stack(
          children: [
            CarouselSlider(
              carouselController: _controller,
              options: CarouselOptions(
                viewportFraction: 1,
                padEnds: false,
                enableInfiniteScroll: false,
                height: height,
                onPageChanged: (index, reason) {
                  if (_currentIndex == index) return;
                  setState(() => _currentIndex = index);
                },
              ),
              items: widget.listing.images.map((image) {
                return SizedBox.expand(
                  child: BlossomImage(
                    image: image,
                    pubkey: widget.listing.pubKey,
                    imageMetas: widget.listing.imageMetas,
                    variantHint: widget.variantHint,
                    fit: BoxFit.cover,
                  ),
                );
              }).toList(),
            ),
            if (widget.showArrows &&
                widget.listing.images.length > 1 &&
                canGoLeft)
              Positioned(
                left: kSpace2,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AppCarouselIconButton(
                    icon: Icons.chevron_left,
                    tooltip: 'Previous image',
                    onPressed: () => _goTo(_currentIndex - 1),
                  ),
                ),
              ),
            if (widget.showArrows &&
                widget.listing.images.length > 1 &&
                canGoRight)
              Positioned(
                right: kSpace2,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AppCarouselIconButton(
                    icon: Icons.chevron_right,
                    tooltip: 'Next image',
                    onPressed: () => _goTo(_currentIndex + 1),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class SmallListingCarousel extends StatelessWidget {
  final Listing listing;
  final double width;
  final double height;
  final BlossomImageVariantHint variantHint;

  const SmallListingCarousel({
    required this.listing,
    this.width = double.infinity,
    this.height = 100,
    this.variantHint = BlossomImageVariantHint.none,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ClipRRect(
        borderRadius: AppBorderRadii.sm,
        child: ListingCarousel(listing: listing, variantHint: variantHint),
      ),
    );
  }
}
