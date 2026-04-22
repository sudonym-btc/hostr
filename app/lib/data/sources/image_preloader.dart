import 'dart:async';
import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:hostr/data/sources/blossom_image_variant.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

/// A service that preloads and caches images, supporting both regular network
/// URLs and Blossom SHA-256 hashes that require server-list resolution first.
///
/// Usage:
///   final preloader = `getIt<ImagePreloader>()`;
///   // Preload images for a listing:
///   preloader.preloadImages(imageRefs, pubkey: ownerPubkey);
///   // Retrieve a resolved URL for a Blossom hash:
///   final url = preloader.getResolvedUrl(sha256hash, pubkey);
///   // Preload into Flutter's image cache for a given BuildContext:
///   preloader.precacheForContext(imageRefs, pubkey: ownerPubkey, context: ctx);
@lazySingleton
class ImagePreloader {
  ImagePreloader();
  static final _logger = CustomLogger(tag: 'app.image-preloader');

  static final _sha256Regex = RegExp(r'^[a-fA-F0-9]{64}$');
  static final _networkRegex = RegExp(r'^(http|https):\/\/');

  /// Cache: sha256hash -> resolved full URL
  final Map<String, String> _resolvedUrls = {};

  /// Tracks in-flight server list lookups to avoid duplicate requests.
  final Map<String, Future<List<String>>> _pendingServerLookups = {};

  /// Tracks in-flight image preloads to avoid duplicate fetches.
  final Map<String, Future<bool>> _preloadingUrls = {};

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
    Iterable<IMeta> imageMetas = const [],
    BlossomImageVariantHint variantHint = BlossomImageVariantHint.none,
  }) async {
    final futures = <Future>[];

    for (final ref in imageRefs) {
      final candidate = BlossomImageVariantResolver.resolve(
        imageRef: ref,
        imageMetas: imageMetas,
        hint: variantHint,
      );
      final candidateRef = candidate.ref;
      if (isSha256(candidateRef)) {
        futures.add(_resolveBlossom(candidateRef, pubkey));
      } else if (isNetworkUrl(candidateRef)) {
        futures.add(_preloadUrl(candidateRef));
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
    Iterable<IMeta> imageMetas = const [],
    BlossomImageVariantHint variantHint = BlossomImageVariantHint.none,
  }) async {
    // First resolve all blossom hashes.
    await preloadImages(
      imageRefs,
      pubkey: pubkey,
      imageMetas: imageMetas,
      variantHint: variantHint,
    );

    // Now precache each resolved URL into the framework's image cache.
    for (final ref in imageRefs) {
      // The context may have been deactivated while awaiting resolution.
      if (!context.mounted) return;
      final candidate = BlossomImageVariantResolver.resolve(
        imageRef: ref,
        imageMetas: imageMetas,
        hint: variantHint,
      );
      final url = _resolveRef(candidate.ref, pubkey);
      if (url != null && !_preloadedUrls.contains(url)) {
        _precacheSingle(url, context);
      }
    }
  }

  /// Resolves a single image reference to a URL (returns immediately from
  /// cache when possible). Returns `null` if the ref is neither a valid hash
  /// nor a URL.
  Future<String?> resolveImageRef(
    String ref, {
    required String pubkey,
    Iterable<IMeta> imageMetas = const [],
    BlossomImageVariantHint variantHint = BlossomImageVariantHint.none,
  }) async {
    final candidate = BlossomImageVariantResolver.resolve(
      imageRef: ref,
      imageMetas: imageMetas,
      hint: variantHint,
    );
    final candidateRef = candidate.ref;

    if (isNetworkUrl(candidateRef)) return candidateRef;
    if (isSha256(candidateRef)) {
      await _resolveBlossom(candidateRef, pubkey);
      return _resolvedUrls[candidateRef];
    }
    return null;
  }

  /// Clears all caches. Useful for testing or logout.
  void clearCache() {
    _resolvedUrls.clear();
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
    debugPrint(
      'ImagePreloader: resolving hash=$hash for pubkey=$pubkey against servers=$servers',
    );
    if (servers.isEmpty) return;

    for (final server in servers) {
      final url = '${server.replaceFirst(RegExp(r'/+$'), '')}/$hash';
      final loaded = await _preloadUrl(url);
      if (loaded) {
        _resolvedUrls[hash] = url;
        return;
      }
    }
  }

  /// Fetches the Blossom server list for [pubkey] through NDK.
  /// Deduplicates only concurrent in-flight requests.
  Future<List<String>> _getServerList(String pubkey) async {
    // Coalesce concurrent lookups for the same pubkey.
    if (_pendingServerLookups.containsKey(pubkey)) {
      return _pendingServerLookups[pubkey]!;
    }

    final completer = Completer<List<String>>();
    _pendingServerLookups[pubkey] = completer.future;

    try {
      final hostr = getIt<Hostr>();
      final servers = await hostr.blossom.getUserServerList(pubkeys: [pubkey]);

      final list = _normaliseServerList(servers);
      if (list.isNotEmpty) {
        completer.complete(list);
        return completer.future;
      }

      final fallback = _normaliseServerList(hostr.config.bootstrapBlossom);
      if (fallback.isNotEmpty) {
        _logger.w(
          'Blossom server list empty for $pubkey; falling back to configured Hostr Blossom servers: $fallback',
        );
        completer.complete(fallback);
        return completer.future;
      }

      completer.complete(list);
    } catch (error, stackTrace) {
      _logger.w(
        'Failed to load Blossom server list for $pubkey',
        error: error,
        stackTrace: stackTrace,
      );
      final fallback = _normaliseServerList(
        getIt<Hostr>().config.bootstrapBlossom,
      );
      if (fallback.isNotEmpty) {
        _logger.w(
          'Using configured Hostr Blossom servers after server-list lookup failure for $pubkey: $fallback',
        );
      }
      completer.complete(fallback);
    } finally {
      _pendingServerLookups.remove(pubkey);
    }

    return completer.future;
  }

  List<String> _normaliseServerList(Iterable<String>? servers) {
    if (servers == null) return <String>[];
    return servers
        .map((server) => server.trim())
        .where((server) => server.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Pre-fetches the image at [url] by resolving it through Flutter's image
  /// pipeline. This warms the HTTP cache and decodes the image data.
  Future<bool> _preloadUrl(String url) async {
    if (_preloadedUrls.contains(url)) return true;
    if (_failedUrls.contains(url)) return false;

    final pending = _preloadingUrls[url];
    if (pending != null) return pending;

    final preload = _preloadUrlUnchecked(url);
    _preloadingUrls[url] = preload;
    try {
      return await preload;
    } finally {
      _preloadingUrls.remove(url);
    }
  }

  Future<bool> _preloadUrlUnchecked(String url) async {
    try {
      final provider = NetworkImage(
        url,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      );
      final stream = provider.resolve(ImageConfiguration.empty);
      final completer = Completer<bool>();

      late ImageStreamListener listener;
      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          _preloadedUrls.add(url);
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete(true);
        },
        onError: (exception, stackTrace) {
          _logger.w(
            'Blossom image preload failed for $url',
            error: exception,
            stackTrace: stackTrace,
          );
          _addFailedUrl(url);
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete(false);
        },
      );
      stream.addListener(listener);

      return await completer.future;
    } catch (error, stackTrace) {
      _logger.w(
        'Blossom image preload threw before resolution for $url',
        error: error,
        stackTrace: stackTrace,
      );
      _addFailedUrl(url);
      return false;
    }
  }

  /// Calls [precacheImage] for a single URL, catching errors silently.
  void _precacheSingle(String url, BuildContext context) {
    if (!context.mounted) return;
    precacheImage(
          NetworkImage(
            url,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          ),
          context,
        )
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
