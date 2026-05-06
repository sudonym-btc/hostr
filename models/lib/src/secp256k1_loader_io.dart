import 'dart:io';
import 'dart:isolate';

import '../util/location/cpu_arch.dart';
import '../util/location/cpu_arch_stub.dart'
    if (dart.library.ffi) '../util/location/cpu_arch_ffi.dart';

Future<void> prepareBundledSecp256k1BinaryIfNeeded() async {
  final expectedName = _platformLibraryFileName();
  if (expectedName == null) return;

  final buildDir = Directory('${Directory.current.path}/build');
  final targetFile = File('${buildDir.path}/$expectedName');
  if (targetFile.existsSync()) {
    return;
  }

  final bundledPath = _resolveBundledSecp256k1LibraryPath();
  if (bundledPath == null) {
    return;
  }

  if (!buildDir.existsSync()) {
    buildDir.createSync(recursive: true);
  }

  await File(bundledPath).copy(targetFile.path);
}

String? _platformLibraryFileName() {
  if (Platform.isMacOS) return 'libsecp256k1.dylib';
  if (Platform.isLinux || Platform.isAndroid) return 'libsecp256k1.so';
  if (Platform.isWindows) return 'secp256k1.dll';
  return null;
}

String? _resolveBundledSecp256k1LibraryPath() {
  final explicit = Platform.environment['HOSTR_SECP256K1_LIBRARY_PATH'];
  if (explicit != null && explicit.trim().isNotEmpty) {
    final file = File(explicit.trim());
    if (file.existsSync()) return file.path;
  }

  final besideExecutable = _resolveSecp256k1PathFromExecutableDir();
  if (besideExecutable != null) return besideExecutable;

  Uri? packageUri;
  try {
    packageUri = Isolate.resolvePackageUriSync(
      Uri.parse('package:models/main.dart'),
    );
  } on UnsupportedError {
    return null;
  }

  if (packageUri == null) {
    return null;
  }

  final libDir = File.fromUri(packageUri).parent.path;
  final packageRoot = Directory(libDir).parent.path;
  final arch = currentCpuArch();

  final candidates = <String>[
    if (Platform.isMacOS) ...[
      if (arch == CpuArch.arm64)
        '$packageRoot/native/macos/arm64/libsecp256k1.dylib',
      if (arch == CpuArch.x64)
        '$packageRoot/native/macos/x86_64/libsecp256k1.dylib',
      '$packageRoot/native/macos/libsecp256k1.dylib',
    ],
    if (Platform.isLinux || Platform.isAndroid) ...[
      if (arch == CpuArch.arm64)
        '$packageRoot/native/linux/arm64/libsecp256k1.so',
      if (arch == CpuArch.x64)
        '$packageRoot/native/linux/x86_64/libsecp256k1.so',
      '$packageRoot/native/linux/libsecp256k1.so',
    ],
    if (Platform.isWindows) ...[
      if (arch == CpuArch.x64)
        '$packageRoot/native/windows/x86_64/secp256k1.dll',
      '$packageRoot/native/windows/secp256k1.dll',
    ],
  ];

  for (final candidate in candidates) {
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }

  return null;
}

String? _resolveSecp256k1PathFromExecutableDir() {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  final bundleDir = Directory(exeDir).parent.path;
  final arch = currentCpuArch();
  final candidates = <String>[
    if (Platform.isMacOS) ...[
      if (arch == CpuArch.arm64)
        '$exeDir/native/macos/arm64/libsecp256k1.dylib',
      if (arch == CpuArch.x64) '$exeDir/native/macos/x86_64/libsecp256k1.dylib',
      '$exeDir/native/macos/libsecp256k1.dylib',
      '$exeDir/lib/libsecp256k1.dylib',
      '$exeDir/libsecp256k1.dylib',
      if (arch == CpuArch.arm64)
        '$bundleDir/native/macos/arm64/libsecp256k1.dylib',
      if (arch == CpuArch.x64)
        '$bundleDir/native/macos/x86_64/libsecp256k1.dylib',
      '$bundleDir/native/macos/libsecp256k1.dylib',
      '$bundleDir/lib/libsecp256k1.dylib',
      '$bundleDir/libsecp256k1.dylib',
    ],
    if (Platform.isLinux || Platform.isAndroid) ...[
      if (arch == CpuArch.arm64) '$exeDir/native/linux/arm64/libsecp256k1.so',
      if (arch == CpuArch.x64) '$exeDir/native/linux/x86_64/libsecp256k1.so',
      '$exeDir/native/linux/libsecp256k1.so',
      '$exeDir/lib/libsecp256k1.so',
      '$exeDir/libsecp256k1.so',
      if (arch == CpuArch.arm64)
        '$bundleDir/native/linux/arm64/libsecp256k1.so',
      if (arch == CpuArch.x64) '$bundleDir/native/linux/x86_64/libsecp256k1.so',
      '$bundleDir/native/linux/libsecp256k1.so',
      '$bundleDir/lib/libsecp256k1.so',
      '$bundleDir/libsecp256k1.so',
    ],
    if (Platform.isWindows) ...[
      if (arch == CpuArch.x64) '$exeDir/native/windows/x86_64/secp256k1.dll',
      '$exeDir/native/windows/secp256k1.dll',
      '$exeDir/secp256k1.dll',
      if (arch == CpuArch.x64) '$bundleDir/native/windows/x86_64/secp256k1.dll',
      '$bundleDir/native/windows/secp256k1.dll',
      '$bundleDir/lib/secp256k1.dll',
      '$bundleDir/secp256k1.dll',
    ],
  ];

  for (final candidate in candidates) {
    if (File(candidate).existsSync()) return candidate;
  }
  return null;
}
