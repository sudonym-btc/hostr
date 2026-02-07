import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:dio/dio.dart';
import 'package:hostr/data/sources/lnurl/lnurl.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/nwc/nwc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart' hide Nwc;
import 'package:validators/validators.dart';

class LnUrlPaymentParameters extends PaymentParameters {
  LnUrlPaymentParameters({super.amount, super.comment, required super.to});
}

// LnUrlResolvedDetails, LightningCallbackDetails, LightningCompletedDetails
// are now in lnurl_workflow.dart

@Injectable(env: Env.allButTestAndMock)
class LnUrlPaymentCubit
    extends
        PaymentCubit<
          LnUrlPaymentParameters,
          LnUrlResolvedDetails,
          LightningCallbackDetails,
          LightningCompletedDetails
        > {
  final Nwc nwc;

  LnUrlPaymentCubit({@factoryParam required super.params, required this.nwc});

  /// Converts Lightning Address (email format) to LNURL.
  String emailToLnUrl(String email) {
    final user = email.split('@')[0];
    final domain = email.split('@')[1];
    return 'lnurlp://$domain/.well-known/lnurlp/$user';
  }

  @override
  Future<LnUrlResolvedDetails> resolver() async {
    // Convert lightning address to lnurl if needed
    final lnurl = isEmail(state.params.to)
        ? emailToLnUrl(state.params.to)
        : state.params.to;

    // Fetch the lnurl params from the remote host
    final lnurlParams = await getParams(lnurl);

    if (lnurlParams.error != null) {
      throw Exception(lnurlParams.error!.reason);
    }

    final lnurlPayParams = lnurlParams.payParams!;

    return LnUrlResolvedDetails(
      callback: lnurlPayParams.callback,
      minAmount: lnurlPayParams.minSendable,
      maxAmount: lnurlPayParams.maxSendable,
      commentAllowed: 0,
    );
  }

  /// Validates that amount is within LNURL limits.
  void validateAmount({
    required BitcoinAmount amount,
    required BitcoinAmount minAmount,
    required BitcoinAmount maxAmount,
  }) {
    if (amount < minAmount) {
      throw Exception('Amount $amount msat is below minimum $minAmount msat');
    }
    if (amount > maxAmount) {
      throw Exception('Amount $amount msat exceeds maximum $maxAmount msat');
    }
  }

  @override
  Future<LightningCallbackDetails> callback() async {
    final callbackUri = Uri.parse(state.resolvedDetails!.callback).replace(
      queryParameters: {
        'amount': state.params.amount!.getInMSats.toString(),
        if (state.params.comment != null && state.params.comment!.isNotEmpty)
          'comment': state.params.comment,
      },
    );

    final response = await getIt<Dio>().get(callbackUri.toString());

    final invoice = response.data['pr'] as String;

    return LightningCallbackDetails(invoice: Bolt11PaymentRequest(invoice));
  }

  @override
  Future<LightningCompletedDetails> complete() async {
    PayInvoiceResponse response = await nwc.payInvoice(
      nwc.connections[0].connection!,
      state.callbackDetails!.invoice.paymentRequest,
    );
    return LightningCompletedDetails(preimage: response.preimage!);
  }
}

class LnUrlResolvedDetails extends ResolvedDetails {
  final String callback;
  final bool allowNostr;
  final String? nostrPubkey;

  LnUrlResolvedDetails({
    required super.minAmount,
    required super.maxAmount,
    required super.commentAllowed,
    required this.callback,
    this.allowNostr = false,
    this.nostrPubkey,
  });
}

class LightningCallbackDetails extends CallbackDetails {
  final Bolt11PaymentRequest invoice;
  LightningCallbackDetails({required this.invoice});
}

class LightningCompletedDetails extends CompletedDetails {
  final String preimage;
  LightningCompletedDetails({required this.preimage});
}
