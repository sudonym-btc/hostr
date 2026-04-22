import 'dart:math' as math;

import 'package:models/main.dart';

class BlossomImageVariantHint {
  final int? maxBytes;
  final int? maxWidth;
  final int? maxHeight;
  final bool allowOriginalFallback;

  const BlossomImageVariantHint({
    this.maxBytes,
    this.maxWidth,
    this.maxHeight,
    this.allowOriginalFallback = false,
  });

  static const none = BlossomImageVariantHint();
  static const listingPreview = BlossomImageVariantHint(maxBytes: 200 * 1024);

  bool get hasConstraints =>
      maxBytes != null || maxWidth != null || maxHeight != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlossomImageVariantHint &&
          other.maxBytes == maxBytes &&
          other.maxWidth == maxWidth &&
          other.maxHeight == maxHeight &&
          other.allowOriginalFallback == allowOriginalFallback;

  @override
  int get hashCode =>
      Object.hash(maxBytes, maxWidth, maxHeight, allowOriginalFallback);
}

class BlossomImageCandidate {
  final String ref;
  final IMeta? meta;
  final bool isOriginal;

  const BlossomImageCandidate({
    required this.ref,
    this.meta,
    this.isOriginal = false,
  });
}

class BlossomImageVariantResolver {
  const BlossomImageVariantResolver._();

  static BlossomImageCandidate resolve({
    required String imageRef,
    Iterable<IMeta> imageMetas = const [],
    BlossomImageVariantHint hint = BlossomImageVariantHint.none,
  }) {
    final ref = imageRef.trim();
    if (ref.isEmpty) return BlossomImageCandidate(ref: ref);

    final metas = imageMetas.where((meta) => meta.url.isNotEmpty).toList();
    final matched = _matchingMetas(ref, metas);
    if (matched.isEmpty) return BlossomImageCandidate(ref: ref);

    final candidates = matched
        .map((meta) => BlossomImageCandidate(ref: meta.url, meta: meta))
        .toList();

    final selected = _selectBest(candidates, hint);
    if (selected != null) return selected;

    if (hint.allowOriginalFallback) {
      String? original;
      for (final meta in matched) {
        final hash = meta.originalSha256;
        if (hash != null && hash.isNotEmpty) {
          original = hash;
          break;
        }
      }
      if (original != null) {
        return BlossomImageCandidate(
          ref: original,
          meta: matched.first,
          isOriginal: true,
        );
      }
    }

    return candidates.first;
  }

  static List<IMeta> _matchingMetas(String imageRef, List<IMeta> metas) {
    final directMatches = metas.where((meta) => _matches(imageRef, meta));
    final direct = directMatches.toList();
    if (direct.isEmpty) return const [];

    final originalHashes = direct
        .map((meta) => meta.originalSha256)
        .whereType<String>()
        .where((hash) => hash.isNotEmpty)
        .toSet();

    if (originalHashes.isEmpty) return direct;

    return metas
        .where((meta) => originalHashes.contains(meta.originalSha256))
        .toList();
  }

  static bool _matches(String imageRef, IMeta meta) =>
      imageRef == meta.url ||
      imageRef == meta.sha256 ||
      imageRef == meta.originalSha256;

  static BlossomImageCandidate? _selectBest(
    List<BlossomImageCandidate> candidates,
    BlossomImageVariantHint hint,
  ) {
    if (candidates.isEmpty) return null;
    if (!hint.hasConstraints) return candidates.first;

    candidates.sort((a, b) => _score(a, hint).compareTo(_score(b, hint)));
    return candidates.first;
  }

  static _CandidateScore _score(
    BlossomImageCandidate candidate,
    BlossomImageVariantHint hint,
  ) {
    final meta = candidate.meta;
    final dimensions = _parseDimensions(meta?.dimensions);
    final size = meta?.size;

    final byteViolation = switch ((hint.maxBytes, size)) {
      (final maxBytes?, final size?) => math.max(0, size - maxBytes),
      (final maxBytes?, null) => maxBytes + 1,
      _ => 0,
    };

    final widthViolation = switch ((hint.maxWidth, dimensions?.width)) {
      (final maxWidth?, final width?) => math.max(0, width - maxWidth),
      (final maxWidth?, null) => maxWidth + 1,
      _ => 0,
    };

    final heightViolation = switch ((hint.maxHeight, dimensions?.height)) {
      (final maxHeight?, final height?) => math.max(0, height - maxHeight),
      (final maxHeight?, null) => maxHeight + 1,
      _ => 0,
    };

    final totalViolation = byteViolation + widthViolation + heightViolation;
    final fits = totalViolation == 0;
    final quality = _quality(meta, dimensions, hint);

    return _CandidateScore(
      fits: fits,
      totalViolation: totalViolation,
      quality: fits ? -quality : quality,
    );
  }

  static int _quality(
    IMeta? meta,
    _ImageDimensions? dimensions,
    BlossomImageVariantHint hint,
  ) {
    if (hint.maxBytes != null) return meta?.size ?? 0;
    return dimensions?.area ?? meta?.size ?? 0;
  }

  static _ImageDimensions? _parseDimensions(String? dimensions) {
    if (dimensions == null || dimensions.isEmpty) return null;
    final parts = dimensions.toLowerCase().split('x');
    if (parts.length != 2) return null;

    final width = int.tryParse(parts[0]);
    final height = int.tryParse(parts[1]);
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }

    return _ImageDimensions(width, height);
  }
}

class _CandidateScore implements Comparable<_CandidateScore> {
  final bool fits;
  final int totalViolation;
  final int quality;

  const _CandidateScore({
    required this.fits,
    required this.totalViolation,
    required this.quality,
  });

  @override
  int compareTo(_CandidateScore other) {
    if (fits != other.fits) return fits ? -1 : 1;
    final violation = totalViolation.compareTo(other.totalViolation);
    if (violation != 0) return violation;
    return quality.compareTo(other.quality);
  }
}

class _ImageDimensions {
  final int width;
  final int height;

  const _ImageDimensions(this.width, this.height);

  int get area => width * height;
}
