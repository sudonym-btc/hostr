import 'dart:math';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:dio/dio.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/lnurl/lnurl.dart';
import 'package:hostr/logic/cubit/payment/payment.cubit.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:validators/validators.dart';

final num btcMilliSatoshiFactor = pow(10, 11);

/// Workflow handling the 3-phase LNURL payment protocol.
/// Phase 1: Resolve LNURL/Lightning Address to payment parameters
/// Phase 2: Callback to fetch invoice
/// Phase 3: Pay invoice (delegated to NwcService)
@injectable
class LnUrlWorkflow {
  final Dio _dio;
  final CustomLogger _logger = CustomLogger();

  LnUrlWorkflow({required Dio dio}) : _dio = dio;

  /// Converts Lightning Address (email format) to LNURL.
  String emailToLnUrl(String email) {
    final user = email.split('@')[0];
    final domain = email.split('@')[1];
    return 'lnurlp://$domain/.well-known/lnurlp/$user';
  }

  /// Phase 1: Resolves LNURL or Lightning Address to payment parameters.
  Future<LnUrlResolvedDetails> resolveLnUrl({required String to}) async {
    // Convert lightning address to lnurl if needed
    final lnurl = isEmail(to) ? emailToLnUrl(to) : to;
    _logger.i('Resolving LnUrl: $lnurl');

    // Fetch the lnurl params from the remote host
    final lnurlParams = await getParams(lnurl);
    _logger.i('LnUrl endpoint response: $lnurlParams');

    if (lnurlParams.error != null) {
      throw Exception(lnurlParams.error!.reason);
    }

    final lnurlPayParams = lnurlParams.payParams!;
    _logger.i('LNURLPayParams: $lnurlPayParams');

    return LnUrlResolvedDetails(
      callback: lnurlPayParams.callback,
      minAmount: lnurlPayParams.minSendable,
      maxAmount: lnurlPayParams.maxSendable,
      commentAllowed: 0,
    );
  }

  /// Phase 2: Executes callback to fetch Lightning invoice.
  Future<LightningCallbackDetails> fetchInvoice({
    required String callbackUrl,
    required Amount amount,
    String? comment,
  }) async {
    final callbackUri = Uri.parse(callbackUrl).replace(
      queryParameters: {
        'amount': (amount.value * btcMilliSatoshiFactor).toInt().toString(),
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );

    _logger.d('Callback uri: $callbackUri');
    final response = await _dio.get(callbackUri.toString());
    _logger.d('Callback response: ${response.data}');

    final invoice = response.data['pr'] as String;
    _logger.d('Invoice received: $invoice');

    return LightningCallbackDetails(invoice: Bolt11PaymentRequest(invoice));
  }

  /// Validates that amount is within LNURL limits.
  void validateAmount({
    required Amount amount,
    required int minAmount,
    required int maxAmount,
  }) {
    final amountMsat = (amount.value * btcMilliSatoshiFactor).toInt();
    if (amountMsat < minAmount) {
      throw Exception(
        'Amount $amountMsat msat is below minimum $minAmount msat',
      );
    }
    if (amountMsat > maxAmount) {
      throw Exception(
        'Amount $amountMsat msat exceeds maximum $maxAmount msat',
      );
    }
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
