import 'dart:io';
import 'dart:isolate';

import 'package:h3_dart/h3_dart.dart';
import 'package:models/util/main.dart';

import 'cpu_arch_stub.dart' if (dart.library.ffi) 'cpu_arch_ffi.dart';

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
    final arch = currentCpuArch();

    if (Platform.isMacOS) {
      return _firstExistingPath([
        if (arch == CpuArch.arm64)
          '$packageRoot/native/macos/arm64/libh3.dylib',
        if (arch == CpuArch.x64)
          '$packageRoot/native/macos/x86_64/libh3.dylib',
        '$packageRoot/native/macos/libh3.dylib',
      ]);
    }
    if (Platform.isLinux) {
      return _firstExistingPath([
        if (arch == CpuArch.arm64)
          '$packageRoot/native/linux/arm64/libh3.so',
        if (arch == CpuArch.x64)
          '$packageRoot/native/linux/x86_64/libh3.so',
        '$packageRoot/native/linux/libh3.so',
      ]);
    }
    if (Platform.isWindows) {
      return _firstExistingPath([
        if (arch == CpuArch.x64)
          '$packageRoot/native/windows/x86_64/h3.dll',
        '$packageRoot/native/windows/h3.dll',
      ]);
    }

    throw UnsupportedError(
        'No bundled H3 binary configured for this platform.');
  }

  static String _firstExistingPath(List<String> candidates) {
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    return candidates.last;
  }
}
