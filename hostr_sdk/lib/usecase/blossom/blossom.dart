import 'dart:typed_data';

import 'package:injectable/injectable.dart' hide Order;
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart';

import '../../config.dart';
import '../../util/main.dart';
import '../requests/requests.dart';

/// Wraps NDK's [Blossom] use case with hostr-specific conveniences such as
/// [ensureBlossomServer] which merges the user's existing server list with the
/// configured bootstrap servers.
@Singleton()
class BlossomUseCase {
  final Ndk _ndk;
  final HostrConfig _config;
  final CustomLogger _logger;

  BlossomUseCase({
    required Ndk ndk,
    required HostrConfig config,
    required CustomLogger logger,
  }) : _ndk = ndk,
       _config = config,
       _logger = logger;

  // ---------------------------------------------------------------------------
  // ensureBlossomServer
  // ---------------------------------------------------------------------------

  /// Fetches the current user's blossom server list, merges it with the
  /// configured [HostrConfig.bootstrapBlossom] servers, and publishes the
  /// combined list. This guarantees that the user always has at least the
  /// bootstrap servers in their published NIP-10063 list.
  Future<void> ensureBlossomServer(
    String pubkey,
  ) => _logger.span('ensureBlossomServer', () async {
    final existingBlossomList = _normaliseServerUrls(
      await _ndk.blossomUserServerList.getUserServerList(pubkeys: [pubkey]),
    );
    final bootstrapBlossomList = _normaliseServerUrls(_config.bootstrapBlossom);
    final missingBootstrapUrls = bootstrapBlossomList
        .where((url) => !existingBlossomList.contains(url))
        .toList();

    _logger.i(
      'Ensuring Blossom server list for pubkey=$pubkey: '
      'existing=$existingBlossomList, '
      'bootstrap=$bootstrapBlossomList, '
      'missingBootstrap=$missingBootstrapUrls',
    );

    final mergedUrls = {
      ...existingBlossomList,
      ...bootstrapBlossomList,
    }.toList();

    // Nothing to publish when no servers are configured (e.g. test env).
    if (mergedUrls.isEmpty) {
      _logger.w(
        'Blossom server list empty and no bootstrap servers configured; '
        'skipping publish for pubkey=$pubkey.',
      );
      return;
    }

    final broadcastResponse = await _ndk.blossomUserServerList
        .publishUserServerList(serverUrlsOrdered: mergedUrls);
    throwIfBroadcastFailed(
      broadcastResponse,
      context: 'Blossom server list for $pubkey',
    );
    final successfulRelays = broadcastResponse
        .where((response) => response.broadcastSuccessful)
        .length;
    _logger.i(
      'Blossom server list publish finished for pubkey=$pubkey: '
      'servers=$mergedUrls, '
      'successfulRelays=$successfulRelays/${broadcastResponse.length}, '
      'responses=${formatBroadcastResponses(broadcastResponse)}',
    );

    // Force refresh the server list cache in NDK after publishing and verify
    // that the configured bootstrap servers are discoverable.
    final refreshedBlossomList = _normaliseServerUrls(
      await _ndk.blossomUserServerList.getUserServerList(pubkeys: [pubkey]),
    );
    final missingAfterPublish = bootstrapBlossomList
        .where((url) => !refreshedBlossomList.contains(url))
        .toList();

    if (missingAfterPublish.isEmpty) {
      _logger.i(
        'Blossom server list verified for pubkey=$pubkey: '
        'readback=$refreshedBlossomList',
      );
    } else {
      _logger.w(
        'Blossom server list readback is missing configured bootstrap servers '
        'for pubkey=$pubkey: missing=$missingAfterPublish, '
        'readback=$refreshedBlossomList',
      );
    }
  });

  List<String> _normaliseServerUrls(Iterable<String>? urls) {
    if (urls == null) return <String>[];
    return urls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();
  }

  // ---------------------------------------------------------------------------
  // NDK Blossom pass-through methods
  // ---------------------------------------------------------------------------

  /// Uploads a blob to the user's blossom servers.
  ///
  /// If [serverUrls] is null the user's published server list (kind 10063) is
  /// fetched automatically. See [Blossom.uploadBlob] for full docs.
  Future<List<BlobUploadResult>> uploadBlob({
    required Uint8List data,
    List<String>? serverUrls,
    String? contentType,
    UploadStrategy strategy = UploadStrategy.mirrorAfterSuccess,
    bool serverMediaOptimisation = false,
  }) => _logger.span('uploadBlob', () async {
    final fallbackBootstrap = _config.bootstrapBlossom
        .where((url) => url.trim().isNotEmpty)
        .toSet()
        .toList();
    final effectiveServerUrls =
        serverUrls ?? (fallbackBootstrap.isEmpty ? null : fallbackBootstrap);

    return _ndk.blossom.uploadBlob(
      data: data,
      serverUrls: effectiveServerUrls,
      contentType: contentType,
      strategy: strategy,
      serverMediaOptimisation: serverMediaOptimisation,
    );
  });

  /// Downloads a blob by SHA-256 hash from the user's blossom servers.
  ///
  /// See [Blossom.getBlob] for full docs.
  Future<BlobResponse> getBlob({
    required String sha256,
    bool useAuth = false,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
  }) {
    return _ndk.blossom.getBlob(
      sha256: sha256,
      useAuth: useAuth,
      serverUrls: serverUrls,
      pubkeyToFetchUserServerList: pubkeyToFetchUserServerList,
    );
  }

  /// Checks whether a blob exists on any server without downloading it.
  ///
  /// Returns the URL of one server that has the blob. See [Blossom.checkBlob].
  Future<String> checkBlob({
    required String sha256,
    bool useAuth = false,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
  }) {
    return _ndk.blossom.checkBlob(
      sha256: sha256,
      useAuth: useAuth,
      serverUrls: serverUrls,
      pubkeyToFetchUserServerList: pubkeyToFetchUserServerList,
    );
  }

  /// Downloads a blob as a stream, useful for large files like videos.
  ///
  /// See [Blossom.getBlobStream] for full docs.
  Future<Stream<BlobResponse>> getBlobStream({
    required String sha256,
    bool useAuth = false,
    List<String>? serverUrls,
    String? pubkeyToFetchUserServerList,
    int chunkSize = 1024 * 1024,
  }) {
    return _ndk.blossom.getBlobStream(
      sha256: sha256,
      useAuth: useAuth,
      serverUrls: serverUrls,
      pubkeyToFetchUserServerList: pubkeyToFetchUserServerList,
      chunkSize: chunkSize,
    );
  }

  /// Lists blobs uploaded by [pubkey].
  ///
  /// See [Blossom.listBlobs] for full docs.
  Future<List<BlobDescriptor>> listBlobs({
    required String pubkey,
    List<String>? serverUrls,
    bool useAuth = true,
    DateTime? since,
    DateTime? until,
  }) {
    return _ndk.blossom.listBlobs(
      pubkey: pubkey,
      serverUrls: serverUrls,
      useAuth: useAuth,
      since: since,
      until: until,
    );
  }

  /// Deletes a blob by SHA-256 hash from the user's blossom servers.
  ///
  /// See [Blossom.deleteBlob] for full docs.
  Future<List<BlobDeleteResult>> deleteBlob({
    required String sha256,
    List<String>? serverUrls,
  }) {
    return _ndk.blossom.deleteBlob(sha256: sha256, serverUrls: serverUrls);
  }

  /// Downloads a blob directly from the given [url] without blossom protocol.
  Future<BlobResponse> directDownload({required Uri url}) {
    return _ndk.blossom.directDownload(url: url);
  }

  /// Reports a blob to a blossom server (NIP-56).
  ///
  /// See [Blossom.report] for full docs.
  Future<int> report({
    required String sha256,
    required String eventId,
    required String reportType,
    required String reportMsg,
    required String serverUrl,
  }) {
    return _ndk.blossom.report(
      sha256: sha256,
      eventId: eventId,
      reportType: reportType,
      reportMsg: reportMsg,
      serverUrl: serverUrl,
    );
  }

  // ---------------------------------------------------------------------------
  // User Server List pass-through
  // ---------------------------------------------------------------------------

  /// Fetches the blossom server list for the given [pubkeys].
  Future<List<String>?> getUserServerList({required List<String> pubkeys}) {
    return _ndk.blossomUserServerList.getUserServerList(pubkeys: pubkeys);
  }

  /// Publishes a new blossom user server list (kind 10063).
  Future<List<RelayBroadcastResponse>> publishUserServerList({
    required List<String> serverUrlsOrdered,
  }) async {
    final responses = await _ndk.blossomUserServerList.publishUserServerList(
      serverUrlsOrdered: serverUrlsOrdered,
    );
    throwIfBroadcastFailed(responses, context: 'Blossom server list');
    return responses;
  }
}
