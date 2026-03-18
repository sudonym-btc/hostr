import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:injectable/injectable.dart';

import '../../../injection.dart';
import '../../../util/main.dart';
import '../../lnurl/lnurl.dart';
import 'pay_models.dart';
import 'pay_operation.dart';
import 'pay_state.dart';

@Injectable(env: Env.allButTestAndMock)
class LnurlPayOperation
    extends
        PayOperation<
          LnurlPayParameters,
          LnUrlResolvedDetails,
          LightningCallbackDetails,
          LightningCompletedDetails
        > {
  final LnurlUseCase lnurl;

  LnurlPayOperation({
    @factoryParam required super.params,
    required this.lnurl,
    required super.nwc,
    required super.logger,
  });

  @override
  Future<LnUrlResolvedDetails> resolver() async {
    // Resolve the LUD-16 address to an LNURL-pay link
    final lud16Link = lnurl.getLud16LinkFromLud16(state.params.to);
    if (lud16Link == null) {
      throw Exception('Invalid lightning address: ${state.params.to}');
    }

    final lnurlResponse = await lnurl.getLnurlResponse(lud16Link);
    if (lnurlResponse == null || lnurlResponse.callback == null) {
      throw Exception('Failed to resolve LNURL parameters');
    }

    return LnUrlResolvedDetails(
      response: lnurlResponse,
      minAmount: lnurlResponse.minSendable!,
      maxAmount: lnurlResponse.maxSendable!,
      commentAllowed: lnurlResponse.commentAllowed ?? 0,
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
  Future<LightningCallbackDetails> finalizer() async {
    if (state is! PayResolved<LnUrlResolvedDetails>) {
      throw Exception('Cannot call LNURL callback before payment is resolved');
    }
    final resolvedState = state as PayResolved<LnUrlResolvedDetails>;

    final invoiceResponse = await lnurl.fetchInvoice(
      lnurlResponse: resolvedState.details.response,
      amountSats: state.params.amount!.getInSats.toInt(),
      comment: state.params.comment,
    );
    if (invoiceResponse == null || invoiceResponse.invoice.isEmpty) {
      throw Exception('Failed to fetch invoice from LNURL callback');
    }

    return LightningCallbackDetails(
      invoice: Bolt11PaymentRequest(invoiceResponse.invoice),
    );
  }

  @override
  Future<LightningCompletedDetails> completer() async {
    final preimage = await settleInvoice(
      callbackDetails!.invoice.paymentRequest,
    );
    if (preimage == null) {
      throw StateError('External payment required');
    }
    return LightningCompletedDetails(preimage: preimage);
  }
}
