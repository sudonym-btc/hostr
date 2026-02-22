import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/amount/amount_input.dart';
import 'package:hostr/presentation/component/widgets/search/listing_map.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

double mapsGoogleLogoSize = 0;

class SearchMapWidget extends StatefulWidget {
  final CustomLogger logger = CustomLogger();

  /// Called with the listing id when a price marker is tapped.
  final ValueChanged<String>? onMarkerTap;

  SearchMapWidget({super.key, this.onMarkerTap});

  @override
  State<StatefulWidget> createState() {
    return _SearchMapWidgetState();
  }
}

class _SearchMapWidgetState extends State<SearchMapWidget> {
  List<ListingMarkerData> _markerData = [];
  StreamSubscription<ListCubitState<Listing>>? _listSubscription;

  @override
  void initState() {
    super.initState();

    // Listen for list cubit updates and convert to marker data.
    final cubit = BlocProvider.of<ListCubit<Listing>>(context);
    _updateMarkerData(cubit.state);

    _listSubscription = cubit.stream
        .debounceTime(const Duration(milliseconds: 1000))
        .listen(_updateMarkerData);
  }

  void _updateMarkerData(ListCubitState<Listing> state) {
    final data = <ListingMarkerData>[];
    for (final item in state.results) {
      final h3Tag = item.tags
          .where((tag) => tag.isNotEmpty && tag.first == 'g')
          .map((tag) => tag.length > 1 ? tag[1] : '')
          .where((value) => value.isNotEmpty)
          .firstOrNull;

      if (h3Tag == null) continue;

      final priceText = item.parsedContent.price.isNotEmpty
          ? formatAmount(item.parsedContent.price.first.amount, exact: false)
          : null;

      data.add(
        ListingMarkerData(id: item.id, h3Tag: h3Tag, priceText: priceText),
      );
    }
    if (mounted) setState(() => _markerData = data);
  }

  @override
  void dispose() {
    _listSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListingMap(
          listings: _markerData,
          onMarkerTap: widget.onMarkerTap,
          showArrows: false,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: mapsGoogleLogoSize,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                stops: [0.75, 1.0],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Theme.of(context).scaffoldBackgroundColor,
                  Theme.of(context).scaffoldBackgroundColor.withAlpha(0),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
