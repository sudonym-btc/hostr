import 'package:hostr_sdk/injection.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/lnurl_http_impl.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl_response.dart';
import 'package:ndk/ndk.dart' hide Nwc;

/// Result of a NIP-05 verification check.
class Nip05VerificationResult {
  /// Whether the nip05 identifier is valid for the given pubkey.
  final bool valid;

  /// Relays advertised in the nip05 response.
  final List<String>? relays;

  /// Any error that occurred during verification.
  final String? error;

  const Nip05VerificationResult({required this.valid, this.relays, this.error});

  const Nip05VerificationResult.invalid({this.error})
    : valid = false,
      relays = null;
}

/// Result of a LUD-16 (Lightning Address) verification check.
class Lud16VerificationResult {
  /// Whether the LUD-16 endpoint is reachable and returns a valid payRequest.
  final bool reachable;

  /// Whether the LNURL endpoint supports Nostr zaps (NIP-57 `allowsNostr`).
  final bool allowsNostr;

  /// The min/max sendable amounts (in millisats).
  final int? minSendable;
  final int? maxSendable;

  /// Any error that occurred during verification.
  final String? error;

  const Lud16VerificationResult({
    required this.reachable,
    this.allowsNostr = false,
    this.minSendable,
    this.maxSendable,
    this.error,
  });

  const Lud16VerificationResult.unreachable({this.error})
    : reachable = false,
      allowsNostr = false,
      minSendable = null,
      maxSendable = null;
}

/// Wraps NDK's NIP-05 and LUD-16/LNURL verification for testability.
@Singleton(env: Env.allButTestAndMock)
class Verification {
  final Ndk _ndk;
  late final Lnurl _lnurl;

  Verification({required Ndk ndk}) : _ndk = ndk {
    _lnurl = Lnurl(
      transport: LnurlTransportHttpImpl(HttpRequestDS(http.Client())),
    );
  }

  /// Verify a NIP-05 identifier against a pubkey.
  ///
  /// Delegates to NDK's [Nip05Usecase.check] which handles caching (24h TTL)
  /// and in-flight request deduplication.
  Future<Nip05VerificationResult> verifyNip05({
    required String nip05,
    required String pubkey,
  }) async {
    if (nip05.isEmpty || pubkey.isEmpty) {
      return const Nip05VerificationResult.invalid(
        error: 'nip05 or pubkey is empty',
      );
    }
    try {
      final result = await _ndk.nip05.check(nip05: nip05, pubkey: pubkey);
      return Nip05VerificationResult(
        valid: result.valid,
        relays: result.relays,
      );
    } catch (e) {
      return Nip05VerificationResult.invalid(error: e.toString());
    }
  }

  /// Verify a LUD-16 (Lightning Address) by fetching its LNURL-pay endpoint.
  ///
  /// Checks:
  /// 1. The `.well-known/lnurlp/<name>` endpoint is reachable
  /// 2. The response is a valid `payRequest`
  /// 3. Whether `allowsNostr` is true (NIP-57 support)
  Future<Lud16VerificationResult> verifyLud16({required String lud16}) async {
    if (lud16.isEmpty) {
      return const Lud16VerificationResult.unreachable(error: 'lud16 is empty');
    }

    final link = Lnurl.getLud16LinkFromLud16(lud16);
    if (link == null) {
      return const Lud16VerificationResult.unreachable(
        error: 'Invalid lud16 format',
      );
    }

    try {
      final LnurlResponse? response = await _lnurl.getLnurlResponse(link);
      if (response == null) {
        return const Lud16VerificationResult.unreachable(
          error: 'No response from LNURL endpoint',
        );
      }

      if (response.tag != 'payRequest') {
        return Lud16VerificationResult.unreachable(
          error: 'Not a payRequest (tag: ${response.tag})',
        );
      }

      return Lud16VerificationResult(
        reachable: true,
        allowsNostr: response.doesAllowsNostr,
        minSendable: response.minSendable,
        maxSendable: response.maxSendable,
      );
    } catch (e) {
      return Lud16VerificationResult.unreachable(error: e.toString());
    }
  }
}

/// Mock verification for test/mock environments.
@Singleton(as: Verification, env: [Env.test, Env.mock])
class MockVerification extends Verification {
  MockVerification({required super.ndk});

  @override
  Future<Nip05VerificationResult> verifyNip05({
    required String nip05,
    required String pubkey,
  }) async {
    return const Nip05VerificationResult(valid: true);
  }

  @override
  Future<Lud16VerificationResult> verifyLud16({required String lud16}) async {
    return const Lud16VerificationResult(reachable: true, allowsNostr: true);
  }
}
