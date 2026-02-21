import 'package:h3_dart/h3_dart.dart';
import 'package:models/util/main.dart';

import 'h3_library_path_stub.dart'
    if (dart.library.io) 'h3_library_path_io.dart';

class H3Engine {
  final H3Hierarchy hierarchy;
  final H3PolygonCover polygonCover;
  H3Engine(H3 h3)
      : hierarchy = H3Hierarchy(h3),
        polygonCover = H3PolygonCover(h3);

  factory H3Engine.bundled() {
    if (shouldUseProcessH3Library()) {
      return H3Engine(H3Factory().process());
    }

    final platformDefaultPath = resolvePlatformDefaultH3LibraryPath();
    if (platformDefaultPath != null) {
      return H3Engine(H3Factory().byPath(platformDefaultPath));
    }

    return H3Engine(H3Factory().byPath(resolveBundledH3LibraryPath()));
  }
}
