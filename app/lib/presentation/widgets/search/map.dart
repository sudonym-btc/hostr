import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/widgets/search/map_style.dart';
import 'package:rxdart/rxdart.dart';

double mapsGoogleLogoSize = 2;

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

    // Add padding by expanding bounds by 10%
    double latPadding = (maxLat - minLat) * 0.1 + 0.1;
    double lngPadding = (maxLng - minLng) * 0.1 + 0.1;

    widget.logger.d("latPadding $latPadding");
    widget.logger.d("lngPadding $lngPadding");

    return LatLngBounds(
      northeast: LatLng(maxLat + latPadding, maxLng + lngPadding),
      southwest: LatLng(minLat - latPadding, minLng - lngPadding),
    );
  }

  _moveCameraToFitAllMarkers() async {
    if (_markers.isEmpty) return;

    LatLngBounds bounds = _calculateBounds();

    final GoogleMapController controller = await _controller.future;

    await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
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
            zoomControlsEnabled: false,
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
