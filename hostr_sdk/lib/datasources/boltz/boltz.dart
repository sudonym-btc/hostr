import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:injectable/injectable.dart';

import '../swagger_generated/boltz.swagger.dart';

@injectable
class BoltzClient {
  final CustomLogger logger;
  late Boltz gBoltzCli;
  final HostrConfig config;
  BoltzClient(this.config, this.logger)
    : gBoltzCli = Boltz.create(
        baseUrl: Uri.parse(config.rootstockConfig.boltz.apiUrl),
      );

  Future<SubmarineResponse> submarine({required String invoice}) async {
    logger.i('Swapping for invoice $invoice');
    SubmarineRequest r = SubmarineRequest(
      from: 'RBTC',
      to: 'BTC',
      invoice: invoice,
    );

    Response<SubmarineResponse> res = await gBoltzCli.swapSubmarinePost(
      body: r,
    );
    logger.i("Response: ${res.body}");
    if (res.isSuccessful) {
      final body = res.body;
      if (body == null) {
        throw StateError('Boltz submarine response body was empty');
      }

      // Boltz API v2 may return `claimAddress` for EVM submarine swaps while
      // older generated models only expose `claimPublicKey`.
      final raw = _tryParseMessage(res.bodyString);
      final claimAddressFromRaw = _asString(raw?['claimAddress']);
      final claimPublicKeyFromRaw = _asString(raw?['claimPublicKey']);
      final normalizedClaimAddress =
          body.claimPublicKey ?? claimAddressFromRaw ?? claimPublicKeyFromRaw;

      if (normalizedClaimAddress == null || normalizedClaimAddress.isEmpty) {
        logger.w(
          'Submarine response missing claim address field. Raw keys: ${raw?.keys.toList()}',
        );
        return body;
      }

      return body.copyWith(claimPublicKey: normalizedClaimAddress);
    }
    throw res.error!;
  }

  Future<SwapStatus> getSwap({required String id}) async {
    logger.i('Getting swap $id');
    Response<SwapStatus> res = await gBoltzCli.swapIdGet(id: id);
    if (res.isSuccessful) return res.body!;
    throw res.error!;
  }

  /// Request a cooperative refund EIP-712 signature from Boltz for a failed
  /// submarine swap. Returns `null` if Boltz refuses (e.g. swap not in a
  /// failed state yet). Throws on network errors.
  Future<SwapSubmarineIdRefundGet$Response?> getCooperativeRefundSignature({
    required String id,
  }) async {
    logger.i('Requesting cooperative refund signature for swap $id');
    try {
      final res = await gBoltzCli.swapSubmarineIdRefundGet(id: id);
      if (res.isSuccessful && res.body != null) {
        logger.i('Got cooperative refund signature for $id');
        return res.body;
      }
      logger.w(
        'Cooperative refund signature not available for $id: '
        '${res.statusCode} ${res.error}',
      );
      return null;
    } catch (e) {
      logger.w('Failed to get cooperative refund signature for $id: $e');
      return null;
    }
  }

  Future<ReverseResponse> reverseSubmarine({
    required double invoiceAmount,
    required String preimageHash,
    required String claimAddress,
  }) async {
    logger.i('Swapping $invoiceAmount for $claimAddress');
    ReverseRequest r = ReverseRequest(
      from: 'BTC',
      to: 'RBTC',
      invoiceAmount: invoiceAmount,
      claimAddress: claimAddress,
      preimageHash: preimageHash,
    );
    logger.i("Request: $r");

    Response<ReverseResponse> res = await gBoltzCli.swapReversePost(body: r);
    logger.i("Response: ${res.body}");
    if (res.isSuccessful) return res.body!;
    throw res.error!;
  }

  Future<Contracts> rbtcContracts() async {
    logger.i('Listing contracts');
    Response<Contracts> res = await gBoltzCli.chainCurrencyContractsGet(
      currency: 'RBTC',
    );
    logger.i("Response: ${res.body}");
    if (res.isSuccessful) return res.body!;
    throw res.error!;
  }

  Future<Response> getSwapReserve() async {
    return await gBoltzCli.swapReverseGet();
  }

  Future<BitcoinAmount> estimateReverseSwapFees({
    required BitcoinAmount invoiceAmount,
    String from = 'BTC',
    String to = 'RBTC',
  }) async {
    final response = await getSwapReserve();
    if (!response.isSuccessful || response.body == null) {
      throw Exception('Failed to fetch reverse swap pairs from Boltz');
    }

    final body = response.body;
    if (body is! Map) {
      throw Exception('Unexpected Boltz reverse pairs response shape');
    }

    final fromMap = body[from];
    if (fromMap is! Map) {
      throw Exception('Boltz reverse pair source currency not found: $from');
    }
    final pair = fromMap[to];
    if (pair is! Map) {
      throw Exception('Boltz reverse pair not found: $from->$to');
    }

    final fees = pair['fees'];
    if (fees is! Map) {
      throw Exception('Boltz reverse pair fees missing for: $from->$to');
    }

    final percentageRaw = fees['percentage'];
    final minerFees = fees['minerFees'];
    if (percentageRaw is! num || minerFees is! Map) {
      throw Exception('Boltz reverse pair fee fields invalid for: $from->$to');
    }

    final lockupRaw = minerFees['lockup'];
    final claimRaw = minerFees['claim'];
    if (lockupRaw is! num || claimRaw is! num) {
      throw Exception('Boltz reverse miner fees invalid for: $from->$to');
    }

    final invoiceSats = invoiceAmount.getInSats.toDouble();
    final percentageFeeSats = invoiceSats * (percentageRaw.toDouble() / 100.0);
    final totalFeeSats =
        percentageFeeSats + lockupRaw.toDouble() + claimRaw.toDouble();

    final estimated = BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      totalFeeSats.ceil(),
    );
    logger.i(
      'Estimated reverse swap fees from Boltz for $from->$to '
      '(invoice: ${invoiceAmount.getInSats} sats): ${estimated.getInSats} sats',
    );
    return estimated;
  }

  Future<Response> getSwapSubmarine() async {
    return await gBoltzCli.swapSubmarineGet();
  }

  Stream<SwapStatus> subscribeToSwap({
    required String id,
    int maxReconnectAttempts = 5,
  }) {
    final controller = StreamController<SwapStatus>.broadcast();
    WebSocket? socket;
    StreamSubscription<dynamic>? socketSub;
    int reconnectAttempts = 0;
    bool intentionallyClosed = false;

    Future<void> closeSocket() async {
      await socketSub?.cancel();
      socketSub = null;
      await socket?.close();
      socket = null;
    }

    Future<void> connect() async {
      try {
        final wsUrl = config.rootstockConfig.boltz.wsUrl;
        logger.d('Connecting to Boltz WS for swap $id (attempt ${reconnectAttempts + 1})');
        socket = await WebSocket.connect(wsUrl);
        reconnectAttempts = 0; // Reset on successful connect
        socket!.add(
          jsonEncode({
            'op': 'subscribe',
            'channel': 'swap.update',
            'args': [id],
          }),
        );

        socketSub = socket!.listen(
          (data) {
            final msg = _tryParseMessage(data);
            if (msg == null || msg['event'] != 'update') return;

            final args = msg['args'];
            if (args is List && args.isNotEmpty && args.first is Map) {
              final payload = Map<String, dynamic>.from(args.first as Map);
              controller.add(SwapStatus.fromJson(payload));
            }
          },
          onError: (e, st) {
            logger.w('Boltz WS error for swap $id: $e');
            if (!intentionallyClosed) {
              _scheduleReconnect(
                id, controller, reconnectAttempts, maxReconnectAttempts,
                connect, closeSocket,
              );
            }
          },
          onDone: () {
            logger.d('Boltz WS closed for swap $id');
            if (!intentionallyClosed && !controller.isClosed) {
              _scheduleReconnect(
                id, controller, reconnectAttempts, maxReconnectAttempts,
                connect, closeSocket,
              );
            }
          },
        );
      } catch (e, st) {
        logger.w('Failed to connect Boltz WS for swap $id: $e');
        if (!intentionallyClosed) {
          _scheduleReconnect(
            id, controller, reconnectAttempts, maxReconnectAttempts,
            connect, closeSocket,
          );
        } else {
          controller.addError(e, st);
          if (!controller.isClosed) controller.close();
        }
      }
    }

    controller.onListen = () { connect(); };
    controller.onCancel = () async {
      intentionallyClosed = true;
      await closeSocket();
      if (!controller.isClosed) await controller.close();
    };

    return controller.stream;
  }

  void _scheduleReconnect(
    String id,
    StreamController<SwapStatus> controller,
    int currentAttempts,
    int maxAttempts,
    Future<void> Function() connect,
    Future<void> Function() closeSocket,
  ) {
    if (controller.isClosed) return;
    if (currentAttempts >= maxAttempts) {
      logger.e(
        'Boltz WS: max reconnect attempts ($maxAttempts) reached for swap $id. '
        'Falling back to polling.',
      );
      // Fall back to a single HTTP poll so the caller still gets a status
      _pollSwapStatus(id, controller);
      return;
    }
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s
    final delay = Duration(seconds: 1 << currentAttempts);
    logger.d('Boltz WS: reconnecting for swap $id in ${delay.inSeconds}s');
    Future.delayed(delay, () async {
      if (controller.isClosed) return;
      await closeSocket();
      await connect();
    });
  }

  /// One-shot HTTP poll fallback when WebSocket reconnection is exhausted.
  Future<void> _pollSwapStatus(
    String id,
    StreamController<SwapStatus> controller,
  ) async {
    try {
      final status = await getSwap(id: id);
      if (!controller.isClosed) {
        controller.add(status);
      }
    } catch (e) {
      logger.e('Boltz HTTP poll fallback failed for swap $id: $e');
      if (!controller.isClosed) {
        controller.addError(e);
      }
    }
  }

  Map<String, dynamic>? _tryParseMessage(dynamic data) {
    try {
      final raw = switch (data) {
        String value => value,
        List<int> value => utf8.decode(value),
        _ => null,
      };
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _asString(dynamic value) {
    return value is String && value.isNotEmpty ? value : null;
  }
}
