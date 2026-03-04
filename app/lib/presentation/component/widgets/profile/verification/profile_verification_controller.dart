import 'package:flutter/foundation.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

/// Encapsulates NIP-05 and LUD-16 verification logic for a profile.
///
/// Shared across profile_header, profile_popup, edit_profile_inputs, etc.
/// Call [verify] with a [ProfileMetadata] to kick off both checks.
class ProfileVerificationController extends ChangeNotifier {
  Nip05VerificationResult? _nip05Result;
  Lud16VerificationResult? _lud16Result;
  bool _nip05Loading = false;
  bool _lud16Loading = false;

  Nip05VerificationResult? get nip05Result => _nip05Result;
  Lud16VerificationResult? get lud16Result => _lud16Result;
  bool get nip05Loading => _nip05Loading;
  bool get lud16Loading => _lud16Loading;

  /// Run both NIP-05 and LUD-16 verification for [profile].
  void verify(ProfileMetadata profile) {
    _verifyNip05(profile);
    _verifyLud16(profile);
  }

  /// Verify just the NIP-05 address for [nip05] against [pubkey].
  ///
  /// Useful in edit forms where values change independently.
  Future<void> verifyNip05Only({
    required String nip05,
    required String pubkey,
  }) async {
    if (nip05.isEmpty) {
      _nip05Result = null;
      _nip05Loading = false;
      notifyListeners();
      return;
    }
    _nip05Loading = true;
    notifyListeners();
    try {
      _nip05Result = await getIt<Hostr>().verification.verifyNip05(
        nip05: nip05,
        pubkey: pubkey,
      );
    } catch (e) {
      _nip05Result = Nip05VerificationResult.invalid(error: e.toString());
    } finally {
      _nip05Loading = false;
      notifyListeners();
    }
  }

  /// Verify just the LUD-16 lightning address.
  ///
  /// Useful in edit forms where values change independently.
  Future<void> verifyLud16Only({required String lud16}) async {
    if (lud16.isEmpty) {
      _lud16Result = null;
      _lud16Loading = false;
      notifyListeners();
      return;
    }
    _lud16Loading = true;
    notifyListeners();
    try {
      _lud16Result = await getIt<Hostr>().verification.verifyLud16(
        lud16: lud16,
      );
    } catch (e) {
      _lud16Result = Lud16VerificationResult.unreachable(error: e.toString());
    } finally {
      _lud16Loading = false;
      notifyListeners();
    }
  }

  // ─── Private helpers ──────────────────────────────────────────

  Future<void> _verifyNip05(ProfileMetadata profile) async {
    final nip05 = profile.metadata.nip05;
    if (nip05 == null || nip05.isEmpty) {
      _nip05Result = null;
      _nip05Loading = false;
      notifyListeners();
      return;
    }
    _nip05Loading = true;
    notifyListeners();
    try {
      _nip05Result = await getIt<Hostr>().verification.verifyNip05(
        nip05: nip05,
        pubkey: profile.pubKey,
      );
    } catch (e) {
      _nip05Result = Nip05VerificationResult.invalid(error: e.toString());
    } finally {
      _nip05Loading = false;
      notifyListeners();
    }
  }

  Future<void> _verifyLud16(ProfileMetadata profile) async {
    final lud16 = profile.metadata.lud16;
    if (lud16 == null || lud16.isEmpty) {
      _lud16Result = null;
      _lud16Loading = false;
      notifyListeners();
      return;
    }
    _lud16Loading = true;
    notifyListeners();
    try {
      _lud16Result = await getIt<Hostr>().verification.verifyLud16(
        lud16: lud16,
      );
    } catch (e) {
      _lud16Result = Lud16VerificationResult.unreachable(error: e.toString());
    } finally {
      _lud16Loading = false;
      notifyListeners();
    }
  }
}
