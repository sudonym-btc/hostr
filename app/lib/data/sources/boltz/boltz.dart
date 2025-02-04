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
      : gBoltzCli = Boltz.create(baseUrl: Uri.parse(config.boltzUrl));

  Future<SubmarineResponse> submarine({required String invoice}) async {
    logger.i('Swapping for invoice $invoice');
    SubmarineRequest r = SubmarineRequest(
      from: 'RBTC',
      to: 'BTC',
      invoice: invoice,
    );
    Response<SubmarineResponse> res =
        await gBoltzCli.swapSubmarinePost(body: r);
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

  Future<ReverseResponse> reverseSubmarine(
      {required double invoiceAmount,
      required String preimageHash,
      required String claimAddress}) async {
    logger.i('Swapping $invoiceAmount for $claimAddress');
    ReverseRequest r = ReverseRequest(
        from: 'BTC',
        to: 'RBTC',
        invoiceAmount: invoiceAmount,
        claimAddress: claimAddress,
        preimageHash: preimageHash);
    logger.i("Request: $r");

    Response<ReverseResponse> res = await gBoltzCli.swapReversePost(body: r);
    logger.i("Response: ${res.body}");
    if (res.isSuccessful) return res.body!;
    throw res.error!;
  }

  Future<Contracts> rbtcContracts() async {
    logger.i('Listing contracts');
    Response<Contracts> res =
        await gBoltzCli.chainCurrencyContractsGet(currency: 'RBTC');
    logger.i("Response: ${res.body}");
    if (res.isSuccessful) return res.body!;
    throw res.error!;
  }
}
