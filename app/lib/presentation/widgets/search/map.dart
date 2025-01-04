import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:rxdart/rxdart.dart';

import 'map_style.dart';

double mapsGoogleLogoSize = 28;

class SearchMap extends StatefulWidget {
  final CustomLogger logger = CustomLogger();
  final CustomSearchController searchController;

  SearchMap({super.key, required this.searchController});

  @override
  State<StatefulWidget> createState() {
    return _SearchMapState();
  }
}

class _SearchMapState extends State<SearchMap> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final Set<Marker> _markers = {};
  final BehaviorSubject<bool> _mapReadySubject =
      BehaviorSubject<bool>.seeded(false);
  final ReplaySubject<LatLng> _markerStream = ReplaySubject<LatLng>();

  _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted) {
      _controller.complete(controller);
      _mapReadySubject.add(true);
      widget.logger.d("Map created");
    }
  }

  @override
  void initState() {
    super.initState();

    // Combine map readiness with marker stream
    _mapReadySubject
        .where((isReady) => isReady) // Only emit when the map is ready
        .flatMap((_) => _markerStream) // Forward all incoming markers
        .listen((position) {
      widget.logger.d("New marker", error: position);
      _addMarker(position);
    });

    widget.logger.i("Init state");
    widget.searchController.stream.listen((state) {
      widget.logger.i("New state $state");
      for (var loc in state.listState.data) {
        widget.logger.i("New state data ");

        getIt<GoogleMaps>().getCoordinatesFromAddress(loc.location).then((res) {
          _markerStream.add(LatLng(res!.latitude, res.longitude));
        });
      }
    });
  }

  void _addMarker(LatLng position) {
    setState(() {
      _markers.add(Marker(
        markerId: MarkerId(position.toString()),
        position: position,
      ));
    });
    _moveCameraToFitAllMarkers();
  }

  _calculateBounds() {
    double minLat = _markers
        .map((p) => p.position.latitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLat = _markers
        .map((p) => p.position.latitude)
        .reduce((a, b) => a > b ? a : b);
    double minLng = _markers
        .map((p) => p.position.longitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLng = _markers
        .map((p) => p.position.longitude)
        .reduce((a, b) => a > b ? a : b);
    widget.logger.i(
        "Calculated bounds: minLat=$minLat, minLng=$minLng, maxLat=$maxLat, maxLng=$maxLng");
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  _moveCameraToFitAllMarkers() async {
    if (_markers.isEmpty) return;

    LatLngBounds bounds = _calculateBounds();

    final GoogleMapController controller = await _controller.future;
    CameraUpdate u2 = CameraUpdate.newLatLngBounds(bounds, 0);

    // Find the bounding box center
    LatLng center = LatLng(
      (bounds.southwest.latitude + bounds.northeast.latitude) / 2,
      (bounds.southwest.longitude + bounds.northeast.longitude) / 2,
    );

    // Approximate zoom calculation
    double latDelta =
        (bounds.northeast.latitude - bounds.southwest.latitude).abs();
    double lngDelta =
        (bounds.northeast.longitude - bounds.southwest.longitude).abs();
    double largestDelta = max(latDelta, lngDelta);

    // Basic formula: adjust 16 to taste
    double calculatedZoom = 16 - (log(largestDelta) / log(2));
    double finalZoom = calculatedZoom.clamp(15, 50); // Keep zoom in valid range

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    await controller.animateCamera(CameraUpdate.zoomTo(finalZoom));

    // Adjust zoom level
    // double zoomLevel = await controller.getZoomLevel();
    // widget.logger.i("Current zoom level: $zoomLevel");
    // controller.animateCamera(CameraUpdate.zoomTo(zoomLevel));
  }

  @override
  void dispose() {
    _mapReadySubject.close();
    _markerStream.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      AnimatedOpacity(
          // If the widget is visible, animate to 0.0 (invisible).
          // If the widget is hidden, animate to 1.0 (fully visible).
          opacity: _controller.isCompleted ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 1000),
          child: GoogleMap(
            style: getMapStyle(context),
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(37.42796133580664, -122.085749655962),
              zoom: 14.4746,
            ),
            markers: _markers,
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
              stops: [1, 1.0], // More solid for 80%, quickly fades at the top

              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.white,
                Colors.white.withAlpha(0),
              ],
            ),
          ),
        ),
      )
    ]);
  }
}
