import 'dart:io';

import 'package:path/path.dart' as p;

Future<void> main(List<String> args) async {
  final output = _option(args, 'output') ?? _option(args, 'o') ?? 'build/cli';
  final verbosity = _option(args, 'verbosity') ?? 'warning';

  final cliRoot = Directory.current.absolute;
  final repoRoot = cliRoot.parent;
  final bundleRoot = Directory(p.join(cliRoot.path, output, 'bundle'));

  final result = await Process.start('dart', [
    'build',
    'cli',
    '--output=$output',
    '--verbosity=$verbosity',
  ], workingDirectory: cliRoot.path);

  await stdout.addStream(result.stdout);
  await stderr.addStream(result.stderr);
  final exitCode = await result.exitCode;
  if (exitCode != 0) {
    stderr.writeln('dart build cli failed with exit code $exitCode');
    exit(exitCode);
  }

  final nativeSource = Directory(p.join(repoRoot.path, 'models', 'native'));
  if (!nativeSource.existsSync()) {
    stderr.writeln('Missing native library directory: ${nativeSource.path}');
    exit(66);
  }

  final nativeTarget = Directory(p.join(bundleRoot.path, 'native'));
  if (nativeTarget.existsSync()) nativeTarget.deleteSync(recursive: true);
  _copyDirectory(nativeSource, nativeTarget);

  final libDir = Directory(p.join(bundleRoot.path, 'lib'));
  libDir.createSync(recursive: true);
  for (final fileName in _currentPlatformNativeFileNames()) {
    final source = _findCurrentPlatformNativeFile(nativeSource, fileName);
    if (source == null) {
      stderr.writeln('Warning: no bundled native library found for $fileName');
      continue;
    }
    source.copySync(p.join(libDir.path, fileName));
  }

  stdout.writeln('Bundled Hostr CLI at ${bundleRoot.path}');
  stdout.writeln(
    'Run: ${p.join(bundleRoot.path, 'bin', 'hostr')} diagnostics native --json',
  );
}

String? _option(List<String> args, String name) {
  final prefix = '--$name=';
  for (var i = 0; i < args.length; i++) {
    final arg = args[i];
    if (arg.startsWith(prefix)) return arg.substring(prefix.length);
    if (arg == '--$name' || arg == '-$name') {
      if (i + 1 < args.length) return args[i + 1];
      return '';
    }
  }
  return null;
}

void _copyDirectory(Directory source, Directory target) {
  target.createSync(recursive: true);
  for (final entity in source.listSync(recursive: false)) {
    final nextTarget = p.join(target.path, p.basename(entity.path));
    if (entity is Directory) {
      _copyDirectory(entity, Directory(nextTarget));
    } else if (entity is File) {
      entity.copySync(nextTarget);
    }
  }
}

List<String> _currentPlatformNativeFileNames() {
  if (Platform.isMacOS) return const ['libh3.dylib', 'libsecp256k1.dylib'];
  if (Platform.isLinux) return const ['libh3.so', 'libsecp256k1.so'];
  if (Platform.isWindows) return const ['h3.dll', 'secp256k1.dll'];
  return const [];
}

File? _findCurrentPlatformNativeFile(Directory nativeSource, String fileName) {
  final platform = Platform.isMacOS
      ? 'macos'
      : Platform.isLinux
      ? 'linux'
      : Platform.isWindows
      ? 'windows'
      : null;
  if (platform == null) return null;

  final arch = _currentArchDirectoryName();
  final candidates = [
    if (arch != null) p.join(nativeSource.path, platform, arch, fileName),
    p.join(nativeSource.path, platform, fileName),
  ];

  for (final candidate in candidates) {
    final file = File(candidate);
    if (file.existsSync()) return file;
  }
  return null;
}

String? _currentArchDirectoryName() {
  final raw = Platform.isWindows
      ? Platform.environment['PROCESSOR_ARCHITECTURE'] ?? ''
      : (Process.runSync('uname', ['-m']).stdout as String? ?? '');
  final normalized = raw.trim().toLowerCase();
  if (normalized == 'arm64' || normalized == 'aarch64') return 'arm64';
  if (normalized == 'x86_64' || normalized == 'amd64') return 'x86_64';
  return null;
}
