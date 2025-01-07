import 'dart:convert';

import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:http/http.dart' as http;

class BoltzClient {
  CustomLogger logger = CustomLogger();
  Config config = getIt<Config>();
  Future<dynamic> submarine({required String invoice}) async {
    logger.i('Swapping for invoice $invoice');
    var res = await http
        .post(Uri.parse('${config.boltzUrl}/v2/swap/submarine'), body: {
      'invoice': invoice,
      'to': 'BTC',
      'from': 'RBTC',
    });
    logger.i("Response: ${res.body}");
    return json.decode(res.body);
  }

  Future<dynamic> reverseSubmarine(
      {required int invoiceAmount,
      required String claimAddress,
      required String preimageHash}) async {
    logger.i('Swapping $invoiceAmount');
    var res =
        await http.post(Uri.parse('${config.boltzUrl}/v2/swap/reverse'), body: {
      'invoiceAmount': invoiceAmount,
      'to': 'RBTC',
      'from': 'BTC',
      'claimAddress': claimAddress,
      'preimageHash': preimageHash,
    });
    logger.i("Response: ${res.body}");
    return json.decode(res.body);
  }

  Future<dynamic> rbtcContracts() async {
    logger.i('Listing contracts');
    var res =
        await http.get(Uri.parse('${config.boltzUrl}/v2/chain/RBTC/contracts'));
    logger.i("Response: ${res.body}");
    var data = json.decode(res.body);
    data = data.data;

    return json.decode(res.body);
  }
}
