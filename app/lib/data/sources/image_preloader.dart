import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

/// A service that preloads and caches images, supporting both regular network
/// URLs and Blossom SHA-256 hashes that require server-list resolution first.
///
/// Usage:
///   final preloader = getIt<ImagePreloader>();
///   // Preload images for a listing:
///   preloader.preloadImages(imageRefs, pubkey: ownerPubkey);
///   // Retrieve a resolved URL for a Blossom hash:
///   final url = preloader.getResolvedUrl(sha256hash, pubkey);
///   // Preload into Flutter's image cache for a given BuildContext:
///   preloader.precacheForContext(imageRefs, pubkey: ownerPubkey, context: ctx);
@lazySingleton
class ImagePreloader {
  ImagePreloader();

  static final _sha256Regex = RegExp(r'^[a-fA-F0-9]{64}$');
  static final _networkRegex = RegExp(r'^(http|https):\/\/');

  /// Cache: sha256hash -> resolved full URL
  final Map<String, String> _resolvedUrls = {};

  /// Cache: pubkey -> list of blossom server URLs
  final Map<String, List<String>> _serverListCache = {};

  /// Tracks in-flight server list lookups to avoid duplicate requests.
  final Map<String, Future<List<String>>> _pendingServerLookups = {};

  /// Tracks in-flight image preloads to avoid duplicate fetches.
  final Set<String> _preloadingUrls = {};

  /// URLs that have been successfully preloaded into Flutter's image cache.
  final Set<String> _preloadedUrls = {};

  /// Bounded LRU set of recently failed URLs to avoid retry storms.
  final LinkedHashSet<String> _failedUrls = LinkedHashSet();
  static const _maxFailedEntries = 200;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Whether [imageRef] (hash or URL) is a SHA-256 Blossom hash.
  bool isSha256(String imageRef) => _sha256Regex.hasMatch(imageRef);

  /// Whether [imageRef] is a regular network URL.
  bool isNetworkUrl(String imageRef) => _networkRegex.hasMatch(imageRef);

  /// Returns the resolved URL for a Blossom [hash] belonging to [pubkey],
  /// or `null` if not yet resolved. Call [preloadImages] first to trigger
  /// resolution.
  String? getResolvedUrl(String hash, String pubkey) => _resolvedUrls[hash];

  /// Returns true if the image at [url] has been fully preloaded into
  /// Flutter's painting cache.
  bool isPreloaded(String url) => _preloadedUrls.contains(url);

  /// Resolves and preloads a list of image references (SHA-256 hashes or
  /// URLs) belonging to [pubkey].
  ///
  /// * Blossom hashes are resolved via the NDK server-list API, then fetched.
  /// * Network URLs are fetched directly.
  /// * Results are cached so subsequent calls are instant.
  Future<void> preloadImages(
    List<String> imageRefs, {
    required String pubkey,
  }) async {
    final futures = <Future>[];

    for (final ref in imageRefs) {
      if (isSha256(ref)) {
        futures.add(_resolveBlossom(ref, pubkey));
      } else if (isNetworkUrl(ref)) {
        futures.add(_preloadUrl(ref));
      }
    }

    await Future.wait(futures, eagerError: false);
  }

  /// Preloads images into Flutter's [ImageCache] so that [Image.network] and
  /// [NetworkImage] render instantly. Must be called with a valid
  /// [BuildContext].
  ///
  /// This first resolves any Blossom hashes, then calls [precacheImage] for
  /// every resolved URL.
  Future<void> precacheForContext(
    List<String> imageRefs, {
    required String pubkey,
    required BuildContext context,
  }) async {
    // First resolve all blossom hashes.
    await preloadImages(imageRefs, pubkey: pubkey);

    // Now precache each resolved URL into the framework's image cache.
    for (final ref in imageRefs) {
      // The context may have been deactivated while awaiting resolution.
      if (!(context as Element).mounted) return;
      final url = _resolveRef(ref, pubkey);
      if (url != null && !_preloadedUrls.contains(url)) {
        _precacheSingle(url, context);
      }
    }
  }

  /// Resolves a single image reference to a URL (returns immediately from
  /// cache when possible). Returns `null` if the ref is neither a valid hash
  /// nor a URL.
  Future<String?> resolveImageRef(String ref, {required String pubkey}) async {
    if (isNetworkUrl(ref)) return ref;
    if (isSha256(ref)) {
      await _resolveBlossom(ref, pubkey);
      return _resolvedUrls[ref];
    }
    return null;
  }

  /// Clears all caches. Useful for testing or logout.
  void clearCache() {
    _resolvedUrls.clear();
    _serverListCache.clear();
    _pendingServerLookups.clear();
    _preloadingUrls.clear();
    _preloadedUrls.clear();
    _failedUrls.clear();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  /// Looks up a ref that might be a hash or a URL. Returns the URL or null.
  String? _resolveRef(String ref, String pubkey) {
    if (isNetworkUrl(ref)) return ref;
    if (isSha256(ref)) return _resolvedUrls[ref];
    return null;
  }

  /// Resolves a Blossom SHA-256 [hash] to a full URL and triggers preloading.
  Future<void> _resolveBlossom(String hash, String pubkey) async {
    // Already resolved.
    if (_resolvedUrls.containsKey(hash)) return;

    final servers = await _getServerList(pubkey);
    print(
      'ImagePreloader: resolving hash=$hash for pubkey=$pubkey against servers=$servers',
    );
    if (servers.isEmpty) return;

    final url = '${servers.first}/$hash';
    _resolvedUrls[hash] = url;
    await _preloadUrl(url);
  }

  /// Returns the cached blossom server list for [pubkey], fetching it from
  /// NDK if necessary. Deduplicates in-flight requests.
  Future<List<String>> _getServerList(String pubkey) async {
    // Always fetch to ensure latest server list, especially after publishing during login
    // if (_serverListCache.containsKey(pubkey)) {
    //   return _serverListCache[pubkey]!;
    // }

    // Coalesce concurrent lookups for the same pubkey.
    if (_pendingServerLookups.containsKey(pubkey)) {
      return _pendingServerLookups[pubkey]!;
    }

    final completer = Completer<List<String>>();
    _pendingServerLookups[pubkey] = completer.future;

    try {
      final servers = await getIt<Hostr>().blossom.getUserServerList(
        pubkeys: [pubkey],
      );
      final list = servers?.toList() ?? <String>[];
      // _serverListCache[pubkey] = list;
      completer.complete(list);
    } catch (e) {
      completer.complete(<String>[]);
    } finally {
      _pendingServerLookups.remove(pubkey);
    }

    return completer.future;
  }

  /// Pre-fetches the image at [url] by resolving it through Flutter's image
  /// pipeline. This warms the HTTP cache and decodes the image data.
  Future<void> _preloadUrl(String url) async {
    if (_preloadedUrls.contains(url) || _failedUrls.contains(url)) return;
    if (_preloadingUrls.contains(url)) return;

    _preloadingUrls.add(url);
    try {
      final provider = NetworkImage(url);
      final stream = provider.resolve(ImageConfiguration.empty);
      final completer = Completer<void>();

      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          _preloadedUrls.add(url);
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete();
        },
        onError: (exception, stackTrace) {
          _addFailedUrl(url);
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete();
        },
      );
      stream.addListener(listener);

      await completer.future;
    } catch (_) {
      _addFailedUrl(url);
    } finally {
      _preloadingUrls.remove(url);
    }
  }

  /// Calls [precacheImage] for a single URL, catching errors silently.
  void _precacheSingle(String url, BuildContext context) {
    if (!(context as Element).mounted) return;
    precacheImage(NetworkImage(url), context)
        .then((_) {
          _preloadedUrls.add(url);
        })
        .catchError((_) {
          _addFailedUrl(url);
        });
  }

  void _addFailedUrl(String url) {
    if (_failedUrls.length >= _maxFailedEntries) {
      _failedUrls.remove(_failedUrls.first);
    }
    _failedUrls.add(url);
  }
}
