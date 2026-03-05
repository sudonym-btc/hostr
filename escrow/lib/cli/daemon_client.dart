import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:escrow/shared/protocol.dart';
import 'package:json_rpc_2/json_rpc_2.dart' as json_rpc;
import 'package:stream_channel/stream_channel.dart';

/// JSON-RPC client that connects to the daemon over a Unix domain socket.
class DaemonClient {
  late json_rpc.Client _rpc;
  late Socket _socket;

  /// Connect to the daemon at [socketPath].
  ///
  /// Throws a [SocketException] if the daemon is not running.
  Future<void> connect(String socketPath) async {
    _socket = await Socket.connect(
      InternetAddress(socketPath, type: InternetAddressType.unix),
      0,
    );

    final incoming = _socket
        .cast<List<int>>()
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .asBroadcastStream();

    final outgoing = StreamController<String>();
    outgoing.stream.listen((line) {
      try {
        _socket.write('$line\n');
      } catch (_) {}
    });

    final channel = StreamChannel<String>(incoming, outgoing.sink);
    _rpc = json_rpc.Client(channel);

    // ignore returned future — listen() runs until the channel closes.
    unawaited(_rpc.listen());
  }

  /// Disconnect from the daemon.
  Future<void> close() async {
    _rpc.close();
    await _socket.close();
  }

  // ── Typed convenience methods ─────────────────────────────────────────────

  Future<Map<String, dynamic>> getStatus() async {
    final result = await _rpc.sendRequest(kRpcGetStatus);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<List<TradeSummary>> listPending() async {
    final result = await _rpc.sendRequest(kRpcListPending);
    final map = Map<String, dynamic>.from(result as Map);
    return (map['trades'] as List)
        .map((e) => TradeSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> getTrade(String tradeId) async {
    final result = await _rpc.sendRequest(kRpcGetTrade, {'tradeId': tradeId});
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> audit(String tradeId) async {
    final result = await _rpc.sendRequest(kRpcAudit, {'tradeId': tradeId});
    return Map<String, dynamic>.from(result as Map);
  }

  Future<String> arbitrate(String tradeId, double forward) async {
    final result = await _rpc.sendRequest(kRpcArbitrate, {
      'tradeId': tradeId,
      'forward': forward,
    });
    final map = Map<String, dynamic>.from(result as Map);
    return map['txHash'] as String;
  }

  Future<List<ThreadSummary>> listThreads() async {
    final result = await _rpc.sendRequest(kRpcListThreads);
    final map = Map<String, dynamic>.from(result as Map);
    return (map['threads'] as List)
        .map((e) => ThreadSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<({List<ThreadMessage> messages, List<String> participants})> getThread(
      String threadId) async {
    final result =
        await _rpc.sendRequest(kRpcGetThread, {'threadId': threadId});
    final map = Map<String, dynamic>.from(result as Map);
    return (
      messages: (map['messages'] as List)
          .map((e) =>
              ThreadMessage.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      participants:
          (map['participants'] as List).map((e) => e as String).toList(),
    );
  }

  Future<void> sendReply(String threadId, String content) async {
    await _rpc.sendRequest(kRpcSendReply, {
      'threadId': threadId,
      'content': content,
    });
  }

  // ── Services ──────────────────────────────────────────────────────────────

  Future<List<ServiceSummary>> listServices() async {
    final result = await _rpc.sendRequest(kRpcListServices);
    final map = Map<String, dynamic>.from(result as Map);
    return (map['services'] as List)
        .map(
            (e) => ServiceSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> getService(String serviceId) async {
    final result =
        await _rpc.sendRequest(kRpcGetService, {'serviceId': serviceId});
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> updateService(
    String serviceId, {
    int? feeBase,
    double? feePercent,
    int? minAmount,
    int? maxAmount,
  }) async {
    await _rpc.sendRequest(kRpcUpdateService, {
      'serviceId': serviceId,
      if (feeBase != null) 'feeBase': feeBase,
      if (feePercent != null) 'feePercent': feePercent,
      if (minAmount != null) 'minAmount': minAmount,
      if (maxAmount != null) 'maxAmount': maxAmount,
    });
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getProfile() async {
    final result = await _rpc.sendRequest(kRpcGetProfile);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<Map<String, dynamic>> getEvmMnemonic() async {
    final result = await _rpc.sendRequest(kRpcGetEvmMnemonic);
    return Map<String, dynamic>.from(result as Map);
  }

  Future<void> updateProfile({
    String? name,
    String? displayName,
    String? about,
    String? picture,
    String? banner,
    String? nip05,
    String? lud16,
    String? website,
  }) async {
    await _rpc.sendRequest(kRpcUpdateProfile, {
      if (name != null) 'name': name,
      if (displayName != null) 'displayName': displayName,
      if (about != null) 'about': about,
      if (picture != null) 'picture': picture,
      if (banner != null) 'banner': banner,
      if (nip05 != null) 'nip05': nip05,
      if (lud16 != null) 'lud16': lud16,
      if (website != null) 'website': website,
    });
  }
}
