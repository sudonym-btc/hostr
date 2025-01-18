import 'dart:convert';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:hostr/data/sources/lnurl/lnurl.dart';
import 'package:hostr/data/sources/lnurl/types.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/swap.dart';
import 'package:hostr/main.dart';
import 'package:http/http.dart' as http;
import 'package:validators/validators.dart';

class LnUrlPaymentParameters extends PaymentParameters {
  LnUrlPaymentParameters({super.amount, super.comment, required super.to});
}

class LnUrlResolvedDetails extends ResolvedDetails {
  final String callback;

  LnUrlResolvedDetails(
      {required super.minAmount,
      required super.maxAmount,
      required super.commentAllowed,
      required this.callback});
}

class LightningCallbackDetails extends CallbackDetails {
  final Bolt11PaymentRequest invoice;
  LightningCallbackDetails({required this.invoice});
}

class LightningCompletedDetails extends CompletedDetails {
  final String preimage;
  LightningCompletedDetails({required this.preimage});
}

class LnUrlPaymentCubit extends PaymentCubit<LnUrlPaymentParameters,
    LnUrlResolvedDetails, LightningCallbackDetails, LightningCompletedDetails> {
  LnUrlPaymentCubit({required super.params});

  @override
  Future<LnUrlResolvedDetails> resolver() async {
    /// First convert lightning address to lnurl
    String lnurl = isEmail(params.to) ? emailToLnUrl(params.to) : params.to;
    logger.i('Resolving LnUrl: $lnurl');

    /// Fetch the lnurl params from the remote host
    LNURLParseResult lnurlParams = await getParams(emailToLnUrl(params.to));
    logger.i('LnUrl endpoint response: $lnurlParams');
    if (lnurlParams.error != null) {
      throw lnurlParams.error!.reason;
    }
    LNURLPayParams lnurlPayParams = lnurlParams.payParams!;
    logger.i('LNURLPayParams: $lnurlParams');
    return LnUrlResolvedDetails(
        callback: lnurlPayParams.callback,
        minAmount: lnurlPayParams.minSendable,
        maxAmount: lnurlPayParams.maxSendable,
        commentAllowed: 0);
  }

  @override
  Future<LightningCallbackDetails> callback() async {
    Uri callbackUri =
        Uri.parse(state.resolvedDetails!.callback).replace(queryParameters: {
      'amount': (state.params.amount!.value * btcMilliSatoshiFactor)
          .toInt()
          .toString()
    });
    logger.d('Callback uri: $callbackUri');
    http.Response r = await http.get(callbackUri);
    logger.d('Callback response: ${r.body}');
    String invoice = json.decode(r.body)['pr'];
    logger.d('Callback response: ${r.body}, $invoice');
    return LightningCallbackDetails(invoice: Bolt11PaymentRequest(invoice));
  }

  @override
  Future<LightningCompletedDetails> complete() async {
    NwcResponse response = await getIt<NwcService>().payInvoice(
        NwcMethodPayInvoiceParams(
            invoice: state.callbackDetails!.invoice.paymentRequest));
    return LightningCompletedDetails(
        preimage: (response.parsedContent.result as NwcMethodPayInvoiceResponse)
            .preimage);
  }
}

String emailToLnUrl(String email) {
  String user = email.split('@')[0];
  String domain = email.split('@')[1];

  return 'lnurlp://${domain}/.well-known/lnurlp/${user}';
}
