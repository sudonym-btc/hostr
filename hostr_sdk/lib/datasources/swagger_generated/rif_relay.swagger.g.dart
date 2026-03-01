// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rif_relay.swagger.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PingResponse _$PingResponseFromJson(Map<String, dynamic> json) => PingResponse(
  relayWorkerAddress: json['relayWorkerAddress'],
  relayManagerAddress: json['relayManagerAddress'],
  relayHubAddress: json['relayHubAddress'],
  minGasPrice: json['minGasPrice'] as String?,
  chainId: json['chainId'] as String?,
  networkId: json['networkId'] as String?,
  ready: json['ready'] as bool?,
  version: json['version'] as String?,
);

Map<String, dynamic> _$PingResponseToJson(PingResponse instance) =>
    <String, dynamic>{
      'relayWorkerAddress': ?instance.relayWorkerAddress,
      'relayManagerAddress': ?instance.relayManagerAddress,
      'relayHubAddress': ?instance.relayHubAddress,
      'minGasPrice': ?instance.minGasPrice,
      'chainId': ?instance.chainId,
      'networkId': ?instance.networkId,
      'ready': ?instance.ready,
      'version': ?instance.version,
    };

RelayTransactionRequest _$RelayTransactionRequestFromJson(
  Map<String, dynamic> json,
) => RelayTransactionRequest(
  relayRequest: json['relayRequest'] == null
      ? null
      : RelayRequest.fromJson(json['relayRequest'] as Map<String, dynamic>),
  metadata: json['metadata'] == null
      ? null
      : RelayMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RelayTransactionRequestToJson(
  RelayTransactionRequest instance,
) => <String, dynamic>{
  'relayRequest': ?instance.relayRequest?.toJson(),
  'metadata': ?instance.metadata?.toJson(),
};

RelayRequest _$RelayRequestFromJson(Map<String, dynamic> json) => RelayRequest(
  request: json['request'] == null
      ? null
      : ForwardRequest.fromJson(json['request'] as Map<String, dynamic>),
  relayData: json['relayData'] == null
      ? null
      : RelayData.fromJson(json['relayData'] as Map<String, dynamic>),
);

Map<String, dynamic> _$RelayRequestToJson(RelayRequest instance) =>
    <String, dynamic>{
      'request': ?instance.request?.toJson(),
      'relayData': ?instance.relayData?.toJson(),
    };

ForwardRequest _$ForwardRequestFromJson(Map<String, dynamic> json) =>
    ForwardRequest(
      relayHub: json['relayHub'],
      from: json['from'],
      to: json['to'],
      tokenContract: json['tokenContract'],
      value: json['value'] as String?,
      gas: json['gas'] as String?,
      nonce: json['nonce'] as String?,
      tokenAmount: json['tokenAmount'] as String?,
      tokenGas: json['tokenGas'] as String?,
      data: json['data'] as String?,
    );

Map<String, dynamic> _$ForwardRequestToJson(ForwardRequest instance) =>
    <String, dynamic>{
      'relayHub': ?instance.relayHub,
      'from': ?instance.from,
      'to': ?instance.to,
      'tokenContract': ?instance.tokenContract,
      'value': ?instance.value,
      'gas': ?instance.gas,
      'nonce': ?instance.nonce,
      'tokenAmount': ?instance.tokenAmount,
      'tokenGas': ?instance.tokenGas,
      'data': ?instance.data,
    };

DeployTransactionRequest _$DeployTransactionRequestFromJson(
  Map<String, dynamic> json,
) => DeployTransactionRequest(
  request: json['request'] == null
      ? null
      : DeployRequestStruct.fromJson(json['request'] as Map<String, dynamic>),
  relayData: json['relayData'] == null
      ? null
      : RelayData.fromJson(json['relayData'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DeployTransactionRequestToJson(
  DeployTransactionRequest instance,
) => <String, dynamic>{
  'request': ?instance.request?.toJson(),
  'relayData': ?instance.relayData?.toJson(),
};

DeployRequestStruct _$DeployRequestStructFromJson(Map<String, dynamic> json) =>
    DeployRequestStruct(
      relayHub: json['relayHub'],
      from: json['from'],
      to: json['to'],
      tokenContract: json['tokenContract'],
      recoverer: json['recoverer'],
      value: json['value'] as String?,
      nonce: json['nonce'] as String?,
      tokenAmount: json['tokenAmount'] as String?,
      tokenGas: json['tokenGas'] as String?,
      index: json['index'] as String?,
      data: json['data'] as String?,
    );

Map<String, dynamic> _$DeployRequestStructToJson(
  DeployRequestStruct instance,
) => <String, dynamic>{
  'relayHub': ?instance.relayHub,
  'from': ?instance.from,
  'to': ?instance.to,
  'tokenContract': ?instance.tokenContract,
  'recoverer': ?instance.recoverer,
  'value': ?instance.value,
  'nonce': ?instance.nonce,
  'tokenAmount': ?instance.tokenAmount,
  'tokenGas': ?instance.tokenGas,
  'index': ?instance.index,
  'data': ?instance.data,
};

RelayData _$RelayDataFromJson(Map<String, dynamic> json) => RelayData(
  gasPrice: json['gasPrice'] as String?,
  feesReceiver: json['feesReceiver'],
  callForwarder: json['callForwarder'],
  callVerifier: json['callVerifier'],
);

Map<String, dynamic> _$RelayDataToJson(RelayData instance) => <String, dynamic>{
  'gasPrice': ?instance.gasPrice,
  'feesReceiver': ?instance.feesReceiver,
  'callForwarder': ?instance.callForwarder,
  'callVerifier': ?instance.callVerifier,
};

RelayMetadata _$RelayMetadataFromJson(Map<String, dynamic> json) =>
    RelayMetadata(
      relayHubAddress: json['relayHubAddress'],
      relayMaxNonce: (json['relayMaxNonce'] as num?)?.toDouble(),
      signature: json['signature'] as String?,
    );

Map<String, dynamic> _$RelayMetadataToJson(RelayMetadata instance) =>
    <String, dynamic>{
      'relayHubAddress': ?instance.relayHubAddress,
      'relayMaxNonce': ?instance.relayMaxNonce,
      'signature': ?instance.signature,
    };

RelayPost$Response _$RelayPost$ResponseFromJson(Map<String, dynamic> json) =>
    RelayPost$Response(
      signedTx: json['signedTx'],
      transactionHash: json['txHash'],
    );

Map<String, dynamic> _$RelayPost$ResponseToJson(RelayPost$Response instance) =>
    <String, dynamic>{
      'signedTx': ?instance.signedTx,
      'txHash': ?instance.transactionHash,
    };

EstimatePost$Response _$EstimatePost$ResponseFromJson(
  Map<String, dynamic> json,
) => EstimatePost$Response(
  gasPrice: json['gasPrice'] as String?,
  estimation: json['estimation'] as String?,
  requiredTokenAmount: json['requiredTokenAmount'] as String?,
  requiredNativeAmount: json['requiredNativeAmount'] as String?,
  exchangeRate: json['exchangeRate'] as String?,
);

Map<String, dynamic> _$EstimatePost$ResponseToJson(
  EstimatePost$Response instance,
) => <String, dynamic>{
  'gasPrice': ?instance.gasPrice,
  'estimation': ?instance.estimation,
  'requiredTokenAmount': ?instance.requiredTokenAmount,
  'requiredNativeAmount': ?instance.requiredNativeAmount,
  'exchangeRate': ?instance.exchangeRate,
};

VerifiersGet$Response _$VerifiersGet$ResponseFromJson(
  Map<String, dynamic> json,
) => VerifiersGet$Response(
  trustedVerifiers:
      (json['trustedVerifiers'] as List<dynamic>?)
          ?.map((e) => e as Object)
          .toList() ??
      [],
);

Map<String, dynamic> _$VerifiersGet$ResponseToJson(
  VerifiersGet$Response instance,
) => <String, dynamic>{'trustedVerifiers': ?instance.trustedVerifiers};
