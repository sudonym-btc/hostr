import 'dart:convert';
import 'dart:io';

final _contractAddressPattern = RegExp(r'^0x[a-fA-F0-9]{40}$');
final _contractAddressKeyPattern = RegExp(
  r'^(regtest|testnet|mainnet|hardhat)\.\d+$',
);

String _nonEmpty(String? value) => value?.trim() ?? '';

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

String _resolveAddressKey(String? explicitAddressKey) {
  final candidates = [
    explicitAddressKey,
    const String.fromEnvironment('ESCROW_CONTRACT_ADDRESS_KEY'),
    Platform.environment['ESCROW_CONTRACT_ADDRESS_KEY'],
  ];

  for (final candidate in candidates) {
    final normalized = _nonEmpty(candidate);
    if (normalized.isEmpty) continue;
    if (_contractAddressKeyPattern.hasMatch(normalized)) return normalized;

    throw StateError(
      'Invalid escrow contract address key "$normalized". '
      'Expected <network>.<chainId>, for example regtest.33.',
    );
  }

  return 'regtest.33';
}

Iterable<String> _candidateAddressFiles() sync* {
  final configuredPaths = [
    const String.fromEnvironment('ESCROW_CONTRACT_ADDRESSES_FILE'),
    Platform.environment['ESCROW_CONTRACT_ADDRESSES_FILE'],
  ];

  for (final configuredPath in configuredPaths) {
    final normalized = _nonEmpty(configuredPath);
    if (normalized.isNotEmpty) yield normalized;
  }

  yield '/contracts/contract-addresses.json';
  yield 'escrow/contracts/contract-addresses.json';
  yield '../escrow/contracts/contract-addresses.json';
  yield '../../escrow/contracts/contract-addresses.json';
}

String _readContractAddressFromFile({
  required String path,
  required String addressKey,
}) {
  final contractFile = File(path);
  if (!contractFile.existsSync()) {
    throw FileSystemException('Escrow contract address file not found', path);
  }

  final rawJson = contractFile.readAsStringSync();
  final decoded = jsonDecode(rawJson);
  if (decoded is! Map<String, dynamic>) {
    throw StateError(
      'Invalid JSON object in escrow contract addresses file: $path',
    );
  }

  final entry = decoded[addressKey];
  if (entry is! Map<String, dynamic>) {
    throw StateError(
      'Missing escrow contract address entry for "$addressKey" in $path.',
    );
  }

  final address = entry['MultiEscrow'];
  if (address is! String || address.trim().isEmpty) {
    throw StateError('Missing MultiEscrow address for "$addressKey" in $path.');
  }

  return _validateContractAddress(
    address,
    'file $path [$addressKey].MultiEscrow',
  );
}

/// Returns the deployed escrow contract address from the canonical
/// `escrow/contracts/contract-addresses.json` manifest.
///
/// Integration tests run in host file system
/// Flutter drive on-device, hence the difference in env/file resolution
///
/// Resolution order:
/// 1. `--dart-define=ESCROW_CONTRACT_ADDRESS=...` for Flutter app/test processes.
/// 2. `ESCROW_CONTRACT_ADDRESS` environment variable for host-side Dart/CLI processes.
/// 3. `ESCROW_CONTRACT_ADDRESSES_FILE` + `ESCROW_CONTRACT_ADDRESS_KEY`.
/// 4. Common repository-relative manifest locations.
String resolveContractAddress({String? addressKey}) {
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

  final resolvedAddressKey = _resolveAddressKey(addressKey);
  Object? lastError;
  for (final path in _candidateAddressFiles()) {
    final contractFile = File(path);
    if (!contractFile.existsSync()) continue;

    try {
      return _readContractAddressFromFile(
        path: path,
        addressKey: resolvedAddressKey,
      );
    } on Object catch (error) {
      lastError = error;
    }
  }

  final suffix = lastError == null ? '' : ' Last error: $lastError';
  throw StateError(
    'Could not resolve escrow contract address. '
    'Set ESCROW_CONTRACT_ADDRESS, pass '
    '--dart-define=ESCROW_CONTRACT_ADDRESS=<0x...>, or ensure '
    'escrow/contracts/contract-addresses.json exists with '
    '$resolvedAddressKey.MultiEscrow.$suffix',
  );
}

void main() {
  try {
    stdout.write(resolveContractAddress());
  } on Object catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
