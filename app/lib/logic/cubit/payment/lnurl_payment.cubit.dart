import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:dio/dio.dart';
import 'package:hostr/data/sources/lnurl/lnurl.dart';
import 'package:hostr/data/sources/lnurl/types.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/swap.dart';
import 'package:hostr/main.dart';
import 'package:ndk/ndk.dart';
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
    // ZapRequest z = await getIt<Ndk>().zaps.createZapRequest(amountSats: (state.params.amount!.value * btcMilliSatoshiFactor).toInt(), signer: Bip340EventSigner(privateKey: Bip340.generatePrivateKey().privateKey), pubKey: pubKey, relays: relays)
    Uri callbackUri =
        Uri.parse(state.resolvedDetails!.callback).replace(queryParameters: {
      'amount': (state.params.amount!.value * btcMilliSatoshiFactor)
          .toInt()
          .toString()
    });
    logger.d('Callback uri: $callbackUri');
    Response r = await getIt<Dio>().get(callbackUri.toString());
    logger.d('Callback response: ${r.data}');
    String invoice = r.data['pr'];
    logger.d('Callback response: ${r.data}, $invoice');
    return LightningCallbackDetails(invoice: Bolt11PaymentRequest(invoice));
  }

  @override
  Future<LightningCompletedDetails> complete() async {
    PayInvoiceResponse response = await getIt<NwcService>().payInvoice(
        getIt<NwcService>().connections[0].connection!,
        state.callbackDetails!.invoice.paymentRequest,
        null);
    return LightningCompletedDetails(preimage: response.preimage);
  }
}

String emailToLnUrl(String email) {
  String user = email.split('@')[0];
  String domain = email.split('@')[1];

  return 'lnurlp://${domain}/.well-known/lnurlp/${user}';
}
