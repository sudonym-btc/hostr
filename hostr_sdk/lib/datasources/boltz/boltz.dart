import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart';
import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:injectable/injectable.dart';

import 'swagger_generated/boltz.swagger.dart';

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
          final wsUrl = config.rootstockConfig.boltz.wsUrl;
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
