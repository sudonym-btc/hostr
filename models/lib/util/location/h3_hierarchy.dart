import 'package:h3_dart/h3_dart.dart';

import 'h3_tag.dart';

class H3Hierarchy {
  final H3 _h3;
  H3Hierarchy(this._h3);

  // final Logger _logger = Logger();
  int _maxH3Resolution = 15;

  List<String> hierarchyForPoint({
    required double latitude,
    required double longitude,
    int finestResolution = 15,
    int? maxTags,
  }) {
    return hierarchyForPointTags(
      latitude: latitude,
      longitude: longitude,
      finestResolution: finestResolution,
      maxTags: maxTags,
    ).map((tag) => tag.index).toList();
  }

  List<H3Tag> hierarchyForPointTags({
    required double latitude,
    required double longitude,
    int finestResolution = 15,
    int? maxTags,
  }) {
    final boundedResolution = finestResolution.clamp(0, _maxH3Resolution);
    final finest = _h3.geoToCell(
      GeoCoord(lat: latitude, lon: longitude),
      boundedResolution,
    );

    final tags = <H3Tag>[];
    final seen = <BigInt>{};
    for (var res = boundedResolution; res >= 0; res--) {
      final index =
          res == boundedResolution ? finest : _h3.cellToParent(finest, res);
      if (seen.add(index)) {
        tags.add(H3Tag(index: index.toString(), resolution: res));
        if (maxTags != null && tags.length >= maxTags) {
          break;
        }
      }
    }

    return tags;
  }
}
