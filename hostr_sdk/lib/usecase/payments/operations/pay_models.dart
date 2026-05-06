import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl_response.dart';
import 'package:wallet/wallet.dart';

class PayParameters {
  TokenAmount? amount;
  final String to;
  String? comment;
  final int? minSendable;
  final int? maxSendable;

  PayParameters({
    required this.to,
    this.amount,
    this.comment,
    this.minSendable,
    this.maxSendable,
  });

  Map<String, Object?> toJson() => {
    'to': to,
    if (amount != null) 'amount': amount!.toJson(),
    if (comment != null) 'comment': comment,
    if (minSendable != null) 'minSendable': minSendable,
    if (maxSendable != null) 'maxSendable': maxSendable,
  };
}

class EvmPayParameters extends PayParameters {
  late EthereumAddress parsedTo;
  EvmPayParameters({
    required super.to,
    super.amount,
    super.minSendable,
    super.maxSendable,
  }) {
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
    super.minSendable,
    super.maxSendable,
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

  Map<String, Object?> toJson() => {
    'type': 'resolved',
    'minAmount': minAmount,
    'maxAmount': maxAmount,
    if (commentAllowed != null) 'commentAllowed': commentAllowed,
  };
}

class CallbackDetails {
  Map<String, Object?> toJson() => {'type': 'callback'};
}

class CompletedDetails {
  Map<String, Object?> toJson() => {'type': 'completed'};
}

class Bolt11PayParameters extends PayParameters {
  Bolt11PayParameters({
    super.amount,
    super.comment,
    required super.to,
    super.minSendable,
    super.maxSendable,
  });
}

class LnurlPayParameters extends PayParameters {
  LnurlPayParameters({
    super.amount,
    super.comment,
    required super.to,
    super.minSendable,
    super.maxSendable,
  });
}

class LnUrlResolvedDetails extends ResolvedDetails {
  final LnurlResponse response;

  LnUrlResolvedDetails({
    required super.minAmount,
    required super.maxAmount,
    required super.commentAllowed,
    required this.response,
  });

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'type': 'lnurl',
    'callback': response.callback,
    'metadata': response.metadata,
  };
}

class LightningCallbackDetails extends CallbackDetails {
  final Bolt11PaymentRequest invoice;
  LightningCallbackDetails({required this.invoice});

  @override
  Map<String, Object?> toJson() => {
    'type': 'lightning',
    'paymentRequest': invoice.paymentRequest,
    'timestamp': invoice.timestamp.toInt(),
    'expirySeconds': _invoiceExpirySeconds(invoice.tags),
  };
}

class LightningCompletedDetails extends CompletedDetails {
  final String preimage;
  LightningCompletedDetails({required this.preimage});

  @override
  Map<String, Object?> toJson() => {'type': 'lightning', 'preimage': preimage};
}

class ZapCompletedDetails extends CompletedDetails {
  final String? preimage;
  final String? zapReceiptEventId;
  final String? zapReceiptId;
  final bool confirmedByZapReceipt;

  ZapCompletedDetails({
    this.preimage,
    this.zapReceiptEventId,
    this.zapReceiptId,
    required this.confirmedByZapReceipt,
  });

  @override
  Map<String, Object?> toJson() => {
    'type': 'zap',
    if (preimage != null) 'preimage': preimage,
    if (zapReceiptEventId != null) 'zapReceiptEventId': zapReceiptEventId,
    if (zapReceiptId != null) 'zapReceiptId': zapReceiptId,
    'confirmedByZapReceipt': confirmedByZapReceipt,
  };
}

int _invoiceExpirySeconds(List<dynamic> tags) {
  for (final tag in tags) {
    if (tag.type != 'expiry') continue;
    final data = tag.data;
    if (data is num) return data.toInt();
  }
  return 3600;
}
