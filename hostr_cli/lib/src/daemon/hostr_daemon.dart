import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../actions/hostr_actions.dart';
import '../commands/session_command.dart' show buildNostrConnect;
import '../context/hostr_cli_context.dart';
import '../output/qr.dart';
import '../output/result.dart';
import 'cancellation.dart';
import 'listing_helpers.dart';

typedef HostrDaemonNotificationSink =
    void Function(String method, Map<String, Object?> params);

class HostrDaemon {
  HostrDaemon(this.context, {HostrDaemonNotificationSink? notifications})
    : _notifications = notifications,
      _signerNotifications = SignerRequestNotificationBridge(notifications);

  static const _publicActions = {
    'hostr.listings.search',
    'hostr.profile.lookup',
  };
  static const _escrowRole = 'escrow';

  final HostrCliRuntimeContext context;
  final HostrDaemonNotificationSink? _notifications;
  final SignerRequestNotificationBridge _signerNotifications;
  final Map<String, NostrConnect> _pendingNostrConnect = {};
  final Map<String, Future<Map<String, Object?>>> _pendingNostrConnectWaits =
      {};
  final Map<String, NostrConnect> _pendingOAuthNostrConnect = {};
  final Map<String, Future<HostrCliResult>> _pendingOAuthNostrConnectWaits = {};
  final Map<String, Future<void>> _sessionHydrations = {};

  Future<HostrCliResult> call({
    String? pubkey,
    required String action,
    required Map<String, dynamic> input,
    String? notificationToken,
    String? traceId,
    HostrCancellationToken? cancellationToken,
  }) async {
    return _guardAction(action, () async {
      cancellationToken?.throwIfCancelled();
      if (pubkey == null || pubkey.trim().isEmpty) {
        if (!_publicActions.contains(action)) {
          throw HostrCliException(
            'auth_required',
            'Action "$action" requires an authenticated Hostr MCP session.',
          );
        }
        final session = await context.runtime.foregroundSession();
        await session.ensureInitialized();
        return _callInitializedSession(
          tokenPubkey: '',
          session: session,
          action: action,
          input: input,
          notificationToken: notificationToken,
          traceId: traceId,
          cancellationToken: cancellationToken,
        );
      }

      final session = context.runtime.session(pubkey);
      await session.ensureInitialized();
      cancellationToken?.throwIfCancelled();
      return _callInitializedSession(
        tokenPubkey: pubkey,
        session: session,
        action: action,
        input: input,
        notificationToken: notificationToken,
        traceId: traceId,
        cancellationToken: cancellationToken,
      );
    }, traceId: traceId);
  }

  Future<HostrCliResult> callForeground({
    required String action,
    required Map<String, dynamic> input,
    String? notificationToken,
    String? traceId,
  }) async {
    return _guardAction(action, () async {
      final session = await context.runtime.foregroundSession();
      await session.ensureInitialized();
      final pubkey = session.auth.activePubkey;
      if (pubkey == null || pubkey.isEmpty) {
        throw HostrCliException(
          'auth_required',
          'Action "$action" requires an active Hostr session.',
        );
      }
      return _callInitializedSession(
        tokenPubkey: pubkey,
        session: session,
        action: action,
        input: input,
        notificationToken: notificationToken,
        traceId: traceId,
      );
    }, traceId: traceId);
  }

  HostrActionSpec _actionSpecOrThrow(String action) {
    try {
      return HostrActionCatalog.byId(action);
    } on ArgumentError {
      throw HostrCliException(
        'unknown_action',
        'Unknown Hostr daemon action "$action".',
        details: {
          'action': action,
          'availableActions': HostrActionCatalog.all
              .map((spec) => spec.id)
              .toList(),
        },
      );
    }
  }

  Future<HostrCliResult> _guardAction(
    String action,
    Future<HostrCliResult> Function() run, {
    String? traceId,
  }) async {
    try {
      return await TraceContext.run(traceId, run);
    } on HostrCliException catch (error) {
      return HostrCliResult(
        ok: false,
        command: action,
        environment: context.options.environment.name,
        dryRun: false,
        traceId: traceId,
        errors: [error.toIssue()],
      );
    } on HostrCancellationException catch (error) {
      return HostrCliResult(
        ok: false,
        command: action,
        environment: context.options.environment.name,
        dryRun: false,
        traceId: traceId,
        errors: [
          HostrCliIssue(
            code: 'request_cancelled',
            message: error.message,
            retryable: false,
          ),
        ],
      );
    } catch (error) {
      return HostrCliResult(
        ok: false,
        command: action,
        environment: context.options.environment.name,
        dryRun: false,
        traceId: traceId,
        errors: [
          HostrCliIssue(
            code: 'unexpected_error',
            message: error.toString(),
            retryable: false,
          ),
        ],
      );
    }
  }

  Future<HostrCliResult> _callInitializedSession({
    required String tokenPubkey,
    required HostrSession session,
    required String action,
    required Map<String, dynamic> input,
    String? notificationToken,
    String? traceId,
    HostrCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    final activePubkey = session.auth.activePubkey;
    if (activePubkey != null &&
        activePubkey.isNotEmpty &&
        !session.auth.needsBunkerRecovery &&
        await session.auth.isAuthenticated()) {
      unawaited(_ensureAuthenticatedSessionHydrated(session));
    }
    if (notificationToken != null &&
        notificationToken.trim().isNotEmpty &&
        activePubkey != null &&
        activePubkey.isNotEmpty) {
      _signerNotifications.attachSession(
        tokenPubkey: tokenPubkey,
        activePubkey: activePubkey,
        session: session,
      );
      _signerNotifications.addOperation(
        activePubkey: activePubkey,
        token: notificationToken,
        traceId: traceId,
      );
    }

    var keepNotificationOperation = false;
    try {
      final spec = _actionSpecOrThrow(action);
      if (spec.requiredRole == _escrowRole) {
        await _requireEscrowPubkey(tokenPubkey, session, action: spec.title);
      }
      final result = switch (action) {
        'hostr.session.status' => (
          dryRun: false,
          data: await _sessionStatus(
            tokenPubkey,
            session,
            HostrSessionStatusInput.fromJson(input),
          ),
        ),
        'hostr.session.connect' => (
          dryRun: false,
          data: await _sessionConnect(
            tokenPubkey,
            session,
            HostrSessionConnectInput.fromJson(input),
            cancellationToken: cancellationToken,
          ),
        ),
        'hostr.listings.search' => (
          dryRun: false,
          data: await _listingsSearch(
            session,
            HostrListingsSearchInput.fromJson(input),
          ),
        ),
        'hostr.listings.list' => (
          dryRun: false,
          data: await _listingsList(
            tokenPubkey,
            session,
            HostrListingsListInput.fromJson(input),
          ),
        ),
        'hostr.listings.create' => await () async {
          final createInput = HostrListingsCreateInput.fromJson(input);
          return (
            dryRun: createInput.dryRun,
            data: await _listingsCreate(tokenPubkey, session, createInput),
          );
        }(),
        'hostr.listings.edit' => await () async {
          final editInput = HostrListingsEditInput.fromJson(input);
          return (
            dryRun: editInput.dryRun,
            data: await _listingsEdit(tokenPubkey, session, editInput),
          );
        }(),
        'hostr.listings.availability' => (
          dryRun: false,
          data: await _listingsAvailability(
            session,
            HostrListingsAvailabilityInput.fromJson(input),
          ),
        ),
        'hostr.listings.reviews' => (
          dryRun: false,
          data: await _listingsReviews(
            session,
            HostrListingsAnchorsInput.fromJson(input),
          ),
        ),
        'hostr.listings.reservationGroups' => (
          dryRun: false,
          data: await _listingsReservationGroups(
            session,
            HostrListingsAnchorsInput.fromJson(input),
          ),
        ),
        'hostr.reservations.negotiateOffer' => await () async {
          final offerInput = HostrReservationsOfferInput.fromJson(input);
          return (
            dryRun: offerInput.dryRun,
            data: await _reservationsOffer(tokenPubkey, session, offerInput),
          );
        }(),
        'hostr.reservations.bookAndPay' => (
          dryRun: false,
          data: await _reservationsBookAndPay(
            tokenPubkey,
            session,
            HostrReservationBookAndPayInput.fromJson(input),
            notificationToken: notificationToken,
            traceId: traceId,
            cancellationToken: cancellationToken,
          ),
        ),
        'hostr.reservations.negotiateAccept' => await () async {
          final tradeInput = HostrReservationTradeInput.fromJson(input);
          return (
            dryRun: tradeInput.dryRun,
            data: await _reservationsOfferOrAccept(
              tokenPubkey,
              session,
              tradeInput,
              acceptLatest: true,
            ),
          );
        }(),
        'hostr.reservations.pay' => await () async {
          final payInput = HostrReservationPayInput.fromJson(input);
          return (
            dryRun: payInput.dryRun,
            data: await _reservationsPay(tokenPubkey, session, payInput),
          );
        }(),
        'hostr.reservations.commit' => await () async {
          final commitInput = HostrReservationCommitInput.fromJson(input);
          return (
            dryRun: commitInput.dryRun,
            data: await _reservationsCommit(tokenPubkey, session, commitInput),
          );
        }(),
        'hostr.reservations.cancel' => await () async {
          final tradeInput = HostrReservationTradeInput.fromJson(input);
          return (
            dryRun: tradeInput.dryRun,
            data: await _reservationsCancel(tokenPubkey, session, tradeInput),
          );
        }(),
        'hostr.updates' => (
          dryRun: false,
          data: await _updates(
            tokenPubkey,
            session,
            HostrUpdatesInput.fromJson(input),
          ),
        ),
        'hostr.reply' => await () async {
          final replyInput = HostrReplyInput.fromJson(input);
          return (
            dryRun: replyInput.dryRun,
            data: await _reply(tokenPubkey, session, replyInput),
          );
        }(),
        'hostr.thread.view' => (
          dryRun: false,
          data: await _threadView(
            tokenPubkey,
            session,
            HostrThreadViewInput.fromJson(input),
          ),
        ),
        'hostr.thread.message' => await () async {
          final messageInput = HostrThreadMessageInput.fromJson(input);
          return (
            dryRun: messageInput.dryRun,
            data: await _threadMessage(tokenPubkey, session, messageInput),
          );
        }(),
        'hostr.escrow.involve' => await () async {
          final involveInput = HostrEscrowInvolveInput.fromJson(input);
          return (
            dryRun: involveInput.dryRun,
            data: await _escrowInvolve(tokenPubkey, session, involveInput),
          );
        }(),
        'hostr.profile.show' => (
          dryRun: false,
          data: await _profileShow(tokenPubkey, session),
        ),
        'hostr.profile.lookup' => (
          dryRun: false,
          data: await _profileLookup(
            session,
            HostrProfileLookupInput.fromJson(input),
          ),
        ),
        'hostr.profile.edit' => await () async {
          final profileInput = HostrProfileEditInput.fromJson(input);
          return (
            dryRun: profileInput.dryRun,
            data: await _profileEdit(tokenPubkey, session, profileInput),
          );
        }(),
        'hostr.trips.list' => (
          dryRun: false,
          data: await _reservationCollection(
            tokenPubkey,
            session,
            HostrReservationCollectionInput.fromJson(input),
            mode: 'trips',
          ),
        ),
        'hostr.bookings.list' => (
          dryRun: false,
          data: await _reservationCollection(
            tokenPubkey,
            session,
            HostrReservationCollectionInput.fromJson(input),
            mode: 'bookings',
          ),
        ),
        'hostr.escrow.methods' => (
          dryRun: false,
          data: await _escrowMethods(
            tokenPubkey,
            session,
            HostrEscrowMethodsInput.fromJson(input),
          ),
        ),
        'hostr.escrow.service.list' => (
          dryRun: false,
          data: await _escrowServiceList(
            tokenPubkey,
            session,
            HostrEscrowServiceListInput.fromJson(input),
          ),
        ),
        'hostr.escrow.service.get' => (
          dryRun: false,
          data: await _escrowServiceGet(
            tokenPubkey,
            session,
            HostrEscrowServiceGetInput.fromJson(input),
          ),
        ),
        'hostr.escrow.service.update' => await () async {
          final updateInput = HostrEscrowServiceUpdateInput.fromJson(input);
          return (
            dryRun: updateInput.dryRun,
            data: await _escrowServiceUpdate(tokenPubkey, session, updateInput),
          );
        }(),
        'hostr.escrow.service.edit' => await () async {
          final updateInput = HostrEscrowServiceUpdateInput.fromJson(input);
          return (
            dryRun: updateInput.dryRun,
            data: await _escrowServiceUpdate(tokenPubkey, session, updateInput),
          );
        }(),
        'hostr.escrow.service.delete' => await () async {
          final deleteInput = HostrEscrowServiceDeleteInput.fromJson(input);
          return (
            dryRun: deleteInput.dryRun,
            data: await _escrowServiceDelete(tokenPubkey, session, deleteInput),
          );
        }(),
        'hostr.escrow.trades.list' => (
          dryRun: false,
          data: await _escrowTradesList(
            tokenPubkey,
            session,
            HostrEscrowTradesListInput.fromJson(input),
          ),
        ),
        'hostr.escrow.trades.view' => (
          dryRun: false,
          data: await _escrowTradeView(
            tokenPubkey,
            session,
            HostrEscrowTradeViewInput.fromJson(input),
          ),
        ),
        'hostr.escrow.trades.audit' => (
          dryRun: false,
          data: await _escrowTradeAudit(
            tokenPubkey,
            session,
            HostrEscrowTradeAuditInput.fromJson(input),
          ),
        ),
        'hostr.escrow.trades.arbitrate' => await () async {
          final arbitrateInput = HostrEscrowArbitrateInput.fromJson(input);
          return (
            dryRun: arbitrateInput.dryRun,
            data: await _escrowArbitrate(tokenPubkey, session, arbitrateInput),
          );
        }(),
        'hostr.escrow.badges.definitions.list' => (
          dryRun: false,
          data: await _escrowBadgeDefinitionsList(
            tokenPubkey,
            session,
            HostrEscrowBadgeDefinitionsListInput.fromJson(input),
          ),
        ),
        'hostr.escrow.badges.definitions.edit' => await () async {
          final badgeInput = HostrEscrowBadgeDefinitionEditInput.fromJson(
            input,
          );
          return (
            dryRun: badgeInput.dryRun,
            data: await _escrowBadgeDefinitionEdit(
              tokenPubkey,
              session,
              badgeInput,
            ),
          );
        }(),
        'hostr.escrow.badges.definitions.delete' => await () async {
          final badgeInput = HostrEscrowBadgeDefinitionDeleteInput.fromJson(
            input,
          );
          return (
            dryRun: badgeInput.dryRun,
            data: await _escrowBadgeDefinitionDelete(
              tokenPubkey,
              session,
              badgeInput,
            ),
          );
        }(),
        'hostr.escrow.badges.awards.list' => (
          dryRun: false,
          data: await _escrowBadgeAwardsList(
            tokenPubkey,
            session,
            HostrEscrowBadgeAwardsListInput.fromJson(input),
          ),
        ),
        'hostr.escrow.badges.award' => await () async {
          final badgeInput = HostrEscrowBadgeAwardInput.fromJson(input);
          return (
            dryRun: badgeInput.dryRun,
            data: await _escrowBadgeAward(tokenPubkey, session, badgeInput),
          );
        }(),
        'hostr.escrow.badges.revoke' => await () async {
          final badgeInput = HostrEscrowBadgeRevokeInput.fromJson(input);
          return (
            dryRun: badgeInput.dryRun,
            data: await _escrowBadgeRevoke(tokenPubkey, session, badgeInput),
          );
        }(),
        'hostr.swaps.watch' => await () async {
          final watchInput = HostrSwapsWatchInput.fromJson(input);
          return (
            dryRun: false,
            data: await _swapsWatch(
              tokenPubkey,
              session,
              watchInput,
              cancellationToken: cancellationToken,
            ),
          );
        }(),
        'hostr.swaps.recoverAll' => await () async {
          final recoverInput = HostrSwapsRecoverAllInput.fromJson(input);
          return (
            dryRun: recoverInput.dryRun,
            data: await _swapsRecoverAll(tokenPubkey, session, recoverInput),
          );
        }(),
        'hostr.swaps.list' => (
          dryRun: false,
          data: await _swapsList(
            tokenPubkey,
            session,
            HostrSwapsListInput.fromJson(input),
          ),
        ),
        _ => throw HostrCliException(
          'unknown_action',
          'Unknown Hostr daemon action "$action".',
          details: {
            'action': action,
            'availableActions': HostrActionCatalog.all
                .map((spec) => spec.id)
                .toList(),
          },
        ),
      };

      keepNotificationOperation =
          action == 'hostr.reservations.bookAndPay' &&
          result.data['continuesInBackground'] == true;

      return HostrCliResult(
        ok: true,
        command: action,
        environment: context.options.environment.name,
        dryRun: result.dryRun,
        traceId: traceId,
        data: result.data,
      );
    } catch (error, stackTrace) {
      final reconnect = await _staleSignerReconnectException(
        tokenPubkey,
        session,
        error,
      );
      if (reconnect != null) throw reconnect;
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      final activePubkey = session.auth.activePubkey;
      if (notificationToken != null &&
          notificationToken.trim().isNotEmpty &&
          activePubkey != null &&
          activePubkey.isNotEmpty &&
          !keepNotificationOperation) {
        _signerNotifications.removeOperation(
          activePubkey: activePubkey,
          token: notificationToken,
        );
      }
    }
  }

  Map<String, Object?> describe() => HostrActionCatalog.toJson();

  Map<String, Object?> visibleActions({String? pubkey}) {
    final escrowPubkeys = _configuredEscrowPubkeys();
    final isEscrow = _isConfiguredEscrowPubkey(pubkey);
    final actions = HostrActionCatalog.all
        .where(
          (spec) =>
              spec.requiredRole == null ||
              spec.requiredRole != _escrowRole ||
              isEscrow,
        )
        .toList();
    return {
      'version': 1,
      'pubkey': pubkey,
      'isEscrow': isEscrow,
      'escrowPubkeys': escrowPubkeys,
      'visibleActionIds': actions.map((spec) => spec.id).toList(),
      'actions': actions.map((spec) => spec.toJson()).toList(),
    };
  }

  Future<HostrCliResult> uploadImage({
    String? pubkey,
    required String base64,
    String? mime,
    String? filename,
    String? traceId,
    HostrCancellationToken? cancellationToken,
  }) async {
    return _guardAction('hostr.upload.image', () async {
      cancellationToken?.throwIfCancelled();
      late final Uint8List bytes;
      try {
        bytes = base64Decode(base64.replaceAll(RegExp(r'\s+'), ''));
      } on FormatException catch (error) {
        throw HostrCliException(
          'invalid_upload_base64',
          'Uploaded image base64 data is invalid: ${error.message}',
          path: 'base64',
          exitCode: 64,
        );
      }
      if (bytes.isEmpty) {
        throw HostrCliException(
          'invalid_upload',
          'Uploaded image is empty.',
          path: 'file',
          exitCode: 64,
        );
      }

      final upload =
          await _tryUploadImageWithSessionAuth(
            pubkey: pubkey,
            bytes: bytes,
            mime: mime,
          ) ??
          await _uploadImageWithoutAuth(
            bytes: bytes,
            mime: mime,
            filename: filename,
            traceId: traceId,
          );
      if (upload == null) {
        throw HostrCliException(
          'image_upload_failed',
          'Blossom upload failed on every configured bootstrap server.',
        );
      }

      return HostrCliResult(
        ok: true,
        command: 'hostr.upload.image',
        environment: context.options.environment.name,
        dryRun: false,
        traceId: traceId,
        data: {
          ...upload,
          'sha256': upload['sha256'] ?? crypto.sha256.convert(bytes).toString(),
          'size': upload['size'] ?? bytes.length,
          'type': upload['type'] ?? mime,
          if (filename != null && filename.trim().isNotEmpty)
            'filename': filename,
        },
      );
    }, traceId: traceId);
  }

  Future<Map<String, Object?>?> _tryUploadImageWithSessionAuth({
    required String? pubkey,
    required Uint8List bytes,
    String? mime,
  }) async {
    final tokenPubkey = pubkey?.trim();
    if (tokenPubkey == null || tokenPubkey.isEmpty) {
      return null;
    }

    try {
      final session = context.runtime.session(tokenPubkey);
      await session.ensureInitialized();
      final activePubkey = session.auth.activePubkey;
      if (activePubkey != tokenPubkey ||
          session.auth.needsBunkerRecovery ||
          !await session.auth.isAuthenticated()) {
        return null;
      }

      final uploadResults = await session.hostr.blossom.uploadBlob(
        data: bytes,
        contentType: mime,
      );
      final success = uploadResults
          .where((result) => result.success && result.descriptor != null)
          .firstOrNull;
      final descriptor = success?.descriptor;
      if (descriptor == null) {
        return null;
      }
      return {
        'url': descriptor.url,
        'sha256': descriptor.sha256,
        'size': descriptor.size,
        'type': descriptor.type ?? mime,
        if (success?.serverUrl != null) 'serverUrl': success!.serverUrl,
        'auth': 'session',
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, Object?>?> _uploadImageWithoutAuth({
    required Uint8List bytes,
    String? mime,
    String? filename,
    String? traceId,
  }) async {
    final servers = context.options.environment.bootstrapBlossom
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toList();
    if (servers.isEmpty) {
      throw HostrCliException(
        'image_upload_failed',
        'No Blossom bootstrap server is configured.',
      );
    }
    final hash = crypto.sha256.convert(bytes).toString();
    final failures = <Map<String, Object?>>[];
    for (final server in servers) {
      final uri = _blossomUploadUri(server);
      final client = HttpClient();
      try {
        final request = await client.putUrl(uri);
        request.headers.contentType = ContentType.parse(
          mime ?? 'application/octet-stream',
        );
        request.headers.contentLength = bytes.length;
        request.headers.set('x-sha-256', hash);
        if (traceId != null && traceId.trim().isNotEmpty) {
          request.headers.set('x-trace-id', traceId);
        }
        if (filename != null && filename.trim().isNotEmpty) {
          request.headers.set('x-filename', filename);
        }
        request.add(bytes);
        final response = await request.close();
        final body = await utf8.decodeStream(response);
        Object? decoded;
        if (body.trim().isNotEmpty) {
          try {
            decoded = jsonDecode(body);
          } on FormatException {
            decoded = body;
          }
        }
        if (response.statusCode >= 200 &&
            response.statusCode < 300 &&
            decoded is Map) {
          return {
            for (final entry in decoded.entries)
              entry.key.toString(): entry.value,
            'serverUrl': uri.toString(),
          };
        }
        failures.add({
          'serverUrl': uri.toString(),
          'statusCode': response.statusCode,
          'body': decoded,
        });
      } catch (error) {
        failures.add({'serverUrl': uri.toString(), 'error': error.toString()});
      } finally {
        client.close(force: true);
      }
    }
    throw HostrCliException(
      'image_upload_failed',
      'Blossom upload failed on every configured bootstrap server.',
      details: failures,
    );
  }

  List<String> _configuredEscrowPubkeys() =>
      context.options.environment.bootstrapEscrowPubkeys
          .map((pubkey) => pubkey.trim().toLowerCase())
          .where((pubkey) => pubkey.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

  bool _isConfiguredEscrowPubkey(String? pubkey) {
    final normalized = pubkey?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return _configuredEscrowPubkeys().contains(normalized);
  }

  Future<void> _requireEscrowPubkey(
    String tokenPubkey,
    HostrSession session, {
    required String action,
  }) async {
    await _requireAuthenticatedPubkey(tokenPubkey, session, action: action);
    final active = session.auth.activePubkey?.trim().toLowerCase();
    final token = tokenPubkey.trim().toLowerCase();
    if (!_isConfiguredEscrowPubkey(token) ||
        active == null ||
        active.isEmpty ||
        active != token) {
      throw HostrCliException(
        'escrow_role_required',
        '$action requires an authenticated Hostr escrow pubkey.',
        details: {
          'pubkey': tokenPubkey,
          'escrowPubkeys': _configuredEscrowPubkeys(),
        },
      );
    }
  }

  Future<HostrCliResult> startOAuthNostrConnect({
    required String requestId,
    bool regenerate = false,
    String? traceId,
    HostrCancellationToken? cancellationToken,
  }) async {
    try {
      cancellationToken?.throwIfCancelled();
      if (regenerate) {
        _pendingOAuthNostrConnect.remove(requestId);
        _pendingOAuthNostrConnectWaits.remove(requestId);
      }

      var nostrConnect = _pendingOAuthNostrConnect[requestId];
      if (nostrConnect == null) {
        final session = await context.runtime.foregroundSession();
        await session.ensureInitialized();
        nostrConnect = _buildMcpNostrConnect(session);
        if (nostrConnect == null) {
          throw HostrCliException(
            'relay_required',
            'No Hostr relay is configured.',
          );
        }
        _pendingOAuthNostrConnect[requestId] = nostrConnect;
      }
      _pendingOAuthNostrConnectWaits.putIfAbsent(
        requestId,
        () => _completeOAuthNostrConnectInternal(
          requestId: requestId,
          nostrConnect: nostrConnect!,
          traceId: traceId,
        ),
      );

      return HostrCliResult(
        ok: true,
        command: 'oauth.nostr_connect.start',
        environment: context.options.environment.name,
        dryRun: false,
        traceId: traceId,
        data: {
          'requestId': requestId,
          'pending': true,
          ..._nostrConnectJson(nostrConnect),
        },
      );
    } on HostrCliException catch (error) {
      return HostrCliResult(
        ok: false,
        command: 'oauth.nostr_connect.start',
        environment: context.options.environment.name,
        dryRun: false,
        traceId: traceId,
        errors: [error.toIssue()],
      );
    } catch (error) {
      return HostrCliResult(
        ok: false,
        command: 'oauth.nostr_connect.start',
        environment: context.options.environment.name,
        dryRun: false,
        traceId: traceId,
        errors: [
          HostrCliIssue(
            code: 'unexpected_error',
            message: error.toString(),
            retryable: false,
          ),
        ],
      );
    }
  }

  Future<HostrCliResult> completeOAuthNostrConnect({
    required String requestId,
    required int timeoutSeconds,
    String? traceId,
    HostrCancellationToken? cancellationToken,
  }) async {
    try {
      cancellationToken?.throwIfCancelled();
      final nostrConnect = _pendingOAuthNostrConnect[requestId];
      if (nostrConnect == null) {
        throw HostrCliException(
          'unknown_oauth_request',
          'Unknown or expired OAuth Nostr Connect request.',
        );
      }

      final future = _pendingOAuthNostrConnectWaits.putIfAbsent(
        requestId,
        () => _completeOAuthNostrConnectInternal(
          requestId: requestId,
          nostrConnect: nostrConnect,
          traceId: traceId,
        ),
      );
      return await _cancelable(
        future.timeout(Duration(seconds: timeoutSeconds.clamp(1, 600).toInt())),
        cancellationToken,
      );
    } on TimeoutException {
      return HostrCliResult(
        ok: false,
        command: 'oauth.nostr_connect.complete',
        environment: context.options.environment.name,
        dryRun: false,
        traceId: traceId,
        errors: [
          HostrCliIssue(
            code: 'nostr_connect_timeout',
            message: 'Timed out waiting for Nostr Connect approval.',
            retryable: true,
          ),
        ],
      );
    } on HostrCliException catch (error) {
      return HostrCliResult(
        ok: false,
        command: 'oauth.nostr_connect.complete',
        environment: context.options.environment.name,
        dryRun: false,
        traceId: traceId,
        errors: [error.toIssue()],
      );
    } catch (error) {
      return HostrCliResult(
        ok: false,
        command: 'oauth.nostr_connect.complete',
        environment: context.options.environment.name,
        dryRun: false,
        traceId: traceId,
        errors: [
          HostrCliIssue(
            code: 'unexpected_error',
            message: error.toString(),
            retryable: false,
          ),
        ],
      );
    }
  }

  Future<HostrCliResult> _completeOAuthNostrConnectInternal({
    required String requestId,
    required NostrConnect nostrConnect,
    String? traceId,
  }) async {
    return TraceContext.run(traceId, () async {
      try {
        final foreground = await context.runtime.foregroundSession();
        await foreground.ensureInitialized();
        await foreground.auth.signinWithNostrConnect(nostrConnect);

        final pubkey = foreground.auth.activePubkey;
        final bunkerConnection = foreground.auth.activeBunkerConnection;
        if (pubkey == null || pubkey.isEmpty || bunkerConnection == null) {
          throw HostrCliException(
            'nostr_connect_incomplete',
            'Nostr Connect did not return a pubkey and bunker connection.',
          );
        }

        final session = context.runtime.session(pubkey);
        await session.ensureInitialized();
        await session.auth.signinWithBunkerConnection(bunkerConnection);
        unawaited(_ensureAuthenticatedSessionHydrated(session));
        await foreground.auth.logout();
        _pendingOAuthNostrConnect.remove(requestId);
        _pendingOAuthNostrConnectWaits.remove(requestId);

        return HostrCliResult(
          ok: true,
          command: 'oauth.nostr_connect.complete',
          environment: context.options.environment.name,
          dryRun: false,
          traceId: traceId,
          data: {
            'authenticated': true,
            'pubkey': pubkey,
            'credentialType': 'bunker',
          },
        );
      } catch (_) {
        _pendingOAuthNostrConnectWaits.remove(requestId);
        rethrow;
      }
    });
  }

  Future<Map<String, Object?>> _sessionStatus(
    String tokenPubkey,
    HostrSession session,
    HostrSessionStatusInput input,
  ) async {
    final activePubkey = session.auth.activePubkey;
    final authenticated = await session.auth.isAuthenticated();
    final needsReconnect =
        session.auth.needsBunkerRecovery &&
        !await session.auth.retryBunkerSessionRestore();
    return {
      'tokenPubkey': tokenPubkey,
      'sessionPubkey': session.pubkey,
      'activePubkey': activePubkey,
      'authenticated': authenticated,
      'signerOnline': authenticated && !needsReconnect,
      if (input.includeStorageDetails)
        'storage': {'scope': 'hostr-session/$tokenPubkey', 'isolated': true},
      if (needsReconnect) 'reconnect': _sessionReconnectHint(tokenPubkey),
    };
  }

  Future<Map<String, Object?>> _sessionConnect(
    String tokenPubkey,
    HostrSession session,
    HostrSessionConnectInput input, {
    HostrCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    if (await session.auth.isAuthenticated() &&
        !session.auth.needsBunkerRecovery &&
        session.auth.activePubkey == tokenPubkey) {
      return {
        'authenticated': true,
        'pubkey': tokenPubkey,
        'credentialType': session.auth.isBunkerBacked
            ? 'bunker'
            : session.auth.isMnemonicBacked
            ? 'mnemonic'
            : session.auth.hasLocalPrivateKey
            ? 'private_key'
            : 'unknown',
      };
    }

    if (input.regenerate) {
      _pendingNostrConnect.remove(tokenPubkey);
      _pendingNostrConnectWaits.remove(tokenPubkey);
    }

    var nostrConnect = _pendingNostrConnect[tokenPubkey];
    if (nostrConnect == null) {
      nostrConnect = _buildMcpNostrConnect(session);
      if (nostrConnect == null) {
        throw HostrCliException(
          'relay_required',
          'No Hostr relay is configured.',
        );
      }
      _pendingNostrConnect[tokenPubkey] = nostrConnect;
    }
    final waitFuture = _pendingNostrConnectWaits.putIfAbsent(
      tokenPubkey,
      () => _completeSessionNostrConnect(
        tokenPubkey: tokenPubkey,
        session: session,
        nostrConnect: nostrConnect!,
      ),
    );

    if (!input.wait) {
      return {
        'authenticated': false,
        'pending': true,
        'displayTitle': 'Log in to Hostr',
        'displayMessage':
            'Scan this with your Nostr app to log in to your Hostr account.',
        ..._nostrConnectJson(nostrConnect),
        'nextInput': {'wait': true, 'regenerate': false},
        'nextStep':
            'Show the QR or nostrconnect URI to the user, then immediately call hostr_session_connect with wait true to listen for the session connection. After it connects, continue the Hostr action that required sign-in.',
        'assistantInstructions': [
          'Show the QR/URI with the text: "Scan this with your Nostr app to log in to your Hostr account."',
          'Do not stop after displaying the QR. Immediately call hostr_session_connect with wait=true and regenerate=false to listen for the session connection.',
          'After hostr_session_connect returns authenticated=true, retry or continue the Hostr action that required sign-in.',
        ],
      };
    }

    return _cancelable(
      waitFuture.timeout(Duration(seconds: input.timeoutSeconds)),
      cancellationToken,
    );
  }

  Future<Map<String, Object?>> _completeSessionNostrConnect({
    required String tokenPubkey,
    required HostrSession session,
    required NostrConnect nostrConnect,
  }) async {
    try {
      await session.auth.signinWithNostrConnect(nostrConnect);
    } catch (_) {
      _pendingNostrConnectWaits.remove(tokenPubkey);
      rethrow;
    }
    final activePubkey = session.auth.activePubkey;
    if (activePubkey != tokenPubkey) {
      _pendingNostrConnect.remove(tokenPubkey);
      _pendingNostrConnectWaits.remove(tokenPubkey);
      await session.auth.logout();
      throw HostrCliException(
        'session_pubkey_mismatch',
        'The approved Nostr Connect signer pubkey does not match the MCP access token pubkey.',
        details: {'tokenPubkey': tokenPubkey, 'activePubkey': activePubkey},
      );
    }

    _pendingNostrConnect.remove(tokenPubkey);
    _pendingNostrConnectWaits.remove(tokenPubkey);
    unawaited(_ensureAuthenticatedSessionHydrated(session));
    return {
      'authenticated': true,
      'pubkey': activePubkey,
      'credentialType': 'bunker',
    };
  }

  Future<void> _ensureAuthenticatedSessionHydrated(
    HostrSession session, {
    bool wait = false,
  }) async {
    final activePubkey = session.auth.activePubkey;
    if (activePubkey == null || activePubkey.isEmpty) return;
    if (session.auth.needsBunkerRecovery ||
        !await session.auth.isAuthenticated()) {
      return;
    }

    final future = _sessionHydrations.putIfAbsent(activePubkey, () async {
      try {
        await session.userSubscriptions.start();
        await Future.wait([
          _waitForStreamStatus(session.userSubscriptions.giftwraps$.status),
          _waitForStreamStatus(
            session.userSubscriptions.allMyReservations$.stream.status,
          ),
        ]);
        if (_isConfiguredEscrowPubkey(activePubkey)) {
          await _escrowToolContext(session);
        }
      } catch (_) {
        _sessionHydrations.remove(activePubkey);
        rethrow;
      }
    });

    if (wait) {
      await future;
    } else {
      unawaited(future.catchError((_) {}));
    }
  }

  Future<Map<String, Object?>> _listingsSearch(
    HostrSession session,
    HostrListingsSearchInput input,
  ) async {
    final builder = Listing.buildFilter();
    if (input.type != null) {
      builder.listingTypes([_listingType(input.type!)]);
    }
    if (input.guests != null) builder.minGuests(input.guests!);
    if (input.features.isNotEmpty) builder.features(input.features);
    if (input.location != null) {
      final polygon = await session.location.polygon(
        input.location!,
        featureTypes: const {'country', 'state', 'region', 'city', 'town'},
      );
      final h3 = H3Engine.bundled();
      final tags = await h3.polygonCover.fromGeoJsonTagsInBackground(
        geoJson: polygon.geoJson,
        maxH3Tags: 30,
      );
      builder.rawTags({'g': tags.map((tag) => tag.index).toList()});
    }

    var listings = await session.listings.list(
      builder.build()..limit = input.query != null ? 500 : input.limit,
      name: 'mcp-search',
    );
    if (input.query != null) {
      final needle = input.query!.toLowerCase();
      listings = listings
          .where(
            (listing) =>
                listing.title.toLowerCase().contains(needle) ||
                listing.description.toLowerCase().contains(needle),
          )
          .toList();
    }
    listings = listings.take(input.limit).toList();
    return {
      'count': listings.length,
      'listings': listings.map(listingSummary).toList(),
    };
  }

  Future<Map<String, Object?>> _listingsList(
    String tokenPubkey,
    HostrSession session,
    HostrListingsListInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Listings list',
    );
    final pubkey = input.mine ? tokenPubkey : input.author;
    final listings = await session.listings.list(
      Filter(authors: pubkey == null ? null : [pubkey], limit: input.limit),
      name: 'hostr-listings-list',
    );
    return {
      'count': listings.length,
      'listings': listings.map(listingSummary).toList(),
    };
  }

  Future<Map<String, Object?>> _listingsCreate(
    String tokenPubkey,
    HostrSession session,
    HostrListingsCreateInput input,
  ) async {
    final activePubkey = await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Listing creation',
    );
    final hostr = session.hostr;
    final listingInput = input.toListingJson();

    if (!input.dryRun) {
      await session.accountSeedStore.ensureReady();
      await session.metadata.ensureSellerConfig(activePubkey);
    }

    final materialized = await materializeListingImages(
      hostr: hostr,
      rawImages: listingInput['images'] as List<dynamic>,
      dryRun: false,
    );
    final h3Tags = await addressH3Tags(hostr, listingInput);
    final listing = buildListingFromInput(
      pubkey: activePubkey,
      input: listingInput,
      images: materialized.urls,
      imageMetas: materialized.metas,
      h3Tags: h3Tags,
    );
    final dTag = listing.getFirstTag('d');

    if (input.dryRun) {
      return {
        'dryRun': true,
        'dTag': dTag,
        'nextInput': {'dryRun': false, 'dTag': dTag},
        'assistantInstructions': [
          'When the user approves this preview, call hostr_listings_create again with dryRun=false and this exact dTag. Do not omit or change dTag; preview, publish, and retries must target the same replaceable listing.',
        ],
        'plannedUploads': materialized.plannedUploads,
        'event': eventJson(listing),
        'listing': listingSummary(listing),
      };
    }

    final result = await session.listings.upsert(listing);
    final published = result.event;
    return {
      'dryRun': false,
      'dTag': dTag,
      'event': eventJson(published),
      'listing': listingSummary(published),
      'relayResponses': result.responses.map(relayResponseJson).toList(),
    };
  }

  Future<Map<String, Object?>> _listingsEdit(
    String tokenPubkey,
    HostrSession session,
    HostrListingsEditInput input,
  ) async {
    final activePubkey = await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Listing edit',
    );
    final hostr = session.hostr;
    final existing = await hostr.listings.getOneByAnchor(input.anchor);
    if (existing == null) {
      throw HostrCliException(
        'not_found',
        'Listing not found.',
        details: {'anchor': input.anchor},
      );
    }
    if (existing.pubKey != activePubkey) {
      throw HostrCliException(
        'not_author',
        'Active session does not author this listing.',
      );
    }

    final patch = input.patch;
    if (!input.dryRun) {
      await session.accountSeedStore.ensureReady();
      await session.metadata.ensureSellerConfig(activePubkey);
    }

    final materialized = patch.containsKey('images')
        ? await materializeListingImages(
            hostr: hostr,
            rawImages: patch['images'] is List
                ? patch['images'] as List<dynamic>
                : [patch['images']],
            dryRun: input.dryRun,
          )
        : null;
    final h3Tags = patch.containsKey('address')
        ? await addressH3Tags(hostr, patch)
        : null;
    final patchPrices =
        patch.containsKey('prices') || patch.containsKey('price')
        ? parsePrices(patch)
        : null;
    final monetary = <DenominatedAmount>[
      if (patchPrices != null) ...patchPrices.map((price) => price.amount),
      if (patch.containsKey('securityDeposit'))
        parseOptionalAmount(patch['securityDeposit'], 'securityDeposit')!,
      if (patch.containsKey('minPaymentAmount'))
        parseOptionalAmount(patch['minPaymentAmount'], 'minPaymentAmount')!,
    ];
    assertSingleDenomination(monetary);

    final updated = existing.rebuild(
      title: patch['title']?.toString(),
      description: patch['description']?.toString(),
      type: patch['type'] == null
          ? null
          : _listingType(patch['type'].toString()),
      quantity: _optionalInt(patch['quantity']),
      active: _optionalBool(patch['active']),
      negotiable: _optionalBool(patch['negotiable']),
      instantBook: _optionalBool(patch['instantBook']),
      prices: patchPrices,
      images: materialized?.urls,
      imageMetas: materialized?.metas,
      securityDeposit: patch.containsKey('securityDeposit')
          ? parseOptionalAmount(patch['securityDeposit'], 'securityDeposit')
          : null,
      clearSecurityDeposit:
          patch['securityDeposit'] == null &&
          patch.containsKey('securityDeposit'),
      minPaymentAmount: patch.containsKey('minPaymentAmount')
          ? parseOptionalAmount(patch['minPaymentAmount'], 'minPaymentAmount')
          : null,
      clearMinPaymentAmount:
          patch['minPaymentAmount'] == null &&
          patch.containsKey('minPaymentAmount'),
      specifications: patch['specifications'] is Map || patch['specs'] is Map
          ? buildSpecifications(patch)
          : null,
      extraTags: h3Tags?.map((tag) => ['g', tag.index]).toList(),
    );

    if (input.dryRun) {
      return {
        'dryRun': true,
        'plannedUploads': materialized?.plannedUploads ?? const [],
        'event': eventJson(updated),
        'listing': listingSummary(updated),
      };
    }

    final result = await session.listings.upsert(updated);
    final published = result.event;
    return {
      'dryRun': false,
      'event': eventJson(published),
      'listing': listingSummary(published),
      'relayResponses': result.responses.map(relayResponseJson).toList(),
    };
  }

  Future<Map<String, Object?>> _listingsAvailability(
    HostrSession session,
    HostrListingsAvailabilityInput input,
  ) async {
    final results = <Map<String, Object?>>[];
    for (final anchor in input.anchors) {
      final listing = await session.listings.getOneByAnchor(anchor);
      if (listing == null) {
        results.add({'anchor': anchor, 'found': false, 'available': false});
        continue;
      }
      final groups = await session.reservations.queryReservationGroups(
        listing: listing,
      );
      results.add({
        'anchor': anchor,
        'found': true,
        'available': Listing.isAvailable(
          input.start,
          input.end,
          groups.values.toList(),
        ),
        'listing': listingSummary(listing),
        'reservationGroupCount': groups.length,
      });
    }
    return {'results': results};
  }

  Future<Map<String, Object?>> _listingsReviews(
    HostrSession session,
    HostrListingsAnchorsInput input,
  ) async {
    final results = <Map<String, Object?>>[];
    for (final anchor in input.anchors) {
      final events = await session.reviews.findByTag(kListingRefTag, anchor);
      results.add({
        'anchor': anchor,
        'count': events.length,
        'events': events.take(input.limit).map(eventJson).toList(),
      });
    }
    return {'tag': kListingRefTag, 'results': results};
  }

  Future<Map<String, Object?>> _listingsReservationGroups(
    HostrSession session,
    HostrListingsAnchorsInput input,
  ) async {
    final results = <Map<String, Object?>>[];
    for (final anchor in input.anchors) {
      final listing = await session.listings.getOneByAnchor(anchor);
      if (listing == null) {
        results.add({'anchor': anchor, 'found': false, 'count': 0});
        continue;
      }
      final groups = await session.reservations.queryReservationGroups(
        listing: listing,
      );
      results.add({
        'anchor': anchor,
        'found': true,
        'count': groups.length,
        'groups': groups.values
            .take(input.limit)
            .map(_reservationGroupJson)
            .toList(),
      });
    }
    return {'results': results};
  }

  Future<Map<String, Object?>> _reservationsOffer(
    String tokenPubkey,
    HostrSession session,
    HostrReservationsOfferInput input,
  ) async {
    if (input.isFollowUpOffer) {
      return _reservationsOfferOrAccept(
        tokenPubkey,
        session,
        HostrReservationTradeInput(
          tradeId: input.tradeId!,
          amount: input.amount,
          dryRun: input.dryRun,
          timeoutSeconds: input.timeoutSeconds,
        ),
        acceptLatest: false,
      );
    }
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Reservation offer',
    );

    await session.accountSeedStore.ensureReady();
    final listing = await session.listings.getOneByAnchor(input.listingAnchor!);
    if (listing == null) {
      throw HostrCliException(
        'listing_not_found',
        'Listing not found.',
        details: {'anchor': input.listingAnchor},
      );
    }
    final groups = await session.reservations.queryReservationGroups(
      listing: listing,
    );
    if (!Listing.isAvailable(
      input.start!,
      input.end!,
      groups.values.toList(),
    )) {
      throw HostrCliException(
        'listing_unavailable',
        'Listing is not available for those dates.',
        details: {
          'anchor': input.listingAnchor,
          'start': input.start!.toUtc().toIso8601String(),
          'end': input.end!.toUtc().toIso8601String(),
        },
      );
    }

    final reservation = await session.reservationRequests
        .createReservationRequest(
          listing: listing,
          startDate: input.start!,
          endDate: input.end!,
          amount: input.amount == null
              ? null
              : parseAmount(input.amount!.toJson(), 'amount'),
        );
    if (!input.dryRun) {
      final responses = await _replyReservationInTradeThread(
        session.hostr,
        reservation,
        participants: [listing.pubKey],
      );
      await _persistTradeContext(
        session.hostr,
        tradeId: reservation.getDtag()!,
        listingAnchor: listing.anchor!,
        sellerPubkey: listing.pubKey,
        reservation: reservation,
      );
      return {
        'dryRun': false,
        'delivery': 'giftwrap',
        'event': eventJson(reservation),
        'tradeId': reservation.getDtag(),
        'tradeContext': _tradeContextJson(
          tradeId: reservation.getDtag()!,
          listing: listing,
          reservation: reservation,
        ),
        'relayResponses': responses,
      };
    }

    return {
      'dryRun': true,
      'delivery': 'giftwrap',
      'event': eventJson(reservation),
      'tradeId': reservation.getDtag(),
      'tradeContext': _tradeContextJson(
        tradeId: reservation.getDtag()!,
        listing: listing,
        reservation: reservation,
      ),
      'listing': listingSummary(listing),
      if (input.amount != null)
        'amount': amountJson(parseAmount(input.amount!.toJson(), 'amount')),
    };
  }

  Future<Map<String, Object?>> _reservationsBookAndPay(
    String tokenPubkey,
    HostrSession session,
    HostrReservationBookAndPayInput input, {
    String? notificationToken,
    String? traceId,
    HostrCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Book and pay reservation',
    );
    final operation = BookAndPayOperation(
      accountSeedStore: session.accountSeedStore,
      auth: session.auth,
      listings: session.listings,
      reservations: session.reservations,
      reservationRequests: session.reservationRequests,
      messaging: session.messaging,
      escrow: session.escrow,
      escrows: session.escrows,
      identityClaims: session.identityClaims,
      metadata: session.metadata,
      evm: session.evm,
      userSubscriptions: session.userSubscriptions,
      paymentProofOrchestrator: session.paymentProofOrchestrator,
      logger: session.hostr.logger,
    );
    final states = <Map<String, Object?>>[];
    final handoff = Completer<Map<String, Object?>>();
    final terminal = Completer<Map<String, Object?>>();
    final sub = operation.stream.listen((state) {
      final json = _augmentBookAndPayStateJson(state.toJson());
      states.add(json);
      _notifications?.call('hostr.booking.state', {
        'operationToken': notificationToken,
        'traceId': ?traceId,
        ...json,
      });
      if (!handoff.isCompleted && json['externalPayment'] is Map) {
        handoff.complete(json);
      }
    });

    var cleanedUp = false;
    Future<void> cleanup() async {
      if (cleanedUp) return;
      cleanedUp = true;
      await sub.cancel();
      await operation.close();
      final activePubkey = session.auth.activePubkey;
      if (notificationToken != null &&
          notificationToken.trim().isNotEmpty &&
          activePubkey != null &&
          activePubkey.isNotEmpty) {
        _signerNotifications.removeOperation(
          activePubkey: activePubkey,
          token: notificationToken,
        );
      }
    }

    cancellationToken?.onCancel(() {
      final error = const HostrCancellationException();
      if (!handoff.isCompleted) {
        handoff.completeError(error);
      }
      if (!terminal.isCompleted) {
        terminal.completeError(error);
      }
      unawaited(cleanup());
    });

    unawaited(() async {
      try {
        await operation.execute(
          BookAndPayInput(
            listingAnchor: input.listingAnchor,
            start: input.start,
            end: input.end,
            amount: input.amount == null
                ? null
                : parseAmount(input.amount!.toJson(), 'amount'),
            escrowServiceId: input.escrowServiceId,
            proofTimeout: Duration(seconds: input.proofTimeoutSeconds),
          ),
        );
        final finalState = operation.state;
        final finalJson = _augmentBookAndPayStateJson(finalState.toJson());
        if (finalState is BookAndPayFailed) {
          throw HostrCliException(
            'book_and_pay_failed',
            finalState.error,
            details: finalJson,
          );
        }
        if (!terminal.isCompleted) {
          terminal.complete({
            'mode': 'book-and-pay',
            'state': finalJson,
            'states': List<Map<String, Object?>>.from(states),
            'continuesInBackground': false,
          });
        }
      } catch (error, stackTrace) {
        if (!terminal.isCompleted) {
          terminal.completeError(error, stackTrace);
        }
        if (!handoff.isCompleted) {
          handoff.completeError(error, stackTrace);
        }
      } finally {
        await cleanup();
      }
    }());

    late final Map<String, Object?> result;
    try {
      result = await _cancelable(
        Future.any<Map<String, Object?>>([
          handoff.future.then((state) {
            final externalPayment = state['externalPayment'];
            final externalPaymentJson = externalPayment is Map
                ? Map<String, Object?>.from(externalPayment)
                : <String, Object?>{};
            final swapId =
                externalPaymentJson['swapId']?.toString() ??
                state['swapId']?.toString();
            final tradeId =
                externalPaymentJson['tradeId']?.toString() ??
                state['tradeId']?.toString();
            return {
              'mode': 'book-and-pay',
              'state': state,
              'states': List<Map<String, Object?>>.from(states),
              'externalPayment': externalPaymentJson,
              'continuesInBackground': true,
              'nextTool': {
                'name': 'hostr_swaps_watch',
                'arguments': {
                  if (swapId != null && swapId.isNotEmpty) 'swapId': swapId,
                  if (tradeId != null && tradeId.isNotEmpty) 'tradeId': tradeId,
                  'reservationWaitSeconds': input.proofTimeoutSeconds,
                },
              },
              'nextStep':
                  'CRITICAL: keep only the Lightning invoice QR image and invoice text visible in the user-facing answer. Do not show the internal trade id or swap id in the payment prompt. The next assistant action after rendering that visible payment prompt must be the read-only hostr_swaps_watch with the returned swapId, tradeId, and reservationWaitSeconds; do not stop after displaying the invoice or wait for the user to say they paid. If watch completes or cannot find the swap, query hostr_trips_list with the same tradeId until the committed reservation appears, then show a reservation card.',
            };
          }),
          terminal.future,
        ]),
        cancellationToken,
      );
    } catch (error, stackTrace) {
      final reconnect = await _staleSignerReconnectException(
        tokenPubkey,
        session,
        error,
      );
      if (reconnect != null) throw reconnect;
      Error.throwWithStackTrace(error, stackTrace);
    }

    return result;
  }

  Map<String, Object?> _augmentBookAndPayStateJson(Map<String, Object?> json) {
    final externalPayment = _externalPaymentPromptFromBookAndPayState(json);
    if (externalPayment == null) return json;
    return {...json, 'externalPayment': externalPayment};
  }

  Map<String, Object?>? _externalPaymentPromptFromBookAndPayState(
    Map<String, Object?> json,
  ) {
    final swapState = json['swapState'];
    if (swapState is! Map) return null;
    final paymentState = swapState['paymentState'];
    if (paymentState is! Map) return null;
    if (paymentState['state'] != 'externalRequired') return null;
    final callbackDetails = paymentState['callbackDetails'];
    if (callbackDetails is! Map) return null;
    final invoice = callbackDetails['paymentRequest']?.toString();
    if (invoice == null || invoice.isEmpty) return null;
    return {
      'type': 'lightning-invoice',
      'invoice': invoice,
      'qrImage': renderQrImageDataUri(invoice),
      if (json['tradeId'] != null) 'tradeId': json['tradeId'],
      if (json['swapId'] != null) 'swapId': json['swapId'],
      if (paymentState['params'] is Map) 'params': paymentState['params'],
      'message':
          'External Lightning payment required. Pay this invoice to continue the Hostr booking.',
    };
  }

  Future<Map<String, Object?>> _reservationsOfferOrAccept(
    String tokenPubkey,
    HostrSession session,
    HostrReservationTradeInput input, {
    required bool acceptLatest,
  }) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Reservation negotiation',
    );
    final hostr = session.hostr;
    final activePubkey = hostr.auth.activePubkey!;
    final thread = await _hydrateTradeThread(
      hostr,
      tradeId: input.tradeId,
      timeout: Duration(seconds: input.timeoutSeconds),
    );
    final reservations = thread?.state.value.reservationRequests ?? const [];
    if (reservations.isEmpty) {
      throw HostrCliException(
        'not_found',
        'No private reservation negotiation found for tradeId.',
        details: {'tradeId': input.tradeId},
      );
    }
    final previous = [...reservations]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final latest = previous.last;
    final listing = await hostr.listings.getOneByAnchor(
      latest.parsedTags.listingAnchor,
    );
    if (listing == null) {
      throw HostrCliException(
        'listing_not_found',
        'Listing for reservation not found.',
        details: {'anchor': latest.parsedTags.listingAnchor},
      );
    }
    final amount = acceptLatest
        ? latest.amount
        : input.amount == null
        ? null
        : parseAmount(input.amount!.toJson(), 'amount');
    if (amount == null) {
      throw HostrCliException(
        'amount_required',
        'Latest offer has no amount to accept.',
      );
    }

    final event = await hostr.reservationRequests.createCounterOffer(
      listing: listing,
      previousRequest: latest,
      amount: amount,
      signerKeyPair: await _activeReservationKeyPair(
        hostr,
        sellerPubkey: listing.pubKey,
        tradeId: input.tradeId,
      ),
    );
    final recipients = _threadRecipients(thread!, activePubkey);
    if (input.dryRun) {
      return {
        'dryRun': true,
        'event': eventJson(event),
        'tradeId': event.getDtag(),
        'recipientPubkeys': recipients,
      };
    }
    final responses = await _replyOnThread(thread, event);
    return {
      'dryRun': false,
      'event': eventJson(event),
      'tradeId': event.getDtag(),
      'relayResponses': responses,
    };
  }

  Future<Map<String, Object?>> _reservationsPay(
    String tokenPubkey,
    HostrSession session,
    HostrReservationPayInput input,
  ) async {
    final activePubkey = await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Reservation payment',
    );
    final hostr = session.hostr;
    await hostr.evm.init();
    final thread = await _hydrateTradeThread(
      hostr,
      tradeId: input.tradeId,
      timeout: Duration(seconds: input.timeoutSeconds),
    );
    final privateRequests =
        thread?.state.value.reservationRequests
            .where(
              (reservation) => reservation.stage != ReservationStage.cancel,
            )
            .toList() ??
        const <Reservation>[];
    final latestPrivateRequest = privateRequests.lastOrNull;
    final plan = await _buildEscrowFundingPlan(
      hostr: hostr,
      tradeId: input.tradeId,
      escrowServiceId: input.escrowServiceId,
      privateReservation: latestPrivateRequest,
    );

    final payCheck = _payActionAvailable(
      listing: plan.listing,
      reservationRequests: privateRequests.isNotEmpty
          ? privateRequests
          : [plan.reservation],
      activePubkey: activePubkey,
    );
    if (!payCheck.available) {
      throw HostrCliException(
        'pay_unavailable',
        'Pay action is not available for this trade.',
        details: payCheck.details,
      );
    }

    if (input.dryRun) {
      return {
        'dryRun': true,
        'tradeId': input.tradeId,
        'mode': 'create-swap',
        'selectedEscrow': _escrowSelectionJson(plan.selectedEscrow),
        'reservation': eventJson(plan.reservation),
        'listing': listingSummary(plan.listing),
        'willCreateSwap': false,
      };
    }

    final selectionThread =
        thread ??
        _ensureTradeThread(
          hostr,
          tradeId: input.tradeId,
          participants: [plan.listing.pubKey],
        );
    final selectionResponses = await _replyOnThread(
      selectionThread,
      plan.selectedEscrow,
    );

    final SwapInParams swapParams;
    try {
      swapParams = await plan.preparer.prepare();
    } on UnsupportedEscrowPaymentTokenException catch (error) {
      throw HostrCliException(
        'unsupported_escrow_payment_token',
        error.message,
        details: error.toJson(),
      );
    }
    final swap = plan.preparer.configuredChain.swapIn(params: swapParams);
    await swap.init();
    await swap.runUntil(
      (state) => state.stateName == 'requestCreated' || state.isTerminal,
    );

    final state = swap.state;
    final data = state.data;
    final invoice = data?.invoiceString;
    if (state is SwapInRequestCreated && data != null) {
      final awaiting = SwapInAwaitingOnChain(data);
      await hostr.operationStateStore.write(
        'swap_in',
        data.boltzId,
        awaiting.toJson(),
      );
    }
    if (data?.boltzId != null) {
      await _persistPaymentContext(
        hostr,
        swapId: data!.boltzId,
        tradeId: input.tradeId,
        listing: plan.listing,
        reservation: plan.reservation,
        selectedEscrow: plan.selectedEscrow,
      );
    }

    final response = <String, Object?>{
      'dryRun': false,
      'tradeId': input.tradeId,
      'mode': 'create-swap',
      'selectedEscrow': _escrowSelectionJson(plan.selectedEscrow),
      'selectionRelayResponses': selectionResponses,
      'swapState': state is SwapInRequestCreated && data != null
          ? SwapInAwaitingOnChain(data).toJson()
          : state.toJson(),
    };
    if (invoice != null) {
      response['invoice'] = invoice;
      response['qrImage'] = renderQrImageDataUri(invoice);
    }
    if (data?.boltzId != null) {
      response['boltzId'] = data!.boltzId;
    }
    return response;
  }

  Future<Map<String, Object?>> _reservationsCommit(
    String tokenPubkey,
    HostrSession session,
    HostrReservationCommitInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Reservation commit',
    );
    final hostr = session.hostr;
    final paymentContext = await hostr.operationStateStore.read(
      _reservationPaymentNamespace,
      input.swapId,
    );
    if (paymentContext == null) {
      throw HostrCliException(
        'payment_context_not_found',
        'No reservation payment context found for swap id.',
        details: {'swapId': input.swapId},
      );
    }

    final swapJson = await hostr.operationStateStore.read(
      'swap_in',
      input.swapId,
    );
    if (swapJson == null) {
      throw HostrCliException(
        'swap_not_found',
        'No swap state found for swap id.',
        details: {'swapId': input.swapId},
      );
    }
    final swapState = SwapInState.fromJson(swapJson);
    if (swapState is! SwapInCompleted ||
        swapState.data.claimTxHash == null ||
        swapState.data.claimTxHash!.isEmpty) {
      throw HostrCliException(
        'swap_not_completed',
        'Swap does not yet have an escrow claim proof.',
        retryable: true,
        details: {'swapId': input.swapId, 'state': swapState.toJson()},
      );
    }

    final tradeId = paymentContext['tradeId'] as String;
    final thread = await _hydrateTradeThread(
      hostr,
      tradeId: tradeId,
      timeout: Duration(seconds: input.timeoutSeconds),
    );
    final latestPrivateRequest = thread?.state.value.reservationRequests
        .where((reservation) => reservation.stage != ReservationStage.cancel)
        .lastOrNull;
    final reservation =
        latestPrivateRequest ??
        Reservation.fromNostrEvent(
          _eventFromJson(
            Map<String, dynamic>.from(paymentContext['reservation'] as Map),
          ),
        );
    final selectedEscrow = EscrowServiceSelected.fromNostrEvent(
      _eventFromJson(
        Map<String, dynamic>.from(paymentContext['selectedEscrow'] as Map),
      ),
    );
    final listing = await hostr.listings.getOneByAnchor(
      reservation.parsedTags.listingAnchor,
    );
    if (listing == null) {
      throw HostrCliException(
        'listing_not_found',
        'Listing for reservation not found.',
        details: {'anchor': reservation.parsedTags.listingAnchor},
      );
    }
    final profile = await hostr.metadata.loadMetadata(listing.pubKey);
    if (profile == null) {
      throw HostrCliException(
        'seller_profile_not_found',
        'Seller profile metadata was not found.',
        details: {'sellerPubkey': listing.pubKey},
      );
    }

    if (input.dryRun) {
      return {
        'dryRun': true,
        'willPublish': true,
        'tradeId': tradeId,
        'swapId': input.swapId,
        'claimTxHash': swapState.data.claimTxHash,
        'reservation': eventJson(reservation),
        'selectedEscrow': _escrowSelectionJson(selectedEscrow),
      };
    }

    final activeKeyPair = await _activeReservationKeyPair(
      hostr,
      sellerPubkey: listing.pubKey,
      tradeId: tradeId,
    );
    final committed = await hostr.reservations.createSelfSigned(
      activeKeyPair: activeKeyPair,
      negotiateReservation: reservation,
      proof: PaymentProof(
        listing: listing,
        hoster: profile,
        zapProof: null,
        escrowProof: EscrowProof(
          txHash: swapState.data.claimTxHash!,
          escrowService: selectedEscrow.service,
          hostsEscrowMethods: selectedEscrow.sellerMethods,
        ),
      ),
    );
    await _persistPaymentContext(
      hostr,
      swapId: input.swapId,
      tradeId: tradeId,
      listing: listing,
      reservation: reservation,
      selectedEscrow: selectedEscrow,
      committedReservation: committed,
      terminal: true,
    );
    final readback = await _waitForPublicReservationsByTradeId(
      hostr,
      tradeId,
      until: (reservations) =>
          reservations.any((reservation) => reservation.id == committed.id),
    );
    return {
      'dryRun': false,
      'published': true,
      'tradeId': tradeId,
      'swapId': input.swapId,
      'event': eventJson(committed),
      'readbackCount': readback.length,
      'readback': readback.map(eventJson).toList(),
    };
  }

  Future<Map<String, Object?>> _reservationsCancel(
    String tokenPubkey,
    HostrSession session,
    HostrReservationTradeInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Reservation cancel',
    );
    final hostr = session.hostr;
    final publicReservations = await _waitForPublicReservationsByTradeId(
      hostr,
      input.tradeId,
      until: (reservations) => reservations.any(
        (reservation) => reservation.stage == ReservationStage.commit,
      ),
    );
    final publicGroup = publicReservations.isEmpty
        ? null
        : ReservationGroup(reservations: publicReservations);
    final hasPublicCommit = publicReservations.any(
      (reservation) => reservation.stage == ReservationStage.commit,
    );
    if (publicGroup != null && hasPublicCommit) {
      if (publicGroup.cancelled) {
        throw HostrCliException(
          'already_cancelled',
          'The committed reservation is already cancelled.',
          details: {
            'tradeId': input.tradeId,
            'reservationGroup': publicReservations.map(eventJson).toList(),
          },
        );
      }
      if (input.dryRun) {
        return {
          'mode': 'committed',
          'dryRun': true,
          'willPublish': true,
          'tradeId': input.tradeId,
          'reservationGroup': publicReservations.map(eventJson).toList(),
        };
      }
      final cancelled = await hostr.reservations.cancel(
        publicGroup,
        await _activeReservationKeyPair(
          hostr,
          sellerPubkey: publicGroup.sellerPubkey,
          tradeId: input.tradeId,
        ),
      );
      return {
        'mode': 'committed',
        'dryRun': false,
        'event': eventJson(cancelled),
        'tradeId': input.tradeId,
      };
    }

    final thread = await _hydrateTradeThread(
      hostr,
      tradeId: input.tradeId,
      timeout: Duration(seconds: input.timeoutSeconds),
    );
    final requests = thread?.state.value.reservationRequests ?? const [];
    if (requests.lastOrNull?.stage == ReservationStage.cancel) {
      throw HostrCliException(
        'already_cancelled',
        'The latest private negotiation event is already cancelled.',
        details: {'tradeId': input.tradeId},
      );
    }
    final previous = requests.reversed
        .where((reservation) => reservation.stage != ReservationStage.cancel)
        .firstOrNull;
    if (previous == null || thread == null) {
      throw HostrCliException(
        'reservation_not_found',
        'No private negotiation or committed reservation found for tradeId.',
        details: {'tradeId': input.tradeId},
      );
    }
    final event = await hostr.reservationRequests.createCancellation(
      previousRequest: previous,
      signerKeyPair: await _activeReservationKeyPair(
        hostr,
        sellerPubkey: getPubKeyFromAnchor(previous.parsedTags.listingAnchor),
        tradeId: input.tradeId,
      ),
    );
    final recipients = _threadRecipients(thread, hostr.auth.activePubkey!);
    if (input.dryRun) {
      return {
        'mode': 'negotiation',
        'dryRun': true,
        'event': eventJson(event),
        'tradeId': event.getDtag(),
        'recipientPubkeys': recipients,
      };
    }
    final responses = await _replyOnThread(thread, event);
    return {
      'mode': 'negotiation',
      'dryRun': false,
      'event': eventJson(event),
      'tradeId': event.getDtag(),
      'relayResponses': responses,
    };
  }

  Future<Map<String, Object?>> _updates(
    String tokenPubkey,
    HostrSession session,
    HostrUpdatesInput input,
  ) async {
    await _requireAuthenticatedPubkey(tokenPubkey, session, action: 'Updates');
    await _ensureAuthenticatedSessionHydrated(session, wait: true);
    final hostr = session.hostr;
    await _waitForStreamStatus(
      hostr.userSubscriptions.giftwraps$.status,
      timeout: Duration(seconds: input.timeoutSeconds),
    );
    final events = hostr.userSubscriptions.giftwraps$.items;
    final threads = hostr.messaging.threads.threads.values;
    final profiles = await _threadProfileSummaries(
      hostr,
      threads,
      activePubkey: tokenPubkey,
    );
    return {
      'count': events.length,
      'events': events.take(input.limit).map(eventJson).toList(),
      'profiles': profiles,
      'threads': threads
          .map((thread) => _threadJson(thread, profiles: profiles))
          .toList(),
    };
  }

  Future<Map<String, Object?>> _reply(
    String tokenPubkey,
    HostrSession session,
    HostrReplyInput input,
  ) async {
    await _requireAuthenticatedPubkey(tokenPubkey, session, action: 'Reply');
    final tags = <List<String>>[
      if (input.conversation != null) [kConversationTag, input.conversation!],
    ];
    if (input.dryRun) {
      return {
        'dryRun': true,
        'content': input.content,
        'tags': tags,
        'recipientPubkeys': input.recipientPubkeys,
      };
    }
    final futures = await session.hostr.messaging.broadcastText(
      content: input.content,
      tags: tags,
      recipientPubkeys: input.recipientPubkeys,
    );
    final nested = await Future.wait(futures);
    return {
      'dryRun': false,
      'relayResponses': nested
          .expand((responses) => responses)
          .map(relayResponseJson)
          .toList(),
    };
  }

  Future<Map<String, Object?>> _threadView(
    String tokenPubkey,
    HostrSession session,
    HostrThreadViewInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Thread view',
    );
    await _ensureAuthenticatedSessionHydrated(session, wait: true);
    final hostr = session.hostr;
    await _hydrateThreadInbox(
      hostr,
      limit: 200,
      timeout: Duration(seconds: input.timeoutSeconds),
      name: 'mcp-thread-view',
    );
    final thread = _resolveThread(
      hostr,
      threadAnchor: input.threadAnchor,
      conversation: input.conversation,
      tradeId: input.tradeId,
      recipientPubkeys: input.recipientPubkeys,
    );
    if (thread == null) {
      return {
        'found': false,
        'threadViews': const [],
        'message':
            'No Hostr thread matched the requested conversation or participants.',
      };
    }
    return {
      'found': true,
      'threadView': await _threadViewJson(
        hostr,
        thread,
        activePubkey: tokenPubkey,
        limit: input.limit,
      ),
    };
  }

  Future<Map<String, Object?>> _threadMessage(
    String tokenPubkey,
    HostrSession session,
    HostrThreadMessageInput input,
  ) async {
    final activePubkey = await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Thread message',
    );
    await _ensureAuthenticatedSessionHydrated(session, wait: true);
    final hostr = session.hostr;
    await _hydrateThreadInbox(
      hostr,
      limit: 200,
      timeout: Duration(seconds: input.timeoutSeconds),
      name: 'mcp-thread-message',
    );
    final conversation = input.tradeId ?? input.conversation;
    var recipients = input.recipientPubkeys;
    var thread = _resolveThread(
      hostr,
      threadAnchor: input.threadAnchor,
      conversation: input.conversation,
      tradeId: input.tradeId,
      recipientPubkeys: recipients,
    );

    final role = input.recipientRole?.trim().toLowerCase();
    if (role == 'escrow') {
      final tradeId = input.tradeId?.trim();
      if (tradeId == null || tradeId.isEmpty) {
        throw HostrCliException(
          'trade_id_required',
          'Messaging escrow requires a concrete reservation tradeId so buyer, seller, and escrow are all included in the thread.',
        );
      }
      final plan = await _resolveEscrowTradeThreadPlan(
        hostr,
        activePubkey: activePubkey,
        tradeId: tradeId,
        tradeThread: thread,
        timeout: Duration(seconds: input.timeoutSeconds),
      );
      recipients = plan.recipientPubkeys;
      thread = plan.thread;
    } else if (recipients.isEmpty && input.recipientRole != null) {
      final pubkey = await _pubkeyForThreadRole(
        hostr,
        tradeId: conversation,
        role: input.recipientRole!,
        thread: thread,
        timeout: Duration(seconds: input.timeoutSeconds),
      );
      if (pubkey != null) recipients = [pubkey];
    }

    if (recipients.isEmpty && thread != null) {
      recipients = _threadRecipients(thread, activePubkey);
    }
    if (recipients.isEmpty) {
      throw HostrCliException(
        'recipient_required',
        'Thread message requires a thread with recipients, recipientPubkeys, or a resolvable recipientRole.',
      );
    }

    thread ??= hostr.messaging.threads.ensureConversation(
      participants: {activePubkey, ...recipients},
      conversationTag: conversation ?? '',
    );
    thread.configureConversation(
      conversationTag: conversation ?? thread.conversationTag,
      participants: {activePubkey, ...recipients},
    );

    if (input.dryRun) {
      return {
        'dryRun': true,
        'content': input.content,
        'recipientPubkeys': recipients,
        'threadView': await _threadViewJson(
          hostr,
          thread,
          activePubkey: activePubkey,
        ),
      };
    }

    final sentEvent = await thread
        .replyTextAndWait(input.content)
        .timeout(Duration(seconds: input.timeoutSeconds));
    return {
      'dryRun': false,
      'sentMessage': _sentTextEventJson(sentEvent, activePubkey: activePubkey),
      'recipientPubkeys': recipients,
      'threadView': await _threadViewJson(
        hostr,
        thread,
        activePubkey: activePubkey,
      ),
    };
  }

  Future<Map<String, Object?>> _escrowInvolve(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowInvolveInput input,
  ) async {
    final activePubkey = await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow involve',
    );
    await _ensureAuthenticatedSessionHydrated(session, wait: true);
    final hostr = session.hostr;
    await _hydrateThreadInbox(
      hostr,
      limit: 200,
      timeout: Duration(seconds: input.timeoutSeconds),
      name: 'mcp-escrow-involve',
    );
    final tradeId = input.tradeId.trim();
    if (tradeId.isEmpty) {
      throw HostrCliException(
        'trade_id_required',
        'Messaging escrow requires a concrete reservation tradeId so buyer, seller, and escrow are all included in the thread.',
      );
    }
    final tradeThread = _resolveThread(hostr, tradeId: tradeId);
    final plan = await _resolveEscrowTradeThreadPlan(
      hostr,
      activePubkey: activePubkey,
      tradeId: tradeId,
      tradeThread: tradeThread,
      timeout: Duration(seconds: input.timeoutSeconds),
    );
    final escrowThread = plan.thread;
    final content = input.content;
    if (content == null || content.trim().isEmpty) {
      return {
        'dryRun': true,
        'requiresMessage': true,
        'message':
            'Escrow trade thread is open. Ask the user what they would like to message the escrow.',
        'tradeId': tradeId,
        'participantPubkeys': plan.participantPubkeys,
        'recipientPubkeys': plan.recipientPubkeys,
        'roles': plan.rolePubkeys,
        'threadView': await _threadViewJson(
          hostr,
          escrowThread,
          activePubkey: activePubkey,
        ),
      };
    }

    if (input.dryRun) {
      return {
        'dryRun': true,
        'content': content,
        'tradeId': tradeId,
        'participantPubkeys': plan.participantPubkeys,
        'recipientPubkeys': plan.recipientPubkeys,
        'roles': plan.rolePubkeys,
        'threadView': await _threadViewJson(
          hostr,
          escrowThread,
          activePubkey: activePubkey,
        ),
      };
    }

    final sentEvent = await escrowThread
        .replyTextAndWait(content)
        .timeout(Duration(seconds: input.timeoutSeconds));
    return {
      'dryRun': false,
      'sentMessage': _sentTextEventJson(sentEvent, activePubkey: activePubkey),
      'tradeId': tradeId,
      'participantPubkeys': plan.participantPubkeys,
      'recipientPubkeys': plan.recipientPubkeys,
      'roles': plan.rolePubkeys,
      'threadView': await _threadViewJson(
        hostr,
        escrowThread,
        activePubkey: activePubkey,
      ),
    };
  }

  Future<Map<String, Object?>> _profileShow(
    String tokenPubkey,
    HostrSession session,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Profile show',
    );
    final profile = await session.metadata.loadMetadata(tokenPubkey);
    return {
      'pubkey': tokenPubkey,
      'exists': profile != null,
      if (profile != null) 'event': eventJson(profile),
      if (profile != null) 'metadata': profile.metadata.toJson(),
    };
  }

  Future<Map<String, Object?>> _profileLookup(
    HostrSession session,
    HostrProfileLookupInput input,
  ) async {
    final pubkey = _pubkeyFromNpub(input.npub);
    final profile = await session.metadata.loadMetadata(pubkey);
    return {
      'pubkey': pubkey,
      'npub': Helpers.encodeBech32(pubkey, 'npub'),
      'exists': profile != null,
      if (profile != null) 'event': eventJson(profile),
      if (profile != null) 'metadata': profile.metadata.toJson(),
    };
  }

  Future<Map<String, Object?>> _profileEdit(
    String tokenPubkey,
    HostrSession session,
    HostrProfileEditInput input,
  ) async {
    final activePubkey = await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Profile edit',
    );
    final existing = await session.metadata.loadMetadata(activePubkey);
    final metadata = Metadata(
      name: input.name ?? existing?.metadata.name ?? '',
      about: input.about ?? existing?.metadata.about ?? '',
      picture: input.image ?? existing?.metadata.picture ?? '',
      lud16: input.lud16 ?? existing?.metadata.lud16 ?? '',
      nip05: input.nip05 ?? existing?.metadata.nip05 ?? '',
    )..pubKey = activePubkey;
    final profile = ProfileMetadata.fromNostrEvent(metadata.toEvent());
    if (input.dryRun) {
      return {
        'dryRun': true,
        'pubkey': activePubkey,
        'event': eventJson(profile),
        'metadata': metadata.toJson(),
      };
    }
    final result = await session.metadata.upsert(profile);
    final published = result.event;
    return {
      'dryRun': false,
      'pubkey': activePubkey,
      'event': eventJson(published),
      'metadata': published.metadata.toJson(),
      'relayResponses': result.responses.map(relayResponseJson).toList(),
    };
  }

  Future<Map<String, Object?>> _reservationCollection(
    String tokenPubkey,
    HostrSession session,
    HostrReservationCollectionInput input, {
    required String mode,
  }) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: mode == 'bookings' ? 'Bookings list' : 'Trips list',
    );
    await _ensureAuthenticatedSessionHydrated(session, wait: true);
    final hostr = session.hostr;
    if (input.tradeId != null) {
      final lookup = await _reservationLookupByTradeId(
        hostr,
        input.tradeId!,
        waitSeconds: input.waitSeconds,
      );
      return {'mode': mode, ...lookup};
    }
    final source = mode == 'bookings'
        ? hostr.userSubscriptions.myResolvedHostingsList$
        : hostr.userSubscriptions.myResolvedTripsList$;
    final snapshot = await _resolvedReservationGroupSnapshot(
      source,
      timeout: Duration(seconds: input.waitSeconds),
    );
    final valid = snapshot
        .where((item) => item.validation is Valid<ReservationGroup>)
        .take(input.limit)
        .toList();
    final results = await Future.wait(
      valid.map(
        (item) =>
            _resolvedReservationCollectionItemJson(hostr, item, mode: mode),
      ),
    );
    return {
      'mode': mode,
      'source': mode == 'bookings'
          ? 'userSubscriptions.myResolvedHostingsList'
          : 'userSubscriptions.myResolvedTripsList',
      'count': results.length,
      'invalidCount': snapshot.length - valid.length,
      'results': results,
    };
  }

  Future<Map<String, Object?>> _swapsList(
    String tokenPubkey,
    HostrSession session,
    HostrSwapsListInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Swap state',
    );
    final entries = <Map<String, Object?>>[];
    for (final namespace in _swapNamespaces(input.namespace)) {
      final states = await session.hostr.operationStateStore.readAll(namespace);
      entries.add({
        'namespace': namespace,
        'count': states.length,
        'states': states,
      });
    }
    return {'pubkey': tokenPubkey, 'entries': entries};
  }

  Future<Map<String, Object?>> _escrowMethods(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowMethodsInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow method lookup',
    );
    final buyerPubkey = input.buyer ?? tokenPubkey;
    final sellerPubkey = input.user;
    final mutual = await session.hostr.escrows.determineMutualEscrow(
      buyerPubkey,
      sellerPubkey,
    );
    final services = mutual.compatibleServices;
    return {
      'buyerPubkey': buyerPubkey,
      'sellerPubkey': sellerPubkey,
      'buyerMethod': _escrowMethodJson(mutual.buyerMethod),
      'sellerMethod': _escrowMethodJson(mutual.sellerMethod),
      'compatibleCount': services.length,
      'compatibleServices': services.map(_escrowServiceJson).toList(),
      'defaultServiceId': services.firstOrNull?.id,
      'requiresChoice': services.length > 1,
    };
  }

  Future<Map<String, Object?>> _escrowTradesList(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowTradesListInput input,
  ) async {
    final escrow = await _escrowToolContext(session);
    final daemon = session.escrowDaemon;
    await _waitForEscrowTradeCache(daemon);
    final trades = daemon.trades.values.toList()
      ..sort(_compareEscrowTradeSnapshots);
    final limitedTrades = trades.take(input.limit).toList();
    final cards = await Future.wait(
      limitedTrades.map(
        (trade) => _escrowTradeSnapshotCard(session, escrow.context, trade),
      ),
    );
    return {
      'pubkey': tokenPubkey,
      'escrowPubkeys': _configuredEscrowPubkeys(),
      'escrowService': _escrowServiceJson(escrow.context.escrowService),
      'arbiterEvmAddress': escrow.signer.address.toString(),
      'count': cards.length,
      'totalCount': trades.length,
      'source': 'session.escrowDaemon.trades',
      'limit': input.limit,
      'escrowTradeCards': cards,
    };
  }

  Future<Map<String, Object?>> _escrowServiceUpdate(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowServiceUpdateInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow service update',
    );
    final escrow = await _escrowToolContext(session);
    final current = input.serviceId == null
        ? escrow.context.escrowService
        : await _getOwnedEscrowService(session, tokenPubkey, input.serviceId!);
    final updatedHints = input.tokenFeeHints != null
        ? input.tokenFeeHints!.map(
            (token, hints) => MapEntry(
              token,
              TokenFeeHints(
                baseFee: hints.baseFee,
                maxFee: hints.maxFee,
                minFee: hints.minFee,
              ),
            ),
          )
        : input.clearTokenFeeHints
        ? const <String, TokenFeeHints>{}
        : current.tokenFeeHints;

    final updated = EscrowService(
      pubKey: current.pubKey,
      tags: current.parsedTags,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      content: EscrowServiceContent(
        pubkey: current.escrowPubkey,
        evmAddress: current.evmAddress,
        contractAddress: current.contractAddress,
        contractBytecodeHash: current.contractBytecodeHash,
        chainId: current.chainId,
        maxDuration: input.maxDurationSeconds != null
            ? Duration(seconds: input.maxDurationSeconds!)
            : current.maxDuration,
        type: current.escrowType,
        feePercent: input.feePercent ?? current.feePercent,
        tokenFeeHints: updatedHints,
      ),
    );

    if (input.dryRun) {
      return {
        'dryRun': true,
        'serviceBefore': _escrowServiceJson(current),
        'serviceAfter': _escrowServiceJson(updated),
        'escrowServiceCards': [
          _escrowServiceCard(updated, preview: true, before: current),
        ],
      };
    }

    final result = await session.hostr.escrows.upsert(updated);
    final published = result.event;
    return {
      'dryRun': false,
      'serviceBefore': _escrowServiceJson(current),
      'serviceAfter': _escrowServiceJson(published),
      'relayResponses': result.responses.map(relayResponseJson).toList(),
      'escrowServiceCards': [_escrowServiceCard(published, before: current)],
    };
  }

  Future<Map<String, Object?>> _escrowServiceList(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowServiceListInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow service list',
    );
    final services = await session.hostr.escrows.list(
      Filter(authors: [tokenPubkey], limit: input.limit),
      name: 'escrow-service-list',
    );
    services.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return {
      'pubkey': tokenPubkey,
      'count': services.length,
      'escrowServiceCards': services.map(_escrowServiceCard).toList(),
      'services': services.map(_escrowServiceJson).toList(),
    };
  }

  Future<Map<String, Object?>> _escrowServiceGet(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowServiceGetInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow service get',
    );
    final service = await _getOwnedEscrowService(
      session,
      tokenPubkey,
      input.serviceId,
    );
    return {
      'pubkey': tokenPubkey,
      'service': _escrowServiceJson(service),
      'escrowServiceCards': [_escrowServiceCard(service)],
    };
  }

  Future<Map<String, Object?>> _escrowServiceDelete(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowServiceDeleteInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow service delete',
    );
    final service = await _getOwnedEscrowService(
      session,
      tokenPubkey,
      input.serviceId,
    );
    final card = _escrowServiceCard(service, deleted: !input.dryRun);
    if (input.dryRun) {
      return {
        'dryRun': true,
        'service': _escrowServiceJson(service),
        if (input.reason != null) 'reason': input.reason,
        'escrowServiceCards': [
          {...card, 'title': 'Escrow service deletion preview'},
        ],
      };
    }

    final dTag = service.getFirstTag('d') ?? service.contractAddress;
    final deletion = Nip01Event(
      pubKey: tokenPubkey,
      kind: 5,
      tags: [
        ['e', service.id],
        ['a', '${service.kind}:$tokenPubkey:$dTag'],
        ['k', '${service.kind}'],
      ],
      content: input.reason ?? 'Escrow service deleted by operator',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    final result = await session.hostr.escrows.requests.broadcastEvent(
      event: deletion,
    );
    return {
      'dryRun': false,
      'deleted': true,
      'serviceId': service.id,
      if (input.reason != null) 'reason': input.reason,
      'relayResponses': result.responses.map(relayResponseJson).toList(),
      'escrowServiceCards': [
        {...card, 'title': 'Escrow service deleted'},
      ],
    };
  }

  Future<Map<String, Object?>> _escrowTradeView(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowTradeViewInput input,
  ) async {
    final escrow = await _escrowToolContext(session);
    return {
      'pubkey': tokenPubkey,
      'escrowPubkeys': _configuredEscrowPubkeys(),
      'escrowService': _escrowServiceJson(escrow.context.escrowService),
      'escrowTradeCards': [
        await _escrowTradeCard(session, escrow, input.tradeId),
      ],
    };
  }

  Future<Map<String, Object?>> _escrowTradeAudit(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowTradeAuditInput input,
  ) async {
    final escrow = await _escrowToolContext(session);
    final tradeCard = await _escrowTradeCard(session, escrow, input.tradeId);
    final audit = await session.hostr.tradeAudit.audit(input.tradeId);
    return {
      'pubkey': tokenPubkey,
      'escrowPubkeys': _configuredEscrowPubkeys(),
      'tradeId': input.tradeId,
      'audit': _tradeAuditJson(audit),
      'escrowTradeCards': [
        {...tradeCard, 'audit': _tradeAuditJson(audit)},
      ],
    };
  }

  Future<Map<String, Object?>> _escrowArbitrate(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowArbitrateInput input,
  ) async {
    final escrow = await _escrowToolContext(session);
    final before = await _escrowTradeCard(session, escrow, input.tradeId);
    final onChain = before['onChain'];
    final status = before['status']?.toString();
    if (onChain == null) {
      throw HostrCliException(
        'escrow_trade_not_active',
        'Trade ${input.tradeId} is not active on the escrow contract.',
        details: {'tradeId': input.tradeId, 'status': status},
      );
    }
    if (status == 'arbitrated' || status == 'released' || status == 'claimed') {
      throw HostrCliException(
        'escrow_trade_terminal',
        'Trade ${input.tradeId} is already terminal with status "$status".',
        details: {'tradeId': input.tradeId, 'status': status},
      );
    }

    final call = escrow.context.contract.arbitrate(
      tradeId: input.tradeId,
      paymentForward: input.paymentForward,
      bondForward: input.bondForward,
      ethKey: escrow.signer,
    );
    final callSummary = {
      'methodName': 'arbitrate',
      'to': call.to.toString(),
      'valueWei': call.value.toString(),
    };
    if (input.dryRun) {
      return {
        'dryRun': true,
        'tradeId': input.tradeId,
        'paymentForward': input.paymentForward,
        'bondForward': input.bondForward,
        if (input.reason != null) 'reason': input.reason,
        'wouldBroadcast': callSummary,
        'escrowTradeCards': [
          {
            ...before,
            'arbitrationPreview': {
              'paymentForward': input.paymentForward,
              'bondForward': input.bondForward,
              if (input.reason != null) 'reason': input.reason,
            },
          },
        ],
      };
    }

    final txHash = await escrow.context.configuredChain.sendCalls(
      escrow.signer,
      {'arbitrate': call},
    );
    final receipt = await escrow.context.configuredChain.awaitReceipt(txHash);
    escrow.context.configuredChain.notifyNewBlock();
    final after = await _escrowTradeCard(session, escrow, input.tradeId);
    return {
      'dryRun': false,
      'tradeId': input.tradeId,
      'paymentForward': input.paymentForward,
      'bondForward': input.bondForward,
      if (input.reason != null) 'reason': input.reason,
      'txHash': txHash,
      'receipt': {
        'transactionHash': receipt.transactionHash,
        'status': receipt.status,
      },
      'escrowTradeCards': [after],
    };
  }

  Future<Map<String, Object?>> _escrowBadgeDefinitionsList(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowBadgeDefinitionsListInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow badge definitions list',
    );
    final definitions = await session.hostr.badgeDefinitions.list(
      Filter(authors: [tokenPubkey], limit: input.limit),
      name: 'escrow-badge-definitions',
    );
    definitions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return {
      'pubkey': tokenPubkey,
      'count': definitions.length,
      'badgeCards': definitions
          .map((definition) => _badgeDefinitionCard(definition))
          .toList(),
      'definitions': definitions.map(_badgeDefinitionJson).toList(),
    };
  }

  Future<Map<String, Object?>> _escrowBadgeDefinitionEdit(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowBadgeDefinitionEditInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow badge definition edit',
    );
    final event = Nip01Event(
      pubKey: tokenPubkey,
      kind: kNostrKindBadgeDefinition,
      tags: [
        ['d', input.identifier],
      ],
      content: jsonEncode({
        'name': input.name,
        if (input.description != null) 'description': input.description,
        if (input.image != null) 'image': input.image,
      }),
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    final definition = BadgeDefinition.fromNostrEvent(event);
    final card = _badgeDefinitionCard(
      definition,
      title: input.dryRun
          ? 'Badge definition preview'
          : 'Badge definition published',
    );
    if (input.dryRun) {
      return {
        'dryRun': true,
        'definition': _badgeDefinitionJson(definition),
        'badgeCards': [card],
      };
    }
    final result = await session.hostr.badgeDefinitions.upsert(definition);
    final published = result.event;
    return {
      'dryRun': false,
      'definition': _badgeDefinitionJson(published),
      'relayResponses': result.responses.map(relayResponseJson).toList(),
      'badgeCards': [
        _badgeDefinitionCard(published, title: 'Badge definition published'),
      ],
    };
  }

  Future<Map<String, Object?>> _escrowBadgeDefinitionDelete(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowBadgeDefinitionDeleteInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow badge definition delete',
    );
    final definition = await session.hostr.badgeDefinitions.getOneByAnchor(
      input.anchor,
    );
    if (definition == null || definition.pubKey != tokenPubkey) {
      throw HostrCliException(
        'badge_definition_not_found',
        'Badge definition not found for the authenticated escrow pubkey.',
        details: {'anchor': input.anchor},
      );
    }
    final card = _badgeDefinitionCard(
      definition,
      title: input.dryRun
          ? 'Badge definition deletion preview'
          : 'Badge definition deleted',
      deleted: !input.dryRun,
    );
    if (input.dryRun) {
      return {
        'dryRun': true,
        'definition': _badgeDefinitionJson(definition),
        if (input.reason != null) 'reason': input.reason,
        'badgeCards': [card],
      };
    }
    final deletion = Nip01Event(
      pubKey: tokenPubkey,
      kind: 5,
      tags: [
        ['e', definition.id],
        ['a', input.anchor],
        ['k', '${definition.kind}'],
      ],
      content: input.reason ?? 'Badge definition deleted by escrow operator',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    final result = await session.hostr.badgeDefinitions.requests.broadcastEvent(
      event: deletion,
    );
    return {
      'dryRun': false,
      'deleted': true,
      'definition': _badgeDefinitionJson(definition),
      if (input.reason != null) 'reason': input.reason,
      'relayResponses': result.responses.map(relayResponseJson).toList(),
      'badgeCards': [card],
    };
  }

  Future<Map<String, Object?>> _escrowBadgeAwardsList(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowBadgeAwardsListInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow badge awards list',
    );
    final awards = await session.hostr.badgeAwards.list(
      Filter(
        authors: [tokenPubkey],
        limit: input.limit,
        tags: input.definitionAnchor == null
            ? null
            : {
                'a': [input.definitionAnchor!],
              },
      ),
      name: 'escrow-badge-awards',
    );
    awards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return {
      'pubkey': tokenPubkey,
      'count': awards.length,
      'badgeCards': awards.map((award) => _badgeAwardCard(award)).toList(),
      'awards': awards.map(_badgeAwardJson).toList(),
    };
  }

  Future<Map<String, Object?>> _escrowBadgeAward(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowBadgeAwardInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow badge award',
    );
    final tags = <List<String>>[
      ['a', input.definitionAnchor],
      ['p', input.recipientPubkey],
      if (input.listingAnchor != null) ['a', input.listingAnchor!],
    ];
    final event = Nip01Event(
      pubKey: tokenPubkey,
      kind: kNostrKindBadgeAward,
      tags: tags,
      content: '',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    final award = BadgeAward.fromNostrEvent(event);
    final card = _badgeAwardCard(
      award,
      title: input.dryRun ? 'Badge award preview' : 'Badge awarded',
    );
    if (input.dryRun) {
      return {
        'dryRun': true,
        'award': _badgeAwardJson(award),
        'badgeCards': [card],
      };
    }
    final result = await session.hostr.badgeAwards.upsert(award);
    final published = result.event;
    return {
      'dryRun': false,
      'award': _badgeAwardJson(published),
      'relayResponses': result.responses.map(relayResponseJson).toList(),
      'badgeCards': [_badgeAwardCard(published, title: 'Badge awarded')],
    };
  }

  Future<Map<String, Object?>> _escrowBadgeRevoke(
    String tokenPubkey,
    HostrSession session,
    HostrEscrowBadgeRevokeInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Escrow badge revoke',
    );
    final award = await session.hostr.badgeAwards.getById(input.awardId);
    if (award.pubKey != tokenPubkey) {
      throw HostrCliException(
        'badge_award_not_owned',
        'Badge award was not issued by the authenticated escrow pubkey.',
        details: {'awardId': input.awardId, 'issuer': award.pubKey},
      );
    }
    final card = _badgeAwardCard(
      award,
      title: input.dryRun ? 'Badge revocation preview' : 'Badge revoked',
      deleted: !input.dryRun,
    );
    if (input.dryRun) {
      return {
        'dryRun': true,
        'award': _badgeAwardJson(award),
        if (input.reason != null) 'reason': input.reason,
        'badgeCards': [card],
      };
    }
    final deletion = Nip01Event(
      pubKey: tokenPubkey,
      kind: 5,
      tags: [
        ['e', award.id],
        ['k', '${award.kind}'],
      ],
      content: input.reason ?? 'Badge award revoked by escrow operator',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    final result = await session.hostr.badgeAwards.requests.broadcastEvent(
      event: deletion,
    );
    return {
      'dryRun': false,
      'revoked': true,
      'award': _badgeAwardJson(award),
      if (input.reason != null) 'reason': input.reason,
      'relayResponses': result.responses.map(relayResponseJson).toList(),
      'badgeCards': [card],
    };
  }

  Future<({EscrowDaemonContext context, dynamic signer})> _escrowToolContext(
    HostrSession session,
  ) async {
    final daemon = session.escrowDaemon;
    final context = daemon.isBootstrapped
        ? daemon.context
        : await daemon.bootstrap(const EscrowDaemonConfig());
    if (!daemon.isStarted) {
      await daemon.start();
    }
    final signer = await session.auth.hd.getActiveEvmKey();
    return (context: context, signer: signer);
  }

  Future<EscrowService> _getOwnedEscrowService(
    HostrSession session,
    String tokenPubkey,
    String serviceId,
  ) async {
    final service = await session.hostr.escrows.getById(serviceId);
    if (service.pubKey != tokenPubkey) {
      throw HostrCliException(
        'escrow_service_not_owned',
        'Escrow service is not owned by the authenticated escrow pubkey.',
        details: {
          'serviceId': serviceId,
          'ownerPubkey': service.pubKey,
          'authenticatedPubkey': tokenPubkey,
        },
      );
    }
    return service;
  }

  Map<String, Object?> _escrowServiceCard(
    EscrowService service, {
    bool preview = false,
    EscrowService? before,
    bool deleted = false,
  }) {
    final beforeFee = before?.feePercent;
    final beforeMaxDuration = before?.maxDuration.inSeconds;
    return {
      'type': 'escrow-service-card',
      'title': deleted
          ? 'Escrow service deleted'
          : preview
          ? 'Escrow service update preview'
          : 'Escrow service',
      'pubkey': service.pubKey,
      'evmAddress': service.evmAddress,
      'chainId': service.chainId,
      'contractAddress': service.contractAddress,
      'contractBytecodeHash': service.contractBytecodeHash,
      'feePercent': service.feePercent,
      'maxDurationSeconds': service.maxDuration.inSeconds,
      'tokenFeeHints': _tokenFeeHintsJson(service.tokenFeeHints),
      if (deleted) 'deleted': true,
      if (before != null)
        'changes': {
          if (beforeFee != service.feePercent)
            'feePercent': {'from': beforeFee, 'to': service.feePercent},
          if (beforeMaxDuration != service.maxDuration.inSeconds)
            'maxDurationSeconds': {
              'from': beforeMaxDuration,
              'to': service.maxDuration.inSeconds,
            },
          if (!_tokenFeeHintsEqual(before.tokenFeeHints, service.tokenFeeHints))
            'tokenFeeHints': {
              'from': _tokenFeeHintsJson(before.tokenFeeHints),
              'to': _tokenFeeHintsJson(service.tokenFeeHints),
            },
        },
    };
  }

  Map<String, Object?> _badgeDefinitionJson(BadgeDefinition definition) => {
    'id': definition.id,
    'anchor': definition.anchor,
    'identifier': definition.identifier,
    'pubkey': definition.pubKey,
    'name': definition.name,
    if (definition.description != null) 'description': definition.description,
    if (definition.image != null) 'image': definition.image,
    if (definition.thumbs != null) 'thumbs': definition.thumbs,
    'createdAt': definition.createdAt,
  };

  Map<String, Object?> _badgeAwardJson(BadgeAward award) => {
    'id': award.id,
    'issuerPubkey': award.pubKey,
    'definitionAnchor': award.badgeDefinitionAnchor,
    'recipientPubkeys': award.recipients,
    if (award.targetAnchor != null) 'listingAnchor': award.targetAnchor,
    'createdAt': award.createdAt,
  };

  Map<String, Object?> _badgeDefinitionCard(
    BadgeDefinition definition, {
    String? title,
    bool deleted = false,
  }) => {
    'type': 'escrow-badge-definition-card',
    'title': title ?? 'Badge definition',
    'anchor': definition.anchor,
    'identifier': definition.identifier,
    'name': definition.name,
    if (definition.description != null) 'description': definition.description,
    if (definition.image != null) 'image': definition.image,
    if (deleted) 'deleted': true,
  };

  Map<String, Object?> _badgeAwardCard(
    BadgeAward award, {
    String? title,
    bool deleted = false,
  }) => {
    'type': 'escrow-badge-award-card',
    'title': title ?? 'Badge award',
    'awardId': award.id,
    'definitionAnchor': award.badgeDefinitionAnchor,
    'recipientPubkeys': award.recipients,
    if (award.targetAnchor != null) 'listingAnchor': award.targetAnchor,
    'issuedAt': DateTime.fromMillisecondsSinceEpoch(
      award.createdAt * 1000,
      isUtc: true,
    ).toIso8601String(),
    if (deleted) 'deleted': true,
  };

  Map<String, Object?> _tradeAuditJson(TradeAuditResult audit) => {
    'type': 'escrow-trade-audit-card',
    'title': 'Escrow trade audit',
    'tradeId': audit.tradeId,
    'explanation': audit.explanation,
    if (audit.listing != null) ...{
      'listingAnchor': audit.listing!.anchor,
      'listingTitle': audit.listing!.title,
    },
    'hasBuyer': audit.buyer != null,
    'hasSeller': audit.seller != null,
    'hasEscrow': audit.escrow != null,
    if (audit.buyer != null) 'buyer': _partyAuditJson(audit.buyer!),
    if (audit.seller != null) 'seller': _partyAuditJson(audit.seller!),
    if (audit.escrow != null) 'escrow': _partyAuditJson(audit.escrow!),
    'formatted': audit.format(),
  };

  Map<String, Object?> _partyAuditJson(PartyAudit party) => {
    'role': party.role,
    'pubkey': party.pubkey,
    'reservationCount': party.reservations.length,
    'transitionCount': party.transitions.length,
    'currentStage': party.currentStage?.name,
    'chainValid': party.transitionChainResult.isValid,
    if (!party.transitionChainResult.isValid)
      'chainReason': party.transitionChainResult.reason,
    'reservations': party.validatedReservations
        .map(
          (entry) => {
            'stage': entry.reservation.stage.name,
            'cancelled': entry.reservation.cancelled,
            'valid': entry.validation.isValid,
          },
        )
        .toList(),
    'transitions': party.transitions
        .map(
          (transition) => {
            'type': transition.transitionType.name,
            'fromStage': transition.fromStage.name,
            'toStage': transition.toStage.name,
          },
        )
        .toList(),
    if (party.escrowVerification != null)
      'escrowVerification': {
        'valid': party.escrowVerification!.isValid,
        if (party.escrowVerification!.reason != null)
          'reason': party.escrowVerification!.reason,
      },
  };

  Future<List<EscrowEvent>> _escrowEventsFor(
    SupportedEscrowContract contract,
    ContractEventsParams params,
  ) async {
    final events = contract.allEvents(params, null, includeLive: false);
    final status = await events.status.firstWhere(
      (status) =>
          status is StreamStatusQueryComplete ||
          status is StreamStatusLive ||
          status is StreamStatusError,
    );
    if (status is StreamStatusError) {
      throw HostrCliException(
        'escrow_event_query_failed',
        'Failed to query escrow events: ${status.error}',
        details: {'params': params.toString()},
      );
    }
    return events.items.toList()..sort((a, b) {
      final block = a.blockNum.compareTo(b.blockNum);
      if (block != 0) return block;
      final tx = a.transactionIndex.compareTo(b.transactionIndex);
      if (tx != 0) return tx;
      return a.logIndex.compareTo(b.logIndex);
    });
  }

  Future<void> _waitForEscrowTradeCache(EscrowDaemon daemon) async {
    if (daemon.trades.isNotEmpty) return;
    try {
      await daemon.trades$
          .firstWhere((trades) => trades.isNotEmpty)
          .timeout(const Duration(seconds: 2));
    } on TimeoutException {
      // An empty cache is a valid result; the daemon keeps listening after the
      // MCP response returns.
    }
  }

  int _compareEscrowTradeSnapshots(TradeSnapshot a, TradeSnapshot b) {
    // Pending (funded) first, then newest chain event descending.
    final aPending = a.status == TradeStatus.funded ? 0 : 1;
    final bPending = b.status == TradeStatus.funded ? 0 : 1;
    if (aPending != bPending) return aPending.compareTo(bPending);
    final aBlock = a.updatedBlockNum;
    final bBlock = b.updatedBlockNum;
    if (aBlock != null && bBlock != null && aBlock != bBlock) {
      return bBlock.compareTo(aBlock);
    }
    return b.updatedAt.compareTo(a.updatedAt);
  }

  ReservationGroup? _cachedEscrowReservationGroup(
    HostrSession session,
    String tradeId,
  ) {
    for (final group in session.escrowDaemon.reservationGroups.values) {
      try {
        if (group.tradeId == tradeId) return group;
      } catch (_) {
        // Ignore incomplete groups.
      }
    }
    return null;
  }

  String _escrowTradeTitle(String tradeId, ReservationGroup? group) {
    if (group != null) {
      final listing = _embeddedReservationListing(group);
      if (listing != null && listing.title.isNotEmpty) return listing.title;
    }
    return 'Escrow trade ${_shortPubkey(tradeId)}';
  }

  Future<Map<String, Object?>?> _escrowTradeParticipantsJson(
    HostrSession session,
    String tradeId, {
    ReservationGroup? group,
  }) async {
    group ??= _cachedEscrowReservationGroup(session, tradeId);
    if (group == null) return null;

    ResolvedReservationGroupParticipants? resolved;
    try {
      resolved = await ReservationGroupParticipantResolver(
        keyring: DefaultReservationParticipantKeyring(
          auth: session.auth,
          tradeAccountAllocator: session.auth.service<TradeAccountAllocator>(),
          ndk: session.auth.service<Ndk>(),
          logger: session.hostr.logger,
        ),
      ).resolve(group);
    } catch (_) {
      resolved = null;
    }

    final sellerPubkey =
        resolved?.resolvedParticipantPubkeyForRole('seller') ??
        group.sellerPubkey;
    final buyerPubkey =
        resolved?.resolvedParticipantPubkeyForRole('buyer') ??
        group.buyerPubkey;
    final escrowPubkey =
        resolved?.resolvedParticipantPubkeyForRole('escrow') ??
        group.escrowPubkey;
    final rolePubkeys = <String, String>{
      if (sellerPubkey.isNotEmpty) 'seller': sellerPubkey,
      if (buyerPubkey != null && buyerPubkey.isNotEmpty) 'buyer': buyerPubkey,
      if (escrowPubkey != null && escrowPubkey.isNotEmpty)
        'escrow': escrowPubkey,
    };
    final profiles = await _profileSummariesForPubkeys(
      session.hostr,
      rolePubkeys.values,
    );

    return {
      'roles': rolePubkeys,
      'profiles': profiles,
      if (buyerPubkey != null && buyerPubkey.isNotEmpty)
        'buyer': profiles[buyerPubkey],
      if (sellerPubkey.isNotEmpty) 'seller': profiles[sellerPubkey],
      if (escrowPubkey != null && escrowPubkey.isNotEmpty)
        'escrow': profiles[escrowPubkey],
      'participantPubkeys': rolePubkeys.values.toSet().toList()..sort(),
      if (resolved != null) ...{
        'rawGroupId': resolved.rawGroupId,
        'resolvedGroupId': resolved.resolvedGroupId,
        'hasResolvedParticipants': resolved.hasResolvedParticipants,
      },
    };
  }

  bool _escrowTradeStatusTerminal(String status) =>
      status == 'arbitrated' || status == 'released' || status == 'claimed';

  List<Map<String, Object?>> _escrowTradeNextActions(
    String tradeId,
    String status,
  ) {
    final viewThread = {
      'label': 'View thread',
      'tool': 'hostr_escrow_involve',
      'arguments': {'tradeId': tradeId},
    };
    if (_escrowTradeStatusTerminal(status)) return [viewThread];
    return [
      {
        'label': 'Arbitrate',
        'tool': 'hostr_escrow_trades_arbitrate',
        'arguments': {'tradeId': tradeId},
      },
      viewThread,
    ];
  }

  String _escrowTokenSymbol(EscrowDaemonContext context, String tokenAddress) {
    const zeroAddr = '0x0000000000000000000000000000000000000000';
    if (tokenAddress.toLowerCase() == zeroAddr) {
      return context.configuredChain.config.nativeDenomination;
    }
    final normalized = tokenAddress.toLowerCase();
    for (final entry in context.configuredChain.config.tokens.entries) {
      if (entry.value.address.toLowerCase() == normalized) return entry.key;
    }
    return '${tokenAddress.substring(0, 8)}…';
  }

  String _escrowTokenDenomination(
    EscrowDaemonContext context,
    String tokenAddress,
  ) {
    const zeroAddr = '0x0000000000000000000000000000000000000000';
    if (tokenAddress.toLowerCase() == zeroAddr) {
      return context.configuredChain.config.nativeDenomination;
    }
    final token = context.configuredChain.config.tokenByAddress(tokenAddress);
    return token?.denomination ?? _escrowTokenSymbol(context, tokenAddress);
  }

  String _trimDecimal(String value) {
    final trimmed = value.replaceFirst(RegExp(r'\.?0+$'), '');
    return trimmed.isEmpty || trimmed == '-' ? '0' : trimmed;
  }

  String _tokenAmountDisplay(EscrowDaemonContext context, TokenAmount amount) {
    final symbol = _escrowTokenSymbol(context, amount.token.address);
    final denomination = _escrowTokenDenomination(
      context,
      amount.token.address,
    );
    if (denomination == 'USD') {
      final decimal = amount.toDecimalString(maxDecimals: 2);
      return '\$${decimal.replaceFirst(RegExp(r'\.00$'), '')}';
    }
    final decimal = _trimDecimal(amount.toDecimalString(maxDecimals: 8));
    return '$decimal $symbol';
  }

  Future<Map<String, Object?>> _escrowTradeSnapshotCard(
    HostrSession session,
    EscrowDaemonContext context,
    TradeSnapshot snapshot,
  ) async {
    final group = _cachedEscrowReservationGroup(session, snapshot.tradeId);
    final listing = group == null ? null : _embeddedReservationListing(group);
    final status = snapshot.status.name;
    return {
      'type': 'escrow-trade-card',
      'tradeId': snapshot.tradeId,
      'title': _escrowTradeTitle(snapshot.tradeId, group),
      'status': status,
      'amount': _tokenAmountJson(snapshot.amount),
      'amountDisplay': _tokenAmountDisplay(context, snapshot.amount),
      'tokenSymbol': _escrowTokenSymbol(context, snapshot.amount.token.address),
      'tokenAddress': snapshot.amount.token.address,
      'tokenDecimals': snapshot.amount.token.decimals,
      'lastTxHash': snapshot.lastTxHash,
      'updatedAt': snapshot.updatedAt.toIso8601String(),
      if (snapshot.updatedBlockNum != null)
        'updatedBlockNum': snapshot.updatedBlockNum,
      if (group != null) 'reservationGroup': _reservationGroupJson(group),
      if (listing != null) 'listing': listingSummary(listing),
      'participants': await _escrowTradeParticipantsJson(
        session,
        snapshot.tradeId,
        group: group,
      ),
      'nextActions': _escrowTradeNextActions(snapshot.tradeId, status),
      'source': 'session.escrowDaemon.trades',
    };
  }

  Future<Map<String, Object?>> _escrowTradeCard(
    HostrSession session,
    ({EscrowDaemonContext context, dynamic signer}) escrow,
    String tradeId,
  ) async {
    final events = await _escrowEventsFor(
      escrow.context.contract,
      ContractEventsParams(tradeId: tradeId),
    );
    final onChain = await _readOnChainTrade(escrow.context.contract, tradeId);
    if (onChain != null &&
        onChain.arbiter.toString().toLowerCase() !=
            escrow.signer.address.toString().toLowerCase()) {
      throw HostrCliException(
        'escrow_trade_not_assigned',
        'Trade $tradeId is not assigned to the authenticated escrow account.',
        details: {
          'tradeId': tradeId,
          'authenticatedEscrowAddress': escrow.signer.address.toString(),
          'tradeArbiterAddress': onChain.arbiter.toString(),
        },
      );
    }

    final lookup = await _reservationLookupByTradeId(
      session.hostr,
      tradeId,
      waitSeconds: 0,
    );
    final group = _cachedEscrowReservationGroup(session, tradeId);
    final summary = _escrowTradeSummary(tradeId, events);
    final status = summary['status']?.toString() ?? 'unknown';
    return {
      'type': 'escrow-trade-card',
      'tradeId': tradeId,
      'title': _escrowTradeTitle(tradeId, group),
      ...summary,
      'eventCount': events.length,
      'events': events.map(_escrowEventJson).toList(),
      if (onChain != null) 'onChain': _onChainTradeJson(onChain),
      'participants': await _escrowTradeParticipantsJson(
        session,
        tradeId,
        group: group,
      ),
      'nextActions': _escrowTradeNextActions(tradeId, status),
      if (lookup['found'] == true) 'reservationLookup': lookup,
    };
  }

  Future<OnChainTrade?> _readOnChainTrade(
    SupportedEscrowContract contract,
    String tradeId,
  ) async {
    try {
      return await contract.getTrade(tradeId);
    } catch (_) {
      return null;
    }
  }

  Map<String, Object?> _escrowTradeSummary(
    String tradeId,
    List<EscrowEvent> events,
  ) {
    var status = events.isEmpty ? 'not_found' : 'unknown';
    TokenAmount? amount;
    TokenAmount? bondAmount;
    String? lastTxHash;
    int? updatedBlockNum;
    for (final event in events) {
      lastTxHash = event.transactionHash;
      updatedBlockNum = event.blockNum;
      if (event is EscrowFundedEvent) {
        status = 'funded';
        amount = event.amount;
        bondAmount = event.bondAmount;
      } else if (event is EscrowArbitratedEvent) {
        status = 'arbitrated';
      } else if (event is EscrowReleasedEvent) {
        status = 'released';
      } else if (event is EscrowClaimedEvent) {
        status = 'claimed';
      }
    }
    final result = <String, Object?>{
      'status': status,
      if (amount != null) 'amount': _tokenAmountJson(amount),
      if (bondAmount != null) 'bondAmount': _tokenAmountJson(bondAmount),
    };
    if (lastTxHash != null) result['lastTxHash'] = lastTxHash;
    if (updatedBlockNum != null) result['updatedBlockNum'] = updatedBlockNum;
    return result;
  }

  Map<String, Object?> _escrowEventJson(EscrowEvent event) => {
    'type': event.runtimeType.toString(),
    'tradeId': event.tradeId,
    'txHash': event.transactionHash,
    'blockNum': event.blockNum,
    'chainId': event.chainId,
    'contractAddress': event.contractAddress,
    'transactionIndex': event.transactionIndex,
    'logIndex': event.logIndex,
    if (event is EscrowFundedEvent) ...{
      'amount': _tokenAmountJson(event.amount),
      if (event.bondAmount != null)
        'bondAmount': _tokenAmountJson(event.bondAmount!),
      'unlockAt': event.unlockAt,
    },
    if (event is EscrowArbitratedEvent) ...{
      'paymentForwarded': event.paymentForwarded,
      'bondForwarded': event.bondForwarded,
    },
  };

  Map<String, Object?> _onChainTradeJson(OnChainTrade trade) => {
    'isActive': trade.isActive,
    'buyer': trade.buyer.toString(),
    'seller': trade.seller.toString(),
    'arbiter': trade.arbiter.toString(),
    'token': trade.token.toString(),
    'paymentAmount': trade.paymentAmount.toString(),
    'bondAmount': trade.bondAmount.toString(),
    'unlockAt': trade.unlockAt.toString(),
    'escrowFee': trade.escrowFee.toString(),
  };

  Map<String, Object?> _tokenAmountJson(TokenAmount amount) => {
    'value': amount.toDecimalString(),
    'smallestUnitValue': amount.value.toString(),
    'token': amount.token.toJson(),
  };

  Future<Map<String, Object?>> _swapsWatch(
    String tokenPubkey,
    HostrSession session,
    HostrSwapsWatchInput input, {
    HostrCancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Swap watch',
    );
    final requestedTradeId = input.tradeId;
    if (requestedTradeId != null && requestedTradeId.isNotEmpty) {
      final lookup = await _reservationLookupByTradeId(
        session.hostr,
        requestedTradeId,
        waitSeconds: input.reservationWaitSeconds,
        cancellationToken: cancellationToken,
      );
      if (lookup['committed'] == true) {
        return {
          'swapId': input.swapId,
          'tradeId': requestedTradeId,
          'stateName': 'reservation_committed',
          'isTerminal': true,
          'reservationLookup': lookup,
        };
      }
    }
    final beforeJson = await session.hostr.operationStateStore.read(
      'swap_in',
      input.swapId,
    );
    if (beforeJson == null) {
      final tradeId = input.tradeId;
      if (tradeId == null || tradeId.isEmpty) {
        throw HostrCliException(
          'swap_not_found',
          'No persisted swap-in state found for swap id.',
          details: {'swapId': input.swapId},
        );
      }
      return {
        'swapId': input.swapId,
        'tradeId': tradeId,
        'swapNotFound': true,
        'stateName': 'not_found',
        'isTerminal': true,
        'reservationLookup': await _reservationLookupByTradeId(
          session.hostr,
          tradeId,
          waitSeconds: input.reservationWaitSeconds,
          cancellationToken: cancellationToken,
        ),
      };
    }
    var before = SwapInState.fromJson(beforeJson);
    final beforeTradeId =
        input.tradeId ?? _tradeIdFromSwapStateJson(beforeJson);
    return await _swapWatchJson(
      hostr: session.hostr,
      swapId: input.swapId,
      tradeId: beforeTradeId,
      reservationWaitSeconds: input.reservationWaitSeconds,
      resolved: 0,
      state: before,
      cancellationToken: cancellationToken,
    );
  }

  Future<Map<String, Object?>> _swapsRecoverAll(
    String tokenPubkey,
    HostrSession session,
    HostrSwapsRecoverAllInput input,
  ) async {
    await _requireAuthenticatedPubkey(
      tokenPubkey,
      session,
      action: 'Swap recovery',
    );
    final pending = await _pendingSwapStates(session.hostr);
    if (input.dryRun) {
      return {
        'dryRun': true,
        'wouldRecover': pending,
        'count': pending.length,
        'background': input.background,
      };
    }
    await session.hostr.evm.init();
    final resolved = await session.hostr.evm.recoverStaleOperations(
      isBackground: input.background,
    );
    final remaining = await _pendingSwapStates(session.hostr);
    return {
      'dryRun': false,
      'resolved': resolved,
      'remainingCount': remaining.length,
      'remaining': remaining,
    };
  }
}

class SignerRequestNotificationBridge {
  SignerRequestNotificationBridge(this._notifications);

  static const _nonBlockingSignerRequestEventKinds = <int>{
    kNostrKindReceivedHeartbeat,
  };

  final HostrDaemonNotificationSink? _notifications;
  final Map<String, StreamSubscription<List<PendingSignerRequest>>>
  _subscriptions = {};
  final Map<String, Object?> _attachedAccounts = {};
  final Map<String, Set<String>> _seenRequestIds = {};
  final Map<String, Set<String>> _operationTokens = {};
  final Map<String, Map<String, String?>> _operationTraceIds = {};

  void attachSession({
    required String tokenPubkey,
    required String activePubkey,
    required HostrSession session,
  }) {
    if (_notifications == null) return;
    final account = session.hostr.ndk.accounts.accounts[activePubkey];
    if (account == null) return;
    if (identical(_attachedAccounts[activePubkey], account)) {
      return;
    }

    _attachedAccounts[activePubkey] = account;
    _seenRequestIds[activePubkey] = account.pendingRequests
        .map((request) => request.id)
        .toSet();
    unawaited(_subscriptions.remove(activePubkey)?.cancel());
    _subscriptions[activePubkey] = account.pendingRequestsStream.listen((
      requests,
    ) {
      _handlePendingRequests(
        tokenPubkey: tokenPubkey,
        activePubkey: activePubkey,
        requests: requests,
      );
    });
  }

  void addOperation({
    required String activePubkey,
    required String token,
    String? traceId,
  }) {
    if (_notifications == null) return;
    final normalized = token.trim();
    if (normalized.isEmpty) return;
    _operationTokens
        .putIfAbsent(activePubkey, () => <String>{})
        .add(normalized);
    _operationTraceIds.putIfAbsent(
      activePubkey,
      () => <String, String?>{},
    )[normalized] = traceId;
  }

  void removeOperation({required String activePubkey, required String token}) {
    final normalized = token.trim();
    if (normalized.isEmpty) return;
    final tokens = _operationTokens[activePubkey];
    tokens?.remove(normalized);
    _operationTraceIds[activePubkey]?.remove(normalized);
    if (tokens != null && tokens.isEmpty) {
      _operationTokens.remove(activePubkey);
      _operationTraceIds.remove(activePubkey);
    }
  }

  void _handlePendingRequests({
    required String tokenPubkey,
    required String activePubkey,
    required List<PendingSignerRequest> requests,
  }) {
    final currentIds = requests.map((request) => request.id).toSet();
    final seen = _seenRequestIds.putIfAbsent(activePubkey, () => <String>{});
    final newRequests = requests
        .where((request) => !seen.contains(request.id))
        .where(_shouldNotifyForRequest)
        .toList(growable: false);
    _seenRequestIds[activePubkey] = currentIds;

    final tokens = _operationTokens[activePubkey];
    if (tokens == null || tokens.isEmpty) return;
    final traceIds = _operationTraceIds[activePubkey] ?? const {};
    for (final request in newRequests) {
      for (final token in tokens) {
        final traceId = traceIds[token];
        _notifications?.call('hostr.signer.pending', {
          'operationToken': token,
          'traceId': ?traceId,
          'tokenPubkey': tokenPubkey,
          'activePubkey': activePubkey,
          'requestId': request.id,
          'signerPubkey': request.signerPubkey,
          'signerMethod': request.method.protocolString,
          'eventKind': request.event?.kind,
          'eventLabel': _eventKindDescription(request.event?.kind),
          'createdAt': request.createdAt.toIso8601String(),
          'message': _pendingMessage(request),
        });
      }
    }
  }

  bool _shouldNotifyForRequest(PendingSignerRequest request) {
    if (request.method != SignerMethod.signEvent) return true;
    final kind = request.event?.kind;
    if (kind == null) return true;
    return !_nonBlockingSignerRequestEventKinds.contains(kind);
  }

  String _pendingMessage(PendingSignerRequest request) {
    final label = _eventKindDescription(request.event?.kind);
    return 'Waiting for signer approval: approve the $label in your Nostr signer.';
  }

  String _eventKindDescription(int? kind) {
    return switch (kind) {
      kNostrKindProfile => 'profile metadata',
      kNostrKindListing => 'listing',
      kNostrKindReservation => 'reservation update',
      kNostrKindReview => 'review',
      kNostrKindCommitAuthorization => 'payment commit authorization',
      kNostrKindTradeKeyAuthorization => 'trade key authorization',
      kNostrKindHostrSeed => 'account recovery seed',
      kNostrKindReservationTransition => 'reservation transition',
      kNostrKindEscrowService => 'escrow service advertisement',
      kNostrKindEscrowMethod => 'escrow payment methods',
      kNostrKindEscrowServiceSelected => 'escrow selection',
      kNostrKindIdentityClaims => 'identity claim',
      kNostrKindLegacyDM => 'legacy direct message',
      kNostrKindDM => 'direct message',
      kNostrKindJsonMessage => 'Hostr message',
      kNostrKindSeenStatus => 'seen status',
      kNostrKindReaction => 'reaction',
      kNostrKindZapRequest => 'zap request',
      kNostrKindZapReceipt => 'zap receipt',
      kNostrKindConnect => 'Nostr Connect request',
      kNostrKindSeal => 'encrypted message seal',
      kNostrKindGiftWrap => 'encrypted message wrapper',
      kNostrKindDmRelays => 'direct message relay list',
      kNostrKindReceivedHeartbeat => 'heartbeat',
      kNostrKindSeenMessages => 'seen message marker',
      kNostrKindNWCInfo => 'Nostr Wallet Connect info',
      kNostrKindNWCRequest => 'Nostr Wallet Connect request',
      kNostrKindNWCResponse => 'Nostr Wallet Connect response',
      kNostrKindNWCNotification => 'Nostr Wallet Connect notification',
      kNostrKindBadgeAward => 'badge award',
      kNostrKindBadgeDefinition => 'badge definition',
      kNostrKindProfileBadges => 'profile badges',
      null => 'signer request',
      _ => 'Nostr event kind $kind',
    };
  }
}

Future<String> _requireAuthenticatedPubkey(
  String tokenPubkey,
  HostrSession session, {
  required String action,
}) async {
  if (!await session.auth.isAuthenticated()) {
    throw HostrCliException(
      'auth_required',
      '$action requires an active Hostr session.',
      details: _sessionReconnectHint(tokenPubkey),
    );
  }
  if (session.auth.needsBunkerRecovery &&
      !await session.auth.retryBunkerSessionRestore()) {
    throw HostrCliException(
      'auth_required',
      '$action requires the user to reconnect their Nostr signer.',
      details: _sessionReconnectHint(tokenPubkey),
    );
  }
  final activePubkey = session.auth.activePubkey;
  if (activePubkey == null || activePubkey.isEmpty) {
    throw HostrCliException(
      'auth_required',
      '$action requires an active Hostr pubkey.',
      details: _sessionReconnectHint(tokenPubkey),
    );
  }
  if (activePubkey != tokenPubkey) {
    throw HostrCliException(
      'session_pubkey_mismatch',
      'The active Hostr session does not match the MCP access token pubkey.',
      details: {'tokenPubkey': tokenPubkey, 'activePubkey': activePubkey},
    );
  }
  return activePubkey;
}

String _pubkeyFromNpub(String npub) {
  final trimmed = npub.trim();
  if (!trimmed.startsWith('npub1')) {
    throw HostrCliException(
      'invalid_npub',
      'Profile lookup requires a NIP-19 npub value.',
      details: {'npub': npub},
    );
  }
  try {
    final decoded = Helpers.decodeBech32(trimmed);
    final pubkey = decoded[0];
    if (pubkey.length == 64 && RegExp(r'^[0-9a-fA-F]+$').hasMatch(pubkey)) {
      return pubkey.toLowerCase();
    }
  } catch (_) {
    // Fall through to the consistent HostrCliException below.
  }
  throw HostrCliException(
    'invalid_npub',
    'Profile lookup requires a valid NIP-19 npub value.',
    details: {'npub': npub},
  );
}

Uri _blossomUploadUri(String serverUrl) {
  final uri = Uri.parse(serverUrl);
  if (uri.path.endsWith('/upload')) return uri;
  final basePath = uri.path.replaceFirst(RegExp(r'/+$'), '');
  return uri.replace(path: '$basePath/upload', query: '', fragment: '');
}

NostrConnect? _buildMcpNostrConnect(HostrSession session) {
  final envName = session.runtime.environment;
  final appName = switch (envName) {
    'prod' => 'Hostr',
    'staging' => 'Hostr (Staging)',
    _ => 'Hostr (Development)',
  };
  final appUrl = switch (envName) {
    'prod' => 'https://hostr.network',
    'staging' => 'https://ai.staging.hostr.network',
    _ => 'https://ai.hostr.development',
  };
  return buildNostrConnect(session.hostr, appName: appName, appUrl: appUrl);
}

Map<String, Object?> _nostrConnectJson(NostrConnect nostrConnect) {
  final uri = nostrConnect.nostrConnectURL;
  return {
    'nostrconnect': uri,
    'qr': renderTerminalQr(uri),
    'qrImage': renderQrImageDataUri(uri),
  };
}

Map<String, Object?> _sessionReconnectHint(String tokenPubkey) => {
  'sessionAction': 'hostr_session_connect',
  'tokenPubkey': tokenPubkey,
  'message': 'Scan this with your Nostr app to log in to your Hostr account.',
  'sessionInput': {'wait': false, 'regenerate': true},
  'then': {'wait': true, 'regenerate': false},
  'instructions':
      'Call hostr_session_connect with wait false to obtain a Nostr Connect QR/URI, show it with the user-friendly sign-in text, then immediately call hostr_session_connect with wait true to listen for the session connection and continue the intended Hostr action.',
  'assistantInstructions': [
    'Show the QR/URI with the text: "Scan this with your Nostr app to log in to your Hostr account."',
    'Do not stop after displaying the QR. Immediately call hostr_session_connect with wait=true and regenerate=false to listen for the session connection.',
    'After hostr_session_connect returns authenticated=true, retry or continue the Hostr action that required sign-in.',
  ],
};

Future<HostrCliException?> _staleSignerReconnectException(
  String tokenPubkey,
  HostrSession session,
  Object? error,
) async {
  if (!_isSignerNotAuthorizedError(error)) return null;
  await session.auth.markBunkerSessionRecoveryRequired(
    error ?? 'Signer request rejected: Not authorized',
  );
  return HostrCliException(
    'auth_required',
    'Your Nostr signer connection is no longer authorized. Reconnect your Hostr account with Nostr Connect, then retry the action.',
    retryable: true,
    details: {
      ..._sessionReconnectHint(tokenPubkey),
      'reason': 'signer_not_authorized',
      'originalError': error.toString(),
    },
  );
}

bool _isSignerNotAuthorizedError(Object? error) {
  if (error is SignerRequestRejectedException) {
    return _containsNotAuthorized(error.originalMessage);
  }
  if (error is HostrCliException) {
    return _containsNotAuthorized(error.message) ||
        _containsNotAuthorized(error.details);
  }
  return _containsNotAuthorized(error);
}

bool _containsNotAuthorized(Object? value) {
  if (value == null) return false;
  if (value is Map) {
    return value.values.any(_containsNotAuthorized);
  }
  if (value is Iterable) {
    return value.any(_containsNotAuthorized);
  }
  return value.toString().toLowerCase().contains('not authorized');
}

Future<List<Map<String, Object?>>> _replyReservationInTradeThread(
  Hostr hostr,
  Reservation reservation, {
  required Iterable<String> participants,
}) {
  final thread = _ensureTradeThread(
    hostr,
    tradeId: reservation.getDtag()!,
    participants: participants,
  );
  return _replyOnThread(thread, reservation);
}

Thread _ensureTradeThread(
  Hostr hostr, {
  required String tradeId,
  required Iterable<String> participants,
}) {
  final activePubkey = hostr.auth.getActiveKey().publicKey;
  return hostr.messaging.threads.ensureTradeConversation(
    tradeId: tradeId,
    participants: {activePubkey, ...participants},
  );
}

Future<List<Map<String, Object?>>> _replyOnThread(
  Thread thread,
  Nip01Event event,
) async {
  final futures = await thread.replyEvent(event);
  final nested = await Future.wait(futures);
  return nested
      .expand((responses) => responses)
      .map(relayResponseJson)
      .toList();
}

Future<Thread?> _hydrateTradeThread(
  Hostr hostr, {
  required String tradeId,
  Duration timeout = const Duration(seconds: 12),
}) async {
  final pubkey = hostr.auth.activePubkey;
  if (pubkey == null) return null;
  await hostr.userSubscriptions.start();
  await _waitForStreamStatus(
    hostr.userSubscriptions.giftwraps$.status,
    timeout: timeout,
  );
  return hostr.messaging.threads.findByConversationTag(tradeId).lastOrNull;
}

Future<T> _cancelable<T>(
  Future<T> future,
  HostrCancellationToken? cancellationToken,
) {
  if (cancellationToken == null) return future;
  cancellationToken.throwIfCancelled();
  final completer = Completer<T>();
  cancellationToken.onCancel(() {
    if (!completer.isCompleted) {
      completer.completeError(const HostrCancellationException());
    }
  });
  future.then(
    (value) {
      if (!completer.isCompleted) {
        completer.complete(value);
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    },
  );
  return completer.future;
}

Future<List<Reservation>> _waitForPublicReservationsByTradeId(
  Hostr hostr,
  String tradeId, {
  bool Function(List<Reservation> reservations)? until,
  Duration timeout = const Duration(seconds: 15),
  HostrCancellationToken? cancellationToken,
}) async {
  cancellationToken?.throwIfCancelled();
  final stream = hostr.userSubscriptions.allMyReservations$.stream;
  final byParticipant = <String, Reservation>{};

  void addIfMatches(Reservation reservation) {
    if (reservation.getDtag() != tradeId) return;
    byParticipant[reservation.pubKey] = reservation;
  }

  List<Reservation> latest() {
    final reservations = byParticipant.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return reservations;
  }

  bool isDone() {
    final reservations = latest();
    return until?.call(reservations) ?? reservations.isNotEmpty;
  }

  for (final reservation in stream.items) {
    addIfMatches(reservation);
  }
  if (isDone() || timeout <= Duration.zero) return latest();

  final completer = Completer<List<Reservation>>();
  Timer? timer;
  StreamSubscription<Reservation>? subscription;

  void complete() {
    if (!completer.isCompleted) {
      completer.complete(latest());
    }
  }

  cancellationToken?.onCancel(() {
    if (!completer.isCompleted) {
      completer.completeError(const HostrCancellationException());
    }
  });

  subscription = stream.stream.listen(
    (reservation) {
      addIfMatches(reservation);
      if (isDone()) complete();
    },
    onError: (_) {
      complete();
    },
  );
  timer = Timer(timeout, complete);

  try {
    return await _cancelable(completer.future, cancellationToken);
  } finally {
    timer.cancel();
    await subscription.cancel();
  }
}

Future<List<ResolvedValidatedReservationGroupParticipants>>
_resolvedReservationGroupSnapshot(
  StreamWithStatus<List<ResolvedValidatedReservationGroupParticipants>>
  source, {
  Duration timeout = const Duration(seconds: 12),
}) async {
  if (source.items.isNotEmpty || timeout <= Duration.zero) {
    return source.items.isEmpty ? const [] : source.items.last;
  }

  final completer =
      Completer<List<ResolvedValidatedReservationGroupParticipants>>();
  Timer? timer;
  StreamSubscription<List<ResolvedValidatedReservationGroupParticipants>>?
  itemSubscription;
  StreamSubscription<StreamStatus>? statusSubscription;

  List<ResolvedValidatedReservationGroupParticipants> latest() =>
      source.items.isEmpty ? const [] : source.items.last;

  void complete([List<ResolvedValidatedReservationGroupParticipants>? items]) {
    if (!completer.isCompleted) {
      completer.complete(items ?? latest());
    }
  }

  itemSubscription = source.stream.listen(complete, onError: (_) => complete());
  statusSubscription = source.status.listen((status) {
    if (status is StreamStatusQueryComplete || status is StreamStatusLive) {
      complete();
    }
    if (status is StreamStatusError) {
      complete();
    }
  });
  timer = Timer(timeout, complete);

  try {
    return await completer.future;
  } finally {
    timer.cancel();
    await itemSubscription.cancel();
    await statusSubscription.cancel();
  }
}

Future<Map<String, Object?>> _reservationLookupByTradeId(
  Hostr hostr,
  String tradeId, {
  int waitSeconds = 15,
  HostrCancellationToken? cancellationToken,
}) async {
  final reservations = await _waitForPublicReservationsByTradeId(
    hostr,
    tradeId,
    until: (reservations) => reservations.any(
      (reservation) => reservation.stage == ReservationStage.commit,
    ),
    timeout: Duration(seconds: waitSeconds),
    cancellationToken: cancellationToken,
  );
  cancellationToken?.throwIfCancelled();
  final committed = reservations
      .where((reservation) => reservation.stage == ReservationStage.commit)
      .toList();
  final group = reservations.isEmpty
      ? null
      : ReservationGroup(reservations: reservations);
  Listing? listing;
  final listingAnchor = group?.listingAnchor;
  if (listingAnchor != null && listingAnchor.isNotEmpty) {
    try {
      listing = await hostr.listings.getOneByAnchor(listingAnchor);
    } catch (_) {
      listing = null;
    }
  }
  return {
    'tradeId': tradeId,
    'found': reservations.isNotEmpty,
    'committed': committed.isNotEmpty,
    'count': reservations.length,
    if (group != null) 'group': _reservationGroupJson(group),
    if (listing != null) 'listing': listingSummary(listing),
    if (committed.isNotEmpty) 'committedReservation': eventJson(committed.last),
    'reservations': reservations.map(eventJson).toList(),
  };
}

Future<void> _waitForStreamStatus(
  Stream<StreamStatus> status, {
  Duration timeout = const Duration(seconds: 12),
}) async {
  try {
    await status
        .firstWhere(
          (status) =>
              status is StreamStatusQueryComplete || status is StreamStatusLive,
        )
        .timeout(timeout);
  } on TimeoutException {
    // Continue with whatever the replay source has already hydrated.
  }
}

Future<List<Nip01Event>> _hydrateThreadInbox(
  Hostr hostr, {
  required String name,
  int limit = 200,
  Duration timeout = const Duration(seconds: 12),
}) async {
  final pubkey = hostr.auth.activePubkey;
  if (pubkey == null) return const [];
  await hostr.userSubscriptions.start();
  await _waitForStreamStatus(
    hostr.userSubscriptions.giftwraps$.status,
    timeout: timeout,
  );
  return hostr.userSubscriptions.giftwraps$.items.take(limit).toList();
}

Thread? _resolveThread(
  Hostr hostr, {
  String? threadAnchor,
  String? conversation,
  String? tradeId,
  Iterable<String> recipientPubkeys = const [],
}) {
  final threads = hostr.messaging.threads;
  final anchor = threadAnchor?.trim();
  if (anchor != null && anchor.isNotEmpty) {
    final exact = threads.threads[anchor];
    if (exact != null) return exact;
  }

  final tag = (tradeId ?? conversation)?.trim();
  final activePubkey = hostr.auth.activePubkey;
  final recipients = recipientPubkeys
      .where((pubkey) => pubkey.trim().isNotEmpty)
      .map((pubkey) => pubkey.trim())
      .toSet();
  if (tag != null &&
      tag.isNotEmpty &&
      activePubkey != null &&
      recipients.isNotEmpty) {
    final exact = threads.findTradeThread(
      tradeId: tag,
      participants: {activePubkey, ...recipients},
    );
    if (exact != null) return exact;
  }

  if (tag != null && tag.isNotEmpty) {
    final matches = threads.findByConversationTag(tag);
    if (matches.length == 1) return matches.single;
    if (recipients.isNotEmpty) {
      final filtered = matches.where((thread) {
        final participants = thread.state.value.participantPubkeys.toSet();
        return recipients.every(participants.contains);
      }).toList();
      if (filtered.length == 1) return filtered.single;
      if (filtered.isNotEmpty) {
        filtered.sort(
          (a, b) => a.lastActivityTimestamp.compareTo(b.lastActivityTimestamp),
        );
        return filtered.last;
      }
    }
    if (matches.isNotEmpty) {
      matches.sort(
        (a, b) => a.lastActivityTimestamp.compareTo(b.lastActivityTimestamp),
      );
      return matches.last;
    }
  }

  if (activePubkey != null && recipients.isNotEmpty) {
    final conversationId = Threads.conversationIdentifier({
      activePubkey,
      ...recipients,
    }, conversationTag: tag ?? '');
    return threads.threads[conversationId];
  }
  return null;
}

Future<String?> _pubkeyForThreadRole(
  Hostr hostr, {
  required String? tradeId,
  required String role,
  Thread? thread,
  Duration timeout = const Duration(seconds: 12),
}) async {
  final normalized = role.trim().toLowerCase();
  final state = thread?.state.value;
  if (normalized == 'host' || normalized == 'seller') {
    final requests = state?.reservationRequests ?? const <Reservation>[];
    for (final request in requests.reversed) {
      final anchor = request.parsedTags.listingAnchor;
      if (anchor.isNotEmpty) {
        return getPubKeyFromAnchor(anchor);
      }
    }
  }
  if (normalized == 'escrow') {
    final selected = state?.selectedEscrows.lastOrNull;
    final selectedPubkey = selected?.service.escrowPubkey;
    if (selectedPubkey != null && selectedPubkey.isNotEmpty) {
      return selectedPubkey;
    }
  }

  if (tradeId == null || tradeId.trim().isEmpty) return null;
  final reservations = await _waitForPublicReservationsByTradeId(
    hostr,
    tradeId,
    timeout: timeout,
    until: (items) => items.isNotEmpty,
  );
  if (reservations.isEmpty) return null;
  final group = ReservationGroup(reservations: reservations);
  return switch (normalized) {
    'host' || 'seller' => group.sellerPubkey,
    'guest' || 'buyer' => group.buyerPubkey,
    'escrow' => group.escrowPubkey,
    _ => null,
  };
}

class _EscrowTradeThreadPlan {
  const _EscrowTradeThreadPlan({
    required this.thread,
    required this.participantPubkeys,
    required this.recipientPubkeys,
    required this.rolePubkeys,
  });

  final Thread thread;
  final List<String> participantPubkeys;
  final List<String> recipientPubkeys;
  final Map<String, String> rolePubkeys;
}

Future<_EscrowTradeThreadPlan> _resolveEscrowTradeThreadPlan(
  Hostr hostr, {
  required String activePubkey,
  required String tradeId,
  Thread? tradeThread,
  Duration timeout = const Duration(seconds: 12),
}) async {
  final normalizedTradeId = tradeId.trim();
  if (normalizedTradeId.isEmpty) {
    throw HostrCliException(
      'trade_id_required',
      'Messaging escrow requires a concrete reservation tradeId so buyer, seller, and escrow are all included in the thread.',
    );
  }

  final resolvedItem = await _resolvedReservationGroupForTradeId(
    hostr,
    normalizedTradeId,
    timeout: timeout,
  );
  final resolvedParticipants = resolvedItem?.participants;
  final group = resolvedItem?.group;
  final state = tradeThread?.state.value;

  String? sellerPubkey =
      resolvedParticipants?.resolvedParticipantPubkeyForRole('seller') ??
      group?.sellerPubkey;
  String? buyerPubkey =
      resolvedParticipants?.resolvedParticipantPubkeyForRole('buyer') ??
      group?.buyerPubkey;
  String? escrowPubkey =
      resolvedParticipants?.resolvedParticipantPubkeyForRole('escrow') ??
      group?.escrowPubkey ??
      state?.selectedEscrows.lastOrNull?.service.escrowPubkey;

  final seenParticipants = <String>{
    activePubkey,
    if (state != null) ...state.participantPubkeys,
    if (state != null) ...state.counterpartyPubkeys,
  };

  for (final request
      in state?.reservationRequests.reversed ?? const <Reservation>[]) {
    seenParticipants.add(request.pubKey);
    seenParticipants.addAll(request.parsedTags.getTags('p'));
    final anchor = request.parsedTags.listingAnchor;
    if ((sellerPubkey == null || sellerPubkey.isEmpty) && anchor.isNotEmpty) {
      sellerPubkey = getPubKeyFromAnchor(anchor);
    }
    buyerPubkey ??= request.parsedTags.getTagValueByMarker('p', 'buyer');
    escrowPubkey ??= request.parsedTags.getTagValueByMarker('p', 'escrow');
  }

  if ((sellerPubkey == null || sellerPubkey.isEmpty) && state != null) {
    sellerPubkey = await _pubkeyForThreadRole(
      hostr,
      tradeId: normalizedTradeId,
      role: 'seller',
      thread: tradeThread,
      timeout: timeout,
    );
  }
  if ((escrowPubkey == null || escrowPubkey.isEmpty) && state != null) {
    escrowPubkey = await _pubkeyForThreadRole(
      hostr,
      tradeId: normalizedTradeId,
      role: 'escrow',
      thread: tradeThread,
      timeout: timeout,
    );
  }

  if (buyerPubkey == null || buyerPubkey.isEmpty) {
    final candidates = seenParticipants
        .where(
          (pubkey) =>
              pubkey.isNotEmpty &&
              pubkey != sellerPubkey &&
              pubkey != escrowPubkey,
        )
        .toSet();
    if (activePubkey != sellerPubkey && activePubkey != escrowPubkey) {
      buyerPubkey = activePubkey;
    } else if (candidates.length == 1) {
      buyerPubkey = candidates.single;
    }
  }

  final missingRoles = <String>[
    if (sellerPubkey == null || sellerPubkey.isEmpty) 'seller',
    if (buyerPubkey == null || buyerPubkey.isEmpty) 'buyer',
    if (escrowPubkey == null || escrowPubkey.isEmpty) 'escrow',
  ];
  if (missingRoles.isNotEmpty) {
    throw HostrCliException(
      'trade_participants_not_found',
      'Cannot message escrow until the tradeId resolves to seller, buyer, and escrow participants.',
      details: {'tradeId': normalizedTradeId, 'missingRoles': missingRoles},
    );
  }

  final rolePubkeys = <String, String>{
    'seller': sellerPubkey!,
    'buyer': buyerPubkey!,
    'escrow': escrowPubkey!,
  };
  final participantPubkeys = rolePubkeys.values.toSet();
  if (!participantPubkeys.contains(activePubkey)) {
    throw HostrCliException(
      'active_user_not_trade_participant',
      'Cannot message escrow for a trade unless the authenticated user is the buyer, seller, or escrow participant.',
      details: {
        'tradeId': normalizedTradeId,
        'activePubkey': activePubkey,
        'roles': rolePubkeys,
      },
    );
  }

  final thread = hostr.messaging.threads.ensureTradeConversation(
    tradeId: normalizedTradeId,
    participants: participantPubkeys,
  );
  thread.configureConversation(
    conversationTag: normalizedTradeId,
    participants: participantPubkeys,
  );

  return _EscrowTradeThreadPlan(
    thread: thread,
    participantPubkeys: participantPubkeys.toList()..sort(),
    recipientPubkeys:
        participantPubkeys.where((pubkey) => pubkey != activePubkey).toList()
          ..sort(),
    rolePubkeys: rolePubkeys,
  );
}

Future<ResolvedValidatedReservationGroupParticipants?>
_resolvedReservationGroupForTradeId(
  Hostr hostr,
  String tradeId, {
  Duration timeout = const Duration(seconds: 12),
}) async {
  final snapshots = await Future.wait([
    _resolvedReservationGroupSnapshot(
      hostr.userSubscriptions.myResolvedTripsList$,
      timeout: timeout,
    ),
    _resolvedReservationGroupSnapshot(
      hostr.userSubscriptions.myResolvedHostingsList$,
      timeout: timeout,
    ),
  ]);
  final matches = snapshots
      .expand((items) => items)
      .where((item) => item.group.tradeId == tradeId)
      .toList();
  if (matches.isEmpty) return null;
  final valid = matches.where((item) => item.validation is Valid).toList();
  return valid.isNotEmpty ? valid.last : matches.last;
}

List<String> _threadRecipients(Thread thread, String activePubkey) {
  return {
      ...thread.state.value.counterpartyPubkeys,
      ...thread.state.value.participantPubkeys,
    }.where((pubkey) => pubkey.isNotEmpty && pubkey != activePubkey).toList()
    ..sort();
}

Future<Map<String, Object?>> _threadProfileSummaries(
  Hostr hostr,
  Iterable<Thread> threads, {
  required String activePubkey,
}) async {
  final pubkeys = <String>{
    for (final thread in threads) ..._threadRecipients(thread, activePubkey),
  };
  final profiles = <String, Object?>{};
  await Future.wait(
    pubkeys.map((pubkey) async {
      final profile = await hostr.metadata.loadMetadata(pubkey);
      profiles[pubkey] = _profileSummary(pubkey, profile);
    }),
  );
  return profiles;
}

Future<Map<String, Object?>> _profileSummariesForPubkeys(
  Hostr hostr,
  Iterable<String> pubkeys,
) async {
  final unique = pubkeys.where((pubkey) => pubkey.isNotEmpty).toSet();
  final profiles = <String, Object?>{};
  await Future.wait(
    unique.map((pubkey) async {
      final profile = await hostr.metadata.loadMetadata(pubkey);
      profiles[pubkey] = _profileSummary(pubkey, profile);
    }),
  );
  return profiles;
}

Future<Map<String, Object?>> _resolvedReservationCollectionItemJson(
  Hostr hostr,
  ResolvedValidatedReservationGroupParticipants item, {
  required String mode,
}) async {
  final group = item.group;
  final sellerPubkey =
      item.participants.resolvedParticipantPubkeyForRole('seller') ??
      group.sellerPubkey;
  final buyerPubkey =
      item.participants.resolvedParticipantPubkeyForRole('buyer') ??
      group.buyerPubkey;
  final escrowPubkey =
      item.participants.resolvedParticipantPubkeyForRole('escrow') ??
      group.escrowPubkey;
  final rolePubkeys = <String, String>{
    if (sellerPubkey.isNotEmpty) 'seller': sellerPubkey,
    if (buyerPubkey != null && buyerPubkey.isNotEmpty) 'buyer': buyerPubkey,
    if (escrowPubkey != null && escrowPubkey.isNotEmpty) 'escrow': escrowPubkey,
  };
  final profiles = <String, Object?>{};
  await Future.wait(
    rolePubkeys.entries.map((entry) async {
      final profile = await hostr.metadata.loadMetadata(entry.value);
      profiles[entry.key] = _profileSummary(entry.value, profile);
    }),
  );
  final listing = _embeddedReservationListing(group);
  return {
    'found': true,
    'mode': mode,
    'tradeId': group.tradeId,
    'valid': item.validation is Valid<ReservationGroup>,
    'group': _reservationGroupJson(group),
    if (listing != null) 'listing': listingSummary(listing),
    'participants': {
      'rawGroupId': item.participants.rawGroupId,
      'resolvedGroupId': item.participants.resolvedGroupId,
      'rawParticipantSet': item.participants.rawParticipantSet.toList()..sort(),
      'resolvedParticipantSet':
          item.participants.resolvedParticipantSet.toList()..sort(),
      'hasResolvedParticipants': item.participants.hasResolvedParticipants,
      'roles': rolePubkeys,
      'profiles': profiles,
    },
  };
}

Map<String, Object?> _profileSummary(String pubkey, ProfileMetadata? profile) {
  final metadata = profile?.metadata;
  final name = metadata?.displayName ?? metadata?.name ?? _shortPubkey(pubkey);
  return {
    'pubkey': pubkey,
    'name': name,
    if (metadata?.name != null && metadata!.name!.isNotEmpty)
      'profileName': metadata.name,
    if (metadata?.displayName != null && metadata!.displayName!.isNotEmpty)
      'displayName': metadata.displayName,
    if (metadata?.picture != null && metadata!.picture!.isNotEmpty)
      'picture': metadata.picture,
    if (metadata?.nip05 != null && metadata!.nip05!.isNotEmpty)
      'nip05': metadata.nip05,
  };
}

String _shortPubkey(String pubkey) =>
    pubkey.length <= 12 ? pubkey : '${pubkey.substring(0, 8)}...';

Future<KeyPair> _activeReservationKeyPair(
  Hostr hostr, {
  required String sellerPubkey,
  required String tradeId,
}) async {
  final active = hostr.auth.getActiveKey();
  if (active.publicKey == sellerPubkey) return active;
  await hostr.accountSeedStore.ensureReady();
  final accountIndex = await hostr.tradeAccountAllocator
      .findTradeAccountIndexByTradeId(tradeId);
  return hostr.auth.hd.getTradeKeyPair(accountIndex: accountIndex);
}

Map<String, Object?> _reservationGroupJson(ReservationGroup group) {
  final listing = _embeddedReservationListing(group);
  return {
    'groupId': group.groupId,
    'tradeId': group.tradeId,
    'listingAnchor': group.listingAnchor,
    if (listing != null && listing.title.isNotEmpty)
      'listingTitle': listing.title,
    'sellerPubkey': group.sellerPubkey,
    'buyerPubkey': group.buyerPubkey,
    'escrowPubkey': group.escrowPubkey,
    'stage': group.stage.name,
    'cancelled': group.cancelled,
    'active': group.isActive,
    'confirmed': group.isConfirmed,
    'start': group.start?.toUtc().toIso8601String(),
    'end': group.end?.toUtc().toIso8601String(),
    'reservations': group.reservations.map(eventJson).toList(),
  };
}

Listing? _embeddedReservationListing(ReservationGroup group) {
  for (final reservation in group.reservations.reversed) {
    final listing = reservation.proof?.listing;
    if (listing != null) return listing;
  }
  return null;
}

Map<String, Object?> _threadJson(
  Thread thread, {
  Map<String, Object?> profiles = const {},
}) {
  final state = thread.state.value;
  final profileList = _threadRecipients(thread, state.ourPubkey)
      .map((pubkey) => profiles[pubkey])
      .whereType<Map<String, Object?>>()
      .toList();
  return {
    'anchor': thread.anchor,
    'conversation': thread.conversationTag,
    'participantPubkeys': state.participantPubkeys,
    'counterpartyPubkeys': state.counterpartyPubkeys,
    'counterparties': profileList,
    'unreadCount': state.unreadCount(state.ourPubkey),
    'reservationRequests': state.reservationRequests.map(eventJson).toList(),
    'textMessages': state.textMessages.map(eventJson).toList(),
    'events': state.events.map(eventJson).toList(),
  };
}

Future<Map<String, Object?>> _threadViewJson(
  Hostr hostr,
  Thread thread, {
  required String activePubkey,
  int limit = 50,
}) async {
  final state = thread.state.value;
  final participantPubkeys = {
    activePubkey,
    ...state.participantPubkeys,
    ...state.counterpartyPubkeys,
  };
  final profiles = await _profileSummariesForPubkeys(hostr, participantPubkeys);
  final messages = state.textMessages;
  final visibleMessages = messages.length > limit
      ? messages.sublist(messages.length - limit)
      : messages;
  final counterparties = _threadRecipients(thread, activePubkey)
      .map((pubkey) => profiles[pubkey])
      .whereType<Map<String, Object?>>()
      .toList();
  final title = _threadTitle(thread, counterparties: counterparties);
  return {
    'type': 'thread-view',
    'anchor': thread.anchor,
    if (thread.conversationTag.isNotEmpty) 'tradeId': thread.conversationTag,
    if (thread.conversationTag.isNotEmpty)
      'conversation': thread.conversationTag,
    'title': title,
    'counterparties': counterparties,
    'unreadCount': state.unreadCount(activePubkey),
    'messageCount': messages.length,
    'hasMoreMessages': messages.length > visibleMessages.length,
    'messages': visibleMessages
        .map(
          (message) => _threadMessageJson(
            message,
            activePubkey: activePubkey,
            profiles: profiles,
          ),
        )
        .toList(),
    'reservationRequests': state.reservationRequests.map(eventJson).toList(),
  };
}

Map<String, Object?> _sentTextEventJson(
  Nip01Event event, {
  required String activePubkey,
}) {
  return {
    'id': event.id,
    'senderPubkey': event.pubKey,
    'sentByUser': event.pubKey == activePubkey,
    'content': event.content,
    'createdAt': DateTime.fromMillisecondsSinceEpoch(
      event.createdAt * 1000,
      isUtc: true,
    ).toUtc().toIso8601String(),
  };
}

String _threadTitle(
  Thread thread, {
  required List<Map<String, Object?>> counterparties,
}) {
  for (final request in thread.state.value.reservationRequests.reversed) {
    final listing = request.proof?.listing;
    final title = listing?.title;
    if (title != null && title.isNotEmpty) return title;
  }
  if (counterparties.isNotEmpty) {
    final names = counterparties
        .map((profile) => profile['name']?.toString())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .join(', ');
    if (names.isNotEmpty) return 'Conversation with $names';
  }
  if (thread.conversationTag.isNotEmpty) {
    final tag = thread.conversationTag;
    final short = tag.length <= 8 ? tag : tag.substring(0, 8);
    return 'Hostr thread $short';
  }
  return 'Hostr thread';
}

Map<String, Object?> _threadMessageJson(
  TextMessage message, {
  required String activePubkey,
  required Map<String, Object?> profiles,
}) {
  final profile = profiles[message.pubKey];
  final profileMap = profile is Map<String, Object?> ? profile : null;
  final senderName =
      profileMap?['name']?.toString() ?? _shortPubkey(message.pubKey);
  return {
    'id': message.id,
    'senderPubkey': message.pubKey,
    'senderName': senderName,
    'sentByUser': message.pubKey == activePubkey,
    'content': message.content,
    'createdAt': DateTime.fromMillisecondsSinceEpoch(
      message.createdAt * 1000,
      isUtc: true,
    ).toUtc().toIso8601String(),
  };
}

List<String> _swapNamespaces(String namespace) {
  if (namespace == 'swap_in' || namespace == 'swap_out') return [namespace];
  return const ['swap_in', 'swap_out'];
}

Future<List<Map<String, Object?>>> _pendingSwapStates(Hostr hostr) async {
  final pending = <Map<String, Object?>>[];
  for (final namespace in _swapNamespaces('all')) {
    final states = await hostr.operationStateStore.readAll(namespace);
    for (final state in states) {
      if (state['isTerminal'] == true) continue;
      pending.add({'namespace': namespace, 'state': state});
    }
  }
  return pending;
}

Future<Map<String, Object?>> _swapWatchJson({
  required Hostr hostr,
  required String swapId,
  required String? tradeId,
  required int reservationWaitSeconds,
  required int resolved,
  required SwapInState state,
  HostrCancellationToken? cancellationToken,
}) async {
  cancellationToken?.throwIfCancelled();
  final stateJson = state.toJson();
  final resolvedTradeId = tradeId ?? _tradeIdFromSwapStateJson(stateJson);
  final claimTxHash = state is SwapInCompleted ? state.data.claimTxHash : null;
  final externalPayment = _externalPaymentPromptFromSwapStateJson(
    stateJson,
    swapId: swapId,
  );
  final shouldLookupReservation =
      resolvedTradeId != null &&
      resolvedTradeId.isNotEmpty &&
      externalPayment == null &&
      (state.isTerminal || claimTxHash?.isNotEmpty == true);
  return {
    'swapId': swapId,
    'tradeId': resolvedTradeId,
    'resolved': resolved,
    'state': stateJson,
    'stateName': state.stateName,
    'isTerminal': state.isTerminal,
    'escrowProofAvailable': claimTxHash?.isNotEmpty == true,
    if (claimTxHash?.isNotEmpty == true) 'claimTxHash': claimTxHash,
    if (shouldLookupReservation)
      'reservationLookup': await _reservationLookupByTradeId(
        hostr,
        resolvedTradeId,
        waitSeconds: reservationWaitSeconds,
        cancellationToken: cancellationToken,
      ),
    ...externalPayment == null
        ? const <String, Object?>{}
        : {'externalPayment': externalPayment},
  };
}

String? _tradeIdFromSwapStateJson(Map<String, Object?> state) {
  for (final key in const ['tradeId', 'parentOperationId']) {
    final value = state[key]?.toString();
    if (value != null && value.isNotEmpty) return value;
  }
  final externalPayment = state['externalPayment'];
  if (externalPayment is Map) {
    final value = externalPayment['tradeId']?.toString();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

Map<String, Object?>? _externalPaymentPromptFromSwapStateJson(
  Map<String, Object?> state, {
  required String swapId,
}) {
  final paymentState = state['paymentState'];
  if (paymentState is! Map) return null;
  if (paymentState['state'] != 'externalRequired') return null;
  final callbackDetails = paymentState['callbackDetails'];
  if (callbackDetails is! Map) return null;
  final invoice = callbackDetails['paymentRequest']?.toString();
  if (invoice == null || invoice.isEmpty) return null;
  return {
    'type': 'lightning-invoice',
    'invoice': invoice,
    'qrImage': renderQrImageDataUri(invoice),
    'swapId': swapId,
    if (paymentState['params'] is Map) 'params': paymentState['params'],
    'message':
        'External Lightning payment required. Pay this invoice to continue the Hostr booking.',
  };
}

const _reservationTradeNamespace = 'reservation_trade';
const _reservationPaymentNamespace = 'reservation_payment';

Future<void> _persistTradeContext(
  Hostr hostr, {
  required String tradeId,
  required String listingAnchor,
  required String sellerPubkey,
  required Reservation reservation,
}) {
  return hostr.operationStateStore.write(_reservationTradeNamespace, tradeId, {
    'id': tradeId,
    'state': 'offered',
    'isTerminal': false,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
    'tradeId': tradeId,
    'listingAnchor': listingAnchor,
    'sellerPubkey': sellerPubkey,
    'reservation': eventJson(reservation),
  });
}

Map<String, Object?> _tradeContextJson({
  required String tradeId,
  required Listing listing,
  required Reservation reservation,
}) => {
  'tradeId': tradeId,
  'listingAnchor': listing.anchor,
  'sellerPubkey': listing.pubKey,
  'reservation': eventJson(reservation),
};

Future<void> _persistPaymentContext(
  Hostr hostr, {
  required String swapId,
  required String tradeId,
  required Listing listing,
  required Reservation reservation,
  required EscrowServiceSelected selectedEscrow,
  Reservation? committedReservation,
  bool terminal = false,
}) {
  return hostr.operationStateStore.write(_reservationPaymentNamespace, swapId, {
    'id': swapId,
    'state': terminal ? 'committed' : 'swap_created',
    'isTerminal': terminal,
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
    'swapId': swapId,
    'tradeId': tradeId,
    'listingAnchor': listing.anchor,
    'sellerPubkey': listing.pubKey,
    'reservation': eventJson(reservation),
    'selectedEscrow': eventJson(selectedEscrow),
    if (committedReservation != null)
      'committedReservation': eventJson(committedReservation),
  });
}

Nip01Event _eventFromJson(Map<String, dynamic> json) =>
    Nip01EventModel.fromJson(json);

Reservation? _reservationFromTradeContext(Map<String, dynamic> context) {
  for (final key in const ['reservation', 'event']) {
    final value = context[key];
    if (value is! Map) continue;
    try {
      return Reservation.fromNostrEvent(
        _eventFromJson(Map<String, dynamic>.from(value)),
      );
    } catch (_) {
      // Keep scanning; malformed optional event data should not hide a
      // persisted trade id that can be hydrated from relays.
    }
  }
  return null;
}

Future<Reservation?> _readPersistedTradeReservation(
  Hostr hostr,
  String tradeId,
) async {
  final context = await hostr.operationStateStore.read(
    _reservationTradeNamespace,
    tradeId,
  );
  if (context == null) return null;
  return _reservationFromTradeContext(context);
}

String _resolveNegotiationPubkey(
  List<Reservation> reservationRequests,
  String sellerPubkey,
  String activePubkey,
) {
  if (activePubkey == sellerPubkey) return activePubkey;
  for (final request in reservationRequests.reversed) {
    if (request.pubKey != sellerPubkey) return request.pubKey;
  }
  return reservationRequests.lastOrNull?.recipient ?? activePubkey;
}

({bool available, Map<String, Object?> details}) _payActionAvailable({
  required Listing listing,
  required List<Reservation> reservationRequests,
  required String activePubkey,
}) {
  final sellerPubkey = listing.pubKey;
  final role = activePubkey == sellerPubkey ? TradeRole.host : TradeRole.guest;
  final ourPubkey = _resolveNegotiationPubkey(
    reservationRequests,
    sellerPubkey,
    activePubkey,
  );
  final actions = ReservationRequestActions.resolve(
    reservationRequests,
    listing,
    ourPubkey,
    role,
  );
  return (
    available: actions.contains(TradeAction.pay),
    details: {
      'role': role.name,
      'ourNegotiationPubkey': ourPubkey,
      'actions': actions.map(_publicTradeActionName).toList(),
      'latestOffer': reservationRequests.lastOrNull == null
          ? null
          : eventJson(reservationRequests.last),
    },
  );
}

String _publicTradeActionName(TradeAction action) =>
    action == TradeAction.counter ? 'offer' : action.name;

Future<_EscrowFundingPlan> _buildEscrowFundingPlan({
  required Hostr hostr,
  required String tradeId,
  String? escrowServiceId,
  Reservation? privateReservation,
}) async {
  final persistedReservation = privateReservation == null
      ? await _readPersistedTradeReservation(hostr, tradeId)
      : null;
  final publicReservations = privateReservation == null
      ? await hostr.reservations.getByTradeId(tradeId)
      : const <Reservation>[];
  final reservations = [
    ?privateReservation,
    ?persistedReservation,
    ...publicReservations,
  ];
  final negotiateReservations =
      reservations
          .where(
            (reservation) =>
                reservation.isNegotiation &&
                reservation.stage != ReservationStage.cancel,
          )
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  if (negotiateReservations.isEmpty) {
    throw HostrCliException(
      'reservation_not_found',
      'No payable private negotiate-stage reservation found for tradeId.',
      details: {'tradeId': tradeId},
    );
  }

  final reservation = negotiateReservations.last;
  if (reservation.amount == null) {
    throw HostrCliException(
      'reservation_amount_required',
      'Payable reservation does not include an amount.',
      details: {'tradeId': tradeId, 'reservation': eventJson(reservation)},
    );
  }
  final listing = await hostr.listings.getOneByAnchor(
    reservation.parsedTags.listingAnchor,
  );
  if (listing == null) {
    throw HostrCliException(
      'listing_not_found',
      'Listing for reservation not found.',
      details: {'anchor': reservation.parsedTags.listingAnchor},
    );
  }

  final sellerPubkey = listing.pubKey;
  final sellerProfile = await hostr.metadata.loadMetadata(sellerPubkey);
  if (sellerProfile == null) {
    throw HostrCliException(
      'seller_profile_not_found',
      'Seller profile metadata was not found.',
      details: {'sellerPubkey': sellerPubkey},
    );
  }

  final sellerEvmAddress = await hostr.identityClaims.loadEvmAddress(
    sellerPubkey,
  );
  if (sellerEvmAddress == null || sellerEvmAddress.isEmpty) {
    throw HostrCliException(
      'seller_evm_address_not_found',
      'Seller EVM identity claim was not found.',
      details: {'sellerPubkey': sellerPubkey},
    );
  }

  final mutual = await hostr.escrows.determineMutualEscrow(
    hostr.auth.getActiveKey().publicKey,
    sellerPubkey,
  );
  if (mutual.compatibleServices.isEmpty || mutual.sellerMethod == null) {
    throw HostrCliException(
      'no_mutual_escrow',
      'No compatible escrow service was found for buyer and seller.',
      details: {
        'sellerPubkey': sellerPubkey,
        'sellerMethod': mutual.sellerMethod?.id,
        'buyerMethod': mutual.buyerMethod?.id,
      },
    );
  }

  final service = escrowServiceId == null || escrowServiceId.isEmpty
      ? mutual.compatibleServices.first
      : mutual.compatibleServices.where((service) {
          return service.id == escrowServiceId ||
              service.pubKey == escrowServiceId ||
              service.escrowPubkey == escrowServiceId ||
              service.contractAddress.toLowerCase() ==
                  escrowServiceId.toLowerCase();
        }).firstOrNull;
  if (service == null) {
    throw HostrCliException(
      'escrow_service_not_found',
      'Requested escrow service is not compatible with this trade.',
      details: {
        'requested': escrowServiceId,
        'compatible': mutual.compatibleServices
            .map((service) => _escrowServiceJson(service))
            .toList(),
      },
    );
  }

  final selectedEscrow = EscrowServiceSelected(
    pubKey: hostr.auth.getActiveKey().publicKey,
    tags: EscrowServiceSelectedTags([]),
    content: EscrowServiceSelectedContent(
      service: service,
      sellerMethods: mutual.sellerMethod!,
    ),
  );

  final preparer = hostr.escrow.fund(
    EscrowFundParams(
      escrowService: service,
      negotiateReservation: reservation,
      sellerProfile: sellerProfile,
      sellerEvmAddress: sellerEvmAddress,
      amount: reservation.amount!,
      sellerEscrowMethod: mutual.sellerMethod,
      securityDeposit: listing.securityDeposit,
      listingName: listing.title,
    ),
  );

  return _EscrowFundingPlan(
    reservation: reservation,
    listing: listing,
    selectedEscrow: selectedEscrow,
    preparer: preparer,
  );
}

Map<String, Object?> _escrowSelectionJson(EscrowServiceSelected selection) => {
  'event': eventJson(selection),
  'service': _escrowServiceJson(selection.service),
  'sellerMethods': eventJson(selection.sellerMethods),
};

Map<String, Object?>? _escrowMethodJson(EscrowMethod? method) {
  if (method == null) return null;
  return {
    'event': eventJson(method),
    'id': method.id,
    'pubkey': method.pubKey,
    'trustedEscrowPubkeys': method.trustedEscrowPubkeys,
    'supportedContractBytecodeHashes': method.supportedContractBytecodeHashes,
    'acceptedPaymentForms': method.acceptedPaymentForms
        .map(
          (form) => {
            'denomination': form.denomination,
            'tokenTagId': form.tokenTagId,
            if (form.appId != null) 'appId': form.appId,
          },
        )
        .toList(),
  };
}

Map<String, Object?> _escrowServiceJson(EscrowService service) => {
  'event': eventJson(service),
  'id': service.id,
  'pubkey': service.pubKey,
  'escrowPubkey': service.escrowPubkey,
  'chainId': service.chainId,
  'contractAddress': service.contractAddress,
  'contractBytecodeHash': service.contractBytecodeHash,
  'evmAddress': service.evmAddress,
  'feePercent': service.feePercent,
  'maxDurationSeconds': service.maxDuration.inSeconds,
  'tokenFeeHints': _tokenFeeHintsJson(service.tokenFeeHints),
};

Map<String, Object?> _tokenFeeHintsJson(Map<String, TokenFeeHints> hints) => {
  for (final entry in hints.entries)
    entry.key: {
      'baseFee': entry.value.baseFee,
      'maxFee': entry.value.maxFee,
      'minFee': entry.value.minFee,
    },
};

bool _tokenFeeHintsEqual(
  Map<String, TokenFeeHints> left,
  Map<String, TokenFeeHints> right,
) {
  if (left.length != right.length) return false;
  for (final entry in left.entries) {
    final other = right[entry.key];
    if (other == null) return false;
    if (entry.value.baseFee != other.baseFee ||
        entry.value.maxFee != other.maxFee ||
        entry.value.minFee != other.minFee) {
      return false;
    }
  }
  return true;
}

class _EscrowFundingPlan {
  const _EscrowFundingPlan({
    required this.reservation,
    required this.listing,
    required this.selectedEscrow,
    required this.preparer,
  });

  final Reservation reservation;
  final Listing listing;
  final EscrowServiceSelected selectedEscrow;
  final EscrowFundPreparer preparer;
}

int? _optionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

bool? _optionalBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
    return true;
  }
  if (normalized == 'false' || normalized == 'no' || normalized == '0') {
    return false;
  }
  return null;
}

ListingType _listingType(String input) {
  return ListingType.values.firstWhere(
    (type) => type.name == input.trim().toLowerCase(),
    orElse: () => throw HostrCliException(
      'invalid_listing_type',
      'Unsupported listing type "$input".',
      path: 'type',
      exitCode: 64,
    ),
  );
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;

  T? get lastOrNull => isEmpty ? null : last;
}
