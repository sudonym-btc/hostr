import 'package:flutter/material.dart';
import 'package:hostr/presentation/widgets/main.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class SearchResultsWidget extends StatelessWidget {
  const SearchResultsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final totalHeight = constraints.maxHeight;
      final listingStartHeight = totalHeight / 2;

      return SlidingUpPanel(
          parallaxEnabled: true,
          color: Theme.of(context).scaffoldBackgroundColor,
          panel: Column(
            children: [
              Container(
                height: 30,
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Listings(),
              ),
            ],
          ),
          minHeight: totalHeight - listingStartHeight,
          maxHeight: MediaQuery.of(context).size.height,
          body: Column(children: [
            Container(
                height: totalHeight - listingStartHeight + mapsGoogleLogoSize,
                child: SearchMap()),
          ]));
    }));
  }
}
