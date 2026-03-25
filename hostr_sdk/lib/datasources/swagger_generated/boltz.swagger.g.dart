// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boltz.swagger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArkTimeouts _$ArkTimeoutsFromJson(Map<String, dynamic> json) => ArkTimeouts(
  refund: (json['refund'] as num).toDouble(),
  unilateralClaim: (json['unilateralClaim'] as num).toDouble(),
  unilateralRefund: (json['unilateralRefund'] as num).toDouble(),
  unilateralRefundWithoutReceiver:
      (json['unilateralRefundWithoutReceiver'] as num).toDouble(),
);

Map<String, dynamic> _$ArkTimeoutsToJson(
  ArkTimeouts instance,
) => <String, dynamic>{
  'refund': instance.refund,
  'unilateralClaim': instance.unilateralClaim,
  'unilateralRefund': instance.unilateralRefund,
  'unilateralRefundWithoutReceiver': instance.unilateralRefundWithoutReceiver,
};

SwapTreeLeaf _$SwapTreeLeafFromJson(Map<String, dynamic> json) => SwapTreeLeaf(
  version: (json['version'] as num).toDouble(),
  output: json['output'] as String,
);

Map<String, dynamic> _$SwapTreeLeafToJson(SwapTreeLeaf instance) =>
    <String, dynamic>{'version': instance.version, 'output': instance.output};

SwapTree _$SwapTreeFromJson(Map<String, dynamic> json) => SwapTree(
  claimLeaf: SwapTreeLeaf.fromJson(json['claimLeaf'] as Map<String, dynamic>),
  refundLeaf: SwapTreeLeaf.fromJson(json['refundLeaf'] as Map<String, dynamic>),
  covenantClaimLeaf: json['covenantClaimLeaf'] == null
      ? null
      : SwapTreeLeaf.fromJson(
          json['covenantClaimLeaf'] as Map<String, dynamic>,
        ),
  refundWithoutBoltzLeaf: json['refundWithoutBoltzLeaf'] == null
      ? null
      : SwapTreeLeaf.fromJson(
          json['refundWithoutBoltzLeaf'] as Map<String, dynamic>,
        ),
  unilateralClaimLeaf: json['unilateralClaimLeaf'] == null
      ? null
      : SwapTreeLeaf.fromJson(
          json['unilateralClaimLeaf'] as Map<String, dynamic>,
        ),
  unilateralRefundLeaf: json['unilateralRefundLeaf'] == null
      ? null
      : SwapTreeLeaf.fromJson(
          json['unilateralRefundLeaf'] as Map<String, dynamic>,
        ),
  unilateralRefundWithoutBoltzLeaf:
      json['unilateralRefundWithoutBoltzLeaf'] == null
      ? null
      : SwapTreeLeaf.fromJson(
          json['unilateralRefundWithoutBoltzLeaf'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SwapTreeToJson(SwapTree instance) => <String, dynamic>{
  'claimLeaf': instance.claimLeaf.toJson(),
  'refundLeaf': instance.refundLeaf.toJson(),
  'covenantClaimLeaf': ?instance.covenantClaimLeaf?.toJson(),
  'refundWithoutBoltzLeaf': ?instance.refundWithoutBoltzLeaf?.toJson(),
  'unilateralClaimLeaf': ?instance.unilateralClaimLeaf?.toJson(),
  'unilateralRefundLeaf': ?instance.unilateralRefundLeaf?.toJson(),
  'unilateralRefundWithoutBoltzLeaf': ?instance.unilateralRefundWithoutBoltzLeaf
      ?.toJson(),
};

ExtraFees _$ExtraFeesFromJson(Map<String, dynamic> json) => ExtraFees(
  id: json['id'] as String,
  percentage: (json['percentage'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ExtraFeesToJson(ExtraFees instance) => <String, dynamic>{
  'id': instance.id,
  'percentage': ?instance.percentage,
};

SubmarinePair _$SubmarinePairFromJson(Map<String, dynamic> json) =>
    SubmarinePair(
      hash: json['hash'] as String,
      rate: (json['rate'] as num).toDouble(),
      limits: SubmarinePair$Limits.fromJson(
        json['limits'] as Map<String, dynamic>,
      ),
      fees: SubmarinePair$Fees.fromJson(json['fees'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmarinePairToJson(SubmarinePair instance) =>
    <String, dynamic>{
      'hash': instance.hash,
      'rate': instance.rate,
      'limits': instance.limits.toJson(),
      'fees': instance.fees.toJson(),
    };

WebhookData _$WebhookDataFromJson(Map<String, dynamic> json) => WebhookData(
  url: json['url'] as String,
  hashSwapId: json['hashSwapId'] as bool? ?? false,
  status:
      (json['status'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

Map<String, dynamic> _$WebhookDataToJson(WebhookData instance) =>
    <String, dynamic>{
      'url': instance.url,
      'hashSwapId': ?instance.hashSwapId,
      'status': ?instance.status,
    };

SubmarineRequest _$SubmarineRequestFromJson(Map<String, dynamic> json) =>
    SubmarineRequest(
      from: json['from'] as String,
      to: json['to'] as String,
      invoice: json['invoice'] as String?,
      preimageHash: json['preimageHash'] as String?,
      refundPublicKey: json['refundPublicKey'] as String?,
      pairHash: json['pairHash'] as String?,
      referralId: json['referralId'] as String?,
      paymentTimeout: (json['paymentTimeout'] as num?)?.toDouble(),
      webhook: json['webhook'] == null
          ? null
          : WebhookData.fromJson(json['webhook'] as Map<String, dynamic>),
      extraFees: json['extraFees'] == null
          ? null
          : ExtraFees.fromJson(json['extraFees'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmarineRequestToJson(SubmarineRequest instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'invoice': ?instance.invoice,
      'preimageHash': ?instance.preimageHash,
      'refundPublicKey': ?instance.refundPublicKey,
      'pairHash': ?instance.pairHash,
      'referralId': ?instance.referralId,
      'paymentTimeout': ?instance.paymentTimeout,
      'webhook': ?instance.webhook?.toJson(),
      'extraFees': ?instance.extraFees?.toJson(),
    };

SubmarineResponse _$SubmarineResponseFromJson(Map<String, dynamic> json) =>
    SubmarineResponse(
      id: json['id'] as String,
      bip21: json['bip21'] as String?,
      address: json['address'] as String?,
      swapTree: json['swapTree'] == null
          ? null
          : SwapTree.fromJson(json['swapTree'] as Map<String, dynamic>),
      claimPublicKey: json['claimPublicKey'] as String?,
      timeoutBlockHeight: (json['timeoutBlockHeight'] as num?)?.toDouble(),
      timeoutBlockHeights: json['timeoutBlockHeights'] == null
          ? null
          : ArkTimeouts.fromJson(
              json['timeoutBlockHeights'] as Map<String, dynamic>,
            ),
      acceptZeroConf: json['acceptZeroConf'] as bool?,
      expectedAmount: (json['expectedAmount'] as num).toDouble(),
      blindingKey: json['blindingKey'] as String?,
      referralId: json['referralId'] as String?,
    );

Map<String, dynamic> _$SubmarineResponseToJson(SubmarineResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bip21': ?instance.bip21,
      'address': ?instance.address,
      'swapTree': ?instance.swapTree?.toJson(),
      'claimPublicKey': ?instance.claimPublicKey,
      'timeoutBlockHeight': ?instance.timeoutBlockHeight,
      'timeoutBlockHeights': ?instance.timeoutBlockHeights?.toJson(),
      'acceptZeroConf': ?instance.acceptZeroConf,
      'expectedAmount': instance.expectedAmount,
      'blindingKey': ?instance.blindingKey,
      'referralId': ?instance.referralId,
    };

SubmarineTransaction _$SubmarineTransactionFromJson(
  Map<String, dynamic> json,
) => SubmarineTransaction(
  id: json['id'] as String,
  hex: json['hex'] as String?,
  timeoutBlockHeight: (json['timeoutBlockHeight'] as num).toDouble(),
  timeoutEta: (json['timeoutEta'] as num?)?.toDouble(),
);

Map<String, dynamic> _$SubmarineTransactionToJson(
  SubmarineTransaction instance,
) => <String, dynamic>{
  'id': instance.id,
  'hex': ?instance.hex,
  'timeoutBlockHeight': instance.timeoutBlockHeight,
  'timeoutEta': ?instance.timeoutEta,
};

SubmarinePreimage _$SubmarinePreimageFromJson(Map<String, dynamic> json) =>
    SubmarinePreimage(preimage: json['preimage'] as String);

Map<String, dynamic> _$SubmarinePreimageToJson(SubmarinePreimage instance) =>
    <String, dynamic>{'preimage': instance.preimage};

RefundRequest _$RefundRequestFromJson(Map<String, dynamic> json) =>
    RefundRequest(
      pubNonce: json['pubNonce'] as String,
      transaction: json['transaction'] as String,
      index: (json['index'] as num).toDouble(),
    );

Map<String, dynamic> _$RefundRequestToJson(RefundRequest instance) =>
    <String, dynamic>{
      'pubNonce': instance.pubNonce,
      'transaction': instance.transaction,
      'index': instance.index,
    };

PartialSignature _$PartialSignatureFromJson(Map<String, dynamic> json) =>
    PartialSignature(
      pubNonce: json['pubNonce'] as String,
      partialSignature: json['partialSignature'] as String,
    );

Map<String, dynamic> _$PartialSignatureToJson(PartialSignature instance) =>
    <String, dynamic>{
      'pubNonce': instance.pubNonce,
      'partialSignature': instance.partialSignature,
    };

ArkRefundRequest _$ArkRefundRequestFromJson(Map<String, dynamic> json) =>
    ArkRefundRequest(
      transaction: json['transaction'] as String,
      checkpoint: json['checkpoint'] as String,
    );

Map<String, dynamic> _$ArkRefundRequestToJson(ArkRefundRequest instance) =>
    <String, dynamic>{
      'transaction': instance.transaction,
      'checkpoint': instance.checkpoint,
    };

ArkRefundResponse _$ArkRefundResponseFromJson(Map<String, dynamic> json) =>
    ArkRefundResponse(
      transaction: json['transaction'] as String,
      checkpoint: json['checkpoint'] as String,
    );

Map<String, dynamic> _$ArkRefundResponseToJson(ArkRefundResponse instance) =>
    <String, dynamic>{
      'transaction': instance.transaction,
      'checkpoint': instance.checkpoint,
    };

SubmarineClaimDetails _$SubmarineClaimDetailsFromJson(
  Map<String, dynamic> json,
) => SubmarineClaimDetails(
  preimage: json['preimage'] as String,
  pubNonce: json['pubNonce'] as String,
  publicKey: json['publicKey'] as String,
  transactionHash: json['transactionHash'] as String,
);

Map<String, dynamic> _$SubmarineClaimDetailsToJson(
  SubmarineClaimDetails instance,
) => <String, dynamic>{
  'preimage': instance.preimage,
  'pubNonce': instance.pubNonce,
  'publicKey': instance.publicKey,
  'transactionHash': instance.transactionHash,
};

ReversePair _$ReversePairFromJson(Map<String, dynamic> json) => ReversePair(
  hash: json['hash'] as String,
  rate: (json['rate'] as num).toDouble(),
  limits: ReversePair$Limits.fromJson(json['limits'] as Map<String, dynamic>),
  fees: ReversePair$Fees.fromJson(json['fees'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ReversePairToJson(ReversePair instance) =>
    <String, dynamic>{
      'hash': instance.hash,
      'rate': instance.rate,
      'limits': instance.limits.toJson(),
      'fees': instance.fees.toJson(),
    };

ReverseRequest _$ReverseRequestFromJson(Map<String, dynamic> json) =>
    ReverseRequest(
      from: json['from'] as String,
      to: json['to'] as String,
      preimageHash: json['preimageHash'] as String,
      claimPublicKey: json['claimPublicKey'] as String?,
      claimAddress: json['claimAddress'] as String?,
      invoiceAmount: (json['invoiceAmount'] as num?)?.toDouble(),
      onchainAmount: (json['onchainAmount'] as num?)?.toDouble(),
      pairHash: json['pairHash'] as String?,
      referralId: json['referralId'] as String?,
      address: json['address'] as String?,
      addressSignature: json['addressSignature'] as String?,
      claimCovenant: json['claimCovenant'] as bool? ?? false,
      description: json['description'] as String?,
      descriptionHash: json['descriptionHash'] as String?,
      invoiceExpiry: (json['invoiceExpiry'] as num?)?.toDouble(),
      webhook: json['webhook'] == null
          ? null
          : WebhookData.fromJson(json['webhook'] as Map<String, dynamic>),
      extraFees: json['extraFees'] == null
          ? null
          : ExtraFees.fromJson(json['extraFees'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReverseRequestToJson(ReverseRequest instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'preimageHash': instance.preimageHash,
      'claimPublicKey': ?instance.claimPublicKey,
      'claimAddress': ?instance.claimAddress,
      'invoiceAmount': ?instance.invoiceAmount,
      'onchainAmount': ?instance.onchainAmount,
      'pairHash': ?instance.pairHash,
      'referralId': ?instance.referralId,
      'address': ?instance.address,
      'addressSignature': ?instance.addressSignature,
      'claimCovenant': ?instance.claimCovenant,
      'description': ?instance.description,
      'descriptionHash': ?instance.descriptionHash,
      'invoiceExpiry': ?instance.invoiceExpiry,
      'webhook': ?instance.webhook?.toJson(),
      'extraFees': ?instance.extraFees?.toJson(),
    };

ReverseResponse _$ReverseResponseFromJson(Map<String, dynamic> json) =>
    ReverseResponse(
      id: json['id'] as String,
      invoice: json['invoice'] as String,
      swapTree: json['swapTree'] == null
          ? null
          : SwapTree.fromJson(json['swapTree'] as Map<String, dynamic>),
      lockupAddress: json['lockupAddress'] as String?,
      refundPublicKey: json['refundPublicKey'] as String?,
      refundAddress: json['refundAddress'] as String?,
      timeoutBlockHeight: (json['timeoutBlockHeight'] as num?)?.toDouble(),
      timeoutBlockHeights: json['timeoutBlockHeights'] == null
          ? null
          : ArkTimeouts.fromJson(
              json['timeoutBlockHeights'] as Map<String, dynamic>,
            ),
      onchainAmount: (json['onchainAmount'] as num?)?.toDouble(),
      blindingKey: json['blindingKey'] as String?,
      referralId: json['referralId'] as String?,
    );

Map<String, dynamic> _$ReverseResponseToJson(ReverseResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoice': instance.invoice,
      'swapTree': ?instance.swapTree?.toJson(),
      'lockupAddress': ?instance.lockupAddress,
      'refundPublicKey': ?instance.refundPublicKey,
      'refundAddress': ?instance.refundAddress,
      'timeoutBlockHeight': ?instance.timeoutBlockHeight,
      'timeoutBlockHeights': ?instance.timeoutBlockHeights?.toJson(),
      'onchainAmount': ?instance.onchainAmount,
      'blindingKey': ?instance.blindingKey,
      'referralId': ?instance.referralId,
    };

InvoiceExpiryRange _$InvoiceExpiryRangeFromJson(Map<String, dynamic> json) =>
    InvoiceExpiryRange(
      min: (json['min'] as num).toDouble(),
      max: (json['max'] as num).toDouble(),
    );

Map<String, dynamic> _$InvoiceExpiryRangeToJson(InvoiceExpiryRange instance) =>
    <String, dynamic>{'min': instance.min, 'max': instance.max};

ReverseTransaction _$ReverseTransactionFromJson(Map<String, dynamic> json) =>
    ReverseTransaction(
      id: json['id'] as String,
      hex: json['hex'] as String?,
      timeoutBlockHeight: (json['timeoutBlockHeight'] as num).toDouble(),
    );

Map<String, dynamic> _$ReverseTransactionToJson(ReverseTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hex': ?instance.hex,
      'timeoutBlockHeight': instance.timeoutBlockHeight,
    };

ReverseClaimRequest _$ReverseClaimRequestFromJson(Map<String, dynamic> json) =>
    ReverseClaimRequest(
      preimage: json['preimage'] as String,
      pubNonce: json['pubNonce'] as String?,
      transaction: json['transaction'] as String?,
      index: (json['index'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ReverseClaimRequestToJson(
  ReverseClaimRequest instance,
) => <String, dynamic>{
  'preimage': instance.preimage,
  'pubNonce': ?instance.pubNonce,
  'transaction': ?instance.transaction,
  'index': ?instance.index,
};

ReverseBip21 _$ReverseBip21FromJson(Map<String, dynamic> json) => ReverseBip21(
  bip21: json['bip21'] as String,
  signature: json['signature'] as String,
);

Map<String, dynamic> _$ReverseBip21ToJson(ReverseBip21 instance) =>
    <String, dynamic>{'bip21': instance.bip21, 'signature': instance.signature};

ChainPair _$ChainPairFromJson(Map<String, dynamic> json) => ChainPair(
  hash: json['hash'] as String,
  rate: (json['rate'] as num).toDouble(),
  limits: ChainPair$Limits.fromJson(json['limits'] as Map<String, dynamic>),
  fees: ChainPair$Fees.fromJson(json['fees'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChainPairToJson(ChainPair instance) => <String, dynamic>{
  'hash': instance.hash,
  'rate': instance.rate,
  'limits': instance.limits.toJson(),
  'fees': instance.fees.toJson(),
};

ChainRequest _$ChainRequestFromJson(Map<String, dynamic> json) => ChainRequest(
  from: json['from'] as String,
  to: json['to'] as String,
  preimageHash: json['preimageHash'] as String,
  claimPublicKey: json['claimPublicKey'] as String?,
  refundPublicKey: json['refundPublicKey'] as String?,
  claimAddress: json['claimAddress'] as String?,
  userLockAmount: (json['userLockAmount'] as num?)?.toDouble(),
  serverLockAmount: (json['serverLockAmount'] as num?)?.toDouble(),
  pairHash: json['pairHash'] as String?,
  referralId: json['referralId'] as String?,
  webhook: json['webhook'] == null
      ? null
      : WebhookData.fromJson(json['webhook'] as Map<String, dynamic>),
  extraFees: json['extraFees'] == null
      ? null
      : ExtraFees.fromJson(json['extraFees'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ChainRequestToJson(ChainRequest instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'preimageHash': instance.preimageHash,
      'claimPublicKey': ?instance.claimPublicKey,
      'refundPublicKey': ?instance.refundPublicKey,
      'claimAddress': ?instance.claimAddress,
      'userLockAmount': ?instance.userLockAmount,
      'serverLockAmount': ?instance.serverLockAmount,
      'pairHash': ?instance.pairHash,
      'referralId': ?instance.referralId,
      'webhook': ?instance.webhook?.toJson(),
      'extraFees': ?instance.extraFees?.toJson(),
    };

ChainSwapData _$ChainSwapDataFromJson(Map<String, dynamic> json) =>
    ChainSwapData(
      swapTree: json['swapTree'] == null
          ? null
          : SwapTree.fromJson(json['swapTree'] as Map<String, dynamic>),
      lockupAddress: json['lockupAddress'] as String?,
      serverPublicKey: json['serverPublicKey'] as String?,
      timeoutBlockHeight: (json['timeoutBlockHeight'] as num?)?.toDouble(),
      timeoutBlockHeights: json['timeoutBlockHeights'] == null
          ? null
          : ArkTimeouts.fromJson(
              json['timeoutBlockHeights'] as Map<String, dynamic>,
            ),
      amount: (json['amount'] as num).toDouble(),
      blindingKey: json['blindingKey'] as String?,
      refundAddress: json['refundAddress'] as String?,
      bip21: json['bip21'] as String?,
      claimAddress: json['claimAddress'] as String?,
    );

Map<String, dynamic> _$ChainSwapDataToJson(ChainSwapData instance) =>
    <String, dynamic>{
      'swapTree': ?instance.swapTree?.toJson(),
      'lockupAddress': ?instance.lockupAddress,
      'serverPublicKey': ?instance.serverPublicKey,
      'timeoutBlockHeight': ?instance.timeoutBlockHeight,
      'timeoutBlockHeights': ?instance.timeoutBlockHeights?.toJson(),
      'amount': instance.amount,
      'blindingKey': ?instance.blindingKey,
      'refundAddress': ?instance.refundAddress,
      'bip21': ?instance.bip21,
      'claimAddress': ?instance.claimAddress,
    };

ChainResponse _$ChainResponseFromJson(Map<String, dynamic> json) =>
    ChainResponse(
      id: json['id'] as String,
      referralId: json['referralId'] as String?,
      claimDetails: ChainSwapData.fromJson(
        json['claimDetails'] as Map<String, dynamic>,
      ),
      lockupDetails: ChainSwapData.fromJson(
        json['lockupDetails'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ChainResponseToJson(ChainResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'referralId': ?instance.referralId,
      'claimDetails': instance.claimDetails.toJson(),
      'lockupDetails': instance.lockupDetails.toJson(),
    };

ChainSwapTransaction _$ChainSwapTransactionFromJson(
  Map<String, dynamic> json,
) => ChainSwapTransaction(
  transaction: ChainSwapTransaction$Transaction.fromJson(
    json['transaction'] as Map<String, dynamic>,
  ),
  timeout: json['timeout'] == null
      ? null
      : ChainSwapTransaction$Timeout.fromJson(
          json['timeout'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ChainSwapTransactionToJson(
  ChainSwapTransaction instance,
) => <String, dynamic>{
  'transaction': instance.transaction.toJson(),
  'timeout': ?instance.timeout?.toJson(),
};

ChainSwapTransactions _$ChainSwapTransactionsFromJson(
  Map<String, dynamic> json,
) => ChainSwapTransactions(
  userLock: json['userLock'] == null
      ? null
      : ChainSwapTransaction.fromJson(json['userLock'] as Map<String, dynamic>),
  serverLock: json['serverLock'] == null
      ? null
      : ChainSwapTransaction.fromJson(
          json['serverLock'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ChainSwapTransactionsToJson(
  ChainSwapTransactions instance,
) => <String, dynamic>{
  'userLock': ?instance.userLock?.toJson(),
  'serverLock': ?instance.serverLock?.toJson(),
};

ChainSwapSigningDetails _$ChainSwapSigningDetailsFromJson(
  Map<String, dynamic> json,
) => ChainSwapSigningDetails(
  pubNonce: json['pubNonce'] as String,
  publicKey: json['publicKey'] as String,
  transactionHash: json['transactionHash'] as String,
);

Map<String, dynamic> _$ChainSwapSigningDetailsToJson(
  ChainSwapSigningDetails instance,
) => <String, dynamic>{
  'pubNonce': instance.pubNonce,
  'publicKey': instance.publicKey,
  'transactionHash': instance.transactionHash,
};

ChainSwapSigningRequest _$ChainSwapSigningRequestFromJson(
  Map<String, dynamic> json,
) => ChainSwapSigningRequest(
  preimage: json['preimage'] as String?,
  signature: json['signature'] == null
      ? null
      : PartialSignature.fromJson(json['signature'] as Map<String, dynamic>),
  toSign: json['toSign'] == null
      ? null
      : ChainSwapSigningRequest$ToSign.fromJson(
          json['toSign'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$ChainSwapSigningRequestToJson(
  ChainSwapSigningRequest instance,
) => <String, dynamic>{
  'preimage': ?instance.preimage,
  'signature': ?instance.signature?.toJson(),
  'toSign': ?instance.toSign?.toJson(),
};

Quote _$QuoteFromJson(Map<String, dynamic> json) =>
    Quote(amount: (json['amount'] as num).toDouble());

Map<String, dynamic> _$QuoteToJson(Quote instance) => <String, dynamic>{
  'amount': instance.amount,
};

QuoteResponse _$QuoteResponseFromJson(Map<String, dynamic> json) =>
    QuoteResponse();

Map<String, dynamic> _$QuoteResponseToJson(QuoteResponse instance) =>
    <String, dynamic>{};

SwapStatus _$SwapStatusFromJson(Map<String, dynamic> json) => SwapStatus(
  status: json['status'] as String,
  zeroConfRejected: json['zeroConfRejected'] as bool?,
  transaction: json['transaction'] == null
      ? null
      : SwapStatus$Transaction.fromJson(
          json['transaction'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$SwapStatusToJson(SwapStatus instance) =>
    <String, dynamic>{
      'status': instance.status,
      'zeroConfRejected': ?instance.zeroConfRejected,
      'transaction': ?instance.transaction?.toJson(),
    };

RescueRequest _$RescueRequestFromJson(Map<String, dynamic> json) =>
    RescueRequest();

Map<String, dynamic> _$RescueRequestToJson(RescueRequest instance) =>
    <String, dynamic>{};

Transaction _$TransactionFromJson(Map<String, dynamic> json) =>
    Transaction(id: json['id'] as String, hex: json['hex'] as String);

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{'id': instance.id, 'hex': instance.hex};

RescuableSwap _$RescuableSwapFromJson(Map<String, dynamic> json) =>
    RescuableSwap(
      id: json['id'] as String,
      type: rescuableSwapTypeFromJson(json['type']),
      status: json['status'] as String,
      symbol: json['symbol'] as String,
      keyIndex: (json['keyIndex'] as num).toDouble(),
      preimageHash: json['preimageHash'] as String,
      invoice: json['invoice'] as String?,
      timeoutBlockHeight: (json['timeoutBlockHeight'] as num).toDouble(),
      serverPublicKey: json['serverPublicKey'] as String,
      blindingKey: json['blindingKey'] as String?,
      tree: SwapTree.fromJson(json['tree'] as Map<String, dynamic>),
      lockupAddress: json['lockupAddress'] as String,
      transaction: json['transaction'] == null
          ? null
          : Transaction.fromJson(json['transaction'] as Map<String, dynamic>),
      createdAt: (json['createdAt'] as num).toDouble(),
    );

Map<String, dynamic> _$RescuableSwapToJson(RescuableSwap instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': ?rescuableSwapTypeToJson(instance.type),
      'status': instance.status,
      'symbol': instance.symbol,
      'keyIndex': instance.keyIndex,
      'preimageHash': instance.preimageHash,
      'invoice': ?instance.invoice,
      'timeoutBlockHeight': instance.timeoutBlockHeight,
      'serverPublicKey': instance.serverPublicKey,
      'blindingKey': ?instance.blindingKey,
      'tree': instance.tree.toJson(),
      'lockupAddress': instance.lockupAddress,
      'transaction': ?instance.transaction?.toJson(),
      'createdAt': instance.createdAt,
    };

RestoreClaimDetails _$RestoreClaimDetailsFromJson(Map<String, dynamic> json) =>
    RestoreClaimDetails(
      tree: SwapTree.fromJson(json['tree'] as Map<String, dynamic>),
      amount: (json['amount'] as num?)?.toDouble(),
      keyIndex: (json['keyIndex'] as num).toDouble(),
      transaction: json['transaction'] == null
          ? null
          : Transaction.fromJson(json['transaction'] as Map<String, dynamic>),
      lockupAddress: json['lockupAddress'] as String,
      serverPublicKey: json['serverPublicKey'] as String,
      timeoutBlockHeight: (json['timeoutBlockHeight'] as num?)?.toDouble(),
      timeoutBlockHeights: json['timeoutBlockHeights'] == null
          ? null
          : ArkTimeouts.fromJson(
              json['timeoutBlockHeights'] as Map<String, dynamic>,
            ),
      blindingKey: json['blindingKey'] as String?,
      preimageHash: json['preimageHash'] as String,
    );

Map<String, dynamic> _$RestoreClaimDetailsToJson(
  RestoreClaimDetails instance,
) => <String, dynamic>{
  'tree': instance.tree.toJson(),
  'amount': ?instance.amount,
  'keyIndex': instance.keyIndex,
  'transaction': ?instance.transaction?.toJson(),
  'lockupAddress': instance.lockupAddress,
  'serverPublicKey': instance.serverPublicKey,
  'timeoutBlockHeight': ?instance.timeoutBlockHeight,
  'timeoutBlockHeights': ?instance.timeoutBlockHeights?.toJson(),
  'blindingKey': ?instance.blindingKey,
  'preimageHash': instance.preimageHash,
};

RestoreRefundDetails _$RestoreRefundDetailsFromJson(
  Map<String, dynamic> json,
) => RestoreRefundDetails(
  tree: SwapTree.fromJson(json['tree'] as Map<String, dynamic>),
  amount: (json['amount'] as num?)?.toDouble(),
  keyIndex: (json['keyIndex'] as num).toDouble(),
  transaction: json['transaction'] == null
      ? null
      : Transaction.fromJson(json['transaction'] as Map<String, dynamic>),
  lockupAddress: json['lockupAddress'] as String,
  serverPublicKey: json['serverPublicKey'] as String,
  timeoutBlockHeight: (json['timeoutBlockHeight'] as num?)?.toDouble(),
  timeoutBlockHeights: json['timeoutBlockHeights'] == null
      ? null
      : ArkTimeouts.fromJson(
          json['timeoutBlockHeights'] as Map<String, dynamic>,
        ),
  blindingKey: json['blindingKey'] as String?,
);

Map<String, dynamic> _$RestoreRefundDetailsToJson(
  RestoreRefundDetails instance,
) => <String, dynamic>{
  'tree': instance.tree.toJson(),
  'amount': ?instance.amount,
  'keyIndex': instance.keyIndex,
  'transaction': ?instance.transaction?.toJson(),
  'lockupAddress': instance.lockupAddress,
  'serverPublicKey': instance.serverPublicKey,
  'timeoutBlockHeight': ?instance.timeoutBlockHeight,
  'timeoutBlockHeights': ?instance.timeoutBlockHeights?.toJson(),
  'blindingKey': ?instance.blindingKey,
};

RestorableSwap _$RestorableSwapFromJson(Map<String, dynamic> json) =>
    RestorableSwap(
      id: json['id'] as String,
      type: restorableSwapTypeFromJson(json['type']),
      status: json['status'] as String,
      createdAt: (json['createdAt'] as num).toDouble(),
      from: json['from'] as String,
      to: json['to'] as String,
      preimageHash: json['preimageHash'] as String?,
      invoice: json['invoice'] as String?,
      claimDetails: json['claimDetails'] == null
          ? null
          : RestoreClaimDetails.fromJson(
              json['claimDetails'] as Map<String, dynamic>,
            ),
      refundDetails: json['refundDetails'] == null
          ? null
          : RestoreRefundDetails.fromJson(
              json['refundDetails'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$RestorableSwapToJson(RestorableSwap instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': ?restorableSwapTypeToJson(instance.type),
      'status': instance.status,
      'createdAt': instance.createdAt,
      'from': instance.from,
      'to': instance.to,
      'preimageHash': ?instance.preimageHash,
      'invoice': ?instance.invoice,
      'claimDetails': ?instance.claimDetails?.toJson(),
      'refundDetails': ?instance.refundDetails?.toJson(),
    };

RestoreIndexResponse _$RestoreIndexResponseFromJson(
  Map<String, dynamic> json,
) => RestoreIndexResponse(index: (json['index'] as num).toDouble());

Map<String, dynamic> _$RestoreIndexResponseToJson(
  RestoreIndexResponse instance,
) => <String, dynamic>{'index': instance.index};

AssetRescueSetupRequest _$AssetRescueSetupRequestFromJson(
  Map<String, dynamic> json,
) => AssetRescueSetupRequest(
  swapId: json['swapId'] as String,
  transactionId: json['transactionId'] as String,
  vout: (json['vout'] as num).toDouble(),
  destination: json['destination'] as String,
);

Map<String, dynamic> _$AssetRescueSetupRequestToJson(
  AssetRescueSetupRequest instance,
) => <String, dynamic>{
  'swapId': instance.swapId,
  'transactionId': instance.transactionId,
  'vout': instance.vout,
  'destination': instance.destination,
};

AssetRescueMusigData _$AssetRescueMusigDataFromJson(
  Map<String, dynamic> json,
) => AssetRescueMusigData(
  serverPublicKey: json['serverPublicKey'] as String,
  pubNonce: json['pubNonce'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$AssetRescueMusigDataToJson(
  AssetRescueMusigData instance,
) => <String, dynamic>{
  'serverPublicKey': instance.serverPublicKey,
  'pubNonce': instance.pubNonce,
  'message': instance.message,
};

AssetRescueSetupResponse _$AssetRescueSetupResponseFromJson(
  Map<String, dynamic> json,
) => AssetRescueSetupResponse(
  musig: AssetRescueMusigData.fromJson(json['musig'] as Map<String, dynamic>),
  transaction: json['transaction'] as String,
);

Map<String, dynamic> _$AssetRescueSetupResponseToJson(
  AssetRescueSetupResponse instance,
) => <String, dynamic>{
  'musig': instance.musig.toJson(),
  'transaction': instance.transaction,
};

AssetRescueBroadcastRequest _$AssetRescueBroadcastRequestFromJson(
  Map<String, dynamic> json,
) => AssetRescueBroadcastRequest(
  swapId: json['swapId'] as String,
  pubNonce: json['pubNonce'] as String,
  partialSignature: json['partialSignature'] as String,
);

Map<String, dynamic> _$AssetRescueBroadcastRequestToJson(
  AssetRescueBroadcastRequest instance,
) => <String, dynamic>{
  'swapId': instance.swapId,
  'pubNonce': instance.pubNonce,
  'partialSignature': instance.partialSignature,
};

AssetRescueBroadcastResponse _$AssetRescueBroadcastResponseFromJson(
  Map<String, dynamic> json,
) => AssetRescueBroadcastResponse(
  transactionId: json['transactionId'] as String,
);

Map<String, dynamic> _$AssetRescueBroadcastResponseToJson(
  AssetRescueBroadcastResponse instance,
) => <String, dynamic>{'transactionId': instance.transactionId};

PairStats _$PairStatsFromJson(Map<String, dynamic> json) => PairStats(
  fee:
      (json['fee'] as List<dynamic>?)
          ?.map((e) => e as List<dynamic>)
          .toList() ??
      [],
  maximalRoutingFee:
      (json['maximalRoutingFee'] as List<dynamic>?)
          ?.map((e) => e as List<dynamic>)
          .toList() ??
      [],
);

Map<String, dynamic> _$PairStatsToJson(PairStats instance) => <String, dynamic>{
  'fee': instance.fee,
  'maximalRoutingFee': ?instance.maximalRoutingFee,
};

LightningNode _$LightningNodeFromJson(Map<String, dynamic> json) =>
    LightningNode(
      id: json['id'] as String,
      alias: json['alias'] as String?,
      color: json['color'] as String?,
    );

Map<String, dynamic> _$LightningNodeToJson(LightningNode instance) =>
    <String, dynamic>{
      'id': instance.id,
      'alias': ?instance.alias,
      'color': ?instance.color,
    };

LightningChannelPolicy _$LightningChannelPolicyFromJson(
  Map<String, dynamic> json,
) => LightningChannelPolicy(
  active: json['active'] as bool,
  baseFeeMillisatoshi: (json['baseFeeMillisatoshi'] as num).toDouble(),
  feePpm: (json['feePpm'] as num).toDouble(),
  delay: (json['delay'] as num).toDouble(),
  htlcMinimumMillisatoshi: (json['htlcMinimumMillisatoshi'] as num?)
      ?.toDouble(),
  htlcMaximumMillisatoshi: (json['htlcMaximumMillisatoshi'] as num?)
      ?.toDouble(),
);

Map<String, dynamic> _$LightningChannelPolicyToJson(
  LightningChannelPolicy instance,
) => <String, dynamic>{
  'active': instance.active,
  'baseFeeMillisatoshi': instance.baseFeeMillisatoshi,
  'feePpm': instance.feePpm,
  'delay': instance.delay,
  'htlcMinimumMillisatoshi': ?instance.htlcMinimumMillisatoshi,
  'htlcMaximumMillisatoshi': ?instance.htlcMaximumMillisatoshi,
};

LightningChannel _$LightningChannelFromJson(Map<String, dynamic> json) =>
    LightningChannel(
      source: LightningNode.fromJson(json['source'] as Map<String, dynamic>),
      shortChannelId: json['shortChannelId'] as String,
      capacity: (json['capacity'] as num?)?.toDouble(),
      active: json['active'] as bool?,
      info: json['info'] == null
          ? null
          : LightningChannelPolicy.fromJson(
              json['info'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$LightningChannelToJson(LightningChannel instance) =>
    <String, dynamic>{
      'source': instance.source.toJson(),
      'shortChannelId': instance.shortChannelId,
      'capacity': ?instance.capacity,
      'active': ?instance.active,
      'info': ?instance.info?.toJson(),
    };

LightningChannelInfo _$LightningChannelInfoFromJson(
  Map<String, dynamic> json,
) => LightningChannelInfo(
  shortChannelId: json['shortChannelId'] as String,
  capacity: (json['capacity'] as num).toDouble(),
  policies:
      (json['policies'] as List<dynamic>?)
          ?.map(
            (e) => LightningChannelPolicy.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
);

Map<String, dynamic> _$LightningChannelInfoToJson(
  LightningChannelInfo instance,
) => <String, dynamic>{
  'shortChannelId': instance.shortChannelId,
  'capacity': instance.capacity,
  'policies': instance.policies.map((e) => e.toJson()).toList(),
};

Contracts _$ContractsFromJson(Map<String, dynamic> json) => Contracts(
  network: Contracts$Network.fromJson(json['network'] as Map<String, dynamic>),
  swapContracts: Contracts$SwapContracts.fromJson(
    json['swapContracts'] as Map<String, dynamic>,
  ),
  supportedContracts: json['supportedContracts'] as Map<String, dynamic>,
  tokens: json['tokens'] as Map<String, dynamic>,
);

Map<String, dynamic> _$ContractsToJson(Contracts instance) => <String, dynamic>{
  'network': instance.network.toJson(),
  'swapContracts': instance.swapContracts.toJson(),
  'supportedContracts': instance.supportedContracts,
  'tokens': instance.tokens,
};

TokenQuote _$TokenQuoteFromJson(Map<String, dynamic> json) => TokenQuote(
  quote: json['quote'] as String,
  data: json['data'] as Map<String, dynamic>,
);

Map<String, dynamic> _$TokenQuoteToJson(TokenQuote instance) =>
    <String, dynamic>{'quote': instance.quote, 'data': instance.data};

Call _$CallFromJson(Map<String, dynamic> json) => Call(
  to: json['to'] as String,
  value: json['value'] as String,
  data: json['data'] as String,
);

Map<String, dynamic> _$CallToJson(Call instance) => <String, dynamic>{
  'to': instance.to,
  'value': instance.value,
  'data': instance.data,
};

NodeInfo _$NodeInfoFromJson(Map<String, dynamic> json) => NodeInfo(
  publicKey: json['publicKey'] as String,
  uris:
      (json['uris'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
);

Map<String, dynamic> _$NodeInfoToJson(NodeInfo instance) => <String, dynamic>{
  'publicKey': instance.publicKey,
  'uris': instance.uris,
};

NodeStats _$NodeStatsFromJson(Map<String, dynamic> json) => NodeStats(
  capacity: (json['capacity'] as num).toInt(),
  channels: (json['channels'] as num).toInt(),
  peers: (json['peers'] as num).toInt(),
  oldestChannel: (json['oldestChannel'] as num).toInt(),
);

Map<String, dynamic> _$NodeStatsToJson(NodeStats instance) => <String, dynamic>{
  'capacity': instance.capacity,
  'channels': instance.channels,
  'peers': instance.peers,
  'oldestChannel': instance.oldestChannel,
};

CommitmentLockupDetails _$CommitmentLockupDetailsFromJson(
  Map<String, dynamic> json,
) => CommitmentLockupDetails(
  contract: json['contract'] as String,
  claimAddress: json['claimAddress'] as String,
  timelock: (json['timelock'] as num).toDouble(),
);

Map<String, dynamic> _$CommitmentLockupDetailsToJson(
  CommitmentLockupDetails instance,
) => <String, dynamic>{
  'contract': instance.contract,
  'claimAddress': instance.claimAddress,
  'timelock': instance.timelock,
};

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(error: json['error'] as String);

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{'error': instance.error};

SwapSubmarineIdInvoicePost$RequestBody
_$SwapSubmarineIdInvoicePost$RequestBodyFromJson(Map<String, dynamic> json) =>
    SwapSubmarineIdInvoicePost$RequestBody(
      invoice: json['invoice'] as String,
      pairHash: json['pairHash'] as String?,
    );

Map<String, dynamic> _$SwapSubmarineIdInvoicePost$RequestBodyToJson(
  SwapSubmarineIdInvoicePost$RequestBody instance,
) => <String, dynamic>{
  'invoice': instance.invoice,
  'pairHash': ?instance.pairHash,
};

LightningCurrencyBolt12Post$RequestBody
_$LightningCurrencyBolt12Post$RequestBodyFromJson(Map<String, dynamic> json) =>
    LightningCurrencyBolt12Post$RequestBody(
      offer: json['offer'] as String,
      url: json['url'] as String?,
    );

Map<String, dynamic> _$LightningCurrencyBolt12Post$RequestBodyToJson(
  LightningCurrencyBolt12Post$RequestBody instance,
) => <String, dynamic>{'offer': instance.offer, 'url': ?instance.url};

LightningCurrencyBolt12Patch$RequestBody
_$LightningCurrencyBolt12Patch$RequestBodyFromJson(Map<String, dynamic> json) =>
    LightningCurrencyBolt12Patch$RequestBody(
      offer: json['offer'] as String,
      url: json['url'] as String?,
      signature: json['signature'] as String,
    );

Map<String, dynamic> _$LightningCurrencyBolt12Patch$RequestBodyToJson(
  LightningCurrencyBolt12Patch$RequestBody instance,
) => <String, dynamic>{
  'offer': instance.offer,
  'url': ?instance.url,
  'signature': instance.signature,
};

LightningCurrencyBolt12Delete$RequestBody
_$LightningCurrencyBolt12Delete$RequestBodyFromJson(
  Map<String, dynamic> json,
) => LightningCurrencyBolt12Delete$RequestBody(
  offer: json['offer'] as String,
  signature: json['signature'] as String,
);

Map<String, dynamic> _$LightningCurrencyBolt12Delete$RequestBodyToJson(
  LightningCurrencyBolt12Delete$RequestBody instance,
) => <String, dynamic>{
  'offer': instance.offer,
  'signature': instance.signature,
};

LightningCurrencyBolt12FetchPost$RequestBody
_$LightningCurrencyBolt12FetchPost$RequestBodyFromJson(
  Map<String, dynamic> json,
) => LightningCurrencyBolt12FetchPost$RequestBody(
  offer: json['offer'] as String,
  amount: (json['amount'] as num).toDouble(),
  note: json['note'] as String?,
);

Map<String, dynamic> _$LightningCurrencyBolt12FetchPost$RequestBodyToJson(
  LightningCurrencyBolt12FetchPost$RequestBody instance,
) => <String, dynamic>{
  'offer': instance.offer,
  'amount': instance.amount,
  'note': ?instance.note,
};

ChainCurrencyTransactionPost$RequestBody
_$ChainCurrencyTransactionPost$RequestBodyFromJson(Map<String, dynamic> json) =>
    ChainCurrencyTransactionPost$RequestBody(hex: json['hex'] as String);

Map<String, dynamic> _$ChainCurrencyTransactionPost$RequestBodyToJson(
  ChainCurrencyTransactionPost$RequestBody instance,
) => <String, dynamic>{'hex': instance.hex};

QuoteCurrencyEncodePost$RequestBody
_$QuoteCurrencyEncodePost$RequestBodyFromJson(Map<String, dynamic> json) =>
    QuoteCurrencyEncodePost$RequestBody(
      recipient: json['recipient'] as String,
      amountIn: json['amountIn'] as String,
      amountOutMin: json['amountOutMin'] as String,
      data: json['data'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$QuoteCurrencyEncodePost$RequestBodyToJson(
  QuoteCurrencyEncodePost$RequestBody instance,
) => <String, dynamic>{
  'recipient': instance.recipient,
  'amountIn': instance.amountIn,
  'amountOutMin': instance.amountOutMin,
  'data': instance.data,
};

CommitmentCurrencyPost$RequestBody _$CommitmentCurrencyPost$RequestBodyFromJson(
  Map<String, dynamic> json,
) => CommitmentCurrencyPost$RequestBody(
  swapId: json['swapId'] as String,
  signature: json['signature'] as String,
  transactionHash: json['transactionHash'] as String,
  logIndex: (json['logIndex'] as num?)?.toInt(),
  maxOverpaymentPercentage: (json['maxOverpaymentPercentage'] as num?)
      ?.toDouble(),
);

Map<String, dynamic> _$CommitmentCurrencyPost$RequestBodyToJson(
  CommitmentCurrencyPost$RequestBody instance,
) => <String, dynamic>{
  'swapId': instance.swapId,
  'signature': instance.signature,
  'transactionHash': instance.transactionHash,
  'logIndex': ?instance.logIndex,
  'maxOverpaymentPercentage': ?instance.maxOverpaymentPercentage,
};

CommitmentCurrencyRefundPost$RequestBody
_$CommitmentCurrencyRefundPost$RequestBodyFromJson(Map<String, dynamic> json) =>
    CommitmentCurrencyRefundPost$RequestBody(
      transactionHash: json['transactionHash'] as String,
      logIndex: (json['logIndex'] as num?)?.toInt(),
      refundAddressSignature: json['refundAddressSignature'] as String,
    );

Map<String, dynamic> _$CommitmentCurrencyRefundPost$RequestBodyToJson(
  CommitmentCurrencyRefundPost$RequestBody instance,
) => <String, dynamic>{
  'transactionHash': instance.transactionHash,
  'logIndex': ?instance.logIndex,
  'refundAddressSignature': instance.refundAddressSignature,
};

VersionGet$Response _$VersionGet$ResponseFromJson(Map<String, dynamic> json) =>
    VersionGet$Response(version: json['version'] as String);

Map<String, dynamic> _$VersionGet$ResponseToJson(
  VersionGet$Response instance,
) => <String, dynamic>{'version': instance.version};

SwapSubmarineIdInvoicePost$Response
_$SwapSubmarineIdInvoicePost$ResponseFromJson(Map<String, dynamic> json) =>
    SwapSubmarineIdInvoicePost$Response(
      bip21: json['bip21'] as String,
      expectedAmount: (json['expectedAmount'] as num).toDouble(),
      acceptZeroConf: json['acceptZeroConf'] as bool,
    );

Map<String, dynamic> _$SwapSubmarineIdInvoicePost$ResponseToJson(
  SwapSubmarineIdInvoicePost$Response instance,
) => <String, dynamic>{
  'bip21': instance.bip21,
  'expectedAmount': instance.expectedAmount,
  'acceptZeroConf': instance.acceptZeroConf,
};

SwapSubmarineIdInvoiceAmountGet$Response
_$SwapSubmarineIdInvoiceAmountGet$ResponseFromJson(Map<String, dynamic> json) =>
    SwapSubmarineIdInvoiceAmountGet$Response(
      invoiceAmount: (json['invoiceAmount'] as num).toDouble(),
    );

Map<String, dynamic> _$SwapSubmarineIdInvoiceAmountGet$ResponseToJson(
  SwapSubmarineIdInvoiceAmountGet$Response instance,
) => <String, dynamic>{'invoiceAmount': instance.invoiceAmount};

SwapSubmarineIdRefundGet$Response _$SwapSubmarineIdRefundGet$ResponseFromJson(
  Map<String, dynamic> json,
) => SwapSubmarineIdRefundGet$Response(signature: json['signature'] as String);

Map<String, dynamic> _$SwapSubmarineIdRefundGet$ResponseToJson(
  SwapSubmarineIdRefundGet$Response instance,
) => <String, dynamic>{'signature': instance.signature};

SwapChainIdRefundGet$Response _$SwapChainIdRefundGet$ResponseFromJson(
  Map<String, dynamic> json,
) => SwapChainIdRefundGet$Response(signature: json['signature'] as String);

Map<String, dynamic> _$SwapChainIdRefundGet$ResponseToJson(
  SwapChainIdRefundGet$Response instance,
) => <String, dynamic>{'signature': instance.signature};

LightningCurrencyBolt12ReceivingGet$Response
_$LightningCurrencyBolt12ReceivingGet$ResponseFromJson(
  Map<String, dynamic> json,
) => LightningCurrencyBolt12ReceivingGet$Response(
  minCltv: (json['minCltv'] as num).toInt(),
);

Map<String, dynamic> _$LightningCurrencyBolt12ReceivingGet$ResponseToJson(
  LightningCurrencyBolt12ReceivingGet$Response instance,
) => <String, dynamic>{'minCltv': instance.minCltv};

LightningCurrencyBolt12FetchPost$Response
_$LightningCurrencyBolt12FetchPost$ResponseFromJson(
  Map<String, dynamic> json,
) => LightningCurrencyBolt12FetchPost$Response(
  invoice: json['invoice'] as String,
  magicRoutingHint: json['magicRoutingHint'] == null
      ? null
      : ReverseBip21.fromJson(json['magicRoutingHint'] as Map<String, dynamic>),
);

Map<String, dynamic> _$LightningCurrencyBolt12FetchPost$ResponseToJson(
  LightningCurrencyBolt12FetchPost$Response instance,
) => <String, dynamic>{
  'invoice': instance.invoice,
  'magicRoutingHint': ?instance.magicRoutingHint?.toJson(),
};

ChainCurrencyFeeGet$Response _$ChainCurrencyFeeGet$ResponseFromJson(
  Map<String, dynamic> json,
) => ChainCurrencyFeeGet$Response(fee: (json['fee'] as num).toDouble());

Map<String, dynamic> _$ChainCurrencyFeeGet$ResponseToJson(
  ChainCurrencyFeeGet$Response instance,
) => <String, dynamic>{'fee': instance.fee};

ChainCurrencyHeightGet$Response _$ChainCurrencyHeightGet$ResponseFromJson(
  Map<String, dynamic> json,
) =>
    ChainCurrencyHeightGet$Response(height: (json['height'] as num).toDouble());

Map<String, dynamic> _$ChainCurrencyHeightGet$ResponseToJson(
  ChainCurrencyHeightGet$Response instance,
) => <String, dynamic>{'height': instance.height};

ChainCurrencyTransactionIdGet$Response
_$ChainCurrencyTransactionIdGet$ResponseFromJson(Map<String, dynamic> json) =>
    ChainCurrencyTransactionIdGet$Response(
      hex: json['hex'] as String,
      confirmations: (json['confirmations'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ChainCurrencyTransactionIdGet$ResponseToJson(
  ChainCurrencyTransactionIdGet$Response instance,
) => <String, dynamic>{
  'hex': instance.hex,
  'confirmations': ?instance.confirmations,
};

ChainCurrencyTransactionPost$Response
_$ChainCurrencyTransactionPost$ResponseFromJson(Map<String, dynamic> json) =>
    ChainCurrencyTransactionPost$Response(id: json['id'] as String);

Map<String, dynamic> _$ChainCurrencyTransactionPost$ResponseToJson(
  ChainCurrencyTransactionPost$Response instance,
) => <String, dynamic>{'id': instance.id};

QuoteCurrencyEncodePost$Response _$QuoteCurrencyEncodePost$ResponseFromJson(
  Map<String, dynamic> json,
) => QuoteCurrencyEncodePost$Response(
  calls:
      (json['calls'] as List<dynamic>?)
          ?.map((e) => Call.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$QuoteCurrencyEncodePost$ResponseToJson(
  QuoteCurrencyEncodePost$Response instance,
) => <String, dynamic>{'calls': instance.calls.map((e) => e.toJson()).toList()};

CommitmentCurrencyRefundPost$Response
_$CommitmentCurrencyRefundPost$ResponseFromJson(Map<String, dynamic> json) =>
    CommitmentCurrencyRefundPost$Response(
      signature: json['signature'] as String,
    );

Map<String, dynamic> _$CommitmentCurrencyRefundPost$ResponseToJson(
  CommitmentCurrencyRefundPost$Response instance,
) => <String, dynamic>{'signature': instance.signature};

ReferralGet$Response _$ReferralGet$ResponseFromJson(
  Map<String, dynamic> json,
) => ReferralGet$Response(id: json['id'] as String);

Map<String, dynamic> _$ReferralGet$ResponseToJson(
  ReferralGet$Response instance,
) => <String, dynamic>{'id': instance.id};

SubmarinePair$Limits _$SubmarinePair$LimitsFromJson(
  Map<String, dynamic> json,
) => SubmarinePair$Limits(
  minimal: (json['minimal'] as num).toDouble(),
  minimalBatched: (json['minimalBatched'] as num?)?.toDouble(),
  maximal: (json['maximal'] as num).toDouble(),
  maximalZeroConf: (json['maximalZeroConf'] as num).toDouble(),
);

Map<String, dynamic> _$SubmarinePair$LimitsToJson(
  SubmarinePair$Limits instance,
) => <String, dynamic>{
  'minimal': instance.minimal,
  'minimalBatched': ?instance.minimalBatched,
  'maximal': instance.maximal,
  'maximalZeroConf': instance.maximalZeroConf,
};

SubmarinePair$Fees _$SubmarinePair$FeesFromJson(Map<String, dynamic> json) =>
    SubmarinePair$Fees(
      percentage: (json['percentage'] as num).toDouble(),
      minerFees: (json['minerFees'] as num).toDouble(),
    );

Map<String, dynamic> _$SubmarinePair$FeesToJson(SubmarinePair$Fees instance) =>
    <String, dynamic>{
      'percentage': instance.percentage,
      'minerFees': instance.minerFees,
    };

ReversePair$Limits _$ReversePair$LimitsFromJson(Map<String, dynamic> json) =>
    ReversePair$Limits(
      minimal: (json['minimal'] as num).toDouble(),
      maximal: (json['maximal'] as num).toDouble(),
    );

Map<String, dynamic> _$ReversePair$LimitsToJson(ReversePair$Limits instance) =>
    <String, dynamic>{'minimal': instance.minimal, 'maximal': instance.maximal};

ReversePair$Fees _$ReversePair$FeesFromJson(Map<String, dynamic> json) =>
    ReversePair$Fees(
      percentage: (json['percentage'] as num).toDouble(),
      minerFees: ReversePair$Fees$MinerFees.fromJson(
        json['minerFees'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ReversePair$FeesToJson(ReversePair$Fees instance) =>
    <String, dynamic>{
      'percentage': instance.percentage,
      'minerFees': instance.minerFees.toJson(),
    };

ChainPair$Limits _$ChainPair$LimitsFromJson(Map<String, dynamic> json) =>
    ChainPair$Limits(
      minimal: (json['minimal'] as num).toDouble(),
      maximal: (json['maximal'] as num).toDouble(),
      maximalZeroConf: (json['maximalZeroConf'] as num).toDouble(),
    );

Map<String, dynamic> _$ChainPair$LimitsToJson(ChainPair$Limits instance) =>
    <String, dynamic>{
      'minimal': instance.minimal,
      'maximal': instance.maximal,
      'maximalZeroConf': instance.maximalZeroConf,
    };

ChainPair$Fees _$ChainPair$FeesFromJson(Map<String, dynamic> json) =>
    ChainPair$Fees(
      percentage: (json['percentage'] as num).toDouble(),
      minerFees: ChainPair$Fees$MinerFees.fromJson(
        json['minerFees'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ChainPair$FeesToJson(ChainPair$Fees instance) =>
    <String, dynamic>{
      'percentage': instance.percentage,
      'minerFees': instance.minerFees.toJson(),
    };

ChainSwapTransaction$Transaction _$ChainSwapTransaction$TransactionFromJson(
  Map<String, dynamic> json,
) => ChainSwapTransaction$Transaction(
  id: json['id'] as String,
  hex: json['hex'] as String?,
);

Map<String, dynamic> _$ChainSwapTransaction$TransactionToJson(
  ChainSwapTransaction$Transaction instance,
) => <String, dynamic>{'id': instance.id, 'hex': ?instance.hex};

ChainSwapTransaction$Timeout _$ChainSwapTransaction$TimeoutFromJson(
  Map<String, dynamic> json,
) => ChainSwapTransaction$Timeout(
  blockHeight: (json['blockHeight'] as num).toDouble(),
  eta: (json['eta'] as num?)?.toDouble(),
);

Map<String, dynamic> _$ChainSwapTransaction$TimeoutToJson(
  ChainSwapTransaction$Timeout instance,
) => <String, dynamic>{
  'blockHeight': instance.blockHeight,
  'eta': ?instance.eta,
};

ChainSwapSigningRequest$ToSign _$ChainSwapSigningRequest$ToSignFromJson(
  Map<String, dynamic> json,
) => ChainSwapSigningRequest$ToSign(
  pubNonce: json['pubNonce'] as String,
  transaction: json['transaction'] as String,
  index: (json['index'] as num).toDouble(),
);

Map<String, dynamic> _$ChainSwapSigningRequest$ToSignToJson(
  ChainSwapSigningRequest$ToSign instance,
) => <String, dynamic>{
  'pubNonce': instance.pubNonce,
  'transaction': instance.transaction,
  'index': instance.index,
};

SwapStatus$Transaction _$SwapStatus$TransactionFromJson(
  Map<String, dynamic> json,
) => SwapStatus$Transaction(
  id: json['id'] as String?,
  hex: json['hex'] as String?,
);

Map<String, dynamic> _$SwapStatus$TransactionToJson(
  SwapStatus$Transaction instance,
) => <String, dynamic>{'id': ?instance.id, 'hex': ?instance.hex};

Contracts$Network _$Contracts$NetworkFromJson(Map<String, dynamic> json) =>
    Contracts$Network(
      chainId: (json['chainId'] as num).toDouble(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$Contracts$NetworkToJson(Contracts$Network instance) =>
    <String, dynamic>{'chainId': instance.chainId, 'name': instance.name};

Contracts$SwapContracts _$Contracts$SwapContractsFromJson(
  Map<String, dynamic> json,
) => Contracts$SwapContracts(
  etherSwap: json['EtherSwap'] as String,
  eRC20Swap: json['ERC20Swap'] as String,
);

Map<String, dynamic> _$Contracts$SwapContractsToJson(
  Contracts$SwapContracts instance,
) => <String, dynamic>{
  'EtherSwap': instance.etherSwap,
  'ERC20Swap': instance.eRC20Swap,
};

ReversePair$Fees$MinerFees _$ReversePair$Fees$MinerFeesFromJson(
  Map<String, dynamic> json,
) => ReversePair$Fees$MinerFees(
  lockup: (json['lockup'] as num).toDouble(),
  claim: (json['claim'] as num).toDouble(),
);

Map<String, dynamic> _$ReversePair$Fees$MinerFeesToJson(
  ReversePair$Fees$MinerFees instance,
) => <String, dynamic>{'lockup': instance.lockup, 'claim': instance.claim};

ChainPair$Fees$MinerFees _$ChainPair$Fees$MinerFeesFromJson(
  Map<String, dynamic> json,
) => ChainPair$Fees$MinerFees(
  server: (json['server'] as num).toDouble(),
  user: ChainPair$Fees$MinerFees$User.fromJson(
    json['user'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$ChainPair$Fees$MinerFeesToJson(
  ChainPair$Fees$MinerFees instance,
) => <String, dynamic>{
  'server': instance.server,
  'user': instance.user.toJson(),
};

ChainPair$Fees$MinerFees$User _$ChainPair$Fees$MinerFees$UserFromJson(
  Map<String, dynamic> json,
) => ChainPair$Fees$MinerFees$User(
  claim: (json['claim'] as num).toDouble(),
  lockup: (json['lockup'] as num).toDouble(),
);

Map<String, dynamic> _$ChainPair$Fees$MinerFees$UserToJson(
  ChainPair$Fees$MinerFees$User instance,
) => <String, dynamic>{'claim': instance.claim, 'lockup': instance.lockup};
