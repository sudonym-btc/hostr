import 'package:chopper/chopper.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';

import 'swagger_generated/boltz.swagger.dart';

class BoltzClient {
  CustomLogger logger = CustomLogger();
  Config config = getIt<Config>();
  Boltz gBoltzCli = Boltz.create();

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
    var res = await gBoltzCli.swapReversePost(body: r);
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
