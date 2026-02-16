import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_operation.dart';
import 'package:http/http.dart' as http;
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/lnurl_http_impl.dart';
import 'package:ndk/domain_layer/repositories/lnurl_transport.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';
import 'package:ndk/ndk.dart' hide Zaps;

import 'pay_models.dart';

// Callback/completed details are defined in LnUrlWorkflow

class ZapPayOperation
    extends
        PayOperation<
          ZapPayParameters,
          ZapResolvedDetails,
          LightningCallbackDetails,
          LightningCompletedDetails
        > {
  final Zaps zaps;
  final LnurlTransport lnurlTransport = LnurlTransportHttpImpl(
    HttpRequestDS(http.Client()),
  );
  late final Lnurl lnurl = Lnurl(transport: lnurlTransport);
  ZapPayOperation({
    required super.params,
    required this.zaps,
    required super.nwc,
  });

  @override
  Future<LightningCompletedDetails> completer() async {
    throw UnimplementedError('Zap completer not implemented yet');
    // ZapResponse response = await zaps.zap(
    //   nwcConnection: nwc.connections[0].connection!,
    //   lnurl: state.params.to,
    //   amountSats: state.params.amount!.getInSats.toInt(),
    // );
    // return LightningCompletedDetails(
    //   preimage: response.payInvoiceResponse!.preimage!,
    // );
  }

  @override
  Future<LightningCallbackDetails> finalizer() async {
    // throw UnimplementedError('Zap finalizer not implemented yet');
    logger.d('Fetching invoice for zap with params: ${state.params}');
    final invoice = await lnurl.fetchInvoice(
      lnurlResponse: (resolvedDetails as ZapResolvedDetails).response,
      amountSats: params.amount!.getInSats.toInt(),
      zapRequest: ZapRequest(
        pubKey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
        tags: [
          ['e', 'some-event-id'],
          ['p', 'some-pubkey'],
        ],
        content: 'my content',
      ),
    );
    logger.i('Fetched invoice for zap: $invoice');
    if (invoice == null) {
      throw Exception('Failed to fetch invoice for zap');
    }
    return LightningCallbackDetails(
      invoice: Bolt11PaymentRequest(invoice.invoice),
    );
  }

  @override
  Future<ZapResolvedDetails> resolver() async {
    final lnurlParams = await lnurl.getLnurlResponse(
      Lnurl.getLud16LinkFromLud16(state.params.to)!,
    );
    // @todo: verify nostr pubkey same as in params

    logger.i('Resolved LNURL params: ${lnurlParams}');
    // lnurlParams.
    if (lnurlParams == null) {
      throw Exception('Failed to resolve LNURL params');
    }

    return ZapResolvedDetails(
      response: lnurlParams,
      minAmount: lnurlParams.minSendable!,
      maxAmount: lnurlParams.maxSendable!,
      commentAllowed: lnurlParams.commentAllowed ?? 0,
    );
  }
}
