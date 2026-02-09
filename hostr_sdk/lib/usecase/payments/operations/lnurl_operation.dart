import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/usecase/main.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_operation.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart' hide Nwc;

import 'pay_state.dart';

class LnurlPayParameters extends PayParameters {
  LnurlPayParameters({super.amount, super.comment, required super.to});
}

// LnUrlResolvedDetails, LightningCallbackDetails, LightningCompletedDetails
// are now in lnurl_workflow.dart

@Injectable(env: Env.allButTestAndMock)
class LnurlPayOperation
    extends
        PayOperation<
          LnurlPayParameters,
          LnUrlResolvedDetails,
          LightningCallbackDetails,
          LightningCompletedDetails
        > {
  final Nwc nwc;

  LnurlPayOperation({@factoryParam required super.params, required this.nwc});

  /// Converts Lightning Address (email format) to LNURL.
  String emailToLnUrl(String email) {
    final user = email.split('@')[0];
    final domain = email.split('@')[1];
    return 'lnurlp://$domain/.well-known/lnurlp/$user';
  }

  @override
  Future<LnUrlResolvedDetails> resolver() async {
    throw UnimplementedError('LNURL resolver not implemented yet');
    // // Convert lightning address to lnurl if needed
    // final lnurl = isEmail(state.params.to)
    //     ? emailToLnUrl(state.params.to)
    //     : state.params.to;

    // // Fetch the lnurl params from the remote host
    // final lnurlParams = await getParams(lnurl);

    // if (lnurlParams.error != null) {
    //   throw Exception(lnurlParams.error!.reason);
    // }

    // final lnurlPayParams = lnurlParams.payParams!;

    // return LnUrlResolvedDetails(
    //   callback: lnurlPayParams.callback,
    //   minAmount: lnurlPayParams.minSendable,
    //   maxAmount: lnurlPayParams.maxSendable,
    //   commentAllowed: 0,
    // );
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
  Future<LightningCallbackDetails> finalizer() async {
    if (state is! PayResolved<LnUrlResolvedDetails>) {
      throw Exception('Cannot call LNURL callback before payment is resolved');
    }
    throw UnimplementedError('LNURL callback not implemented yet');
    final resolvedState = state as PayResolved<LnUrlResolvedDetails>;
    // final callbackUri = Uri.parse(resolvedState.details.callback).replace(
    //   queryParameters: {
    //     'amount': state.params.amount!.getInMSats.toString(),
    //     if (state.params.comment != null && state.params.comment!.isNotEmpty)
    //       'comment': state.params.comment,
    //   },
    // );

    // final response = await getIt<Dio>().get(callbackUri.toString());

    // final invoice = response.data['pr'] as String;

    // return LightningCallbackDetails(invoice: Bolt11PaymentRequest(invoice));
  }

  @override
  Future<LightningCompletedDetails> completer() async {
    PayInvoiceResponse response = await nwc.payInvoice(
      nwc.connections[0].connection!,
      callbackDetails!.invoice.paymentRequest,
    );
    return LightningCompletedDetails(preimage: response.preimage!);
  }
}
