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

  /// Shared map controller.
  final ListingMapController controller;

  SearchMapWidget({super.key, required this.controller, this.onMarkerTap});

  @override
  State<StatefulWidget> createState() {
    return _SearchMapWidgetState();
  }
}

class _SearchMapWidgetState extends State<SearchMapWidget> {
  StreamSubscription<ListCubitState<Listing>>? _listSubscription;

  Widget _buildMapContent(BuildContext context) {
    return Stack(
      children: [
        ListingMap(
          controller: widget.controller,
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

  double _resolveEvenLogicalExtent(BuildContext context, double maxExtent) {
    if (!maxExtent.isFinite || maxExtent <= 0) {
      return maxExtent;
    }

    final dpr = MediaQuery.devicePixelRatioOf(context);
    final maxPhysicalExtent = (maxExtent * dpr).floor();
    if (maxPhysicalExtent <= 1) {
      return maxExtent;
    }

    final snappedPhysicalExtent = maxPhysicalExtent.isEven
        ? maxPhysicalExtent
        : maxPhysicalExtent - 1;

    return snappedPhysicalExtent / dpr;
  }

  @override
  void initState() {
    super.initState();

    // Listen for list cubit updates and convert to marker data.
    final cubit = BlocProvider.of<ListCubit<Listing>>(context);
    _updateMarkerData(cubit.state);

    _listSubscription = cubit.stream
        .debounceTime(const Duration(milliseconds: 50))
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

      final priceText = item.prices.isNotEmpty
          ? formatAmount(item.prices.first.amount, exact: false)
          : null;

      data.add(
        ListingMarkerData(id: item.id, h3Tag: h3Tag, priceText: priceText),
      );
    }
    widget.controller.setListings(data);
  }

  @override
  void dispose() {
    _listSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final snappedWidth = _resolveEvenLogicalExtent(
          context,
          constraints.maxWidth,
        );
        final snappedHeight = _resolveEvenLogicalExtent(
          context,
          constraints.maxHeight,
        );

        final widthChanged =
            snappedWidth.isFinite && snappedWidth < constraints.maxWidth;
        final heightChanged =
            snappedHeight.isFinite && snappedHeight < constraints.maxHeight;

        if (!widthChanged && !heightChanged) {
          return _buildMapContent(context);
        }

        return Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: widthChanged ? snappedWidth : null,
            height: heightChanged ? snappedHeight : null,
            child: _buildMapContent(context),
          ),
        );
      },
    );
  }
}
