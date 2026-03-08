import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:injectable/injectable.dart';

import '../../config.dart';
import '../../util/main.dart';
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
    String? description,
  }) async {
    logger.i('Swapping $invoiceAmount for $claimAddress');
    ReverseRequest r = ReverseRequest(
      from: 'BTC',
      to: 'RBTC',
      invoiceAmount: invoiceAmount,
      claimAddress: claimAddress,
      preimageHash: preimageHash,
      description: description,
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

  /// Fetch the typed [ReversePair] for a given currency pair.
  ///
  /// Parses the raw Boltz `/swap/reverse` response into the generated
  /// [ReversePair] model so callers don't need to dig through untyped maps.
  Future<ReversePair> getReversePair({
    String from = 'BTC',
    String to = 'RBTC',
  }) async {
    final response = await getSwapReserve();
    if (!response.isSuccessful || response.body == null) {
      throw StateError('Failed to fetch reverse swap pairs from Boltz');
    }
    final body = response.body;
    if (body is! Map) {
      throw StateError('Unexpected Boltz reverse pairs response shape');
    }
    final fromMap = body[from];
    if (fromMap is! Map) {
      throw StateError('Boltz reverse pair source currency not found: $from');
    }
    final pairRaw = fromMap[to];
    if (pairRaw is! Map) {
      throw StateError('Boltz reverse pair not found: $from->$to');
    }
    final pairJson = Map<String, dynamic>.from(
      pairRaw.map((key, value) => MapEntry(key.toString(), value)),
    );
    return ReversePair.fromJson(pairJson);
  }

  /// Fetch the typed [SubmarinePair] for a given currency pair.
  Future<SubmarinePair> getSubmarinePair({
    String from = 'RBTC',
    String to = 'BTC',
  }) async {
    final response = await getSwapSubmarine();
    if (!response.isSuccessful || response.body == null) {
      throw StateError('Failed to fetch submarine swap pairs from Boltz');
    }
    final body = response.body;
    if (body is! Map) {
      throw StateError('Unexpected Boltz submarine pairs response shape');
    }
    final fromMap = body[from];
    if (fromMap is! Map) {
      throw StateError('Boltz submarine source currency not found: $from');
    }
    final pairRaw = fromMap[to];
    if (pairRaw is! Map) {
      throw StateError('Boltz submarine pair not found: $from->$to');
    }
    final pairJson = Map<String, dynamic>.from(
      pairRaw.map((key, value) => MapEntry(key.toString(), value)),
    );
    return SubmarinePair.fromJson(pairJson);
  }

  /// Given a desired **on-chain** amount, compute the Lightning invoice amount
  /// needed so that after Boltz deducts its percentage + miner fees the
  /// recipient receives at least [desiredOnchainAmount].
  ///
  /// Boltz reverse-swap formula:
  ///   `onchain = invoice × (1 − percentage/100) − lockupFee`
  ///
  /// The claim fee is **not** deducted by Boltz — the recipient pays it
  /// separately (via RIF Relay on EVM, or a sweep tx on BTC).
  ///
  /// Solving for invoice:
  ///   `invoice = (desired + lockupFee) / (1 − percentage/100)`
  Future<({BitcoinAmount invoiceAmount, BitcoinAmount feeOverhead})>
  computeInvoiceForDesiredOnchain({
    required BitcoinAmount desiredOnchainAmount,
    String from = 'BTC',
    String to = 'RBTC',
  }) async {
    final pair = await getReversePair(from: from, to: to);
    final pFraction = pair.fees.percentage / 100.0;
    final lockupFee = pair.fees.minerFees.lockup;

    final desiredSats = desiredOnchainAmount.getInSats.toDouble();
    final invoiceSats = (desiredSats + lockupFee) / (1.0 - pFraction);
    final invoiceSatsCeil = invoiceSats.ceil();

    final invoice = BitcoinAmount.fromInt(BitcoinUnit.sat, invoiceSatsCeil);
    final feeOverhead = BitcoinAmount.fromBigInt(
      BitcoinUnit.sat,
      BigInt.from(invoiceSatsCeil) - desiredOnchainAmount.getInSats,
    );

    logger.i(
      'computeInvoiceForDesiredOnchain $from->$to: '
      'desired=${desiredOnchainAmount.getInSats}, invoice=${invoice.getInSats}, '
      'overhead=${feeOverhead.getInSats} (lockup=$lockupFee, pct=${pair.fees.percentage}%)',
    );
    return (invoiceAmount: invoice, feeOverhead: feeOverhead);
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
    Timer? reconnectTimer;

    Future<void> closeSocket() async {
      reconnectTimer?.cancel();
      reconnectTimer = null;
      try {
        await socketSub?.cancel();
      } catch (_) {
        // Best-effort shutdown. Socket teardown races are expected during
        // test cancellation and should not surface as unhandled async errors.
      }
      socketSub = null;
      try {
        await socket?.close();
      } catch (_) {
        // Ignore late close errors from an already-closing websocket.
      }
      socket = null;
    }

    Future<void> connect() async {
      if (intentionallyClosed || controller.isClosed) return;
      try {
        final wsUrl = config.rootstockConfig.boltz.wsUrl;
        logger.d(
          'Connecting to Boltz WS for swap $id (attempt ${reconnectAttempts + 1})',
        );
        socket = await WebSocket.connect(wsUrl);
        if (intentionallyClosed || controller.isClosed) {
          await closeSocket();
          return;
        }
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
              reconnectAttempts++;
              _scheduleReconnect(
                id,
                controller,
                reconnectAttempts,
                maxReconnectAttempts,
                connect,
                closeSocket,
                () => intentionallyClosed,
                (timer) => reconnectTimer = timer,
              );
            }
          },
          onDone: () {
            logger.d('Boltz WS closed for swap $id');
            if (!intentionallyClosed && !controller.isClosed) {
              reconnectAttempts++;
              _scheduleReconnect(
                id,
                controller,
                reconnectAttempts,
                maxReconnectAttempts,
                connect,
                closeSocket,
                () => intentionallyClosed,
                (timer) => reconnectTimer = timer,
              );
            }
          },
        );
      } catch (e, st) {
        logger.w('Failed to connect Boltz WS for swap $id: $e');
        if (!intentionallyClosed) {
          reconnectAttempts++;
          _scheduleReconnect(
            id,
            controller,
            reconnectAttempts,
            maxReconnectAttempts,
            connect,
            closeSocket,
            () => intentionallyClosed,
            (timer) => reconnectTimer = timer,
          );
        } else if (!controller.isClosed) {
          controller.addError(e, st);
          if (!controller.isClosed) controller.close();
        }
      }
    }

    controller.onListen = () {
      unawaited(connect());
    };
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
    bool Function() isIntentionallyClosed,
    void Function(Timer) setReconnectTimer,
  ) {
    if (controller.isClosed) return;
    if (isIntentionallyClosed()) return;
    if (currentAttempts >= maxAttempts) {
      logger.e(
        'Boltz WS: max reconnect attempts ($maxAttempts) reached for swap $id. '
        'Falling back to periodic polling.',
      );
      // Fall back to periodic HTTP polling so the caller keeps getting
      // status updates even after the WebSocket is gone (e.g. app
      // returning from background after paying an invoice externally).
      _startPolling(id, controller, isIntentionallyClosed);
      return;
    }
    // Exponential backoff: 0s, 2s, 4s, 8s, 16s
    // First attempt is immediate (e.g. app just resumed from background).
    final delay = currentAttempts <= 1
        ? Duration.zero
        : Duration(seconds: 1 << currentAttempts);
    logger.d('Boltz WS: reconnecting for swap $id in ${delay.inSeconds}s');
    final timer = Timer(delay, () async {
      if (controller.isClosed) return;
      if (isIntentionallyClosed()) return;
      await closeSocket();
      await connect();
    });
    setReconnectTimer(timer);
  }

  /// Periodic HTTP poll fallback when WebSocket reconnection is exhausted.
  ///
  /// Polls every [interval] until the controller is closed or the caller
  /// signals intentional close. This covers the case where the app goes
  /// to background (killing the WebSocket), the user pays an invoice in
  /// another app, and returns — the poll picks up the new status quickly.
  void _startPolling(
    String id,
    StreamController<SwapStatus> controller,
    bool Function() isIntentionallyClosed, {
    Duration interval = const Duration(seconds: 3),
  }) {
    logger.d('Boltz: starting HTTP poll fallback for swap $id');
    // Fire immediately, then repeat on interval.
    _pollSwapStatus(id, controller);

    Timer.periodic(interval, (timer) {
      if (controller.isClosed || isIntentionallyClosed()) {
        timer.cancel();
        logger.d('Boltz: stopped HTTP poll fallback for swap $id');
        return;
      }
      _pollSwapStatus(id, controller);
    });
  }

  /// One-shot HTTP poll — fetches the current swap status via REST.
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
