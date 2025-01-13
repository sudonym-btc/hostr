// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boltz.swagger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Contracts _$ContractsFromJson(Map<String, dynamic> json) => Contracts(
      network:
          Contracts$Network.fromJson(json['network'] as Map<String, dynamic>),
      swapContracts: Contracts$SwapContracts.fromJson(
          json['swapContracts'] as Map<String, dynamic>),
      tokens: json['tokens'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$ContractsToJson(Contracts instance) => <String, dynamic>{
      'network': instance.network.toJson(),
      'swapContracts': instance.swapContracts.toJson(),
      'tokens': instance.tokens,
    };

NodeInfo _$NodeInfoFromJson(Map<String, dynamic> json) => NodeInfo(
      publicKey: json['publicKey'] as String,
      uris:
          (json['uris'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              [],
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

ErrorResponse _$ErrorResponseFromJson(Map<String, dynamic> json) =>
    ErrorResponse(
      error: json['error'] as String,
    );

Map<String, dynamic> _$ErrorResponseToJson(ErrorResponse instance) =>
    <String, dynamic>{
      'error': instance.error,
    };

SwapTreeLeaf _$SwapTreeLeafFromJson(Map<String, dynamic> json) => SwapTreeLeaf(
      version: (json['version'] as num).toDouble(),
      output: json['output'] as String,
    );

Map<String, dynamic> _$SwapTreeLeafToJson(SwapTreeLeaf instance) =>
    <String, dynamic>{
      'version': instance.version,
      'output': instance.output,
    };

SwapTree _$SwapTreeFromJson(Map<String, dynamic> json) => SwapTree(
      claimLeaf:
          SwapTreeLeaf.fromJson(json['claimLeaf'] as Map<String, dynamic>),
      refundLeaf:
          SwapTreeLeaf.fromJson(json['refundLeaf'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SwapTreeToJson(SwapTree instance) => <String, dynamic>{
      'claimLeaf': instance.claimLeaf.toJson(),
      'refundLeaf': instance.refundLeaf.toJson(),
    };

SubmarinePair _$SubmarinePairFromJson(Map<String, dynamic> json) =>
    SubmarinePair(
      hash: json['hash'] as String,
      rate: (json['rate'] as num).toDouble(),
      limits:
          SubmarinePair$Limits.fromJson(json['limits'] as Map<String, dynamic>),
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
      status: (json['status'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$WebhookDataToJson(WebhookData instance) =>
    <String, dynamic>{
      'url': instance.url,
      'hashSwapId': instance.hashSwapId,
      'status': instance.status,
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
      webhook: json['webhook'] == null
          ? null
          : WebhookData.fromJson(json['webhook'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SubmarineRequestToJson(SubmarineRequest instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'invoice': instance.invoice,
      'preimageHash': instance.preimageHash,
      'refundPublicKey': instance.refundPublicKey,
      'pairHash': instance.pairHash,
      'referralId': instance.referralId,
      'webhook': instance.webhook?.toJson(),
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
      timeoutBlockHeight: (json['timeoutBlockHeight'] as num).toDouble(),
      acceptZeroConf: json['acceptZeroConf'] as bool?,
      expectedAmount: (json['expectedAmount'] as num).toDouble(),
      blindingKey: json['blindingKey'] as String?,
      referralId: json['referralId'] as String?,
    );

Map<String, dynamic> _$SubmarineResponseToJson(SubmarineResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bip21': instance.bip21,
      'address': instance.address,
      'swapTree': instance.swapTree?.toJson(),
      'claimPublicKey': instance.claimPublicKey,
      'timeoutBlockHeight': instance.timeoutBlockHeight,
      'acceptZeroConf': instance.acceptZeroConf,
      'expectedAmount': instance.expectedAmount,
      'blindingKey': instance.blindingKey,
      'referralId': instance.referralId,
    };

SubmarineTransaction _$SubmarineTransactionFromJson(
        Map<String, dynamic> json) =>
    SubmarineTransaction(
      id: json['id'] as String,
      hex: json['hex'] as String?,
      timeoutBlockHeight: (json['timeoutBlockHeight'] as num).toDouble(),
      timeoutEta: (json['timeoutEta'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$SubmarineTransactionToJson(
        SubmarineTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hex': instance.hex,
      'timeoutBlockHeight': instance.timeoutBlockHeight,
      'timeoutEta': instance.timeoutEta,
    };

SubmarinePreimage _$SubmarinePreimageFromJson(Map<String, dynamic> json) =>
    SubmarinePreimage(
      preimage: json['preimage'] as String,
    );

Map<String, dynamic> _$SubmarinePreimageToJson(SubmarinePreimage instance) =>
    <String, dynamic>{
      'preimage': instance.preimage,
    };

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

SubmarineClaimDetails _$SubmarineClaimDetailsFromJson(
        Map<String, dynamic> json) =>
    SubmarineClaimDetails(
      preimage: json['preimage'] as String,
      pubNonce: json['pubNonce'] as String,
      publicKey: json['publicKey'] as String,
      transactionHash: json['transactionHash'] as String,
    );

Map<String, dynamic> _$SubmarineClaimDetailsToJson(
        SubmarineClaimDetails instance) =>
    <String, dynamic>{
      'preimage': instance.preimage,
      'pubNonce': instance.pubNonce,
      'publicKey': instance.publicKey,
      'transactionHash': instance.transactionHash,
    };

ReversePair _$ReversePairFromJson(Map<String, dynamic> json) => ReversePair(
      hash: json['hash'] as String,
      rate: (json['rate'] as num).toDouble(),
      limits:
          ReversePair$Limits.fromJson(json['limits'] as Map<String, dynamic>),
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
    );

Map<String, dynamic> _$ReverseRequestToJson(ReverseRequest instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'preimageHash': instance.preimageHash,
      'claimPublicKey': instance.claimPublicKey,
      'claimAddress': instance.claimAddress,
      'invoiceAmount': instance.invoiceAmount,
      'onchainAmount': instance.onchainAmount,
      'pairHash': instance.pairHash,
      'referralId': instance.referralId,
      'address': instance.address,
      'addressSignature': instance.addressSignature,
      'claimCovenant': instance.claimCovenant,
      'description': instance.description,
      'descriptionHash': instance.descriptionHash,
      'invoiceExpiry': instance.invoiceExpiry,
      'webhook': instance.webhook?.toJson(),
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
      timeoutBlockHeight: (json['timeoutBlockHeight'] as num).toDouble(),
      onchainAmount: (json['onchainAmount'] as num?)?.toDouble(),
      blindingKey: json['blindingKey'] as String?,
      referralId: json['referralId'] as String?,
    );

Map<String, dynamic> _$ReverseResponseToJson(ReverseResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'invoice': instance.invoice,
      'swapTree': instance.swapTree?.toJson(),
      'lockupAddress': instance.lockupAddress,
      'refundPublicKey': instance.refundPublicKey,
      'timeoutBlockHeight': instance.timeoutBlockHeight,
      'onchainAmount': instance.onchainAmount,
      'blindingKey': instance.blindingKey,
      'referralId': instance.referralId,
    };

ReverseTransaction _$ReverseTransactionFromJson(Map<String, dynamic> json) =>
    ReverseTransaction(
      id: json['id'] as String,
      hex: json['hex'] as String?,
      timeoutBlockHeight: (json['timeoutBlockHeight'] as num).toDouble(),
    );

Map<String, dynamic> _$ReverseTransactionToJson(ReverseTransaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hex': instance.hex,
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
        ReverseClaimRequest instance) =>
    <String, dynamic>{
      'preimage': instance.preimage,
      'pubNonce': instance.pubNonce,
      'transaction': instance.transaction,
      'index': instance.index,
    };

ReverseBip21 _$ReverseBip21FromJson(Map<String, dynamic> json) => ReverseBip21(
      bip21: json['bip21'] as String?,
      signature: json['signature'] as String,
    );

Map<String, dynamic> _$ReverseBip21ToJson(ReverseBip21 instance) =>
    <String, dynamic>{
      'bip21': instance.bip21,
      'signature': instance.signature,
    };

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
    );

Map<String, dynamic> _$ChainRequestToJson(ChainRequest instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'preimageHash': instance.preimageHash,
      'claimPublicKey': instance.claimPublicKey,
      'refundPublicKey': instance.refundPublicKey,
      'claimAddress': instance.claimAddress,
      'userLockAmount': instance.userLockAmount,
      'serverLockAmount': instance.serverLockAmount,
      'pairHash': instance.pairHash,
      'referralId': instance.referralId,
      'webhook': instance.webhook?.toJson(),
    };

ChainSwapData _$ChainSwapDataFromJson(Map<String, dynamic> json) =>
    ChainSwapData(
      swapTree: SwapTree.fromJson(json['swapTree'] as Map<String, dynamic>),
      lockupAddress: json['lockupAddress'] as String?,
      serverPublicKey: json['serverPublicKey'] as String?,
      timeoutBlockHeight: (json['timeoutBlockHeight'] as num).toDouble(),
      amount: (json['amount'] as num).toDouble(),
      blindingKey: json['blindingKey'] as String?,
      refundAddress: json['refundAddress'] as String?,
      bip21: json['bip21'] as String?,
    );

Map<String, dynamic> _$ChainSwapDataToJson(ChainSwapData instance) =>
    <String, dynamic>{
      'swapTree': instance.swapTree.toJson(),
      'lockupAddress': instance.lockupAddress,
      'serverPublicKey': instance.serverPublicKey,
      'timeoutBlockHeight': instance.timeoutBlockHeight,
      'amount': instance.amount,
      'blindingKey': instance.blindingKey,
      'refundAddress': instance.refundAddress,
      'bip21': instance.bip21,
    };

ChainResponse _$ChainResponseFromJson(Map<String, dynamic> json) =>
    ChainResponse(
      id: json['id'] as String,
      referralId: json['referralId'] as String?,
      claimDetails:
          ChainSwapData.fromJson(json['claimDetails'] as Map<String, dynamic>),
      lockupDetails:
          ChainSwapData.fromJson(json['lockupDetails'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChainResponseToJson(ChainResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'referralId': instance.referralId,
      'claimDetails': instance.claimDetails.toJson(),
      'lockupDetails': instance.lockupDetails.toJson(),
    };

ChainSwapTransaction _$ChainSwapTransactionFromJson(
        Map<String, dynamic> json) =>
    ChainSwapTransaction(
      transaction: ChainSwapTransaction$Transaction.fromJson(
          json['transaction'] as Map<String, dynamic>),
      timeout: json['timeout'] == null
          ? null
          : ChainSwapTransaction$Timeout.fromJson(
              json['timeout'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChainSwapTransactionToJson(
        ChainSwapTransaction instance) =>
    <String, dynamic>{
      'transaction': instance.transaction.toJson(),
      'timeout': instance.timeout?.toJson(),
    };

ChainSwapTransactions _$ChainSwapTransactionsFromJson(
        Map<String, dynamic> json) =>
    ChainSwapTransactions(
      userLock: json['userLock'] == null
          ? null
          : ChainSwapTransaction.fromJson(
              json['userLock'] as Map<String, dynamic>),
      serverLock: json['serverLock'] == null
          ? null
          : ChainSwapTransaction.fromJson(
              json['serverLock'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChainSwapTransactionsToJson(
        ChainSwapTransactions instance) =>
    <String, dynamic>{
      'userLock': instance.userLock?.toJson(),
      'serverLock': instance.serverLock?.toJson(),
    };

ChainSwapSigningDetails _$ChainSwapSigningDetailsFromJson(
        Map<String, dynamic> json) =>
    ChainSwapSigningDetails(
      pubNonce: json['pubNonce'] as String,
      publicKey: json['publicKey'] as String,
      transactionHash: json['transactionHash'] as String,
    );

Map<String, dynamic> _$ChainSwapSigningDetailsToJson(
        ChainSwapSigningDetails instance) =>
    <String, dynamic>{
      'pubNonce': instance.pubNonce,
      'publicKey': instance.publicKey,
      'transactionHash': instance.transactionHash,
    };

ChainSwapSigningRequest _$ChainSwapSigningRequestFromJson(
        Map<String, dynamic> json) =>
    ChainSwapSigningRequest(
      preimage: json['preimage'] as String?,
      signature: json['signature'] == null
          ? null
          : PartialSignature.fromJson(
              json['signature'] as Map<String, dynamic>),
      toSign: json['toSign'] == null
          ? null
          : ChainSwapSigningRequest$ToSign.fromJson(
              json['toSign'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChainSwapSigningRequestToJson(
        ChainSwapSigningRequest instance) =>
    <String, dynamic>{
      'preimage': instance.preimage,
      'signature': instance.signature?.toJson(),
      'toSign': instance.toSign?.toJson(),
    };

Quote _$QuoteFromJson(Map<String, dynamic> json) => Quote(
      amount: (json['amount'] as num).toDouble(),
    );

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
              json['transaction'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$SwapStatusToJson(SwapStatus instance) =>
    <String, dynamic>{
      'status': instance.status,
      'zeroConfRejected': instance.zeroConfRejected,
      'transaction': instance.transaction?.toJson(),
    };

ChainCurrencyTransactionPost$RequestBody
    _$ChainCurrencyTransactionPost$RequestBodyFromJson(
            Map<String, dynamic> json) =>
        ChainCurrencyTransactionPost$RequestBody(
          hex: json['hex'] as String,
        );

Map<String, dynamic> _$ChainCurrencyTransactionPost$RequestBodyToJson(
        ChainCurrencyTransactionPost$RequestBody instance) =>
    <String, dynamic>{
      'hex': instance.hex,
    };

LightningCurrencyBolt12FetchPost$RequestBody
    _$LightningCurrencyBolt12FetchPost$RequestBodyFromJson(
            Map<String, dynamic> json) =>
        LightningCurrencyBolt12FetchPost$RequestBody(
          offer: json['offer'] as String,
          amount: (json['amount'] as num).toDouble(),
        );

Map<String, dynamic> _$LightningCurrencyBolt12FetchPost$RequestBodyToJson(
        LightningCurrencyBolt12FetchPost$RequestBody instance) =>
    <String, dynamic>{
      'offer': instance.offer,
      'amount': instance.amount,
    };

SwapSubmarineIdInvoicePost$RequestBody
    _$SwapSubmarineIdInvoicePost$RequestBodyFromJson(
            Map<String, dynamic> json) =>
        SwapSubmarineIdInvoicePost$RequestBody(
          invoice: json['invoice'] as String,
          pairHash: json['pairHash'] as String?,
        );

Map<String, dynamic> _$SwapSubmarineIdInvoicePost$RequestBodyToJson(
        SwapSubmarineIdInvoicePost$RequestBody instance) =>
    <String, dynamic>{
      'invoice': instance.invoice,
      'pairHash': instance.pairHash,
    };

ChainCurrencyFeeGet$Response _$ChainCurrencyFeeGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    ChainCurrencyFeeGet$Response(
      fee: (json['fee'] as num).toDouble(),
    );

Map<String, dynamic> _$ChainCurrencyFeeGet$ResponseToJson(
        ChainCurrencyFeeGet$Response instance) =>
    <String, dynamic>{
      'fee': instance.fee,
    };

ChainCurrencyHeightGet$Response _$ChainCurrencyHeightGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    ChainCurrencyHeightGet$Response(
      height: (json['height'] as num).toDouble(),
    );

Map<String, dynamic> _$ChainCurrencyHeightGet$ResponseToJson(
        ChainCurrencyHeightGet$Response instance) =>
    <String, dynamic>{
      'height': instance.height,
    };

ChainCurrencyTransactionIdGet$Response
    _$ChainCurrencyTransactionIdGet$ResponseFromJson(
            Map<String, dynamic> json) =>
        ChainCurrencyTransactionIdGet$Response(
          hex: json['hex'] as String,
        );

Map<String, dynamic> _$ChainCurrencyTransactionIdGet$ResponseToJson(
        ChainCurrencyTransactionIdGet$Response instance) =>
    <String, dynamic>{
      'hex': instance.hex,
    };

ChainCurrencyTransactionPost$Response
    _$ChainCurrencyTransactionPost$ResponseFromJson(
            Map<String, dynamic> json) =>
        ChainCurrencyTransactionPost$Response(
          id: json['id'] as String,
        );

Map<String, dynamic> _$ChainCurrencyTransactionPost$ResponseToJson(
        ChainCurrencyTransactionPost$Response instance) =>
    <String, dynamic>{
      'id': instance.id,
    };

VersionGet$Response _$VersionGet$ResponseFromJson(Map<String, dynamic> json) =>
    VersionGet$Response(
      version: json['version'] as String,
    );

Map<String, dynamic> _$VersionGet$ResponseToJson(
        VersionGet$Response instance) =>
    <String, dynamic>{
      'version': instance.version,
    };

LightningCurrencyBolt12FetchPost$Response
    _$LightningCurrencyBolt12FetchPost$ResponseFromJson(
            Map<String, dynamic> json) =>
        LightningCurrencyBolt12FetchPost$Response(
          invoice: json['invoice'] as String,
        );

Map<String, dynamic> _$LightningCurrencyBolt12FetchPost$ResponseToJson(
        LightningCurrencyBolt12FetchPost$Response instance) =>
    <String, dynamic>{
      'invoice': instance.invoice,
    };

ReferralGet$Response _$ReferralGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    ReferralGet$Response(
      id: json['id'] as String,
    );

Map<String, dynamic> _$ReferralGet$ResponseToJson(
        ReferralGet$Response instance) =>
    <String, dynamic>{
      'id': instance.id,
    };

SwapSubmarineIdInvoicePost$Response
    _$SwapSubmarineIdInvoicePost$ResponseFromJson(Map<String, dynamic> json) =>
        SwapSubmarineIdInvoicePost$Response(
          bip21: json['bip21'] as String,
          expectedAmount: (json['expectedAmount'] as num).toDouble(),
          acceptZeroConf: json['acceptZeroConf'] as bool,
        );

Map<String, dynamic> _$SwapSubmarineIdInvoicePost$ResponseToJson(
        SwapSubmarineIdInvoicePost$Response instance) =>
    <String, dynamic>{
      'bip21': instance.bip21,
      'expectedAmount': instance.expectedAmount,
      'acceptZeroConf': instance.acceptZeroConf,
    };

SwapSubmarineIdInvoiceAmountGet$Response
    _$SwapSubmarineIdInvoiceAmountGet$ResponseFromJson(
            Map<String, dynamic> json) =>
        SwapSubmarineIdInvoiceAmountGet$Response(
          invoiceAmount: (json['invoiceAmount'] as num).toDouble(),
        );

Map<String, dynamic> _$SwapSubmarineIdInvoiceAmountGet$ResponseToJson(
        SwapSubmarineIdInvoiceAmountGet$Response instance) =>
    <String, dynamic>{
      'invoiceAmount': instance.invoiceAmount,
    };

SwapSubmarineIdRefundGet$Response _$SwapSubmarineIdRefundGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    SwapSubmarineIdRefundGet$Response(
      signature: json['signature'] as String,
    );

Map<String, dynamic> _$SwapSubmarineIdRefundGet$ResponseToJson(
        SwapSubmarineIdRefundGet$Response instance) =>
    <String, dynamic>{
      'signature': instance.signature,
    };

SwapChainIdRefundGet$Response _$SwapChainIdRefundGet$ResponseFromJson(
        Map<String, dynamic> json) =>
    SwapChainIdRefundGet$Response(
      signature: json['signature'] as String,
    );

Map<String, dynamic> _$SwapChainIdRefundGet$ResponseToJson(
        SwapChainIdRefundGet$Response instance) =>
    <String, dynamic>{
      'signature': instance.signature,
    };

Contracts$Network _$Contracts$NetworkFromJson(Map<String, dynamic> json) =>
    Contracts$Network(
      chainId: (json['chainId'] as num).toDouble(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$Contracts$NetworkToJson(Contracts$Network instance) =>
    <String, dynamic>{
      'chainId': instance.chainId,
      'name': instance.name,
    };

Contracts$SwapContracts _$Contracts$SwapContractsFromJson(
        Map<String, dynamic> json) =>
    Contracts$SwapContracts(
      etherSwap: json['EtherSwap'] as String?,
      eRC20Swap: json['ERC20Swap'] as String?,
    );

Map<String, dynamic> _$Contracts$SwapContractsToJson(
        Contracts$SwapContracts instance) =>
    <String, dynamic>{
      'EtherSwap': instance.etherSwap,
      'ERC20Swap': instance.eRC20Swap,
    };

SubmarinePair$Limits _$SubmarinePair$LimitsFromJson(
        Map<String, dynamic> json) =>
    SubmarinePair$Limits(
      minimal: (json['minimal'] as num).toDouble(),
      maximal: (json['maximal'] as num).toDouble(),
      maximalZeroConf: (json['maximalZeroConf'] as num).toDouble(),
    );

Map<String, dynamic> _$SubmarinePair$LimitsToJson(
        SubmarinePair$Limits instance) =>
    <String, dynamic>{
      'minimal': instance.minimal,
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
    <String, dynamic>{
      'minimal': instance.minimal,
      'maximal': instance.maximal,
    };

ReversePair$Fees _$ReversePair$FeesFromJson(Map<String, dynamic> json) =>
    ReversePair$Fees(
      percentage: (json['percentage'] as num).toDouble(),
      minerFees: ReversePair$Fees$MinerFees.fromJson(
          json['minerFees'] as Map<String, dynamic>),
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
    );

Map<String, dynamic> _$ChainPair$LimitsToJson(ChainPair$Limits instance) =>
    <String, dynamic>{
      'minimal': instance.minimal,
      'maximal': instance.maximal,
    };

ChainPair$Fees _$ChainPair$FeesFromJson(Map<String, dynamic> json) =>
    ChainPair$Fees(
      percentage: (json['percentage'] as num).toDouble(),
      minerFees: ChainPair$Fees$MinerFees.fromJson(
          json['minerFees'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ChainPair$FeesToJson(ChainPair$Fees instance) =>
    <String, dynamic>{
      'percentage': instance.percentage,
      'minerFees': instance.minerFees.toJson(),
    };

ChainSwapTransaction$Transaction _$ChainSwapTransaction$TransactionFromJson(
        Map<String, dynamic> json) =>
    ChainSwapTransaction$Transaction(
      id: json['id'] as String,
      hex: json['hex'] as String?,
    );

Map<String, dynamic> _$ChainSwapTransaction$TransactionToJson(
        ChainSwapTransaction$Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hex': instance.hex,
    };

ChainSwapTransaction$Timeout _$ChainSwapTransaction$TimeoutFromJson(
        Map<String, dynamic> json) =>
    ChainSwapTransaction$Timeout(
      blockHeight: (json['blockHeight'] as num).toDouble(),
      eta: (json['eta'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ChainSwapTransaction$TimeoutToJson(
        ChainSwapTransaction$Timeout instance) =>
    <String, dynamic>{
      'blockHeight': instance.blockHeight,
      'eta': instance.eta,
    };

ChainSwapSigningRequest$ToSign _$ChainSwapSigningRequest$ToSignFromJson(
        Map<String, dynamic> json) =>
    ChainSwapSigningRequest$ToSign(
      pubNonce: json['pubNonce'] as String,
      transaction: json['transaction'] as String,
      index: (json['index'] as num).toDouble(),
    );

Map<String, dynamic> _$ChainSwapSigningRequest$ToSignToJson(
        ChainSwapSigningRequest$ToSign instance) =>
    <String, dynamic>{
      'pubNonce': instance.pubNonce,
      'transaction': instance.transaction,
      'index': instance.index,
    };

SwapStatus$Transaction _$SwapStatus$TransactionFromJson(
        Map<String, dynamic> json) =>
    SwapStatus$Transaction(
      id: json['id'] as String?,
      hex: json['hex'] as String?,
    );

Map<String, dynamic> _$SwapStatus$TransactionToJson(
        SwapStatus$Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'hex': instance.hex,
    };

ReversePair$Fees$MinerFees _$ReversePair$Fees$MinerFeesFromJson(
        Map<String, dynamic> json) =>
    ReversePair$Fees$MinerFees(
      lockup: (json['lockup'] as num).toDouble(),
      claim: (json['claim'] as num).toDouble(),
    );

Map<String, dynamic> _$ReversePair$Fees$MinerFeesToJson(
        ReversePair$Fees$MinerFees instance) =>
    <String, dynamic>{
      'lockup': instance.lockup,
      'claim': instance.claim,
    };

ChainPair$Fees$MinerFees _$ChainPair$Fees$MinerFeesFromJson(
        Map<String, dynamic> json) =>
    ChainPair$Fees$MinerFees(
      lockup: (json['lockup'] as num).toDouble(),
      claim: (json['claim'] as num).toDouble(),
    );

Map<String, dynamic> _$ChainPair$Fees$MinerFeesToJson(
        ChainPair$Fees$MinerFees instance) =>
    <String, dynamic>{
      'lockup': instance.lockup,
      'claim': instance.claim,
    };
