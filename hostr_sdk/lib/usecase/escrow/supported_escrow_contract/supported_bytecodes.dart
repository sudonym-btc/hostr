/// SHA-256 hashes of runtime bytecodes for all supported escrow contracts.
///
/// These are **compile-time constants** — they only change when the Solidity
/// source changes, not on every deployment or restart (addresses change,
/// bytecodes don't).
///
/// To update after modifying escrow contracts:
///   dart run hostr_sdk:update_bytecodes
///
/// Maps bytecode hash → human-readable contract name.
const supportedEscrowBytecodeHashes = <String, String>{
  // MultiEscrow v1 — SHA-256 of runtime bytecode from escrow/contracts/MultiEscrow.sol
  '5d9520183effe800f57f6c9286f3fdaa37f9261d61901bd2e4925d3c6c4ad4aa':
      'MultiEscrow',
};
