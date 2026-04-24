import 'package:models/main.dart';

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

  UserStartupProfileBootstrapper({required MetadataUseCase metadata})
    : _metadata = metadata;

  Future<UserStartupProfileBootstrapResult> run({
    required String pubkey,
    required Future<bool> hasNip65Future,
  }) async {
    var metadata = await _metadata.loadMetadata(pubkey);
    final hasNip65 = await hasNip65Future;

    if (metadata == null && hasNip65) {
      metadata = await _metadata.loadMetadata(pubkey, forceRefresh: true);
    }

    if (metadata != null) {
      // Temporarily do not write user config during startup. In particular,
      // Hostr should not auto-publish Blossom server lists or NIP-65 relay lists
      // while the app is scoped to Hostr-owned infrastructure. Keep the hook
      // here so we can re-enable config reconciliation once relay/list semantics
      // are part of the product again.
      //
      // unawaited(_metadata.ensureUserConfig(pubkey).catchError((_) {}));
    }

    return UserStartupProfileBootstrapResult(
      metadata: metadata,
      hasNip65: hasNip65,
    );
  }
}
