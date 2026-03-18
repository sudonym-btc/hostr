/// A single NIP-05 / LUD-16 record in the fake registry.
class IdentityRecord {
  final String username;
  final String domain;
  final String pubkey;

  const IdentityRecord({
    required this.username,
    required this.domain,
    required this.pubkey,
  });

  String get nip05 => '$username@$domain';
}

/// In-memory NIP-05 / LUD-16 identity registry.
///
/// Replaces the LnbitsDatasource NIP-05 + LUD-16 setup that the
/// infrastructure pipeline performs against a real LNbits instance.
class FakeIdentityRegistry {
  final Map<String, IdentityRecord> _identities = {};

  /// All registered identities.
  List<IdentityRecord> get allRecords => _identities.values.toList();

  /// Register a username → pubkey mapping.
  void register({
    required String username,
    required String domain,
    required String pubkey,
  }) {
    _identities['$username@$domain'] = IdentityRecord(
      username: username,
      domain: domain,
      pubkey: pubkey,
    );
  }

  /// Look up the record for a NIP-05 identifier.
  IdentityRecord? lookup(String nip05) => _identities[nip05];

  /// Verify that [nip05] resolves to [pubkey].
  bool verifyNip05(String nip05, String pubkey) {
    return _identities[nip05]?.pubkey == pubkey;
  }

  /// Check whether a LUD-16 address is reachable.
  bool verifyLud16(String lud16) => _identities.containsKey(lud16);

  /// Reset all state.
  void reset() => _identities.clear();
}
