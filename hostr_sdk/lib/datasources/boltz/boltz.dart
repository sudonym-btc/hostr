import 'dart:async';
import 'dart:convert';

import 'package:chopper/chopper.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../usecase/evm/config/evm_config.dart';
import '../../util/main.dart';
import '../swagger_generated/boltz.swagger.dart';
import 'boltz_chain_info.dart';

class BoltzClient {
  final CustomLogger logger;
  late Boltz gBoltzCli;
  final BoltzConfig boltzConfig;
  BoltzClient(this.boltzConfig, this.logger)
    : gBoltzCli = Boltz.create(
        baseUrl: Uri.parse(boltzConfig.apiUrl),
        interceptors: [
          HeadersInterceptor({'referral': 'boltz_webapp_desktop'}),
          const _TraceHeadersInterceptor(),
        ],
      );

  /// WebSocket URL derived from the API URL.
  String get wsUrl => boltzConfig.wsUrl;

  /// Discover all EVM chains supported by this Boltz instance.
  ///
  /// Parses `GET /chain/contracts` for chain topology (chainId, swap
  /// contracts, tokens). Does **not** resolve swap-pair availability —
  /// that is looked up at swap-time via `getReversePair` / `getSubmarinePair`.
  Future<List<BoltzChainInfo>> discoverChains() => logger.span(
    'discoverChains',
    () async {
      final res = await gBoltzCli.chainContractsGet();
      if (!res.isSuccessful || res.body == null) {
        throw StateError('Failed to fetch chain contracts from Boltz');
      }

      final body = res.body;
      if (body is! Map) {
        throw StateError('Unexpected Boltz chain contracts response shape');
      }

      final chains = <BoltzChainInfo>[];
      for (final entry in body.entries) {
        final chainKey = entry.key.toString();
        final data = entry.value;
        if (data is! Map) continue;

        final network = data['network'];
        if (network is! Map) continue;

        final chainIdRaw = network['chainId'];
        if (chainIdRaw == null) continue;
        final chainId = chainIdRaw is int
            ? chainIdRaw
            : (chainIdRaw as num).toInt();

        final swapContracts = data['swapContracts'];
        if (swapContracts is! Map) continue;

        final etherSwapRaw = swapContracts['EtherSwap'];
        final erc20SwapRaw = swapContracts['ERC20Swap'];
        if (etherSwapRaw is! String || etherSwapRaw.isEmpty) continue;

        final tokensRaw = data['tokens'];
        final tokens = tokensRaw is Map<String, dynamic>
            ? _parseTokenAddresses(tokensRaw)
            : tokensRaw is Map
            ? _parseTokenAddresses(
                tokensRaw.map((key, value) => MapEntry(key.toString(), value)),
              )
            : <String, EthereumAddress>{};

        final info = BoltzChainInfo(
          chainKey: chainKey,
          chainId: chainId,
          etherSwap: EthereumAddress.fromHex(etherSwapRaw),
          erc20Swap: erc20SwapRaw is String && erc20SwapRaw.isNotEmpty
              ? EthereumAddress.fromHex(erc20SwapRaw)
              : EthereumAddress.fromHex(etherSwapRaw),
          tokens: tokens,
        );
        chains.add(info);

        logger.i(
          'Boltz discovered chain: $chainKey '
          '(chainId=$chainId, tokens=${tokens.keys.toList()})',
        );
      }

      logger.i('Boltz discovered ${chains.length} chain(s)');
      return chains;
    },
  );

  Future<SubmarineResponse> submarine({
    required String invoice,
    String from = 'RBTC',
    String to = 'BTC',
  }) => logger.span('submarine', () async {
    logger.i('Swapping for invoice $invoice');
    SubmarineRequest r = SubmarineRequest(from: from, to: to, invoice: invoice);

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
  });

  Future<SwapStatus> getSwap({required String id}) =>
      logger.span('getSwap', () async {
        logger.i('Getting swap $id');
        Response<SwapStatus> res = await gBoltzCli.swapIdGet(id: id);
        if (res.isSuccessful) return res.body!;
        throw res.error!;
      });

  /// Fetch the preimage for a completed submarine swap.
  ///
  /// Boltz reveals the preimage once it has paid the Lightning invoice.
  /// The caller should verify `SHA-256(preimage) == paymentHash` to
  /// cryptographically prove the invoice was actually settled.
  Future<String> getSubmarinePreimage({required String id}) =>
      logger.span('getSubmarinePreimage', () async {
        logger.i('Fetching preimage for submarine swap $id');
        final res = await gBoltzCli.swapSubmarineIdPreimageGet(id: id);
        if (res.isSuccessful && res.body != null) {
          return res.body!.preimage;
        }
        throw StateError(
          'Failed to fetch preimage for swap $id: '
          '${res.statusCode} ${res.error}',
        );
      });

  /// Request a cooperative refund EIP-712 signature from Boltz for a failed
  /// submarine swap. Returns `null` if Boltz refuses (e.g. swap not in a
  /// failed state yet). Throws on network errors.
  Future<SwapSubmarineIdRefundGet$Response?> getCooperativeRefundSignature({
    required String id,
  }) => logger.span('getCooperativeRefundSignature', () async {
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
  });

  Future<ReverseResponse> reverseSubmarine({
    double? invoiceAmount,
    double? onchainAmount,
    required String preimageHash,
    required String claimAddress,
    String? description,
    String from = 'BTC',
    String to = 'RBTC',
  }) => logger.span('reverseSubmarine', () async {
    if (invoiceAmount == null && onchainAmount == null) {
      throw ArgumentError(
        'Either invoiceAmount or onchainAmount must be provided',
      );
    }

    logger.i(
      'Creating reverse swap $from->$to for $claimAddress '
      '(invoiceAmount=$invoiceAmount, onchainAmount=$onchainAmount)',
    );
    ReverseRequest r = ReverseRequest(
      from: from,
      to: to,
      invoiceAmount: invoiceAmount,
      onchainAmount: onchainAmount,
      claimAddress: claimAddress,
      preimageHash: preimageHash,
      description: description,
    );
    logger.i("Request: $r");

    for (var attempt = 1; attempt <= 4; attempt++) {
      Response<ReverseResponse> res = await gBoltzCli.swapReversePost(body: r);
      logger.i("Response: ${res.body}");
      if (res.isSuccessful) return res.body!;

      final error = res.error!;
      if (!_isTransientSerializationError(error) || attempt == 4) {
        throw error;
      }

      logger.w(
        'Boltz reverse swap creation hit transient serialization conflict; '
        'retrying attempt ${attempt + 1}/4: $error',
      );
      await Future<void>.delayed(Duration(milliseconds: 250 * attempt));
    }

    throw StateError('Boltz reverse swap retry loop exhausted unexpectedly');
  });

  bool _isTransientSerializationError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('could not serialize access') ||
        message.contains('serialization failure');
  }

  Future<Contracts> rbtcContracts() => logger.span('rbtcContracts', () async {
    logger.i('Listing contracts');
    Response<Contracts> res = await gBoltzCli.chainCurrencyContractsGet(
      currency: 'RBTC',
    );
    logger.i("Response: ${res.body}");
    if (res.isSuccessful) return res.body!;
    throw res.error!;
  });

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
  }) => logger.span('getReversePair', () async {
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
  });

  /// Fetch the typed [SubmarinePair] for a given currency pair.
  Future<SubmarinePair> getSubmarinePair({
    String from = 'RBTC',
    String to = 'BTC',
  }) => logger.span('getSubmarinePair', () async {
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
  });

  Future<Response> getSwapSubmarine() async {
    return await gBoltzCli.swapSubmarineGet();
  }

  Map<String, EthereumAddress> _parseTokenAddresses(Map<String, dynamic> raw) {
    final tokens = <String, EthereumAddress>{};
    for (final entry in raw.entries) {
      final tokenName = entry.key.toString();
      final tokenData = entry.value;
      if (tokenData is String && tokenData.isNotEmpty) {
        tokens[tokenName] = EthereumAddress.fromHex(tokenData);
      } else if (tokenData is Map && tokenData['contractAddress'] is String) {
        tokens[tokenName] = EthereumAddress.fromHex(
          tokenData['contractAddress'] as String,
        );
      }
    }
    return tokens;
  }

  Stream<SwapStatus> subscribeToSwap({
    required String id,
    int maxReconnectAttempts = 5,
  }) {
    final controller = StreamController<SwapStatus>.broadcast();
    WebSocketChannel? channel;
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
        await channel?.sink.close();
      } catch (_) {
        // Ignore late close errors from an already-closing websocket.
      }
      channel = null;
    }

    Future<void> connect() async {
      if (intentionallyClosed || controller.isClosed) return;
      try {
        final wsUrl = boltzConfig.wsUrl;
        logger.d(
          'Connecting to Boltz WS for swap $id (attempt ${reconnectAttempts + 1})',
        );
        channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        await channel!.ready;
        if (intentionallyClosed || controller.isClosed) {
          await closeSocket();
          return;
        }
        reconnectAttempts = 0; // Reset on successful connect
        channel!.sink.add(
          jsonEncode({
            'op': 'subscribe',
            'channel': 'swap.update',
            'args': [id],
          }),
        );

        socketSub = channel!.stream.listen(
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

class _TraceHeadersInterceptor implements Interceptor {
  const _TraceHeadersInterceptor();

  @override
  FutureOr<Response<BodyType>> intercept<BodyType>(Chain<BodyType> chain) {
    final headers = TraceContext.headers();
    if (headers.isEmpty) {
      return chain.proceed(chain.request);
    }
    return chain.proceed(applyHeaders(chain.request, headers));
  }
}
