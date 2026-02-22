import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Creates a custom map marker [BitmapDescriptor] displaying a price label
/// as a rounded pill with the app's primary colour.
///
/// The marker is rendered to an off-screen canvas and converted to an image,
/// since Google Maps Flutter only accepts [BitmapDescriptor] — not widgets.
class PriceMarkerBuilder {
  /// Cache of already-rendered markers keyed by their display text,
  /// so identical prices don't get repainted.
  static final Map<String, BitmapDescriptor> _cache = {};

  /// Creates a [BitmapDescriptor] showing [priceText] (e.g. "₿ 50K")
  /// on a pill-shaped background.
  ///
  /// Pass [textStyle] from the theme (e.g. `bodySmall`) to inherit the app's
  /// font family and size. [fillColor] is the pill background (primary),
  /// [textColor] is the label colour (onPrimary).
  ///
  /// Set [showArrow] to `false` for a plain round pill without the bottom
  /// pointer (useful for static / listing-page maps).
  ///
  /// Results are cached by [priceText] + colours so repeated calls are free.
  static Future<BitmapDescriptor> build({
    required String priceText,
    required Color fillColor,
    required Color textColor,
    TextStyle? textStyle,
    bool showArrow = true,
    double devicePixelRatio = 2.0,
    double borderWidth = 1.5,
  }) async {
    final cacheKey =
        '$priceText-${fillColor.value}-${textColor.value}-$showArrow-$borderWidth';
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final descriptor = await _render(
      priceText: priceText,
      fillColor: fillColor,
      textColor: textColor,
      textStyle: textStyle,
      showArrow: showArrow,
      devicePixelRatio: devicePixelRatio,
      borderWidth: borderWidth,
    );
    _cache[cacheKey] = descriptor;
    return descriptor;
  }

  /// Clears the cached markers (e.g. on theme change).
  static void clearCache() => _cache.clear();

  static Future<BitmapDescriptor> _render({
    required String priceText,
    required Color fillColor,
    required Color textColor,
    TextStyle? textStyle,
    required bool showArrow,
    required double devicePixelRatio,
    required double borderWidth,
  }) async {
    // Render at high resolution for crisp edges on all densities.
    final double renderScale = devicePixelRatio;

    // ── Resolve text style ────────────────────────────────────────────
    final baseFontSize = textStyle?.fontSize ?? 12.0;
    final fontFamily = textStyle?.fontFamily;

    // ── Measure text ──────────────────────────────────────────────────
    final textPainter = TextPainter(
      text: TextSpan(
        text: priceText,
        style: TextStyle(
          color: textColor,
          fontSize: baseFontSize * renderScale,
          fontWeight: FontWeight.bold,
          fontFamily: fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // ── Size the pill ─────────────────────────────────────────────────
    final scaledBorderWidth = borderWidth * renderScale;
    // The stroke is painted centered on the path, so half extends outward.
    final halfBorder = scaledBorderWidth / 2;
    final paddingH = 9.0 * renderScale;
    final paddingV = 5.5 * renderScale;
    final arrowHeight = showArrow ? 5.0 * renderScale : 0.0;
    final arrowHalfWidth = 5.0 * renderScale;
    final pillWidth = textPainter.width + paddingH * 2;
    final pillHeight = textPainter.height + paddingV * 2;
    // Expand the canvas by the full border width (half on each side).
    final totalWidth = pillWidth + scaledBorderWidth;
    final totalHeight = pillHeight + arrowHeight + scaledBorderWidth;
    final radius = pillHeight / 2;

    // ── Paint ─────────────────────────────────────────────────────────
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final fillPaint = Paint()
      ..color = fillColor
      ..isAntiAlias = true;

    // Offset the pill inward by halfBorder so the stroke stays within bounds.
    final pillPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(halfBorder, halfBorder, pillWidth, pillHeight),
          Radius.circular(radius),
        ),
      );

    // Optionally add a small arrow triangle below the pill.
    final Path shape;
    if (showArrow) {
      final cx = halfBorder + pillWidth / 2;
      final arrowTop = halfBorder + pillHeight - 1;
      final arrowBottom = halfBorder + pillHeight + arrowHeight;
      final arrowPath = Path()
        ..moveTo(cx - arrowHalfWidth, arrowTop)
        ..lineTo(cx, arrowBottom)
        ..lineTo(cx + arrowHalfWidth, arrowTop)
        ..close();
      shape = Path.combine(PathOperation.union, pillPath, arrowPath);
    } else {
      shape = pillPath;
    }

    canvas.drawPath(shape, fillPaint);

    // Border — round joins so the arrow tip stays clean.
    final borderPaint = Paint()
      ..color = textColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = scaledBorderWidth
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(shape, borderPaint);

    // Text — offset by halfBorder so it stays centered inside the pill.
    textPainter.paint(
      canvas,
      Offset(halfBorder + paddingH, halfBorder + paddingV),
    );

    // ── Convert to image bytes ────────────────────────────────────────
    final picture = recorder.endRecording();
    final image = await picture.toImage(totalWidth.ceil(), totalHeight.ceil());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final bytes = byteData!.buffer.asUint8List();

    // Display width in logical pixels — divide by DPR so the marker
    // appears at the intended small size on screen.
    final logicalWidth = totalWidth / renderScale;
    return BitmapDescriptor.bytes(bytes, width: logicalWidth);
  }
}
