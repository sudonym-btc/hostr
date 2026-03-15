import 'package:h3_dart/h3_dart.dart';
import 'package:models/util/main.dart';

import 'h3_library_path_stub.dart'
    if (dart.library.io) 'h3_library_path_io.dart';

enum H3BackendKind { override, process, platformDefault, bundled }

class H3BackendSelection {
  const H3BackendSelection({
    required this.kind,
    required this.source,
    required this.implementationType,
    this.libraryPath,
  });

  final H3BackendKind kind;
  final String source;
  final String implementationType;
  final String? libraryPath;

  String describe() {
    final buffer = StringBuffer('$source [$implementationType]');
    if (libraryPath != null) {
      buffer.write(' path=$libraryPath');
    }
    return buffer.toString();
  }
}

H3 Function()? _h3FactoryOverride;
String? _h3FactoryOverrideLabel;
H3BackendSelection? _lastH3BackendSelection;

void setH3FactoryOverride(H3 Function()? overrideFactory, {String? label}) {
  _h3FactoryOverride = overrideFactory;
  _h3FactoryOverrideLabel = label;
  _lastH3BackendSelection = null;
}

H3BackendSelection? getH3BackendSelection() => _lastH3BackendSelection;

String describeH3BackendSelection() {
  final selection = _lastH3BackendSelection;
  if (selection != null) {
    return selection.describe();
  }

  final overrideLabel = _h3FactoryOverrideLabel;
  if (overrideLabel != null) {
    return 'pending override: $overrideLabel';
  }

  return 'pending automatic selection';
}

H3 createOptimalH3() {
  final overrideFactory = _h3FactoryOverride;
  if (overrideFactory != null) {
    final h3 = overrideFactory();
    _lastH3BackendSelection = H3BackendSelection(
      kind: H3BackendKind.override,
      source: _h3FactoryOverrideLabel ?? 'override',
      implementationType: h3.runtimeType.toString(),
    );
    return h3;
  }

  if (shouldUseProcessH3Library()) {
    final h3 = H3Factory().process();
    _lastH3BackendSelection = H3BackendSelection(
      kind: H3BackendKind.process,
      source: 'h3_dart process()',
      implementationType: h3.runtimeType.toString(),
    );
    return h3;
  }

  final platformDefaultPath = resolvePlatformDefaultH3LibraryPath();
  if (platformDefaultPath != null) {
    try {
      final h3 = H3Factory().byPath(platformDefaultPath);
      _lastH3BackendSelection = H3BackendSelection(
        kind: H3BackendKind.platformDefault,
        source: 'h3_dart byPath(platform default)',
        implementationType: h3.runtimeType.toString(),
        libraryPath: platformDefaultPath,
      );
      return h3;
    } catch (_) {
      // Platform default path failed (for example bare `libh3.so` on Linux
      // CI). Fall through to bundled binary resolution below.
    }
  }

  final bundledPath = resolveBundledH3LibraryPath();
  final h3 = H3Factory().byPath(bundledPath);
  _lastH3BackendSelection = H3BackendSelection(
    kind: H3BackendKind.bundled,
    source: 'h3_dart byPath(bundled)',
    implementationType: h3.runtimeType.toString(),
    libraryPath: bundledPath,
  );
  return h3;
}

class H3Engine {
  final H3Hierarchy hierarchy;
  final H3PolygonCover polygonCover;
  H3Engine(H3 h3)
      : hierarchy = H3Hierarchy(h3),
        polygonCover = H3PolygonCover(h3);

  factory H3Engine.bundled() => H3Engine(createOptimalH3());
}
