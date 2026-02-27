import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../bip340.dart';
import 'serializable.dart';

/// Field-agnostic commitment mixin.
///
/// Any [Serializable] subclass can mix in [CommitTerms] to declare which of
/// its JSON keys are locked into a commitment hash. The mixin provides
/// hashing, signing and verification — without knowing anything about the
/// specific field names or their types.
///
/// ```dart
/// class ReservationContent extends EventContent with CommitTerms {
///   @override
///   Set<String> get committedFields => {'start', 'end', 'quantity', 'amount', 'recipient'};
///   ...
/// }
/// ```
///
/// The hash is computed from the [toJson] output of the host class, picking
/// only the keys listed in [committedFields]. This eliminates duplication
/// between the domain model and a separate commit-terms object.
mixin CommitTerms on Serializable {
  /// Which keys from [toJson] are locked into the commitment hash.
  ///
  /// Only keys present in the output of [toJson] **and** listed here will be
  /// included in the hash. The concrete class decides what matters.
  Set<String> get committedFields;

  /// Schnorr signatures over [commitHash], keyed by public key.
  ///
  /// When a seller signs the commit, the buyer can carry this signature
  /// inside their own event so third parties can verify the seller agreed
  /// to these exact terms.
  Map<String, String> get signatures;

  // ── Hashing ───────────────────────────────────────────────────────

  /// SHA-256 hash of the committed fields' canonical (sorted-key) JSON.
  ///
  /// Values are read from [toJson]; only keys in [committedFields] are
  /// included. Signatures, stage, and any other transient fields are
  /// excluded automatically.
  String commitHash() {
    final json = toJson();
    final committed = <String, dynamic>{};
    for (final key in committedFields) {
      if (json.containsKey(key)) committed[key] = json[key];
    }
    final sorted = Map.fromEntries(
      committed.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sha256.convert(utf8.encode(jsonEncode(sorted))).toString();
  }

  // ── Signing ───────────────────────────────────────────────────────

  /// Compute a BIP-340 Schnorr signature over [commitHash].
  ///
  /// Returns the hex-encoded signature string. The caller is responsible
  /// for storing it in [signatures] (typically via `copyWith`).
  String signCommit(KeyPair keyPair) {
    return Bip340.sign(commitHash(), keyPair.privateKey!);
  }

  /// Check whether a valid signature exists for [pubkey].
  ///
  /// If [pubkey] is `null`, returns `true` when **any** signature in
  /// [signatures] is valid.
  bool verifyCommit([String? pubkey]) {
    if (pubkey != null) {
      final sig = signatures[pubkey];
      if (sig == null) return false;
      return Bip340.verify(commitHash(), sig, pubkey);
    }
    return signatures.entries.any(
      (entry) => Bip340.verify(commitHash(), entry.value, entry.key),
    );
  }
}
