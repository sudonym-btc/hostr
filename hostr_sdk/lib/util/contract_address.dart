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

/// Returns the deployed escrow contract address from promoted runtime config.
///
/// Resolution order:
/// 1. `--dart-define=ESCROW_CONTRACT_ADDRESS=...` for Flutter app/test processes.
/// 2. `ESCROW_CONTRACT_ADDRESS` environment variable for host-side Dart/CLI processes.
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

  throw StateError(
    'Could not resolve escrow contract address. '
    'Set ESCROW_CONTRACT_ADDRESS in the environment or pass '
    '--dart-define=ESCROW_CONTRACT_ADDRESS=<0x...>.',
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
