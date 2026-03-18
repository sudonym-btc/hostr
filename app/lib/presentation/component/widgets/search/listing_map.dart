import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/search/listing_map_controller.dart';
import 'package:hostr/presentation/component/widgets/search/map_style.dart';
import 'package:hostr/presentation/component/widgets/search/price_marker.dart';
import 'package:models/main.dart';

export 'listing_map_controller.dart';

/// A reusable Google Map that displays price-pill markers for listings.
///
/// Pass a [ListingMapController] to imperatively manage selection, viewport,
/// and marker data. If omitted, an internal controller is created and seeded
/// from [initialListings].
class ListingMap extends StatefulWidget {
  /// Optional external controller.
  final ListingMapController? controller;

  /// Initial listings used only when [controller] is omitted.
  final List<ListingMarkerData> initialListings;

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

  /// Zoom used when only one marker is visible.
  final double singleMarkerZoom;

  /// Whether nearby markers should be grouped into cluster markers.
  final bool enableClustering;

  // ── Pill (individual marker) styling ────────────────────────────
  final Color? pillBackgroundColor;
  final Color? pillBorderColor;
  final double? pillBorderWidth;
  final Color? pillColor;

  // ── Cluster marker styling ─────────────────────────────────────
  final Color? clusterBackgroundColor;
  final Color? clusterBorderColor;
  final double? clusterBorderWidth;
  final Color? clusterColor;

  // ── Focused / highlighted marker styling ───────────────────────
  final Color? focusedBackgroundColor;
  final Color? focusedBorderColor;
  final double? focusedBorderWidth;
  final Color? focusedColor;

  // ── Disabled marker styling ────────────────────────────────────
  final Color? disabledBackgroundColor;
  final Color? disabledBorderColor;
  final double? disabledBorderWidth;
  final Color? disabledColor;

  // ── Text builders ──────────────────────────────────────────────
  /// Builds the label for a single (non-clustered) marker.
  /// Receives the [ListingMarkerData] item. Defaults to [priceText].
  final String Function(ListingMarkerData item)? pillTextBuilder;

  /// Builds the label for a clustered marker.
  /// Receives the list of [ListingMarkerData] items in the cluster.
  /// Defaults to the cluster member count.
  final String Function(List<ListingMarkerData> items)? clusterTextBuilder;

  const ListingMap({
    super.key,
    this.controller,
    this.initialListings = const [],
    this.onMarkerTap,
    this.interactive = true,
    this.showArrows = true,
    this.initialCamera,
    this.fitBoundsPadding = 120,
    this.autoFitBounds = true,
    this.singleMarkerZoom = 13,
    this.enableClustering = true,
    this.pillBackgroundColor,
    this.pillBorderColor,
    this.pillBorderWidth,
    this.pillColor,
    this.clusterBackgroundColor,
    this.clusterBorderColor,
    this.clusterBorderWidth,
    this.clusterColor,
    this.focusedBackgroundColor,
    this.focusedBorderColor,
    this.focusedBorderWidth,
    this.focusedColor,
    this.disabledBackgroundColor,
    this.disabledBorderColor,
    this.disabledBorderWidth,
    this.disabledColor,
    this.pillTextBuilder,
    this.clusterTextBuilder,
  });

  @override
  State<ListingMap> createState() => _ListingMapState();
}

class _ListingMapState extends State<ListingMap> with WidgetsBindingObserver {
  static const _kMercatorLatitudeLimit = 85.05112878;
  static const _kLongitudeRestrictionEpsilon = 0.000001;
  static const _kResizeViewportDebounce = Duration(milliseconds: 150);

  final Completer<GoogleMapController> _googleMapController = Completer();
  final Map<String, Marker> _markers = {};
  final Map<String, _MarkerMeta> _markerMeta = {};
  final Map<String, String> _groupIdByListingId = {};

  late final ListingMapController _internalController;

  bool _mapReady = false;
  bool _isClampingCamera = false;
  int _syncGeneration = 0;
  int _cameraOperationGeneration = 0;
  int _handledMarkersRevision = -1;
  int _handledViewportRevision = -1;
  bool _didRunInitialDependencySync = false;
  bool _hasScheduledPostFrameViewportIntent = false;

  /// Currently highlighted rendered marker id (accent colour).
  String? _focusedMarkerId;

  /// Cached resolved listings so we can re-cluster on zoom without
  /// re-resolving every H3 tag.
  List<_ResolvedListingMarker> _resolvedListings = [];

  /// Last zoom level used to cluster, so we can detect meaningful changes.
  double? _lastClusterZoom;

  Size? _lastViewportSize;

  /// Debounce timer for camera-idle re-clusters.
  Timer? _cameraIdleDebounce;

  Timer? _viewportResizeDebounce;

  ListingMapController get _listingMapController =>
      widget.controller ?? _internalController;

  // ── Map lifecycle ───────────────────────────────────────────────────

  void _onMapCreated(GoogleMapController controller) {
    if (_googleMapController.isCompleted || !mounted) return;

    _googleMapController.complete(controller);
    _mapReady = true;

    if (_listingMapController.selectedListingId == null &&
        _listingMapController.listings.isNotEmpty) {
      _listingMapController.focusAll();
    }

    unawaited(_syncMarkers(applyViewportIntent: true));
    _schedulePostFrameViewportIntent();
  }

  // ── Marker syncing ─────────────────────────────────────────────────

  @override
  void didUpdateWidget(covariant ListingMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    final oldController = oldWidget.controller ?? _internalController;
    final nextController = _listingMapController;

    if (oldController != nextController) {
      oldController.removeListener(_onControllerChanged);
      nextController.addListener(_onControllerChanged);
      _handledMarkersRevision = -1;
      _handledViewportRevision = -1;
      _focusedMarkerId = null;
      unawaited(_handleControllerChange());
      return;
    }

    if (widget.controller == null &&
        !listEquals(oldWidget.initialListings, widget.initialListings)) {
      _internalController.setListings(widget.initialListings);
      return;
    }

    unawaited(_syncMarkers(applyViewportIntent: _mapReady));
  }

  Future<void> _syncMarkers({required bool applyViewportIntent}) async {
    final h3 = getIt<H3Engine>();

    final resolvedListings = <_ResolvedListingMarker>[];
    for (final data in _listingMapController.listings) {
      final center = h3.polygonCover.centerForTag(data.h3Tag);
      if (center == null) continue;

      resolvedListings.add(
        _ResolvedListingMarker(
          id: data.id,
          position: LatLng(center.latitude, center.longitude),
          priceText: data.priceText ?? '?',
          enabled: data.enabled,
        ),
      );
    }

    _resolvedListings = resolvedListings;
    _lastClusterZoom = null;

    await _recluster(applyViewportIntent: applyViewportIntent);
  }

  /// Re-clusters the cached [_resolvedListings] using the current camera
  /// zoom level and rebuilds the marker set.
  Future<void> _recluster({required bool applyViewportIntent}) async {
    final generation = ++_syncGeneration;
    final theme = Theme.of(context);
    final dpr = MediaQuery.of(context).devicePixelRatio;

    final clusterThreshold = widget.enableClustering
        ? await _clusterThreshold()
        : 0.0;
    if (!mounted || generation != _syncGeneration) return;

    final groups = _buildMarkerGroups(_resolvedListings, clusterThreshold);
    final nextMarkers = <String, Marker>{};
    final nextMarkerMeta = <String, _MarkerMeta>{};
    final nextGroupIdByListingId = <String, String>{};

    for (final group in groups.values) {
      for (final listingId in group.memberIds) {
        nextGroupIdByListingId[listingId] = group.markerId;
      }
    }

    final selectedListingId = _listingMapController.selectedListingId;
    final desiredFocusedMarkerId = selectedListingId == null
        ? _focusedMarkerId
        : nextGroupIdByListingId[selectedListingId];

    // Build a lookup from listing id → original marker data so text
    // builders can access the full item.
    final dataById = <String, ListingMarkerData>{
      for (final d in _listingMapController.listings) d.id: d,
    };

    for (final group in groups.values) {
      final isFocused = group.markerId == desiredFocusedMarkerId;
      final isCluster = group.memberIds.length > 1;

      // ── Resolve colours ────────────────────────────────────────
      final Color fillColor;
      final Color textColor;
      final Color? borderColor;
      final double borderWidth;

      if (isFocused) {
        fillColor =
            widget.focusedBackgroundColor ??
            theme.colorScheme.surfaceContainerLowest;
        textColor = widget.focusedColor ?? theme.colorScheme.onSurface;
        borderColor = widget.focusedBorderColor;
        borderWidth = widget.focusedBorderWidth ?? 1;
      } else if (!group.enabled) {
        fillColor =
            widget.disabledBackgroundColor ??
            theme.colorScheme.surfaceContainerHighest;
        textColor = widget.disabledColor ?? theme.colorScheme.onSurfaceVariant;
        borderColor = widget.disabledBorderColor;
        borderWidth = widget.disabledBorderWidth ?? 1;
      } else if (isCluster) {
        fillColor =
            widget.clusterBackgroundColor ?? theme.colorScheme.surfaceContainer;
        textColor = widget.clusterColor ?? theme.colorScheme.onSurface;
        borderColor = widget.clusterBorderColor;
        borderWidth = widget.clusterBorderWidth ?? 1;
      } else {
        fillColor =
            widget.pillBackgroundColor ??
            theme.colorScheme.surfaceContainerHighest;
        textColor = widget.pillColor ?? theme.colorScheme.onSurface;
        borderColor = widget.pillBorderColor;
        borderWidth = widget.pillBorderWidth ?? 1;
      }

      // ── Resolve label text ─────────────────────────────────────
      final String label;
      if (isCluster && widget.clusterTextBuilder != null) {
        final items = group.memberIds
            .map((id) => dataById[id])
            .whereType<ListingMarkerData>()
            .toList();
        label = widget.clusterTextBuilder!(items);
      } else if (!isCluster && widget.pillTextBuilder != null) {
        final item = dataById[group.memberIds.first];
        label = item != null ? widget.pillTextBuilder!(item) : group.label;
      } else {
        label = group.label;
      }

      final icon = await PriceMarkerBuilder.build(
        priceText: label,
        fillColor: fillColor,
        textColor: textColor,
        borderColor: borderColor,
        textStyle: theme.textTheme.bodySmall,
        showArrow: widget.showArrows,
        isCluster: isCluster,
        devicePixelRatio: dpr,
        borderWidth: borderWidth,
      );

      if (!mounted || generation != _syncGeneration) return;

      nextMarkerMeta[group.markerId] = _MarkerMeta(
        position: group.position,
        priceText: group.label,
        enabled: group.enabled,
        memberIds: group.memberIds,
        isCluster: isCluster,
      );
      nextMarkers[group.markerId] = Marker(
        markerId: MarkerId(group.markerId),
        position: group.position,
        icon: icon,
        zIndexInt: isFocused ? 1 : 0,
        anchor: Offset(0.5, widget.showArrows ? 1.0 : 0.5),
        consumeTapEvents: true,
        onTap: () => unawaited(_handleMarkerTap(group.markerId)),
      );
    }

    if (!mounted || generation != _syncGeneration) return;

    setState(() {
      // Retain stale marker entries with a no-op onTap so that the
      // google_maps_flutter platform channel can still resolve their IDs
      // if a tap fires between the JS-side and Dart-side cleanup.
      // Only markers that were *visible* (i.e. real) get this treatment;
      // entries that were already invisible from a prior cycle are dropped
      // so stale markers don't accumulate indefinitely.
      final staleIds = _markers.keys
          .where((id) => !nextMarkers.containsKey(id))
          .toList();
      for (final id in staleIds) {
        final stale = _markers[id];
        if (stale != null && stale.visible) {
          nextMarkers[id] = stale.copyWith(
            visibleParam: false,
            onTapParam: () {},
          );
        }
      }

      _markers
        ..clear()
        ..addAll(nextMarkers);
      _markerMeta
        ..clear()
        ..addAll(nextMarkerMeta);
      _groupIdByListingId
        ..clear()
        ..addAll(nextGroupIdByListingId);
      _focusedMarkerId =
          desiredFocusedMarkerId != null &&
              nextMarkerMeta.containsKey(desiredFocusedMarkerId)
          ? desiredFocusedMarkerId
          : null;
    });

    if (applyViewportIntent && generation == _syncGeneration) {
      await _applyViewportIntent();
      _schedulePostFrameViewportIntent();
    }
  }

  // ── Clustering helpers ─────────────────────────────────────────────

  /// Computes the grouping threshold in degrees based on the *actual*
  /// visible region of the camera so that markers whose pills would
  /// overlap on screen get collapsed.
  Future<double> _clusterThreshold() async {
    if (_resolvedListings.length < 2) return 0;

    final renderBox = context.findRenderObject() as RenderBox?;
    final viewport = renderBox?.size ?? MediaQuery.sizeOf(context);

    double latSpan;
    double lngSpan;

    // Prefer the actual visible region from the live camera.
    if (_mapReady && _googleMapController.isCompleted) {
      final controller = await _googleMapController.future;
      final visibleRegion = await controller.getVisibleRegion();
      latSpan =
          (visibleRegion.northeast.latitude - visibleRegion.southwest.latitude)
              .abs();
      lngSpan =
          (visibleRegion.northeast.longitude -
                  visibleRegion.southwest.longitude)
              .abs();
    } else {
      // Fallback: estimate from the bounding box of all markers + padding.
      double minLat = double.infinity, maxLat = double.negativeInfinity;
      double minLng = double.infinity, maxLng = double.negativeInfinity;
      for (final l in _resolvedListings) {
        final lat = l.position.latitude;
        final lng = l.position.longitude;
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lng < minLng) minLng = lng;
        if (lng > maxLng) maxLng = lng;
      }
      latSpan = maxLat - minLat;
      lngSpan = maxLng - minLng;
    }

    final degPerPxLat = latSpan / max(viewport.height, 1.0);
    final degPerPxLng = lngSpan / max(viewport.width, 1.0);

    // A price-pill marker is roughly 70 × 28 logical pixels.
    // Use half the pill dimensions so markers only cluster when they
    // actually overlap rather than when their bounding boxes are close.
    const pillW = 35.0;
    const pillH = 14.0;

    final thresholdLat = degPerPxLat * pillH;
    final thresholdLng = degPerPxLng * pillW;

    // Use the larger dimension; floor at 0.0002° (~22 m) so
    // same-building markers always cluster.
    return max(max(thresholdLat, thresholdLng), 0.0002);
  }

  /// Called by [onCameraIdle] — re-clusters if the zoom changed enough.
  Future<void> _onCameraIdle() async {
    if (!_mapReady || !_googleMapController.isCompleted) return;
    if (_resolvedListings.length < 2) return;

    final controller = await _googleMapController.future;
    final zoom = (await controller.getZoomLevel());

    // Only re-cluster when zoom moved by ≥ 0.5 stops (avoids thrashing
    // on tiny pan gestures that don't change overlap).
    if (_lastClusterZoom != null && (zoom - _lastClusterZoom!).abs() < 0.5) {
      return;
    }
    _lastClusterZoom = zoom;
    await _recluster(applyViewportIntent: false);
  }

  void _onCameraIdleDebounced() {
    _cameraIdleDebounce?.cancel();
    _cameraIdleDebounce = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_onCameraIdle()),
    );
  }

  void _onCameraMove(CameraPosition position) {
    final clampedLatitude = _clampCenterLatitudeForViewport(
      position.target.latitude,
      position.zoom,
    );
    if ((clampedLatitude - position.target.latitude).abs() < 0.000001) return;
    unawaited(_clampVerticalCameraPosition(position, clampedLatitude));
  }

  Size _viewportSize() {
    final viewportSize = _lastViewportSize;
    if (viewportSize != null &&
        viewportSize.width.isFinite &&
        viewportSize.height.isFinite &&
        viewportSize.width > 0 &&
        viewportSize.height > 0) {
      return viewportSize;
    }

    return MediaQuery.sizeOf(context);
  }

  double _minimumZoomForViewport() {
    final viewportHeight = _viewportSize().height;
    if (viewportHeight <= 0) return 1.0;

    final requiredZoom = log(viewportHeight / 256) / ln2;
    return max(2.0, requiredZoom);
  }

  double _latitudeToWorldY(double latitude) {
    final sinValue = sin(latitude * pi / 180).clamp(-0.9999, 0.9999);
    return 0.5 - log((1 + sinValue) / (1 - sinValue)) / (4 * pi);
  }

  double _worldYToLatitude(double worldY) {
    final mercator = pi * (1 - (2 * worldY));
    final sinhMercator = (exp(mercator) - exp(-mercator)) / 2;
    return atan(sinhMercator) * 180 / pi;
  }

  double _clampCenterLatitudeForViewport(double latitude, double zoom) {
    final viewportHeight = _viewportSize().height;
    if (viewportHeight <= 0) {
      return latitude.clamp(-_kMercatorLatitudeLimit, _kMercatorLatitudeLimit);
    }

    final effectiveZoom = max(zoom, _minimumZoomForViewport());
    final worldHeight = 256 * pow(2, effectiveZoom).toDouble();
    final halfViewportWorld = min(viewportHeight / 2, worldHeight / 2);

    final minCenterWorldY = halfViewportWorld / worldHeight;
    final maxCenterWorldY = 1 - minCenterWorldY;
    final worldY = _latitudeToWorldY(
      latitude,
    ).clamp(minCenterWorldY, maxCenterWorldY);

    return _worldYToLatitude(worldY);
  }

  Future<void> _clampVerticalCameraPosition(
    CameraPosition position,
    double clampedLatitude,
  ) async {
    if (_isClampingCamera || !_mapReady || !_googleMapController.isCompleted) {
      return;
    }

    _isClampingCamera = true;
    try {
      final controller = await _googleMapController.future;
      if (!mounted) return;

      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(clampedLatitude, position.target.longitude),
            zoom: position.zoom,
            tilt: position.tilt,
            bearing: position.bearing,
          ),
        ),
      );
    } finally {
      _isClampingCamera = false;
    }
  }

  /// Greedy nearest-neighbour clustering: each incoming marker joins the
  /// closest existing group within [threshold] degrees, or starts a new one.
  Map<String, _MarkerGroup> _buildMarkerGroups(
    List<_ResolvedListingMarker> listings,
    double threshold,
  ) {
    final thresholdSq = threshold * threshold;
    final groups = <_MarkerGroup>[];

    for (final listing in listings) {
      int? matchIdx;
      double bestDistSq = thresholdSq;

      for (int i = 0; i < groups.length; i++) {
        final dlat = groups[i].position.latitude - listing.position.latitude;
        final dlng = groups[i].position.longitude - listing.position.longitude;
        final distSq = dlat * dlat + dlng * dlng;
        if (distSq < bestDistSq) {
          bestDistSq = distSq;
          matchIdx = i;
        }
      }

      if (matchIdx != null) {
        groups[matchIdx] = groups[matchIdx].add(listing);
      } else {
        groups.add(
          _MarkerGroup.fromListing(
            markerId: _markerGroupIdForPosition(listing.position),
            listing: listing,
          ),
        );
      }
    }

    return {for (final g in groups) g.markerId: g};
  }

  String _markerGroupIdForPosition(LatLng position) {
    // Keep full precision so the id is stable for the exact anchor listing.
    return 'group:${position.latitude}:${position.longitude}';
  }

  // ── Camera helpers ─────────────────────────────────────────────────

  Future<void> _fitBounds({required int operationId}) async {
    final positions = _viewportTargetPositions();
    if (positions.isEmpty || _isStaleCameraOperation(operationId)) return;

    final controller = await _googleMapController.future;
    if (_isStaleCameraOperation(operationId)) return;

    if (positions.length == 1) {
      final target = positions.first;
      await controller.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: widget.singleMarkerZoom),
        ),
      );
      return;
    }

    final bounds = _calculateBounds(positions);
    await controller.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, widget.fitBoundsPadding),
    );
  }

  List<LatLng> _viewportTargetPositions() {
    if (_resolvedListings.isNotEmpty) {
      return _resolvedListings.map((listing) => listing.position).toList();
    }

    return _markers.values.map((marker) => marker.position).toList();
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions
        .map((p) => p.latitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLat = positions
        .map((p) => p.latitude)
        .reduce((a, b) => a > b ? a : b);
    double minLng = positions
        .map((p) => p.longitude)
        .reduce((a, b) => a < b ? a : b);
    double maxLng = positions
        .map((p) => p.longitude)
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
    _internalController = ListingMapController(
      initialListings: widget.initialListings,
    );
    _listingMapController.addListener(_onControllerChanged);
    _handledMarkersRevision = _listingMapController.markersRevision;
    _handledViewportRevision = _listingMapController.viewportRevision;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRunInitialDependencySync) return;

    _didRunInitialDependencySync = true;
    unawaited(_syncMarkers(applyViewportIntent: false));
  }

  @override
  void dispose() {
    _cameraIdleDebounce?.cancel();
    _viewportResizeDebounce?.cancel();
    _listingMapController.removeListener(_onControllerChanged);
    if (widget.controller == null) {
      _internalController.dispose();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onControllerChanged() {
    unawaited(_handleControllerChange());
  }

  Future<void> _handleControllerChange() async {
    final controller = _listingMapController;
    final markersChanged =
        _handledMarkersRevision != controller.markersRevision;
    final viewportChanged =
        _handledViewportRevision != controller.viewportRevision;

    _handledMarkersRevision = controller.markersRevision;
    _handledViewportRevision = controller.viewportRevision;

    if (markersChanged) {
      await _syncMarkers(
        applyViewportIntent: widget.autoFitBounds || _mapReady,
      );
      return;
    }

    if (viewportChanged) {
      await _applyViewportIntent();
    }
  }

  Future<void> _applyViewportIntent() async {
    if (!_mapReady || !_googleMapController.isCompleted || !mounted) return;

    final operationId = ++_cameraOperationGeneration;
    final viewportMode = _listingMapController.viewportMode;
    final selectedListingId = _listingMapController.selectedListingId;

    switch (viewportMode) {
      case ListingMapViewportMode.focusAll:
        await _focusAll(operationId);
        return;
      case ListingMapViewportMode.selected:
        if (selectedListingId == null) {
          await _focusAll(operationId);
          return;
        }
        await _focusListing(selectedListingId, operationId);
        return;
      case ListingMapViewportMode.idle:
        return;
    }
  }

  void _schedulePostFrameViewportIntent() {
    if (_hasScheduledPostFrameViewportIntent || !mounted) return;

    _hasScheduledPostFrameViewportIntent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hasScheduledPostFrameViewportIntent = false;
      if (!mounted) return;
      unawaited(_applyViewportIntent());
    });
  }

  bool _isStaleCameraOperation(int operationId) {
    return !mounted || operationId != _cameraOperationGeneration;
  }

  Future<void> _focusAll(int operationId) async {
    if (_markers.isEmpty) return;

    await _clearFocus();
    if (_isStaleCameraOperation(operationId)) return;

    await _fitBounds(operationId: operationId);
  }

  Future<void> _focusListing(String listingId, int operationId) async {
    final markerId = _groupIdByListingId[listingId];
    if (markerId == null) return;

    final marker = _markers[markerId];
    if (marker == null) return;

    await _updateFocus(markerId);
    if (_isStaleCameraOperation(operationId)) return;

    final controller = await _googleMapController.future;
    if (_isStaleCameraOperation(operationId)) return;

    await controller.animateCamera(CameraUpdate.newLatLng(marker.position));
  }

  Future<void> _clearFocus() async {
    final oldId = _focusedMarkerId;
    _focusedMarkerId = null;

    if (oldId != null && _markers.containsKey(oldId)) {
      await _rebuildMarkerIcon(oldId);
    }
  }

  Future<void> _refocusForResize() async {
    if (!_mapReady || !_googleMapController.isCompleted || !mounted) return;

    final selectedListingId = _listingMapController.selectedListingId;
    final operationId = ++_cameraOperationGeneration;

    if (selectedListingId != null) {
      await _focusListing(selectedListingId, operationId);
      return;
    }

    await _focusAll(operationId);
  }

  void _scheduleResizeViewportRefresh(Size size) {
    if (!size.width.isFinite || !size.height.isFinite) return;
    if (size.width <= 0 || size.height <= 0) return;
    if (_lastViewportSize == size) return;

    _lastViewportSize = size;
    _viewportResizeDebounce?.cancel();
    _viewportResizeDebounce = Timer(
      _kResizeViewportDebounce,
      () => unawaited(_refocusForResize()),
    );
  }

  /// Rebuilds a single marker icon using the same colour / label
  /// resolution as [_recluster] so style params and text builders apply.
  Future<void> _rebuildMarkerIcon(String id, {bool isFocused = false}) async {
    final meta = _markerMeta[id];
    final existing = _markers[id];
    if (meta == null || existing == null || !mounted) return;

    final dpr = MediaQuery.of(context).devicePixelRatio;
    final theme = Theme.of(context);

    // ── Resolve colours (mirrors _recluster) ─────────────────
    final Color fillColor;
    final Color textColor;
    final Color? borderColor;
    final double borderWidth;

    if (isFocused) {
      fillColor =
          widget.focusedBackgroundColor ??
          theme.colorScheme.surfaceContainerLowest;
      textColor = widget.focusedColor ?? theme.colorScheme.onSurface;
      borderColor = widget.focusedBorderColor;
      borderWidth = widget.focusedBorderWidth ?? 1;
    } else if (!meta.enabled) {
      fillColor =
          widget.disabledBackgroundColor ??
          theme.colorScheme.surfaceContainerHighest;
      textColor = widget.disabledColor ?? theme.colorScheme.onSurfaceVariant;
      borderColor = widget.disabledBorderColor;
      borderWidth = widget.disabledBorderWidth ?? 1;
    } else if (meta.isCluster) {
      fillColor =
          widget.clusterBackgroundColor ?? theme.colorScheme.surfaceContainer;
      textColor = widget.clusterColor ?? theme.colorScheme.onSurface;
      borderColor = widget.clusterBorderColor;
      borderWidth = widget.clusterBorderWidth ?? 1;
    } else {
      fillColor =
          widget.pillBackgroundColor ??
          theme.colorScheme.surfaceContainerHighest;
      textColor = widget.pillColor ?? theme.colorScheme.onSurface;
      borderColor = widget.pillBorderColor;
      borderWidth = widget.pillBorderWidth ?? 1;
    }

    // ── Resolve label (mirrors _recluster) ───────────────────
    final dataById = <String, ListingMarkerData>{
      for (final d in _listingMapController.listings) d.id: d,
    };

    final String label;
    if (meta.isCluster && widget.clusterTextBuilder != null) {
      final items = meta.memberIds
          .map((mid) => dataById[mid])
          .whereType<ListingMarkerData>()
          .toList();
      label = widget.clusterTextBuilder!(items);
    } else if (!meta.isCluster && widget.pillTextBuilder != null) {
      final item = dataById[meta.memberIds.first];
      label = item != null ? widget.pillTextBuilder!(item) : meta.priceText;
    } else {
      label = meta.priceText;
    }

    final icon = await PriceMarkerBuilder.build(
      priceText: label,
      fillColor: fillColor,
      textColor: textColor,
      borderColor: borderColor,
      textStyle: theme.textTheme.bodySmall,
      showArrow: widget.showArrows,
      isCluster: meta.isCluster,
      devicePixelRatio: dpr,
      borderWidth: borderWidth,
    );

    if (!mounted) return;

    // Re-validate after the async gap: a concurrent _recluster may have
    // removed this marker from _markerMeta.  Inserting a visible marker
    // without a meta entry would silently swallow future taps on it.
    if (_markerMeta[id] == null) return;

    setState(() {
      _markers[id] = Marker(
        markerId: MarkerId(id),
        position: meta.position,
        icon: icon,
        zIndexInt: isFocused ? 1 : 0,
        anchor: Offset(0.5, widget.showArrows ? 1.0 : 0.5),
        consumeTapEvents: true,
        onTap: () => unawaited(_handleMarkerTap(id)),
      );
    });
  }

  Future<void> _handleMarkerTap(String markerId) async {
    final meta = _markerMeta[markerId];
    if (meta == null) return;

    if (meta.memberIds.length == 1) {
      final listingId = meta.memberIds.single;
      _listingMapController.select(listingId);
      widget.onMarkerTap?.call(listingId);
      return;
    }

    _listingMapController.deselect();
    await _updateFocus(markerId);
  }

  /// Switches the focused marker: restores the old one to its default
  /// style, highlights the new one with the focused style.
  Future<void> _updateFocus(String newId) async {
    if (newId == _focusedMarkerId) return;

    final oldId = _focusedMarkerId;
    _focusedMarkerId = newId;

    // Restore previous focused marker to its default style.
    if (oldId != null && _markers.containsKey(oldId)) {
      await _rebuildMarkerIcon(oldId);
    }

    // Highlight the new focused marker.
    if (_markers.containsKey(newId)) {
      await _rebuildMarkerIcon(newId, isFocused: true);
    }
  }

  @override
  void didChangePlatformBrightness() {
    PriceMarkerBuilder.clearCache();
    if (_mapReady) {
      unawaited(_syncMarkers(applyViewportIntent: true));
      return;
    }
    setState(() {});
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultCamera = CameraPosition(target: LatLng(0, 0), zoom: 1);
    final cameraTargetBounds = kIsWeb
        ? CameraTargetBounds(
            LatLngBounds(
              southwest: const LatLng(
                -_kMercatorLatitudeLimit,
                -180 + _kLongitudeRestrictionEpsilon,
              ),
              northeast: const LatLng(
                _kMercatorLatitudeLimit,
                180 - _kLongitudeRestrictionEpsilon,
              ),
            ),
          )
        : CameraTargetBounds.unbounded;
    return LayoutBuilder(
      builder: (context, constraints) {
        final nextViewportSize = constraints.biggest;
        if (nextViewportSize.width.isFinite &&
            nextViewportSize.height.isFinite &&
            nextViewportSize.width > 0 &&
            nextViewportSize.height > 0) {
          _lastViewportSize = nextViewportSize;
        }
        _scheduleResizeViewportRefresh(constraints.biggest);
        return GoogleMap(
          style: getMapStyle(context, isDarkMode),
          onMapCreated: _onMapCreated,
          onCameraMove: widget.interactive && kIsWeb ? _onCameraMove : null,
          onCameraIdle: widget.interactive && widget.enableClustering
              ? _onCameraIdleDebounced
              : null,
          initialCameraPosition: widget.initialCamera ?? defaultCamera,
          markers: _markers.values.toSet(),
          mapToolbarEnabled: false,
          zoomControlsEnabled: false,
          webCameraControlEnabled: false,
          cameraTargetBounds: cameraTargetBounds,
          minMaxZoomPreference: kIsWeb
              ? MinMaxZoomPreference(_minimumZoomForViewport(), 17)
              : MinMaxZoomPreference.unbounded,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          mapType: MapType.normal,
          scrollGesturesEnabled: widget.interactive,
          zoomGesturesEnabled: widget.interactive,
          tiltGesturesEnabled: widget.interactive,
          rotateGesturesEnabled: widget.interactive,
        );
      },
    );
  }
}

/// Lightweight data kept per marker so we can rebuild its icon
/// when focus changes without re-resolving H3 tags.
class _MarkerMeta {
  final LatLng position;
  final String priceText;
  final bool enabled;
  final List<String> memberIds;
  final bool isCluster;

  const _MarkerMeta({
    required this.position,
    required this.priceText,
    required this.enabled,
    required this.memberIds,
    this.isCluster = false,
  });
}

class _ResolvedListingMarker {
  final String id;
  final LatLng position;
  final String priceText;
  final bool enabled;

  const _ResolvedListingMarker({
    required this.id,
    required this.position,
    required this.priceText,
    required this.enabled,
  });
}

class _MarkerGroup {
  final String markerId;
  final LatLng position;
  final List<String> memberIds;
  final String label;
  final bool enabled;

  const _MarkerGroup({
    required this.markerId,
    required this.position,
    required this.memberIds,
    required this.label,
    required this.enabled,
  });

  factory _MarkerGroup.fromListing({
    required String markerId,
    required _ResolvedListingMarker listing,
  }) {
    return _MarkerGroup(
      markerId: markerId,
      position: listing.position,
      memberIds: [listing.id],
      label: listing.priceText,
      enabled: listing.enabled,
    );
  }

  _MarkerGroup add(_ResolvedListingMarker listing) {
    final nextMemberIds = [...memberIds, listing.id];
    return _MarkerGroup(
      markerId: markerId,
      position: position,
      memberIds: nextMemberIds,
      label: '${nextMemberIds.length} results',
      enabled: enabled || listing.enabled,
    );
  }
}
