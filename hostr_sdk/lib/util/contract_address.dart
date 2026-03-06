import 'dart:io';

final _contractAddressPattern = RegExp(r'^0x[a-fA-F0-9]{40}$');

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

/// Returns the deployed escrow contract address from the Docker data file
/// written by the `escrow-contract-deploy` container.
///
/// Integration tests run in host file system
/// Flutter drive on-device, hence the difference in env/file resolution
///
/// Resolution order:
/// 1. `--dart-define=CONTRACT_ADDR=...` for Flutter app/test processes.
/// 2. `CONTRACT_ADDR` environment variable for host-side Dart/CLI processes.
/// 3. Common repository-relative file locations.
String resolveContractAddress() {
  const definedAddress = String.fromEnvironment('CONTRACT_ADDR');
  if (definedAddress.isNotEmpty) {
    return _validateContractAddress(
      definedAddress,
      'dart-define CONTRACT_ADDR',
    );
  }

  final envAddress = Platform.environment['CONTRACT_ADDR']?.trim();
  if (envAddress != null && envAddress.isNotEmpty) {
    return _validateContractAddress(envAddress, 'environment CONTRACT_ADDR');
  }

  for (final path in const [
    'docker/data/escrow/contract_addr',
    '../docker/data/escrow/contract_addr',
    '../../docker/data/escrow/contract_addr',
  ]) {
    final contractFile = File(path);
    if (!contractFile.existsSync()) continue;

    final address = contractFile.readAsStringSync().trim();
    if (address.isNotEmpty) {
      return _validateContractAddress(address, 'file $path');
    }
  }

  throw StateError(
    'Could not resolve escrow contract address. '
    'Set CONTRACT_ADDR, pass --dart-define=CONTRACT_ADDR=<0x...>, '
    'or ensure docker/data/escrow/contract_addr exists.',
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
