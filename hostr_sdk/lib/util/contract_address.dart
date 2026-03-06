import 'dart:io';

/// Returns the deployed escrow contract address from the Docker data file
/// written by the `escrow-contract-deploy` container.
///
/// Callers may run from either the repository root or `hostr_sdk/`, so both
/// relative locations are checked.
String resolveContractAddress() {
  for (final path in const [
    'docker/data/escrow/contract_addr',
    '../docker/data/escrow/contract_addr',
  ]) {
    final contractFile = File(path);
    if (!contractFile.existsSync()) continue;

    final address = contractFile.readAsStringSync().trim();
    if (address.isNotEmpty) return address;
  }

  throw StateError(
    'Could not read escrow contract address from docker/data/escrow/contract_addr. '
    'Run the escrow-contract-deploy service before using the seeder or hostr_sdk integration tests.',
  );
}
