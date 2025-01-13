import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/search/map_style.dart';
import 'package:rxdart/rxdart.dart';

double mapsGoogleLogoSize = 0;

class SearchMapWidget extends StatefulWidget {
  final CustomLogger logger = CustomLogger();

  SearchMapWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SearchMapWidgetState();
  }
}

class _SearchMapWidgetState extends State<SearchMapWidget> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final Map<String, Marker> _markers = {};
  final BehaviorSubject<bool> _mapReadySubject =
      BehaviorSubject<bool>.seeded(false);
  final Set<String> _fetchedIds = {}; // Set to keep track of fetched IDs

  _onMapCreated(GoogleMapController controller) {
    widget.logger.i("Map created");
    if (!_controller.isCompleted) {
      widget.logger.i("Map completed");
      _controller.complete(controller);
      _mapReadySubject.add(true);
    }
  }

  @override
  void initState() {
    super.initState();

    widget.logger.i("Init state");
    _mapReadySubject

        /// Only emit when the map is ready
        .where((isReady) => isReady)

        /// Start listening to the list results
        .flatMap((_) => BlocProvider.of<ListCubit<Listing>>(context).stream)

        /// Debounce to avoid too many updates
        .debounceTime(Duration(milliseconds: 500))
        .listen((state) async {
      widget.logger.i("New state $state");

      // Add markers for new locations
      for (var item in state.results) {
        if (!_fetchedIds.contains(item.id)) {
          _fetchedIds.add(item.id!);
          var res = await getIt<GoogleMaps>()
              .getCoordinatesFromAddress(item.parsedContent.location);

          if (res != null) {
            setState(() {
              _markers[item.id!] =
                  Marker(markerId: MarkerId(item.id!), position: res);
            });
          }
        }
      }

      // Collect markers to be removed
      final markersToRemove = _markers.values.where((marker) {
        final shouldRemove =
            !state.results.any((loc) => loc.id == marker.markerId.value);
        if (shouldRemove) {
          setState(() {
            _fetchedIds.remove(marker.markerId.value);
            _markers.remove(marker.markerId.value);
          });
        }
        return shouldRemove;
      }).toList();

      _moveCameraToFitAllMarkers();
    });
  }

  _calculateBounds() {
    double minLat = _markers.values
        .map((p) => p.position.latitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLat = _markers.values
        .map((p) => p.position.latitude)
        .reduce((a, b) => a > b ? a : b);
    double minLng = _markers.values
        .map((p) => p.position.longitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLng = _markers.values
        .map((p) => p.position.longitude)
        .reduce((a, b) => a > b ? a : b);
    widget.logger.i(
        "Calculated bounds: minLat=$minLat, minLng=$minLng, maxLat=$maxLat, maxLng=$maxLng");

    // Add padding by expanding bounds by 10%
    double latPadding = 0; //(maxLat - minLat) * 0.1 + 0.1;
    double lngPadding = 0; //(maxLng - minLng) * 0.1 + 0.1;

    widget.logger.d("latPadding $latPadding");
    widget.logger.d("lngPadding $lngPadding");

    return LatLngBounds(
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
    );
  }

  _moveCameraToFitAllMarkers() async {
    widget.logger.i('Move camera to fit all markers ${_markers.length}');
    if (_markers.isEmpty) return;

    LatLngBounds bounds = _calculateBounds();

    final GoogleMapController controller = await _controller.future;
    // Calculate padding for each side
    double leftPadding = 50.0; // Adjust this value as needed
    double rightPadding = 50.0; // Adjust this value as needed
    double bottomPadding = 50.0; // Adjust this value as needed

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 120));
  }

  @override
  void dispose() {
    _mapReadySubject.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AnimatedOpacity(
          // If the widget is visible, animate to 0.0 (invisible).
          // If the widget is hidden, animate to 1.0 (fully visible).
          opacity: _controller.isCompleted ? 1.0 : 1,
          duration: const Duration(milliseconds: 1000),
          child: GoogleMap(
            style: getMapStyle(context),
            onMapCreated: _onMapCreated,
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: LatLng(37.42796133580664, -122.085749655962),
              zoom: 14.4746,
            ),
            markers: _markers.values.toSet(),
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          )),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        height: mapsGoogleLogoSize,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              stops: [
                0.75,
                1.0
              ], // More solid for 80%, quickly fades at the top

              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Theme.of(context).scaffoldBackgroundColor,
                Theme.of(context).scaffoldBackgroundColor.withAlpha(0),
              ],
            ),
          ),
        ),
      )
    ]);
  }
}
