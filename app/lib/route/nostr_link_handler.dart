import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/naddr.dart';
import 'package:ndk/ndk.dart';

/// Handles incoming `nostr:` deep links (NIP-21) and routes them within the app.
///
/// Per NIP-21, links follow the format `nostr:<bech32-entity>`.
/// Per NIP-89, the `naddr` entity already encodes the event kind, so the app
/// can determine whether it handles a given link by inspecting the decoded kind.
///
/// Supported kinds:
/// - [kNostrKindListing] (32121) → navigates to the listing screen
class NostrLinkHandler {
  final AppRouter _router;
  final CustomLogger _logger = CustomLogger();

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// Event kinds this app can handle via deep links.
  static const Set<int> supportedKinds = {kNostrKindListing};

  NostrLinkHandler({required AppRouter router}) : _router = router;

  /// Start listening for incoming deep links.
  ///
  /// Should be called once during app initialization, after the router is
  /// ready to accept navigation.
  Future<void> init() async {
    _appLinks = AppLinks();

    // Handle the link that launched the app (cold start).
    try {
      final initialUri = await _appLinks!.getInitialLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      _logger.e('Error getting initial deep link: $e');
    }

    // Handle links received while the app is already running (warm start).
    _linkSubscription = _appLinks!.uriLinkStream.listen(
      _handleUri,
      onError: (err) {
        _logger.e('Deep link stream error: $err');
      },
    );
  }

  /// Parse a URI and navigate if it matches a supported Nostr entity.
  void _handleUri(Uri uri) {
    _logger.i('Received deep link: $uri');

    final nostrEntity = _extractNostrEntity(uri);
    if (nostrEntity == null) {
      _logger.d('Not a valid nostr: URI, ignoring');
      return;
    }

    _routeNostrEntity(nostrEntity);
  }

  /// Extract the bech32 entity from a `nostr:` URI.
  ///
  /// Supports both:
  /// - Custom scheme: `nostr:naddr1...`
  /// - Web fallback:  `https://hostr.cc/nostr/naddr1...`
  String? _extractNostrEntity(Uri uri) {
    // Custom scheme: nostr:naddr1abc...
    if (uri.scheme == 'nostr') {
      // The path is the bech32 entity after "nostr:"
      final entity = uri.toString().substring('nostr:'.length);
      return entity.isNotEmpty ? entity : null;
    }

    // Web/universal link: https://hostr.cc/e/naddr1abc...
    if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments.first == 'e') {
      return uri.pathSegments[1];
    }

    return null;
  }

  /// Route to the appropriate screen based on the decoded Nostr entity.
  void _routeNostrEntity(String bech32Entity) {
    try {
      if (bech32Entity.startsWith('naddr1')) {
        _handleNaddr(bech32Entity);
      } else if (bech32Entity.startsWith('nprofile1')) {
        _logger.d('nprofile links not yet supported');
      } else if (bech32Entity.startsWith('nevent1')) {
        _logger.d('nevent links not yet supported');
      } else if (bech32Entity.startsWith('note1')) {
        _logger.d('note links not yet supported');
      } else {
        _logger.d('Unsupported NIP-19 entity type: $bech32Entity');
      }
    } catch (e, st) {
      _logger.e('Error routing nostr entity: $e\n$st');
    }
  }

  /// Decode an `naddr` and navigate to the corresponding screen.
  ///
  /// The `naddr` TLV payload contains the event kind, so we know at decode
  /// time whether this app handles that kind — this is the mechanism NIP-89
  /// describes for kind-based routing.
  void _handleNaddr(String naddrStr) {
    final Naddr naddr = Nip19.decodeNaddr(naddrStr);
    _logger.i(
      'Decoded naddr: kind=${naddr.kind}, pubkey=${naddr.pubkey}, '
      'd=${naddr.identifier}, relays=${naddr.relays}',
    );

    if (!supportedKinds.contains(naddr.kind)) {
      _logger.d('Kind ${naddr.kind} not supported by this app');
      return;
    }

    switch (naddr.kind) {
      case kNostrKindListing:
        // Reconstruct the anchor format used by the app: kind:pubkey:d-tag
        final anchor = '${naddr.kind}:${naddr.pubkey}:${naddr.identifier}';
        _logger.i('Navigating to listing with anchor: $anchor');
        _router.push(ListingRoute(a: anchor));
        break;
    }
  }

  /// Clean up resources.
  void dispose() {
    _linkSubscription?.cancel();
  }
}
