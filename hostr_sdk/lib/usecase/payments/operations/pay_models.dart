import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
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
