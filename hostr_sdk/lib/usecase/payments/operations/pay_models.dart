import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl_response.dart';
import 'package:wallet/wallet.dart';

class PayParameters {
  final BitcoinAmount? amount;
  final String to;
  final String? comment;

  PayParameters({required this.to, this.amount, this.comment});
}

class EvmPayParameters extends PayParameters {
  late EthereumAddress parsedTo;
  EvmPayParameters({required super.to, super.amount}) {
    parsedTo = EthereumAddress.fromHex(to);
  }
}

class ZapPayParameters extends PayParameters {
  final Event? event;
  ZapPayParameters({
    super.amount,
    super.comment,
    required super.to,
    this.event,
  });
}

class ZapResolvedDetails extends LnUrlResolvedDetails {
  ZapResolvedDetails({
    required super.minAmount,
    required super.maxAmount,
    required super.commentAllowed,
    required super.response,
  });
}

class ResolvedDetails {
  final int minAmount;
  final int maxAmount;
  final int? commentAllowed;

  ResolvedDetails({
    required this.minAmount,
    required this.maxAmount,
    required this.commentAllowed,
  });
}

class CallbackDetails {}

class CompletedDetails {}

class Bolt11PayParameters extends PayParameters {
  Bolt11PayParameters({super.amount, super.comment, required super.to});
}

class LnurlPayParameters extends PayParameters {
  LnurlPayParameters({super.amount, super.comment, required super.to});
}

class LnUrlResolvedDetails extends ResolvedDetails {
  final LnurlResponse response;

  LnUrlResolvedDetails({
    required super.minAmount,
    required super.maxAmount,
    required super.commentAllowed,
    required this.response,
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
