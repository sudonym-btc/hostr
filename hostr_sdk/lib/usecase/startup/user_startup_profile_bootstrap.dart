import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../identity_claims/identity_claims.dart';
import '../listings/listings.dart';
import '../metadata/metadata.dart';

class UserStartupProfileBootstrapResult {
  final ProfileMetadata? metadata;
  final bool hasNip65;

  const UserStartupProfileBootstrapResult({
    required this.metadata,
    required this.hasNip65,
  });

  bool get hasMetadata => metadata != null;
}

/// Small testable unit for the user-startup profile decision tree.
///
/// Responsibilities:
/// - use the initial metadata load result immediately
/// - if metadata is missing but NIP-65 exists, retry with forceRefresh
/// - once metadata exists, ensure user config is mirrored/patched
class UserStartupProfileBootstrapper {
  final MetadataUseCase _metadata;
  final Listings _listings;
  final IdentityClaimsUseCase _identityClaims;

  UserStartupProfileBootstrapper({
    required MetadataUseCase metadata,
    required Listings listings,
    required IdentityClaimsUseCase identityClaims,
  }) : _metadata = metadata,
       _listings = listings,
       _identityClaims = identityClaims;

  Future<UserStartupProfileBootstrapResult> run({
    required String pubkey,
    required Future<bool> hasNip65Future,
  }) async {
    var metadata = await _metadata.loadMetadata(pubkey);
    final hasNip65 = await hasNip65Future;

    if (metadata == null && hasNip65) {
      metadata = await _metadata.loadMetadata(pubkey, forceRefresh: true);
    }

    await _ensureHostIdentity(pubkey);

    return UserStartupProfileBootstrapResult(
      metadata: metadata,
      hasNip65: hasNip65,
    );
  }

  Future<void> _ensureHostIdentity(String pubkey) async {
    final listings = await _listings.list(
      Filter(authors: [pubkey], limit: 1),
      name: 'startup-host-listings',
    );
    if (listings.isEmpty) return;

    await _identityClaims.ensureEvmAddress();
  }
}
