import 'dart:typed_data';

import 'package:hostr_sdk/config.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/domain_layer/repositories/blossom.dart' show UploadStrategy;
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart';

import '../../util/main.dart';

/// Wraps NDK's [Blossom] use case with hostr-specific conveniences such as
/// [ensureBlossomServer] which merges the user's existing server list with the
/// configured bootstrap servers.
@Singleton()
class BlossomUseCase {
  final Ndk _ndk;
  final HostrConfig _config;
  final CustomLogger logger;

  BlossomUseCase({
    required Ndk ndk,
    required HostrConfig config,
    required this.logger,
  }) : _ndk = ndk,
       _config = config;

  // ---------------------------------------------------------------------------
  // ensureBlossomServer
  // ---------------------------------------------------------------------------

  /// Fetches the current user's blossom server list, merges it with the
  /// configured [HostrConfig.bootstrapBlossom] servers, and publishes the
  /// combined list. This guarantees that the user always has at least the
  /// bootstrap servers in their published NIP-10063 list.
  Future<void> ensureBlossomServer(String pubkey) async {
    final blossomList = await _ndk.blossomUserServerList.getUserServerList(
      pubkeys: [pubkey],
    );
    logger.d('Blossom list: $blossomList');

    final broadcastResponse = await _ndk.blossomUserServerList
        .publishUserServerList(
          serverUrlsOrdered: {
            ...blossomList ?? [],
            ..._config.bootstrapBlossom,
          }.toList(),
        );
    logger.d(
      'Blossom list publish response: ${broadcastResponse[0].broadcastSuccessful}',
    );
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
  }) {
    return _ndk.blossom.uploadBlob(
      data: data,
      serverUrls: serverUrls,
      contentType: contentType,
      strategy: strategy,
      serverMediaOptimisation: serverMediaOptimisation,
    );
  }

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
  }) {
    return _ndk.blossomUserServerList.publishUserServerList(
      serverUrlsOrdered: serverUrlsOrdered,
    );
  }
}
