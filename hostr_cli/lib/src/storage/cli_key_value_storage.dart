import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:path/path.dart' as p;

class CliKeyValueStorage implements KeyValueStorage {
  CliKeyValueStorage({
    required this.stateDir,
    required this.allowInsecureFileStorage,
    this.service = 'network.hostr.cli',
  });

  final Directory stateDir;
  final bool allowInsecureFileStorage;
  final String service;

  File get _insecureFile => File(p.join(stateDir.path, 'secrets.json'));

  @override
  Future<void> write(String key, dynamic value) async {
    final stringValue = value is String ? value : jsonEncode(value);
    if (allowInsecureFileStorage) {
      await _fileWrite(key, stringValue);
      return;
    }
    if (Platform.isMacOS) {
      await _macWrite(key, stringValue);
      return;
    }
    if (Platform.isLinux && await _hasExecutable('secret-tool')) {
      await _linuxWrite(key, stringValue);
      return;
    }
    throw StateError(
      'No secure storage backend available. Install secret-tool on Linux, '
      'or configure file-backed storage for a private state directory.',
    );
  }

  @override
  Future<dynamic> read(String key) async {
    if (allowInsecureFileStorage) {
      return _fileRead(key);
    }
    if (Platform.isMacOS) {
      return _macRead(key);
    }
    if (Platform.isLinux && await _hasExecutable('secret-tool')) {
      return _linuxRead(key);
    }
    return null;
  }

  @override
  Future<void> delete(String key) async {
    if (allowInsecureFileStorage) {
      await _fileDelete(key);
      return;
    }
    if (Platform.isMacOS) {
      await _macDelete(key);
      return;
    }
    if (Platform.isLinux && await _hasExecutable('secret-tool')) {
      await _linuxDelete(key);
      return;
    }
  }

  Future<bool> _hasExecutable(String executable) async {
    final result = await Process.run('which', [executable]);
    return result.exitCode == 0;
  }

  Future<void> _macWrite(String key, String value) async {
    await _macDelete(key);
    final result = await Process.run('/usr/bin/security', [
      'add-generic-password',
      '-s',
      service,
      '-a',
      key,
      '-w',
      value,
      '-U',
    ]);
    if (result.exitCode != 0) {
      throw StateError('Keychain write failed for $key: ${result.stderr}');
    }
  }

  Future<String?> _macRead(String key) async {
    final result = await Process.run('/usr/bin/security', [
      'find-generic-password',
      '-s',
      service,
      '-a',
      key,
      '-w',
    ]);
    if (result.exitCode != 0) return null;
    return (result.stdout as String).trimRight();
  }

  Future<void> _macDelete(String key) async {
    await Process.run('/usr/bin/security', [
      'delete-generic-password',
      '-s',
      service,
      '-a',
      key,
    ]);
  }

  Future<void> _linuxWrite(String key, String value) async {
    final process = await Process.start('secret-tool', [
      'store',
      '--label=Hostr CLI $key',
      'service',
      service,
      'key',
      key,
    ]);
    process.stdin.write(value);
    await process.stdin.close();
    final exitCode = await process.exitCode;
    if (exitCode != 0) {
      throw StateError('secret-tool write failed for $key');
    }
  }

  Future<String?> _linuxRead(String key) async {
    final result = await Process.run('secret-tool', [
      'lookup',
      'service',
      service,
      'key',
      key,
    ]);
    if (result.exitCode != 0) return null;
    return (result.stdout as String).trimRight();
  }

  Future<void> _linuxDelete(String key) async {
    await Process.run('secret-tool', ['clear', 'service', service, 'key', key]);
  }

  Future<Map<String, dynamic>> _readFileMap() async {
    if (!await _insecureFile.exists()) return <String, dynamic>{};
    return jsonDecode(await _insecureFile.readAsString())
        as Map<String, dynamic>;
  }

  Future<void> _writeFileMap(Map<String, dynamic> values) async {
    await stateDir.create(recursive: true);
    await _insecureFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(values),
      flush: true,
    );
    if (!Platform.isWindows) {
      await Process.run('chmod', ['600', _insecureFile.path]);
    }
  }

  Future<void> _fileWrite(String key, String value) async {
    final values = await _readFileMap();
    values[key] = value;
    await _writeFileMap(values);
  }

  Future<String?> _fileRead(String key) async {
    final values = await _readFileMap();
    final value = values[key];
    return value?.toString();
  }

  Future<void> _fileDelete(String key) async {
    final values = await _readFileMap();
    values.remove(key);
    await _writeFileMap(values);
  }
}
