import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:injectable/injectable.dart';

import 'swagger_generated/boltz.swagger.dart';

@injectable
class BoltzClient {
  CustomLogger logger = CustomLogger();
  late Boltz gBoltzCli;
  final Config config;
  BoltzClient(this.config)
    : gBoltzCli = Boltz.create(
        baseUrl: Uri.parse(config.rootstock.boltz.apiUrl),
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
    if (res.isSuccessful) return res.body!;
    throw res.error!;
  }

  Future<SwapStatus> getSwap({required String id}) async {
    logger.i('Getting swap $id');
    Response<SwapStatus> res = await gBoltzCli.swapIdGet(id: id);
    if (res.isSuccessful) return res.body!;
    throw res.error!;
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

  Future<Response> getSwapSubmarine() async {
    return await gBoltzCli.swapSubmarineGet();
  }

  Stream<SwapStatus> subscribeToSwap({required String id}) {
    final controller = StreamController<SwapStatus>.broadcast();
    WebSocket? socket;
    StreamSubscription<dynamic>? socketSub;

    Future<void> closeSocket() async {
      await socketSub?.cancel();
      socketSub = null;
      await socket?.close();
      socket = null;
    }

    controller
      ..onListen = () async {
        try {
          final wsUrl = config.rootstock.boltz.wsUrl;
          socket = await WebSocket.connect(wsUrl);
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
            onError: controller.addError,
            onDone: () {
              if (!controller.isClosed) controller.close();
            },
          );
        } catch (e, st) {
          controller.addError(e, st);
          if (!controller.isClosed) await controller.close();
        }
      }
      ..onCancel = () async {
        await closeSocket();
        if (!controller.isClosed) await controller.close();
      };

    return controller.stream;
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
}
