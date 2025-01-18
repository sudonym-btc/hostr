// ignore_for_file: type=lint

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

part 'boltz.swagger.chopper.dart';
part 'boltz.swagger.g.dart';

// **************************************************************************
// SwaggerChopperGenerator
// **************************************************************************

@ChopperApi()
abstract class Boltz extends ChopperService {
  static Boltz create({
    ChopperClient? client,
    http.Client? httpClient,
    Authenticator? authenticator,
    ErrorConverter? errorConverter,
    Converter? converter,
    Uri? baseUrl,
    List<Interceptor>? interceptors,
  }) {
    if (client != null) {
      return _$Boltz(client);
    }

    final newClient = ChopperClient(
        services: [_$Boltz()],
        converter: converter ?? $JsonSerializableConverter(),
        interceptors: interceptors ?? [],
        client: httpClient,
        authenticator: authenticator,
        errorConverter: errorConverter,
        baseUrl: baseUrl ?? Uri.parse('http://'));
    return _$Boltz(newClient);
  }

  ///
  Future<chopper.Response<Object>> chainFeesGet() {
    return _chainFeesGet();
  }

  ///
  @Get(path: '/chain/fees')
  Future<chopper.Response<Object>> _chainFeesGet();

  ///
  Future<chopper.Response<Object>> chainHeightsGet() {
    return _chainHeightsGet();
  }

  ///
  @Get(path: '/chain/heights')
  Future<chopper.Response<Object>> _chainHeightsGet();

  ///
  Future<chopper.Response<Object>> chainContractsGet() {
    return _chainContractsGet();
  }

  ///
  @Get(path: '/chain/contracts')
  Future<chopper.Response<Object>> _chainContractsGet();

  ///
  ///@param currency Currency of the chain to get a fee estimation for
  Future<chopper.Response<ChainCurrencyFeeGet$Response>> chainCurrencyFeeGet(
      {required String? currency}) {
    generatedMapping.putIfAbsent(ChainCurrencyFeeGet$Response,
        () => ChainCurrencyFeeGet$Response.fromJsonFactory);

    return _chainCurrencyFeeGet(currency: currency);
  }

  ///
  ///@param currency Currency of the chain to get a fee estimation for
  @Get(path: '/chain/{currency}/fee')
  Future<chopper.Response<ChainCurrencyFeeGet$Response>> _chainCurrencyFeeGet(
      {@Path('currency') required String? currency});

  ///
  ///@param currency Currency of the chain to get the block height for
  Future<chopper.Response<ChainCurrencyHeightGet$Response>>
      chainCurrencyHeightGet({required String? currency}) {
    generatedMapping.putIfAbsent(ChainCurrencyHeightGet$Response,
        () => ChainCurrencyHeightGet$Response.fromJsonFactory);

    return _chainCurrencyHeightGet(currency: currency);
  }

  ///
  ///@param currency Currency of the chain to get the block height for
  @Get(path: '/chain/{currency}/height')
  Future<chopper.Response<ChainCurrencyHeightGet$Response>>
      _chainCurrencyHeightGet({@Path('currency') required String? currency});

  ///
  ///@param currency Currency of the chain to query for
  ///@param id Id of the transaction to query
  Future<chopper.Response<ChainCurrencyTransactionIdGet$Response>>
      chainCurrencyTransactionIdGet({
    required String? currency,
    required String? id,
  }) {
    generatedMapping.putIfAbsent(ChainCurrencyTransactionIdGet$Response,
        () => ChainCurrencyTransactionIdGet$Response.fromJsonFactory);

    return _chainCurrencyTransactionIdGet(currency: currency, id: id);
  }

  ///
  ///@param currency Currency of the chain to query for
  ///@param id Id of the transaction to query
  @Get(path: '/chain/{currency}/transaction/{id}')
  Future<chopper.Response<ChainCurrencyTransactionIdGet$Response>>
      _chainCurrencyTransactionIdGet({
    @Path('currency') required String? currency,
    @Path('id') required String? id,
  });

  ///
  ///@param currency Currency of the chain to broadcast on
  Future<chopper.Response<ChainCurrencyTransactionPost$Response>>
      chainCurrencyTransactionPost({
    required String? currency,
    required ChainCurrencyTransactionPost$RequestBody? body,
  }) {
    generatedMapping.putIfAbsent(ChainCurrencyTransactionPost$Response,
        () => ChainCurrencyTransactionPost$Response.fromJsonFactory);

    return _chainCurrencyTransactionPost(currency: currency, body: body);
  }

  ///
  ///@param currency Currency of the chain to broadcast on
  @Post(
    path: '/chain/{currency}/transaction',
    optionalBody: true,
  )
  Future<chopper.Response<ChainCurrencyTransactionPost$Response>>
      _chainCurrencyTransactionPost({
    @Path('currency') required String? currency,
    @Body() required ChainCurrencyTransactionPost$RequestBody? body,
  });

  ///
  ///@param currency Currency of the chain to query for
  Future<chopper.Response<Contracts>> chainCurrencyContractsGet(
      {required String? currency}) {
    generatedMapping.putIfAbsent(Contracts, () => Contracts.fromJsonFactory);

    return _chainCurrencyContractsGet(currency: currency);
  }

  ///
  ///@param currency Currency of the chain to query for
  @Get(path: '/chain/{currency}/contracts')
  Future<chopper.Response<Contracts>> _chainCurrencyContractsGet(
      {@Path('currency') required String? currency});

  ///
  Future<chopper.Response<VersionGet$Response>> versionGet() {
    generatedMapping.putIfAbsent(
        VersionGet$Response, () => VersionGet$Response.fromJsonFactory);

    return _versionGet();
  }

  ///
  @Get(path: '/version')
  Future<chopper.Response<VersionGet$Response>> _versionGet();

  ///
  Future<chopper.Response<List<String>>> infosGet() {
    return _infosGet();
  }

  ///
  @Get(path: '/infos')
  Future<chopper.Response<List<String>>> _infosGet();

  ///
  Future<chopper.Response<List<String>>> warningsGet() {
    return _warningsGet();
  }

  ///
  @Get(path: '/warnings')
  Future<chopper.Response<List<String>>> _warningsGet();

  ///
  ///@param currency Currency of the lightning network to use
  Future<chopper.Response<LightningCurrencyBolt12FetchPost$Response>>
      lightningCurrencyBolt12FetchPost({
    required String? currency,
    required LightningCurrencyBolt12FetchPost$RequestBody? body,
  }) {
    generatedMapping.putIfAbsent(LightningCurrencyBolt12FetchPost$Response,
        () => LightningCurrencyBolt12FetchPost$Response.fromJsonFactory);

    return _lightningCurrencyBolt12FetchPost(currency: currency, body: body);
  }

  ///
  ///@param currency Currency of the lightning network to use
  @Post(
    path: '/lightning/{currency}/bolt12/fetch',
    optionalBody: true,
  )
  Future<chopper.Response<LightningCurrencyBolt12FetchPost$Response>>
      _lightningCurrencyBolt12FetchPost({
    @Path('currency') required String? currency,
    @Body() required LightningCurrencyBolt12FetchPost$RequestBody? body,
  });

  ///
  Future<chopper.Response<Object>> nodesGet() {
    return _nodesGet();
  }

  ///
  @Get(path: '/nodes')
  Future<chopper.Response<Object>> _nodesGet();

  ///
  Future<chopper.Response<Object>> nodesStatsGet() {
    return _nodesStatsGet();
  }

  ///
  @Get(path: '/nodes/stats')
  Future<chopper.Response<Object>> _nodesStatsGet();

  ///
  ///@param TS Current UNIX timestamp when the request is sent
  ///@param API-KEY Your API key
  ///@param API-HMAC HMAC-SHA256 with your API-Secret as key of the TS + HTTP method (all uppercase) + the HTTP path
  Future<chopper.Response<ReferralGet$Response>> referralGet({
    String? ts,
    String? apikey,
    String? apihmac,
  }) {
    generatedMapping.putIfAbsent(
        ReferralGet$Response, () => ReferralGet$Response.fromJsonFactory);

    return _referralGet(
        ts: ts?.toString(),
        apikey: apikey?.toString(),
        apihmac: apihmac?.toString());
  }

  ///
  ///@param TS Current UNIX timestamp when the request is sent
  ///@param API-KEY Your API key
  ///@param API-HMAC HMAC-SHA256 with your API-Secret as key of the TS + HTTP method (all uppercase) + the HTTP path
  @Get(path: '/referral')
  Future<chopper.Response<ReferralGet$Response>> _referralGet({
    @Header('TS') String? ts,
    @Header('API-KEY') String? apikey,
    @Header('API-HMAC') String? apihmac,
  });

  ///
  ///@param TS Current UNIX timestamp when the request is sent
  ///@param API-KEY Your API key
  ///@param API-HMAC HMAC-SHA256 with your API-Secret as key of the TS + HTTP method (all uppercase) + the HTTP path
  Future<chopper.Response<Object>> referralFeesGet({
    String? ts,
    String? apikey,
    String? apihmac,
  }) {
    return _referralFeesGet(
        ts: ts?.toString(),
        apikey: apikey?.toString(),
        apihmac: apihmac?.toString());
  }

  ///
  ///@param TS Current UNIX timestamp when the request is sent
  ///@param API-KEY Your API key
  ///@param API-HMAC HMAC-SHA256 with your API-Secret as key of the TS + HTTP method (all uppercase) + the HTTP path
  @Get(path: '/referral/fees')
  Future<chopper.Response<Object>> _referralFeesGet({
    @Header('TS') String? ts,
    @Header('API-KEY') String? apikey,
    @Header('API-HMAC') String? apihmac,
  });

  ///
  ///@param TS Current UNIX timestamp when the request is sent
  ///@param API-KEY Your API key
  ///@param API-HMAC HMAC-SHA256 with your API-Secret as key of the TS + HTTP method (all uppercase) + the HTTP path
  Future<chopper.Response<Object>> referralStatsGet({
    String? ts,
    String? apikey,
    String? apihmac,
  }) {
    return _referralStatsGet(
        ts: ts?.toString(),
        apikey: apikey?.toString(),
        apihmac: apihmac?.toString());
  }

  ///
  ///@param TS Current UNIX timestamp when the request is sent
  ///@param API-KEY Your API key
  ///@param API-HMAC HMAC-SHA256 with your API-Secret as key of the TS + HTTP method (all uppercase) + the HTTP path
  @Get(path: '/referral/stats')
  Future<chopper.Response<Object>> _referralStatsGet({
    @Header('TS') String? ts,
    @Header('API-KEY') String? apikey,
    @Header('API-HMAC') String? apihmac,
  });

  ///
  Future<chopper.Response<Object>> swapSubmarineGet() {
    return _swapSubmarineGet();
  }

  ///
  @Get(path: '/swap/submarine')
  Future<chopper.Response<Object>> _swapSubmarineGet();

  ///
  Future<chopper.Response<SubmarineResponse>> swapSubmarinePost(
      {required SubmarineRequest? body}) {
    generatedMapping.putIfAbsent(
        SubmarineResponse, () => SubmarineResponse.fromJsonFactory);

    return _swapSubmarinePost(body: body);
  }

  ///
  @Post(
    path: '/swap/submarine',
    optionalBody: true,
  )
  Future<chopper.Response<SubmarineResponse>> _swapSubmarinePost(
      {@Body() required SubmarineRequest? body});

  ///
  ///@param id ID of the Submarine Swap
  Future<chopper.Response<SwapSubmarineIdInvoicePost$Response>>
      swapSubmarineIdInvoicePost({
    required String? id,
    required SwapSubmarineIdInvoicePost$RequestBody? body,
  }) {
    generatedMapping.putIfAbsent(SwapSubmarineIdInvoicePost$Response,
        () => SwapSubmarineIdInvoicePost$Response.fromJsonFactory);

    return _swapSubmarineIdInvoicePost(id: id, body: body);
  }

  ///
  ///@param id ID of the Submarine Swap
  @Post(
    path: '/swap/submarine/{id}/invoice',
    optionalBody: true,
  )
  Future<chopper.Response<SwapSubmarineIdInvoicePost$Response>>
      _swapSubmarineIdInvoicePost({
    @Path('id') required String? id,
    @Body() required SwapSubmarineIdInvoicePost$RequestBody? body,
  });

  ///
  ///@param id ID of the Submarine Swap
  Future<chopper.Response<SwapSubmarineIdInvoiceAmountGet$Response>>
      swapSubmarineIdInvoiceAmountGet({required String? id}) {
    generatedMapping.putIfAbsent(SwapSubmarineIdInvoiceAmountGet$Response,
        () => SwapSubmarineIdInvoiceAmountGet$Response.fromJsonFactory);

    return _swapSubmarineIdInvoiceAmountGet(id: id);
  }

  ///
  ///@param id ID of the Submarine Swap
  @Get(path: '/swap/submarine/{id}/invoice/amount')
  Future<chopper.Response<SwapSubmarineIdInvoiceAmountGet$Response>>
      _swapSubmarineIdInvoiceAmountGet({@Path('id') required String? id});

  ///
  ///@param id ID of the Submarine Swap
  Future<chopper.Response<SubmarineTransaction>> swapSubmarineIdTransactionGet(
      {required String? id}) {
    generatedMapping.putIfAbsent(
        SubmarineTransaction, () => SubmarineTransaction.fromJsonFactory);

    return _swapSubmarineIdTransactionGet(id: id);
  }

  ///
  ///@param id ID of the Submarine Swap
  @Get(path: '/swap/submarine/{id}/transaction')
  Future<chopper.Response<SubmarineTransaction>> _swapSubmarineIdTransactionGet(
      {@Path('id') required String? id});

  ///
  ///@param id ID of the Submarine Swap
  Future<chopper.Response<SubmarinePreimage>> swapSubmarineIdPreimageGet(
      {required String? id}) {
    generatedMapping.putIfAbsent(
        SubmarinePreimage, () => SubmarinePreimage.fromJsonFactory);

    return _swapSubmarineIdPreimageGet(id: id);
  }

  ///
  ///@param id ID of the Submarine Swap
  @Get(path: '/swap/submarine/{id}/preimage')
  Future<chopper.Response<SubmarinePreimage>> _swapSubmarineIdPreimageGet(
      {@Path('id') required String? id});

  ///
  ///@param id ID or preimage hash of the Swap
  Future<chopper.Response<SwapSubmarineIdRefundGet$Response>>
      swapSubmarineIdRefundGet({required String? id}) {
    generatedMapping.putIfAbsent(SwapSubmarineIdRefundGet$Response,
        () => SwapSubmarineIdRefundGet$Response.fromJsonFactory);

    return _swapSubmarineIdRefundGet(id: id);
  }

  ///
  ///@param id ID or preimage hash of the Swap
  @Get(path: '/swap/submarine/{id}/refund')
  Future<chopper.Response<SwapSubmarineIdRefundGet$Response>>
      _swapSubmarineIdRefundGet({@Path('id') required String? id});

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<PartialSignature>> swapSubmarineIdRefundPost({
    required String? id,
    required RefundRequest? body,
  }) {
    generatedMapping.putIfAbsent(
        PartialSignature, () => PartialSignature.fromJsonFactory);

    return _swapSubmarineIdRefundPost(id: id, body: body);
  }

  ///
  ///@param id ID of the Swap
  @Post(
    path: '/swap/submarine/{id}/refund',
    optionalBody: true,
  )
  Future<chopper.Response<PartialSignature>> _swapSubmarineIdRefundPost({
    @Path('id') required String? id,
    @Body() required RefundRequest? body,
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<SubmarineClaimDetails>> swapSubmarineIdClaimGet(
      {required String? id}) {
    generatedMapping.putIfAbsent(
        SubmarineClaimDetails, () => SubmarineClaimDetails.fromJsonFactory);

    return _swapSubmarineIdClaimGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @Get(path: '/swap/submarine/{id}/claim')
  Future<chopper.Response<SubmarineClaimDetails>> _swapSubmarineIdClaimGet(
      {@Path('id') required String? id});

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<Object>> swapSubmarineIdClaimPost({
    required String? id,
    required PartialSignature? body,
  }) {
    return _swapSubmarineIdClaimPost(id: id, body: body);
  }

  ///
  ///@param id ID of the Swap
  @Post(
    path: '/swap/submarine/{id}/claim',
    optionalBody: true,
  )
  Future<chopper.Response<Object>> _swapSubmarineIdClaimPost({
    @Path('id') required String? id,
    @Body() required PartialSignature? body,
  });

  ///
  Future<chopper.Response<Object>> swapReverseGet() {
    return _swapReverseGet();
  }

  ///
  @Get(path: '/swap/reverse')
  Future<chopper.Response<Object>> _swapReverseGet();

  ///
  Future<chopper.Response<ReverseResponse>> swapReversePost(
      {required ReverseRequest? body}) {
    generatedMapping.putIfAbsent(
        ReverseResponse, () => ReverseResponse.fromJsonFactory);

    return _swapReversePost(body: body);
  }

  ///
  @Post(
    path: '/swap/reverse',
    optionalBody: true,
  )
  Future<chopper.Response<ReverseResponse>> _swapReversePost(
      {@Body() required ReverseRequest? body});

  ///
  ///@param id ID of the Reverse Swap
  Future<chopper.Response<ReverseTransaction>> swapReverseIdTransactionGet(
      {required String? id}) {
    generatedMapping.putIfAbsent(
        ReverseTransaction, () => ReverseTransaction.fromJsonFactory);

    return _swapReverseIdTransactionGet(id: id);
  }

  ///
  ///@param id ID of the Reverse Swap
  @Get(path: '/swap/reverse/{id}/transaction')
  Future<chopper.Response<ReverseTransaction>> _swapReverseIdTransactionGet(
      {@Path('id') required String? id});

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<PartialSignature>> swapReverseIdClaimPost({
    required String? id,
    required ReverseClaimRequest? body,
  }) {
    generatedMapping.putIfAbsent(
        PartialSignature, () => PartialSignature.fromJsonFactory);

    return _swapReverseIdClaimPost(id: id, body: body);
  }

  ///
  ///@param id ID of the Swap
  @Post(
    path: '/swap/reverse/{id}/claim',
    optionalBody: true,
  )
  Future<chopper.Response<PartialSignature>> _swapReverseIdClaimPost({
    @Path('id') required String? id,
    @Body() required ReverseClaimRequest? body,
  });

  ///
  ///@param invoice Invoice of the Reverse Swap
  Future<chopper.Response<ReverseBip21>> swapReverseInvoiceBip21Get(
      {required String? invoice}) {
    generatedMapping.putIfAbsent(
        ReverseBip21, () => ReverseBip21.fromJsonFactory);

    return _swapReverseInvoiceBip21Get(invoice: invoice);
  }

  ///
  ///@param invoice Invoice of the Reverse Swap
  @Get(path: '/swap/reverse/{invoice}/bip21')
  Future<chopper.Response<ReverseBip21>> _swapReverseInvoiceBip21Get(
      {@Path('invoice') required String? invoice});

  ///
  Future<chopper.Response<Object>> swapChainGet() {
    return _swapChainGet();
  }

  ///
  @Get(path: '/swap/chain')
  Future<chopper.Response<Object>> _swapChainGet();

  ///
  Future<chopper.Response<ChainResponse>> swapChainPost(
      {required ChainRequest? body}) {
    generatedMapping.putIfAbsent(
        ChainResponse, () => ChainResponse.fromJsonFactory);

    return _swapChainPost(body: body);
  }

  ///
  @Post(
    path: '/swap/chain',
    optionalBody: true,
  )
  Future<chopper.Response<ChainResponse>> _swapChainPost(
      {@Body() required ChainRequest? body});

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<ChainSwapTransactions>> swapChainIdTransactionsGet(
      {required String? id}) {
    generatedMapping.putIfAbsent(
        ChainSwapTransactions, () => ChainSwapTransactions.fromJsonFactory);

    return _swapChainIdTransactionsGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @Get(path: '/swap/chain/{id}/transactions')
  Future<chopper.Response<ChainSwapTransactions>> _swapChainIdTransactionsGet(
      {@Path('id') required String? id});

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<ChainSwapSigningDetails>> swapChainIdClaimGet(
      {required String? id}) {
    generatedMapping.putIfAbsent(
        ChainSwapSigningDetails, () => ChainSwapSigningDetails.fromJsonFactory);

    return _swapChainIdClaimGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @Get(path: '/swap/chain/{id}/claim')
  Future<chopper.Response<ChainSwapSigningDetails>> _swapChainIdClaimGet(
      {@Path('id') required String? id});

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<PartialSignature>> swapChainIdClaimPost({
    required String? id,
    required ChainSwapSigningRequest? body,
  }) {
    generatedMapping.putIfAbsent(
        PartialSignature, () => PartialSignature.fromJsonFactory);

    return _swapChainIdClaimPost(id: id, body: body);
  }

  ///
  ///@param id ID of the Swap
  @Post(
    path: '/swap/chain/{id}/claim',
    optionalBody: true,
  )
  Future<chopper.Response<PartialSignature>> _swapChainIdClaimPost({
    @Path('id') required String? id,
    @Body() required ChainSwapSigningRequest? body,
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<SwapChainIdRefundGet$Response>> swapChainIdRefundGet(
      {required String? id}) {
    generatedMapping.putIfAbsent(SwapChainIdRefundGet$Response,
        () => SwapChainIdRefundGet$Response.fromJsonFactory);

    return _swapChainIdRefundGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @Get(path: '/swap/chain/{id}/refund')
  Future<chopper.Response<SwapChainIdRefundGet$Response>> _swapChainIdRefundGet(
      {@Path('id') required String? id});

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<PartialSignature>> swapChainIdRefundPost({
    required String? id,
    required RefundRequest? body,
  }) {
    generatedMapping.putIfAbsent(
        PartialSignature, () => PartialSignature.fromJsonFactory);

    return _swapChainIdRefundPost(id: id, body: body);
  }

  ///
  ///@param id ID of the Swap
  @Post(
    path: '/swap/chain/{id}/refund',
    optionalBody: true,
  )
  Future<chopper.Response<PartialSignature>> _swapChainIdRefundPost({
    @Path('id') required String? id,
    @Body() required RefundRequest? body,
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<Quote>> swapChainIdQuoteGet({required String? id}) {
    generatedMapping.putIfAbsent(Quote, () => Quote.fromJsonFactory);

    return _swapChainIdQuoteGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @Get(path: '/swap/chain/{id}/quote')
  Future<chopper.Response<Quote>> _swapChainIdQuoteGet(
      {@Path('id') required String? id});

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<QuoteResponse>> swapChainIdQuotePost({
    required String? id,
    required Quote? body,
  }) {
    generatedMapping.putIfAbsent(
        QuoteResponse, () => QuoteResponse.fromJsonFactory);

    return _swapChainIdQuotePost(id: id, body: body);
  }

  ///
  ///@param id ID of the Swap
  @Post(
    path: '/swap/chain/{id}/quote',
    optionalBody: true,
  )
  Future<chopper.Response<QuoteResponse>> _swapChainIdQuotePost({
    @Path('id') required String? id,
    @Body() required Quote? body,
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<SwapStatus>> swapIdGet({required String? id}) {
    generatedMapping.putIfAbsent(SwapStatus, () => SwapStatus.fromJsonFactory);

    return _swapIdGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @Get(path: '/swap/{id}')
  Future<chopper.Response<SwapStatus>> _swapIdGet(
      {@Path('id') required String? id});
}

@JsonSerializable(explicitToJson: true)
class Contracts {
  const Contracts({
    required this.network,
    required this.swapContracts,
    required this.tokens,
  });

  factory Contracts.fromJson(Map<String, dynamic> json) =>
      _$ContractsFromJson(json);

  static const toJsonFactory = _$ContractsToJson;
  Map<String, dynamic> toJson() => _$ContractsToJson(this);

  @JsonKey(name: 'network', includeIfNull: false)
  final Contracts$Network network;
  @JsonKey(name: 'swapContracts', includeIfNull: false)
  final Contracts$SwapContracts swapContracts;
  @JsonKey(name: 'tokens', includeIfNull: false)
  final Map<String, dynamic> tokens;
  static const fromJsonFactory = _$ContractsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Contracts &&
            (identical(other.network, network) ||
                const DeepCollectionEquality()
                    .equals(other.network, network)) &&
            (identical(other.swapContracts, swapContracts) ||
                const DeepCollectionEquality()
                    .equals(other.swapContracts, swapContracts)) &&
            (identical(other.tokens, tokens) ||
                const DeepCollectionEquality().equals(other.tokens, tokens)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(network) ^
      const DeepCollectionEquality().hash(swapContracts) ^
      const DeepCollectionEquality().hash(tokens) ^
      runtimeType.hashCode;
}

extension $ContractsExtension on Contracts {
  Contracts copyWith(
      {Contracts$Network? network,
      Contracts$SwapContracts? swapContracts,
      Map<String, dynamic>? tokens}) {
    return Contracts(
        network: network ?? this.network,
        swapContracts: swapContracts ?? this.swapContracts,
        tokens: tokens ?? this.tokens);
  }

  Contracts copyWithWrapped(
      {Wrapped<Contracts$Network>? network,
      Wrapped<Contracts$SwapContracts>? swapContracts,
      Wrapped<Map<String, dynamic>>? tokens}) {
    return Contracts(
        network: (network != null ? network.value : this.network),
        swapContracts:
            (swapContracts != null ? swapContracts.value : this.swapContracts),
        tokens: (tokens != null ? tokens.value : this.tokens));
  }
}

@JsonSerializable(explicitToJson: true)
class NodeInfo {
  const NodeInfo({
    required this.publicKey,
    required this.uris,
  });

  factory NodeInfo.fromJson(Map<String, dynamic> json) =>
      _$NodeInfoFromJson(json);

  static const toJsonFactory = _$NodeInfoToJson;
  Map<String, dynamic> toJson() => _$NodeInfoToJson(this);

  @JsonKey(name: 'publicKey', includeIfNull: false)
  final String publicKey;
  @JsonKey(name: 'uris', includeIfNull: false, defaultValue: <String>[])
  final List<String> uris;
  static const fromJsonFactory = _$NodeInfoFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is NodeInfo &&
            (identical(other.publicKey, publicKey) ||
                const DeepCollectionEquality()
                    .equals(other.publicKey, publicKey)) &&
            (identical(other.uris, uris) ||
                const DeepCollectionEquality().equals(other.uris, uris)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(publicKey) ^
      const DeepCollectionEquality().hash(uris) ^
      runtimeType.hashCode;
}

extension $NodeInfoExtension on NodeInfo {
  NodeInfo copyWith({String? publicKey, List<String>? uris}) {
    return NodeInfo(
        publicKey: publicKey ?? this.publicKey, uris: uris ?? this.uris);
  }

  NodeInfo copyWithWrapped(
      {Wrapped<String>? publicKey, Wrapped<List<String>>? uris}) {
    return NodeInfo(
        publicKey: (publicKey != null ? publicKey.value : this.publicKey),
        uris: (uris != null ? uris.value : this.uris));
  }
}

@JsonSerializable(explicitToJson: true)
class NodeStats {
  const NodeStats({
    required this.capacity,
    required this.channels,
    required this.peers,
    required this.oldestChannel,
  });

  factory NodeStats.fromJson(Map<String, dynamic> json) =>
      _$NodeStatsFromJson(json);

  static const toJsonFactory = _$NodeStatsToJson;
  Map<String, dynamic> toJson() => _$NodeStatsToJson(this);

  @JsonKey(name: 'capacity', includeIfNull: false)
  final int capacity;
  @JsonKey(name: 'channels', includeIfNull: false)
  final int channels;
  @JsonKey(name: 'peers', includeIfNull: false)
  final int peers;
  @JsonKey(name: 'oldestChannel', includeIfNull: false)
  final int oldestChannel;
  static const fromJsonFactory = _$NodeStatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is NodeStats &&
            (identical(other.capacity, capacity) ||
                const DeepCollectionEquality()
                    .equals(other.capacity, capacity)) &&
            (identical(other.channels, channels) ||
                const DeepCollectionEquality()
                    .equals(other.channels, channels)) &&
            (identical(other.peers, peers) ||
                const DeepCollectionEquality().equals(other.peers, peers)) &&
            (identical(other.oldestChannel, oldestChannel) ||
                const DeepCollectionEquality()
                    .equals(other.oldestChannel, oldestChannel)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(capacity) ^
      const DeepCollectionEquality().hash(channels) ^
      const DeepCollectionEquality().hash(peers) ^
      const DeepCollectionEquality().hash(oldestChannel) ^
      runtimeType.hashCode;
}

extension $NodeStatsExtension on NodeStats {
  NodeStats copyWith(
      {int? capacity, int? channels, int? peers, int? oldestChannel}) {
    return NodeStats(
        capacity: capacity ?? this.capacity,
        channels: channels ?? this.channels,
        peers: peers ?? this.peers,
        oldestChannel: oldestChannel ?? this.oldestChannel);
  }

  NodeStats copyWithWrapped(
      {Wrapped<int>? capacity,
      Wrapped<int>? channels,
      Wrapped<int>? peers,
      Wrapped<int>? oldestChannel}) {
    return NodeStats(
        capacity: (capacity != null ? capacity.value : this.capacity),
        channels: (channels != null ? channels.value : this.channels),
        peers: (peers != null ? peers.value : this.peers),
        oldestChannel:
            (oldestChannel != null ? oldestChannel.value : this.oldestChannel));
  }
}

@JsonSerializable(explicitToJson: true)
class ErrorResponse {
  const ErrorResponse({
    required this.error,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) =>
      _$ErrorResponseFromJson(json);

  static const toJsonFactory = _$ErrorResponseToJson;
  Map<String, dynamic> toJson() => _$ErrorResponseToJson(this);

  @JsonKey(name: 'error', includeIfNull: false)
  final String error;
  static const fromJsonFactory = _$ErrorResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ErrorResponse &&
            (identical(other.error, error) ||
                const DeepCollectionEquality().equals(other.error, error)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(error) ^ runtimeType.hashCode;
}

extension $ErrorResponseExtension on ErrorResponse {
  ErrorResponse copyWith({String? error}) {
    return ErrorResponse(error: error ?? this.error);
  }

  ErrorResponse copyWithWrapped({Wrapped<String>? error}) {
    return ErrorResponse(error: (error != null ? error.value : this.error));
  }
}

@JsonSerializable(explicitToJson: true)
class SwapTreeLeaf {
  const SwapTreeLeaf({
    required this.version,
    required this.output,
  });

  factory SwapTreeLeaf.fromJson(Map<String, dynamic> json) =>
      _$SwapTreeLeafFromJson(json);

  static const toJsonFactory = _$SwapTreeLeafToJson;
  Map<String, dynamic> toJson() => _$SwapTreeLeafToJson(this);

  @JsonKey(name: 'version', includeIfNull: false)
  final double version;
  @JsonKey(name: 'output', includeIfNull: false)
  final String output;
  static const fromJsonFactory = _$SwapTreeLeafFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SwapTreeLeaf &&
            (identical(other.version, version) ||
                const DeepCollectionEquality()
                    .equals(other.version, version)) &&
            (identical(other.output, output) ||
                const DeepCollectionEquality().equals(other.output, output)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(version) ^
      const DeepCollectionEquality().hash(output) ^
      runtimeType.hashCode;
}

extension $SwapTreeLeafExtension on SwapTreeLeaf {
  SwapTreeLeaf copyWith({double? version, String? output}) {
    return SwapTreeLeaf(
        version: version ?? this.version, output: output ?? this.output);
  }

  SwapTreeLeaf copyWithWrapped(
      {Wrapped<double>? version, Wrapped<String>? output}) {
    return SwapTreeLeaf(
        version: (version != null ? version.value : this.version),
        output: (output != null ? output.value : this.output));
  }
}

@JsonSerializable(explicitToJson: true)
class SwapTree {
  const SwapTree({
    required this.claimLeaf,
    required this.refundLeaf,
  });

  factory SwapTree.fromJson(Map<String, dynamic> json) =>
      _$SwapTreeFromJson(json);

  static const toJsonFactory = _$SwapTreeToJson;
  Map<String, dynamic> toJson() => _$SwapTreeToJson(this);

  @JsonKey(name: 'claimLeaf', includeIfNull: false)
  final SwapTreeLeaf claimLeaf;
  @JsonKey(name: 'refundLeaf', includeIfNull: false)
  final SwapTreeLeaf refundLeaf;
  static const fromJsonFactory = _$SwapTreeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SwapTree &&
            (identical(other.claimLeaf, claimLeaf) ||
                const DeepCollectionEquality()
                    .equals(other.claimLeaf, claimLeaf)) &&
            (identical(other.refundLeaf, refundLeaf) ||
                const DeepCollectionEquality()
                    .equals(other.refundLeaf, refundLeaf)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(claimLeaf) ^
      const DeepCollectionEquality().hash(refundLeaf) ^
      runtimeType.hashCode;
}

extension $SwapTreeExtension on SwapTree {
  SwapTree copyWith({SwapTreeLeaf? claimLeaf, SwapTreeLeaf? refundLeaf}) {
    return SwapTree(
        claimLeaf: claimLeaf ?? this.claimLeaf,
        refundLeaf: refundLeaf ?? this.refundLeaf);
  }

  SwapTree copyWithWrapped(
      {Wrapped<SwapTreeLeaf>? claimLeaf, Wrapped<SwapTreeLeaf>? refundLeaf}) {
    return SwapTree(
        claimLeaf: (claimLeaf != null ? claimLeaf.value : this.claimLeaf),
        refundLeaf: (refundLeaf != null ? refundLeaf.value : this.refundLeaf));
  }
}

@JsonSerializable(explicitToJson: true)
class SubmarinePair {
  const SubmarinePair({
    required this.hash,
    required this.rate,
    required this.limits,
    required this.fees,
  });

  factory SubmarinePair.fromJson(Map<String, dynamic> json) =>
      _$SubmarinePairFromJson(json);

  static const toJsonFactory = _$SubmarinePairToJson;
  Map<String, dynamic> toJson() => _$SubmarinePairToJson(this);

  @JsonKey(name: 'hash', includeIfNull: false)
  final String hash;
  @JsonKey(name: 'rate', includeIfNull: false)
  final double rate;
  @JsonKey(name: 'limits', includeIfNull: false)
  final SubmarinePair$Limits limits;
  @JsonKey(name: 'fees', includeIfNull: false)
  final SubmarinePair$Fees fees;
  static const fromJsonFactory = _$SubmarinePairFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubmarinePair &&
            (identical(other.hash, hash) ||
                const DeepCollectionEquality().equals(other.hash, hash)) &&
            (identical(other.rate, rate) ||
                const DeepCollectionEquality().equals(other.rate, rate)) &&
            (identical(other.limits, limits) ||
                const DeepCollectionEquality().equals(other.limits, limits)) &&
            (identical(other.fees, fees) ||
                const DeepCollectionEquality().equals(other.fees, fees)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(hash) ^
      const DeepCollectionEquality().hash(rate) ^
      const DeepCollectionEquality().hash(limits) ^
      const DeepCollectionEquality().hash(fees) ^
      runtimeType.hashCode;
}

extension $SubmarinePairExtension on SubmarinePair {
  SubmarinePair copyWith(
      {String? hash,
      double? rate,
      SubmarinePair$Limits? limits,
      SubmarinePair$Fees? fees}) {
    return SubmarinePair(
        hash: hash ?? this.hash,
        rate: rate ?? this.rate,
        limits: limits ?? this.limits,
        fees: fees ?? this.fees);
  }

  SubmarinePair copyWithWrapped(
      {Wrapped<String>? hash,
      Wrapped<double>? rate,
      Wrapped<SubmarinePair$Limits>? limits,
      Wrapped<SubmarinePair$Fees>? fees}) {
    return SubmarinePair(
        hash: (hash != null ? hash.value : this.hash),
        rate: (rate != null ? rate.value : this.rate),
        limits: (limits != null ? limits.value : this.limits),
        fees: (fees != null ? fees.value : this.fees));
  }
}

@JsonSerializable(explicitToJson: true)
class WebhookData {
  const WebhookData({
    required this.url,
    this.hashSwapId,
    this.status,
  });

  factory WebhookData.fromJson(Map<String, dynamic> json) =>
      _$WebhookDataFromJson(json);

  static const toJsonFactory = _$WebhookDataToJson;
  Map<String, dynamic> toJson() => _$WebhookDataToJson(this);

  @JsonKey(name: 'url', includeIfNull: false)
  final String url;
  @JsonKey(name: 'hashSwapId', includeIfNull: false, defaultValue: false)
  final bool? hashSwapId;
  @JsonKey(name: 'status', includeIfNull: false, defaultValue: <String>[])
  final List<String>? status;
  static const fromJsonFactory = _$WebhookDataFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is WebhookData &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)) &&
            (identical(other.hashSwapId, hashSwapId) ||
                const DeepCollectionEquality()
                    .equals(other.hashSwapId, hashSwapId)) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(url) ^
      const DeepCollectionEquality().hash(hashSwapId) ^
      const DeepCollectionEquality().hash(status) ^
      runtimeType.hashCode;
}

extension $WebhookDataExtension on WebhookData {
  WebhookData copyWith({String? url, bool? hashSwapId, List<String>? status}) {
    return WebhookData(
        url: url ?? this.url,
        hashSwapId: hashSwapId ?? this.hashSwapId,
        status: status ?? this.status);
  }

  WebhookData copyWithWrapped(
      {Wrapped<String>? url,
      Wrapped<bool?>? hashSwapId,
      Wrapped<List<String>?>? status}) {
    return WebhookData(
        url: (url != null ? url.value : this.url),
        hashSwapId: (hashSwapId != null ? hashSwapId.value : this.hashSwapId),
        status: (status != null ? status.value : this.status));
  }
}

@JsonSerializable(explicitToJson: true)
class SubmarineRequest {
  const SubmarineRequest({
    required this.from,
    required this.to,
    this.invoice,
    this.preimageHash,
    this.refundPublicKey,
    this.pairHash,
    this.referralId,
    this.webhook,
  });

  factory SubmarineRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmarineRequestFromJson(json);

  static const toJsonFactory = _$SubmarineRequestToJson;
  Map<String, dynamic> toJson() => _$SubmarineRequestToJson(this);

  @JsonKey(name: 'from', includeIfNull: false)
  final String from;
  @JsonKey(name: 'to', includeIfNull: false)
  final String to;
  @JsonKey(name: 'invoice', includeIfNull: false)
  final String? invoice;
  @JsonKey(name: 'preimageHash', includeIfNull: false)
  final String? preimageHash;
  @JsonKey(name: 'refundPublicKey', includeIfNull: false)
  final String? refundPublicKey;
  @JsonKey(name: 'pairHash', includeIfNull: false)
  final String? pairHash;
  @JsonKey(name: 'referralId', includeIfNull: false)
  final String? referralId;
  @JsonKey(name: 'webhook', includeIfNull: false)
  final WebhookData? webhook;
  static const fromJsonFactory = _$SubmarineRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubmarineRequest &&
            (identical(other.from, from) ||
                const DeepCollectionEquality().equals(other.from, from)) &&
            (identical(other.to, to) ||
                const DeepCollectionEquality().equals(other.to, to)) &&
            (identical(other.invoice, invoice) ||
                const DeepCollectionEquality()
                    .equals(other.invoice, invoice)) &&
            (identical(other.preimageHash, preimageHash) ||
                const DeepCollectionEquality()
                    .equals(other.preimageHash, preimageHash)) &&
            (identical(other.refundPublicKey, refundPublicKey) ||
                const DeepCollectionEquality()
                    .equals(other.refundPublicKey, refundPublicKey)) &&
            (identical(other.pairHash, pairHash) ||
                const DeepCollectionEquality()
                    .equals(other.pairHash, pairHash)) &&
            (identical(other.referralId, referralId) ||
                const DeepCollectionEquality()
                    .equals(other.referralId, referralId)) &&
            (identical(other.webhook, webhook) ||
                const DeepCollectionEquality().equals(other.webhook, webhook)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(from) ^
      const DeepCollectionEquality().hash(to) ^
      const DeepCollectionEquality().hash(invoice) ^
      const DeepCollectionEquality().hash(preimageHash) ^
      const DeepCollectionEquality().hash(refundPublicKey) ^
      const DeepCollectionEquality().hash(pairHash) ^
      const DeepCollectionEquality().hash(referralId) ^
      const DeepCollectionEquality().hash(webhook) ^
      runtimeType.hashCode;
}

extension $SubmarineRequestExtension on SubmarineRequest {
  SubmarineRequest copyWith(
      {String? from,
      String? to,
      String? invoice,
      String? preimageHash,
      String? refundPublicKey,
      String? pairHash,
      String? referralId,
      WebhookData? webhook}) {
    return SubmarineRequest(
        from: from ?? this.from,
        to: to ?? this.to,
        invoice: invoice ?? this.invoice,
        preimageHash: preimageHash ?? this.preimageHash,
        refundPublicKey: refundPublicKey ?? this.refundPublicKey,
        pairHash: pairHash ?? this.pairHash,
        referralId: referralId ?? this.referralId,
        webhook: webhook ?? this.webhook);
  }

  SubmarineRequest copyWithWrapped(
      {Wrapped<String>? from,
      Wrapped<String>? to,
      Wrapped<String?>? invoice,
      Wrapped<String?>? preimageHash,
      Wrapped<String?>? refundPublicKey,
      Wrapped<String?>? pairHash,
      Wrapped<String?>? referralId,
      Wrapped<WebhookData?>? webhook}) {
    return SubmarineRequest(
        from: (from != null ? from.value : this.from),
        to: (to != null ? to.value : this.to),
        invoice: (invoice != null ? invoice.value : this.invoice),
        preimageHash:
            (preimageHash != null ? preimageHash.value : this.preimageHash),
        refundPublicKey: (refundPublicKey != null
            ? refundPublicKey.value
            : this.refundPublicKey),
        pairHash: (pairHash != null ? pairHash.value : this.pairHash),
        referralId: (referralId != null ? referralId.value : this.referralId),
        webhook: (webhook != null ? webhook.value : this.webhook));
  }
}

@JsonSerializable(explicitToJson: true)
class SubmarineResponse {
  const SubmarineResponse({
    required this.id,
    this.bip21,
    this.address,
    this.swapTree,
    this.claimPublicKey,
    required this.timeoutBlockHeight,
    this.acceptZeroConf,
    required this.expectedAmount,
    this.blindingKey,
    this.referralId,
  });

  factory SubmarineResponse.fromJson(Map<String, dynamic> json) =>
      _$SubmarineResponseFromJson(json);

  static const toJsonFactory = _$SubmarineResponseToJson;
  Map<String, dynamic> toJson() => _$SubmarineResponseToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'bip21', includeIfNull: false)
  final String? bip21;
  @JsonKey(name: 'address', includeIfNull: false)
  final String? address;
  @JsonKey(name: 'swapTree', includeIfNull: false)
  final SwapTree? swapTree;
  @JsonKey(name: 'claimPublicKey', includeIfNull: false)
  final String? claimPublicKey;
  @JsonKey(name: 'timeoutBlockHeight', includeIfNull: false)
  final double timeoutBlockHeight;
  @JsonKey(name: 'acceptZeroConf', includeIfNull: false)
  final bool? acceptZeroConf;
  @JsonKey(name: 'expectedAmount', includeIfNull: false)
  final double expectedAmount;
  @JsonKey(name: 'blindingKey', includeIfNull: false)
  final String? blindingKey;
  @JsonKey(name: 'referralId', includeIfNull: false)
  final String? referralId;
  static const fromJsonFactory = _$SubmarineResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubmarineResponse &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.bip21, bip21) ||
                const DeepCollectionEquality().equals(other.bip21, bip21)) &&
            (identical(other.address, address) ||
                const DeepCollectionEquality()
                    .equals(other.address, address)) &&
            (identical(other.swapTree, swapTree) ||
                const DeepCollectionEquality()
                    .equals(other.swapTree, swapTree)) &&
            (identical(other.claimPublicKey, claimPublicKey) ||
                const DeepCollectionEquality()
                    .equals(other.claimPublicKey, claimPublicKey)) &&
            (identical(other.timeoutBlockHeight, timeoutBlockHeight) ||
                const DeepCollectionEquality()
                    .equals(other.timeoutBlockHeight, timeoutBlockHeight)) &&
            (identical(other.acceptZeroConf, acceptZeroConf) ||
                const DeepCollectionEquality()
                    .equals(other.acceptZeroConf, acceptZeroConf)) &&
            (identical(other.expectedAmount, expectedAmount) ||
                const DeepCollectionEquality()
                    .equals(other.expectedAmount, expectedAmount)) &&
            (identical(other.blindingKey, blindingKey) ||
                const DeepCollectionEquality()
                    .equals(other.blindingKey, blindingKey)) &&
            (identical(other.referralId, referralId) ||
                const DeepCollectionEquality()
                    .equals(other.referralId, referralId)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(bip21) ^
      const DeepCollectionEquality().hash(address) ^
      const DeepCollectionEquality().hash(swapTree) ^
      const DeepCollectionEquality().hash(claimPublicKey) ^
      const DeepCollectionEquality().hash(timeoutBlockHeight) ^
      const DeepCollectionEquality().hash(acceptZeroConf) ^
      const DeepCollectionEquality().hash(expectedAmount) ^
      const DeepCollectionEquality().hash(blindingKey) ^
      const DeepCollectionEquality().hash(referralId) ^
      runtimeType.hashCode;
}

extension $SubmarineResponseExtension on SubmarineResponse {
  SubmarineResponse copyWith(
      {String? id,
      String? bip21,
      String? address,
      SwapTree? swapTree,
      String? claimPublicKey,
      double? timeoutBlockHeight,
      bool? acceptZeroConf,
      double? expectedAmount,
      String? blindingKey,
      String? referralId}) {
    return SubmarineResponse(
        id: id ?? this.id,
        bip21: bip21 ?? this.bip21,
        address: address ?? this.address,
        swapTree: swapTree ?? this.swapTree,
        claimPublicKey: claimPublicKey ?? this.claimPublicKey,
        timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
        acceptZeroConf: acceptZeroConf ?? this.acceptZeroConf,
        expectedAmount: expectedAmount ?? this.expectedAmount,
        blindingKey: blindingKey ?? this.blindingKey,
        referralId: referralId ?? this.referralId);
  }

  SubmarineResponse copyWithWrapped(
      {Wrapped<String>? id,
      Wrapped<String?>? bip21,
      Wrapped<String?>? address,
      Wrapped<SwapTree?>? swapTree,
      Wrapped<String?>? claimPublicKey,
      Wrapped<double>? timeoutBlockHeight,
      Wrapped<bool?>? acceptZeroConf,
      Wrapped<double>? expectedAmount,
      Wrapped<String?>? blindingKey,
      Wrapped<String?>? referralId}) {
    return SubmarineResponse(
        id: (id != null ? id.value : this.id),
        bip21: (bip21 != null ? bip21.value : this.bip21),
        address: (address != null ? address.value : this.address),
        swapTree: (swapTree != null ? swapTree.value : this.swapTree),
        claimPublicKey: (claimPublicKey != null
            ? claimPublicKey.value
            : this.claimPublicKey),
        timeoutBlockHeight: (timeoutBlockHeight != null
            ? timeoutBlockHeight.value
            : this.timeoutBlockHeight),
        acceptZeroConf: (acceptZeroConf != null
            ? acceptZeroConf.value
            : this.acceptZeroConf),
        expectedAmount: (expectedAmount != null
            ? expectedAmount.value
            : this.expectedAmount),
        blindingKey:
            (blindingKey != null ? blindingKey.value : this.blindingKey),
        referralId: (referralId != null ? referralId.value : this.referralId));
  }
}

@JsonSerializable(explicitToJson: true)
class SubmarineTransaction {
  const SubmarineTransaction({
    required this.id,
    this.hex,
    required this.timeoutBlockHeight,
    this.timeoutEta,
  });

  factory SubmarineTransaction.fromJson(Map<String, dynamic> json) =>
      _$SubmarineTransactionFromJson(json);

  static const toJsonFactory = _$SubmarineTransactionToJson;
  Map<String, dynamic> toJson() => _$SubmarineTransactionToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'hex', includeIfNull: false)
  final String? hex;
  @JsonKey(name: 'timeoutBlockHeight', includeIfNull: false)
  final double timeoutBlockHeight;
  @JsonKey(name: 'timeoutEta', includeIfNull: false)
  final double? timeoutEta;
  static const fromJsonFactory = _$SubmarineTransactionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubmarineTransaction &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.hex, hex) ||
                const DeepCollectionEquality().equals(other.hex, hex)) &&
            (identical(other.timeoutBlockHeight, timeoutBlockHeight) ||
                const DeepCollectionEquality()
                    .equals(other.timeoutBlockHeight, timeoutBlockHeight)) &&
            (identical(other.timeoutEta, timeoutEta) ||
                const DeepCollectionEquality()
                    .equals(other.timeoutEta, timeoutEta)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(hex) ^
      const DeepCollectionEquality().hash(timeoutBlockHeight) ^
      const DeepCollectionEquality().hash(timeoutEta) ^
      runtimeType.hashCode;
}

extension $SubmarineTransactionExtension on SubmarineTransaction {
  SubmarineTransaction copyWith(
      {String? id,
      String? hex,
      double? timeoutBlockHeight,
      double? timeoutEta}) {
    return SubmarineTransaction(
        id: id ?? this.id,
        hex: hex ?? this.hex,
        timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
        timeoutEta: timeoutEta ?? this.timeoutEta);
  }

  SubmarineTransaction copyWithWrapped(
      {Wrapped<String>? id,
      Wrapped<String?>? hex,
      Wrapped<double>? timeoutBlockHeight,
      Wrapped<double?>? timeoutEta}) {
    return SubmarineTransaction(
        id: (id != null ? id.value : this.id),
        hex: (hex != null ? hex.value : this.hex),
        timeoutBlockHeight: (timeoutBlockHeight != null
            ? timeoutBlockHeight.value
            : this.timeoutBlockHeight),
        timeoutEta: (timeoutEta != null ? timeoutEta.value : this.timeoutEta));
  }
}

@JsonSerializable(explicitToJson: true)
class SubmarinePreimage {
  const SubmarinePreimage({
    required this.preimage,
  });

  factory SubmarinePreimage.fromJson(Map<String, dynamic> json) =>
      _$SubmarinePreimageFromJson(json);

  static const toJsonFactory = _$SubmarinePreimageToJson;
  Map<String, dynamic> toJson() => _$SubmarinePreimageToJson(this);

  @JsonKey(name: 'preimage', includeIfNull: false)
  final String preimage;
  static const fromJsonFactory = _$SubmarinePreimageFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubmarinePreimage &&
            (identical(other.preimage, preimage) ||
                const DeepCollectionEquality()
                    .equals(other.preimage, preimage)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(preimage) ^ runtimeType.hashCode;
}

extension $SubmarinePreimageExtension on SubmarinePreimage {
  SubmarinePreimage copyWith({String? preimage}) {
    return SubmarinePreimage(preimage: preimage ?? this.preimage);
  }

  SubmarinePreimage copyWithWrapped({Wrapped<String>? preimage}) {
    return SubmarinePreimage(
        preimage: (preimage != null ? preimage.value : this.preimage));
  }
}

@JsonSerializable(explicitToJson: true)
class RefundRequest {
  const RefundRequest({
    required this.pubNonce,
    required this.transaction,
    required this.index,
  });

  factory RefundRequest.fromJson(Map<String, dynamic> json) =>
      _$RefundRequestFromJson(json);

  static const toJsonFactory = _$RefundRequestToJson;
  Map<String, dynamic> toJson() => _$RefundRequestToJson(this);

  @JsonKey(name: 'pubNonce', includeIfNull: false)
  final String pubNonce;
  @JsonKey(name: 'transaction', includeIfNull: false)
  final String transaction;
  @JsonKey(name: 'index', includeIfNull: false)
  final double index;
  static const fromJsonFactory = _$RefundRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RefundRequest &&
            (identical(other.pubNonce, pubNonce) ||
                const DeepCollectionEquality()
                    .equals(other.pubNonce, pubNonce)) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality()
                    .equals(other.transaction, transaction)) &&
            (identical(other.index, index) ||
                const DeepCollectionEquality().equals(other.index, index)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(pubNonce) ^
      const DeepCollectionEquality().hash(transaction) ^
      const DeepCollectionEquality().hash(index) ^
      runtimeType.hashCode;
}

extension $RefundRequestExtension on RefundRequest {
  RefundRequest copyWith(
      {String? pubNonce, String? transaction, double? index}) {
    return RefundRequest(
        pubNonce: pubNonce ?? this.pubNonce,
        transaction: transaction ?? this.transaction,
        index: index ?? this.index);
  }

  RefundRequest copyWithWrapped(
      {Wrapped<String>? pubNonce,
      Wrapped<String>? transaction,
      Wrapped<double>? index}) {
    return RefundRequest(
        pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
        transaction:
            (transaction != null ? transaction.value : this.transaction),
        index: (index != null ? index.value : this.index));
  }
}

@JsonSerializable(explicitToJson: true)
class PartialSignature {
  const PartialSignature({
    required this.pubNonce,
    required this.partialSignature,
  });

  factory PartialSignature.fromJson(Map<String, dynamic> json) =>
      _$PartialSignatureFromJson(json);

  static const toJsonFactory = _$PartialSignatureToJson;
  Map<String, dynamic> toJson() => _$PartialSignatureToJson(this);

  @JsonKey(name: 'pubNonce', includeIfNull: false)
  final String pubNonce;
  @JsonKey(name: 'partialSignature', includeIfNull: false)
  final String partialSignature;
  static const fromJsonFactory = _$PartialSignatureFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PartialSignature &&
            (identical(other.pubNonce, pubNonce) ||
                const DeepCollectionEquality()
                    .equals(other.pubNonce, pubNonce)) &&
            (identical(other.partialSignature, partialSignature) ||
                const DeepCollectionEquality()
                    .equals(other.partialSignature, partialSignature)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(pubNonce) ^
      const DeepCollectionEquality().hash(partialSignature) ^
      runtimeType.hashCode;
}

extension $PartialSignatureExtension on PartialSignature {
  PartialSignature copyWith({String? pubNonce, String? partialSignature}) {
    return PartialSignature(
        pubNonce: pubNonce ?? this.pubNonce,
        partialSignature: partialSignature ?? this.partialSignature);
  }

  PartialSignature copyWithWrapped(
      {Wrapped<String>? pubNonce, Wrapped<String>? partialSignature}) {
    return PartialSignature(
        pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
        partialSignature: (partialSignature != null
            ? partialSignature.value
            : this.partialSignature));
  }
}

@JsonSerializable(explicitToJson: true)
class SubmarineClaimDetails {
  const SubmarineClaimDetails({
    required this.preimage,
    required this.pubNonce,
    required this.publicKey,
    required this.transactionHash,
  });

  factory SubmarineClaimDetails.fromJson(Map<String, dynamic> json) =>
      _$SubmarineClaimDetailsFromJson(json);

  static const toJsonFactory = _$SubmarineClaimDetailsToJson;
  Map<String, dynamic> toJson() => _$SubmarineClaimDetailsToJson(this);

  @JsonKey(name: 'preimage', includeIfNull: false)
  final String preimage;
  @JsonKey(name: 'pubNonce', includeIfNull: false)
  final String pubNonce;
  @JsonKey(name: 'publicKey', includeIfNull: false)
  final String publicKey;
  @JsonKey(name: 'transactionHash', includeIfNull: false)
  final String transactionHash;
  static const fromJsonFactory = _$SubmarineClaimDetailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubmarineClaimDetails &&
            (identical(other.preimage, preimage) ||
                const DeepCollectionEquality()
                    .equals(other.preimage, preimage)) &&
            (identical(other.pubNonce, pubNonce) ||
                const DeepCollectionEquality()
                    .equals(other.pubNonce, pubNonce)) &&
            (identical(other.publicKey, publicKey) ||
                const DeepCollectionEquality()
                    .equals(other.publicKey, publicKey)) &&
            (identical(other.transactionHash, transactionHash) ||
                const DeepCollectionEquality()
                    .equals(other.transactionHash, transactionHash)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(preimage) ^
      const DeepCollectionEquality().hash(pubNonce) ^
      const DeepCollectionEquality().hash(publicKey) ^
      const DeepCollectionEquality().hash(transactionHash) ^
      runtimeType.hashCode;
}

extension $SubmarineClaimDetailsExtension on SubmarineClaimDetails {
  SubmarineClaimDetails copyWith(
      {String? preimage,
      String? pubNonce,
      String? publicKey,
      String? transactionHash}) {
    return SubmarineClaimDetails(
        preimage: preimage ?? this.preimage,
        pubNonce: pubNonce ?? this.pubNonce,
        publicKey: publicKey ?? this.publicKey,
        transactionHash: transactionHash ?? this.transactionHash);
  }

  SubmarineClaimDetails copyWithWrapped(
      {Wrapped<String>? preimage,
      Wrapped<String>? pubNonce,
      Wrapped<String>? publicKey,
      Wrapped<String>? transactionHash}) {
    return SubmarineClaimDetails(
        preimage: (preimage != null ? preimage.value : this.preimage),
        pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
        publicKey: (publicKey != null ? publicKey.value : this.publicKey),
        transactionHash: (transactionHash != null
            ? transactionHash.value
            : this.transactionHash));
  }
}

@JsonSerializable(explicitToJson: true)
class ReversePair {
  const ReversePair({
    required this.hash,
    required this.rate,
    required this.limits,
    required this.fees,
  });

  factory ReversePair.fromJson(Map<String, dynamic> json) =>
      _$ReversePairFromJson(json);

  static const toJsonFactory = _$ReversePairToJson;
  Map<String, dynamic> toJson() => _$ReversePairToJson(this);

  @JsonKey(name: 'hash', includeIfNull: false)
  final String hash;
  @JsonKey(name: 'rate', includeIfNull: false)
  final double rate;
  @JsonKey(name: 'limits', includeIfNull: false)
  final ReversePair$Limits limits;
  @JsonKey(name: 'fees', includeIfNull: false)
  final ReversePair$Fees fees;
  static const fromJsonFactory = _$ReversePairFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReversePair &&
            (identical(other.hash, hash) ||
                const DeepCollectionEquality().equals(other.hash, hash)) &&
            (identical(other.rate, rate) ||
                const DeepCollectionEquality().equals(other.rate, rate)) &&
            (identical(other.limits, limits) ||
                const DeepCollectionEquality().equals(other.limits, limits)) &&
            (identical(other.fees, fees) ||
                const DeepCollectionEquality().equals(other.fees, fees)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(hash) ^
      const DeepCollectionEquality().hash(rate) ^
      const DeepCollectionEquality().hash(limits) ^
      const DeepCollectionEquality().hash(fees) ^
      runtimeType.hashCode;
}

extension $ReversePairExtension on ReversePair {
  ReversePair copyWith(
      {String? hash,
      double? rate,
      ReversePair$Limits? limits,
      ReversePair$Fees? fees}) {
    return ReversePair(
        hash: hash ?? this.hash,
        rate: rate ?? this.rate,
        limits: limits ?? this.limits,
        fees: fees ?? this.fees);
  }

  ReversePair copyWithWrapped(
      {Wrapped<String>? hash,
      Wrapped<double>? rate,
      Wrapped<ReversePair$Limits>? limits,
      Wrapped<ReversePair$Fees>? fees}) {
    return ReversePair(
        hash: (hash != null ? hash.value : this.hash),
        rate: (rate != null ? rate.value : this.rate),
        limits: (limits != null ? limits.value : this.limits),
        fees: (fees != null ? fees.value : this.fees));
  }
}

@JsonSerializable(explicitToJson: true)
class ReverseRequest {
  const ReverseRequest({
    required this.from,
    required this.to,
    required this.preimageHash,
    this.claimPublicKey,
    this.claimAddress,
    this.invoiceAmount,
    this.onchainAmount,
    this.pairHash,
    this.referralId,
    this.address,
    this.addressSignature,
    this.claimCovenant,
    this.description,
    this.descriptionHash,
    this.invoiceExpiry,
    this.webhook,
  });

  factory ReverseRequest.fromJson(Map<String, dynamic> json) =>
      _$ReverseRequestFromJson(json);

  static const toJsonFactory = _$ReverseRequestToJson;
  Map<String, dynamic> toJson() => _$ReverseRequestToJson(this);

  @JsonKey(name: 'from', includeIfNull: false)
  final String from;
  @JsonKey(name: 'to', includeIfNull: false)
  final String to;
  @JsonKey(name: 'preimageHash', includeIfNull: false)
  final String preimageHash;
  @JsonKey(name: 'claimPublicKey', includeIfNull: false)
  final String? claimPublicKey;
  @JsonKey(name: 'claimAddress', includeIfNull: false)
  final String? claimAddress;
  @JsonKey(name: 'invoiceAmount', includeIfNull: false)
  final double? invoiceAmount;
  @JsonKey(name: 'onchainAmount', includeIfNull: false)
  final double? onchainAmount;
  @JsonKey(name: 'pairHash', includeIfNull: false)
  final String? pairHash;
  @JsonKey(name: 'referralId', includeIfNull: false)
  final String? referralId;
  @JsonKey(name: 'address', includeIfNull: false)
  final String? address;
  @JsonKey(name: 'addressSignature', includeIfNull: false)
  final String? addressSignature;
  @JsonKey(name: 'claimCovenant', includeIfNull: false, defaultValue: false)
  final bool? claimCovenant;
  @JsonKey(name: 'description', includeIfNull: false)
  final String? description;
  @JsonKey(name: 'descriptionHash', includeIfNull: false)
  final String? descriptionHash;
  @JsonKey(name: 'invoiceExpiry', includeIfNull: false)
  final double? invoiceExpiry;
  @JsonKey(name: 'webhook', includeIfNull: false)
  final WebhookData? webhook;
  static const fromJsonFactory = _$ReverseRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReverseRequest &&
            (identical(other.from, from) ||
                const DeepCollectionEquality().equals(other.from, from)) &&
            (identical(other.to, to) ||
                const DeepCollectionEquality().equals(other.to, to)) &&
            (identical(other.preimageHash, preimageHash) ||
                const DeepCollectionEquality()
                    .equals(other.preimageHash, preimageHash)) &&
            (identical(other.claimPublicKey, claimPublicKey) ||
                const DeepCollectionEquality()
                    .equals(other.claimPublicKey, claimPublicKey)) &&
            (identical(other.claimAddress, claimAddress) ||
                const DeepCollectionEquality()
                    .equals(other.claimAddress, claimAddress)) &&
            (identical(other.invoiceAmount, invoiceAmount) ||
                const DeepCollectionEquality()
                    .equals(other.invoiceAmount, invoiceAmount)) &&
            (identical(other.onchainAmount, onchainAmount) ||
                const DeepCollectionEquality()
                    .equals(other.onchainAmount, onchainAmount)) &&
            (identical(other.pairHash, pairHash) ||
                const DeepCollectionEquality()
                    .equals(other.pairHash, pairHash)) &&
            (identical(other.referralId, referralId) ||
                const DeepCollectionEquality()
                    .equals(other.referralId, referralId)) &&
            (identical(other.address, address) ||
                const DeepCollectionEquality()
                    .equals(other.address, address)) &&
            (identical(other.addressSignature, addressSignature) ||
                const DeepCollectionEquality()
                    .equals(other.addressSignature, addressSignature)) &&
            (identical(other.claimCovenant, claimCovenant) ||
                const DeepCollectionEquality()
                    .equals(other.claimCovenant, claimCovenant)) &&
            (identical(other.description, description) ||
                const DeepCollectionEquality()
                    .equals(other.description, description)) &&
            (identical(other.descriptionHash, descriptionHash) ||
                const DeepCollectionEquality()
                    .equals(other.descriptionHash, descriptionHash)) &&
            (identical(other.invoiceExpiry, invoiceExpiry) ||
                const DeepCollectionEquality()
                    .equals(other.invoiceExpiry, invoiceExpiry)) &&
            (identical(other.webhook, webhook) ||
                const DeepCollectionEquality().equals(other.webhook, webhook)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(from) ^
      const DeepCollectionEquality().hash(to) ^
      const DeepCollectionEquality().hash(preimageHash) ^
      const DeepCollectionEquality().hash(claimPublicKey) ^
      const DeepCollectionEquality().hash(claimAddress) ^
      const DeepCollectionEquality().hash(invoiceAmount) ^
      const DeepCollectionEquality().hash(onchainAmount) ^
      const DeepCollectionEquality().hash(pairHash) ^
      const DeepCollectionEquality().hash(referralId) ^
      const DeepCollectionEquality().hash(address) ^
      const DeepCollectionEquality().hash(addressSignature) ^
      const DeepCollectionEquality().hash(claimCovenant) ^
      const DeepCollectionEquality().hash(description) ^
      const DeepCollectionEquality().hash(descriptionHash) ^
      const DeepCollectionEquality().hash(invoiceExpiry) ^
      const DeepCollectionEquality().hash(webhook) ^
      runtimeType.hashCode;
}

extension $ReverseRequestExtension on ReverseRequest {
  ReverseRequest copyWith(
      {String? from,
      String? to,
      String? preimageHash,
      String? claimPublicKey,
      String? claimAddress,
      double? invoiceAmount,
      double? onchainAmount,
      String? pairHash,
      String? referralId,
      String? address,
      String? addressSignature,
      bool? claimCovenant,
      String? description,
      String? descriptionHash,
      double? invoiceExpiry,
      WebhookData? webhook}) {
    return ReverseRequest(
        from: from ?? this.from,
        to: to ?? this.to,
        preimageHash: preimageHash ?? this.preimageHash,
        claimPublicKey: claimPublicKey ?? this.claimPublicKey,
        claimAddress: claimAddress ?? this.claimAddress,
        invoiceAmount: invoiceAmount ?? this.invoiceAmount,
        onchainAmount: onchainAmount ?? this.onchainAmount,
        pairHash: pairHash ?? this.pairHash,
        referralId: referralId ?? this.referralId,
        address: address ?? this.address,
        addressSignature: addressSignature ?? this.addressSignature,
        claimCovenant: claimCovenant ?? this.claimCovenant,
        description: description ?? this.description,
        descriptionHash: descriptionHash ?? this.descriptionHash,
        invoiceExpiry: invoiceExpiry ?? this.invoiceExpiry,
        webhook: webhook ?? this.webhook);
  }

  ReverseRequest copyWithWrapped(
      {Wrapped<String>? from,
      Wrapped<String>? to,
      Wrapped<String>? preimageHash,
      Wrapped<String?>? claimPublicKey,
      Wrapped<String?>? claimAddress,
      Wrapped<double?>? invoiceAmount,
      Wrapped<double?>? onchainAmount,
      Wrapped<String?>? pairHash,
      Wrapped<String?>? referralId,
      Wrapped<String?>? address,
      Wrapped<String?>? addressSignature,
      Wrapped<bool?>? claimCovenant,
      Wrapped<String?>? description,
      Wrapped<String?>? descriptionHash,
      Wrapped<double?>? invoiceExpiry,
      Wrapped<WebhookData?>? webhook}) {
    return ReverseRequest(
        from: (from != null ? from.value : this.from),
        to: (to != null ? to.value : this.to),
        preimageHash:
            (preimageHash != null ? preimageHash.value : this.preimageHash),
        claimPublicKey: (claimPublicKey != null
            ? claimPublicKey.value
            : this.claimPublicKey),
        claimAddress:
            (claimAddress != null ? claimAddress.value : this.claimAddress),
        invoiceAmount:
            (invoiceAmount != null ? invoiceAmount.value : this.invoiceAmount),
        onchainAmount:
            (onchainAmount != null ? onchainAmount.value : this.onchainAmount),
        pairHash: (pairHash != null ? pairHash.value : this.pairHash),
        referralId: (referralId != null ? referralId.value : this.referralId),
        address: (address != null ? address.value : this.address),
        addressSignature: (addressSignature != null
            ? addressSignature.value
            : this.addressSignature),
        claimCovenant:
            (claimCovenant != null ? claimCovenant.value : this.claimCovenant),
        description:
            (description != null ? description.value : this.description),
        descriptionHash: (descriptionHash != null
            ? descriptionHash.value
            : this.descriptionHash),
        invoiceExpiry:
            (invoiceExpiry != null ? invoiceExpiry.value : this.invoiceExpiry),
        webhook: (webhook != null ? webhook.value : this.webhook));
  }
}

@JsonSerializable(explicitToJson: true)
class ReverseResponse {
  const ReverseResponse({
    required this.id,
    required this.invoice,
    this.swapTree,
    this.lockupAddress,
    this.refundPublicKey,
    required this.timeoutBlockHeight,
    this.onchainAmount,
    this.blindingKey,
    this.referralId,
  });

  factory ReverseResponse.fromJson(Map<String, dynamic> json) =>
      _$ReverseResponseFromJson(json);

  static const toJsonFactory = _$ReverseResponseToJson;
  Map<String, dynamic> toJson() => _$ReverseResponseToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'invoice', includeIfNull: false)
  final String invoice;
  @JsonKey(name: 'swapTree', includeIfNull: false)
  final SwapTree? swapTree;
  @JsonKey(name: 'lockupAddress', includeIfNull: false)
  final String? lockupAddress;
  @JsonKey(name: 'refundPublicKey', includeIfNull: false)
  final String? refundPublicKey;
  @JsonKey(name: 'timeoutBlockHeight', includeIfNull: false)
  final double timeoutBlockHeight;
  @JsonKey(name: 'onchainAmount', includeIfNull: false)
  final double? onchainAmount;
  @JsonKey(name: 'blindingKey', includeIfNull: false)
  final String? blindingKey;
  @JsonKey(name: 'referralId', includeIfNull: false)
  final String? referralId;
  static const fromJsonFactory = _$ReverseResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReverseResponse &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.invoice, invoice) ||
                const DeepCollectionEquality()
                    .equals(other.invoice, invoice)) &&
            (identical(other.swapTree, swapTree) ||
                const DeepCollectionEquality()
                    .equals(other.swapTree, swapTree)) &&
            (identical(other.lockupAddress, lockupAddress) ||
                const DeepCollectionEquality()
                    .equals(other.lockupAddress, lockupAddress)) &&
            (identical(other.refundPublicKey, refundPublicKey) ||
                const DeepCollectionEquality()
                    .equals(other.refundPublicKey, refundPublicKey)) &&
            (identical(other.timeoutBlockHeight, timeoutBlockHeight) ||
                const DeepCollectionEquality()
                    .equals(other.timeoutBlockHeight, timeoutBlockHeight)) &&
            (identical(other.onchainAmount, onchainAmount) ||
                const DeepCollectionEquality()
                    .equals(other.onchainAmount, onchainAmount)) &&
            (identical(other.blindingKey, blindingKey) ||
                const DeepCollectionEquality()
                    .equals(other.blindingKey, blindingKey)) &&
            (identical(other.referralId, referralId) ||
                const DeepCollectionEquality()
                    .equals(other.referralId, referralId)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(invoice) ^
      const DeepCollectionEquality().hash(swapTree) ^
      const DeepCollectionEquality().hash(lockupAddress) ^
      const DeepCollectionEquality().hash(refundPublicKey) ^
      const DeepCollectionEquality().hash(timeoutBlockHeight) ^
      const DeepCollectionEquality().hash(onchainAmount) ^
      const DeepCollectionEquality().hash(blindingKey) ^
      const DeepCollectionEquality().hash(referralId) ^
      runtimeType.hashCode;
}

extension $ReverseResponseExtension on ReverseResponse {
  ReverseResponse copyWith(
      {String? id,
      String? invoice,
      SwapTree? swapTree,
      String? lockupAddress,
      String? refundPublicKey,
      double? timeoutBlockHeight,
      double? onchainAmount,
      String? blindingKey,
      String? referralId}) {
    return ReverseResponse(
        id: id ?? this.id,
        invoice: invoice ?? this.invoice,
        swapTree: swapTree ?? this.swapTree,
        lockupAddress: lockupAddress ?? this.lockupAddress,
        refundPublicKey: refundPublicKey ?? this.refundPublicKey,
        timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
        onchainAmount: onchainAmount ?? this.onchainAmount,
        blindingKey: blindingKey ?? this.blindingKey,
        referralId: referralId ?? this.referralId);
  }

  ReverseResponse copyWithWrapped(
      {Wrapped<String>? id,
      Wrapped<String>? invoice,
      Wrapped<SwapTree?>? swapTree,
      Wrapped<String?>? lockupAddress,
      Wrapped<String?>? refundPublicKey,
      Wrapped<double>? timeoutBlockHeight,
      Wrapped<double?>? onchainAmount,
      Wrapped<String?>? blindingKey,
      Wrapped<String?>? referralId}) {
    return ReverseResponse(
        id: (id != null ? id.value : this.id),
        invoice: (invoice != null ? invoice.value : this.invoice),
        swapTree: (swapTree != null ? swapTree.value : this.swapTree),
        lockupAddress:
            (lockupAddress != null ? lockupAddress.value : this.lockupAddress),
        refundPublicKey: (refundPublicKey != null
            ? refundPublicKey.value
            : this.refundPublicKey),
        timeoutBlockHeight: (timeoutBlockHeight != null
            ? timeoutBlockHeight.value
            : this.timeoutBlockHeight),
        onchainAmount:
            (onchainAmount != null ? onchainAmount.value : this.onchainAmount),
        blindingKey:
            (blindingKey != null ? blindingKey.value : this.blindingKey),
        referralId: (referralId != null ? referralId.value : this.referralId));
  }
}

@JsonSerializable(explicitToJson: true)
class ReverseTransaction {
  const ReverseTransaction({
    required this.id,
    this.hex,
    required this.timeoutBlockHeight,
  });

  factory ReverseTransaction.fromJson(Map<String, dynamic> json) =>
      _$ReverseTransactionFromJson(json);

  static const toJsonFactory = _$ReverseTransactionToJson;
  Map<String, dynamic> toJson() => _$ReverseTransactionToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'hex', includeIfNull: false)
  final String? hex;
  @JsonKey(name: 'timeoutBlockHeight', includeIfNull: false)
  final double timeoutBlockHeight;
  static const fromJsonFactory = _$ReverseTransactionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReverseTransaction &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.hex, hex) ||
                const DeepCollectionEquality().equals(other.hex, hex)) &&
            (identical(other.timeoutBlockHeight, timeoutBlockHeight) ||
                const DeepCollectionEquality()
                    .equals(other.timeoutBlockHeight, timeoutBlockHeight)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(hex) ^
      const DeepCollectionEquality().hash(timeoutBlockHeight) ^
      runtimeType.hashCode;
}

extension $ReverseTransactionExtension on ReverseTransaction {
  ReverseTransaction copyWith(
      {String? id, String? hex, double? timeoutBlockHeight}) {
    return ReverseTransaction(
        id: id ?? this.id,
        hex: hex ?? this.hex,
        timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight);
  }

  ReverseTransaction copyWithWrapped(
      {Wrapped<String>? id,
      Wrapped<String?>? hex,
      Wrapped<double>? timeoutBlockHeight}) {
    return ReverseTransaction(
        id: (id != null ? id.value : this.id),
        hex: (hex != null ? hex.value : this.hex),
        timeoutBlockHeight: (timeoutBlockHeight != null
            ? timeoutBlockHeight.value
            : this.timeoutBlockHeight));
  }
}

@JsonSerializable(explicitToJson: true)
class ReverseClaimRequest {
  const ReverseClaimRequest({
    required this.preimage,
    this.pubNonce,
    this.transaction,
    this.index,
  });

  factory ReverseClaimRequest.fromJson(Map<String, dynamic> json) =>
      _$ReverseClaimRequestFromJson(json);

  static const toJsonFactory = _$ReverseClaimRequestToJson;
  Map<String, dynamic> toJson() => _$ReverseClaimRequestToJson(this);

  @JsonKey(name: 'preimage', includeIfNull: false)
  final String preimage;
  @JsonKey(name: 'pubNonce', includeIfNull: false)
  final String? pubNonce;
  @JsonKey(name: 'transaction', includeIfNull: false)
  final String? transaction;
  @JsonKey(name: 'index', includeIfNull: false)
  final double? index;
  static const fromJsonFactory = _$ReverseClaimRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReverseClaimRequest &&
            (identical(other.preimage, preimage) ||
                const DeepCollectionEquality()
                    .equals(other.preimage, preimage)) &&
            (identical(other.pubNonce, pubNonce) ||
                const DeepCollectionEquality()
                    .equals(other.pubNonce, pubNonce)) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality()
                    .equals(other.transaction, transaction)) &&
            (identical(other.index, index) ||
                const DeepCollectionEquality().equals(other.index, index)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(preimage) ^
      const DeepCollectionEquality().hash(pubNonce) ^
      const DeepCollectionEquality().hash(transaction) ^
      const DeepCollectionEquality().hash(index) ^
      runtimeType.hashCode;
}

extension $ReverseClaimRequestExtension on ReverseClaimRequest {
  ReverseClaimRequest copyWith(
      {String? preimage,
      String? pubNonce,
      String? transaction,
      double? index}) {
    return ReverseClaimRequest(
        preimage: preimage ?? this.preimage,
        pubNonce: pubNonce ?? this.pubNonce,
        transaction: transaction ?? this.transaction,
        index: index ?? this.index);
  }

  ReverseClaimRequest copyWithWrapped(
      {Wrapped<String>? preimage,
      Wrapped<String?>? pubNonce,
      Wrapped<String?>? transaction,
      Wrapped<double?>? index}) {
    return ReverseClaimRequest(
        preimage: (preimage != null ? preimage.value : this.preimage),
        pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
        transaction:
            (transaction != null ? transaction.value : this.transaction),
        index: (index != null ? index.value : this.index));
  }
}

@JsonSerializable(explicitToJson: true)
class ReverseBip21 {
  const ReverseBip21({
    this.bip21,
    required this.signature,
  });

  factory ReverseBip21.fromJson(Map<String, dynamic> json) =>
      _$ReverseBip21FromJson(json);

  static const toJsonFactory = _$ReverseBip21ToJson;
  Map<String, dynamic> toJson() => _$ReverseBip21ToJson(this);

  @JsonKey(name: 'bip21', includeIfNull: false)
  final String? bip21;
  @JsonKey(name: 'signature', includeIfNull: false)
  final String signature;
  static const fromJsonFactory = _$ReverseBip21FromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReverseBip21 &&
            (identical(other.bip21, bip21) ||
                const DeepCollectionEquality().equals(other.bip21, bip21)) &&
            (identical(other.signature, signature) ||
                const DeepCollectionEquality()
                    .equals(other.signature, signature)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(bip21) ^
      const DeepCollectionEquality().hash(signature) ^
      runtimeType.hashCode;
}

extension $ReverseBip21Extension on ReverseBip21 {
  ReverseBip21 copyWith({String? bip21, String? signature}) {
    return ReverseBip21(
        bip21: bip21 ?? this.bip21, signature: signature ?? this.signature);
  }

  ReverseBip21 copyWithWrapped(
      {Wrapped<String?>? bip21, Wrapped<String>? signature}) {
    return ReverseBip21(
        bip21: (bip21 != null ? bip21.value : this.bip21),
        signature: (signature != null ? signature.value : this.signature));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainPair {
  const ChainPair({
    required this.hash,
    required this.rate,
    required this.limits,
    required this.fees,
  });

  factory ChainPair.fromJson(Map<String, dynamic> json) =>
      _$ChainPairFromJson(json);

  static const toJsonFactory = _$ChainPairToJson;
  Map<String, dynamic> toJson() => _$ChainPairToJson(this);

  @JsonKey(name: 'hash', includeIfNull: false)
  final String hash;
  @JsonKey(name: 'rate', includeIfNull: false)
  final double rate;
  @JsonKey(name: 'limits', includeIfNull: false)
  final ChainPair$Limits limits;
  @JsonKey(name: 'fees', includeIfNull: false)
  final ChainPair$Fees fees;
  static const fromJsonFactory = _$ChainPairFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainPair &&
            (identical(other.hash, hash) ||
                const DeepCollectionEquality().equals(other.hash, hash)) &&
            (identical(other.rate, rate) ||
                const DeepCollectionEquality().equals(other.rate, rate)) &&
            (identical(other.limits, limits) ||
                const DeepCollectionEquality().equals(other.limits, limits)) &&
            (identical(other.fees, fees) ||
                const DeepCollectionEquality().equals(other.fees, fees)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(hash) ^
      const DeepCollectionEquality().hash(rate) ^
      const DeepCollectionEquality().hash(limits) ^
      const DeepCollectionEquality().hash(fees) ^
      runtimeType.hashCode;
}

extension $ChainPairExtension on ChainPair {
  ChainPair copyWith(
      {String? hash,
      double? rate,
      ChainPair$Limits? limits,
      ChainPair$Fees? fees}) {
    return ChainPair(
        hash: hash ?? this.hash,
        rate: rate ?? this.rate,
        limits: limits ?? this.limits,
        fees: fees ?? this.fees);
  }

  ChainPair copyWithWrapped(
      {Wrapped<String>? hash,
      Wrapped<double>? rate,
      Wrapped<ChainPair$Limits>? limits,
      Wrapped<ChainPair$Fees>? fees}) {
    return ChainPair(
        hash: (hash != null ? hash.value : this.hash),
        rate: (rate != null ? rate.value : this.rate),
        limits: (limits != null ? limits.value : this.limits),
        fees: (fees != null ? fees.value : this.fees));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainRequest {
  const ChainRequest({
    required this.from,
    required this.to,
    required this.preimageHash,
    this.claimPublicKey,
    this.refundPublicKey,
    this.claimAddress,
    this.userLockAmount,
    this.serverLockAmount,
    this.pairHash,
    this.referralId,
    this.webhook,
  });

  factory ChainRequest.fromJson(Map<String, dynamic> json) =>
      _$ChainRequestFromJson(json);

  static const toJsonFactory = _$ChainRequestToJson;
  Map<String, dynamic> toJson() => _$ChainRequestToJson(this);

  @JsonKey(name: 'from', includeIfNull: false)
  final String from;
  @JsonKey(name: 'to', includeIfNull: false)
  final String to;
  @JsonKey(name: 'preimageHash', includeIfNull: false)
  final String preimageHash;
  @JsonKey(name: 'claimPublicKey', includeIfNull: false)
  final String? claimPublicKey;
  @JsonKey(name: 'refundPublicKey', includeIfNull: false)
  final String? refundPublicKey;
  @JsonKey(name: 'claimAddress', includeIfNull: false)
  final String? claimAddress;
  @JsonKey(name: 'userLockAmount', includeIfNull: false)
  final double? userLockAmount;
  @JsonKey(name: 'serverLockAmount', includeIfNull: false)
  final double? serverLockAmount;
  @JsonKey(name: 'pairHash', includeIfNull: false)
  final String? pairHash;
  @JsonKey(name: 'referralId', includeIfNull: false)
  final String? referralId;
  @JsonKey(name: 'webhook', includeIfNull: false)
  final WebhookData? webhook;
  static const fromJsonFactory = _$ChainRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainRequest &&
            (identical(other.from, from) ||
                const DeepCollectionEquality().equals(other.from, from)) &&
            (identical(other.to, to) ||
                const DeepCollectionEquality().equals(other.to, to)) &&
            (identical(other.preimageHash, preimageHash) ||
                const DeepCollectionEquality()
                    .equals(other.preimageHash, preimageHash)) &&
            (identical(other.claimPublicKey, claimPublicKey) ||
                const DeepCollectionEquality()
                    .equals(other.claimPublicKey, claimPublicKey)) &&
            (identical(other.refundPublicKey, refundPublicKey) ||
                const DeepCollectionEquality()
                    .equals(other.refundPublicKey, refundPublicKey)) &&
            (identical(other.claimAddress, claimAddress) ||
                const DeepCollectionEquality()
                    .equals(other.claimAddress, claimAddress)) &&
            (identical(other.userLockAmount, userLockAmount) ||
                const DeepCollectionEquality()
                    .equals(other.userLockAmount, userLockAmount)) &&
            (identical(other.serverLockAmount, serverLockAmount) ||
                const DeepCollectionEquality()
                    .equals(other.serverLockAmount, serverLockAmount)) &&
            (identical(other.pairHash, pairHash) ||
                const DeepCollectionEquality()
                    .equals(other.pairHash, pairHash)) &&
            (identical(other.referralId, referralId) ||
                const DeepCollectionEquality()
                    .equals(other.referralId, referralId)) &&
            (identical(other.webhook, webhook) ||
                const DeepCollectionEquality().equals(other.webhook, webhook)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(from) ^
      const DeepCollectionEquality().hash(to) ^
      const DeepCollectionEquality().hash(preimageHash) ^
      const DeepCollectionEquality().hash(claimPublicKey) ^
      const DeepCollectionEquality().hash(refundPublicKey) ^
      const DeepCollectionEquality().hash(claimAddress) ^
      const DeepCollectionEquality().hash(userLockAmount) ^
      const DeepCollectionEquality().hash(serverLockAmount) ^
      const DeepCollectionEquality().hash(pairHash) ^
      const DeepCollectionEquality().hash(referralId) ^
      const DeepCollectionEquality().hash(webhook) ^
      runtimeType.hashCode;
}

extension $ChainRequestExtension on ChainRequest {
  ChainRequest copyWith(
      {String? from,
      String? to,
      String? preimageHash,
      String? claimPublicKey,
      String? refundPublicKey,
      String? claimAddress,
      double? userLockAmount,
      double? serverLockAmount,
      String? pairHash,
      String? referralId,
      WebhookData? webhook}) {
    return ChainRequest(
        from: from ?? this.from,
        to: to ?? this.to,
        preimageHash: preimageHash ?? this.preimageHash,
        claimPublicKey: claimPublicKey ?? this.claimPublicKey,
        refundPublicKey: refundPublicKey ?? this.refundPublicKey,
        claimAddress: claimAddress ?? this.claimAddress,
        userLockAmount: userLockAmount ?? this.userLockAmount,
        serverLockAmount: serverLockAmount ?? this.serverLockAmount,
        pairHash: pairHash ?? this.pairHash,
        referralId: referralId ?? this.referralId,
        webhook: webhook ?? this.webhook);
  }

  ChainRequest copyWithWrapped(
      {Wrapped<String>? from,
      Wrapped<String>? to,
      Wrapped<String>? preimageHash,
      Wrapped<String?>? claimPublicKey,
      Wrapped<String?>? refundPublicKey,
      Wrapped<String?>? claimAddress,
      Wrapped<double?>? userLockAmount,
      Wrapped<double?>? serverLockAmount,
      Wrapped<String?>? pairHash,
      Wrapped<String?>? referralId,
      Wrapped<WebhookData?>? webhook}) {
    return ChainRequest(
        from: (from != null ? from.value : this.from),
        to: (to != null ? to.value : this.to),
        preimageHash:
            (preimageHash != null ? preimageHash.value : this.preimageHash),
        claimPublicKey: (claimPublicKey != null
            ? claimPublicKey.value
            : this.claimPublicKey),
        refundPublicKey: (refundPublicKey != null
            ? refundPublicKey.value
            : this.refundPublicKey),
        claimAddress:
            (claimAddress != null ? claimAddress.value : this.claimAddress),
        userLockAmount: (userLockAmount != null
            ? userLockAmount.value
            : this.userLockAmount),
        serverLockAmount: (serverLockAmount != null
            ? serverLockAmount.value
            : this.serverLockAmount),
        pairHash: (pairHash != null ? pairHash.value : this.pairHash),
        referralId: (referralId != null ? referralId.value : this.referralId),
        webhook: (webhook != null ? webhook.value : this.webhook));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapData {
  const ChainSwapData({
    required this.swapTree,
    this.lockupAddress,
    this.serverPublicKey,
    required this.timeoutBlockHeight,
    required this.amount,
    this.blindingKey,
    this.refundAddress,
    this.bip21,
  });

  factory ChainSwapData.fromJson(Map<String, dynamic> json) =>
      _$ChainSwapDataFromJson(json);

  static const toJsonFactory = _$ChainSwapDataToJson;
  Map<String, dynamic> toJson() => _$ChainSwapDataToJson(this);

  @JsonKey(name: 'swapTree', includeIfNull: false)
  final SwapTree swapTree;
  @JsonKey(name: 'lockupAddress', includeIfNull: false)
  final String? lockupAddress;
  @JsonKey(name: 'serverPublicKey', includeIfNull: false)
  final String? serverPublicKey;
  @JsonKey(name: 'timeoutBlockHeight', includeIfNull: false)
  final double timeoutBlockHeight;
  @JsonKey(name: 'amount', includeIfNull: false)
  final double amount;
  @JsonKey(name: 'blindingKey', includeIfNull: false)
  final String? blindingKey;
  @JsonKey(name: 'refundAddress', includeIfNull: false)
  final String? refundAddress;
  @JsonKey(name: 'bip21', includeIfNull: false)
  final String? bip21;
  static const fromJsonFactory = _$ChainSwapDataFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainSwapData &&
            (identical(other.swapTree, swapTree) ||
                const DeepCollectionEquality()
                    .equals(other.swapTree, swapTree)) &&
            (identical(other.lockupAddress, lockupAddress) ||
                const DeepCollectionEquality()
                    .equals(other.lockupAddress, lockupAddress)) &&
            (identical(other.serverPublicKey, serverPublicKey) ||
                const DeepCollectionEquality()
                    .equals(other.serverPublicKey, serverPublicKey)) &&
            (identical(other.timeoutBlockHeight, timeoutBlockHeight) ||
                const DeepCollectionEquality()
                    .equals(other.timeoutBlockHeight, timeoutBlockHeight)) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.blindingKey, blindingKey) ||
                const DeepCollectionEquality()
                    .equals(other.blindingKey, blindingKey)) &&
            (identical(other.refundAddress, refundAddress) ||
                const DeepCollectionEquality()
                    .equals(other.refundAddress, refundAddress)) &&
            (identical(other.bip21, bip21) ||
                const DeepCollectionEquality().equals(other.bip21, bip21)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(swapTree) ^
      const DeepCollectionEquality().hash(lockupAddress) ^
      const DeepCollectionEquality().hash(serverPublicKey) ^
      const DeepCollectionEquality().hash(timeoutBlockHeight) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(blindingKey) ^
      const DeepCollectionEquality().hash(refundAddress) ^
      const DeepCollectionEquality().hash(bip21) ^
      runtimeType.hashCode;
}

extension $ChainSwapDataExtension on ChainSwapData {
  ChainSwapData copyWith(
      {SwapTree? swapTree,
      String? lockupAddress,
      String? serverPublicKey,
      double? timeoutBlockHeight,
      double? amount,
      String? blindingKey,
      String? refundAddress,
      String? bip21}) {
    return ChainSwapData(
        swapTree: swapTree ?? this.swapTree,
        lockupAddress: lockupAddress ?? this.lockupAddress,
        serverPublicKey: serverPublicKey ?? this.serverPublicKey,
        timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
        amount: amount ?? this.amount,
        blindingKey: blindingKey ?? this.blindingKey,
        refundAddress: refundAddress ?? this.refundAddress,
        bip21: bip21 ?? this.bip21);
  }

  ChainSwapData copyWithWrapped(
      {Wrapped<SwapTree>? swapTree,
      Wrapped<String?>? lockupAddress,
      Wrapped<String?>? serverPublicKey,
      Wrapped<double>? timeoutBlockHeight,
      Wrapped<double>? amount,
      Wrapped<String?>? blindingKey,
      Wrapped<String?>? refundAddress,
      Wrapped<String?>? bip21}) {
    return ChainSwapData(
        swapTree: (swapTree != null ? swapTree.value : this.swapTree),
        lockupAddress:
            (lockupAddress != null ? lockupAddress.value : this.lockupAddress),
        serverPublicKey: (serverPublicKey != null
            ? serverPublicKey.value
            : this.serverPublicKey),
        timeoutBlockHeight: (timeoutBlockHeight != null
            ? timeoutBlockHeight.value
            : this.timeoutBlockHeight),
        amount: (amount != null ? amount.value : this.amount),
        blindingKey:
            (blindingKey != null ? blindingKey.value : this.blindingKey),
        refundAddress:
            (refundAddress != null ? refundAddress.value : this.refundAddress),
        bip21: (bip21 != null ? bip21.value : this.bip21));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainResponse {
  const ChainResponse({
    required this.id,
    this.referralId,
    required this.claimDetails,
    required this.lockupDetails,
  });

  factory ChainResponse.fromJson(Map<String, dynamic> json) =>
      _$ChainResponseFromJson(json);

  static const toJsonFactory = _$ChainResponseToJson;
  Map<String, dynamic> toJson() => _$ChainResponseToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'referralId', includeIfNull: false)
  final String? referralId;
  @JsonKey(name: 'claimDetails', includeIfNull: false)
  final ChainSwapData claimDetails;
  @JsonKey(name: 'lockupDetails', includeIfNull: false)
  final ChainSwapData lockupDetails;
  static const fromJsonFactory = _$ChainResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainResponse &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.referralId, referralId) ||
                const DeepCollectionEquality()
                    .equals(other.referralId, referralId)) &&
            (identical(other.claimDetails, claimDetails) ||
                const DeepCollectionEquality()
                    .equals(other.claimDetails, claimDetails)) &&
            (identical(other.lockupDetails, lockupDetails) ||
                const DeepCollectionEquality()
                    .equals(other.lockupDetails, lockupDetails)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(referralId) ^
      const DeepCollectionEquality().hash(claimDetails) ^
      const DeepCollectionEquality().hash(lockupDetails) ^
      runtimeType.hashCode;
}

extension $ChainResponseExtension on ChainResponse {
  ChainResponse copyWith(
      {String? id,
      String? referralId,
      ChainSwapData? claimDetails,
      ChainSwapData? lockupDetails}) {
    return ChainResponse(
        id: id ?? this.id,
        referralId: referralId ?? this.referralId,
        claimDetails: claimDetails ?? this.claimDetails,
        lockupDetails: lockupDetails ?? this.lockupDetails);
  }

  ChainResponse copyWithWrapped(
      {Wrapped<String>? id,
      Wrapped<String?>? referralId,
      Wrapped<ChainSwapData>? claimDetails,
      Wrapped<ChainSwapData>? lockupDetails}) {
    return ChainResponse(
        id: (id != null ? id.value : this.id),
        referralId: (referralId != null ? referralId.value : this.referralId),
        claimDetails:
            (claimDetails != null ? claimDetails.value : this.claimDetails),
        lockupDetails:
            (lockupDetails != null ? lockupDetails.value : this.lockupDetails));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapTransaction {
  const ChainSwapTransaction({
    required this.transaction,
    this.timeout,
  });

  factory ChainSwapTransaction.fromJson(Map<String, dynamic> json) =>
      _$ChainSwapTransactionFromJson(json);

  static const toJsonFactory = _$ChainSwapTransactionToJson;
  Map<String, dynamic> toJson() => _$ChainSwapTransactionToJson(this);

  @JsonKey(name: 'transaction', includeIfNull: false)
  final ChainSwapTransaction$Transaction transaction;
  @JsonKey(name: 'timeout', includeIfNull: false)
  final ChainSwapTransaction$Timeout? timeout;
  static const fromJsonFactory = _$ChainSwapTransactionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainSwapTransaction &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality()
                    .equals(other.transaction, transaction)) &&
            (identical(other.timeout, timeout) ||
                const DeepCollectionEquality().equals(other.timeout, timeout)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(transaction) ^
      const DeepCollectionEquality().hash(timeout) ^
      runtimeType.hashCode;
}

extension $ChainSwapTransactionExtension on ChainSwapTransaction {
  ChainSwapTransaction copyWith(
      {ChainSwapTransaction$Transaction? transaction,
      ChainSwapTransaction$Timeout? timeout}) {
    return ChainSwapTransaction(
        transaction: transaction ?? this.transaction,
        timeout: timeout ?? this.timeout);
  }

  ChainSwapTransaction copyWithWrapped(
      {Wrapped<ChainSwapTransaction$Transaction>? transaction,
      Wrapped<ChainSwapTransaction$Timeout?>? timeout}) {
    return ChainSwapTransaction(
        transaction:
            (transaction != null ? transaction.value : this.transaction),
        timeout: (timeout != null ? timeout.value : this.timeout));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapTransactions {
  const ChainSwapTransactions({
    this.userLock,
    this.serverLock,
  });

  factory ChainSwapTransactions.fromJson(Map<String, dynamic> json) =>
      _$ChainSwapTransactionsFromJson(json);

  static const toJsonFactory = _$ChainSwapTransactionsToJson;
  Map<String, dynamic> toJson() => _$ChainSwapTransactionsToJson(this);

  @JsonKey(name: 'userLock', includeIfNull: false)
  final ChainSwapTransaction? userLock;
  @JsonKey(name: 'serverLock', includeIfNull: false)
  final ChainSwapTransaction? serverLock;
  static const fromJsonFactory = _$ChainSwapTransactionsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainSwapTransactions &&
            (identical(other.userLock, userLock) ||
                const DeepCollectionEquality()
                    .equals(other.userLock, userLock)) &&
            (identical(other.serverLock, serverLock) ||
                const DeepCollectionEquality()
                    .equals(other.serverLock, serverLock)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(userLock) ^
      const DeepCollectionEquality().hash(serverLock) ^
      runtimeType.hashCode;
}

extension $ChainSwapTransactionsExtension on ChainSwapTransactions {
  ChainSwapTransactions copyWith(
      {ChainSwapTransaction? userLock, ChainSwapTransaction? serverLock}) {
    return ChainSwapTransactions(
        userLock: userLock ?? this.userLock,
        serverLock: serverLock ?? this.serverLock);
  }

  ChainSwapTransactions copyWithWrapped(
      {Wrapped<ChainSwapTransaction?>? userLock,
      Wrapped<ChainSwapTransaction?>? serverLock}) {
    return ChainSwapTransactions(
        userLock: (userLock != null ? userLock.value : this.userLock),
        serverLock: (serverLock != null ? serverLock.value : this.serverLock));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapSigningDetails {
  const ChainSwapSigningDetails({
    required this.pubNonce,
    required this.publicKey,
    required this.transactionHash,
  });

  factory ChainSwapSigningDetails.fromJson(Map<String, dynamic> json) =>
      _$ChainSwapSigningDetailsFromJson(json);

  static const toJsonFactory = _$ChainSwapSigningDetailsToJson;
  Map<String, dynamic> toJson() => _$ChainSwapSigningDetailsToJson(this);

  @JsonKey(name: 'pubNonce', includeIfNull: false)
  final String pubNonce;
  @JsonKey(name: 'publicKey', includeIfNull: false)
  final String publicKey;
  @JsonKey(name: 'transactionHash', includeIfNull: false)
  final String transactionHash;
  static const fromJsonFactory = _$ChainSwapSigningDetailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainSwapSigningDetails &&
            (identical(other.pubNonce, pubNonce) ||
                const DeepCollectionEquality()
                    .equals(other.pubNonce, pubNonce)) &&
            (identical(other.publicKey, publicKey) ||
                const DeepCollectionEquality()
                    .equals(other.publicKey, publicKey)) &&
            (identical(other.transactionHash, transactionHash) ||
                const DeepCollectionEquality()
                    .equals(other.transactionHash, transactionHash)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(pubNonce) ^
      const DeepCollectionEquality().hash(publicKey) ^
      const DeepCollectionEquality().hash(transactionHash) ^
      runtimeType.hashCode;
}

extension $ChainSwapSigningDetailsExtension on ChainSwapSigningDetails {
  ChainSwapSigningDetails copyWith(
      {String? pubNonce, String? publicKey, String? transactionHash}) {
    return ChainSwapSigningDetails(
        pubNonce: pubNonce ?? this.pubNonce,
        publicKey: publicKey ?? this.publicKey,
        transactionHash: transactionHash ?? this.transactionHash);
  }

  ChainSwapSigningDetails copyWithWrapped(
      {Wrapped<String>? pubNonce,
      Wrapped<String>? publicKey,
      Wrapped<String>? transactionHash}) {
    return ChainSwapSigningDetails(
        pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
        publicKey: (publicKey != null ? publicKey.value : this.publicKey),
        transactionHash: (transactionHash != null
            ? transactionHash.value
            : this.transactionHash));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapSigningRequest {
  const ChainSwapSigningRequest({
    this.preimage,
    this.signature,
    this.toSign,
  });

  factory ChainSwapSigningRequest.fromJson(Map<String, dynamic> json) =>
      _$ChainSwapSigningRequestFromJson(json);

  static const toJsonFactory = _$ChainSwapSigningRequestToJson;
  Map<String, dynamic> toJson() => _$ChainSwapSigningRequestToJson(this);

  @JsonKey(name: 'preimage', includeIfNull: false)
  final String? preimage;
  @JsonKey(name: 'signature', includeIfNull: false)
  final PartialSignature? signature;
  @JsonKey(name: 'toSign', includeIfNull: false)
  final ChainSwapSigningRequest$ToSign? toSign;
  static const fromJsonFactory = _$ChainSwapSigningRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainSwapSigningRequest &&
            (identical(other.preimage, preimage) ||
                const DeepCollectionEquality()
                    .equals(other.preimage, preimage)) &&
            (identical(other.signature, signature) ||
                const DeepCollectionEquality()
                    .equals(other.signature, signature)) &&
            (identical(other.toSign, toSign) ||
                const DeepCollectionEquality().equals(other.toSign, toSign)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(preimage) ^
      const DeepCollectionEquality().hash(signature) ^
      const DeepCollectionEquality().hash(toSign) ^
      runtimeType.hashCode;
}

extension $ChainSwapSigningRequestExtension on ChainSwapSigningRequest {
  ChainSwapSigningRequest copyWith(
      {String? preimage,
      PartialSignature? signature,
      ChainSwapSigningRequest$ToSign? toSign}) {
    return ChainSwapSigningRequest(
        preimage: preimage ?? this.preimage,
        signature: signature ?? this.signature,
        toSign: toSign ?? this.toSign);
  }

  ChainSwapSigningRequest copyWithWrapped(
      {Wrapped<String?>? preimage,
      Wrapped<PartialSignature?>? signature,
      Wrapped<ChainSwapSigningRequest$ToSign?>? toSign}) {
    return ChainSwapSigningRequest(
        preimage: (preimage != null ? preimage.value : this.preimage),
        signature: (signature != null ? signature.value : this.signature),
        toSign: (toSign != null ? toSign.value : this.toSign));
  }
}

@JsonSerializable(explicitToJson: true)
class Quote {
  const Quote({
    required this.amount,
  });

  factory Quote.fromJson(Map<String, dynamic> json) => _$QuoteFromJson(json);

  static const toJsonFactory = _$QuoteToJson;
  Map<String, dynamic> toJson() => _$QuoteToJson(this);

  @JsonKey(name: 'amount', includeIfNull: false)
  final double amount;
  static const fromJsonFactory = _$QuoteFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Quote &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(amount) ^ runtimeType.hashCode;
}

extension $QuoteExtension on Quote {
  Quote copyWith({double? amount}) {
    return Quote(amount: amount ?? this.amount);
  }

  Quote copyWithWrapped({Wrapped<double>? amount}) {
    return Quote(amount: (amount != null ? amount.value : this.amount));
  }
}

@JsonSerializable(explicitToJson: true)
class QuoteResponse {
  const QuoteResponse();

  factory QuoteResponse.fromJson(Map<String, dynamic> json) =>
      _$QuoteResponseFromJson(json);

  static const toJsonFactory = _$QuoteResponseToJson;
  Map<String, dynamic> toJson() => _$QuoteResponseToJson(this);

  static const fromJsonFactory = _$QuoteResponseFromJson;

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => runtimeType.hashCode;
}

@JsonSerializable(explicitToJson: true)
class SwapStatus {
  const SwapStatus({
    required this.status,
    this.zeroConfRejected,
    this.transaction,
  });

  factory SwapStatus.fromJson(Map<String, dynamic> json) =>
      _$SwapStatusFromJson(json);

  static const toJsonFactory = _$SwapStatusToJson;
  Map<String, dynamic> toJson() => _$SwapStatusToJson(this);

  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'zeroConfRejected', includeIfNull: false)
  final bool? zeroConfRejected;
  @JsonKey(name: 'transaction', includeIfNull: false)
  final SwapStatus$Transaction? transaction;
  static const fromJsonFactory = _$SwapStatusFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SwapStatus &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.zeroConfRejected, zeroConfRejected) ||
                const DeepCollectionEquality()
                    .equals(other.zeroConfRejected, zeroConfRejected)) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality()
                    .equals(other.transaction, transaction)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(zeroConfRejected) ^
      const DeepCollectionEquality().hash(transaction) ^
      runtimeType.hashCode;
}

extension $SwapStatusExtension on SwapStatus {
  SwapStatus copyWith(
      {String? status,
      bool? zeroConfRejected,
      SwapStatus$Transaction? transaction}) {
    return SwapStatus(
        status: status ?? this.status,
        zeroConfRejected: zeroConfRejected ?? this.zeroConfRejected,
        transaction: transaction ?? this.transaction);
  }

  SwapStatus copyWithWrapped(
      {Wrapped<String>? status,
      Wrapped<bool?>? zeroConfRejected,
      Wrapped<SwapStatus$Transaction?>? transaction}) {
    return SwapStatus(
        status: (status != null ? status.value : this.status),
        zeroConfRejected: (zeroConfRejected != null
            ? zeroConfRejected.value
            : this.zeroConfRejected),
        transaction:
            (transaction != null ? transaction.value : this.transaction));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainCurrencyTransactionPost$RequestBody {
  const ChainCurrencyTransactionPost$RequestBody({
    required this.hex,
  });

  factory ChainCurrencyTransactionPost$RequestBody.fromJson(
          Map<String, dynamic> json) =>
      _$ChainCurrencyTransactionPost$RequestBodyFromJson(json);

  static const toJsonFactory = _$ChainCurrencyTransactionPost$RequestBodyToJson;
  Map<String, dynamic> toJson() =>
      _$ChainCurrencyTransactionPost$RequestBodyToJson(this);

  @JsonKey(name: 'hex', includeIfNull: false)
  final String hex;
  static const fromJsonFactory =
      _$ChainCurrencyTransactionPost$RequestBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainCurrencyTransactionPost$RequestBody &&
            (identical(other.hex, hex) ||
                const DeepCollectionEquality().equals(other.hex, hex)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(hex) ^ runtimeType.hashCode;
}

extension $ChainCurrencyTransactionPost$RequestBodyExtension
    on ChainCurrencyTransactionPost$RequestBody {
  ChainCurrencyTransactionPost$RequestBody copyWith({String? hex}) {
    return ChainCurrencyTransactionPost$RequestBody(hex: hex ?? this.hex);
  }

  ChainCurrencyTransactionPost$RequestBody copyWithWrapped(
      {Wrapped<String>? hex}) {
    return ChainCurrencyTransactionPost$RequestBody(
        hex: (hex != null ? hex.value : this.hex));
  }
}

@JsonSerializable(explicitToJson: true)
class LightningCurrencyBolt12FetchPost$RequestBody {
  const LightningCurrencyBolt12FetchPost$RequestBody({
    required this.offer,
    required this.amount,
  });

  factory LightningCurrencyBolt12FetchPost$RequestBody.fromJson(
          Map<String, dynamic> json) =>
      _$LightningCurrencyBolt12FetchPost$RequestBodyFromJson(json);

  static const toJsonFactory =
      _$LightningCurrencyBolt12FetchPost$RequestBodyToJson;
  Map<String, dynamic> toJson() =>
      _$LightningCurrencyBolt12FetchPost$RequestBodyToJson(this);

  @JsonKey(name: 'offer', includeIfNull: false)
  final String offer;
  @JsonKey(name: 'amount', includeIfNull: false)
  final double amount;
  static const fromJsonFactory =
      _$LightningCurrencyBolt12FetchPost$RequestBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningCurrencyBolt12FetchPost$RequestBody &&
            (identical(other.offer, offer) ||
                const DeepCollectionEquality().equals(other.offer, offer)) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(offer) ^
      const DeepCollectionEquality().hash(amount) ^
      runtimeType.hashCode;
}

extension $LightningCurrencyBolt12FetchPost$RequestBodyExtension
    on LightningCurrencyBolt12FetchPost$RequestBody {
  LightningCurrencyBolt12FetchPost$RequestBody copyWith(
      {String? offer, double? amount}) {
    return LightningCurrencyBolt12FetchPost$RequestBody(
        offer: offer ?? this.offer, amount: amount ?? this.amount);
  }

  LightningCurrencyBolt12FetchPost$RequestBody copyWithWrapped(
      {Wrapped<String>? offer, Wrapped<double>? amount}) {
    return LightningCurrencyBolt12FetchPost$RequestBody(
        offer: (offer != null ? offer.value : this.offer),
        amount: (amount != null ? amount.value : this.amount));
  }
}

@JsonSerializable(explicitToJson: true)
class SwapSubmarineIdInvoicePost$RequestBody {
  const SwapSubmarineIdInvoicePost$RequestBody({
    required this.invoice,
    this.pairHash,
  });

  factory SwapSubmarineIdInvoicePost$RequestBody.fromJson(
          Map<String, dynamic> json) =>
      _$SwapSubmarineIdInvoicePost$RequestBodyFromJson(json);

  static const toJsonFactory = _$SwapSubmarineIdInvoicePost$RequestBodyToJson;
  Map<String, dynamic> toJson() =>
      _$SwapSubmarineIdInvoicePost$RequestBodyToJson(this);

  @JsonKey(name: 'invoice', includeIfNull: false)
  final String invoice;
  @JsonKey(name: 'pairHash', includeIfNull: false)
  final String? pairHash;
  static const fromJsonFactory =
      _$SwapSubmarineIdInvoicePost$RequestBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SwapSubmarineIdInvoicePost$RequestBody &&
            (identical(other.invoice, invoice) ||
                const DeepCollectionEquality()
                    .equals(other.invoice, invoice)) &&
            (identical(other.pairHash, pairHash) ||
                const DeepCollectionEquality()
                    .equals(other.pairHash, pairHash)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(invoice) ^
      const DeepCollectionEquality().hash(pairHash) ^
      runtimeType.hashCode;
}

extension $SwapSubmarineIdInvoicePost$RequestBodyExtension
    on SwapSubmarineIdInvoicePost$RequestBody {
  SwapSubmarineIdInvoicePost$RequestBody copyWith(
      {String? invoice, String? pairHash}) {
    return SwapSubmarineIdInvoicePost$RequestBody(
        invoice: invoice ?? this.invoice, pairHash: pairHash ?? this.pairHash);
  }

  SwapSubmarineIdInvoicePost$RequestBody copyWithWrapped(
      {Wrapped<String>? invoice, Wrapped<String?>? pairHash}) {
    return SwapSubmarineIdInvoicePost$RequestBody(
        invoice: (invoice != null ? invoice.value : this.invoice),
        pairHash: (pairHash != null ? pairHash.value : this.pairHash));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainCurrencyFeeGet$Response {
  const ChainCurrencyFeeGet$Response({
    required this.fee,
  });

  factory ChainCurrencyFeeGet$Response.fromJson(Map<String, dynamic> json) =>
      _$ChainCurrencyFeeGet$ResponseFromJson(json);

  static const toJsonFactory = _$ChainCurrencyFeeGet$ResponseToJson;
  Map<String, dynamic> toJson() => _$ChainCurrencyFeeGet$ResponseToJson(this);

  @JsonKey(name: 'fee', includeIfNull: false)
  final double fee;
  static const fromJsonFactory = _$ChainCurrencyFeeGet$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainCurrencyFeeGet$Response &&
            (identical(other.fee, fee) ||
                const DeepCollectionEquality().equals(other.fee, fee)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(fee) ^ runtimeType.hashCode;
}

extension $ChainCurrencyFeeGet$ResponseExtension
    on ChainCurrencyFeeGet$Response {
  ChainCurrencyFeeGet$Response copyWith({double? fee}) {
    return ChainCurrencyFeeGet$Response(fee: fee ?? this.fee);
  }

  ChainCurrencyFeeGet$Response copyWithWrapped({Wrapped<double>? fee}) {
    return ChainCurrencyFeeGet$Response(
        fee: (fee != null ? fee.value : this.fee));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainCurrencyHeightGet$Response {
  const ChainCurrencyHeightGet$Response({
    required this.height,
  });

  factory ChainCurrencyHeightGet$Response.fromJson(Map<String, dynamic> json) =>
      _$ChainCurrencyHeightGet$ResponseFromJson(json);

  static const toJsonFactory = _$ChainCurrencyHeightGet$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$ChainCurrencyHeightGet$ResponseToJson(this);

  @JsonKey(name: 'height', includeIfNull: false)
  final double height;
  static const fromJsonFactory = _$ChainCurrencyHeightGet$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainCurrencyHeightGet$Response &&
            (identical(other.height, height) ||
                const DeepCollectionEquality().equals(other.height, height)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(height) ^ runtimeType.hashCode;
}

extension $ChainCurrencyHeightGet$ResponseExtension
    on ChainCurrencyHeightGet$Response {
  ChainCurrencyHeightGet$Response copyWith({double? height}) {
    return ChainCurrencyHeightGet$Response(height: height ?? this.height);
  }

  ChainCurrencyHeightGet$Response copyWithWrapped({Wrapped<double>? height}) {
    return ChainCurrencyHeightGet$Response(
        height: (height != null ? height.value : this.height));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainCurrencyTransactionIdGet$Response {
  const ChainCurrencyTransactionIdGet$Response({
    required this.hex,
  });

  factory ChainCurrencyTransactionIdGet$Response.fromJson(
          Map<String, dynamic> json) =>
      _$ChainCurrencyTransactionIdGet$ResponseFromJson(json);

  static const toJsonFactory = _$ChainCurrencyTransactionIdGet$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$ChainCurrencyTransactionIdGet$ResponseToJson(this);

  @JsonKey(name: 'hex', includeIfNull: false)
  final String hex;
  static const fromJsonFactory =
      _$ChainCurrencyTransactionIdGet$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainCurrencyTransactionIdGet$Response &&
            (identical(other.hex, hex) ||
                const DeepCollectionEquality().equals(other.hex, hex)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(hex) ^ runtimeType.hashCode;
}

extension $ChainCurrencyTransactionIdGet$ResponseExtension
    on ChainCurrencyTransactionIdGet$Response {
  ChainCurrencyTransactionIdGet$Response copyWith({String? hex}) {
    return ChainCurrencyTransactionIdGet$Response(hex: hex ?? this.hex);
  }

  ChainCurrencyTransactionIdGet$Response copyWithWrapped(
      {Wrapped<String>? hex}) {
    return ChainCurrencyTransactionIdGet$Response(
        hex: (hex != null ? hex.value : this.hex));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainCurrencyTransactionPost$Response {
  const ChainCurrencyTransactionPost$Response({
    required this.id,
  });

  factory ChainCurrencyTransactionPost$Response.fromJson(
          Map<String, dynamic> json) =>
      _$ChainCurrencyTransactionPost$ResponseFromJson(json);

  static const toJsonFactory = _$ChainCurrencyTransactionPost$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$ChainCurrencyTransactionPost$ResponseToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  static const fromJsonFactory =
      _$ChainCurrencyTransactionPost$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainCurrencyTransactionPost$Response &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^ runtimeType.hashCode;
}

extension $ChainCurrencyTransactionPost$ResponseExtension
    on ChainCurrencyTransactionPost$Response {
  ChainCurrencyTransactionPost$Response copyWith({String? id}) {
    return ChainCurrencyTransactionPost$Response(id: id ?? this.id);
  }

  ChainCurrencyTransactionPost$Response copyWithWrapped({Wrapped<String>? id}) {
    return ChainCurrencyTransactionPost$Response(
        id: (id != null ? id.value : this.id));
  }
}

@JsonSerializable(explicitToJson: true)
class VersionGet$Response {
  const VersionGet$Response({
    required this.version,
  });

  factory VersionGet$Response.fromJson(Map<String, dynamic> json) =>
      _$VersionGet$ResponseFromJson(json);

  static const toJsonFactory = _$VersionGet$ResponseToJson;
  Map<String, dynamic> toJson() => _$VersionGet$ResponseToJson(this);

  @JsonKey(name: 'version', includeIfNull: false)
  final String version;
  static const fromJsonFactory = _$VersionGet$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is VersionGet$Response &&
            (identical(other.version, version) ||
                const DeepCollectionEquality().equals(other.version, version)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(version) ^ runtimeType.hashCode;
}

extension $VersionGet$ResponseExtension on VersionGet$Response {
  VersionGet$Response copyWith({String? version}) {
    return VersionGet$Response(version: version ?? this.version);
  }

  VersionGet$Response copyWithWrapped({Wrapped<String>? version}) {
    return VersionGet$Response(
        version: (version != null ? version.value : this.version));
  }
}

@JsonSerializable(explicitToJson: true)
class LightningCurrencyBolt12FetchPost$Response {
  const LightningCurrencyBolt12FetchPost$Response({
    required this.invoice,
  });

  factory LightningCurrencyBolt12FetchPost$Response.fromJson(
          Map<String, dynamic> json) =>
      _$LightningCurrencyBolt12FetchPost$ResponseFromJson(json);

  static const toJsonFactory =
      _$LightningCurrencyBolt12FetchPost$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$LightningCurrencyBolt12FetchPost$ResponseToJson(this);

  @JsonKey(name: 'invoice', includeIfNull: false)
  final String invoice;
  static const fromJsonFactory =
      _$LightningCurrencyBolt12FetchPost$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningCurrencyBolt12FetchPost$Response &&
            (identical(other.invoice, invoice) ||
                const DeepCollectionEquality().equals(other.invoice, invoice)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(invoice) ^ runtimeType.hashCode;
}

extension $LightningCurrencyBolt12FetchPost$ResponseExtension
    on LightningCurrencyBolt12FetchPost$Response {
  LightningCurrencyBolt12FetchPost$Response copyWith({String? invoice}) {
    return LightningCurrencyBolt12FetchPost$Response(
        invoice: invoice ?? this.invoice);
  }

  LightningCurrencyBolt12FetchPost$Response copyWithWrapped(
      {Wrapped<String>? invoice}) {
    return LightningCurrencyBolt12FetchPost$Response(
        invoice: (invoice != null ? invoice.value : this.invoice));
  }
}

@JsonSerializable(explicitToJson: true)
class ReferralGet$Response {
  const ReferralGet$Response({
    required this.id,
  });

  factory ReferralGet$Response.fromJson(Map<String, dynamic> json) =>
      _$ReferralGet$ResponseFromJson(json);

  static const toJsonFactory = _$ReferralGet$ResponseToJson;
  Map<String, dynamic> toJson() => _$ReferralGet$ResponseToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  static const fromJsonFactory = _$ReferralGet$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReferralGet$Response &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^ runtimeType.hashCode;
}

extension $ReferralGet$ResponseExtension on ReferralGet$Response {
  ReferralGet$Response copyWith({String? id}) {
    return ReferralGet$Response(id: id ?? this.id);
  }

  ReferralGet$Response copyWithWrapped({Wrapped<String>? id}) {
    return ReferralGet$Response(id: (id != null ? id.value : this.id));
  }
}

@JsonSerializable(explicitToJson: true)
class SwapSubmarineIdInvoicePost$Response {
  const SwapSubmarineIdInvoicePost$Response({
    required this.bip21,
    required this.expectedAmount,
    required this.acceptZeroConf,
  });

  factory SwapSubmarineIdInvoicePost$Response.fromJson(
          Map<String, dynamic> json) =>
      _$SwapSubmarineIdInvoicePost$ResponseFromJson(json);

  static const toJsonFactory = _$SwapSubmarineIdInvoicePost$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$SwapSubmarineIdInvoicePost$ResponseToJson(this);

  @JsonKey(name: 'bip21', includeIfNull: false)
  final String bip21;
  @JsonKey(name: 'expectedAmount', includeIfNull: false)
  final double expectedAmount;
  @JsonKey(name: 'acceptZeroConf', includeIfNull: false)
  final bool acceptZeroConf;
  static const fromJsonFactory = _$SwapSubmarineIdInvoicePost$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SwapSubmarineIdInvoicePost$Response &&
            (identical(other.bip21, bip21) ||
                const DeepCollectionEquality().equals(other.bip21, bip21)) &&
            (identical(other.expectedAmount, expectedAmount) ||
                const DeepCollectionEquality()
                    .equals(other.expectedAmount, expectedAmount)) &&
            (identical(other.acceptZeroConf, acceptZeroConf) ||
                const DeepCollectionEquality()
                    .equals(other.acceptZeroConf, acceptZeroConf)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(bip21) ^
      const DeepCollectionEquality().hash(expectedAmount) ^
      const DeepCollectionEquality().hash(acceptZeroConf) ^
      runtimeType.hashCode;
}

extension $SwapSubmarineIdInvoicePost$ResponseExtension
    on SwapSubmarineIdInvoicePost$Response {
  SwapSubmarineIdInvoicePost$Response copyWith(
      {String? bip21, double? expectedAmount, bool? acceptZeroConf}) {
    return SwapSubmarineIdInvoicePost$Response(
        bip21: bip21 ?? this.bip21,
        expectedAmount: expectedAmount ?? this.expectedAmount,
        acceptZeroConf: acceptZeroConf ?? this.acceptZeroConf);
  }

  SwapSubmarineIdInvoicePost$Response copyWithWrapped(
      {Wrapped<String>? bip21,
      Wrapped<double>? expectedAmount,
      Wrapped<bool>? acceptZeroConf}) {
    return SwapSubmarineIdInvoicePost$Response(
        bip21: (bip21 != null ? bip21.value : this.bip21),
        expectedAmount: (expectedAmount != null
            ? expectedAmount.value
            : this.expectedAmount),
        acceptZeroConf: (acceptZeroConf != null
            ? acceptZeroConf.value
            : this.acceptZeroConf));
  }
}

@JsonSerializable(explicitToJson: true)
class SwapSubmarineIdInvoiceAmountGet$Response {
  const SwapSubmarineIdInvoiceAmountGet$Response({
    required this.invoiceAmount,
  });

  factory SwapSubmarineIdInvoiceAmountGet$Response.fromJson(
          Map<String, dynamic> json) =>
      _$SwapSubmarineIdInvoiceAmountGet$ResponseFromJson(json);

  static const toJsonFactory = _$SwapSubmarineIdInvoiceAmountGet$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$SwapSubmarineIdInvoiceAmountGet$ResponseToJson(this);

  @JsonKey(name: 'invoiceAmount', includeIfNull: false)
  final double invoiceAmount;
  static const fromJsonFactory =
      _$SwapSubmarineIdInvoiceAmountGet$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SwapSubmarineIdInvoiceAmountGet$Response &&
            (identical(other.invoiceAmount, invoiceAmount) ||
                const DeepCollectionEquality()
                    .equals(other.invoiceAmount, invoiceAmount)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(invoiceAmount) ^ runtimeType.hashCode;
}

extension $SwapSubmarineIdInvoiceAmountGet$ResponseExtension
    on SwapSubmarineIdInvoiceAmountGet$Response {
  SwapSubmarineIdInvoiceAmountGet$Response copyWith({double? invoiceAmount}) {
    return SwapSubmarineIdInvoiceAmountGet$Response(
        invoiceAmount: invoiceAmount ?? this.invoiceAmount);
  }

  SwapSubmarineIdInvoiceAmountGet$Response copyWithWrapped(
      {Wrapped<double>? invoiceAmount}) {
    return SwapSubmarineIdInvoiceAmountGet$Response(
        invoiceAmount:
            (invoiceAmount != null ? invoiceAmount.value : this.invoiceAmount));
  }
}

@JsonSerializable(explicitToJson: true)
class SwapSubmarineIdRefundGet$Response {
  const SwapSubmarineIdRefundGet$Response({
    required this.signature,
  });

  factory SwapSubmarineIdRefundGet$Response.fromJson(
          Map<String, dynamic> json) =>
      _$SwapSubmarineIdRefundGet$ResponseFromJson(json);

  static const toJsonFactory = _$SwapSubmarineIdRefundGet$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$SwapSubmarineIdRefundGet$ResponseToJson(this);

  @JsonKey(name: 'signature', includeIfNull: false)
  final String signature;
  static const fromJsonFactory = _$SwapSubmarineIdRefundGet$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SwapSubmarineIdRefundGet$Response &&
            (identical(other.signature, signature) ||
                const DeepCollectionEquality()
                    .equals(other.signature, signature)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(signature) ^ runtimeType.hashCode;
}

extension $SwapSubmarineIdRefundGet$ResponseExtension
    on SwapSubmarineIdRefundGet$Response {
  SwapSubmarineIdRefundGet$Response copyWith({String? signature}) {
    return SwapSubmarineIdRefundGet$Response(
        signature: signature ?? this.signature);
  }

  SwapSubmarineIdRefundGet$Response copyWithWrapped(
      {Wrapped<String>? signature}) {
    return SwapSubmarineIdRefundGet$Response(
        signature: (signature != null ? signature.value : this.signature));
  }
}

@JsonSerializable(explicitToJson: true)
class SwapChainIdRefundGet$Response {
  const SwapChainIdRefundGet$Response({
    required this.signature,
  });

  factory SwapChainIdRefundGet$Response.fromJson(Map<String, dynamic> json) =>
      _$SwapChainIdRefundGet$ResponseFromJson(json);

  static const toJsonFactory = _$SwapChainIdRefundGet$ResponseToJson;
  Map<String, dynamic> toJson() => _$SwapChainIdRefundGet$ResponseToJson(this);

  @JsonKey(name: 'signature', includeIfNull: false)
  final String signature;
  static const fromJsonFactory = _$SwapChainIdRefundGet$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SwapChainIdRefundGet$Response &&
            (identical(other.signature, signature) ||
                const DeepCollectionEquality()
                    .equals(other.signature, signature)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(signature) ^ runtimeType.hashCode;
}

extension $SwapChainIdRefundGet$ResponseExtension
    on SwapChainIdRefundGet$Response {
  SwapChainIdRefundGet$Response copyWith({String? signature}) {
    return SwapChainIdRefundGet$Response(
        signature: signature ?? this.signature);
  }

  SwapChainIdRefundGet$Response copyWithWrapped({Wrapped<String>? signature}) {
    return SwapChainIdRefundGet$Response(
        signature: (signature != null ? signature.value : this.signature));
  }
}

@JsonSerializable(explicitToJson: true)
class Contracts$Network {
  const Contracts$Network({
    required this.chainId,
    required this.name,
  });

  factory Contracts$Network.fromJson(Map<String, dynamic> json) =>
      _$Contracts$NetworkFromJson(json);

  static const toJsonFactory = _$Contracts$NetworkToJson;
  Map<String, dynamic> toJson() => _$Contracts$NetworkToJson(this);

  @JsonKey(name: 'chainId', includeIfNull: false)
  final double chainId;
  @JsonKey(name: 'name', includeIfNull: false)
  final String name;
  static const fromJsonFactory = _$Contracts$NetworkFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Contracts$Network &&
            (identical(other.chainId, chainId) ||
                const DeepCollectionEquality()
                    .equals(other.chainId, chainId)) &&
            (identical(other.name, name) ||
                const DeepCollectionEquality().equals(other.name, name)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(chainId) ^
      const DeepCollectionEquality().hash(name) ^
      runtimeType.hashCode;
}

extension $Contracts$NetworkExtension on Contracts$Network {
  Contracts$Network copyWith({double? chainId, String? name}) {
    return Contracts$Network(
        chainId: chainId ?? this.chainId, name: name ?? this.name);
  }

  Contracts$Network copyWithWrapped(
      {Wrapped<double>? chainId, Wrapped<String>? name}) {
    return Contracts$Network(
        chainId: (chainId != null ? chainId.value : this.chainId),
        name: (name != null ? name.value : this.name));
  }
}

@JsonSerializable(explicitToJson: true)
class Contracts$SwapContracts {
  const Contracts$SwapContracts({
    this.etherSwap,
    this.eRC20Swap,
  });

  factory Contracts$SwapContracts.fromJson(Map<String, dynamic> json) =>
      _$Contracts$SwapContractsFromJson(json);

  static const toJsonFactory = _$Contracts$SwapContractsToJson;
  Map<String, dynamic> toJson() => _$Contracts$SwapContractsToJson(this);

  @JsonKey(name: 'EtherSwap', includeIfNull: false)
  final String? etherSwap;
  @JsonKey(name: 'ERC20Swap', includeIfNull: false)
  final String? eRC20Swap;
  static const fromJsonFactory = _$Contracts$SwapContractsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Contracts$SwapContracts &&
            (identical(other.etherSwap, etherSwap) ||
                const DeepCollectionEquality()
                    .equals(other.etherSwap, etherSwap)) &&
            (identical(other.eRC20Swap, eRC20Swap) ||
                const DeepCollectionEquality()
                    .equals(other.eRC20Swap, eRC20Swap)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(etherSwap) ^
      const DeepCollectionEquality().hash(eRC20Swap) ^
      runtimeType.hashCode;
}

extension $Contracts$SwapContractsExtension on Contracts$SwapContracts {
  Contracts$SwapContracts copyWith({String? etherSwap, String? eRC20Swap}) {
    return Contracts$SwapContracts(
        etherSwap: etherSwap ?? this.etherSwap,
        eRC20Swap: eRC20Swap ?? this.eRC20Swap);
  }

  Contracts$SwapContracts copyWithWrapped(
      {Wrapped<String?>? etherSwap, Wrapped<String?>? eRC20Swap}) {
    return Contracts$SwapContracts(
        etherSwap: (etherSwap != null ? etherSwap.value : this.etherSwap),
        eRC20Swap: (eRC20Swap != null ? eRC20Swap.value : this.eRC20Swap));
  }
}

@JsonSerializable(explicitToJson: true)
class SubmarinePair$Limits {
  const SubmarinePair$Limits({
    required this.minimal,
    required this.maximal,
    required this.maximalZeroConf,
  });

  factory SubmarinePair$Limits.fromJson(Map<String, dynamic> json) =>
      _$SubmarinePair$LimitsFromJson(json);

  static const toJsonFactory = _$SubmarinePair$LimitsToJson;
  Map<String, dynamic> toJson() => _$SubmarinePair$LimitsToJson(this);

  @JsonKey(name: 'minimal', includeIfNull: false)
  final double minimal;
  @JsonKey(name: 'maximal', includeIfNull: false)
  final double maximal;
  @JsonKey(name: 'maximalZeroConf', includeIfNull: false)
  final double maximalZeroConf;
  static const fromJsonFactory = _$SubmarinePair$LimitsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubmarinePair$Limits &&
            (identical(other.minimal, minimal) ||
                const DeepCollectionEquality()
                    .equals(other.minimal, minimal)) &&
            (identical(other.maximal, maximal) ||
                const DeepCollectionEquality()
                    .equals(other.maximal, maximal)) &&
            (identical(other.maximalZeroConf, maximalZeroConf) ||
                const DeepCollectionEquality()
                    .equals(other.maximalZeroConf, maximalZeroConf)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(minimal) ^
      const DeepCollectionEquality().hash(maximal) ^
      const DeepCollectionEquality().hash(maximalZeroConf) ^
      runtimeType.hashCode;
}

extension $SubmarinePair$LimitsExtension on SubmarinePair$Limits {
  SubmarinePair$Limits copyWith(
      {double? minimal, double? maximal, double? maximalZeroConf}) {
    return SubmarinePair$Limits(
        minimal: minimal ?? this.minimal,
        maximal: maximal ?? this.maximal,
        maximalZeroConf: maximalZeroConf ?? this.maximalZeroConf);
  }

  SubmarinePair$Limits copyWithWrapped(
      {Wrapped<double>? minimal,
      Wrapped<double>? maximal,
      Wrapped<double>? maximalZeroConf}) {
    return SubmarinePair$Limits(
        minimal: (minimal != null ? minimal.value : this.minimal),
        maximal: (maximal != null ? maximal.value : this.maximal),
        maximalZeroConf: (maximalZeroConf != null
            ? maximalZeroConf.value
            : this.maximalZeroConf));
  }
}

@JsonSerializable(explicitToJson: true)
class SubmarinePair$Fees {
  const SubmarinePair$Fees({
    required this.percentage,
    required this.minerFees,
  });

  factory SubmarinePair$Fees.fromJson(Map<String, dynamic> json) =>
      _$SubmarinePair$FeesFromJson(json);

  static const toJsonFactory = _$SubmarinePair$FeesToJson;
  Map<String, dynamic> toJson() => _$SubmarinePair$FeesToJson(this);

  @JsonKey(name: 'percentage', includeIfNull: false)
  final double percentage;
  @JsonKey(name: 'minerFees', includeIfNull: false)
  final double minerFees;
  static const fromJsonFactory = _$SubmarinePair$FeesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SubmarinePair$Fees &&
            (identical(other.percentage, percentage) ||
                const DeepCollectionEquality()
                    .equals(other.percentage, percentage)) &&
            (identical(other.minerFees, minerFees) ||
                const DeepCollectionEquality()
                    .equals(other.minerFees, minerFees)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(percentage) ^
      const DeepCollectionEquality().hash(minerFees) ^
      runtimeType.hashCode;
}

extension $SubmarinePair$FeesExtension on SubmarinePair$Fees {
  SubmarinePair$Fees copyWith({double? percentage, double? minerFees}) {
    return SubmarinePair$Fees(
        percentage: percentage ?? this.percentage,
        minerFees: minerFees ?? this.minerFees);
  }

  SubmarinePair$Fees copyWithWrapped(
      {Wrapped<double>? percentage, Wrapped<double>? minerFees}) {
    return SubmarinePair$Fees(
        percentage: (percentage != null ? percentage.value : this.percentage),
        minerFees: (minerFees != null ? minerFees.value : this.minerFees));
  }
}

@JsonSerializable(explicitToJson: true)
class ReversePair$Limits {
  const ReversePair$Limits({
    required this.minimal,
    required this.maximal,
  });

  factory ReversePair$Limits.fromJson(Map<String, dynamic> json) =>
      _$ReversePair$LimitsFromJson(json);

  static const toJsonFactory = _$ReversePair$LimitsToJson;
  Map<String, dynamic> toJson() => _$ReversePair$LimitsToJson(this);

  @JsonKey(name: 'minimal', includeIfNull: false)
  final double minimal;
  @JsonKey(name: 'maximal', includeIfNull: false)
  final double maximal;
  static const fromJsonFactory = _$ReversePair$LimitsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReversePair$Limits &&
            (identical(other.minimal, minimal) ||
                const DeepCollectionEquality()
                    .equals(other.minimal, minimal)) &&
            (identical(other.maximal, maximal) ||
                const DeepCollectionEquality().equals(other.maximal, maximal)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(minimal) ^
      const DeepCollectionEquality().hash(maximal) ^
      runtimeType.hashCode;
}

extension $ReversePair$LimitsExtension on ReversePair$Limits {
  ReversePair$Limits copyWith({double? minimal, double? maximal}) {
    return ReversePair$Limits(
        minimal: minimal ?? this.minimal, maximal: maximal ?? this.maximal);
  }

  ReversePair$Limits copyWithWrapped(
      {Wrapped<double>? minimal, Wrapped<double>? maximal}) {
    return ReversePair$Limits(
        minimal: (minimal != null ? minimal.value : this.minimal),
        maximal: (maximal != null ? maximal.value : this.maximal));
  }
}

@JsonSerializable(explicitToJson: true)
class ReversePair$Fees {
  const ReversePair$Fees({
    required this.percentage,
    required this.minerFees,
  });

  factory ReversePair$Fees.fromJson(Map<String, dynamic> json) =>
      _$ReversePair$FeesFromJson(json);

  static const toJsonFactory = _$ReversePair$FeesToJson;
  Map<String, dynamic> toJson() => _$ReversePair$FeesToJson(this);

  @JsonKey(name: 'percentage', includeIfNull: false)
  final double percentage;
  @JsonKey(name: 'minerFees', includeIfNull: false)
  final ReversePair$Fees$MinerFees minerFees;
  static const fromJsonFactory = _$ReversePair$FeesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReversePair$Fees &&
            (identical(other.percentage, percentage) ||
                const DeepCollectionEquality()
                    .equals(other.percentage, percentage)) &&
            (identical(other.minerFees, minerFees) ||
                const DeepCollectionEquality()
                    .equals(other.minerFees, minerFees)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(percentage) ^
      const DeepCollectionEquality().hash(minerFees) ^
      runtimeType.hashCode;
}

extension $ReversePair$FeesExtension on ReversePair$Fees {
  ReversePair$Fees copyWith(
      {double? percentage, ReversePair$Fees$MinerFees? minerFees}) {
    return ReversePair$Fees(
        percentage: percentage ?? this.percentage,
        minerFees: minerFees ?? this.minerFees);
  }

  ReversePair$Fees copyWithWrapped(
      {Wrapped<double>? percentage,
      Wrapped<ReversePair$Fees$MinerFees>? minerFees}) {
    return ReversePair$Fees(
        percentage: (percentage != null ? percentage.value : this.percentage),
        minerFees: (minerFees != null ? minerFees.value : this.minerFees));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainPair$Limits {
  const ChainPair$Limits({
    required this.minimal,
    required this.maximal,
  });

  factory ChainPair$Limits.fromJson(Map<String, dynamic> json) =>
      _$ChainPair$LimitsFromJson(json);

  static const toJsonFactory = _$ChainPair$LimitsToJson;
  Map<String, dynamic> toJson() => _$ChainPair$LimitsToJson(this);

  @JsonKey(name: 'minimal', includeIfNull: false)
  final double minimal;
  @JsonKey(name: 'maximal', includeIfNull: false)
  final double maximal;
  static const fromJsonFactory = _$ChainPair$LimitsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainPair$Limits &&
            (identical(other.minimal, minimal) ||
                const DeepCollectionEquality()
                    .equals(other.minimal, minimal)) &&
            (identical(other.maximal, maximal) ||
                const DeepCollectionEquality().equals(other.maximal, maximal)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(minimal) ^
      const DeepCollectionEquality().hash(maximal) ^
      runtimeType.hashCode;
}

extension $ChainPair$LimitsExtension on ChainPair$Limits {
  ChainPair$Limits copyWith({double? minimal, double? maximal}) {
    return ChainPair$Limits(
        minimal: minimal ?? this.minimal, maximal: maximal ?? this.maximal);
  }

  ChainPair$Limits copyWithWrapped(
      {Wrapped<double>? minimal, Wrapped<double>? maximal}) {
    return ChainPair$Limits(
        minimal: (minimal != null ? minimal.value : this.minimal),
        maximal: (maximal != null ? maximal.value : this.maximal));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainPair$Fees {
  const ChainPair$Fees({
    required this.percentage,
    required this.minerFees,
  });

  factory ChainPair$Fees.fromJson(Map<String, dynamic> json) =>
      _$ChainPair$FeesFromJson(json);

  static const toJsonFactory = _$ChainPair$FeesToJson;
  Map<String, dynamic> toJson() => _$ChainPair$FeesToJson(this);

  @JsonKey(name: 'percentage', includeIfNull: false)
  final double percentage;
  @JsonKey(name: 'minerFees', includeIfNull: false)
  final ChainPair$Fees$MinerFees minerFees;
  static const fromJsonFactory = _$ChainPair$FeesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainPair$Fees &&
            (identical(other.percentage, percentage) ||
                const DeepCollectionEquality()
                    .equals(other.percentage, percentage)) &&
            (identical(other.minerFees, minerFees) ||
                const DeepCollectionEquality()
                    .equals(other.minerFees, minerFees)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(percentage) ^
      const DeepCollectionEquality().hash(minerFees) ^
      runtimeType.hashCode;
}

extension $ChainPair$FeesExtension on ChainPair$Fees {
  ChainPair$Fees copyWith(
      {double? percentage, ChainPair$Fees$MinerFees? minerFees}) {
    return ChainPair$Fees(
        percentage: percentage ?? this.percentage,
        minerFees: minerFees ?? this.minerFees);
  }

  ChainPair$Fees copyWithWrapped(
      {Wrapped<double>? percentage,
      Wrapped<ChainPair$Fees$MinerFees>? minerFees}) {
    return ChainPair$Fees(
        percentage: (percentage != null ? percentage.value : this.percentage),
        minerFees: (minerFees != null ? minerFees.value : this.minerFees));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapTransaction$Transaction {
  const ChainSwapTransaction$Transaction({
    required this.id,
    this.hex,
  });

  factory ChainSwapTransaction$Transaction.fromJson(
          Map<String, dynamic> json) =>
      _$ChainSwapTransaction$TransactionFromJson(json);

  static const toJsonFactory = _$ChainSwapTransaction$TransactionToJson;
  Map<String, dynamic> toJson() =>
      _$ChainSwapTransaction$TransactionToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'hex', includeIfNull: false)
  final String? hex;
  static const fromJsonFactory = _$ChainSwapTransaction$TransactionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainSwapTransaction$Transaction &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.hex, hex) ||
                const DeepCollectionEquality().equals(other.hex, hex)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(hex) ^
      runtimeType.hashCode;
}

extension $ChainSwapTransaction$TransactionExtension
    on ChainSwapTransaction$Transaction {
  ChainSwapTransaction$Transaction copyWith({String? id, String? hex}) {
    return ChainSwapTransaction$Transaction(
        id: id ?? this.id, hex: hex ?? this.hex);
  }

  ChainSwapTransaction$Transaction copyWithWrapped(
      {Wrapped<String>? id, Wrapped<String?>? hex}) {
    return ChainSwapTransaction$Transaction(
        id: (id != null ? id.value : this.id),
        hex: (hex != null ? hex.value : this.hex));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapTransaction$Timeout {
  const ChainSwapTransaction$Timeout({
    required this.blockHeight,
    this.eta,
  });

  factory ChainSwapTransaction$Timeout.fromJson(Map<String, dynamic> json) =>
      _$ChainSwapTransaction$TimeoutFromJson(json);

  static const toJsonFactory = _$ChainSwapTransaction$TimeoutToJson;
  Map<String, dynamic> toJson() => _$ChainSwapTransaction$TimeoutToJson(this);

  @JsonKey(name: 'blockHeight', includeIfNull: false)
  final double blockHeight;
  @JsonKey(name: 'eta', includeIfNull: false)
  final double? eta;
  static const fromJsonFactory = _$ChainSwapTransaction$TimeoutFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainSwapTransaction$Timeout &&
            (identical(other.blockHeight, blockHeight) ||
                const DeepCollectionEquality()
                    .equals(other.blockHeight, blockHeight)) &&
            (identical(other.eta, eta) ||
                const DeepCollectionEquality().equals(other.eta, eta)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(blockHeight) ^
      const DeepCollectionEquality().hash(eta) ^
      runtimeType.hashCode;
}

extension $ChainSwapTransaction$TimeoutExtension
    on ChainSwapTransaction$Timeout {
  ChainSwapTransaction$Timeout copyWith({double? blockHeight, double? eta}) {
    return ChainSwapTransaction$Timeout(
        blockHeight: blockHeight ?? this.blockHeight, eta: eta ?? this.eta);
  }

  ChainSwapTransaction$Timeout copyWithWrapped(
      {Wrapped<double>? blockHeight, Wrapped<double?>? eta}) {
    return ChainSwapTransaction$Timeout(
        blockHeight:
            (blockHeight != null ? blockHeight.value : this.blockHeight),
        eta: (eta != null ? eta.value : this.eta));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapSigningRequest$ToSign {
  const ChainSwapSigningRequest$ToSign({
    required this.pubNonce,
    required this.transaction,
    required this.index,
  });

  factory ChainSwapSigningRequest$ToSign.fromJson(Map<String, dynamic> json) =>
      _$ChainSwapSigningRequest$ToSignFromJson(json);

  static const toJsonFactory = _$ChainSwapSigningRequest$ToSignToJson;
  Map<String, dynamic> toJson() => _$ChainSwapSigningRequest$ToSignToJson(this);

  @JsonKey(name: 'pubNonce', includeIfNull: false)
  final String pubNonce;
  @JsonKey(name: 'transaction', includeIfNull: false)
  final String transaction;
  @JsonKey(name: 'index', includeIfNull: false)
  final double index;
  static const fromJsonFactory = _$ChainSwapSigningRequest$ToSignFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainSwapSigningRequest$ToSign &&
            (identical(other.pubNonce, pubNonce) ||
                const DeepCollectionEquality()
                    .equals(other.pubNonce, pubNonce)) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality()
                    .equals(other.transaction, transaction)) &&
            (identical(other.index, index) ||
                const DeepCollectionEquality().equals(other.index, index)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(pubNonce) ^
      const DeepCollectionEquality().hash(transaction) ^
      const DeepCollectionEquality().hash(index) ^
      runtimeType.hashCode;
}

extension $ChainSwapSigningRequest$ToSignExtension
    on ChainSwapSigningRequest$ToSign {
  ChainSwapSigningRequest$ToSign copyWith(
      {String? pubNonce, String? transaction, double? index}) {
    return ChainSwapSigningRequest$ToSign(
        pubNonce: pubNonce ?? this.pubNonce,
        transaction: transaction ?? this.transaction,
        index: index ?? this.index);
  }

  ChainSwapSigningRequest$ToSign copyWithWrapped(
      {Wrapped<String>? pubNonce,
      Wrapped<String>? transaction,
      Wrapped<double>? index}) {
    return ChainSwapSigningRequest$ToSign(
        pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
        transaction:
            (transaction != null ? transaction.value : this.transaction),
        index: (index != null ? index.value : this.index));
  }
}

@JsonSerializable(explicitToJson: true)
class SwapStatus$Transaction {
  const SwapStatus$Transaction({
    this.id,
    this.hex,
  });

  factory SwapStatus$Transaction.fromJson(Map<String, dynamic> json) =>
      _$SwapStatus$TransactionFromJson(json);

  static const toJsonFactory = _$SwapStatus$TransactionToJson;
  Map<String, dynamic> toJson() => _$SwapStatus$TransactionToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String? id;
  @JsonKey(name: 'hex', includeIfNull: false)
  final String? hex;
  static const fromJsonFactory = _$SwapStatus$TransactionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SwapStatus$Transaction &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.hex, hex) ||
                const DeepCollectionEquality().equals(other.hex, hex)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(hex) ^
      runtimeType.hashCode;
}

extension $SwapStatus$TransactionExtension on SwapStatus$Transaction {
  SwapStatus$Transaction copyWith({String? id, String? hex}) {
    return SwapStatus$Transaction(id: id ?? this.id, hex: hex ?? this.hex);
  }

  SwapStatus$Transaction copyWithWrapped(
      {Wrapped<String?>? id, Wrapped<String?>? hex}) {
    return SwapStatus$Transaction(
        id: (id != null ? id.value : this.id),
        hex: (hex != null ? hex.value : this.hex));
  }
}

@JsonSerializable(explicitToJson: true)
class ReversePair$Fees$MinerFees {
  const ReversePair$Fees$MinerFees({
    required this.lockup,
    required this.claim,
  });

  factory ReversePair$Fees$MinerFees.fromJson(Map<String, dynamic> json) =>
      _$ReversePair$Fees$MinerFeesFromJson(json);

  static const toJsonFactory = _$ReversePair$Fees$MinerFeesToJson;
  Map<String, dynamic> toJson() => _$ReversePair$Fees$MinerFeesToJson(this);

  @JsonKey(name: 'lockup', includeIfNull: false)
  final double lockup;
  @JsonKey(name: 'claim', includeIfNull: false)
  final double claim;
  static const fromJsonFactory = _$ReversePair$Fees$MinerFeesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ReversePair$Fees$MinerFees &&
            (identical(other.lockup, lockup) ||
                const DeepCollectionEquality().equals(other.lockup, lockup)) &&
            (identical(other.claim, claim) ||
                const DeepCollectionEquality().equals(other.claim, claim)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(lockup) ^
      const DeepCollectionEquality().hash(claim) ^
      runtimeType.hashCode;
}

extension $ReversePair$Fees$MinerFeesExtension on ReversePair$Fees$MinerFees {
  ReversePair$Fees$MinerFees copyWith({double? lockup, double? claim}) {
    return ReversePair$Fees$MinerFees(
        lockup: lockup ?? this.lockup, claim: claim ?? this.claim);
  }

  ReversePair$Fees$MinerFees copyWithWrapped(
      {Wrapped<double>? lockup, Wrapped<double>? claim}) {
    return ReversePair$Fees$MinerFees(
        lockup: (lockup != null ? lockup.value : this.lockup),
        claim: (claim != null ? claim.value : this.claim));
  }
}

@JsonSerializable(explicitToJson: true)
class ChainPair$Fees$MinerFees {
  const ChainPair$Fees$MinerFees({
    required this.lockup,
    required this.claim,
  });

  factory ChainPair$Fees$MinerFees.fromJson(Map<String, dynamic> json) =>
      _$ChainPair$Fees$MinerFeesFromJson(json);

  static const toJsonFactory = _$ChainPair$Fees$MinerFeesToJson;
  Map<String, dynamic> toJson() => _$ChainPair$Fees$MinerFeesToJson(this);

  @JsonKey(name: 'lockup', includeIfNull: false)
  final double lockup;
  @JsonKey(name: 'claim', includeIfNull: false)
  final double claim;
  static const fromJsonFactory = _$ChainPair$Fees$MinerFeesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainPair$Fees$MinerFees &&
            (identical(other.lockup, lockup) ||
                const DeepCollectionEquality().equals(other.lockup, lockup)) &&
            (identical(other.claim, claim) ||
                const DeepCollectionEquality().equals(other.claim, claim)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(lockup) ^
      const DeepCollectionEquality().hash(claim) ^
      runtimeType.hashCode;
}

extension $ChainPair$Fees$MinerFeesExtension on ChainPair$Fees$MinerFees {
  ChainPair$Fees$MinerFees copyWith({double? lockup, double? claim}) {
    return ChainPair$Fees$MinerFees(
        lockup: lockup ?? this.lockup, claim: claim ?? this.claim);
  }

  ChainPair$Fees$MinerFees copyWithWrapped(
      {Wrapped<double>? lockup, Wrapped<double>? claim}) {
    return ChainPair$Fees$MinerFees(
        lockup: (lockup != null ? lockup.value : this.lockup),
        claim: (claim != null ? claim.value : this.claim));
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
      chopper.Response response) async {
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
          body: DateTime.parse((response.body as String).replaceAll('"', ''))
              as ResultType);
    }

    final jsonRes = await super.convertResponse(response);
    return jsonRes.copyWith<ResultType>(
        body: $jsonDecoder.decode<Item>(jsonRes.body) as ResultType);
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
