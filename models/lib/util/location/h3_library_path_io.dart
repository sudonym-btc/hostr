import 'dart:io';
import 'dart:isolate';

import 'cpu_arch.dart';
import 'cpu_arch_stub.dart' if (dart.library.ffi) 'cpu_arch_ffi.dart';

bool shouldUseProcessH3Library() {
  // iOS app runtime exposes H3 symbols via the process image.
  // On macOS CLI/test runtimes this is often not true, so use explicit paths.
  return Platform.isIOS;
}

String? resolvePlatformDefaultH3LibraryPath() {
  if (Platform.isAndroid || Platform.isLinux) {
    return 'libh3.so';
  }
  if (Platform.isMacOS && !_supportsPackageUriResolution()) {
    // Some Flutter runtimes (for example widgetbook on macOS) do not support
    // Isolate.resolvePackageUriSync. Try resolving an absolute repository path
    // first, then fall back to default dynamic loader search paths.
    return _resolveMacOsLibraryPathFromWorkspace() ?? 'libh3.dylib';
  }
  if (Platform.isWindows) {
    return 'h3.dll';
  }
  return null;
}

String? _resolveMacOsLibraryPathFromWorkspace() {
  final arch = currentCpuArch();
  final cwd = Directory.current.path;

  final relativeRoots = <String>['.', '..', '../..', '../../..'];
  final archRelative = arch == CpuArch.x64
      ? 'models/native/macos/x86_64/libh3.dylib'
      : 'models/native/macos/arm64/libh3.dylib';

  for (final root in relativeRoots) {
    final archPath = File('$cwd/$root/$archRelative').absolute.path;
    if (File(archPath).existsSync()) {
      return archPath;
    }

    final genericPath =
        File('$cwd/$root/models/native/macos/libh3.dylib').absolute.path;
    if (File(genericPath).existsSync()) {
      return genericPath;
    }
  }

  return null;
}

bool _supportsPackageUriResolution() {
  try {
    Isolate.resolvePackageUriSync(Uri.parse('package:models/main.dart'));
    return true;
  } on UnsupportedError {
    return false;
  }
}

String resolveBundledH3LibraryPath() {
  Uri? packageUri;
  try {
    packageUri = Isolate.resolvePackageUriSync(
      Uri.parse('package:models/main.dart'),
    );
  } on UnsupportedError {
    throw UnsupportedError(
      'Isolate.resolvePackageUriSync is unavailable in this runtime. '
      'Use process/default platform loading for H3.',
    );
  }
  if (packageUri == null) {
    throw StateError('Unable to resolve package:models root for H3 binaries.');
  }

  final libDir = File.fromUri(packageUri).parent.path;
  final packageRoot = Directory(libDir).parent.path;
  final arch = currentCpuArch();

  if (Platform.isMacOS) {
    return _firstExistingPath([
      if (arch == CpuArch.arm64) '$packageRoot/native/macos/arm64/libh3.dylib',
      if (arch == CpuArch.x64) '$packageRoot/native/macos/x86_64/libh3.dylib',
      '$packageRoot/native/macos/libh3.dylib',
    ]);
  }
  if (Platform.isLinux) {
    return _firstExistingPath([
      if (arch == CpuArch.arm64) '$packageRoot/native/linux/arm64/libh3.so',
      if (arch == CpuArch.x64) '$packageRoot/native/linux/x86_64/libh3.so',
      '$packageRoot/native/linux/libh3.so',
    ]);
  }
  if (Platform.isWindows) {
    return _firstExistingPath([
      if (arch == CpuArch.x64) '$packageRoot/native/windows/x86_64/h3.dll',
      '$packageRoot/native/windows/h3.dll',
    ]);
  }

  throw UnsupportedError('No bundled H3 binary configured for this platform.');
}

String _firstExistingPath(List<String> candidates) {
  for (final path in candidates) {
    if (File(path).existsSync()) return path;
  }
  return candidates.last;
}
