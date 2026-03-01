// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element_parameter

import 'package:json_annotation/json_annotation.dart';
import 'package:json_annotation/json_annotation.dart' as json;
import 'package:collection/collection.dart';
import 'dart:convert';

import 'package:chopper/chopper.dart';

import 'client_mapping.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/http.dart' show MultipartFile;
import 'package:chopper/chopper.dart' as chopper;
import 'rif_relay.metadata.swagger.dart';

part 'rif_relay.swagger.chopper.dart';
part 'rif_relay.swagger.g.dart';

// **************************************************************************
// SwaggerChopperGenerator
// **************************************************************************

@ChopperApi()
abstract class RifRelay extends ChopperService {
  static RifRelay create({
    ChopperClient? client,
    http.Client? httpClient,
    Authenticator? authenticator,
    ErrorConverter? errorConverter,
    Converter? converter,
    Uri? baseUrl,
    List<Interceptor>? interceptors,
  }) {
    if (client != null) {
      return _$RifRelay(client);
    }

    final newClient = ChopperClient(
      services: [_$RifRelay()],
      converter: converter ?? $JsonSerializableConverter(),
      interceptors: interceptors ?? [],
      client: httpClient,
      authenticator: authenticator,
      errorConverter: errorConverter,
      baseUrl: baseUrl ?? Uri.parse('http://'),
    );
    return _$RifRelay(newClient);
  }

  ///It retrieves server configuration addresses and some general data.
  Future<chopper.Response<PingResponse>> chainInfoGet() {
    generatedMapping.putIfAbsent(
      PingResponse,
      () => PingResponse.fromJsonFactory,
    );

    return _chainInfoGet();
  }

  ///It retrieves server configuration addresses and some general data.
  @GET(path: '/chain-info')
  Future<chopper.Response<PingResponse>> _chainInfoGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'It displays addresses used by the server, as well as chain information, status and version.',
      summary:
          'It retrieves server configuration addresses and some general data.',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: [],
      deprecated: false,
    ),
  });

  ///It returns a 204 response with an empty body.
  Future<chopper.Response> statusGet() {
    return _statusGet();
  }

  ///It returns a 204 response with an empty body.
  @GET(path: '/status')
  Future<chopper.Response> _statusGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'It may be used just to check if the server is running.',
      summary: 'It returns a 204 response with an empty body.',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: [],
      deprecated: false,
    ),
  });

  ///It relay transactions.
  Future<chopper.Response<RelayPost$Response>> relayPost({
    required Object? body,
  }) {
    generatedMapping.putIfAbsent(
      RelayPost$Response,
      () => RelayPost$Response.fromJsonFactory,
    );

    return _relayPost(body: body);
  }

  ///It relay transactions.
  @POST(path: '/relay', optionalBody: true)
  Future<chopper.Response<RelayPost$Response>> _relayPost({
    @Body() required Object? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'It receives transactions to be relayed (deploy or forward requests) and after performing all the checks, it broadcasts them to the `relayHub`. For further information, please have a look at [Rif Relay architecture document](https://developers.rsk.co/rif/relay/architecture/)',
      summary: 'It relay transactions.',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: [],
      deprecated: false,
    ),
  });

  ///It estimate the mas possible gas in relay transaction.
  Future<chopper.Response<EstimatePost$Response>> estimatePost({
    required Object? body,
  }) {
    generatedMapping.putIfAbsent(
      EstimatePost$Response,
      () => EstimatePost$Response.fromJsonFactory,
    );

    return _estimatePost(body: body);
  }

  ///It estimate the mas possible gas in relay transaction.
  @POST(path: '/estimate', optionalBody: true)
  Future<chopper.Response<EstimatePost$Response>> _estimatePost({
    @Body() required Object? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'It receives transactions to be estimated (deploy or forward requests) and after performing all the checks, it estimates the gas consumption. It\'s possible to have a more precise estimation by including the user\'s signature, or a less precise estimation by specifying `\'SERVER_SIGNATURE_REQUIRED\'` in the `metadata.signature` field.',
      summary: 'It estimate the mas possible gas in relay transaction.',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: [],
      deprecated: false,
    ),
  });

  ///It retrieves the accepted tokens.
  ///@param verifier The address of the verifier to use to retrieve the accepted tokens.
  Future<chopper.Response<Object>> tokensGet({dynamic verifier}) {
    return _tokensGet(verifier: verifier);
  }

  ///It retrieves the accepted tokens.
  ///@param verifier The address of the verifier to use to retrieve the accepted tokens.
  @GET(path: '/tokens')
  Future<chopper.Response<Object>> _tokensGet({
    @Query('verifier') dynamic verifier,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'It retrieves the accepted tokens of the specified verifier if any, otherwise, it retrieves the accepted tokens of all the verifiers.',
      summary: 'It retrieves the accepted tokens.',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: [],
      deprecated: false,
    ),
  });

  ///It retrieves the accepted destination contracts.
  ///@param verifier The address of the verifier to use to retrieve the accepted destination contracts.
  Future<chopper.Response<Object>> contractsGet({dynamic verifier}) {
    return _contractsGet(verifier: verifier);
  }

  ///It retrieves the accepted destination contracts.
  ///@param verifier The address of the verifier to use to retrieve the accepted destination contracts.
  @GET(path: '/contracts')
  Future<chopper.Response<Object>> _contractsGet({
    @Query('verifier') dynamic verifier,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'It retrieves the accepted destination contracts of the specified verifier if any, otherwise, it retrieves the accepted destination contracts of all the verifiers.',
      summary: 'It retrieves the accepted destination contracts.',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: [],
      deprecated: false,
    ),
  });

  ///It returns the list of the trusted verifiers
  Future<chopper.Response<VerifiersGet$Response>> verifiersGet() {
    generatedMapping.putIfAbsent(
      VerifiersGet$Response,
      () => VerifiersGet$Response.fromJsonFactory,
    );

    return _verifiersGet();
  }

  ///It returns the list of the trusted verifiers
  @GET(path: '/verifiers')
  Future<chopper.Response<VerifiersGet$Response>> _verifiersGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'It returns the list of the trusted verifiers. \'Trusted\' verifiers means that we trust `verifyRelayedCall` to be consistent: off-chain call and on-chain calls should either both succeed or both revert.',
      summary: 'It returns the list of the trusted verifiers',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: [],
      deprecated: false,
    ),
  });
}

@JsonSerializable(explicitToJson: true)
class PingResponse {
  const PingResponse({
    this.relayWorkerAddress,
    this.relayManagerAddress,
    this.relayHubAddress,
    this.minGasPrice,
    this.chainId,
    this.networkId,
    this.ready,
    this.version,
  });

  factory PingResponse.fromJson(Map<String, dynamic> json) =>
      _$PingResponseFromJson(json);

  static const toJsonFactory = _$PingResponseToJson;
  Map<String, dynamic> toJson() => _$PingResponseToJson(this);

  @JsonKey(name: 'relayWorkerAddress', includeIfNull: false)
  final Object? relayWorkerAddress;
  @JsonKey(name: 'relayManagerAddress', includeIfNull: false)
  final Object? relayManagerAddress;
  @JsonKey(name: 'relayHubAddress', includeIfNull: false)
  final Object? relayHubAddress;
  @JsonKey(name: 'minGasPrice', includeIfNull: false)
  final String? minGasPrice;
  @JsonKey(name: 'chainId', includeIfNull: false)
  final String? chainId;
  @JsonKey(name: 'networkId', includeIfNull: false)
  final String? networkId;
  @JsonKey(name: 'ready', includeIfNull: false)
  final bool? ready;
  @JsonKey(name: 'version', includeIfNull: false)
  final String? version;
  static const fromJsonFactory = _$PingResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PingResponse &&
            (identical(other.relayWorkerAddress, relayWorkerAddress) ||
                const DeepCollectionEquality().equals(
                  other.relayWorkerAddress,
                  relayWorkerAddress,
                )) &&
            (identical(other.relayManagerAddress, relayManagerAddress) ||
                const DeepCollectionEquality().equals(
                  other.relayManagerAddress,
                  relayManagerAddress,
                )) &&
            (identical(other.relayHubAddress, relayHubAddress) ||
                const DeepCollectionEquality().equals(
                  other.relayHubAddress,
                  relayHubAddress,
                )) &&
            (identical(other.minGasPrice, minGasPrice) ||
                const DeepCollectionEquality().equals(
                  other.minGasPrice,
                  minGasPrice,
                )) &&
            (identical(other.chainId, chainId) ||
                const DeepCollectionEquality().equals(
                  other.chainId,
                  chainId,
                )) &&
            (identical(other.networkId, networkId) ||
                const DeepCollectionEquality().equals(
                  other.networkId,
                  networkId,
                )) &&
            (identical(other.ready, ready) ||
                const DeepCollectionEquality().equals(other.ready, ready)) &&
            (identical(other.version, version) ||
                const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(relayWorkerAddress) ^
      const DeepCollectionEquality().hash(relayManagerAddress) ^
      const DeepCollectionEquality().hash(relayHubAddress) ^
      const DeepCollectionEquality().hash(minGasPrice) ^
      const DeepCollectionEquality().hash(chainId) ^
      const DeepCollectionEquality().hash(networkId) ^
      const DeepCollectionEquality().hash(ready) ^
      const DeepCollectionEquality().hash(version) ^
      runtimeType.hashCode;
}

extension $PingResponseExtension on PingResponse {
  PingResponse copyWith({
    Object? relayWorkerAddress,
    Object? relayManagerAddress,
    Object? relayHubAddress,
    String? minGasPrice,
    String? chainId,
    String? networkId,
    bool? ready,
    String? version,
  }) {
    return PingResponse(
      relayWorkerAddress: relayWorkerAddress ?? this.relayWorkerAddress,
      relayManagerAddress: relayManagerAddress ?? this.relayManagerAddress,
      relayHubAddress: relayHubAddress ?? this.relayHubAddress,
      minGasPrice: minGasPrice ?? this.minGasPrice,
      chainId: chainId ?? this.chainId,
      networkId: networkId ?? this.networkId,
      ready: ready ?? this.ready,
      version: version ?? this.version,
    );
  }

  PingResponse copyWithWrapped({
    Wrapped<Object?>? relayWorkerAddress,
    Wrapped<Object?>? relayManagerAddress,
    Wrapped<Object?>? relayHubAddress,
    Wrapped<String?>? minGasPrice,
    Wrapped<String?>? chainId,
    Wrapped<String?>? networkId,
    Wrapped<bool?>? ready,
    Wrapped<String?>? version,
  }) {
    return PingResponse(
      relayWorkerAddress: (relayWorkerAddress != null
          ? relayWorkerAddress.value
          : this.relayWorkerAddress),
      relayManagerAddress: (relayManagerAddress != null
          ? relayManagerAddress.value
          : this.relayManagerAddress),
      relayHubAddress: (relayHubAddress != null
          ? relayHubAddress.value
          : this.relayHubAddress),
      minGasPrice: (minGasPrice != null ? minGasPrice.value : this.minGasPrice),
      chainId: (chainId != null ? chainId.value : this.chainId),
      networkId: (networkId != null ? networkId.value : this.networkId),
      ready: (ready != null ? ready.value : this.ready),
      version: (version != null ? version.value : this.version),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RelayTransactionRequest {
  const RelayTransactionRequest({this.relayRequest, this.metadata});

  factory RelayTransactionRequest.fromJson(Map<String, dynamic> json) =>
      _$RelayTransactionRequestFromJson(json);

  static const toJsonFactory = _$RelayTransactionRequestToJson;
  Map<String, dynamic> toJson() => _$RelayTransactionRequestToJson(this);

  @JsonKey(name: 'relayRequest', includeIfNull: false)
  final RelayRequest? relayRequest;
  @JsonKey(name: 'metadata', includeIfNull: false)
  final RelayMetadata? metadata;
  static const fromJsonFactory = _$RelayTransactionRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RelayTransactionRequest &&
            (identical(other.relayRequest, relayRequest) ||
                const DeepCollectionEquality().equals(
                  other.relayRequest,
                  relayRequest,
                )) &&
            (identical(other.metadata, metadata) ||
                const DeepCollectionEquality().equals(
                  other.metadata,
                  metadata,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(relayRequest) ^
      const DeepCollectionEquality().hash(metadata) ^
      runtimeType.hashCode;
}

extension $RelayTransactionRequestExtension on RelayTransactionRequest {
  RelayTransactionRequest copyWith({
    RelayRequest? relayRequest,
    RelayMetadata? metadata,
  }) {
    return RelayTransactionRequest(
      relayRequest: relayRequest ?? this.relayRequest,
      metadata: metadata ?? this.metadata,
    );
  }

  RelayTransactionRequest copyWithWrapped({
    Wrapped<RelayRequest?>? relayRequest,
    Wrapped<RelayMetadata?>? metadata,
  }) {
    return RelayTransactionRequest(
      relayRequest: (relayRequest != null
          ? relayRequest.value
          : this.relayRequest),
      metadata: (metadata != null ? metadata.value : this.metadata),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RelayRequest {
  const RelayRequest({this.request, this.relayData});

  factory RelayRequest.fromJson(Map<String, dynamic> json) =>
      _$RelayRequestFromJson(json);

  static const toJsonFactory = _$RelayRequestToJson;
  Map<String, dynamic> toJson() => _$RelayRequestToJson(this);

  @JsonKey(name: 'request', includeIfNull: false)
  final ForwardRequest? request;
  @JsonKey(name: 'relayData', includeIfNull: false)
  final RelayData? relayData;
  static const fromJsonFactory = _$RelayRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RelayRequest &&
            (identical(other.request, request) ||
                const DeepCollectionEquality().equals(
                  other.request,
                  request,
                )) &&
            (identical(other.relayData, relayData) ||
                const DeepCollectionEquality().equals(
                  other.relayData,
                  relayData,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(request) ^
      const DeepCollectionEquality().hash(relayData) ^
      runtimeType.hashCode;
}

extension $RelayRequestExtension on RelayRequest {
  RelayRequest copyWith({ForwardRequest? request, RelayData? relayData}) {
    return RelayRequest(
      request: request ?? this.request,
      relayData: relayData ?? this.relayData,
    );
  }

  RelayRequest copyWithWrapped({
    Wrapped<ForwardRequest?>? request,
    Wrapped<RelayData?>? relayData,
  }) {
    return RelayRequest(
      request: (request != null ? request.value : this.request),
      relayData: (relayData != null ? relayData.value : this.relayData),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ForwardRequest {
  const ForwardRequest({
    this.relayHub,
    this.from,
    this.to,
    this.tokenContract,
    this.value,
    this.gas,
    this.nonce,
    this.tokenAmount,
    this.tokenGas,
    this.data,
  });

  factory ForwardRequest.fromJson(Map<String, dynamic> json) =>
      _$ForwardRequestFromJson(json);

  static const toJsonFactory = _$ForwardRequestToJson;
  Map<String, dynamic> toJson() => _$ForwardRequestToJson(this);

  @JsonKey(name: 'relayHub', includeIfNull: false)
  final Object? relayHub;
  @JsonKey(name: 'from', includeIfNull: false)
  final Object? from;
  @JsonKey(name: 'to', includeIfNull: false)
  final Object? to;
  @JsonKey(name: 'tokenContract', includeIfNull: false)
  final Object? tokenContract;
  @JsonKey(name: 'value', includeIfNull: false)
  final String? value;
  @JsonKey(name: 'gas', includeIfNull: false)
  final String? gas;
  @JsonKey(name: 'nonce', includeIfNull: false)
  final String? nonce;
  @JsonKey(name: 'tokenAmount', includeIfNull: false)
  final String? tokenAmount;
  @JsonKey(name: 'tokenGas', includeIfNull: false)
  final String? tokenGas;
  @JsonKey(name: 'data', includeIfNull: false)
  final String? data;
  static const fromJsonFactory = _$ForwardRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ForwardRequest &&
            (identical(other.relayHub, relayHub) ||
                const DeepCollectionEquality().equals(
                  other.relayHub,
                  relayHub,
                )) &&
            (identical(other.from, from) ||
                const DeepCollectionEquality().equals(other.from, from)) &&
            (identical(other.to, to) ||
                const DeepCollectionEquality().equals(other.to, to)) &&
            (identical(other.tokenContract, tokenContract) ||
                const DeepCollectionEquality().equals(
                  other.tokenContract,
                  tokenContract,
                )) &&
            (identical(other.value, value) ||
                const DeepCollectionEquality().equals(other.value, value)) &&
            (identical(other.gas, gas) ||
                const DeepCollectionEquality().equals(other.gas, gas)) &&
            (identical(other.nonce, nonce) ||
                const DeepCollectionEquality().equals(other.nonce, nonce)) &&
            (identical(other.tokenAmount, tokenAmount) ||
                const DeepCollectionEquality().equals(
                  other.tokenAmount,
                  tokenAmount,
                )) &&
            (identical(other.tokenGas, tokenGas) ||
                const DeepCollectionEquality().equals(
                  other.tokenGas,
                  tokenGas,
                )) &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(relayHub) ^
      const DeepCollectionEquality().hash(from) ^
      const DeepCollectionEquality().hash(to) ^
      const DeepCollectionEquality().hash(tokenContract) ^
      const DeepCollectionEquality().hash(value) ^
      const DeepCollectionEquality().hash(gas) ^
      const DeepCollectionEquality().hash(nonce) ^
      const DeepCollectionEquality().hash(tokenAmount) ^
      const DeepCollectionEquality().hash(tokenGas) ^
      const DeepCollectionEquality().hash(data) ^
      runtimeType.hashCode;
}

extension $ForwardRequestExtension on ForwardRequest {
  ForwardRequest copyWith({
    Object? relayHub,
    Object? from,
    Object? to,
    Object? tokenContract,
    String? value,
    String? gas,
    String? nonce,
    String? tokenAmount,
    String? tokenGas,
    String? data,
  }) {
    return ForwardRequest(
      relayHub: relayHub ?? this.relayHub,
      from: from ?? this.from,
      to: to ?? this.to,
      tokenContract: tokenContract ?? this.tokenContract,
      value: value ?? this.value,
      gas: gas ?? this.gas,
      nonce: nonce ?? this.nonce,
      tokenAmount: tokenAmount ?? this.tokenAmount,
      tokenGas: tokenGas ?? this.tokenGas,
      data: data ?? this.data,
    );
  }

  ForwardRequest copyWithWrapped({
    Wrapped<Object?>? relayHub,
    Wrapped<Object?>? from,
    Wrapped<Object?>? to,
    Wrapped<Object?>? tokenContract,
    Wrapped<String?>? value,
    Wrapped<String?>? gas,
    Wrapped<String?>? nonce,
    Wrapped<String?>? tokenAmount,
    Wrapped<String?>? tokenGas,
    Wrapped<String?>? data,
  }) {
    return ForwardRequest(
      relayHub: (relayHub != null ? relayHub.value : this.relayHub),
      from: (from != null ? from.value : this.from),
      to: (to != null ? to.value : this.to),
      tokenContract: (tokenContract != null
          ? tokenContract.value
          : this.tokenContract),
      value: (value != null ? value.value : this.value),
      gas: (gas != null ? gas.value : this.gas),
      nonce: (nonce != null ? nonce.value : this.nonce),
      tokenAmount: (tokenAmount != null ? tokenAmount.value : this.tokenAmount),
      tokenGas: (tokenGas != null ? tokenGas.value : this.tokenGas),
      data: (data != null ? data.value : this.data),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class DeployTransactionRequest {
  const DeployTransactionRequest({this.request, this.relayData});

  factory DeployTransactionRequest.fromJson(Map<String, dynamic> json) =>
      _$DeployTransactionRequestFromJson(json);

  static const toJsonFactory = _$DeployTransactionRequestToJson;
  Map<String, dynamic> toJson() => _$DeployTransactionRequestToJson(this);

  @JsonKey(name: 'request', includeIfNull: false)
  final DeployRequestStruct? request;
  @JsonKey(name: 'relayData', includeIfNull: false)
  final RelayData? relayData;
  static const fromJsonFactory = _$DeployTransactionRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DeployTransactionRequest &&
            (identical(other.request, request) ||
                const DeepCollectionEquality().equals(
                  other.request,
                  request,
                )) &&
            (identical(other.relayData, relayData) ||
                const DeepCollectionEquality().equals(
                  other.relayData,
                  relayData,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(request) ^
      const DeepCollectionEquality().hash(relayData) ^
      runtimeType.hashCode;
}

extension $DeployTransactionRequestExtension on DeployTransactionRequest {
  DeployTransactionRequest copyWith({
    DeployRequestStruct? request,
    RelayData? relayData,
  }) {
    return DeployTransactionRequest(
      request: request ?? this.request,
      relayData: relayData ?? this.relayData,
    );
  }

  DeployTransactionRequest copyWithWrapped({
    Wrapped<DeployRequestStruct?>? request,
    Wrapped<RelayData?>? relayData,
  }) {
    return DeployTransactionRequest(
      request: (request != null ? request.value : this.request),
      relayData: (relayData != null ? relayData.value : this.relayData),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class DeployRequestStruct {
  const DeployRequestStruct({
    this.relayHub,
    this.from,
    this.to,
    this.tokenContract,
    this.recoverer,
    this.value,
    this.nonce,
    this.tokenAmount,
    this.tokenGas,
    this.index,
    this.data,
  });

  factory DeployRequestStruct.fromJson(Map<String, dynamic> json) =>
      _$DeployRequestStructFromJson(json);

  static const toJsonFactory = _$DeployRequestStructToJson;
  Map<String, dynamic> toJson() => _$DeployRequestStructToJson(this);

  @JsonKey(name: 'relayHub', includeIfNull: false)
  final Object? relayHub;
  @JsonKey(name: 'from', includeIfNull: false)
  final Object? from;
  @JsonKey(name: 'to', includeIfNull: false)
  final Object? to;
  @JsonKey(name: 'tokenContract', includeIfNull: false)
  final Object? tokenContract;
  @JsonKey(name: 'recoverer', includeIfNull: false)
  final Object? recoverer;
  @JsonKey(name: 'value', includeIfNull: false)
  final String? value;
  @JsonKey(name: 'nonce', includeIfNull: false)
  final String? nonce;
  @JsonKey(name: 'tokenAmount', includeIfNull: false)
  final String? tokenAmount;
  @JsonKey(name: 'tokenGas', includeIfNull: false)
  final String? tokenGas;
  @JsonKey(name: 'index', includeIfNull: false)
  final String? index;
  @JsonKey(name: 'data', includeIfNull: false)
  final String? data;
  static const fromJsonFactory = _$DeployRequestStructFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DeployRequestStruct &&
            (identical(other.relayHub, relayHub) ||
                const DeepCollectionEquality().equals(
                  other.relayHub,
                  relayHub,
                )) &&
            (identical(other.from, from) ||
                const DeepCollectionEquality().equals(other.from, from)) &&
            (identical(other.to, to) ||
                const DeepCollectionEquality().equals(other.to, to)) &&
            (identical(other.tokenContract, tokenContract) ||
                const DeepCollectionEquality().equals(
                  other.tokenContract,
                  tokenContract,
                )) &&
            (identical(other.recoverer, recoverer) ||
                const DeepCollectionEquality().equals(
                  other.recoverer,
                  recoverer,
                )) &&
            (identical(other.value, value) ||
                const DeepCollectionEquality().equals(other.value, value)) &&
            (identical(other.nonce, nonce) ||
                const DeepCollectionEquality().equals(other.nonce, nonce)) &&
            (identical(other.tokenAmount, tokenAmount) ||
                const DeepCollectionEquality().equals(
                  other.tokenAmount,
                  tokenAmount,
                )) &&
            (identical(other.tokenGas, tokenGas) ||
                const DeepCollectionEquality().equals(
                  other.tokenGas,
                  tokenGas,
                )) &&
            (identical(other.index, index) ||
                const DeepCollectionEquality().equals(other.index, index)) &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(relayHub) ^
      const DeepCollectionEquality().hash(from) ^
      const DeepCollectionEquality().hash(to) ^
      const DeepCollectionEquality().hash(tokenContract) ^
      const DeepCollectionEquality().hash(recoverer) ^
      const DeepCollectionEquality().hash(value) ^
      const DeepCollectionEquality().hash(nonce) ^
      const DeepCollectionEquality().hash(tokenAmount) ^
      const DeepCollectionEquality().hash(tokenGas) ^
      const DeepCollectionEquality().hash(index) ^
      const DeepCollectionEquality().hash(data) ^
      runtimeType.hashCode;
}

extension $DeployRequestStructExtension on DeployRequestStruct {
  DeployRequestStruct copyWith({
    Object? relayHub,
    Object? from,
    Object? to,
    Object? tokenContract,
    Object? recoverer,
    String? value,
    String? nonce,
    String? tokenAmount,
    String? tokenGas,
    String? index,
    String? data,
  }) {
    return DeployRequestStruct(
      relayHub: relayHub ?? this.relayHub,
      from: from ?? this.from,
      to: to ?? this.to,
      tokenContract: tokenContract ?? this.tokenContract,
      recoverer: recoverer ?? this.recoverer,
      value: value ?? this.value,
      nonce: nonce ?? this.nonce,
      tokenAmount: tokenAmount ?? this.tokenAmount,
      tokenGas: tokenGas ?? this.tokenGas,
      index: index ?? this.index,
      data: data ?? this.data,
    );
  }

  DeployRequestStruct copyWithWrapped({
    Wrapped<Object?>? relayHub,
    Wrapped<Object?>? from,
    Wrapped<Object?>? to,
    Wrapped<Object?>? tokenContract,
    Wrapped<Object?>? recoverer,
    Wrapped<String?>? value,
    Wrapped<String?>? nonce,
    Wrapped<String?>? tokenAmount,
    Wrapped<String?>? tokenGas,
    Wrapped<String?>? index,
    Wrapped<String?>? data,
  }) {
    return DeployRequestStruct(
      relayHub: (relayHub != null ? relayHub.value : this.relayHub),
      from: (from != null ? from.value : this.from),
      to: (to != null ? to.value : this.to),
      tokenContract: (tokenContract != null
          ? tokenContract.value
          : this.tokenContract),
      recoverer: (recoverer != null ? recoverer.value : this.recoverer),
      value: (value != null ? value.value : this.value),
      nonce: (nonce != null ? nonce.value : this.nonce),
      tokenAmount: (tokenAmount != null ? tokenAmount.value : this.tokenAmount),
      tokenGas: (tokenGas != null ? tokenGas.value : this.tokenGas),
      index: (index != null ? index.value : this.index),
      data: (data != null ? data.value : this.data),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RelayData {
  const RelayData({
    this.gasPrice,
    this.feesReceiver,
    this.callForwarder,
    this.callVerifier,
  });

  factory RelayData.fromJson(Map<String, dynamic> json) =>
      _$RelayDataFromJson(json);

  static const toJsonFactory = _$RelayDataToJson;
  Map<String, dynamic> toJson() => _$RelayDataToJson(this);

  @JsonKey(name: 'gasPrice', includeIfNull: false)
  final String? gasPrice;
  @JsonKey(name: 'feesReceiver', includeIfNull: false)
  final Object? feesReceiver;
  @JsonKey(name: 'callForwarder', includeIfNull: false)
  final Object? callForwarder;
  @JsonKey(name: 'callVerifier', includeIfNull: false)
  final Object? callVerifier;
  static const fromJsonFactory = _$RelayDataFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RelayData &&
            (identical(other.gasPrice, gasPrice) ||
                const DeepCollectionEquality().equals(
                  other.gasPrice,
                  gasPrice,
                )) &&
            (identical(other.feesReceiver, feesReceiver) ||
                const DeepCollectionEquality().equals(
                  other.feesReceiver,
                  feesReceiver,
                )) &&
            (identical(other.callForwarder, callForwarder) ||
                const DeepCollectionEquality().equals(
                  other.callForwarder,
                  callForwarder,
                )) &&
            (identical(other.callVerifier, callVerifier) ||
                const DeepCollectionEquality().equals(
                  other.callVerifier,
                  callVerifier,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(gasPrice) ^
      const DeepCollectionEquality().hash(feesReceiver) ^
      const DeepCollectionEquality().hash(callForwarder) ^
      const DeepCollectionEquality().hash(callVerifier) ^
      runtimeType.hashCode;
}

extension $RelayDataExtension on RelayData {
  RelayData copyWith({
    String? gasPrice,
    Object? feesReceiver,
    Object? callForwarder,
    Object? callVerifier,
  }) {
    return RelayData(
      gasPrice: gasPrice ?? this.gasPrice,
      feesReceiver: feesReceiver ?? this.feesReceiver,
      callForwarder: callForwarder ?? this.callForwarder,
      callVerifier: callVerifier ?? this.callVerifier,
    );
  }

  RelayData copyWithWrapped({
    Wrapped<String?>? gasPrice,
    Wrapped<Object?>? feesReceiver,
    Wrapped<Object?>? callForwarder,
    Wrapped<Object?>? callVerifier,
  }) {
    return RelayData(
      gasPrice: (gasPrice != null ? gasPrice.value : this.gasPrice),
      feesReceiver: (feesReceiver != null
          ? feesReceiver.value
          : this.feesReceiver),
      callForwarder: (callForwarder != null
          ? callForwarder.value
          : this.callForwarder),
      callVerifier: (callVerifier != null
          ? callVerifier.value
          : this.callVerifier),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RelayMetadata {
  const RelayMetadata({
    this.relayHubAddress,
    this.relayMaxNonce,
    this.signature,
  });

  factory RelayMetadata.fromJson(Map<String, dynamic> json) =>
      _$RelayMetadataFromJson(json);

  static const toJsonFactory = _$RelayMetadataToJson;
  Map<String, dynamic> toJson() => _$RelayMetadataToJson(this);

  @JsonKey(name: 'relayHubAddress', includeIfNull: false)
  final Object? relayHubAddress;
  @JsonKey(name: 'relayMaxNonce', includeIfNull: false)
  final double? relayMaxNonce;
  @JsonKey(name: 'signature', includeIfNull: false)
  final String? signature;
  static const fromJsonFactory = _$RelayMetadataFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RelayMetadata &&
            (identical(other.relayHubAddress, relayHubAddress) ||
                const DeepCollectionEquality().equals(
                  other.relayHubAddress,
                  relayHubAddress,
                )) &&
            (identical(other.relayMaxNonce, relayMaxNonce) ||
                const DeepCollectionEquality().equals(
                  other.relayMaxNonce,
                  relayMaxNonce,
                )) &&
            (identical(other.signature, signature) ||
                const DeepCollectionEquality().equals(
                  other.signature,
                  signature,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(relayHubAddress) ^
      const DeepCollectionEquality().hash(relayMaxNonce) ^
      const DeepCollectionEquality().hash(signature) ^
      runtimeType.hashCode;
}

extension $RelayMetadataExtension on RelayMetadata {
  RelayMetadata copyWith({
    Object? relayHubAddress,
    double? relayMaxNonce,
    String? signature,
  }) {
    return RelayMetadata(
      relayHubAddress: relayHubAddress ?? this.relayHubAddress,
      relayMaxNonce: relayMaxNonce ?? this.relayMaxNonce,
      signature: signature ?? this.signature,
    );
  }

  RelayMetadata copyWithWrapped({
    Wrapped<Object?>? relayHubAddress,
    Wrapped<double?>? relayMaxNonce,
    Wrapped<String?>? signature,
  }) {
    return RelayMetadata(
      relayHubAddress: (relayHubAddress != null
          ? relayHubAddress.value
          : this.relayHubAddress),
      relayMaxNonce: (relayMaxNonce != null
          ? relayMaxNonce.value
          : this.relayMaxNonce),
      signature: (signature != null ? signature.value : this.signature),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RelayPost$Response {
  const RelayPost$Response({this.signedTx, this.transactionHash});

  factory RelayPost$Response.fromJson(Map<String, dynamic> json) =>
      _$RelayPost$ResponseFromJson(json);

  static const toJsonFactory = _$RelayPost$ResponseToJson;
  Map<String, dynamic> toJson() => _$RelayPost$ResponseToJson(this);

  @JsonKey(name: 'signedTx', includeIfNull: false)
  final Object? signedTx;
  @JsonKey(name: 'txHash', includeIfNull: false)
  final Object? transactionHash;
  static const fromJsonFactory = _$RelayPost$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RelayPost$Response &&
            (identical(other.signedTx, signedTx) ||
                const DeepCollectionEquality().equals(
                  other.signedTx,
                  signedTx,
                )) &&
            (identical(other.transactionHash, transactionHash) ||
                const DeepCollectionEquality().equals(
                  other.transactionHash,
                  transactionHash,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(signedTx) ^
      const DeepCollectionEquality().hash(transactionHash) ^
      runtimeType.hashCode;
}

extension $RelayPost$ResponseExtension on RelayPost$Response {
  RelayPost$Response copyWith({Object? signedTx, Object? transactionHash}) {
    return RelayPost$Response(
      signedTx: signedTx ?? this.signedTx,
      transactionHash: transactionHash ?? this.transactionHash,
    );
  }

  RelayPost$Response copyWithWrapped({
    Wrapped<Object?>? signedTx,
    Wrapped<Object?>? transactionHash,
  }) {
    return RelayPost$Response(
      signedTx: (signedTx != null ? signedTx.value : this.signedTx),
      transactionHash: (transactionHash != null
          ? transactionHash.value
          : this.transactionHash),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class EstimatePost$Response {
  const EstimatePost$Response({
    this.gasPrice,
    this.estimation,
    this.requiredTokenAmount,
    this.requiredNativeAmount,
    this.exchangeRate,
  });

  factory EstimatePost$Response.fromJson(Map<String, dynamic> json) =>
      _$EstimatePost$ResponseFromJson(json);

  static const toJsonFactory = _$EstimatePost$ResponseToJson;
  Map<String, dynamic> toJson() => _$EstimatePost$ResponseToJson(this);

  @JsonKey(name: 'gasPrice', includeIfNull: false)
  final String? gasPrice;
  @JsonKey(name: 'estimation', includeIfNull: false)
  final String? estimation;
  @JsonKey(name: 'requiredTokenAmount', includeIfNull: false)
  final String? requiredTokenAmount;
  @JsonKey(name: 'requiredNativeAmount', includeIfNull: false)
  final String? requiredNativeAmount;
  @JsonKey(name: 'exchangeRate', includeIfNull: false)
  final String? exchangeRate;
  static const fromJsonFactory = _$EstimatePost$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is EstimatePost$Response &&
            (identical(other.gasPrice, gasPrice) ||
                const DeepCollectionEquality().equals(
                  other.gasPrice,
                  gasPrice,
                )) &&
            (identical(other.estimation, estimation) ||
                const DeepCollectionEquality().equals(
                  other.estimation,
                  estimation,
                )) &&
            (identical(other.requiredTokenAmount, requiredTokenAmount) ||
                const DeepCollectionEquality().equals(
                  other.requiredTokenAmount,
                  requiredTokenAmount,
                )) &&
            (identical(other.requiredNativeAmount, requiredNativeAmount) ||
                const DeepCollectionEquality().equals(
                  other.requiredNativeAmount,
                  requiredNativeAmount,
                )) &&
            (identical(other.exchangeRate, exchangeRate) ||
                const DeepCollectionEquality().equals(
                  other.exchangeRate,
                  exchangeRate,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(gasPrice) ^
      const DeepCollectionEquality().hash(estimation) ^
      const DeepCollectionEquality().hash(requiredTokenAmount) ^
      const DeepCollectionEquality().hash(requiredNativeAmount) ^
      const DeepCollectionEquality().hash(exchangeRate) ^
      runtimeType.hashCode;
}

extension $EstimatePost$ResponseExtension on EstimatePost$Response {
  EstimatePost$Response copyWith({
    String? gasPrice,
    String? estimation,
    String? requiredTokenAmount,
    String? requiredNativeAmount,
    String? exchangeRate,
  }) {
    return EstimatePost$Response(
      gasPrice: gasPrice ?? this.gasPrice,
      estimation: estimation ?? this.estimation,
      requiredTokenAmount: requiredTokenAmount ?? this.requiredTokenAmount,
      requiredNativeAmount: requiredNativeAmount ?? this.requiredNativeAmount,
      exchangeRate: exchangeRate ?? this.exchangeRate,
    );
  }

  EstimatePost$Response copyWithWrapped({
    Wrapped<String?>? gasPrice,
    Wrapped<String?>? estimation,
    Wrapped<String?>? requiredTokenAmount,
    Wrapped<String?>? requiredNativeAmount,
    Wrapped<String?>? exchangeRate,
  }) {
    return EstimatePost$Response(
      gasPrice: (gasPrice != null ? gasPrice.value : this.gasPrice),
      estimation: (estimation != null ? estimation.value : this.estimation),
      requiredTokenAmount: (requiredTokenAmount != null
          ? requiredTokenAmount.value
          : this.requiredTokenAmount),
      requiredNativeAmount: (requiredNativeAmount != null
          ? requiredNativeAmount.value
          : this.requiredNativeAmount),
      exchangeRate: (exchangeRate != null
          ? exchangeRate.value
          : this.exchangeRate),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class VerifiersGet$Response {
  const VerifiersGet$Response({this.trustedVerifiers});

  factory VerifiersGet$Response.fromJson(Map<String, dynamic> json) =>
      _$VerifiersGet$ResponseFromJson(json);

  static const toJsonFactory = _$VerifiersGet$ResponseToJson;
  Map<String, dynamic> toJson() => _$VerifiersGet$ResponseToJson(this);

  @JsonKey(
    name: 'trustedVerifiers',
    includeIfNull: false,
    defaultValue: <Object>[],
  )
  final List<Object>? trustedVerifiers;
  static const fromJsonFactory = _$VerifiersGet$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is VerifiersGet$Response &&
            (identical(other.trustedVerifiers, trustedVerifiers) ||
                const DeepCollectionEquality().equals(
                  other.trustedVerifiers,
                  trustedVerifiers,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(trustedVerifiers) ^
      runtimeType.hashCode;
}

extension $VerifiersGet$ResponseExtension on VerifiersGet$Response {
  VerifiersGet$Response copyWith({List<Object>? trustedVerifiers}) {
    return VerifiersGet$Response(
      trustedVerifiers: trustedVerifiers ?? this.trustedVerifiers,
    );
  }

  VerifiersGet$Response copyWithWrapped({
    Wrapped<List<Object>?>? trustedVerifiers,
  }) {
    return VerifiersGet$Response(
      trustedVerifiers: (trustedVerifiers != null
          ? trustedVerifiers.value
          : this.trustedVerifiers),
    );
  }
}

typedef $JsonFactory<T> = T Function(Map<String, dynamic> json);

class $CustomJsonDecoder {
  $CustomJsonDecoder(this.factories);

  final Map<Type, $JsonFactory> factories;

  dynamic decode<T>(dynamic entity) {
    if (entity is Iterable) {
      return _decodeList<T>(entity);
    }

    if (entity is T) {
      return entity;
    }

    if (isTypeOf<T, Map>()) {
      return entity;
    }

    if (isTypeOf<T, Iterable>()) {
      return entity;
    }

    if (entity is Map<String, dynamic>) {
      return _decodeMap<T>(entity);
    }

    return entity;
  }

  T _decodeMap<T>(Map<String, dynamic> values) {
    final jsonFactory = factories[T];
    if (jsonFactory == null || jsonFactory is! $JsonFactory<T>) {
      return throw "Could not find factory for type $T. Is '$T: $T.fromJsonFactory' included in the CustomJsonDecoder instance creation in bootstrapper.dart?";
    }

    return jsonFactory(values);
  }

  List<T> _decodeList<T>(Iterable values) =>
      values.where((v) => v != null).map<T>((v) => decode<T>(v) as T).toList();
}

class $JsonSerializableConverter extends chopper.JsonConverter {
  @override
  FutureOr<chopper.Response<ResultType>> convertResponse<ResultType, Item>(
    chopper.Response response,
  ) async {
    if (response.bodyString.isEmpty) {
      // In rare cases, when let's say 204 (no content) is returned -
      // we cannot decode the missing json with the result type specified
      return chopper.Response(response.base, null, error: response.error);
    }

    if (ResultType == String) {
      return response.copyWith();
    }

    if (ResultType == DateTime) {
      return response.copyWith(
        body:
            DateTime.parse((response.body as String).replaceAll('"', ''))
                as ResultType,
      );
    }

    final jsonRes = await super.convertResponse(response);
    return jsonRes.copyWith<ResultType>(
      body: $jsonDecoder.decode<Item>(jsonRes.body) as ResultType,
    );
  }
}

final $jsonDecoder = $CustomJsonDecoder(generatedMapping);

// ignore: unused_element
String? _dateToJson(DateTime? date) {
  if (date == null) {
    return null;
  }

  final year = date.year.toString();
  final month = date.month < 10 ? '0${date.month}' : date.month.toString();
  final day = date.day < 10 ? '0${date.day}' : date.day.toString();

  return '$year-$month-$day';
}

class Wrapped<T> {
  final T value;
  const Wrapped.value(this.value);
}
