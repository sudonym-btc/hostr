import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

final _contractAddressPattern = RegExp(r'^0x[a-fA-F0-9]{40}$');
const _defaultContractAddressLookupKey = 'regtest.33';
const _defaultContractName = 'MultiEscrow';

String _normalizeContractAddress(String value) {
  final trimmed = value.trim();
  if ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
      (trimmed.startsWith("'") && trimmed.endsWith("'"))) {
    return trimmed.substring(1, trimmed.length - 1).trim();
  }
  return trimmed;
}

String _validateContractAddress(String value, String source) {
  final normalized = _normalizeContractAddress(value);
  if (_contractAddressPattern.hasMatch(normalized)) return normalized;

  throw StateError(
    'Invalid escrow contract address from $source: "$normalized". '
    'Expected a 0x-prefixed 40-hex-character address.',
  );
}

/// Returns the deployed escrow contract address from promoted runtime config.
///
/// Resolution order:
/// 1. `--dart-define=ESCROW_CONTRACT_ADDRESS=...` for Flutter app/test processes.
/// 2. `ESCROW_CONTRACT_ADDRESS` environment variable for host-side Dart/CLI processes.
/// 3. Address lookup file, using `ESCROW_CONTRACT_ADDRESS_KEY` (default
///    `regtest.33`) and contract name `MultiEscrow`.
/// 4. Repo fallback at `escrow/contracts/contract-addresses.json`.
String resolveContractAddress({
  String? addressKey,
  String contractName = _defaultContractName,
}) {
  const definedAddress = String.fromEnvironment('ESCROW_CONTRACT_ADDRESS');
  if (definedAddress.isNotEmpty) {
    return _validateContractAddress(
      definedAddress,
      'dart-define ESCROW_CONTRACT_ADDRESS',
    );
  }

  final envAddress = Platform.environment['ESCROW_CONTRACT_ADDRESS']?.trim();
  if (envAddress != null && envAddress.isNotEmpty) {
    return _validateContractAddress(
      envAddress,
      'environment ESCROW_CONTRACT_ADDRESS',
    );
  }

  final resolvedAddressKey =
      addressKey ??
      Platform.environment['ESCROW_CONTRACT_ADDRESS_KEY']?.trim() ??
      _defaultContractAddressLookupKey;

  final fileAddress = _resolveContractAddressFromFile(
    addressKey: resolvedAddressKey,
    contractName: contractName,
  );
  if (fileAddress != null) {
    return fileAddress;
  }

  throw StateError(
    'Could not resolve escrow contract address. '
    'Set ESCROW_CONTRACT_ADDRESS in the environment, pass '
    '--dart-define=ESCROW_CONTRACT_ADDRESS=<0x...>, or ensure '
    '${_contractAddressesFileDisplayPath()} contains '
    '$contractName under key "$resolvedAddressKey".',
  );
}

String? _resolveContractAddressFromFile({
  required String addressKey,
  required String contractName,
}) {
  for (final path in _candidateContractAddressFiles()) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }

    final resolved = _readContractAddressFromFile(
      file: file,
      addressKey: addressKey,
      contractName: contractName,
    );
    if (resolved != null) {
      return resolved;
    }
  }

  return null;
}

Iterable<String> _candidateContractAddressFiles() sync* {
  final envFile = Platform.environment['ESCROW_CONTRACT_ADDRESSES_FILE']
      ?.trim();
  if (envFile != null && envFile.isNotEmpty) {
    yield envFile;
  }

  final singularEnvFile = Platform.environment['ESCROW_CONTRACT_ADDRESS_FILE']
      ?.trim();
  if (singularEnvFile != null && singularEnvFile.isNotEmpty) {
    yield singularEnvFile;
  }

  final packageRoot = _resolveHostrSdkPackageRoot();
  if (packageRoot != null) {
    yield '$packageRoot/../escrow/contracts/contract-addresses.json';
    yield '$packageRoot/contract-addresses.json';
  }

  yield '${Directory.current.path}/../escrow/contracts/contract-addresses.json';
  yield '${Directory.current.path}/escrow/contracts/contract-addresses.json';
  yield '${Directory.current.path}/contract-addresses.json';
}

String? _resolveHostrSdkPackageRoot() {
  Uri? packageUri;
  try {
    packageUri = Isolate.resolvePackageUriSync(
      Uri.parse('package:hostr_sdk/hostr_sdk.dart'),
    );
  } on UnsupportedError {
    return null;
  }

  if (packageUri == null) {
    return null;
  }

  return File.fromUri(packageUri).parent.parent.path;
}

String? _readContractAddressFromFile({
  required File file,
  required String addressKey,
  required String contractName,
}) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(file.readAsStringSync());
  } on FormatException catch (error) {
    throw StateError('Invalid JSON in ${file.path}: ${error.message}');
  }

  if (decoded is! Map) {
    throw StateError(
      'Invalid contract address file ${file.path}: expected a JSON object.',
    );
  }

  final entry = decoded[addressKey];
  if (entry is! Map) {
    return null;
  }

  final value = entry[contractName];
  if (value is! String || value.trim().isEmpty) {
    return null;
  }

  return _validateContractAddress(
    value,
    'file ${file.path} [$addressKey].$contractName',
  );
}

String _contractAddressesFileDisplayPath() {
  final packageRoot = _resolveHostrSdkPackageRoot();
  if (packageRoot != null) {
    return 'escrow/contracts/contract-addresses.json';
  }
  return 'contract-addresses.json';
}

void main() {
  try {
    stdout.write(resolveContractAddress());
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
