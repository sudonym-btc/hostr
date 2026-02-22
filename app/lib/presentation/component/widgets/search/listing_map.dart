import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/search/map_style.dart';
import 'package:hostr/presentation/component/widgets/search/price_marker.dart';
import 'package:models/main.dart';

/// Data object describing a single marker to place on a [ListingMap].
///
/// [id] is used for marker identity and the [onMarkerTap] callback.
/// [h3Tag] is resolved to lat/lng via [H3Engine].
/// [priceText] is rendered on the pill label (pass `null` to skip).
/// [enabled] can be toggled in the future (e.g. availability) to switch
/// the marker to a disabled colour.
class ListingMarkerData {
  final String id;
  final String h3Tag;
  final String? priceText;
  final bool enabled;

  const ListingMarkerData({
    required this.id,
    required this.h3Tag,
    this.priceText,
    this.enabled = true,
  });
}

/// A reusable Google Map that displays price-pill markers for listings.
///
/// **Search page** — pass an updating [listings] list, leave [interactive]
/// true (the default), and provide [onMarkerTap] to scroll to the clicked
/// listing.
///
/// **Listing detail page** — pass a single-element [listings] list, set
/// [interactive] to `false` to lock zoom / scroll / tilt / rotate, and
/// optionally set [showArrows] to `false` for plain round pills.
class ListingMap extends StatefulWidget {
  /// Markers to render. The widget diffs against the previous list
  /// automatically.
  final List<ListingMarkerData> listings;

  /// Called with the listing [id] when a marker is tapped.
  final ValueChanged<String>? onMarkerTap;

  /// Whether zoom, scroll, tilt and rotate gestures are enabled.
  final bool interactive;

  /// Whether to render a downward-pointing arrow on each marker pill.
  final bool showArrows;

  /// Initial camera position. Falls back to (0, 0) zoom 1 when `null`.
  final CameraPosition? initialCamera;

  /// Padding applied when fitting all markers into view.
  final double fitBoundsPadding;

  /// Whether to auto-fit camera to marker bounds whenever markers change.
  final bool autoFitBounds;

  const ListingMap({
    super.key,
    required this.listings,
    this.onMarkerTap,
    this.interactive = true,
    this.showArrows = true,
    this.initialCamera,
    this.fitBoundsPadding = 120,
    this.autoFitBounds = true,
  });

  @override
  State<ListingMap> createState() => _ListingMapState();
}

class _ListingMapState extends State<ListingMap> with WidgetsBindingObserver {
  final Completer<GoogleMapController> _controller = Completer();
  final Map<String, Marker> _markers = {};
  bool _mapReady = false;

  // ── Map lifecycle ───────────────────────────────────────────────────

  void _onMapCreated(GoogleMapController controller) {
    if (!_controller.isCompleted && mounted) {
      _controller.complete(controller);
      _mapReady = true;
      _syncMarkers();
    }
  }

  // ── Marker syncing ─────────────────────────────────────────────────

  @override
  void didUpdateWidget(covariant ListingMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_mapReady) _syncMarkers();
  }

  Future<void> _syncMarkers() async {
    final theme = Theme.of(context);
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final h3 = getIt<H3Engine>();

    final incomingIds = widget.listings.map((l) => l.id).toSet();

    // Remove stale markers.
    final staleKeys = _markers.keys
        .where((id) => !incomingIds.contains(id))
        .toList();
    if (staleKeys.isNotEmpty) {
      setState(() {
        for (final key in staleKeys) {
          _markers.remove(key);
        }
      });
    }

    // Add / update new markers.
    for (final data in widget.listings) {
      if (_markers.containsKey(data.id)) continue;

      final center = h3.polygonCover.centerForTag(data.h3Tag);
      if (center == null) continue;

      final position = LatLng(center.latitude, center.longitude);

      final priceText = data.priceText ?? '?';
      final fillColor = data.enabled
          ? theme.colorScheme.primary
          : theme.colorScheme.surfaceContainerHighest;
      final textColor = data.enabled
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurfaceVariant;

      final icon = await PriceMarkerBuilder.build(
        priceText: priceText,
        fillColor: fillColor,
        textColor: textColor,
        textStyle: theme.textTheme.bodySmall,
        showArrow: widget.showArrows,
        devicePixelRatio: dpr,
      );

      if (!mounted) return;

      setState(() {
        _markers[data.id] = Marker(
          markerId: MarkerId(data.id),
          position: position,
          icon: icon,
          anchor: Offset(0.5, widget.showArrows ? 1.0 : 0.5),
          consumeTapEvents: true,
          onTap: () => widget.onMarkerTap?.call(data.id),
        );
      });
    }

    if (widget.autoFitBounds) {
      _fitBounds();
    }
  }

  // ── Camera helpers ─────────────────────────────────────────────────

  Future<void> _fitBounds() async {
    if (_markers.isEmpty) return;
    final bounds = _calculateBounds();
    final controller = await _controller.future;
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, widget.fitBoundsPadding),
    );
  }

  LatLngBounds _calculateBounds() {
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

    const double minPadding = 0.005;
    if ((maxLat - minLat).abs() < 1e-6 && (maxLng - minLng).abs() < 1e-6) {
      minLat -= minPadding;
      maxLat += minPadding;
      minLng -= minPadding;
      maxLng += minPadding;
    }

    return LatLngBounds(
      northeast: LatLng(maxLat, maxLng),
      southwest: LatLng(minLat, minLng),
    );
  }

  // ── Widget lifecycle ───────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangePlatformBrightness() {
    setState(() {});
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultCamera = CameraPosition(target: LatLng(0, 0), zoom: 1);

    return GoogleMap(
      style: getMapStyle(context, isDarkMode),
      onMapCreated: _onMapCreated,
      initialCameraPosition: widget.initialCamera ?? defaultCamera,
      markers: _markers.values.toSet(),
      // Controls
      zoomControlsEnabled: false,
      minMaxZoomPreference: const MinMaxZoomPreference(1, 17),
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      // Interactivity
      scrollGesturesEnabled: widget.interactive,
      zoomGesturesEnabled: widget.interactive,
      tiltGesturesEnabled: widget.interactive,
      rotateGesturesEnabled: widget.interactive,
    );
  }
}
