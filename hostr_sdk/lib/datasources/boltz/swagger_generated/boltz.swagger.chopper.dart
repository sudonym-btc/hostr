// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'boltz.swagger.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$Boltz extends Boltz {
  _$Boltz([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = Boltz;

  @override
  Future<Response<Object>> _chainFeesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Fee estimations for all supported chains',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/chain/fees');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _chainHeightsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Block heights for all supported chains',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/chain/heights');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _chainContractsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get the network information and contract addresses for all supported EVM chains',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/chain/contracts');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<ChainCurrencyFeeGet$Response>> _chainCurrencyFeeGet({
    required String? currency,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Fee estimations for a chain',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/chain/${currency}/fee');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client
        .send<ChainCurrencyFeeGet$Response, ChainCurrencyFeeGet$Response>(
          $request,
        );
  }

  @override
  Future<Response<ChainCurrencyHeightGet$Response>> _chainCurrencyHeightGet({
    required String? currency,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Block height for a chain',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/chain/${currency}/height');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client
        .send<ChainCurrencyHeightGet$Response, ChainCurrencyHeightGet$Response>(
          $request,
        );
  }

  @override
  Future<Response<ChainCurrencyTransactionIdGet$Response>>
  _chainCurrencyTransactionIdGet({
    required String? currency,
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Fetch a raw transaction by its id',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/chain/${currency}/transaction/${id}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      ChainCurrencyTransactionIdGet$Response,
      ChainCurrencyTransactionIdGet$Response
    >($request);
  }

  @override
  Future<Response<ChainCurrencyTransactionPost$Response>>
  _chainCurrencyTransactionPost({
    required String? currency,
    required ChainCurrencyTransactionPost$RequestBody? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Broadcast a transaction',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/chain/${currency}/transaction');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      ChainCurrencyTransactionPost$Response,
      ChainCurrencyTransactionPost$Response
    >($request);
  }

  @override
  Future<Response<Contracts>> _chainCurrencyContractsGet({
    required String? currency,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get the network information and contract addresses for a supported EVM chains',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/chain/${currency}/contracts');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Contracts, Contracts>($request);
  }

  @override
  Future<Response<VersionGet$Response>> _versionGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Version of the backend',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Info"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/version');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<VersionGet$Response, VersionGet$Response>($request);
  }

  @override
  Future<Response<List<String>>> _infosGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Information about the configuration of the backend',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Info"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/infos');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<String>, String>($request);
  }

  @override
  Future<Response<List<String>>> _warningsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Warnings about the configuration of the backend',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Info"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/warnings');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<List<String>, String>($request);
  }

  @override
  Future<Response<LightningCurrencyBolt12FetchPost$Response>>
  _lightningCurrencyBolt12FetchPost({
    required String? currency,
    required LightningCurrencyBolt12FetchPost$RequestBody? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Fetches an invoice for a BOLT12 offer',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Lightning"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/lightning/${currency}/bolt12/fetch');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      LightningCurrencyBolt12FetchPost$Response,
      LightningCurrencyBolt12FetchPost$Response
    >($request);
  }

  @override
  Future<Response<Object>> _nodesGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Information about the Lightning nodes the backend is connected to',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Nodes"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/nodes');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _nodesStatsGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Statistics about the Lightning nodes the backend is connected to',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Nodes"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/nodes/stats');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<ReferralGet$Response>> _referralGet({
    String? ts,
    String? apikey,
    String? apihmac,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Referral ID for the used API keys',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Referral"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/referral');
    final Map<String, String> $headers = {
      if (ts != null) 'TS': ts,
      if (apikey != null) 'API-KEY': apikey,
      if (apihmac != null) 'API-HMAC': apihmac,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      headers: $headers,
      tag: swaggerMetaData,
    );
    return client.send<ReferralGet$Response, ReferralGet$Response>($request);
  }

  @override
  Future<Response<Object>> _referralFeesGet({
    String? ts,
    String? apikey,
    String? apihmac,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Referral fees collected for an ID',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Referral"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/referral/fees');
    final Map<String, String> $headers = {
      if (ts != null) 'TS': ts,
      if (apikey != null) 'API-KEY': apikey,
      if (apihmac != null) 'API-HMAC': apihmac,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      headers: $headers,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _referralStatsGet({
    String? ts,
    String? apikey,
    String? apihmac,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Statistics for Swaps created with an referral ID',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Referral"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/referral/stats');
    final Map<String, String> $headers = {
      if (ts != null) 'TS': ts,
      if (apikey != null) 'API-KEY': apikey,
      if (apihmac != null) 'API-HMAC': apihmac,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      headers: $headers,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _swapSubmarineGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Possible pairs for Submarine Swaps',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/submarine');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<SubmarineResponse>> _swapSubmarinePost({
    required SubmarineRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create a new Submarine Swap from onchain to lightning',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/submarine');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<SubmarineResponse, SubmarineResponse>($request);
  }

  @override
  Future<Response<SwapSubmarineIdInvoicePost$Response>>
  _swapSubmarineIdInvoicePost({
    required String? id,
    required SwapSubmarineIdInvoicePost$RequestBody? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Set the invoice for a Submarine Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/invoice');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<
      SwapSubmarineIdInvoicePost$Response,
      SwapSubmarineIdInvoicePost$Response
    >($request);
  }

  @override
  Future<Response<SwapSubmarineIdInvoiceAmountGet$Response>>
  _swapSubmarineIdInvoiceAmountGet({
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get the expected amount of the invoice that should be set after the Swap was created with a preimage hash and an onchain transaction was sent',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/invoice/amount');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      SwapSubmarineIdInvoiceAmountGet$Response,
      SwapSubmarineIdInvoiceAmountGet$Response
    >($request);
  }

  @override
  Future<Response<SubmarineTransaction>> _swapSubmarineIdTransactionGet({
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the lockup transaction of a Submarine Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/transaction');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SubmarineTransaction, SubmarineTransaction>($request);
  }

  @override
  Future<Response<SubmarinePreimage>> _swapSubmarineIdPreimageGet({
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the preimage of a successful Submarine Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/preimage');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SubmarinePreimage, SubmarinePreimage>($request);
  }

  @override
  Future<Response<SwapSubmarineIdRefundGet$Response>>
  _swapSubmarineIdRefundGet({
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get an EIP-712 signature for a cooperative EVM refund',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/refund');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<
      SwapSubmarineIdRefundGet$Response,
      SwapSubmarineIdRefundGet$Response
    >($request);
  }

  @override
  Future<Response<PartialSignature>> _swapSubmarineIdRefundPost({
    required String? id,
    required RefundRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Requests a partial signature for a cooperative Submarine Swap refund transaction',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/refund');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PartialSignature, PartialSignature>($request);
  }

  @override
  Future<Response<SubmarineClaimDetails>> _swapSubmarineIdClaimGet({
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get the needed information to post a partial signature for a cooperative Submarine Swap claim transaction',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/claim');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SubmarineClaimDetails, SubmarineClaimDetails>($request);
  }

  @override
  Future<Response<Object>> _swapSubmarineIdClaimPost({
    required String? id,
    required PartialSignature? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Send Boltz the clients partial signature for a cooperative Submarine Swap claim transaction',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/claim');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _swapReverseGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Possible pairs for Reverse Swaps',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Reverse"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/reverse');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<ReverseResponse>> _swapReversePost({
    required ReverseRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create a new Reverse Swap from lightning to onchain',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Reverse"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/reverse');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<ReverseResponse, ReverseResponse>($request);
  }

  @override
  Future<Response<ReverseTransaction>> _swapReverseIdTransactionGet({
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the lockup transaction of a Reverse Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Reverse"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/reverse/${id}/transaction');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<ReverseTransaction, ReverseTransaction>($request);
  }

  @override
  Future<Response<PartialSignature>> _swapReverseIdClaimPost({
    required String? id,
    required ReverseClaimRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Requests a partial signature for a cooperative Reverse Swap claim transaction. To settle the invoice, but not claim the onchain HTLC (eg to create a batched claim in the future), only the preimage is required. If no transaction is provided, an empty object is returned as response.',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Reverse"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/reverse/${id}/claim');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PartialSignature, PartialSignature>($request);
  }

  @override
  Future<Response<ReverseBip21>> _swapReverseInvoiceBip21Get({
    required String? invoice,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the BIP-21 of a Reverse Swap for a direct payment',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Reverse"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/reverse/${invoice}/bip21');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<ReverseBip21, ReverseBip21>($request);
  }

  @override
  Future<Response<Object>> _swapChainGet({
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Possible pairs for Chain Swaps',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain Swap"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/chain');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<ChainResponse>> _swapChainPost({
    required ChainRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Create a new Chain Swap from chain to chain. Omit "userLockAmount" and "serverLockAmount" to create a Chain Swap with an arbitrary amount',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain Swap"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/chain');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<ChainResponse, ChainResponse>($request);
  }

  @override
  Future<Response<ChainSwapTransactions>> _swapChainIdTransactionsGet({
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Gets the transactions of a Chain Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain Swap"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/chain/${id}/transactions');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<ChainSwapTransactions, ChainSwapTransactions>($request);
  }

  @override
  Future<Response<ChainSwapSigningDetails>> _swapChainIdClaimGet({
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Gets the server claim transaction signing details',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain Swap"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/chain/${id}/claim');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<ChainSwapSigningDetails, ChainSwapSigningDetails>(
      $request,
    );
  }

  @override
  Future<Response<PartialSignature>> _swapChainIdClaimPost({
    required String? id,
    required ChainSwapSigningRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Send Boltz a partial signature for its claim transaction and get a partial signature for the clients claim in return',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain Swap"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/chain/${id}/claim');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PartialSignature, PartialSignature>($request);
  }

  @override
  Future<Response<SwapChainIdRefundGet$Response>> _swapChainIdRefundGet({
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get an EIP-712 signature for a cooperative EVM refund',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain Swap"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/chain/${id}/refund');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client
        .send<SwapChainIdRefundGet$Response, SwapChainIdRefundGet$Response>(
          $request,
        );
  }

  @override
  Future<Response<PartialSignature>> _swapChainIdRefundPost({
    required String? id,
    required RefundRequest? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Requests a partial signature for a cooperative Chain Swap refund transaction',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain Swap"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/chain/${id}/refund');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<PartialSignature, PartialSignature>($request);
  }

  @override
  Future<Response<Quote>> _swapChainIdQuoteGet({
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Gets a new quote for an overpaid or underpaid Chain Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain Swap"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/chain/${id}/quote');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<Quote, Quote>($request);
  }

  @override
  Future<Response<QuoteResponse>> _swapChainIdQuotePost({
    required String? id,
    required Quote? body,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Accepts a new quote for a Chain Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain Swap"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/chain/${id}/quote');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<QuoteResponse, QuoteResponse>($request);
  }

  @override
  Future<Response<SwapStatus>> _swapIdGet({
    required String? id,
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the status of a Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Swap"],
      deprecated: false,
    ),
  }) {
    final Uri $url = Uri.parse('/swap/${id}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<SwapStatus, SwapStatus>($request);
  }
}
