import 'dart:io';
import 'dart:isolate';

import 'package:h3_dart/h3_dart.dart';
import 'package:models/util/main.dart';

class H3Engine {
  final H3Hierarchy hierarchy;
  final H3PolygonCover polygonCover;
  H3Engine(H3 h3)
      : hierarchy = H3Hierarchy(h3),
        polygonCover = H3PolygonCover(h3);

  factory H3Engine.bundled() {
    final envPath = Platform.environment['HOSTR_H3_LIBRARY'];
    if (envPath != null && envPath.trim().isNotEmpty) {
      return H3Engine(H3Factory().byPath(envPath.trim()));
    }

    return H3Engine(H3Factory().byPath(_resolveBundledLibraryPath()));
  }

  static String _resolveBundledLibraryPath() {
    final packageUri = Isolate.resolvePackageUriSync(
      Uri.parse('package:models/main.dart'),
    );
    if (packageUri == null) {
      throw StateError(
          'Unable to resolve package:models root for H3 binaries.');
    }

    final libDir = File.fromUri(packageUri).parent.path;
    final packageRoot = Directory(libDir).parent.path;

    if (Platform.isMacOS) {
      return '$packageRoot/native/macos/libh3.dylib';
    }
    if (Platform.isLinux) {
      return '$packageRoot/native/linux/libh3.so';
    }
    if (Platform.isWindows) {
      return '$packageRoot/native/windows/h3.dll';
    }

    throw UnsupportedError(
        'No bundled H3 binary configured for this platform.');
  }
}
