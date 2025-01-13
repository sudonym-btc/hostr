// GENERATED CODE - DO NOT MODIFY BY HAND

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
  Future<Response<Object>> _chainFeesGet() {
    final Uri $url = Uri.parse('/chain/fees');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _chainHeightsGet() {
    final Uri $url = Uri.parse('/chain/heights');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _chainContractsGet() {
    final Uri $url = Uri.parse('/chain/contracts');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<ChainCurrencyFeeGet$Response>> _chainCurrencyFeeGet(
      {required String? currency}) {
    final Uri $url = Uri.parse('/chain/${currency}/fee');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<ChainCurrencyFeeGet$Response,
        ChainCurrencyFeeGet$Response>($request);
  }

  @override
  Future<Response<ChainCurrencyHeightGet$Response>> _chainCurrencyHeightGet(
      {required String? currency}) {
    final Uri $url = Uri.parse('/chain/${currency}/height');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<ChainCurrencyHeightGet$Response,
        ChainCurrencyHeightGet$Response>($request);
  }

  @override
  Future<Response<ChainCurrencyTransactionIdGet$Response>>
      _chainCurrencyTransactionIdGet({
    required String? currency,
    required String? id,
  }) {
    final Uri $url = Uri.parse('/chain/${currency}/transaction/${id}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<ChainCurrencyTransactionIdGet$Response,
        ChainCurrencyTransactionIdGet$Response>($request);
  }

  @override
  Future<Response<ChainCurrencyTransactionPost$Response>>
      _chainCurrencyTransactionPost({
    required String? currency,
    required ChainCurrencyTransactionPost$RequestBody? body,
  }) {
    final Uri $url = Uri.parse('/chain/${currency}/transaction');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<ChainCurrencyTransactionPost$Response,
        ChainCurrencyTransactionPost$Response>($request);
  }

  @override
  Future<Response<Contracts>> _chainCurrencyContractsGet(
      {required String? currency}) {
    final Uri $url = Uri.parse('/chain/${currency}/contracts');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<Contracts, Contracts>($request);
  }

  @override
  Future<Response<VersionGet$Response>> _versionGet() {
    final Uri $url = Uri.parse('/version');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<VersionGet$Response, VersionGet$Response>($request);
  }

  @override
  Future<Response<List<String>>> _infosGet() {
    final Uri $url = Uri.parse('/infos');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<List<String>, String>($request);
  }

  @override
  Future<Response<List<String>>> _warningsGet() {
    final Uri $url = Uri.parse('/warnings');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<List<String>, String>($request);
  }

  @override
  Future<Response<LightningCurrencyBolt12FetchPost$Response>>
      _lightningCurrencyBolt12FetchPost({
    required String? currency,
    required LightningCurrencyBolt12FetchPost$RequestBody? body,
  }) {
    final Uri $url = Uri.parse('/lightning/${currency}/bolt12/fetch');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<LightningCurrencyBolt12FetchPost$Response,
        LightningCurrencyBolt12FetchPost$Response>($request);
  }

  @override
  Future<Response<Object>> _nodesGet() {
    final Uri $url = Uri.parse('/nodes');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _nodesStatsGet() {
    final Uri $url = Uri.parse('/nodes/stats');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<ReferralGet$Response>> _referralGet({
    String? ts,
    String? apikey,
    String? apihmac,
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
    );
    return client.send<ReferralGet$Response, ReferralGet$Response>($request);
  }

  @override
  Future<Response<Object>> _referralFeesGet({
    String? ts,
    String? apikey,
    String? apihmac,
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
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _referralStatsGet({
    String? ts,
    String? apikey,
    String? apihmac,
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
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _swapSubmarineGet() {
    final Uri $url = Uri.parse('/swap/submarine');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<SubmarineResponse>> _swapSubmarinePost(
      {required SubmarineRequest? body}) {
    final Uri $url = Uri.parse('/swap/submarine');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<SubmarineResponse, SubmarineResponse>($request);
  }

  @override
  Future<Response<SwapSubmarineIdInvoicePost$Response>>
      _swapSubmarineIdInvoicePost({
    required String? id,
    required SwapSubmarineIdInvoicePost$RequestBody? body,
  }) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/invoice');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<SwapSubmarineIdInvoicePost$Response,
        SwapSubmarineIdInvoicePost$Response>($request);
  }

  @override
  Future<Response<SwapSubmarineIdInvoiceAmountGet$Response>>
      _swapSubmarineIdInvoiceAmountGet({required String? id}) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/invoice/amount');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<SwapSubmarineIdInvoiceAmountGet$Response,
        SwapSubmarineIdInvoiceAmountGet$Response>($request);
  }

  @override
  Future<Response<SubmarineTransaction>> _swapSubmarineIdTransactionGet(
      {required String? id}) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/transaction');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<SubmarineTransaction, SubmarineTransaction>($request);
  }

  @override
  Future<Response<SubmarinePreimage>> _swapSubmarineIdPreimageGet(
      {required String? id}) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/preimage');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<SubmarinePreimage, SubmarinePreimage>($request);
  }

  @override
  Future<Response<SwapSubmarineIdRefundGet$Response>> _swapSubmarineIdRefundGet(
      {required String? id}) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/refund');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<SwapSubmarineIdRefundGet$Response,
        SwapSubmarineIdRefundGet$Response>($request);
  }

  @override
  Future<Response<PartialSignature>> _swapSubmarineIdRefundPost({
    required String? id,
    required RefundRequest? body,
  }) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/refund');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<PartialSignature, PartialSignature>($request);
  }

  @override
  Future<Response<SubmarineClaimDetails>> _swapSubmarineIdClaimGet(
      {required String? id}) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/claim');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<SubmarineClaimDetails, SubmarineClaimDetails>($request);
  }

  @override
  Future<Response<Object>> _swapSubmarineIdClaimPost({
    required String? id,
    required PartialSignature? body,
  }) {
    final Uri $url = Uri.parse('/swap/submarine/${id}/claim');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _swapReverseGet() {
    final Uri $url = Uri.parse('/swap/reverse');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<ReverseResponse>> _swapReversePost(
      {required ReverseRequest? body}) {
    final Uri $url = Uri.parse('/swap/reverse');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<ReverseResponse, ReverseResponse>($request);
  }

  @override
  Future<Response<ReverseTransaction>> _swapReverseIdTransactionGet(
      {required String? id}) {
    final Uri $url = Uri.parse('/swap/reverse/${id}/transaction');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<ReverseTransaction, ReverseTransaction>($request);
  }

  @override
  Future<Response<PartialSignature>> _swapReverseIdClaimPost({
    required String? id,
    required ReverseClaimRequest? body,
  }) {
    final Uri $url = Uri.parse('/swap/reverse/${id}/claim');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<PartialSignature, PartialSignature>($request);
  }

  @override
  Future<Response<ReverseBip21>> _swapReverseInvoiceBip21Get(
      {required String? invoice}) {
    final Uri $url = Uri.parse('/swap/reverse/${invoice}/bip21');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<ReverseBip21, ReverseBip21>($request);
  }

  @override
  Future<Response<Object>> _swapChainGet() {
    final Uri $url = Uri.parse('/swap/chain');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<ChainResponse>> _swapChainPost(
      {required ChainRequest? body}) {
    final Uri $url = Uri.parse('/swap/chain');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<ChainResponse, ChainResponse>($request);
  }

  @override
  Future<Response<ChainSwapTransactions>> _swapChainIdTransactionsGet(
      {required String? id}) {
    final Uri $url = Uri.parse('/swap/chain/${id}/transactions');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<ChainSwapTransactions, ChainSwapTransactions>($request);
  }

  @override
  Future<Response<ChainSwapSigningDetails>> _swapChainIdClaimGet(
      {required String? id}) {
    final Uri $url = Uri.parse('/swap/chain/${id}/claim');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client
        .send<ChainSwapSigningDetails, ChainSwapSigningDetails>($request);
  }

  @override
  Future<Response<PartialSignature>> _swapChainIdClaimPost({
    required String? id,
    required ChainSwapSigningRequest? body,
  }) {
    final Uri $url = Uri.parse('/swap/chain/${id}/claim');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<PartialSignature, PartialSignature>($request);
  }

  @override
  Future<Response<SwapChainIdRefundGet$Response>> _swapChainIdRefundGet(
      {required String? id}) {
    final Uri $url = Uri.parse('/swap/chain/${id}/refund');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<SwapChainIdRefundGet$Response,
        SwapChainIdRefundGet$Response>($request);
  }

  @override
  Future<Response<PartialSignature>> _swapChainIdRefundPost({
    required String? id,
    required RefundRequest? body,
  }) {
    final Uri $url = Uri.parse('/swap/chain/${id}/refund');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<PartialSignature, PartialSignature>($request);
  }

  @override
  Future<Response<Quote>> _swapChainIdQuoteGet({required String? id}) {
    final Uri $url = Uri.parse('/swap/chain/${id}/quote');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<Quote, Quote>($request);
  }

  @override
  Future<Response<QuoteResponse>> _swapChainIdQuotePost({
    required String? id,
    required Quote? body,
  }) {
    final Uri $url = Uri.parse('/swap/chain/${id}/quote');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
    );
    return client.send<QuoteResponse, QuoteResponse>($request);
  }

  @override
  Future<Response<SwapStatus>> _swapIdGet({required String? id}) {
    final Uri $url = Uri.parse('/swap/${id}');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
    );
    return client.send<SwapStatus, SwapStatus>($request);
  }
}
