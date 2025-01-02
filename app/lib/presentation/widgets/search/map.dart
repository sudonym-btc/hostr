import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';

class SearchMap extends StatefulWidget {
  final CustomLogger logger = CustomLogger();
  final CustomSearchController searchController;

  SearchMap({super.key, required this.searchController});

  @override
  State<StatefulWidget> createState() {
    return _SearchMapState();
  }
}

class _SearchMapState extends State<SearchMap>
    with AutomaticKeepAliveClientMixin {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    widget.logger.i("Init state");
    widget.searchController.stream.listen((state) {
      widget.logger.i("New state $state");
      for (var loc in state.listState.data) {
        widget.logger.i("New state data ");

        getIt<GoogleMaps>().getCoordinatesFromAddress(loc.location).then((res) {
          _addMarker(LatLng(res!.latitude, res.longitude));
        });
      }
    });
  }

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 1,
  );

  void _addMarker(LatLng position) {
    final marker = Marker(
        flat: true,
        markerId: MarkerId(position.toString()),
        position: position,
        icon:
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet));
    setState(() {
      _markers.add(marker);
    });
    _moveCameraToFitAllMarkers();
  }

  Future<void> _moveCameraToFitAllMarkers() async {
    widget.logger.i("Moving camera to fit all markers");
    final GoogleMapController controller = await _controller.future;
    widget.logger.i("Controller ready ${_markers.length} $controller");

    if (_markers.isEmpty) return;

    LatLngBounds bounds;
    if (_markers.length == 1) {
      bounds = LatLngBounds(
        southwest: _markers.first.position,
        northeast: _markers.first.position,
      );
    } else {
      double minLat = _markers
          .map((e) => e.position.latitude)
          .reduce((a, b) => a < b ? a : b);
      double maxLat = _markers
          .map((e) => e.position.latitude)
          .reduce((a, b) => a > b ? a : b);
      double minLng = _markers
          .map((e) => e.position.longitude)
          .reduce((a, b) => a < b ? a : b);
      double maxLng = _markers
          .map((e) => e.position.longitude)
          .reduce((a, b) => a > b ? a : b);

      widget.logger.i(
          "Calculated bounds: minLat=$minLat, minLng=$minLng, maxLat=$maxLat, maxLng=$maxLng");

      bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );
    }
    if (bounds.southwest == bounds.northeast) {
      widget.logger.i(
          "Only one marker or all markers have the same position, moving camera to single point");
      CameraUpdate cameraUpdate =
          CameraUpdate.newLatLngZoom(bounds.southwest, 10);
      controller.animateCamera(cameraUpdate).then((_) {
        widget.logger.i("Camera moved successfully to single point");
      }).catchError((error) {
        widget.logger.e("Error moving camera: $error");
      });
    } else {
      widget.logger
          .i("Moving camera to fit all markers within bounds: $bounds");
      CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, 50);
      controller.moveCamera(cameraUpdate).then((_) {
        widget.logger.i("Camera moved successfully to fit all markers");
      }).catchError((error) {
        widget.logger.e("Error moving camera: $error");
      });
    }
  }

  @override
  void dispose() {
    _controller.future.then((controller) {
      controller.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Get the theme colors
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final backgroundColor = theme.scaffoldBackgroundColor;

    // Create the map style object
    final mapStyle = [
      {
        "elementType": "geometry",
        "stylers": [
          {"color": "#f5f5f5"}
        ]
      },
      {
        "elementType": "labels.icon",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#616161"}
        ]
      },
      {
        "elementType": "labels.text.stroke",
        "stylers": [
          {"color": "#f5f5f5"}
        ]
      },
      {
        "featureType": "administrative.land_parcel",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#bdbdbd"}
        ]
      },
      {
        "featureType": "poi",
        "elementType": "geometry",
        "stylers": [
          {"color": "#eeeeee"}
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#757575"}
        ]
      },
      {
        "featureType": "poi.business",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
          {"color": "#e5e5e5"}
        ]
      },
      {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#9e9e9e"}
        ]
      },
      {
        "featureType": "road",
        "elementType": "geometry",
        "stylers": [
          {"color": "#ffffff"}
        ]
      },
      {
        "featureType": "road",
        "elementType": "labels.icon",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "road.arterial",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "road.arterial",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#757575"}
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
          {"color": "#dadada"}
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "road.highway",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#616161"}
        ]
      },
      {
        "featureType": "road.local",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#9e9e9e"}
        ]
      },
      {
        "featureType": "transit",
        "stylers": [
          {"visibility": "off"}
        ]
      },
      {
        "featureType": "transit.line",
        "elementType": "geometry",
        "stylers": [
          {"color": "#e5e5e5"}
        ]
      },
      {
        "featureType": "transit.station",
        "elementType": "geometry",
        "stylers": [
          {"color": "#eeeeee"}
        ]
      },
      {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
          {"color": "#c9c9c9"}
        ]
      },
      {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
          {"color": "#9e9e9e"}
        ]
      }
    ];

    return GoogleMap(
      style: JsonEncoder().convert(mapStyle),
      onMapCreated: (GoogleMapController controller) {
        if (_controller.isCompleted) return;
        _controller.complete(controller);
      },
      initialCameraPosition: _kGooglePlex,
      markers: _markers,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
