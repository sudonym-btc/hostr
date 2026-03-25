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
import 'boltz.enums.swagger.dart' as enums;
import 'boltz.metadata.swagger.dart';
export 'boltz.enums.swagger.dart';

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
      baseUrl: baseUrl ?? Uri.parse('http://'),
    );
    return _$Boltz(newClient);
  }

  ///
  Future<chopper.Response<VersionGet$Response>> versionGet() {
    generatedMapping.putIfAbsent(
      VersionGet$Response,
      () => VersionGet$Response.fromJsonFactory,
    );

    return _versionGet();
  }

  ///
  @GET(path: '/version')
  Future<chopper.Response<VersionGet$Response>> _versionGet({
    @chopper.Tag()
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
  });

  ///
  Future<chopper.Response<List<String>>> infosGet() {
    return _infosGet();
  }

  ///
  @GET(path: '/infos')
  Future<chopper.Response<List<String>>> _infosGet({
    @chopper.Tag()
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
  });

  ///
  Future<chopper.Response<List<String>>> warningsGet() {
    return _warningsGet();
  }

  ///
  @GET(path: '/warnings')
  Future<chopper.Response<List<String>>> _warningsGet({
    @chopper.Tag()
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
  });

  ///
  Future<chopper.Response<Object>> swapSubmarineGet() {
    return _swapSubmarineGet();
  }

  ///
  @GET(path: '/swap/submarine')
  Future<chopper.Response<Object>> _swapSubmarineGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Possible pairs for Submarine Swaps',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine Swap"],
      deprecated: false,
    ),
  });

  ///
  Future<chopper.Response<SubmarineResponse>> swapSubmarinePost({
    required SubmarineRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      SubmarineResponse,
      () => SubmarineResponse.fromJsonFactory,
    );

    return _swapSubmarinePost(body: body);
  }

  ///
  @POST(path: '/swap/submarine', optionalBody: true)
  Future<chopper.Response<SubmarineResponse>> _swapSubmarinePost({
    @Body() required SubmarineRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create a new Submarine Swap from onchain to lightning',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Submarine Swap
  Future<chopper.Response<SwapSubmarineIdInvoicePost$Response>>
  swapSubmarineIdInvoicePost({
    required String? id,
    required SwapSubmarineIdInvoicePost$RequestBody? body,
  }) {
    generatedMapping.putIfAbsent(
      SwapSubmarineIdInvoicePost$Response,
      () => SwapSubmarineIdInvoicePost$Response.fromJsonFactory,
    );

    return _swapSubmarineIdInvoicePost(id: id, body: body);
  }

  ///
  ///@param id ID of the Submarine Swap
  @POST(path: '/swap/submarine/{id}/invoice', optionalBody: true)
  Future<chopper.Response<SwapSubmarineIdInvoicePost$Response>>
  _swapSubmarineIdInvoicePost({
    @Path('id') required String? id,
    @Body() required SwapSubmarineIdInvoicePost$RequestBody? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Set the invoice for a Submarine Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Submarine Swap
  Future<chopper.Response<SwapSubmarineIdInvoiceAmountGet$Response>>
  swapSubmarineIdInvoiceAmountGet({required String? id}) {
    generatedMapping.putIfAbsent(
      SwapSubmarineIdInvoiceAmountGet$Response,
      () => SwapSubmarineIdInvoiceAmountGet$Response.fromJsonFactory,
    );

    return _swapSubmarineIdInvoiceAmountGet(id: id);
  }

  ///
  ///@param id ID of the Submarine Swap
  @GET(path: '/swap/submarine/{id}/invoice/amount')
  Future<chopper.Response<SwapSubmarineIdInvoiceAmountGet$Response>>
  _swapSubmarineIdInvoiceAmountGet({
    @Path('id') required String? id,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get the expected amount of the invoice that should be set after the Swap was created with a preimage hash and an onchain transaction was sent',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Submarine Swap
  Future<chopper.Response<SubmarineTransaction>> swapSubmarineIdTransactionGet({
    required String? id,
  }) {
    generatedMapping.putIfAbsent(
      SubmarineTransaction,
      () => SubmarineTransaction.fromJsonFactory,
    );

    return _swapSubmarineIdTransactionGet(id: id);
  }

  ///
  ///@param id ID of the Submarine Swap
  @GET(path: '/swap/submarine/{id}/transaction')
  Future<chopper.Response<SubmarineTransaction>>
  _swapSubmarineIdTransactionGet({
    @Path('id') required String? id,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the lockup transaction of a Submarine Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Submarine Swap
  Future<chopper.Response<SubmarinePreimage>> swapSubmarineIdPreimageGet({
    required String? id,
  }) {
    generatedMapping.putIfAbsent(
      SubmarinePreimage,
      () => SubmarinePreimage.fromJsonFactory,
    );

    return _swapSubmarineIdPreimageGet(id: id);
  }

  ///
  ///@param id ID of the Submarine Swap
  @GET(path: '/swap/submarine/{id}/preimage')
  Future<chopper.Response<SubmarinePreimage>> _swapSubmarineIdPreimageGet({
    @Path('id') required String? id,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the preimage of a successful Submarine Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID or preimage hash of the Swap
  Future<chopper.Response<SwapSubmarineIdRefundGet$Response>>
  swapSubmarineIdRefundGet({required String? id}) {
    generatedMapping.putIfAbsent(
      SwapSubmarineIdRefundGet$Response,
      () => SwapSubmarineIdRefundGet$Response.fromJsonFactory,
    );

    return _swapSubmarineIdRefundGet(id: id);
  }

  ///
  ///@param id ID or preimage hash of the Swap
  @GET(path: '/swap/submarine/{id}/refund')
  Future<chopper.Response<SwapSubmarineIdRefundGet$Response>>
  _swapSubmarineIdRefundGet({
    @Path('id') required String? id,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get an EIP-712 signature for a cooperative EVM refund',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<PartialSignature>> swapSubmarineIdRefundPost({
    required String? id,
    required RefundRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      PartialSignature,
      () => PartialSignature.fromJsonFactory,
    );

    return _swapSubmarineIdRefundPost(id: id, body: body);
  }

  ///
  ///@param id ID of the Swap
  @POST(path: '/swap/submarine/{id}/refund', optionalBody: true)
  Future<chopper.Response<PartialSignature>> _swapSubmarineIdRefundPost({
    @Path('id') required String? id,
    @Body() required RefundRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Requests a partial signature for a cooperative Submarine Swap refund transaction',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Submarine Swap
  Future<chopper.Response<ArkRefundResponse>> swapSubmarineIdRefundArkPost({
    required String? id,
    required ArkRefundRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      ArkRefundResponse,
      () => ArkRefundResponse.fromJsonFactory,
    );

    return _swapSubmarineIdRefundArkPost(id: id, body: body);
  }

  ///
  ///@param id ID of the Submarine Swap
  @POST(path: '/swap/submarine/{id}/refund/ark', optionalBody: true)
  Future<chopper.Response<ArkRefundResponse>> _swapSubmarineIdRefundArkPost({
    @Path('id') required String? id,
    @Body() required ArkRefundRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Signs cooperative refund transactions for Ark Submarine Swaps',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<SubmarineClaimDetails>> swapSubmarineIdClaimGet({
    required String? id,
  }) {
    generatedMapping.putIfAbsent(
      SubmarineClaimDetails,
      () => SubmarineClaimDetails.fromJsonFactory,
    );

    return _swapSubmarineIdClaimGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @GET(path: '/swap/submarine/{id}/claim')
  Future<chopper.Response<SubmarineClaimDetails>> _swapSubmarineIdClaimGet({
    @Path('id') required String? id,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get the needed information to post a partial signature for a cooperative Submarine Swap claim transaction',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine Swap"],
      deprecated: false,
    ),
  });

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
  @POST(path: '/swap/submarine/{id}/claim', optionalBody: true)
  Future<chopper.Response<Object>> _swapSubmarineIdClaimPost({
    @Path('id') required String? id,
    @Body() required PartialSignature? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Send Boltz the clients partial signature for a cooperative Submarine Swap claim transaction',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Submarine Swap"],
      deprecated: false,
    ),
  });

  ///
  Future<chopper.Response<Object>> swapReverseGet() {
    return _swapReverseGet();
  }

  ///
  @GET(path: '/swap/reverse')
  Future<chopper.Response<Object>> _swapReverseGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Possible pairs for Reverse Swaps',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Reverse Swap"],
      deprecated: false,
    ),
  });

  ///
  Future<chopper.Response<ReverseResponse>> swapReversePost({
    required ReverseRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      ReverseResponse,
      () => ReverseResponse.fromJsonFactory,
    );

    return _swapReversePost(body: body);
  }

  ///
  @POST(path: '/swap/reverse', optionalBody: true)
  Future<chopper.Response<ReverseResponse>> _swapReversePost({
    @Body() required ReverseRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Create a new Reverse Swap from lightning to onchain',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Reverse Swap"],
      deprecated: false,
    ),
  });

  ///
  Future<chopper.Response<Object>> swapReverseExpiryGet() {
    return _swapReverseExpiryGet();
  }

  ///
  @GET(path: '/swap/reverse/expiry')
  Future<chopper.Response<Object>> _swapReverseExpiryGet({
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Allowed invoice expiry range in seconds per Reverse Swap pair',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Reverse Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Reverse Swap
  Future<chopper.Response<ReverseTransaction>> swapReverseIdTransactionGet({
    required String? id,
  }) {
    generatedMapping.putIfAbsent(
      ReverseTransaction,
      () => ReverseTransaction.fromJsonFactory,
    );

    return _swapReverseIdTransactionGet(id: id);
  }

  ///
  ///@param id ID of the Reverse Swap
  @GET(path: '/swap/reverse/{id}/transaction')
  Future<chopper.Response<ReverseTransaction>> _swapReverseIdTransactionGet({
    @Path('id') required String? id,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the lockup transaction of a Reverse Swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Reverse Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<PartialSignature>> swapReverseIdClaimPost({
    required String? id,
    required ReverseClaimRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      PartialSignature,
      () => PartialSignature.fromJsonFactory,
    );

    return _swapReverseIdClaimPost(id: id, body: body);
  }

  ///
  ///@param id ID of the Swap
  @POST(path: '/swap/reverse/{id}/claim', optionalBody: true)
  Future<chopper.Response<PartialSignature>> _swapReverseIdClaimPost({
    @Path('id') required String? id,
    @Body() required ReverseClaimRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Requests a partial signature for a cooperative Reverse Swap claim transaction. To settle the invoice, but not claim the onchain HTLC (eg to create a batched claim in the future), only the preimage is required. If no transaction is provided, an empty object is returned as response.',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Reverse Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param invoice Invoice of the Reverse Swap
  Future<chopper.Response<ReverseBip21>> swapReverseInvoiceBip21Get({
    required String? invoice,
  }) {
    generatedMapping.putIfAbsent(
      ReverseBip21,
      () => ReverseBip21.fromJsonFactory,
    );

    return _swapReverseInvoiceBip21Get(invoice: invoice);
  }

  ///
  ///@param invoice Invoice of the Reverse Swap
  @GET(path: '/swap/reverse/{invoice}/bip21')
  Future<chopper.Response<ReverseBip21>> _swapReverseInvoiceBip21Get({
    @Path('invoice') required String? invoice,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the BIP-21 of a Reverse Swap for a direct payment',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Reverse Swap"],
      deprecated: false,
    ),
  });

  ///
  Future<chopper.Response<Object>> swapChainGet() {
    return _swapChainGet();
  }

  ///
  @GET(path: '/swap/chain')
  Future<chopper.Response<Object>> _swapChainGet({
    @chopper.Tag()
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
  });

  ///
  Future<chopper.Response<ChainResponse>> swapChainPost({
    required ChainRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      ChainResponse,
      () => ChainResponse.fromJsonFactory,
    );

    return _swapChainPost(body: body);
  }

  ///
  @POST(path: '/swap/chain', optionalBody: true)
  Future<chopper.Response<ChainResponse>> _swapChainPost({
    @Body() required ChainRequest? body,
    @chopper.Tag()
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
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<ChainSwapTransactions>> swapChainIdTransactionsGet({
    required String? id,
  }) {
    generatedMapping.putIfAbsent(
      ChainSwapTransactions,
      () => ChainSwapTransactions.fromJsonFactory,
    );

    return _swapChainIdTransactionsGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @GET(path: '/swap/chain/{id}/transactions')
  Future<chopper.Response<ChainSwapTransactions>> _swapChainIdTransactionsGet({
    @Path('id') required String? id,
    @chopper.Tag()
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
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<ChainSwapSigningDetails>> swapChainIdClaimGet({
    required String? id,
  }) {
    generatedMapping.putIfAbsent(
      ChainSwapSigningDetails,
      () => ChainSwapSigningDetails.fromJsonFactory,
    );

    return _swapChainIdClaimGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @GET(path: '/swap/chain/{id}/claim')
  Future<chopper.Response<ChainSwapSigningDetails>> _swapChainIdClaimGet({
    @Path('id') required String? id,
    @chopper.Tag()
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
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response> swapChainIdClaimPost({
    required String? id,
    required ChainSwapSigningRequest? body,
  }) {
    return _swapChainIdClaimPost(id: id, body: body);
  }

  ///
  ///@param id ID of the Swap
  @POST(path: '/swap/chain/{id}/claim', optionalBody: true)
  Future<chopper.Response> _swapChainIdClaimPost({
    @Path('id') required String? id,
    @Body() required ChainSwapSigningRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Send Boltz a partial signature for its claim transaction and get a partial signature for the clients claim in return. If client claimed already, only providing "signature" is required and an empty object is returned.',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<SwapChainIdRefundGet$Response>> swapChainIdRefundGet({
    required String? id,
  }) {
    generatedMapping.putIfAbsent(
      SwapChainIdRefundGet$Response,
      () => SwapChainIdRefundGet$Response.fromJsonFactory,
    );

    return _swapChainIdRefundGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @GET(path: '/swap/chain/{id}/refund')
  Future<chopper.Response<SwapChainIdRefundGet$Response>>
  _swapChainIdRefundGet({
    @Path('id') required String? id,
    @chopper.Tag()
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
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<PartialSignature>> swapChainIdRefundPost({
    required String? id,
    required RefundRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      PartialSignature,
      () => PartialSignature.fromJsonFactory,
    );

    return _swapChainIdRefundPost(id: id, body: body);
  }

  ///
  ///@param id ID of the Swap
  @POST(path: '/swap/chain/{id}/refund', optionalBody: true)
  Future<chopper.Response<PartialSignature>> _swapChainIdRefundPost({
    @Path('id') required String? id,
    @Body() required RefundRequest? body,
    @chopper.Tag()
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
  });

  ///
  ///@param id ID of the Chain Swap
  Future<chopper.Response<ArkRefundResponse>> swapChainIdRefundArkPost({
    required String? id,
    required ArkRefundRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      ArkRefundResponse,
      () => ArkRefundResponse.fromJsonFactory,
    );

    return _swapChainIdRefundArkPost(id: id, body: body);
  }

  ///
  ///@param id ID of the Chain Swap
  @POST(path: '/swap/chain/{id}/refund/ark', optionalBody: true)
  Future<chopper.Response<ArkRefundResponse>> _swapChainIdRefundArkPost({
    @Path('id') required String? id,
    @Body() required ArkRefundRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Signs cooperative refund transactions for Ark Chain Swaps',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Chain Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<Quote>> swapChainIdQuoteGet({required String? id}) {
    generatedMapping.putIfAbsent(Quote, () => Quote.fromJsonFactory);

    return _swapChainIdQuoteGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @GET(path: '/swap/chain/{id}/quote')
  Future<chopper.Response<Quote>> _swapChainIdQuoteGet({
    @Path('id') required String? id,
    @chopper.Tag()
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
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<QuoteResponse>> swapChainIdQuotePost({
    required String? id,
    required Quote? body,
  }) {
    generatedMapping.putIfAbsent(
      QuoteResponse,
      () => QuoteResponse.fromJsonFactory,
    );

    return _swapChainIdQuotePost(id: id, body: body);
  }

  ///
  ///@param id ID of the Swap
  @POST(path: '/swap/chain/{id}/quote', optionalBody: true)
  Future<chopper.Response<QuoteResponse>> _swapChainIdQuotePost({
    @Path('id') required String? id,
    @Body() required Quote? body,
    @chopper.Tag()
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
  });

  ///
  ///@param ids Array of Swap IDs (max 64)
  Future<chopper.Response<Object>> swapStatusGet({required List<String>? ids}) {
    return _swapStatusGet(ids: ids);
  }

  ///
  ///@param ids Array of Swap IDs (max 64)
  @GET(path: '/swap/status')
  Future<chopper.Response<Object>> _swapStatusGet({
    @Query('ids') required List<String>? ids,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get the status of multiple Swaps',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param id ID of the Swap
  Future<chopper.Response<SwapStatus>> swapIdGet({required String? id}) {
    generatedMapping.putIfAbsent(SwapStatus, () => SwapStatus.fromJsonFactory);

    return _swapIdGet(id: id);
  }

  ///
  ///@param id ID of the Swap
  @GET(path: '/swap/{id}')
  Future<chopper.Response<SwapStatus>> _swapIdGet({
    @Path('id') required String? id,
    @chopper.Tag()
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
  });

  ///
  @deprecated
  Future<chopper.Response<List<RescuableSwap>>> swapRescuePost({
    required RescueRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      RescuableSwap,
      () => RescuableSwap.fromJsonFactory,
    );

    return _swapRescuePost(body: body);
  }

  ///
  @deprecated
  @POST(path: '/swap/rescue', optionalBody: true)
  Future<chopper.Response<List<RescuableSwap>>> _swapRescuePost({
    @Body() required RescueRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Rescue swaps by searching with an XPUB, a single public key, or multiple public keys. Returns swaps that can be refunded when all information was lost. Deprecated - use /swap/restore instead',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Swap"],
      deprecated: true,
    ),
  });

  ///
  Future<chopper.Response<List<RestorableSwap>>> swapRestorePost({
    required RescueRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      RestorableSwap,
      () => RestorableSwap.fromJsonFactory,
    );

    return _swapRestorePost(body: body);
  }

  ///
  @POST(path: '/swap/restore', optionalBody: true)
  Future<chopper.Response<List<RestorableSwap>>> _swapRestorePost({
    @Body() required RescueRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Restore swaps by searching with an XPUB, a single public key, or multiple public keys. Returns full swap details needed to resume, claim, or refund swaps when information was lost',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Swap"],
      deprecated: false,
    ),
  });

  ///
  Future<chopper.Response<RestoreIndexResponse>> swapRestoreIndexPost({
    required RescueRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      RestoreIndexResponse,
      () => RestoreIndexResponse.fromJsonFactory,
    );

    return _swapRestoreIndexPost(body: body);
  }

  ///
  @POST(path: '/swap/restore/index', optionalBody: true)
  Future<chopper.Response<RestoreIndexResponse>> _swapRestoreIndexPost({
    @Body() required RescueRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get the highest derivation index for swaps associated with an XPUB, a single public key, or multiple public keys. Useful for wallet restoration to determine the next key index to use. Returns -1 if no swaps are found',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Swap"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency symbol (currently only L-BTC is supported)
  Future<chopper.Response<AssetRescueSetupResponse>>
  assetCurrencyRescueSetupPost({
    required String? currency,
    required AssetRescueSetupRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      AssetRescueSetupResponse,
      () => AssetRescueSetupResponse.fromJsonFactory,
    );

    return _assetCurrencyRescueSetupPost(currency: currency, body: body);
  }

  ///
  ///@param currency Currency symbol (currently only L-BTC is supported)
  @POST(path: '/asset/{currency}/rescue/setup', optionalBody: true)
  Future<chopper.Response<AssetRescueSetupResponse>>
  _assetCurrencyRescueSetupPost({
    @Path('currency') required String? currency,
    @Body() required AssetRescueSetupRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Setup a cooperative asset rescue transaction for recovering locked funds. Only works for non L-BTC assets locked on Liquid.',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Asset Rescue"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency symbol (currently only L-BTC is supported)
  Future<chopper.Response<AssetRescueBroadcastResponse>>
  assetCurrencyRescueBroadcastPost({
    required String? currency,
    required AssetRescueBroadcastRequest? body,
  }) {
    generatedMapping.putIfAbsent(
      AssetRescueBroadcastResponse,
      () => AssetRescueBroadcastResponse.fromJsonFactory,
    );

    return _assetCurrencyRescueBroadcastPost(currency: currency, body: body);
  }

  ///
  ///@param currency Currency symbol (currently only L-BTC is supported)
  @POST(path: '/asset/{currency}/rescue/broadcast', optionalBody: true)
  Future<chopper.Response<AssetRescueBroadcastResponse>>
  _assetCurrencyRescueBroadcastPost({
    @Path('currency') required String? currency,
    @Body() required AssetRescueBroadcastRequest? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Broadcast a cooperative asset rescue transaction with the client\'s partial signature',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Asset Rescue"],
      deprecated: false,
    ),
  });

  ///
  ///@param swap_type Type of the swap
  ///@param from Source currency symbol
  ///@param to Destination currency symbol
  ///@param Referral Referral header must be set to 'pro' to access this endpoint
  Future<chopper.Response<PairStats>> swapSwapTypeStatsFromToGet({
    required enums.SwapSwapTypeStatsFromToGetSwapType? swapType,
    required String? from,
    required String? to,
    enums.SwapSwapTypeStatsFromToGetReferral? referral,
  }) {
    generatedMapping.putIfAbsent(PairStats, () => PairStats.fromJsonFactory);

    return _swapSwapTypeStatsFromToGet(
      swapType: swapType?.value?.toString(),
      from: from,
      to: to,
      referral: referral?.value?.toString(),
    );
  }

  ///
  ///@param swap_type Type of the swap
  ///@param from Source currency symbol
  ///@param to Destination currency symbol
  ///@param Referral Referral header must be set to 'pro' to access this endpoint
  @GET(path: '/swap/{swap_type}/stats/{from}/{to}')
  Future<chopper.Response<PairStats>> _swapSwapTypeStatsFromToGet({
    @Path('swap_type') required String? swapType,
    @Path('from') required String? from,
    @Path('to') required String? to,
    @Header('Referral') String? referral,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get historical fee statistics for pairs.',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Historical Data"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency of the lightning network to use
  ///@param node Public key of the node to get information for
  Future<chopper.Response<LightningNode>> lightningCurrencyNodeNodeGet({
    required String? currency,
    required String? node,
  }) {
    generatedMapping.putIfAbsent(
      LightningNode,
      () => LightningNode.fromJsonFactory,
    );

    return _lightningCurrencyNodeNodeGet(currency: currency, node: node);
  }

  ///
  ///@param currency Currency of the lightning network to use
  ///@param node Public key of the node to get information for
  @GET(path: '/lightning/{currency}/node/{node}')
  Future<chopper.Response<LightningNode>> _lightningCurrencyNodeNodeGet({
    @Path('currency') required String? currency,
    @Path('node') required String? node,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Gets information about a lightning node',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Lightning"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency of the lightning network to use
  ///@param id ID of the channel to get information for (LND and CLN style accepted)
  Future<chopper.Response<LightningChannelInfo>> lightningCurrencyChannelIdGet({
    required String? currency,
    required String? id,
  }) {
    generatedMapping.putIfAbsent(
      LightningChannelInfo,
      () => LightningChannelInfo.fromJsonFactory,
    );

    return _lightningCurrencyChannelIdGet(currency: currency, id: id);
  }

  ///
  ///@param currency Currency of the lightning network to use
  ///@param id ID of the channel to get information for (LND and CLN style accepted)
  @GET(path: '/lightning/{currency}/channel/{id}')
  Future<chopper.Response<LightningChannelInfo>>
  _lightningCurrencyChannelIdGet({
    @Path('currency') required String? currency,
    @Path('id') required String? id,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Gets information about a specific lightning channel',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Lightning"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency of the lightning network to use
  ///@param node Public key of the node to get channels for
  Future<chopper.Response<List<LightningChannel>>>
  lightningCurrencyChannelsNodeGet({
    required String? currency,
    required String? node,
  }) {
    generatedMapping.putIfAbsent(
      LightningChannel,
      () => LightningChannel.fromJsonFactory,
    );

    return _lightningCurrencyChannelsNodeGet(currency: currency, node: node);
  }

  ///
  ///@param currency Currency of the lightning network to use
  ///@param node Public key of the node to get channels for
  @GET(path: '/lightning/{currency}/channels/{node}')
  Future<chopper.Response<List<LightningChannel>>>
  _lightningCurrencyChannelsNodeGet({
    @Path('currency') required String? currency,
    @Path('node') required String? node,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Gets the channels of a lightning node',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Lightning"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency of the lightning network to use
  ///@param alias Alias of the node to search for
  Future<chopper.Response<List<LightningNode>>> lightningCurrencySearchGet({
    required String? currency,
    required String? alias,
  }) {
    generatedMapping.putIfAbsent(
      LightningNode,
      () => LightningNode.fromJsonFactory,
    );

    return _lightningCurrencySearchGet(currency: currency, alias: alias);
  }

  ///
  ///@param currency Currency of the lightning network to use
  ///@param alias Alias of the node to search for
  @GET(path: '/lightning/{currency}/search')
  Future<chopper.Response<List<LightningNode>>> _lightningCurrencySearchGet({
    @Path('currency') required String? currency,
    @Query('alias') required String? alias,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Search for lightning nodes by alias',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Lightning"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency of the lightning network to use
  Future<chopper.Response<Object>> lightningCurrencyBolt12Post({
    required String? currency,
    required LightningCurrencyBolt12Post$RequestBody? body,
  }) {
    return _lightningCurrencyBolt12Post(currency: currency, body: body);
  }

  ///
  ///@param currency Currency of the lightning network to use
  @POST(path: '/lightning/{currency}/bolt12', optionalBody: true)
  Future<chopper.Response<Object>> _lightningCurrencyBolt12Post({
    @Path('currency') required String? currency,
    @Body() required LightningCurrencyBolt12Post$RequestBody? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Creates a BOLT12 offer',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Lightning"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency of the lightning network to use
  Future<chopper.Response<Object>> lightningCurrencyBolt12Patch({
    required String? currency,
    required LightningCurrencyBolt12Patch$RequestBody? body,
  }) {
    return _lightningCurrencyBolt12Patch(currency: currency, body: body);
  }

  ///
  ///@param currency Currency of the lightning network to use
  @PATCH(path: '/lightning/{currency}/bolt12', optionalBody: true)
  Future<chopper.Response<Object>> _lightningCurrencyBolt12Patch({
    @Path('currency') required String? currency,
    @Body() required LightningCurrencyBolt12Patch$RequestBody? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Updates the webhook URL for a BOLT12 offer',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Lightning"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency of the lightning network to use
  Future<chopper.Response<Object>> lightningCurrencyBolt12Delete({
    required String? currency,
    required LightningCurrencyBolt12Delete$RequestBody? body,
  }) {
    return _lightningCurrencyBolt12Delete(currency: currency, body: body);
  }

  ///
  ///@param currency Currency of the lightning network to use
  @DELETE(path: '/lightning/{currency}/bolt12')
  Future<chopper.Response<Object>> _lightningCurrencyBolt12Delete({
    @Path('currency') required String? currency,
    @Body() required LightningCurrencyBolt12Delete$RequestBody? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Deletes a BOLT12 offer',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Lightning"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency of the lightning network to use
  ///@param receiving Symbol of the chain to which invoices of the offer should be swapped to
  Future<chopper.Response<LightningCurrencyBolt12ReceivingGet$Response>>
  lightningCurrencyBolt12ReceivingGet({
    required String? currency,
    required String? receiving,
  }) {
    generatedMapping.putIfAbsent(
      LightningCurrencyBolt12ReceivingGet$Response,
      () => LightningCurrencyBolt12ReceivingGet$Response.fromJsonFactory,
    );

    return _lightningCurrencyBolt12ReceivingGet(
      currency: currency,
      receiving: receiving,
    );
  }

  ///
  ///@param currency Currency of the lightning network to use
  ///@param receiving Symbol of the chain to which invoices of the offer should be swapped to
  @GET(path: '/lightning/{currency}/bolt12/{receiving}')
  Future<chopper.Response<LightningCurrencyBolt12ReceivingGet$Response>>
  _lightningCurrencyBolt12ReceivingGet({
    @Path('currency') required String? currency,
    @Path('receiving') required String? receiving,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Gets parameters for a BOLT12 offer',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Lightning"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency of the lightning network to use
  Future<chopper.Response<LightningCurrencyBolt12FetchPost$Response>>
  lightningCurrencyBolt12FetchPost({
    required String? currency,
    required LightningCurrencyBolt12FetchPost$RequestBody? body,
  }) {
    generatedMapping.putIfAbsent(
      LightningCurrencyBolt12FetchPost$Response,
      () => LightningCurrencyBolt12FetchPost$Response.fromJsonFactory,
    );

    return _lightningCurrencyBolt12FetchPost(currency: currency, body: body);
  }

  ///
  ///@param currency Currency of the lightning network to use
  @POST(path: '/lightning/{currency}/bolt12/fetch', optionalBody: true)
  Future<chopper.Response<LightningCurrencyBolt12FetchPost$Response>>
  _lightningCurrencyBolt12FetchPost({
    @Path('currency') required String? currency,
    @Body() required LightningCurrencyBolt12FetchPost$RequestBody? body,
    @chopper.Tag()
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
  });

  ///
  Future<chopper.Response<Object>> chainFeesGet() {
    return _chainFeesGet();
  }

  ///
  @GET(path: '/chain/fees')
  Future<chopper.Response<Object>> _chainFeesGet({
    @chopper.Tag()
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
  });

  ///
  Future<chopper.Response<Object>> chainHeightsGet() {
    return _chainHeightsGet();
  }

  ///
  @GET(path: '/chain/heights')
  Future<chopper.Response<Object>> _chainHeightsGet({
    @chopper.Tag()
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
  });

  ///
  Future<chopper.Response<Object>> chainContractsGet() {
    return _chainContractsGet();
  }

  ///
  @GET(path: '/chain/contracts')
  Future<chopper.Response<Object>> _chainContractsGet({
    @chopper.Tag()
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
  });

  ///
  ///@param currency Currency of the chain to get a fee estimation for
  Future<chopper.Response<ChainCurrencyFeeGet$Response>> chainCurrencyFeeGet({
    required String? currency,
  }) {
    generatedMapping.putIfAbsent(
      ChainCurrencyFeeGet$Response,
      () => ChainCurrencyFeeGet$Response.fromJsonFactory,
    );

    return _chainCurrencyFeeGet(currency: currency);
  }

  ///
  ///@param currency Currency of the chain to get a fee estimation for
  @GET(path: '/chain/{currency}/fee')
  Future<chopper.Response<ChainCurrencyFeeGet$Response>> _chainCurrencyFeeGet({
    @Path('currency') required String? currency,
    @chopper.Tag()
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
  });

  ///
  ///@param currency Currency of the chain to get the block height for
  Future<chopper.Response<ChainCurrencyHeightGet$Response>>
  chainCurrencyHeightGet({required String? currency}) {
    generatedMapping.putIfAbsent(
      ChainCurrencyHeightGet$Response,
      () => ChainCurrencyHeightGet$Response.fromJsonFactory,
    );

    return _chainCurrencyHeightGet(currency: currency);
  }

  ///
  ///@param currency Currency of the chain to get the block height for
  @GET(path: '/chain/{currency}/height')
  Future<chopper.Response<ChainCurrencyHeightGet$Response>>
  _chainCurrencyHeightGet({
    @Path('currency') required String? currency,
    @chopper.Tag()
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
  });

  ///
  ///@param currency Currency of the chain to query for
  ///@param id Id of the transaction to query
  Future<chopper.Response<ChainCurrencyTransactionIdGet$Response>>
  chainCurrencyTransactionIdGet({
    required String? currency,
    required String? id,
  }) {
    generatedMapping.putIfAbsent(
      ChainCurrencyTransactionIdGet$Response,
      () => ChainCurrencyTransactionIdGet$Response.fromJsonFactory,
    );

    return _chainCurrencyTransactionIdGet(currency: currency, id: id);
  }

  ///
  ///@param currency Currency of the chain to query for
  ///@param id Id of the transaction to query
  @GET(path: '/chain/{currency}/transaction/{id}')
  Future<chopper.Response<ChainCurrencyTransactionIdGet$Response>>
  _chainCurrencyTransactionIdGet({
    @Path('currency') required String? currency,
    @Path('id') required String? id,
    @chopper.Tag()
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
  });

  ///
  ///@param currency Currency of the chain to broadcast on
  Future<chopper.Response<ChainCurrencyTransactionPost$Response>>
  chainCurrencyTransactionPost({
    required String? currency,
    required ChainCurrencyTransactionPost$RequestBody? body,
  }) {
    generatedMapping.putIfAbsent(
      ChainCurrencyTransactionPost$Response,
      () => ChainCurrencyTransactionPost$Response.fromJsonFactory,
    );

    return _chainCurrencyTransactionPost(currency: currency, body: body);
  }

  ///
  ///@param currency Currency of the chain to broadcast on
  @POST(path: '/chain/{currency}/transaction', optionalBody: true)
  Future<chopper.Response<ChainCurrencyTransactionPost$Response>>
  _chainCurrencyTransactionPost({
    @Path('currency') required String? currency,
    @Body() required ChainCurrencyTransactionPost$RequestBody? body,
    @chopper.Tag()
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
  });

  ///
  ///@param currency Currency of the chain to query for
  Future<chopper.Response<Contracts>> chainCurrencyContractsGet({
    required String? currency,
  }) {
    generatedMapping.putIfAbsent(Contracts, () => Contracts.fromJsonFactory);

    return _chainCurrencyContractsGet(currency: currency);
  }

  ///
  ///@param currency Currency of the chain to query for
  @GET(path: '/chain/{currency}/contracts')
  Future<chopper.Response<Contracts>> _chainCurrencyContractsGet({
    @Path('currency') required String? currency,
    @chopper.Tag()
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
  });

  ///
  ///@param currency Network for the token swap
  ///@param tokenIn Token to swap from
  ///@param tokenOut Token to swap to
  ///@param amountIn Amount to swap
  Future<chopper.Response<List<TokenQuote>>> quoteCurrencyInGet({
    required String? currency,
    required String? tokenIn,
    required String? tokenOut,
    required String? amountIn,
  }) {
    generatedMapping.putIfAbsent(TokenQuote, () => TokenQuote.fromJsonFactory);

    return _quoteCurrencyInGet(
      currency: currency,
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      amountIn: amountIn,
    );
  }

  ///
  ///@param currency Network for the token swap
  ///@param tokenIn Token to swap from
  ///@param tokenOut Token to swap to
  ///@param amountIn Amount to swap
  @GET(path: '/quote/{currency}/in')
  Future<chopper.Response<List<TokenQuote>>> _quoteCurrencyInGet({
    @Path('currency') required String? currency,
    @Query('tokenIn') required String? tokenIn,
    @Query('tokenOut') required String? tokenOut,
    @Query('amountIn') required String? amountIn,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Gets quotes for a token swap with specified input amount',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Quotes"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Network for the token swap
  ///@param tokenIn Token to swap from
  ///@param tokenOut Token to swap to
  ///@param amountOut Amount to receive from swap
  Future<chopper.Response<List<TokenQuote>>> quoteCurrencyOutGet({
    required String? currency,
    required String? tokenIn,
    required String? tokenOut,
    required String? amountOut,
  }) {
    generatedMapping.putIfAbsent(TokenQuote, () => TokenQuote.fromJsonFactory);

    return _quoteCurrencyOutGet(
      currency: currency,
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      amountOut: amountOut,
    );
  }

  ///
  ///@param currency Network for the token swap
  ///@param tokenIn Token to swap from
  ///@param tokenOut Token to swap to
  ///@param amountOut Amount to receive from swap
  @GET(path: '/quote/{currency}/out')
  Future<chopper.Response<List<TokenQuote>>> _quoteCurrencyOutGet({
    @Path('currency') required String? currency,
    @Query('tokenIn') required String? tokenIn,
    @Query('tokenOut') required String? tokenOut,
    @Query('amountOut') required String? amountOut,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Gets quotes for a token swap with specified output amount',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Quotes"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Network for the token swap
  Future<chopper.Response<QuoteCurrencyEncodePost$Response>>
  quoteCurrencyEncodePost({
    required String? currency,
    required QuoteCurrencyEncodePost$RequestBody? body,
  }) {
    generatedMapping.putIfAbsent(
      QuoteCurrencyEncodePost$Response,
      () => QuoteCurrencyEncodePost$Response.fromJsonFactory,
    );

    return _quoteCurrencyEncodePost(currency: currency, body: body);
  }

  ///
  ///@param currency Network for the token swap
  @POST(path: '/quote/{currency}/encode', optionalBody: true)
  Future<chopper.Response<QuoteCurrencyEncodePost$Response>>
  _quoteCurrencyEncodePost({
    @Path('currency') required String? currency,
    @Body() required QuoteCurrencyEncodePost$RequestBody? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Encodes calldata for a token swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Quotes"],
      deprecated: false,
    ),
  });

  ///
  Future<chopper.Response<Object>> nodesGet() {
    return _nodesGet();
  }

  ///
  @GET(path: '/nodes')
  Future<chopper.Response<Object>> _nodesGet({
    @chopper.Tag()
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
  });

  ///
  Future<chopper.Response<Object>> nodesStatsGet() {
    return _nodesStatsGet();
  }

  ///
  @GET(path: '/nodes/stats')
  Future<chopper.Response<Object>> _nodesStatsGet({
    @chopper.Tag()
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
  });

  ///
  ///@param currency Currency of the chain to get lockup details for
  Future<chopper.Response<CommitmentLockupDetails>>
  commitmentCurrencyDetailsGet({required String? currency}) {
    generatedMapping.putIfAbsent(
      CommitmentLockupDetails,
      () => CommitmentLockupDetails.fromJsonFactory,
    );

    return _commitmentCurrencyDetailsGet(currency: currency);
  }

  ///
  ///@param currency Currency of the chain to get lockup details for
  @GET(path: '/commitment/{currency}/details')
  Future<chopper.Response<CommitmentLockupDetails>>
  _commitmentCurrencyDetailsGet({
    @Path('currency') required String? currency,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Get lockup details for commitment swaps on an EVM chain',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Commitment"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency Currency of the commitment
  Future<chopper.Response<Object>> commitmentCurrencyPost({
    required String? currency,
    required CommitmentCurrencyPost$RequestBody? body,
  }) {
    return _commitmentCurrencyPost(currency: currency, body: body);
  }

  ///
  ///@param currency Currency of the commitment
  @POST(path: '/commitment/{currency}', optionalBody: true)
  Future<chopper.Response<Object>> _commitmentCurrencyPost({
    @Path('currency') required String? currency,
    @Body() required CommitmentCurrencyPost$RequestBody? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Submit a commitment for a swap',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Commitment"],
      deprecated: false,
    ),
  });

  ///
  ///@param currency
  Future<chopper.Response<CommitmentCurrencyRefundPost$Response>>
  commitmentCurrencyRefundPost({
    required String? currency,
    required CommitmentCurrencyRefundPost$RequestBody? body,
  }) {
    generatedMapping.putIfAbsent(
      CommitmentCurrencyRefundPost$Response,
      () => CommitmentCurrencyRefundPost$Response.fromJsonFactory,
    );

    return _commitmentCurrencyRefundPost(currency: currency, body: body);
  }

  ///
  ///@param currency
  @POST(path: '/commitment/{currency}/refund', optionalBody: true)
  Future<chopper.Response<CommitmentCurrencyRefundPost$Response>>
  _commitmentCurrencyRefundPost({
    @Path('currency') required String? currency,
    @Body() required CommitmentCurrencyRefundPost$RequestBody? body,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description:
          'Get an EIP-712 signature for a cooperative refund of an unlinked commitment',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Commitment"],
      deprecated: false,
    ),
  });

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
      ReferralGet$Response,
      () => ReferralGet$Response.fromJsonFactory,
    );

    return _referralGet(
      ts: ts?.toString(),
      apikey: apikey?.toString(),
      apihmac: apihmac?.toString(),
    );
  }

  ///
  ///@param TS Current UNIX timestamp when the request is sent
  ///@param API-KEY Your API key
  ///@param API-HMAC HMAC-SHA256 with your API-Secret as key of the TS + HTTP method (all uppercase) + the HTTP path
  @GET(path: '/referral')
  Future<chopper.Response<ReferralGet$Response>> _referralGet({
    @Header('TS') String? ts,
    @Header('API-KEY') String? apikey,
    @Header('API-HMAC') String? apihmac,
    @chopper.Tag()
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
      apihmac: apihmac?.toString(),
    );
  }

  ///
  ///@param TS Current UNIX timestamp when the request is sent
  ///@param API-KEY Your API key
  ///@param API-HMAC HMAC-SHA256 with your API-Secret as key of the TS + HTTP method (all uppercase) + the HTTP path
  @GET(path: '/referral/fees')
  Future<chopper.Response<Object>> _referralFeesGet({
    @Header('TS') String? ts,
    @Header('API-KEY') String? apikey,
    @Header('API-HMAC') String? apihmac,
    @chopper.Tag()
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
      apihmac: apihmac?.toString(),
    );
  }

  ///
  ///@param TS Current UNIX timestamp when the request is sent
  ///@param API-KEY Your API key
  ///@param API-HMAC HMAC-SHA256 with your API-Secret as key of the TS + HTTP method (all uppercase) + the HTTP path
  @GET(path: '/referral/stats')
  Future<chopper.Response<Object>> _referralStatsGet({
    @Header('TS') String? ts,
    @Header('API-KEY') String? apikey,
    @Header('API-HMAC') String? apihmac,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Statistics for Swaps created with a referral ID',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Referral"],
      deprecated: false,
    ),
  });

  ///
  ///@param TS Current UNIX timestamp when the request is sent
  ///@param API-KEY Your API key
  ///@param API-HMAC HMAC-SHA256 with your API-Secret as key of the TS + HTTP method (all uppercase) + the HTTP path
  Future<chopper.Response<Object>> referralStatsExtraGet({
    String? ts,
    String? apikey,
    String? apihmac,
  }) {
    return _referralStatsExtraGet(
      ts: ts?.toString(),
      apikey: apikey?.toString(),
      apihmac: apihmac?.toString(),
    );
  }

  ///
  ///@param TS Current UNIX timestamp when the request is sent
  ///@param API-KEY Your API key
  ///@param API-HMAC HMAC-SHA256 with your API-Secret as key of the TS + HTTP method (all uppercase) + the HTTP path
  @GET(path: '/referral/stats/extra')
  Future<chopper.Response<Object>> _referralStatsExtraGet({
    @Header('TS') String? ts,
    @Header('API-KEY') String? apikey,
    @Header('API-HMAC') String? apihmac,
    @chopper.Tag()
    SwaggerMetaData swaggerMetaData = const SwaggerMetaData(
      description: 'Extra fees collected for swaps created with a referral ID',
      summary: '',
      operationId: '',
      consumes: [],
      produces: [],
      security: [],
      tags: ["Referral"],
      deprecated: false,
    ),
  });
}

@JsonSerializable(explicitToJson: true)
class ArkTimeouts {
  const ArkTimeouts({
    required this.refund,
    required this.unilateralClaim,
    required this.unilateralRefund,
    required this.unilateralRefundWithoutReceiver,
  });

  factory ArkTimeouts.fromJson(Map<String, dynamic> json) =>
      _$ArkTimeoutsFromJson(json);

  static const toJsonFactory = _$ArkTimeoutsToJson;
  Map<String, dynamic> toJson() => _$ArkTimeoutsToJson(this);

  @JsonKey(name: 'refund', includeIfNull: false)
  final double refund;
  @JsonKey(name: 'unilateralClaim', includeIfNull: false)
  final double unilateralClaim;
  @JsonKey(name: 'unilateralRefund', includeIfNull: false)
  final double unilateralRefund;
  @JsonKey(name: 'unilateralRefundWithoutReceiver', includeIfNull: false)
  final double unilateralRefundWithoutReceiver;
  static const fromJsonFactory = _$ArkTimeoutsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ArkTimeouts &&
            (identical(other.refund, refund) ||
                const DeepCollectionEquality().equals(other.refund, refund)) &&
            (identical(other.unilateralClaim, unilateralClaim) ||
                const DeepCollectionEquality().equals(
                  other.unilateralClaim,
                  unilateralClaim,
                )) &&
            (identical(other.unilateralRefund, unilateralRefund) ||
                const DeepCollectionEquality().equals(
                  other.unilateralRefund,
                  unilateralRefund,
                )) &&
            (identical(
                  other.unilateralRefundWithoutReceiver,
                  unilateralRefundWithoutReceiver,
                ) ||
                const DeepCollectionEquality().equals(
                  other.unilateralRefundWithoutReceiver,
                  unilateralRefundWithoutReceiver,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(refund) ^
      const DeepCollectionEquality().hash(unilateralClaim) ^
      const DeepCollectionEquality().hash(unilateralRefund) ^
      const DeepCollectionEquality().hash(unilateralRefundWithoutReceiver) ^
      runtimeType.hashCode;
}

extension $ArkTimeoutsExtension on ArkTimeouts {
  ArkTimeouts copyWith({
    double? refund,
    double? unilateralClaim,
    double? unilateralRefund,
    double? unilateralRefundWithoutReceiver,
  }) {
    return ArkTimeouts(
      refund: refund ?? this.refund,
      unilateralClaim: unilateralClaim ?? this.unilateralClaim,
      unilateralRefund: unilateralRefund ?? this.unilateralRefund,
      unilateralRefundWithoutReceiver:
          unilateralRefundWithoutReceiver ??
          this.unilateralRefundWithoutReceiver,
    );
  }

  ArkTimeouts copyWithWrapped({
    Wrapped<double>? refund,
    Wrapped<double>? unilateralClaim,
    Wrapped<double>? unilateralRefund,
    Wrapped<double>? unilateralRefundWithoutReceiver,
  }) {
    return ArkTimeouts(
      refund: (refund != null ? refund.value : this.refund),
      unilateralClaim: (unilateralClaim != null
          ? unilateralClaim.value
          : this.unilateralClaim),
      unilateralRefund: (unilateralRefund != null
          ? unilateralRefund.value
          : this.unilateralRefund),
      unilateralRefundWithoutReceiver: (unilateralRefundWithoutReceiver != null
          ? unilateralRefundWithoutReceiver.value
          : this.unilateralRefundWithoutReceiver),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SwapTreeLeaf {
  const SwapTreeLeaf({required this.version, required this.output});

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
                const DeepCollectionEquality().equals(
                  other.version,
                  version,
                )) &&
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
      version: version ?? this.version,
      output: output ?? this.output,
    );
  }

  SwapTreeLeaf copyWithWrapped({
    Wrapped<double>? version,
    Wrapped<String>? output,
  }) {
    return SwapTreeLeaf(
      version: (version != null ? version.value : this.version),
      output: (output != null ? output.value : this.output),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SwapTree {
  const SwapTree({
    required this.claimLeaf,
    required this.refundLeaf,
    this.covenantClaimLeaf,
    this.refundWithoutBoltzLeaf,
    this.unilateralClaimLeaf,
    this.unilateralRefundLeaf,
    this.unilateralRefundWithoutBoltzLeaf,
  });

  factory SwapTree.fromJson(Map<String, dynamic> json) =>
      _$SwapTreeFromJson(json);

  static const toJsonFactory = _$SwapTreeToJson;
  Map<String, dynamic> toJson() => _$SwapTreeToJson(this);

  @JsonKey(name: 'claimLeaf', includeIfNull: false)
  final SwapTreeLeaf claimLeaf;
  @JsonKey(name: 'refundLeaf', includeIfNull: false)
  final SwapTreeLeaf refundLeaf;
  @JsonKey(name: 'covenantClaimLeaf', includeIfNull: false)
  final SwapTreeLeaf? covenantClaimLeaf;
  @JsonKey(name: 'refundWithoutBoltzLeaf', includeIfNull: false)
  final SwapTreeLeaf? refundWithoutBoltzLeaf;
  @JsonKey(name: 'unilateralClaimLeaf', includeIfNull: false)
  final SwapTreeLeaf? unilateralClaimLeaf;
  @JsonKey(name: 'unilateralRefundLeaf', includeIfNull: false)
  final SwapTreeLeaf? unilateralRefundLeaf;
  @JsonKey(name: 'unilateralRefundWithoutBoltzLeaf', includeIfNull: false)
  final SwapTreeLeaf? unilateralRefundWithoutBoltzLeaf;
  static const fromJsonFactory = _$SwapTreeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is SwapTree &&
            (identical(other.claimLeaf, claimLeaf) ||
                const DeepCollectionEquality().equals(
                  other.claimLeaf,
                  claimLeaf,
                )) &&
            (identical(other.refundLeaf, refundLeaf) ||
                const DeepCollectionEquality().equals(
                  other.refundLeaf,
                  refundLeaf,
                )) &&
            (identical(other.covenantClaimLeaf, covenantClaimLeaf) ||
                const DeepCollectionEquality().equals(
                  other.covenantClaimLeaf,
                  covenantClaimLeaf,
                )) &&
            (identical(other.refundWithoutBoltzLeaf, refundWithoutBoltzLeaf) ||
                const DeepCollectionEquality().equals(
                  other.refundWithoutBoltzLeaf,
                  refundWithoutBoltzLeaf,
                )) &&
            (identical(other.unilateralClaimLeaf, unilateralClaimLeaf) ||
                const DeepCollectionEquality().equals(
                  other.unilateralClaimLeaf,
                  unilateralClaimLeaf,
                )) &&
            (identical(other.unilateralRefundLeaf, unilateralRefundLeaf) ||
                const DeepCollectionEquality().equals(
                  other.unilateralRefundLeaf,
                  unilateralRefundLeaf,
                )) &&
            (identical(
                  other.unilateralRefundWithoutBoltzLeaf,
                  unilateralRefundWithoutBoltzLeaf,
                ) ||
                const DeepCollectionEquality().equals(
                  other.unilateralRefundWithoutBoltzLeaf,
                  unilateralRefundWithoutBoltzLeaf,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(claimLeaf) ^
      const DeepCollectionEquality().hash(refundLeaf) ^
      const DeepCollectionEquality().hash(covenantClaimLeaf) ^
      const DeepCollectionEquality().hash(refundWithoutBoltzLeaf) ^
      const DeepCollectionEquality().hash(unilateralClaimLeaf) ^
      const DeepCollectionEquality().hash(unilateralRefundLeaf) ^
      const DeepCollectionEquality().hash(unilateralRefundWithoutBoltzLeaf) ^
      runtimeType.hashCode;
}

extension $SwapTreeExtension on SwapTree {
  SwapTree copyWith({
    SwapTreeLeaf? claimLeaf,
    SwapTreeLeaf? refundLeaf,
    SwapTreeLeaf? covenantClaimLeaf,
    SwapTreeLeaf? refundWithoutBoltzLeaf,
    SwapTreeLeaf? unilateralClaimLeaf,
    SwapTreeLeaf? unilateralRefundLeaf,
    SwapTreeLeaf? unilateralRefundWithoutBoltzLeaf,
  }) {
    return SwapTree(
      claimLeaf: claimLeaf ?? this.claimLeaf,
      refundLeaf: refundLeaf ?? this.refundLeaf,
      covenantClaimLeaf: covenantClaimLeaf ?? this.covenantClaimLeaf,
      refundWithoutBoltzLeaf:
          refundWithoutBoltzLeaf ?? this.refundWithoutBoltzLeaf,
      unilateralClaimLeaf: unilateralClaimLeaf ?? this.unilateralClaimLeaf,
      unilateralRefundLeaf: unilateralRefundLeaf ?? this.unilateralRefundLeaf,
      unilateralRefundWithoutBoltzLeaf:
          unilateralRefundWithoutBoltzLeaf ??
          this.unilateralRefundWithoutBoltzLeaf,
    );
  }

  SwapTree copyWithWrapped({
    Wrapped<SwapTreeLeaf>? claimLeaf,
    Wrapped<SwapTreeLeaf>? refundLeaf,
    Wrapped<SwapTreeLeaf?>? covenantClaimLeaf,
    Wrapped<SwapTreeLeaf?>? refundWithoutBoltzLeaf,
    Wrapped<SwapTreeLeaf?>? unilateralClaimLeaf,
    Wrapped<SwapTreeLeaf?>? unilateralRefundLeaf,
    Wrapped<SwapTreeLeaf?>? unilateralRefundWithoutBoltzLeaf,
  }) {
    return SwapTree(
      claimLeaf: (claimLeaf != null ? claimLeaf.value : this.claimLeaf),
      refundLeaf: (refundLeaf != null ? refundLeaf.value : this.refundLeaf),
      covenantClaimLeaf: (covenantClaimLeaf != null
          ? covenantClaimLeaf.value
          : this.covenantClaimLeaf),
      refundWithoutBoltzLeaf: (refundWithoutBoltzLeaf != null
          ? refundWithoutBoltzLeaf.value
          : this.refundWithoutBoltzLeaf),
      unilateralClaimLeaf: (unilateralClaimLeaf != null
          ? unilateralClaimLeaf.value
          : this.unilateralClaimLeaf),
      unilateralRefundLeaf: (unilateralRefundLeaf != null
          ? unilateralRefundLeaf.value
          : this.unilateralRefundLeaf),
      unilateralRefundWithoutBoltzLeaf:
          (unilateralRefundWithoutBoltzLeaf != null
          ? unilateralRefundWithoutBoltzLeaf.value
          : this.unilateralRefundWithoutBoltzLeaf),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ExtraFees {
  const ExtraFees({required this.id, this.percentage});

  factory ExtraFees.fromJson(Map<String, dynamic> json) =>
      _$ExtraFeesFromJson(json);

  static const toJsonFactory = _$ExtraFeesToJson;
  Map<String, dynamic> toJson() => _$ExtraFeesToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'percentage', includeIfNull: false)
  final double? percentage;
  static const fromJsonFactory = _$ExtraFeesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ExtraFees &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.percentage, percentage) ||
                const DeepCollectionEquality().equals(
                  other.percentage,
                  percentage,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(percentage) ^
      runtimeType.hashCode;
}

extension $ExtraFeesExtension on ExtraFees {
  ExtraFees copyWith({String? id, double? percentage}) {
    return ExtraFees(
      id: id ?? this.id,
      percentage: percentage ?? this.percentage,
    );
  }

  ExtraFees copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<double?>? percentage,
  }) {
    return ExtraFees(
      id: (id != null ? id.value : this.id),
      percentage: (percentage != null ? percentage.value : this.percentage),
    );
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
  SubmarinePair copyWith({
    String? hash,
    double? rate,
    SubmarinePair$Limits? limits,
    SubmarinePair$Fees? fees,
  }) {
    return SubmarinePair(
      hash: hash ?? this.hash,
      rate: rate ?? this.rate,
      limits: limits ?? this.limits,
      fees: fees ?? this.fees,
    );
  }

  SubmarinePair copyWithWrapped({
    Wrapped<String>? hash,
    Wrapped<double>? rate,
    Wrapped<SubmarinePair$Limits>? limits,
    Wrapped<SubmarinePair$Fees>? fees,
  }) {
    return SubmarinePair(
      hash: (hash != null ? hash.value : this.hash),
      rate: (rate != null ? rate.value : this.rate),
      limits: (limits != null ? limits.value : this.limits),
      fees: (fees != null ? fees.value : this.fees),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class WebhookData {
  const WebhookData({required this.url, this.hashSwapId, this.status});

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
                const DeepCollectionEquality().equals(
                  other.hashSwapId,
                  hashSwapId,
                )) &&
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
      status: status ?? this.status,
    );
  }

  WebhookData copyWithWrapped({
    Wrapped<String>? url,
    Wrapped<bool?>? hashSwapId,
    Wrapped<List<String>?>? status,
  }) {
    return WebhookData(
      url: (url != null ? url.value : this.url),
      hashSwapId: (hashSwapId != null ? hashSwapId.value : this.hashSwapId),
      status: (status != null ? status.value : this.status),
    );
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
    this.paymentTimeout,
    this.webhook,
    this.extraFees,
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
  @JsonKey(name: 'paymentTimeout', includeIfNull: false)
  final double? paymentTimeout;
  @JsonKey(name: 'webhook', includeIfNull: false)
  final WebhookData? webhook;
  @JsonKey(name: 'extraFees', includeIfNull: false)
  final ExtraFees? extraFees;
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
                const DeepCollectionEquality().equals(
                  other.invoice,
                  invoice,
                )) &&
            (identical(other.preimageHash, preimageHash) ||
                const DeepCollectionEquality().equals(
                  other.preimageHash,
                  preimageHash,
                )) &&
            (identical(other.refundPublicKey, refundPublicKey) ||
                const DeepCollectionEquality().equals(
                  other.refundPublicKey,
                  refundPublicKey,
                )) &&
            (identical(other.pairHash, pairHash) ||
                const DeepCollectionEquality().equals(
                  other.pairHash,
                  pairHash,
                )) &&
            (identical(other.referralId, referralId) ||
                const DeepCollectionEquality().equals(
                  other.referralId,
                  referralId,
                )) &&
            (identical(other.paymentTimeout, paymentTimeout) ||
                const DeepCollectionEquality().equals(
                  other.paymentTimeout,
                  paymentTimeout,
                )) &&
            (identical(other.webhook, webhook) ||
                const DeepCollectionEquality().equals(
                  other.webhook,
                  webhook,
                )) &&
            (identical(other.extraFees, extraFees) ||
                const DeepCollectionEquality().equals(
                  other.extraFees,
                  extraFees,
                )));
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
      const DeepCollectionEquality().hash(paymentTimeout) ^
      const DeepCollectionEquality().hash(webhook) ^
      const DeepCollectionEquality().hash(extraFees) ^
      runtimeType.hashCode;
}

extension $SubmarineRequestExtension on SubmarineRequest {
  SubmarineRequest copyWith({
    String? from,
    String? to,
    String? invoice,
    String? preimageHash,
    String? refundPublicKey,
    String? pairHash,
    String? referralId,
    double? paymentTimeout,
    WebhookData? webhook,
    ExtraFees? extraFees,
  }) {
    return SubmarineRequest(
      from: from ?? this.from,
      to: to ?? this.to,
      invoice: invoice ?? this.invoice,
      preimageHash: preimageHash ?? this.preimageHash,
      refundPublicKey: refundPublicKey ?? this.refundPublicKey,
      pairHash: pairHash ?? this.pairHash,
      referralId: referralId ?? this.referralId,
      paymentTimeout: paymentTimeout ?? this.paymentTimeout,
      webhook: webhook ?? this.webhook,
      extraFees: extraFees ?? this.extraFees,
    );
  }

  SubmarineRequest copyWithWrapped({
    Wrapped<String>? from,
    Wrapped<String>? to,
    Wrapped<String?>? invoice,
    Wrapped<String?>? preimageHash,
    Wrapped<String?>? refundPublicKey,
    Wrapped<String?>? pairHash,
    Wrapped<String?>? referralId,
    Wrapped<double?>? paymentTimeout,
    Wrapped<WebhookData?>? webhook,
    Wrapped<ExtraFees?>? extraFees,
  }) {
    return SubmarineRequest(
      from: (from != null ? from.value : this.from),
      to: (to != null ? to.value : this.to),
      invoice: (invoice != null ? invoice.value : this.invoice),
      preimageHash: (preimageHash != null
          ? preimageHash.value
          : this.preimageHash),
      refundPublicKey: (refundPublicKey != null
          ? refundPublicKey.value
          : this.refundPublicKey),
      pairHash: (pairHash != null ? pairHash.value : this.pairHash),
      referralId: (referralId != null ? referralId.value : this.referralId),
      paymentTimeout: (paymentTimeout != null
          ? paymentTimeout.value
          : this.paymentTimeout),
      webhook: (webhook != null ? webhook.value : this.webhook),
      extraFees: (extraFees != null ? extraFees.value : this.extraFees),
    );
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
    this.timeoutBlockHeight,
    this.timeoutBlockHeights,
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
  final double? timeoutBlockHeight;
  @JsonKey(name: 'timeoutBlockHeights', includeIfNull: false)
  final ArkTimeouts? timeoutBlockHeights;
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
                const DeepCollectionEquality().equals(
                  other.address,
                  address,
                )) &&
            (identical(other.swapTree, swapTree) ||
                const DeepCollectionEquality().equals(
                  other.swapTree,
                  swapTree,
                )) &&
            (identical(other.claimPublicKey, claimPublicKey) ||
                const DeepCollectionEquality().equals(
                  other.claimPublicKey,
                  claimPublicKey,
                )) &&
            (identical(other.timeoutBlockHeight, timeoutBlockHeight) ||
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeight,
                  timeoutBlockHeight,
                )) &&
            (identical(other.timeoutBlockHeights, timeoutBlockHeights) ||
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeights,
                  timeoutBlockHeights,
                )) &&
            (identical(other.acceptZeroConf, acceptZeroConf) ||
                const DeepCollectionEquality().equals(
                  other.acceptZeroConf,
                  acceptZeroConf,
                )) &&
            (identical(other.expectedAmount, expectedAmount) ||
                const DeepCollectionEquality().equals(
                  other.expectedAmount,
                  expectedAmount,
                )) &&
            (identical(other.blindingKey, blindingKey) ||
                const DeepCollectionEquality().equals(
                  other.blindingKey,
                  blindingKey,
                )) &&
            (identical(other.referralId, referralId) ||
                const DeepCollectionEquality().equals(
                  other.referralId,
                  referralId,
                )));
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
      const DeepCollectionEquality().hash(timeoutBlockHeights) ^
      const DeepCollectionEquality().hash(acceptZeroConf) ^
      const DeepCollectionEquality().hash(expectedAmount) ^
      const DeepCollectionEquality().hash(blindingKey) ^
      const DeepCollectionEquality().hash(referralId) ^
      runtimeType.hashCode;
}

extension $SubmarineResponseExtension on SubmarineResponse {
  SubmarineResponse copyWith({
    String? id,
    String? bip21,
    String? address,
    SwapTree? swapTree,
    String? claimPublicKey,
    double? timeoutBlockHeight,
    ArkTimeouts? timeoutBlockHeights,
    bool? acceptZeroConf,
    double? expectedAmount,
    String? blindingKey,
    String? referralId,
  }) {
    return SubmarineResponse(
      id: id ?? this.id,
      bip21: bip21 ?? this.bip21,
      address: address ?? this.address,
      swapTree: swapTree ?? this.swapTree,
      claimPublicKey: claimPublicKey ?? this.claimPublicKey,
      timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
      timeoutBlockHeights: timeoutBlockHeights ?? this.timeoutBlockHeights,
      acceptZeroConf: acceptZeroConf ?? this.acceptZeroConf,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      blindingKey: blindingKey ?? this.blindingKey,
      referralId: referralId ?? this.referralId,
    );
  }

  SubmarineResponse copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String?>? bip21,
    Wrapped<String?>? address,
    Wrapped<SwapTree?>? swapTree,
    Wrapped<String?>? claimPublicKey,
    Wrapped<double?>? timeoutBlockHeight,
    Wrapped<ArkTimeouts?>? timeoutBlockHeights,
    Wrapped<bool?>? acceptZeroConf,
    Wrapped<double>? expectedAmount,
    Wrapped<String?>? blindingKey,
    Wrapped<String?>? referralId,
  }) {
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
      timeoutBlockHeights: (timeoutBlockHeights != null
          ? timeoutBlockHeights.value
          : this.timeoutBlockHeights),
      acceptZeroConf: (acceptZeroConf != null
          ? acceptZeroConf.value
          : this.acceptZeroConf),
      expectedAmount: (expectedAmount != null
          ? expectedAmount.value
          : this.expectedAmount),
      blindingKey: (blindingKey != null ? blindingKey.value : this.blindingKey),
      referralId: (referralId != null ? referralId.value : this.referralId),
    );
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
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeight,
                  timeoutBlockHeight,
                )) &&
            (identical(other.timeoutEta, timeoutEta) ||
                const DeepCollectionEquality().equals(
                  other.timeoutEta,
                  timeoutEta,
                )));
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
  SubmarineTransaction copyWith({
    String? id,
    String? hex,
    double? timeoutBlockHeight,
    double? timeoutEta,
  }) {
    return SubmarineTransaction(
      id: id ?? this.id,
      hex: hex ?? this.hex,
      timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
      timeoutEta: timeoutEta ?? this.timeoutEta,
    );
  }

  SubmarineTransaction copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String?>? hex,
    Wrapped<double>? timeoutBlockHeight,
    Wrapped<double?>? timeoutEta,
  }) {
    return SubmarineTransaction(
      id: (id != null ? id.value : this.id),
      hex: (hex != null ? hex.value : this.hex),
      timeoutBlockHeight: (timeoutBlockHeight != null
          ? timeoutBlockHeight.value
          : this.timeoutBlockHeight),
      timeoutEta: (timeoutEta != null ? timeoutEta.value : this.timeoutEta),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SubmarinePreimage {
  const SubmarinePreimage({required this.preimage});

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
                const DeepCollectionEquality().equals(
                  other.preimage,
                  preimage,
                )));
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
      preimage: (preimage != null ? preimage.value : this.preimage),
    );
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
                const DeepCollectionEquality().equals(
                  other.pubNonce,
                  pubNonce,
                )) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality().equals(
                  other.transaction,
                  transaction,
                )) &&
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
  RefundRequest copyWith({
    String? pubNonce,
    String? transaction,
    double? index,
  }) {
    return RefundRequest(
      pubNonce: pubNonce ?? this.pubNonce,
      transaction: transaction ?? this.transaction,
      index: index ?? this.index,
    );
  }

  RefundRequest copyWithWrapped({
    Wrapped<String>? pubNonce,
    Wrapped<String>? transaction,
    Wrapped<double>? index,
  }) {
    return RefundRequest(
      pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
      transaction: (transaction != null ? transaction.value : this.transaction),
      index: (index != null ? index.value : this.index),
    );
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
                const DeepCollectionEquality().equals(
                  other.pubNonce,
                  pubNonce,
                )) &&
            (identical(other.partialSignature, partialSignature) ||
                const DeepCollectionEquality().equals(
                  other.partialSignature,
                  partialSignature,
                )));
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
      partialSignature: partialSignature ?? this.partialSignature,
    );
  }

  PartialSignature copyWithWrapped({
    Wrapped<String>? pubNonce,
    Wrapped<String>? partialSignature,
  }) {
    return PartialSignature(
      pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
      partialSignature: (partialSignature != null
          ? partialSignature.value
          : this.partialSignature),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ArkRefundRequest {
  const ArkRefundRequest({required this.transaction, required this.checkpoint});

  factory ArkRefundRequest.fromJson(Map<String, dynamic> json) =>
      _$ArkRefundRequestFromJson(json);

  static const toJsonFactory = _$ArkRefundRequestToJson;
  Map<String, dynamic> toJson() => _$ArkRefundRequestToJson(this);

  @JsonKey(name: 'transaction', includeIfNull: false)
  final String transaction;
  @JsonKey(name: 'checkpoint', includeIfNull: false)
  final String checkpoint;
  static const fromJsonFactory = _$ArkRefundRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ArkRefundRequest &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality().equals(
                  other.transaction,
                  transaction,
                )) &&
            (identical(other.checkpoint, checkpoint) ||
                const DeepCollectionEquality().equals(
                  other.checkpoint,
                  checkpoint,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(transaction) ^
      const DeepCollectionEquality().hash(checkpoint) ^
      runtimeType.hashCode;
}

extension $ArkRefundRequestExtension on ArkRefundRequest {
  ArkRefundRequest copyWith({String? transaction, String? checkpoint}) {
    return ArkRefundRequest(
      transaction: transaction ?? this.transaction,
      checkpoint: checkpoint ?? this.checkpoint,
    );
  }

  ArkRefundRequest copyWithWrapped({
    Wrapped<String>? transaction,
    Wrapped<String>? checkpoint,
  }) {
    return ArkRefundRequest(
      transaction: (transaction != null ? transaction.value : this.transaction),
      checkpoint: (checkpoint != null ? checkpoint.value : this.checkpoint),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ArkRefundResponse {
  const ArkRefundResponse({
    required this.transaction,
    required this.checkpoint,
  });

  factory ArkRefundResponse.fromJson(Map<String, dynamic> json) =>
      _$ArkRefundResponseFromJson(json);

  static const toJsonFactory = _$ArkRefundResponseToJson;
  Map<String, dynamic> toJson() => _$ArkRefundResponseToJson(this);

  @JsonKey(name: 'transaction', includeIfNull: false)
  final String transaction;
  @JsonKey(name: 'checkpoint', includeIfNull: false)
  final String checkpoint;
  static const fromJsonFactory = _$ArkRefundResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ArkRefundResponse &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality().equals(
                  other.transaction,
                  transaction,
                )) &&
            (identical(other.checkpoint, checkpoint) ||
                const DeepCollectionEquality().equals(
                  other.checkpoint,
                  checkpoint,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(transaction) ^
      const DeepCollectionEquality().hash(checkpoint) ^
      runtimeType.hashCode;
}

extension $ArkRefundResponseExtension on ArkRefundResponse {
  ArkRefundResponse copyWith({String? transaction, String? checkpoint}) {
    return ArkRefundResponse(
      transaction: transaction ?? this.transaction,
      checkpoint: checkpoint ?? this.checkpoint,
    );
  }

  ArkRefundResponse copyWithWrapped({
    Wrapped<String>? transaction,
    Wrapped<String>? checkpoint,
  }) {
    return ArkRefundResponse(
      transaction: (transaction != null ? transaction.value : this.transaction),
      checkpoint: (checkpoint != null ? checkpoint.value : this.checkpoint),
    );
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
                const DeepCollectionEquality().equals(
                  other.preimage,
                  preimage,
                )) &&
            (identical(other.pubNonce, pubNonce) ||
                const DeepCollectionEquality().equals(
                  other.pubNonce,
                  pubNonce,
                )) &&
            (identical(other.publicKey, publicKey) ||
                const DeepCollectionEquality().equals(
                  other.publicKey,
                  publicKey,
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
      const DeepCollectionEquality().hash(preimage) ^
      const DeepCollectionEquality().hash(pubNonce) ^
      const DeepCollectionEquality().hash(publicKey) ^
      const DeepCollectionEquality().hash(transactionHash) ^
      runtimeType.hashCode;
}

extension $SubmarineClaimDetailsExtension on SubmarineClaimDetails {
  SubmarineClaimDetails copyWith({
    String? preimage,
    String? pubNonce,
    String? publicKey,
    String? transactionHash,
  }) {
    return SubmarineClaimDetails(
      preimage: preimage ?? this.preimage,
      pubNonce: pubNonce ?? this.pubNonce,
      publicKey: publicKey ?? this.publicKey,
      transactionHash: transactionHash ?? this.transactionHash,
    );
  }

  SubmarineClaimDetails copyWithWrapped({
    Wrapped<String>? preimage,
    Wrapped<String>? pubNonce,
    Wrapped<String>? publicKey,
    Wrapped<String>? transactionHash,
  }) {
    return SubmarineClaimDetails(
      preimage: (preimage != null ? preimage.value : this.preimage),
      pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
      publicKey: (publicKey != null ? publicKey.value : this.publicKey),
      transactionHash: (transactionHash != null
          ? transactionHash.value
          : this.transactionHash),
    );
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
  ReversePair copyWith({
    String? hash,
    double? rate,
    ReversePair$Limits? limits,
    ReversePair$Fees? fees,
  }) {
    return ReversePair(
      hash: hash ?? this.hash,
      rate: rate ?? this.rate,
      limits: limits ?? this.limits,
      fees: fees ?? this.fees,
    );
  }

  ReversePair copyWithWrapped({
    Wrapped<String>? hash,
    Wrapped<double>? rate,
    Wrapped<ReversePair$Limits>? limits,
    Wrapped<ReversePair$Fees>? fees,
  }) {
    return ReversePair(
      hash: (hash != null ? hash.value : this.hash),
      rate: (rate != null ? rate.value : this.rate),
      limits: (limits != null ? limits.value : this.limits),
      fees: (fees != null ? fees.value : this.fees),
    );
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
    this.extraFees,
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
  @JsonKey(name: 'extraFees', includeIfNull: false)
  final ExtraFees? extraFees;
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
                const DeepCollectionEquality().equals(
                  other.preimageHash,
                  preimageHash,
                )) &&
            (identical(other.claimPublicKey, claimPublicKey) ||
                const DeepCollectionEquality().equals(
                  other.claimPublicKey,
                  claimPublicKey,
                )) &&
            (identical(other.claimAddress, claimAddress) ||
                const DeepCollectionEquality().equals(
                  other.claimAddress,
                  claimAddress,
                )) &&
            (identical(other.invoiceAmount, invoiceAmount) ||
                const DeepCollectionEquality().equals(
                  other.invoiceAmount,
                  invoiceAmount,
                )) &&
            (identical(other.onchainAmount, onchainAmount) ||
                const DeepCollectionEquality().equals(
                  other.onchainAmount,
                  onchainAmount,
                )) &&
            (identical(other.pairHash, pairHash) ||
                const DeepCollectionEquality().equals(
                  other.pairHash,
                  pairHash,
                )) &&
            (identical(other.referralId, referralId) ||
                const DeepCollectionEquality().equals(
                  other.referralId,
                  referralId,
                )) &&
            (identical(other.address, address) ||
                const DeepCollectionEquality().equals(
                  other.address,
                  address,
                )) &&
            (identical(other.addressSignature, addressSignature) ||
                const DeepCollectionEquality().equals(
                  other.addressSignature,
                  addressSignature,
                )) &&
            (identical(other.claimCovenant, claimCovenant) ||
                const DeepCollectionEquality().equals(
                  other.claimCovenant,
                  claimCovenant,
                )) &&
            (identical(other.description, description) ||
                const DeepCollectionEquality().equals(
                  other.description,
                  description,
                )) &&
            (identical(other.descriptionHash, descriptionHash) ||
                const DeepCollectionEquality().equals(
                  other.descriptionHash,
                  descriptionHash,
                )) &&
            (identical(other.invoiceExpiry, invoiceExpiry) ||
                const DeepCollectionEquality().equals(
                  other.invoiceExpiry,
                  invoiceExpiry,
                )) &&
            (identical(other.webhook, webhook) ||
                const DeepCollectionEquality().equals(
                  other.webhook,
                  webhook,
                )) &&
            (identical(other.extraFees, extraFees) ||
                const DeepCollectionEquality().equals(
                  other.extraFees,
                  extraFees,
                )));
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
      const DeepCollectionEquality().hash(extraFees) ^
      runtimeType.hashCode;
}

extension $ReverseRequestExtension on ReverseRequest {
  ReverseRequest copyWith({
    String? from,
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
    WebhookData? webhook,
    ExtraFees? extraFees,
  }) {
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
      webhook: webhook ?? this.webhook,
      extraFees: extraFees ?? this.extraFees,
    );
  }

  ReverseRequest copyWithWrapped({
    Wrapped<String>? from,
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
    Wrapped<WebhookData?>? webhook,
    Wrapped<ExtraFees?>? extraFees,
  }) {
    return ReverseRequest(
      from: (from != null ? from.value : this.from),
      to: (to != null ? to.value : this.to),
      preimageHash: (preimageHash != null
          ? preimageHash.value
          : this.preimageHash),
      claimPublicKey: (claimPublicKey != null
          ? claimPublicKey.value
          : this.claimPublicKey),
      claimAddress: (claimAddress != null
          ? claimAddress.value
          : this.claimAddress),
      invoiceAmount: (invoiceAmount != null
          ? invoiceAmount.value
          : this.invoiceAmount),
      onchainAmount: (onchainAmount != null
          ? onchainAmount.value
          : this.onchainAmount),
      pairHash: (pairHash != null ? pairHash.value : this.pairHash),
      referralId: (referralId != null ? referralId.value : this.referralId),
      address: (address != null ? address.value : this.address),
      addressSignature: (addressSignature != null
          ? addressSignature.value
          : this.addressSignature),
      claimCovenant: (claimCovenant != null
          ? claimCovenant.value
          : this.claimCovenant),
      description: (description != null ? description.value : this.description),
      descriptionHash: (descriptionHash != null
          ? descriptionHash.value
          : this.descriptionHash),
      invoiceExpiry: (invoiceExpiry != null
          ? invoiceExpiry.value
          : this.invoiceExpiry),
      webhook: (webhook != null ? webhook.value : this.webhook),
      extraFees: (extraFees != null ? extraFees.value : this.extraFees),
    );
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
    this.refundAddress,
    this.timeoutBlockHeight,
    this.timeoutBlockHeights,
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
  @JsonKey(name: 'refundAddress', includeIfNull: false)
  final String? refundAddress;
  @JsonKey(name: 'timeoutBlockHeight', includeIfNull: false)
  final double? timeoutBlockHeight;
  @JsonKey(name: 'timeoutBlockHeights', includeIfNull: false)
  final ArkTimeouts? timeoutBlockHeights;
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
                const DeepCollectionEquality().equals(
                  other.invoice,
                  invoice,
                )) &&
            (identical(other.swapTree, swapTree) ||
                const DeepCollectionEquality().equals(
                  other.swapTree,
                  swapTree,
                )) &&
            (identical(other.lockupAddress, lockupAddress) ||
                const DeepCollectionEquality().equals(
                  other.lockupAddress,
                  lockupAddress,
                )) &&
            (identical(other.refundPublicKey, refundPublicKey) ||
                const DeepCollectionEquality().equals(
                  other.refundPublicKey,
                  refundPublicKey,
                )) &&
            (identical(other.refundAddress, refundAddress) ||
                const DeepCollectionEquality().equals(
                  other.refundAddress,
                  refundAddress,
                )) &&
            (identical(other.timeoutBlockHeight, timeoutBlockHeight) ||
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeight,
                  timeoutBlockHeight,
                )) &&
            (identical(other.timeoutBlockHeights, timeoutBlockHeights) ||
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeights,
                  timeoutBlockHeights,
                )) &&
            (identical(other.onchainAmount, onchainAmount) ||
                const DeepCollectionEquality().equals(
                  other.onchainAmount,
                  onchainAmount,
                )) &&
            (identical(other.blindingKey, blindingKey) ||
                const DeepCollectionEquality().equals(
                  other.blindingKey,
                  blindingKey,
                )) &&
            (identical(other.referralId, referralId) ||
                const DeepCollectionEquality().equals(
                  other.referralId,
                  referralId,
                )));
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
      const DeepCollectionEquality().hash(refundAddress) ^
      const DeepCollectionEquality().hash(timeoutBlockHeight) ^
      const DeepCollectionEquality().hash(timeoutBlockHeights) ^
      const DeepCollectionEquality().hash(onchainAmount) ^
      const DeepCollectionEquality().hash(blindingKey) ^
      const DeepCollectionEquality().hash(referralId) ^
      runtimeType.hashCode;
}

extension $ReverseResponseExtension on ReverseResponse {
  ReverseResponse copyWith({
    String? id,
    String? invoice,
    SwapTree? swapTree,
    String? lockupAddress,
    String? refundPublicKey,
    String? refundAddress,
    double? timeoutBlockHeight,
    ArkTimeouts? timeoutBlockHeights,
    double? onchainAmount,
    String? blindingKey,
    String? referralId,
  }) {
    return ReverseResponse(
      id: id ?? this.id,
      invoice: invoice ?? this.invoice,
      swapTree: swapTree ?? this.swapTree,
      lockupAddress: lockupAddress ?? this.lockupAddress,
      refundPublicKey: refundPublicKey ?? this.refundPublicKey,
      refundAddress: refundAddress ?? this.refundAddress,
      timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
      timeoutBlockHeights: timeoutBlockHeights ?? this.timeoutBlockHeights,
      onchainAmount: onchainAmount ?? this.onchainAmount,
      blindingKey: blindingKey ?? this.blindingKey,
      referralId: referralId ?? this.referralId,
    );
  }

  ReverseResponse copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String>? invoice,
    Wrapped<SwapTree?>? swapTree,
    Wrapped<String?>? lockupAddress,
    Wrapped<String?>? refundPublicKey,
    Wrapped<String?>? refundAddress,
    Wrapped<double?>? timeoutBlockHeight,
    Wrapped<ArkTimeouts?>? timeoutBlockHeights,
    Wrapped<double?>? onchainAmount,
    Wrapped<String?>? blindingKey,
    Wrapped<String?>? referralId,
  }) {
    return ReverseResponse(
      id: (id != null ? id.value : this.id),
      invoice: (invoice != null ? invoice.value : this.invoice),
      swapTree: (swapTree != null ? swapTree.value : this.swapTree),
      lockupAddress: (lockupAddress != null
          ? lockupAddress.value
          : this.lockupAddress),
      refundPublicKey: (refundPublicKey != null
          ? refundPublicKey.value
          : this.refundPublicKey),
      refundAddress: (refundAddress != null
          ? refundAddress.value
          : this.refundAddress),
      timeoutBlockHeight: (timeoutBlockHeight != null
          ? timeoutBlockHeight.value
          : this.timeoutBlockHeight),
      timeoutBlockHeights: (timeoutBlockHeights != null
          ? timeoutBlockHeights.value
          : this.timeoutBlockHeights),
      onchainAmount: (onchainAmount != null
          ? onchainAmount.value
          : this.onchainAmount),
      blindingKey: (blindingKey != null ? blindingKey.value : this.blindingKey),
      referralId: (referralId != null ? referralId.value : this.referralId),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class InvoiceExpiryRange {
  const InvoiceExpiryRange({required this.min, required this.max});

  factory InvoiceExpiryRange.fromJson(Map<String, dynamic> json) =>
      _$InvoiceExpiryRangeFromJson(json);

  static const toJsonFactory = _$InvoiceExpiryRangeToJson;
  Map<String, dynamic> toJson() => _$InvoiceExpiryRangeToJson(this);

  @JsonKey(name: 'min', includeIfNull: false)
  final double min;
  @JsonKey(name: 'max', includeIfNull: false)
  final double max;
  static const fromJsonFactory = _$InvoiceExpiryRangeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is InvoiceExpiryRange &&
            (identical(other.min, min) ||
                const DeepCollectionEquality().equals(other.min, min)) &&
            (identical(other.max, max) ||
                const DeepCollectionEquality().equals(other.max, max)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(min) ^
      const DeepCollectionEquality().hash(max) ^
      runtimeType.hashCode;
}

extension $InvoiceExpiryRangeExtension on InvoiceExpiryRange {
  InvoiceExpiryRange copyWith({double? min, double? max}) {
    return InvoiceExpiryRange(min: min ?? this.min, max: max ?? this.max);
  }

  InvoiceExpiryRange copyWithWrapped({
    Wrapped<double>? min,
    Wrapped<double>? max,
  }) {
    return InvoiceExpiryRange(
      min: (min != null ? min.value : this.min),
      max: (max != null ? max.value : this.max),
    );
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
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeight,
                  timeoutBlockHeight,
                )));
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
  ReverseTransaction copyWith({
    String? id,
    String? hex,
    double? timeoutBlockHeight,
  }) {
    return ReverseTransaction(
      id: id ?? this.id,
      hex: hex ?? this.hex,
      timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
    );
  }

  ReverseTransaction copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String?>? hex,
    Wrapped<double>? timeoutBlockHeight,
  }) {
    return ReverseTransaction(
      id: (id != null ? id.value : this.id),
      hex: (hex != null ? hex.value : this.hex),
      timeoutBlockHeight: (timeoutBlockHeight != null
          ? timeoutBlockHeight.value
          : this.timeoutBlockHeight),
    );
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
                const DeepCollectionEquality().equals(
                  other.preimage,
                  preimage,
                )) &&
            (identical(other.pubNonce, pubNonce) ||
                const DeepCollectionEquality().equals(
                  other.pubNonce,
                  pubNonce,
                )) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality().equals(
                  other.transaction,
                  transaction,
                )) &&
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
  ReverseClaimRequest copyWith({
    String? preimage,
    String? pubNonce,
    String? transaction,
    double? index,
  }) {
    return ReverseClaimRequest(
      preimage: preimage ?? this.preimage,
      pubNonce: pubNonce ?? this.pubNonce,
      transaction: transaction ?? this.transaction,
      index: index ?? this.index,
    );
  }

  ReverseClaimRequest copyWithWrapped({
    Wrapped<String>? preimage,
    Wrapped<String?>? pubNonce,
    Wrapped<String?>? transaction,
    Wrapped<double?>? index,
  }) {
    return ReverseClaimRequest(
      preimage: (preimage != null ? preimage.value : this.preimage),
      pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
      transaction: (transaction != null ? transaction.value : this.transaction),
      index: (index != null ? index.value : this.index),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ReverseBip21 {
  const ReverseBip21({required this.bip21, required this.signature});

  factory ReverseBip21.fromJson(Map<String, dynamic> json) =>
      _$ReverseBip21FromJson(json);

  static const toJsonFactory = _$ReverseBip21ToJson;
  Map<String, dynamic> toJson() => _$ReverseBip21ToJson(this);

  @JsonKey(name: 'bip21', includeIfNull: false)
  final String bip21;
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
                const DeepCollectionEquality().equals(
                  other.signature,
                  signature,
                )));
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
      bip21: bip21 ?? this.bip21,
      signature: signature ?? this.signature,
    );
  }

  ReverseBip21 copyWithWrapped({
    Wrapped<String>? bip21,
    Wrapped<String>? signature,
  }) {
    return ReverseBip21(
      bip21: (bip21 != null ? bip21.value : this.bip21),
      signature: (signature != null ? signature.value : this.signature),
    );
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
  ChainPair copyWith({
    String? hash,
    double? rate,
    ChainPair$Limits? limits,
    ChainPair$Fees? fees,
  }) {
    return ChainPair(
      hash: hash ?? this.hash,
      rate: rate ?? this.rate,
      limits: limits ?? this.limits,
      fees: fees ?? this.fees,
    );
  }

  ChainPair copyWithWrapped({
    Wrapped<String>? hash,
    Wrapped<double>? rate,
    Wrapped<ChainPair$Limits>? limits,
    Wrapped<ChainPair$Fees>? fees,
  }) {
    return ChainPair(
      hash: (hash != null ? hash.value : this.hash),
      rate: (rate != null ? rate.value : this.rate),
      limits: (limits != null ? limits.value : this.limits),
      fees: (fees != null ? fees.value : this.fees),
    );
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
    this.extraFees,
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
  @JsonKey(name: 'extraFees', includeIfNull: false)
  final ExtraFees? extraFees;
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
                const DeepCollectionEquality().equals(
                  other.preimageHash,
                  preimageHash,
                )) &&
            (identical(other.claimPublicKey, claimPublicKey) ||
                const DeepCollectionEquality().equals(
                  other.claimPublicKey,
                  claimPublicKey,
                )) &&
            (identical(other.refundPublicKey, refundPublicKey) ||
                const DeepCollectionEquality().equals(
                  other.refundPublicKey,
                  refundPublicKey,
                )) &&
            (identical(other.claimAddress, claimAddress) ||
                const DeepCollectionEquality().equals(
                  other.claimAddress,
                  claimAddress,
                )) &&
            (identical(other.userLockAmount, userLockAmount) ||
                const DeepCollectionEquality().equals(
                  other.userLockAmount,
                  userLockAmount,
                )) &&
            (identical(other.serverLockAmount, serverLockAmount) ||
                const DeepCollectionEquality().equals(
                  other.serverLockAmount,
                  serverLockAmount,
                )) &&
            (identical(other.pairHash, pairHash) ||
                const DeepCollectionEquality().equals(
                  other.pairHash,
                  pairHash,
                )) &&
            (identical(other.referralId, referralId) ||
                const DeepCollectionEquality().equals(
                  other.referralId,
                  referralId,
                )) &&
            (identical(other.webhook, webhook) ||
                const DeepCollectionEquality().equals(
                  other.webhook,
                  webhook,
                )) &&
            (identical(other.extraFees, extraFees) ||
                const DeepCollectionEquality().equals(
                  other.extraFees,
                  extraFees,
                )));
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
      const DeepCollectionEquality().hash(extraFees) ^
      runtimeType.hashCode;
}

extension $ChainRequestExtension on ChainRequest {
  ChainRequest copyWith({
    String? from,
    String? to,
    String? preimageHash,
    String? claimPublicKey,
    String? refundPublicKey,
    String? claimAddress,
    double? userLockAmount,
    double? serverLockAmount,
    String? pairHash,
    String? referralId,
    WebhookData? webhook,
    ExtraFees? extraFees,
  }) {
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
      webhook: webhook ?? this.webhook,
      extraFees: extraFees ?? this.extraFees,
    );
  }

  ChainRequest copyWithWrapped({
    Wrapped<String>? from,
    Wrapped<String>? to,
    Wrapped<String>? preimageHash,
    Wrapped<String?>? claimPublicKey,
    Wrapped<String?>? refundPublicKey,
    Wrapped<String?>? claimAddress,
    Wrapped<double?>? userLockAmount,
    Wrapped<double?>? serverLockAmount,
    Wrapped<String?>? pairHash,
    Wrapped<String?>? referralId,
    Wrapped<WebhookData?>? webhook,
    Wrapped<ExtraFees?>? extraFees,
  }) {
    return ChainRequest(
      from: (from != null ? from.value : this.from),
      to: (to != null ? to.value : this.to),
      preimageHash: (preimageHash != null
          ? preimageHash.value
          : this.preimageHash),
      claimPublicKey: (claimPublicKey != null
          ? claimPublicKey.value
          : this.claimPublicKey),
      refundPublicKey: (refundPublicKey != null
          ? refundPublicKey.value
          : this.refundPublicKey),
      claimAddress: (claimAddress != null
          ? claimAddress.value
          : this.claimAddress),
      userLockAmount: (userLockAmount != null
          ? userLockAmount.value
          : this.userLockAmount),
      serverLockAmount: (serverLockAmount != null
          ? serverLockAmount.value
          : this.serverLockAmount),
      pairHash: (pairHash != null ? pairHash.value : this.pairHash),
      referralId: (referralId != null ? referralId.value : this.referralId),
      webhook: (webhook != null ? webhook.value : this.webhook),
      extraFees: (extraFees != null ? extraFees.value : this.extraFees),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapData {
  const ChainSwapData({
    this.swapTree,
    this.lockupAddress,
    this.serverPublicKey,
    this.timeoutBlockHeight,
    this.timeoutBlockHeights,
    required this.amount,
    this.blindingKey,
    this.refundAddress,
    this.bip21,
    this.claimAddress,
  });

  factory ChainSwapData.fromJson(Map<String, dynamic> json) =>
      _$ChainSwapDataFromJson(json);

  static const toJsonFactory = _$ChainSwapDataToJson;
  Map<String, dynamic> toJson() => _$ChainSwapDataToJson(this);

  @JsonKey(name: 'swapTree', includeIfNull: false)
  final SwapTree? swapTree;
  @JsonKey(name: 'lockupAddress', includeIfNull: false)
  final String? lockupAddress;
  @JsonKey(name: 'serverPublicKey', includeIfNull: false)
  final String? serverPublicKey;
  @JsonKey(name: 'timeoutBlockHeight', includeIfNull: false)
  final double? timeoutBlockHeight;
  @JsonKey(name: 'timeoutBlockHeights', includeIfNull: false)
  final ArkTimeouts? timeoutBlockHeights;
  @JsonKey(name: 'amount', includeIfNull: false)
  final double amount;
  @JsonKey(name: 'blindingKey', includeIfNull: false)
  final String? blindingKey;
  @JsonKey(name: 'refundAddress', includeIfNull: false)
  final String? refundAddress;
  @JsonKey(name: 'bip21', includeIfNull: false)
  final String? bip21;
  @JsonKey(name: 'claimAddress', includeIfNull: false)
  final String? claimAddress;
  static const fromJsonFactory = _$ChainSwapDataFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainSwapData &&
            (identical(other.swapTree, swapTree) ||
                const DeepCollectionEquality().equals(
                  other.swapTree,
                  swapTree,
                )) &&
            (identical(other.lockupAddress, lockupAddress) ||
                const DeepCollectionEquality().equals(
                  other.lockupAddress,
                  lockupAddress,
                )) &&
            (identical(other.serverPublicKey, serverPublicKey) ||
                const DeepCollectionEquality().equals(
                  other.serverPublicKey,
                  serverPublicKey,
                )) &&
            (identical(other.timeoutBlockHeight, timeoutBlockHeight) ||
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeight,
                  timeoutBlockHeight,
                )) &&
            (identical(other.timeoutBlockHeights, timeoutBlockHeights) ||
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeights,
                  timeoutBlockHeights,
                )) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.blindingKey, blindingKey) ||
                const DeepCollectionEquality().equals(
                  other.blindingKey,
                  blindingKey,
                )) &&
            (identical(other.refundAddress, refundAddress) ||
                const DeepCollectionEquality().equals(
                  other.refundAddress,
                  refundAddress,
                )) &&
            (identical(other.bip21, bip21) ||
                const DeepCollectionEquality().equals(other.bip21, bip21)) &&
            (identical(other.claimAddress, claimAddress) ||
                const DeepCollectionEquality().equals(
                  other.claimAddress,
                  claimAddress,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(swapTree) ^
      const DeepCollectionEquality().hash(lockupAddress) ^
      const DeepCollectionEquality().hash(serverPublicKey) ^
      const DeepCollectionEquality().hash(timeoutBlockHeight) ^
      const DeepCollectionEquality().hash(timeoutBlockHeights) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(blindingKey) ^
      const DeepCollectionEquality().hash(refundAddress) ^
      const DeepCollectionEquality().hash(bip21) ^
      const DeepCollectionEquality().hash(claimAddress) ^
      runtimeType.hashCode;
}

extension $ChainSwapDataExtension on ChainSwapData {
  ChainSwapData copyWith({
    SwapTree? swapTree,
    String? lockupAddress,
    String? serverPublicKey,
    double? timeoutBlockHeight,
    ArkTimeouts? timeoutBlockHeights,
    double? amount,
    String? blindingKey,
    String? refundAddress,
    String? bip21,
    String? claimAddress,
  }) {
    return ChainSwapData(
      swapTree: swapTree ?? this.swapTree,
      lockupAddress: lockupAddress ?? this.lockupAddress,
      serverPublicKey: serverPublicKey ?? this.serverPublicKey,
      timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
      timeoutBlockHeights: timeoutBlockHeights ?? this.timeoutBlockHeights,
      amount: amount ?? this.amount,
      blindingKey: blindingKey ?? this.blindingKey,
      refundAddress: refundAddress ?? this.refundAddress,
      bip21: bip21 ?? this.bip21,
      claimAddress: claimAddress ?? this.claimAddress,
    );
  }

  ChainSwapData copyWithWrapped({
    Wrapped<SwapTree?>? swapTree,
    Wrapped<String?>? lockupAddress,
    Wrapped<String?>? serverPublicKey,
    Wrapped<double?>? timeoutBlockHeight,
    Wrapped<ArkTimeouts?>? timeoutBlockHeights,
    Wrapped<double>? amount,
    Wrapped<String?>? blindingKey,
    Wrapped<String?>? refundAddress,
    Wrapped<String?>? bip21,
    Wrapped<String?>? claimAddress,
  }) {
    return ChainSwapData(
      swapTree: (swapTree != null ? swapTree.value : this.swapTree),
      lockupAddress: (lockupAddress != null
          ? lockupAddress.value
          : this.lockupAddress),
      serverPublicKey: (serverPublicKey != null
          ? serverPublicKey.value
          : this.serverPublicKey),
      timeoutBlockHeight: (timeoutBlockHeight != null
          ? timeoutBlockHeight.value
          : this.timeoutBlockHeight),
      timeoutBlockHeights: (timeoutBlockHeights != null
          ? timeoutBlockHeights.value
          : this.timeoutBlockHeights),
      amount: (amount != null ? amount.value : this.amount),
      blindingKey: (blindingKey != null ? blindingKey.value : this.blindingKey),
      refundAddress: (refundAddress != null
          ? refundAddress.value
          : this.refundAddress),
      bip21: (bip21 != null ? bip21.value : this.bip21),
      claimAddress: (claimAddress != null
          ? claimAddress.value
          : this.claimAddress),
    );
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
                const DeepCollectionEquality().equals(
                  other.referralId,
                  referralId,
                )) &&
            (identical(other.claimDetails, claimDetails) ||
                const DeepCollectionEquality().equals(
                  other.claimDetails,
                  claimDetails,
                )) &&
            (identical(other.lockupDetails, lockupDetails) ||
                const DeepCollectionEquality().equals(
                  other.lockupDetails,
                  lockupDetails,
                )));
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
  ChainResponse copyWith({
    String? id,
    String? referralId,
    ChainSwapData? claimDetails,
    ChainSwapData? lockupDetails,
  }) {
    return ChainResponse(
      id: id ?? this.id,
      referralId: referralId ?? this.referralId,
      claimDetails: claimDetails ?? this.claimDetails,
      lockupDetails: lockupDetails ?? this.lockupDetails,
    );
  }

  ChainResponse copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String?>? referralId,
    Wrapped<ChainSwapData>? claimDetails,
    Wrapped<ChainSwapData>? lockupDetails,
  }) {
    return ChainResponse(
      id: (id != null ? id.value : this.id),
      referralId: (referralId != null ? referralId.value : this.referralId),
      claimDetails: (claimDetails != null
          ? claimDetails.value
          : this.claimDetails),
      lockupDetails: (lockupDetails != null
          ? lockupDetails.value
          : this.lockupDetails),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapTransaction {
  const ChainSwapTransaction({required this.transaction, this.timeout});

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
                const DeepCollectionEquality().equals(
                  other.transaction,
                  transaction,
                )) &&
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
  ChainSwapTransaction copyWith({
    ChainSwapTransaction$Transaction? transaction,
    ChainSwapTransaction$Timeout? timeout,
  }) {
    return ChainSwapTransaction(
      transaction: transaction ?? this.transaction,
      timeout: timeout ?? this.timeout,
    );
  }

  ChainSwapTransaction copyWithWrapped({
    Wrapped<ChainSwapTransaction$Transaction>? transaction,
    Wrapped<ChainSwapTransaction$Timeout?>? timeout,
  }) {
    return ChainSwapTransaction(
      transaction: (transaction != null ? transaction.value : this.transaction),
      timeout: (timeout != null ? timeout.value : this.timeout),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapTransactions {
  const ChainSwapTransactions({this.userLock, this.serverLock});

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
                const DeepCollectionEquality().equals(
                  other.userLock,
                  userLock,
                )) &&
            (identical(other.serverLock, serverLock) ||
                const DeepCollectionEquality().equals(
                  other.serverLock,
                  serverLock,
                )));
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
  ChainSwapTransactions copyWith({
    ChainSwapTransaction? userLock,
    ChainSwapTransaction? serverLock,
  }) {
    return ChainSwapTransactions(
      userLock: userLock ?? this.userLock,
      serverLock: serverLock ?? this.serverLock,
    );
  }

  ChainSwapTransactions copyWithWrapped({
    Wrapped<ChainSwapTransaction?>? userLock,
    Wrapped<ChainSwapTransaction?>? serverLock,
  }) {
    return ChainSwapTransactions(
      userLock: (userLock != null ? userLock.value : this.userLock),
      serverLock: (serverLock != null ? serverLock.value : this.serverLock),
    );
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
                const DeepCollectionEquality().equals(
                  other.pubNonce,
                  pubNonce,
                )) &&
            (identical(other.publicKey, publicKey) ||
                const DeepCollectionEquality().equals(
                  other.publicKey,
                  publicKey,
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
      const DeepCollectionEquality().hash(pubNonce) ^
      const DeepCollectionEquality().hash(publicKey) ^
      const DeepCollectionEquality().hash(transactionHash) ^
      runtimeType.hashCode;
}

extension $ChainSwapSigningDetailsExtension on ChainSwapSigningDetails {
  ChainSwapSigningDetails copyWith({
    String? pubNonce,
    String? publicKey,
    String? transactionHash,
  }) {
    return ChainSwapSigningDetails(
      pubNonce: pubNonce ?? this.pubNonce,
      publicKey: publicKey ?? this.publicKey,
      transactionHash: transactionHash ?? this.transactionHash,
    );
  }

  ChainSwapSigningDetails copyWithWrapped({
    Wrapped<String>? pubNonce,
    Wrapped<String>? publicKey,
    Wrapped<String>? transactionHash,
  }) {
    return ChainSwapSigningDetails(
      pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
      publicKey: (publicKey != null ? publicKey.value : this.publicKey),
      transactionHash: (transactionHash != null
          ? transactionHash.value
          : this.transactionHash),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapSigningRequest {
  const ChainSwapSigningRequest({this.preimage, this.signature, this.toSign});

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
                const DeepCollectionEquality().equals(
                  other.preimage,
                  preimage,
                )) &&
            (identical(other.signature, signature) ||
                const DeepCollectionEquality().equals(
                  other.signature,
                  signature,
                )) &&
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
  ChainSwapSigningRequest copyWith({
    String? preimage,
    PartialSignature? signature,
    ChainSwapSigningRequest$ToSign? toSign,
  }) {
    return ChainSwapSigningRequest(
      preimage: preimage ?? this.preimage,
      signature: signature ?? this.signature,
      toSign: toSign ?? this.toSign,
    );
  }

  ChainSwapSigningRequest copyWithWrapped({
    Wrapped<String?>? preimage,
    Wrapped<PartialSignature?>? signature,
    Wrapped<ChainSwapSigningRequest$ToSign?>? toSign,
  }) {
    return ChainSwapSigningRequest(
      preimage: (preimage != null ? preimage.value : this.preimage),
      signature: (signature != null ? signature.value : this.signature),
      toSign: (toSign != null ? toSign.value : this.toSign),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Quote {
  const Quote({required this.amount});

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
                const DeepCollectionEquality().equals(
                  other.zeroConfRejected,
                  zeroConfRejected,
                )) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality().equals(
                  other.transaction,
                  transaction,
                )));
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
  SwapStatus copyWith({
    String? status,
    bool? zeroConfRejected,
    SwapStatus$Transaction? transaction,
  }) {
    return SwapStatus(
      status: status ?? this.status,
      zeroConfRejected: zeroConfRejected ?? this.zeroConfRejected,
      transaction: transaction ?? this.transaction,
    );
  }

  SwapStatus copyWithWrapped({
    Wrapped<String>? status,
    Wrapped<bool?>? zeroConfRejected,
    Wrapped<SwapStatus$Transaction?>? transaction,
  }) {
    return SwapStatus(
      status: (status != null ? status.value : this.status),
      zeroConfRejected: (zeroConfRejected != null
          ? zeroConfRejected.value
          : this.zeroConfRejected),
      transaction: (transaction != null ? transaction.value : this.transaction),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RescueRequest {
  const RescueRequest();

  factory RescueRequest.fromJson(Map<String, dynamic> json) =>
      _$RescueRequestFromJson(json);

  static const toJsonFactory = _$RescueRequestToJson;
  Map<String, dynamic> toJson() => _$RescueRequestToJson(this);

  static const fromJsonFactory = _$RescueRequestFromJson;

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode => runtimeType.hashCode;
}

@JsonSerializable(explicitToJson: true)
class Transaction {
  const Transaction({required this.id, required this.hex});

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  static const toJsonFactory = _$TransactionToJson;
  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'hex', includeIfNull: false)
  final String hex;
  static const fromJsonFactory = _$TransactionFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Transaction &&
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

extension $TransactionExtension on Transaction {
  Transaction copyWith({String? id, String? hex}) {
    return Transaction(id: id ?? this.id, hex: hex ?? this.hex);
  }

  Transaction copyWithWrapped({Wrapped<String>? id, Wrapped<String>? hex}) {
    return Transaction(
      id: (id != null ? id.value : this.id),
      hex: (hex != null ? hex.value : this.hex),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RescuableSwap {
  const RescuableSwap({
    required this.id,
    required this.type,
    required this.status,
    required this.symbol,
    required this.keyIndex,
    required this.preimageHash,
    this.invoice,
    required this.timeoutBlockHeight,
    required this.serverPublicKey,
    this.blindingKey,
    required this.tree,
    required this.lockupAddress,
    this.transaction,
    required this.createdAt,
  });

  factory RescuableSwap.fromJson(Map<String, dynamic> json) =>
      _$RescuableSwapFromJson(json);

  static const toJsonFactory = _$RescuableSwapToJson;
  Map<String, dynamic> toJson() => _$RescuableSwapToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(
    name: 'type',
    includeIfNull: false,
    toJson: rescuableSwapTypeToJson,
    fromJson: rescuableSwapTypeFromJson,
  )
  final enums.RescuableSwapType type;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'symbol', includeIfNull: false)
  final String symbol;
  @JsonKey(name: 'keyIndex', includeIfNull: false)
  final double keyIndex;
  @JsonKey(name: 'preimageHash', includeIfNull: false)
  final String preimageHash;
  @JsonKey(name: 'invoice', includeIfNull: false)
  final String? invoice;
  @JsonKey(name: 'timeoutBlockHeight', includeIfNull: false)
  final double timeoutBlockHeight;
  @JsonKey(name: 'serverPublicKey', includeIfNull: false)
  final String serverPublicKey;
  @JsonKey(name: 'blindingKey', includeIfNull: false)
  final String? blindingKey;
  @JsonKey(name: 'tree', includeIfNull: false)
  final SwapTree tree;
  @JsonKey(name: 'lockupAddress', includeIfNull: false)
  final String lockupAddress;
  @JsonKey(name: 'transaction', includeIfNull: false)
  final Transaction? transaction;
  @JsonKey(name: 'createdAt', includeIfNull: false)
  final double createdAt;
  static const fromJsonFactory = _$RescuableSwapFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RescuableSwap &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.symbol, symbol) ||
                const DeepCollectionEquality().equals(other.symbol, symbol)) &&
            (identical(other.keyIndex, keyIndex) ||
                const DeepCollectionEquality().equals(
                  other.keyIndex,
                  keyIndex,
                )) &&
            (identical(other.preimageHash, preimageHash) ||
                const DeepCollectionEquality().equals(
                  other.preimageHash,
                  preimageHash,
                )) &&
            (identical(other.invoice, invoice) ||
                const DeepCollectionEquality().equals(
                  other.invoice,
                  invoice,
                )) &&
            (identical(other.timeoutBlockHeight, timeoutBlockHeight) ||
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeight,
                  timeoutBlockHeight,
                )) &&
            (identical(other.serverPublicKey, serverPublicKey) ||
                const DeepCollectionEquality().equals(
                  other.serverPublicKey,
                  serverPublicKey,
                )) &&
            (identical(other.blindingKey, blindingKey) ||
                const DeepCollectionEquality().equals(
                  other.blindingKey,
                  blindingKey,
                )) &&
            (identical(other.tree, tree) ||
                const DeepCollectionEquality().equals(other.tree, tree)) &&
            (identical(other.lockupAddress, lockupAddress) ||
                const DeepCollectionEquality().equals(
                  other.lockupAddress,
                  lockupAddress,
                )) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality().equals(
                  other.transaction,
                  transaction,
                )) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(type) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(symbol) ^
      const DeepCollectionEquality().hash(keyIndex) ^
      const DeepCollectionEquality().hash(preimageHash) ^
      const DeepCollectionEquality().hash(invoice) ^
      const DeepCollectionEquality().hash(timeoutBlockHeight) ^
      const DeepCollectionEquality().hash(serverPublicKey) ^
      const DeepCollectionEquality().hash(blindingKey) ^
      const DeepCollectionEquality().hash(tree) ^
      const DeepCollectionEquality().hash(lockupAddress) ^
      const DeepCollectionEquality().hash(transaction) ^
      const DeepCollectionEquality().hash(createdAt) ^
      runtimeType.hashCode;
}

extension $RescuableSwapExtension on RescuableSwap {
  RescuableSwap copyWith({
    String? id,
    enums.RescuableSwapType? type,
    String? status,
    String? symbol,
    double? keyIndex,
    String? preimageHash,
    String? invoice,
    double? timeoutBlockHeight,
    String? serverPublicKey,
    String? blindingKey,
    SwapTree? tree,
    String? lockupAddress,
    Transaction? transaction,
    double? createdAt,
  }) {
    return RescuableSwap(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      symbol: symbol ?? this.symbol,
      keyIndex: keyIndex ?? this.keyIndex,
      preimageHash: preimageHash ?? this.preimageHash,
      invoice: invoice ?? this.invoice,
      timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
      serverPublicKey: serverPublicKey ?? this.serverPublicKey,
      blindingKey: blindingKey ?? this.blindingKey,
      tree: tree ?? this.tree,
      lockupAddress: lockupAddress ?? this.lockupAddress,
      transaction: transaction ?? this.transaction,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  RescuableSwap copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<enums.RescuableSwapType>? type,
    Wrapped<String>? status,
    Wrapped<String>? symbol,
    Wrapped<double>? keyIndex,
    Wrapped<String>? preimageHash,
    Wrapped<String?>? invoice,
    Wrapped<double>? timeoutBlockHeight,
    Wrapped<String>? serverPublicKey,
    Wrapped<String?>? blindingKey,
    Wrapped<SwapTree>? tree,
    Wrapped<String>? lockupAddress,
    Wrapped<Transaction?>? transaction,
    Wrapped<double>? createdAt,
  }) {
    return RescuableSwap(
      id: (id != null ? id.value : this.id),
      type: (type != null ? type.value : this.type),
      status: (status != null ? status.value : this.status),
      symbol: (symbol != null ? symbol.value : this.symbol),
      keyIndex: (keyIndex != null ? keyIndex.value : this.keyIndex),
      preimageHash: (preimageHash != null
          ? preimageHash.value
          : this.preimageHash),
      invoice: (invoice != null ? invoice.value : this.invoice),
      timeoutBlockHeight: (timeoutBlockHeight != null
          ? timeoutBlockHeight.value
          : this.timeoutBlockHeight),
      serverPublicKey: (serverPublicKey != null
          ? serverPublicKey.value
          : this.serverPublicKey),
      blindingKey: (blindingKey != null ? blindingKey.value : this.blindingKey),
      tree: (tree != null ? tree.value : this.tree),
      lockupAddress: (lockupAddress != null
          ? lockupAddress.value
          : this.lockupAddress),
      transaction: (transaction != null ? transaction.value : this.transaction),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RestoreClaimDetails {
  const RestoreClaimDetails({
    required this.tree,
    this.amount,
    required this.keyIndex,
    this.transaction,
    required this.lockupAddress,
    required this.serverPublicKey,
    this.timeoutBlockHeight,
    this.timeoutBlockHeights,
    this.blindingKey,
    required this.preimageHash,
  });

  factory RestoreClaimDetails.fromJson(Map<String, dynamic> json) =>
      _$RestoreClaimDetailsFromJson(json);

  static const toJsonFactory = _$RestoreClaimDetailsToJson;
  Map<String, dynamic> toJson() => _$RestoreClaimDetailsToJson(this);

  @JsonKey(name: 'tree', includeIfNull: false)
  final SwapTree tree;
  @JsonKey(name: 'amount', includeIfNull: false)
  final double? amount;
  @JsonKey(name: 'keyIndex', includeIfNull: false)
  final double keyIndex;
  @JsonKey(name: 'transaction', includeIfNull: false)
  final Transaction? transaction;
  @JsonKey(name: 'lockupAddress', includeIfNull: false)
  final String lockupAddress;
  @JsonKey(name: 'serverPublicKey', includeIfNull: false)
  final String serverPublicKey;
  @JsonKey(name: 'timeoutBlockHeight', includeIfNull: false)
  final double? timeoutBlockHeight;
  @JsonKey(name: 'timeoutBlockHeights', includeIfNull: false)
  final ArkTimeouts? timeoutBlockHeights;
  @JsonKey(name: 'blindingKey', includeIfNull: false)
  final String? blindingKey;
  @JsonKey(name: 'preimageHash', includeIfNull: false)
  final String preimageHash;
  static const fromJsonFactory = _$RestoreClaimDetailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RestoreClaimDetails &&
            (identical(other.tree, tree) ||
                const DeepCollectionEquality().equals(other.tree, tree)) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.keyIndex, keyIndex) ||
                const DeepCollectionEquality().equals(
                  other.keyIndex,
                  keyIndex,
                )) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality().equals(
                  other.transaction,
                  transaction,
                )) &&
            (identical(other.lockupAddress, lockupAddress) ||
                const DeepCollectionEquality().equals(
                  other.lockupAddress,
                  lockupAddress,
                )) &&
            (identical(other.serverPublicKey, serverPublicKey) ||
                const DeepCollectionEquality().equals(
                  other.serverPublicKey,
                  serverPublicKey,
                )) &&
            (identical(other.timeoutBlockHeight, timeoutBlockHeight) ||
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeight,
                  timeoutBlockHeight,
                )) &&
            (identical(other.timeoutBlockHeights, timeoutBlockHeights) ||
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeights,
                  timeoutBlockHeights,
                )) &&
            (identical(other.blindingKey, blindingKey) ||
                const DeepCollectionEquality().equals(
                  other.blindingKey,
                  blindingKey,
                )) &&
            (identical(other.preimageHash, preimageHash) ||
                const DeepCollectionEquality().equals(
                  other.preimageHash,
                  preimageHash,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(tree) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(keyIndex) ^
      const DeepCollectionEquality().hash(transaction) ^
      const DeepCollectionEquality().hash(lockupAddress) ^
      const DeepCollectionEquality().hash(serverPublicKey) ^
      const DeepCollectionEquality().hash(timeoutBlockHeight) ^
      const DeepCollectionEquality().hash(timeoutBlockHeights) ^
      const DeepCollectionEquality().hash(blindingKey) ^
      const DeepCollectionEquality().hash(preimageHash) ^
      runtimeType.hashCode;
}

extension $RestoreClaimDetailsExtension on RestoreClaimDetails {
  RestoreClaimDetails copyWith({
    SwapTree? tree,
    double? amount,
    double? keyIndex,
    Transaction? transaction,
    String? lockupAddress,
    String? serverPublicKey,
    double? timeoutBlockHeight,
    ArkTimeouts? timeoutBlockHeights,
    String? blindingKey,
    String? preimageHash,
  }) {
    return RestoreClaimDetails(
      tree: tree ?? this.tree,
      amount: amount ?? this.amount,
      keyIndex: keyIndex ?? this.keyIndex,
      transaction: transaction ?? this.transaction,
      lockupAddress: lockupAddress ?? this.lockupAddress,
      serverPublicKey: serverPublicKey ?? this.serverPublicKey,
      timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
      timeoutBlockHeights: timeoutBlockHeights ?? this.timeoutBlockHeights,
      blindingKey: blindingKey ?? this.blindingKey,
      preimageHash: preimageHash ?? this.preimageHash,
    );
  }

  RestoreClaimDetails copyWithWrapped({
    Wrapped<SwapTree>? tree,
    Wrapped<double?>? amount,
    Wrapped<double>? keyIndex,
    Wrapped<Transaction?>? transaction,
    Wrapped<String>? lockupAddress,
    Wrapped<String>? serverPublicKey,
    Wrapped<double?>? timeoutBlockHeight,
    Wrapped<ArkTimeouts?>? timeoutBlockHeights,
    Wrapped<String?>? blindingKey,
    Wrapped<String>? preimageHash,
  }) {
    return RestoreClaimDetails(
      tree: (tree != null ? tree.value : this.tree),
      amount: (amount != null ? amount.value : this.amount),
      keyIndex: (keyIndex != null ? keyIndex.value : this.keyIndex),
      transaction: (transaction != null ? transaction.value : this.transaction),
      lockupAddress: (lockupAddress != null
          ? lockupAddress.value
          : this.lockupAddress),
      serverPublicKey: (serverPublicKey != null
          ? serverPublicKey.value
          : this.serverPublicKey),
      timeoutBlockHeight: (timeoutBlockHeight != null
          ? timeoutBlockHeight.value
          : this.timeoutBlockHeight),
      timeoutBlockHeights: (timeoutBlockHeights != null
          ? timeoutBlockHeights.value
          : this.timeoutBlockHeights),
      blindingKey: (blindingKey != null ? blindingKey.value : this.blindingKey),
      preimageHash: (preimageHash != null
          ? preimageHash.value
          : this.preimageHash),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RestoreRefundDetails {
  const RestoreRefundDetails({
    required this.tree,
    this.amount,
    required this.keyIndex,
    this.transaction,
    required this.lockupAddress,
    required this.serverPublicKey,
    this.timeoutBlockHeight,
    this.timeoutBlockHeights,
    this.blindingKey,
  });

  factory RestoreRefundDetails.fromJson(Map<String, dynamic> json) =>
      _$RestoreRefundDetailsFromJson(json);

  static const toJsonFactory = _$RestoreRefundDetailsToJson;
  Map<String, dynamic> toJson() => _$RestoreRefundDetailsToJson(this);

  @JsonKey(name: 'tree', includeIfNull: false)
  final SwapTree tree;
  @JsonKey(name: 'amount', includeIfNull: false)
  final double? amount;
  @JsonKey(name: 'keyIndex', includeIfNull: false)
  final double keyIndex;
  @JsonKey(name: 'transaction', includeIfNull: false)
  final Transaction? transaction;
  @JsonKey(name: 'lockupAddress', includeIfNull: false)
  final String lockupAddress;
  @JsonKey(name: 'serverPublicKey', includeIfNull: false)
  final String serverPublicKey;
  @JsonKey(name: 'timeoutBlockHeight', includeIfNull: false)
  final double? timeoutBlockHeight;
  @JsonKey(name: 'timeoutBlockHeights', includeIfNull: false)
  final ArkTimeouts? timeoutBlockHeights;
  @JsonKey(name: 'blindingKey', includeIfNull: false)
  final String? blindingKey;
  static const fromJsonFactory = _$RestoreRefundDetailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RestoreRefundDetails &&
            (identical(other.tree, tree) ||
                const DeepCollectionEquality().equals(other.tree, tree)) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.keyIndex, keyIndex) ||
                const DeepCollectionEquality().equals(
                  other.keyIndex,
                  keyIndex,
                )) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality().equals(
                  other.transaction,
                  transaction,
                )) &&
            (identical(other.lockupAddress, lockupAddress) ||
                const DeepCollectionEquality().equals(
                  other.lockupAddress,
                  lockupAddress,
                )) &&
            (identical(other.serverPublicKey, serverPublicKey) ||
                const DeepCollectionEquality().equals(
                  other.serverPublicKey,
                  serverPublicKey,
                )) &&
            (identical(other.timeoutBlockHeight, timeoutBlockHeight) ||
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeight,
                  timeoutBlockHeight,
                )) &&
            (identical(other.timeoutBlockHeights, timeoutBlockHeights) ||
                const DeepCollectionEquality().equals(
                  other.timeoutBlockHeights,
                  timeoutBlockHeights,
                )) &&
            (identical(other.blindingKey, blindingKey) ||
                const DeepCollectionEquality().equals(
                  other.blindingKey,
                  blindingKey,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(tree) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(keyIndex) ^
      const DeepCollectionEquality().hash(transaction) ^
      const DeepCollectionEquality().hash(lockupAddress) ^
      const DeepCollectionEquality().hash(serverPublicKey) ^
      const DeepCollectionEquality().hash(timeoutBlockHeight) ^
      const DeepCollectionEquality().hash(timeoutBlockHeights) ^
      const DeepCollectionEquality().hash(blindingKey) ^
      runtimeType.hashCode;
}

extension $RestoreRefundDetailsExtension on RestoreRefundDetails {
  RestoreRefundDetails copyWith({
    SwapTree? tree,
    double? amount,
    double? keyIndex,
    Transaction? transaction,
    String? lockupAddress,
    String? serverPublicKey,
    double? timeoutBlockHeight,
    ArkTimeouts? timeoutBlockHeights,
    String? blindingKey,
  }) {
    return RestoreRefundDetails(
      tree: tree ?? this.tree,
      amount: amount ?? this.amount,
      keyIndex: keyIndex ?? this.keyIndex,
      transaction: transaction ?? this.transaction,
      lockupAddress: lockupAddress ?? this.lockupAddress,
      serverPublicKey: serverPublicKey ?? this.serverPublicKey,
      timeoutBlockHeight: timeoutBlockHeight ?? this.timeoutBlockHeight,
      timeoutBlockHeights: timeoutBlockHeights ?? this.timeoutBlockHeights,
      blindingKey: blindingKey ?? this.blindingKey,
    );
  }

  RestoreRefundDetails copyWithWrapped({
    Wrapped<SwapTree>? tree,
    Wrapped<double?>? amount,
    Wrapped<double>? keyIndex,
    Wrapped<Transaction?>? transaction,
    Wrapped<String>? lockupAddress,
    Wrapped<String>? serverPublicKey,
    Wrapped<double?>? timeoutBlockHeight,
    Wrapped<ArkTimeouts?>? timeoutBlockHeights,
    Wrapped<String?>? blindingKey,
  }) {
    return RestoreRefundDetails(
      tree: (tree != null ? tree.value : this.tree),
      amount: (amount != null ? amount.value : this.amount),
      keyIndex: (keyIndex != null ? keyIndex.value : this.keyIndex),
      transaction: (transaction != null ? transaction.value : this.transaction),
      lockupAddress: (lockupAddress != null
          ? lockupAddress.value
          : this.lockupAddress),
      serverPublicKey: (serverPublicKey != null
          ? serverPublicKey.value
          : this.serverPublicKey),
      timeoutBlockHeight: (timeoutBlockHeight != null
          ? timeoutBlockHeight.value
          : this.timeoutBlockHeight),
      timeoutBlockHeights: (timeoutBlockHeights != null
          ? timeoutBlockHeights.value
          : this.timeoutBlockHeights),
      blindingKey: (blindingKey != null ? blindingKey.value : this.blindingKey),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RestorableSwap {
  const RestorableSwap({
    required this.id,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.from,
    required this.to,
    this.preimageHash,
    this.invoice,
    this.claimDetails,
    this.refundDetails,
  });

  factory RestorableSwap.fromJson(Map<String, dynamic> json) =>
      _$RestorableSwapFromJson(json);

  static const toJsonFactory = _$RestorableSwapToJson;
  Map<String, dynamic> toJson() => _$RestorableSwapToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(
    name: 'type',
    includeIfNull: false,
    toJson: restorableSwapTypeToJson,
    fromJson: restorableSwapTypeFromJson,
  )
  final enums.RestorableSwapType type;
  @JsonKey(name: 'status', includeIfNull: false)
  final String status;
  @JsonKey(name: 'createdAt', includeIfNull: false)
  final double createdAt;
  @JsonKey(name: 'from', includeIfNull: false)
  final String from;
  @JsonKey(name: 'to', includeIfNull: false)
  final String to;
  @JsonKey(name: 'preimageHash', includeIfNull: false)
  final String? preimageHash;
  @JsonKey(name: 'invoice', includeIfNull: false)
  final String? invoice;
  @JsonKey(name: 'claimDetails', includeIfNull: false)
  final RestoreClaimDetails? claimDetails;
  @JsonKey(name: 'refundDetails', includeIfNull: false)
  final RestoreRefundDetails? refundDetails;
  static const fromJsonFactory = _$RestorableSwapFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RestorableSwap &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.type, type) ||
                const DeepCollectionEquality().equals(other.type, type)) &&
            (identical(other.status, status) ||
                const DeepCollectionEquality().equals(other.status, status)) &&
            (identical(other.createdAt, createdAt) ||
                const DeepCollectionEquality().equals(
                  other.createdAt,
                  createdAt,
                )) &&
            (identical(other.from, from) ||
                const DeepCollectionEquality().equals(other.from, from)) &&
            (identical(other.to, to) ||
                const DeepCollectionEquality().equals(other.to, to)) &&
            (identical(other.preimageHash, preimageHash) ||
                const DeepCollectionEquality().equals(
                  other.preimageHash,
                  preimageHash,
                )) &&
            (identical(other.invoice, invoice) ||
                const DeepCollectionEquality().equals(
                  other.invoice,
                  invoice,
                )) &&
            (identical(other.claimDetails, claimDetails) ||
                const DeepCollectionEquality().equals(
                  other.claimDetails,
                  claimDetails,
                )) &&
            (identical(other.refundDetails, refundDetails) ||
                const DeepCollectionEquality().equals(
                  other.refundDetails,
                  refundDetails,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(type) ^
      const DeepCollectionEquality().hash(status) ^
      const DeepCollectionEquality().hash(createdAt) ^
      const DeepCollectionEquality().hash(from) ^
      const DeepCollectionEquality().hash(to) ^
      const DeepCollectionEquality().hash(preimageHash) ^
      const DeepCollectionEquality().hash(invoice) ^
      const DeepCollectionEquality().hash(claimDetails) ^
      const DeepCollectionEquality().hash(refundDetails) ^
      runtimeType.hashCode;
}

extension $RestorableSwapExtension on RestorableSwap {
  RestorableSwap copyWith({
    String? id,
    enums.RestorableSwapType? type,
    String? status,
    double? createdAt,
    String? from,
    String? to,
    String? preimageHash,
    String? invoice,
    RestoreClaimDetails? claimDetails,
    RestoreRefundDetails? refundDetails,
  }) {
    return RestorableSwap(
      id: id ?? this.id,
      type: type ?? this.type,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      from: from ?? this.from,
      to: to ?? this.to,
      preimageHash: preimageHash ?? this.preimageHash,
      invoice: invoice ?? this.invoice,
      claimDetails: claimDetails ?? this.claimDetails,
      refundDetails: refundDetails ?? this.refundDetails,
    );
  }

  RestorableSwap copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<enums.RestorableSwapType>? type,
    Wrapped<String>? status,
    Wrapped<double>? createdAt,
    Wrapped<String>? from,
    Wrapped<String>? to,
    Wrapped<String?>? preimageHash,
    Wrapped<String?>? invoice,
    Wrapped<RestoreClaimDetails?>? claimDetails,
    Wrapped<RestoreRefundDetails?>? refundDetails,
  }) {
    return RestorableSwap(
      id: (id != null ? id.value : this.id),
      type: (type != null ? type.value : this.type),
      status: (status != null ? status.value : this.status),
      createdAt: (createdAt != null ? createdAt.value : this.createdAt),
      from: (from != null ? from.value : this.from),
      to: (to != null ? to.value : this.to),
      preimageHash: (preimageHash != null
          ? preimageHash.value
          : this.preimageHash),
      invoice: (invoice != null ? invoice.value : this.invoice),
      claimDetails: (claimDetails != null
          ? claimDetails.value
          : this.claimDetails),
      refundDetails: (refundDetails != null
          ? refundDetails.value
          : this.refundDetails),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class RestoreIndexResponse {
  const RestoreIndexResponse({required this.index});

  factory RestoreIndexResponse.fromJson(Map<String, dynamic> json) =>
      _$RestoreIndexResponseFromJson(json);

  static const toJsonFactory = _$RestoreIndexResponseToJson;
  Map<String, dynamic> toJson() => _$RestoreIndexResponseToJson(this);

  @JsonKey(name: 'index', includeIfNull: false)
  final double index;
  static const fromJsonFactory = _$RestoreIndexResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is RestoreIndexResponse &&
            (identical(other.index, index) ||
                const DeepCollectionEquality().equals(other.index, index)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(index) ^ runtimeType.hashCode;
}

extension $RestoreIndexResponseExtension on RestoreIndexResponse {
  RestoreIndexResponse copyWith({double? index}) {
    return RestoreIndexResponse(index: index ?? this.index);
  }

  RestoreIndexResponse copyWithWrapped({Wrapped<double>? index}) {
    return RestoreIndexResponse(
      index: (index != null ? index.value : this.index),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AssetRescueSetupRequest {
  const AssetRescueSetupRequest({
    required this.swapId,
    required this.transactionId,
    required this.vout,
    required this.destination,
  });

  factory AssetRescueSetupRequest.fromJson(Map<String, dynamic> json) =>
      _$AssetRescueSetupRequestFromJson(json);

  static const toJsonFactory = _$AssetRescueSetupRequestToJson;
  Map<String, dynamic> toJson() => _$AssetRescueSetupRequestToJson(this);

  @JsonKey(name: 'swapId', includeIfNull: false)
  final String swapId;
  @JsonKey(name: 'transactionId', includeIfNull: false)
  final String transactionId;
  @JsonKey(name: 'vout', includeIfNull: false)
  final double vout;
  @JsonKey(name: 'destination', includeIfNull: false)
  final String destination;
  static const fromJsonFactory = _$AssetRescueSetupRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AssetRescueSetupRequest &&
            (identical(other.swapId, swapId) ||
                const DeepCollectionEquality().equals(other.swapId, swapId)) &&
            (identical(other.transactionId, transactionId) ||
                const DeepCollectionEquality().equals(
                  other.transactionId,
                  transactionId,
                )) &&
            (identical(other.vout, vout) ||
                const DeepCollectionEquality().equals(other.vout, vout)) &&
            (identical(other.destination, destination) ||
                const DeepCollectionEquality().equals(
                  other.destination,
                  destination,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(swapId) ^
      const DeepCollectionEquality().hash(transactionId) ^
      const DeepCollectionEquality().hash(vout) ^
      const DeepCollectionEquality().hash(destination) ^
      runtimeType.hashCode;
}

extension $AssetRescueSetupRequestExtension on AssetRescueSetupRequest {
  AssetRescueSetupRequest copyWith({
    String? swapId,
    String? transactionId,
    double? vout,
    String? destination,
  }) {
    return AssetRescueSetupRequest(
      swapId: swapId ?? this.swapId,
      transactionId: transactionId ?? this.transactionId,
      vout: vout ?? this.vout,
      destination: destination ?? this.destination,
    );
  }

  AssetRescueSetupRequest copyWithWrapped({
    Wrapped<String>? swapId,
    Wrapped<String>? transactionId,
    Wrapped<double>? vout,
    Wrapped<String>? destination,
  }) {
    return AssetRescueSetupRequest(
      swapId: (swapId != null ? swapId.value : this.swapId),
      transactionId: (transactionId != null
          ? transactionId.value
          : this.transactionId),
      vout: (vout != null ? vout.value : this.vout),
      destination: (destination != null ? destination.value : this.destination),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AssetRescueMusigData {
  const AssetRescueMusigData({
    required this.serverPublicKey,
    required this.pubNonce,
    required this.message,
  });

  factory AssetRescueMusigData.fromJson(Map<String, dynamic> json) =>
      _$AssetRescueMusigDataFromJson(json);

  static const toJsonFactory = _$AssetRescueMusigDataToJson;
  Map<String, dynamic> toJson() => _$AssetRescueMusigDataToJson(this);

  @JsonKey(name: 'serverPublicKey', includeIfNull: false)
  final String serverPublicKey;
  @JsonKey(name: 'pubNonce', includeIfNull: false)
  final String pubNonce;
  @JsonKey(name: 'message', includeIfNull: false)
  final String message;
  static const fromJsonFactory = _$AssetRescueMusigDataFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AssetRescueMusigData &&
            (identical(other.serverPublicKey, serverPublicKey) ||
                const DeepCollectionEquality().equals(
                  other.serverPublicKey,
                  serverPublicKey,
                )) &&
            (identical(other.pubNonce, pubNonce) ||
                const DeepCollectionEquality().equals(
                  other.pubNonce,
                  pubNonce,
                )) &&
            (identical(other.message, message) ||
                const DeepCollectionEquality().equals(other.message, message)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(serverPublicKey) ^
      const DeepCollectionEquality().hash(pubNonce) ^
      const DeepCollectionEquality().hash(message) ^
      runtimeType.hashCode;
}

extension $AssetRescueMusigDataExtension on AssetRescueMusigData {
  AssetRescueMusigData copyWith({
    String? serverPublicKey,
    String? pubNonce,
    String? message,
  }) {
    return AssetRescueMusigData(
      serverPublicKey: serverPublicKey ?? this.serverPublicKey,
      pubNonce: pubNonce ?? this.pubNonce,
      message: message ?? this.message,
    );
  }

  AssetRescueMusigData copyWithWrapped({
    Wrapped<String>? serverPublicKey,
    Wrapped<String>? pubNonce,
    Wrapped<String>? message,
  }) {
    return AssetRescueMusigData(
      serverPublicKey: (serverPublicKey != null
          ? serverPublicKey.value
          : this.serverPublicKey),
      pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
      message: (message != null ? message.value : this.message),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AssetRescueSetupResponse {
  const AssetRescueSetupResponse({
    required this.musig,
    required this.transaction,
  });

  factory AssetRescueSetupResponse.fromJson(Map<String, dynamic> json) =>
      _$AssetRescueSetupResponseFromJson(json);

  static const toJsonFactory = _$AssetRescueSetupResponseToJson;
  Map<String, dynamic> toJson() => _$AssetRescueSetupResponseToJson(this);

  @JsonKey(name: 'musig', includeIfNull: false)
  final AssetRescueMusigData musig;
  @JsonKey(name: 'transaction', includeIfNull: false)
  final String transaction;
  static const fromJsonFactory = _$AssetRescueSetupResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AssetRescueSetupResponse &&
            (identical(other.musig, musig) ||
                const DeepCollectionEquality().equals(other.musig, musig)) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality().equals(
                  other.transaction,
                  transaction,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(musig) ^
      const DeepCollectionEquality().hash(transaction) ^
      runtimeType.hashCode;
}

extension $AssetRescueSetupResponseExtension on AssetRescueSetupResponse {
  AssetRescueSetupResponse copyWith({
    AssetRescueMusigData? musig,
    String? transaction,
  }) {
    return AssetRescueSetupResponse(
      musig: musig ?? this.musig,
      transaction: transaction ?? this.transaction,
    );
  }

  AssetRescueSetupResponse copyWithWrapped({
    Wrapped<AssetRescueMusigData>? musig,
    Wrapped<String>? transaction,
  }) {
    return AssetRescueSetupResponse(
      musig: (musig != null ? musig.value : this.musig),
      transaction: (transaction != null ? transaction.value : this.transaction),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AssetRescueBroadcastRequest {
  const AssetRescueBroadcastRequest({
    required this.swapId,
    required this.pubNonce,
    required this.partialSignature,
  });

  factory AssetRescueBroadcastRequest.fromJson(Map<String, dynamic> json) =>
      _$AssetRescueBroadcastRequestFromJson(json);

  static const toJsonFactory = _$AssetRescueBroadcastRequestToJson;
  Map<String, dynamic> toJson() => _$AssetRescueBroadcastRequestToJson(this);

  @JsonKey(name: 'swapId', includeIfNull: false)
  final String swapId;
  @JsonKey(name: 'pubNonce', includeIfNull: false)
  final String pubNonce;
  @JsonKey(name: 'partialSignature', includeIfNull: false)
  final String partialSignature;
  static const fromJsonFactory = _$AssetRescueBroadcastRequestFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AssetRescueBroadcastRequest &&
            (identical(other.swapId, swapId) ||
                const DeepCollectionEquality().equals(other.swapId, swapId)) &&
            (identical(other.pubNonce, pubNonce) ||
                const DeepCollectionEquality().equals(
                  other.pubNonce,
                  pubNonce,
                )) &&
            (identical(other.partialSignature, partialSignature) ||
                const DeepCollectionEquality().equals(
                  other.partialSignature,
                  partialSignature,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(swapId) ^
      const DeepCollectionEquality().hash(pubNonce) ^
      const DeepCollectionEquality().hash(partialSignature) ^
      runtimeType.hashCode;
}

extension $AssetRescueBroadcastRequestExtension on AssetRescueBroadcastRequest {
  AssetRescueBroadcastRequest copyWith({
    String? swapId,
    String? pubNonce,
    String? partialSignature,
  }) {
    return AssetRescueBroadcastRequest(
      swapId: swapId ?? this.swapId,
      pubNonce: pubNonce ?? this.pubNonce,
      partialSignature: partialSignature ?? this.partialSignature,
    );
  }

  AssetRescueBroadcastRequest copyWithWrapped({
    Wrapped<String>? swapId,
    Wrapped<String>? pubNonce,
    Wrapped<String>? partialSignature,
  }) {
    return AssetRescueBroadcastRequest(
      swapId: (swapId != null ? swapId.value : this.swapId),
      pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
      partialSignature: (partialSignature != null
          ? partialSignature.value
          : this.partialSignature),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class AssetRescueBroadcastResponse {
  const AssetRescueBroadcastResponse({required this.transactionId});

  factory AssetRescueBroadcastResponse.fromJson(Map<String, dynamic> json) =>
      _$AssetRescueBroadcastResponseFromJson(json);

  static const toJsonFactory = _$AssetRescueBroadcastResponseToJson;
  Map<String, dynamic> toJson() => _$AssetRescueBroadcastResponseToJson(this);

  @JsonKey(name: 'transactionId', includeIfNull: false)
  final String transactionId;
  static const fromJsonFactory = _$AssetRescueBroadcastResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is AssetRescueBroadcastResponse &&
            (identical(other.transactionId, transactionId) ||
                const DeepCollectionEquality().equals(
                  other.transactionId,
                  transactionId,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(transactionId) ^ runtimeType.hashCode;
}

extension $AssetRescueBroadcastResponseExtension
    on AssetRescueBroadcastResponse {
  AssetRescueBroadcastResponse copyWith({String? transactionId}) {
    return AssetRescueBroadcastResponse(
      transactionId: transactionId ?? this.transactionId,
    );
  }

  AssetRescueBroadcastResponse copyWithWrapped({
    Wrapped<String>? transactionId,
  }) {
    return AssetRescueBroadcastResponse(
      transactionId: (transactionId != null
          ? transactionId.value
          : this.transactionId),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class PairStats {
  const PairStats({required this.fee, this.maximalRoutingFee});

  factory PairStats.fromJson(Map<String, dynamic> json) =>
      _$PairStatsFromJson(json);

  static const toJsonFactory = _$PairStatsToJson;
  Map<String, dynamic> toJson() => _$PairStatsToJson(this);

  @JsonKey(name: 'fee', includeIfNull: false, defaultValue: <List<Object?>>[])
  final List<List<Object?>> fee;
  @JsonKey(
    name: 'maximalRoutingFee',
    includeIfNull: false,
    defaultValue: <List<Object?>>[],
  )
  final List<List<Object?>>? maximalRoutingFee;
  static const fromJsonFactory = _$PairStatsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is PairStats &&
            (identical(other.fee, fee) ||
                const DeepCollectionEquality().equals(other.fee, fee)) &&
            (identical(other.maximalRoutingFee, maximalRoutingFee) ||
                const DeepCollectionEquality().equals(
                  other.maximalRoutingFee,
                  maximalRoutingFee,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(fee) ^
      const DeepCollectionEquality().hash(maximalRoutingFee) ^
      runtimeType.hashCode;
}

extension $PairStatsExtension on PairStats {
  PairStats copyWith({
    List<List<Object?>>? fee,
    List<List<Object?>>? maximalRoutingFee,
  }) {
    return PairStats(
      fee: fee ?? this.fee,
      maximalRoutingFee: maximalRoutingFee ?? this.maximalRoutingFee,
    );
  }

  PairStats copyWithWrapped({
    Wrapped<List<List<Object?>>>? fee,
    Wrapped<List<List<Object?>>?>? maximalRoutingFee,
  }) {
    return PairStats(
      fee: (fee != null ? fee.value : this.fee),
      maximalRoutingFee: (maximalRoutingFee != null
          ? maximalRoutingFee.value
          : this.maximalRoutingFee),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LightningNode {
  const LightningNode({required this.id, this.alias, this.color});

  factory LightningNode.fromJson(Map<String, dynamic> json) =>
      _$LightningNodeFromJson(json);

  static const toJsonFactory = _$LightningNodeToJson;
  Map<String, dynamic> toJson() => _$LightningNodeToJson(this);

  @JsonKey(name: 'id', includeIfNull: false)
  final String id;
  @JsonKey(name: 'alias', includeIfNull: false)
  final String? alias;
  @JsonKey(name: 'color', includeIfNull: false)
  final String? color;
  static const fromJsonFactory = _$LightningNodeFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningNode &&
            (identical(other.id, id) ||
                const DeepCollectionEquality().equals(other.id, id)) &&
            (identical(other.alias, alias) ||
                const DeepCollectionEquality().equals(other.alias, alias)) &&
            (identical(other.color, color) ||
                const DeepCollectionEquality().equals(other.color, color)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(id) ^
      const DeepCollectionEquality().hash(alias) ^
      const DeepCollectionEquality().hash(color) ^
      runtimeType.hashCode;
}

extension $LightningNodeExtension on LightningNode {
  LightningNode copyWith({String? id, String? alias, String? color}) {
    return LightningNode(
      id: id ?? this.id,
      alias: alias ?? this.alias,
      color: color ?? this.color,
    );
  }

  LightningNode copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String?>? alias,
    Wrapped<String?>? color,
  }) {
    return LightningNode(
      id: (id != null ? id.value : this.id),
      alias: (alias != null ? alias.value : this.alias),
      color: (color != null ? color.value : this.color),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LightningChannelPolicy {
  const LightningChannelPolicy({
    required this.active,
    required this.baseFeeMillisatoshi,
    required this.feePpm,
    required this.delay,
    this.htlcMinimumMillisatoshi,
    this.htlcMaximumMillisatoshi,
  });

  factory LightningChannelPolicy.fromJson(Map<String, dynamic> json) =>
      _$LightningChannelPolicyFromJson(json);

  static const toJsonFactory = _$LightningChannelPolicyToJson;
  Map<String, dynamic> toJson() => _$LightningChannelPolicyToJson(this);

  @JsonKey(name: 'active', includeIfNull: false)
  final bool active;
  @JsonKey(name: 'baseFeeMillisatoshi', includeIfNull: false)
  final double baseFeeMillisatoshi;
  @JsonKey(name: 'feePpm', includeIfNull: false)
  final double feePpm;
  @JsonKey(name: 'delay', includeIfNull: false)
  final double delay;
  @JsonKey(name: 'htlcMinimumMillisatoshi', includeIfNull: false)
  final double? htlcMinimumMillisatoshi;
  @JsonKey(name: 'htlcMaximumMillisatoshi', includeIfNull: false)
  final double? htlcMaximumMillisatoshi;
  static const fromJsonFactory = _$LightningChannelPolicyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningChannelPolicy &&
            (identical(other.active, active) ||
                const DeepCollectionEquality().equals(other.active, active)) &&
            (identical(other.baseFeeMillisatoshi, baseFeeMillisatoshi) ||
                const DeepCollectionEquality().equals(
                  other.baseFeeMillisatoshi,
                  baseFeeMillisatoshi,
                )) &&
            (identical(other.feePpm, feePpm) ||
                const DeepCollectionEquality().equals(other.feePpm, feePpm)) &&
            (identical(other.delay, delay) ||
                const DeepCollectionEquality().equals(other.delay, delay)) &&
            (identical(
                  other.htlcMinimumMillisatoshi,
                  htlcMinimumMillisatoshi,
                ) ||
                const DeepCollectionEquality().equals(
                  other.htlcMinimumMillisatoshi,
                  htlcMinimumMillisatoshi,
                )) &&
            (identical(
                  other.htlcMaximumMillisatoshi,
                  htlcMaximumMillisatoshi,
                ) ||
                const DeepCollectionEquality().equals(
                  other.htlcMaximumMillisatoshi,
                  htlcMaximumMillisatoshi,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(active) ^
      const DeepCollectionEquality().hash(baseFeeMillisatoshi) ^
      const DeepCollectionEquality().hash(feePpm) ^
      const DeepCollectionEquality().hash(delay) ^
      const DeepCollectionEquality().hash(htlcMinimumMillisatoshi) ^
      const DeepCollectionEquality().hash(htlcMaximumMillisatoshi) ^
      runtimeType.hashCode;
}

extension $LightningChannelPolicyExtension on LightningChannelPolicy {
  LightningChannelPolicy copyWith({
    bool? active,
    double? baseFeeMillisatoshi,
    double? feePpm,
    double? delay,
    double? htlcMinimumMillisatoshi,
    double? htlcMaximumMillisatoshi,
  }) {
    return LightningChannelPolicy(
      active: active ?? this.active,
      baseFeeMillisatoshi: baseFeeMillisatoshi ?? this.baseFeeMillisatoshi,
      feePpm: feePpm ?? this.feePpm,
      delay: delay ?? this.delay,
      htlcMinimumMillisatoshi:
          htlcMinimumMillisatoshi ?? this.htlcMinimumMillisatoshi,
      htlcMaximumMillisatoshi:
          htlcMaximumMillisatoshi ?? this.htlcMaximumMillisatoshi,
    );
  }

  LightningChannelPolicy copyWithWrapped({
    Wrapped<bool>? active,
    Wrapped<double>? baseFeeMillisatoshi,
    Wrapped<double>? feePpm,
    Wrapped<double>? delay,
    Wrapped<double?>? htlcMinimumMillisatoshi,
    Wrapped<double?>? htlcMaximumMillisatoshi,
  }) {
    return LightningChannelPolicy(
      active: (active != null ? active.value : this.active),
      baseFeeMillisatoshi: (baseFeeMillisatoshi != null
          ? baseFeeMillisatoshi.value
          : this.baseFeeMillisatoshi),
      feePpm: (feePpm != null ? feePpm.value : this.feePpm),
      delay: (delay != null ? delay.value : this.delay),
      htlcMinimumMillisatoshi: (htlcMinimumMillisatoshi != null
          ? htlcMinimumMillisatoshi.value
          : this.htlcMinimumMillisatoshi),
      htlcMaximumMillisatoshi: (htlcMaximumMillisatoshi != null
          ? htlcMaximumMillisatoshi.value
          : this.htlcMaximumMillisatoshi),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LightningChannel {
  const LightningChannel({
    required this.source,
    required this.shortChannelId,
    this.capacity,
    this.active,
    this.info,
  });

  factory LightningChannel.fromJson(Map<String, dynamic> json) =>
      _$LightningChannelFromJson(json);

  static const toJsonFactory = _$LightningChannelToJson;
  Map<String, dynamic> toJson() => _$LightningChannelToJson(this);

  @JsonKey(name: 'source', includeIfNull: false)
  final LightningNode source;
  @JsonKey(name: 'shortChannelId', includeIfNull: false)
  final String shortChannelId;
  @JsonKey(name: 'capacity', includeIfNull: false)
  final double? capacity;
  @JsonKey(name: 'active', includeIfNull: false)
  final bool? active;
  @JsonKey(name: 'info', includeIfNull: false)
  final LightningChannelPolicy? info;
  static const fromJsonFactory = _$LightningChannelFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningChannel &&
            (identical(other.source, source) ||
                const DeepCollectionEquality().equals(other.source, source)) &&
            (identical(other.shortChannelId, shortChannelId) ||
                const DeepCollectionEquality().equals(
                  other.shortChannelId,
                  shortChannelId,
                )) &&
            (identical(other.capacity, capacity) ||
                const DeepCollectionEquality().equals(
                  other.capacity,
                  capacity,
                )) &&
            (identical(other.active, active) ||
                const DeepCollectionEquality().equals(other.active, active)) &&
            (identical(other.info, info) ||
                const DeepCollectionEquality().equals(other.info, info)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(source) ^
      const DeepCollectionEquality().hash(shortChannelId) ^
      const DeepCollectionEquality().hash(capacity) ^
      const DeepCollectionEquality().hash(active) ^
      const DeepCollectionEquality().hash(info) ^
      runtimeType.hashCode;
}

extension $LightningChannelExtension on LightningChannel {
  LightningChannel copyWith({
    LightningNode? source,
    String? shortChannelId,
    double? capacity,
    bool? active,
    LightningChannelPolicy? info,
  }) {
    return LightningChannel(
      source: source ?? this.source,
      shortChannelId: shortChannelId ?? this.shortChannelId,
      capacity: capacity ?? this.capacity,
      active: active ?? this.active,
      info: info ?? this.info,
    );
  }

  LightningChannel copyWithWrapped({
    Wrapped<LightningNode>? source,
    Wrapped<String>? shortChannelId,
    Wrapped<double?>? capacity,
    Wrapped<bool?>? active,
    Wrapped<LightningChannelPolicy?>? info,
  }) {
    return LightningChannel(
      source: (source != null ? source.value : this.source),
      shortChannelId: (shortChannelId != null
          ? shortChannelId.value
          : this.shortChannelId),
      capacity: (capacity != null ? capacity.value : this.capacity),
      active: (active != null ? active.value : this.active),
      info: (info != null ? info.value : this.info),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LightningChannelInfo {
  const LightningChannelInfo({
    required this.shortChannelId,
    required this.capacity,
    required this.policies,
  });

  factory LightningChannelInfo.fromJson(Map<String, dynamic> json) =>
      _$LightningChannelInfoFromJson(json);

  static const toJsonFactory = _$LightningChannelInfoToJson;
  Map<String, dynamic> toJson() => _$LightningChannelInfoToJson(this);

  @JsonKey(name: 'shortChannelId', includeIfNull: false)
  final String shortChannelId;
  @JsonKey(name: 'capacity', includeIfNull: false)
  final double capacity;
  @JsonKey(
    name: 'policies',
    includeIfNull: false,
    defaultValue: <LightningChannelPolicy>[],
  )
  final List<LightningChannelPolicy> policies;
  static const fromJsonFactory = _$LightningChannelInfoFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningChannelInfo &&
            (identical(other.shortChannelId, shortChannelId) ||
                const DeepCollectionEquality().equals(
                  other.shortChannelId,
                  shortChannelId,
                )) &&
            (identical(other.capacity, capacity) ||
                const DeepCollectionEquality().equals(
                  other.capacity,
                  capacity,
                )) &&
            (identical(other.policies, policies) ||
                const DeepCollectionEquality().equals(
                  other.policies,
                  policies,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(shortChannelId) ^
      const DeepCollectionEquality().hash(capacity) ^
      const DeepCollectionEquality().hash(policies) ^
      runtimeType.hashCode;
}

extension $LightningChannelInfoExtension on LightningChannelInfo {
  LightningChannelInfo copyWith({
    String? shortChannelId,
    double? capacity,
    List<LightningChannelPolicy>? policies,
  }) {
    return LightningChannelInfo(
      shortChannelId: shortChannelId ?? this.shortChannelId,
      capacity: capacity ?? this.capacity,
      policies: policies ?? this.policies,
    );
  }

  LightningChannelInfo copyWithWrapped({
    Wrapped<String>? shortChannelId,
    Wrapped<double>? capacity,
    Wrapped<List<LightningChannelPolicy>>? policies,
  }) {
    return LightningChannelInfo(
      shortChannelId: (shortChannelId != null
          ? shortChannelId.value
          : this.shortChannelId),
      capacity: (capacity != null ? capacity.value : this.capacity),
      policies: (policies != null ? policies.value : this.policies),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Contracts {
  const Contracts({
    required this.network,
    required this.swapContracts,
    required this.supportedContracts,
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
  @JsonKey(name: 'supportedContracts', includeIfNull: false)
  final Map<String, dynamic> supportedContracts;
  @JsonKey(name: 'tokens', includeIfNull: false)
  final Map<String, dynamic> tokens;
  static const fromJsonFactory = _$ContractsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Contracts &&
            (identical(other.network, network) ||
                const DeepCollectionEquality().equals(
                  other.network,
                  network,
                )) &&
            (identical(other.swapContracts, swapContracts) ||
                const DeepCollectionEquality().equals(
                  other.swapContracts,
                  swapContracts,
                )) &&
            (identical(other.supportedContracts, supportedContracts) ||
                const DeepCollectionEquality().equals(
                  other.supportedContracts,
                  supportedContracts,
                )) &&
            (identical(other.tokens, tokens) ||
                const DeepCollectionEquality().equals(other.tokens, tokens)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(network) ^
      const DeepCollectionEquality().hash(swapContracts) ^
      const DeepCollectionEquality().hash(supportedContracts) ^
      const DeepCollectionEquality().hash(tokens) ^
      runtimeType.hashCode;
}

extension $ContractsExtension on Contracts {
  Contracts copyWith({
    Contracts$Network? network,
    Contracts$SwapContracts? swapContracts,
    Map<String, dynamic>? supportedContracts,
    Map<String, dynamic>? tokens,
  }) {
    return Contracts(
      network: network ?? this.network,
      swapContracts: swapContracts ?? this.swapContracts,
      supportedContracts: supportedContracts ?? this.supportedContracts,
      tokens: tokens ?? this.tokens,
    );
  }

  Contracts copyWithWrapped({
    Wrapped<Contracts$Network>? network,
    Wrapped<Contracts$SwapContracts>? swapContracts,
    Wrapped<Map<String, dynamic>>? supportedContracts,
    Wrapped<Map<String, dynamic>>? tokens,
  }) {
    return Contracts(
      network: (network != null ? network.value : this.network),
      swapContracts: (swapContracts != null
          ? swapContracts.value
          : this.swapContracts),
      supportedContracts: (supportedContracts != null
          ? supportedContracts.value
          : this.supportedContracts),
      tokens: (tokens != null ? tokens.value : this.tokens),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class TokenQuote {
  const TokenQuote({required this.quote, required this.data});

  factory TokenQuote.fromJson(Map<String, dynamic> json) =>
      _$TokenQuoteFromJson(json);

  static const toJsonFactory = _$TokenQuoteToJson;
  Map<String, dynamic> toJson() => _$TokenQuoteToJson(this);

  @JsonKey(name: 'quote', includeIfNull: false)
  final String quote;
  @JsonKey(name: 'data', includeIfNull: false)
  final Map<String, dynamic> data;
  static const fromJsonFactory = _$TokenQuoteFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is TokenQuote &&
            (identical(other.quote, quote) ||
                const DeepCollectionEquality().equals(other.quote, quote)) &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(quote) ^
      const DeepCollectionEquality().hash(data) ^
      runtimeType.hashCode;
}

extension $TokenQuoteExtension on TokenQuote {
  TokenQuote copyWith({String? quote, Map<String, dynamic>? data}) {
    return TokenQuote(quote: quote ?? this.quote, data: data ?? this.data);
  }

  TokenQuote copyWithWrapped({
    Wrapped<String>? quote,
    Wrapped<Map<String, dynamic>>? data,
  }) {
    return TokenQuote(
      quote: (quote != null ? quote.value : this.quote),
      data: (data != null ? data.value : this.data),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Call {
  const Call({required this.to, required this.value, required this.data});

  factory Call.fromJson(Map<String, dynamic> json) => _$CallFromJson(json);

  static const toJsonFactory = _$CallToJson;
  Map<String, dynamic> toJson() => _$CallToJson(this);

  @JsonKey(name: 'to', includeIfNull: false)
  final String to;
  @JsonKey(name: 'value', includeIfNull: false)
  final String value;
  @JsonKey(name: 'data', includeIfNull: false)
  final String data;
  static const fromJsonFactory = _$CallFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Call &&
            (identical(other.to, to) ||
                const DeepCollectionEquality().equals(other.to, to)) &&
            (identical(other.value, value) ||
                const DeepCollectionEquality().equals(other.value, value)) &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(to) ^
      const DeepCollectionEquality().hash(value) ^
      const DeepCollectionEquality().hash(data) ^
      runtimeType.hashCode;
}

extension $CallExtension on Call {
  Call copyWith({String? to, String? value, String? data}) {
    return Call(
      to: to ?? this.to,
      value: value ?? this.value,
      data: data ?? this.data,
    );
  }

  Call copyWithWrapped({
    Wrapped<String>? to,
    Wrapped<String>? value,
    Wrapped<String>? data,
  }) {
    return Call(
      to: (to != null ? to.value : this.to),
      value: (value != null ? value.value : this.value),
      data: (data != null ? data.value : this.data),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class NodeInfo {
  const NodeInfo({required this.publicKey, required this.uris});

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
                const DeepCollectionEquality().equals(
                  other.publicKey,
                  publicKey,
                )) &&
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
      publicKey: publicKey ?? this.publicKey,
      uris: uris ?? this.uris,
    );
  }

  NodeInfo copyWithWrapped({
    Wrapped<String>? publicKey,
    Wrapped<List<String>>? uris,
  }) {
    return NodeInfo(
      publicKey: (publicKey != null ? publicKey.value : this.publicKey),
      uris: (uris != null ? uris.value : this.uris),
    );
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
                const DeepCollectionEquality().equals(
                  other.capacity,
                  capacity,
                )) &&
            (identical(other.channels, channels) ||
                const DeepCollectionEquality().equals(
                  other.channels,
                  channels,
                )) &&
            (identical(other.peers, peers) ||
                const DeepCollectionEquality().equals(other.peers, peers)) &&
            (identical(other.oldestChannel, oldestChannel) ||
                const DeepCollectionEquality().equals(
                  other.oldestChannel,
                  oldestChannel,
                )));
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
  NodeStats copyWith({
    int? capacity,
    int? channels,
    int? peers,
    int? oldestChannel,
  }) {
    return NodeStats(
      capacity: capacity ?? this.capacity,
      channels: channels ?? this.channels,
      peers: peers ?? this.peers,
      oldestChannel: oldestChannel ?? this.oldestChannel,
    );
  }

  NodeStats copyWithWrapped({
    Wrapped<int>? capacity,
    Wrapped<int>? channels,
    Wrapped<int>? peers,
    Wrapped<int>? oldestChannel,
  }) {
    return NodeStats(
      capacity: (capacity != null ? capacity.value : this.capacity),
      channels: (channels != null ? channels.value : this.channels),
      peers: (peers != null ? peers.value : this.peers),
      oldestChannel: (oldestChannel != null
          ? oldestChannel.value
          : this.oldestChannel),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CommitmentLockupDetails {
  const CommitmentLockupDetails({
    required this.contract,
    required this.claimAddress,
    required this.timelock,
  });

  factory CommitmentLockupDetails.fromJson(Map<String, dynamic> json) =>
      _$CommitmentLockupDetailsFromJson(json);

  static const toJsonFactory = _$CommitmentLockupDetailsToJson;
  Map<String, dynamic> toJson() => _$CommitmentLockupDetailsToJson(this);

  @JsonKey(name: 'contract', includeIfNull: false)
  final String contract;
  @JsonKey(name: 'claimAddress', includeIfNull: false)
  final String claimAddress;
  @JsonKey(name: 'timelock', includeIfNull: false)
  final double timelock;
  static const fromJsonFactory = _$CommitmentLockupDetailsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CommitmentLockupDetails &&
            (identical(other.contract, contract) ||
                const DeepCollectionEquality().equals(
                  other.contract,
                  contract,
                )) &&
            (identical(other.claimAddress, claimAddress) ||
                const DeepCollectionEquality().equals(
                  other.claimAddress,
                  claimAddress,
                )) &&
            (identical(other.timelock, timelock) ||
                const DeepCollectionEquality().equals(
                  other.timelock,
                  timelock,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(contract) ^
      const DeepCollectionEquality().hash(claimAddress) ^
      const DeepCollectionEquality().hash(timelock) ^
      runtimeType.hashCode;
}

extension $CommitmentLockupDetailsExtension on CommitmentLockupDetails {
  CommitmentLockupDetails copyWith({
    String? contract,
    String? claimAddress,
    double? timelock,
  }) {
    return CommitmentLockupDetails(
      contract: contract ?? this.contract,
      claimAddress: claimAddress ?? this.claimAddress,
      timelock: timelock ?? this.timelock,
    );
  }

  CommitmentLockupDetails copyWithWrapped({
    Wrapped<String>? contract,
    Wrapped<String>? claimAddress,
    Wrapped<double>? timelock,
  }) {
    return CommitmentLockupDetails(
      contract: (contract != null ? contract.value : this.contract),
      claimAddress: (claimAddress != null
          ? claimAddress.value
          : this.claimAddress),
      timelock: (timelock != null ? timelock.value : this.timelock),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ErrorResponse {
  const ErrorResponse({required this.error});

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
class SwapSubmarineIdInvoicePost$RequestBody {
  const SwapSubmarineIdInvoicePost$RequestBody({
    required this.invoice,
    this.pairHash,
  });

  factory SwapSubmarineIdInvoicePost$RequestBody.fromJson(
    Map<String, dynamic> json,
  ) => _$SwapSubmarineIdInvoicePost$RequestBodyFromJson(json);

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
                const DeepCollectionEquality().equals(
                  other.invoice,
                  invoice,
                )) &&
            (identical(other.pairHash, pairHash) ||
                const DeepCollectionEquality().equals(
                  other.pairHash,
                  pairHash,
                )));
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
  SwapSubmarineIdInvoicePost$RequestBody copyWith({
    String? invoice,
    String? pairHash,
  }) {
    return SwapSubmarineIdInvoicePost$RequestBody(
      invoice: invoice ?? this.invoice,
      pairHash: pairHash ?? this.pairHash,
    );
  }

  SwapSubmarineIdInvoicePost$RequestBody copyWithWrapped({
    Wrapped<String>? invoice,
    Wrapped<String?>? pairHash,
  }) {
    return SwapSubmarineIdInvoicePost$RequestBody(
      invoice: (invoice != null ? invoice.value : this.invoice),
      pairHash: (pairHash != null ? pairHash.value : this.pairHash),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LightningCurrencyBolt12Post$RequestBody {
  const LightningCurrencyBolt12Post$RequestBody({
    required this.offer,
    this.url,
  });

  factory LightningCurrencyBolt12Post$RequestBody.fromJson(
    Map<String, dynamic> json,
  ) => _$LightningCurrencyBolt12Post$RequestBodyFromJson(json);

  static const toJsonFactory = _$LightningCurrencyBolt12Post$RequestBodyToJson;
  Map<String, dynamic> toJson() =>
      _$LightningCurrencyBolt12Post$RequestBodyToJson(this);

  @JsonKey(name: 'offer', includeIfNull: false)
  final String offer;
  @JsonKey(name: 'url', includeIfNull: false)
  final String? url;
  static const fromJsonFactory =
      _$LightningCurrencyBolt12Post$RequestBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningCurrencyBolt12Post$RequestBody &&
            (identical(other.offer, offer) ||
                const DeepCollectionEquality().equals(other.offer, offer)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(offer) ^
      const DeepCollectionEquality().hash(url) ^
      runtimeType.hashCode;
}

extension $LightningCurrencyBolt12Post$RequestBodyExtension
    on LightningCurrencyBolt12Post$RequestBody {
  LightningCurrencyBolt12Post$RequestBody copyWith({
    String? offer,
    String? url,
  }) {
    return LightningCurrencyBolt12Post$RequestBody(
      offer: offer ?? this.offer,
      url: url ?? this.url,
    );
  }

  LightningCurrencyBolt12Post$RequestBody copyWithWrapped({
    Wrapped<String>? offer,
    Wrapped<String?>? url,
  }) {
    return LightningCurrencyBolt12Post$RequestBody(
      offer: (offer != null ? offer.value : this.offer),
      url: (url != null ? url.value : this.url),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LightningCurrencyBolt12Patch$RequestBody {
  const LightningCurrencyBolt12Patch$RequestBody({
    required this.offer,
    this.url,
    required this.signature,
  });

  factory LightningCurrencyBolt12Patch$RequestBody.fromJson(
    Map<String, dynamic> json,
  ) => _$LightningCurrencyBolt12Patch$RequestBodyFromJson(json);

  static const toJsonFactory = _$LightningCurrencyBolt12Patch$RequestBodyToJson;
  Map<String, dynamic> toJson() =>
      _$LightningCurrencyBolt12Patch$RequestBodyToJson(this);

  @JsonKey(name: 'offer', includeIfNull: false)
  final String offer;
  @JsonKey(name: 'url', includeIfNull: false)
  final String? url;
  @JsonKey(name: 'signature', includeIfNull: false)
  final String signature;
  static const fromJsonFactory =
      _$LightningCurrencyBolt12Patch$RequestBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningCurrencyBolt12Patch$RequestBody &&
            (identical(other.offer, offer) ||
                const DeepCollectionEquality().equals(other.offer, offer)) &&
            (identical(other.url, url) ||
                const DeepCollectionEquality().equals(other.url, url)) &&
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
      const DeepCollectionEquality().hash(offer) ^
      const DeepCollectionEquality().hash(url) ^
      const DeepCollectionEquality().hash(signature) ^
      runtimeType.hashCode;
}

extension $LightningCurrencyBolt12Patch$RequestBodyExtension
    on LightningCurrencyBolt12Patch$RequestBody {
  LightningCurrencyBolt12Patch$RequestBody copyWith({
    String? offer,
    String? url,
    String? signature,
  }) {
    return LightningCurrencyBolt12Patch$RequestBody(
      offer: offer ?? this.offer,
      url: url ?? this.url,
      signature: signature ?? this.signature,
    );
  }

  LightningCurrencyBolt12Patch$RequestBody copyWithWrapped({
    Wrapped<String>? offer,
    Wrapped<String?>? url,
    Wrapped<String>? signature,
  }) {
    return LightningCurrencyBolt12Patch$RequestBody(
      offer: (offer != null ? offer.value : this.offer),
      url: (url != null ? url.value : this.url),
      signature: (signature != null ? signature.value : this.signature),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LightningCurrencyBolt12Delete$RequestBody {
  const LightningCurrencyBolt12Delete$RequestBody({
    required this.offer,
    required this.signature,
  });

  factory LightningCurrencyBolt12Delete$RequestBody.fromJson(
    Map<String, dynamic> json,
  ) => _$LightningCurrencyBolt12Delete$RequestBodyFromJson(json);

  static const toJsonFactory =
      _$LightningCurrencyBolt12Delete$RequestBodyToJson;
  Map<String, dynamic> toJson() =>
      _$LightningCurrencyBolt12Delete$RequestBodyToJson(this);

  @JsonKey(name: 'offer', includeIfNull: false)
  final String offer;
  @JsonKey(name: 'signature', includeIfNull: false)
  final String signature;
  static const fromJsonFactory =
      _$LightningCurrencyBolt12Delete$RequestBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningCurrencyBolt12Delete$RequestBody &&
            (identical(other.offer, offer) ||
                const DeepCollectionEquality().equals(other.offer, offer)) &&
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
      const DeepCollectionEquality().hash(offer) ^
      const DeepCollectionEquality().hash(signature) ^
      runtimeType.hashCode;
}

extension $LightningCurrencyBolt12Delete$RequestBodyExtension
    on LightningCurrencyBolt12Delete$RequestBody {
  LightningCurrencyBolt12Delete$RequestBody copyWith({
    String? offer,
    String? signature,
  }) {
    return LightningCurrencyBolt12Delete$RequestBody(
      offer: offer ?? this.offer,
      signature: signature ?? this.signature,
    );
  }

  LightningCurrencyBolt12Delete$RequestBody copyWithWrapped({
    Wrapped<String>? offer,
    Wrapped<String>? signature,
  }) {
    return LightningCurrencyBolt12Delete$RequestBody(
      offer: (offer != null ? offer.value : this.offer),
      signature: (signature != null ? signature.value : this.signature),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LightningCurrencyBolt12FetchPost$RequestBody {
  const LightningCurrencyBolt12FetchPost$RequestBody({
    required this.offer,
    required this.amount,
    this.note,
  });

  factory LightningCurrencyBolt12FetchPost$RequestBody.fromJson(
    Map<String, dynamic> json,
  ) => _$LightningCurrencyBolt12FetchPost$RequestBodyFromJson(json);

  static const toJsonFactory =
      _$LightningCurrencyBolt12FetchPost$RequestBodyToJson;
  Map<String, dynamic> toJson() =>
      _$LightningCurrencyBolt12FetchPost$RequestBodyToJson(this);

  @JsonKey(name: 'offer', includeIfNull: false)
  final String offer;
  @JsonKey(name: 'amount', includeIfNull: false)
  final double amount;
  @JsonKey(name: 'note', includeIfNull: false)
  final String? note;
  static const fromJsonFactory =
      _$LightningCurrencyBolt12FetchPost$RequestBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningCurrencyBolt12FetchPost$RequestBody &&
            (identical(other.offer, offer) ||
                const DeepCollectionEquality().equals(other.offer, offer)) &&
            (identical(other.amount, amount) ||
                const DeepCollectionEquality().equals(other.amount, amount)) &&
            (identical(other.note, note) ||
                const DeepCollectionEquality().equals(other.note, note)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(offer) ^
      const DeepCollectionEquality().hash(amount) ^
      const DeepCollectionEquality().hash(note) ^
      runtimeType.hashCode;
}

extension $LightningCurrencyBolt12FetchPost$RequestBodyExtension
    on LightningCurrencyBolt12FetchPost$RequestBody {
  LightningCurrencyBolt12FetchPost$RequestBody copyWith({
    String? offer,
    double? amount,
    String? note,
  }) {
    return LightningCurrencyBolt12FetchPost$RequestBody(
      offer: offer ?? this.offer,
      amount: amount ?? this.amount,
      note: note ?? this.note,
    );
  }

  LightningCurrencyBolt12FetchPost$RequestBody copyWithWrapped({
    Wrapped<String>? offer,
    Wrapped<double>? amount,
    Wrapped<String?>? note,
  }) {
    return LightningCurrencyBolt12FetchPost$RequestBody(
      offer: (offer != null ? offer.value : this.offer),
      amount: (amount != null ? amount.value : this.amount),
      note: (note != null ? note.value : this.note),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainCurrencyTransactionPost$RequestBody {
  const ChainCurrencyTransactionPost$RequestBody({required this.hex});

  factory ChainCurrencyTransactionPost$RequestBody.fromJson(
    Map<String, dynamic> json,
  ) => _$ChainCurrencyTransactionPost$RequestBodyFromJson(json);

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

  ChainCurrencyTransactionPost$RequestBody copyWithWrapped({
    Wrapped<String>? hex,
  }) {
    return ChainCurrencyTransactionPost$RequestBody(
      hex: (hex != null ? hex.value : this.hex),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class QuoteCurrencyEncodePost$RequestBody {
  const QuoteCurrencyEncodePost$RequestBody({
    required this.recipient,
    required this.amountIn,
    required this.amountOutMin,
    required this.data,
  });

  factory QuoteCurrencyEncodePost$RequestBody.fromJson(
    Map<String, dynamic> json,
  ) => _$QuoteCurrencyEncodePost$RequestBodyFromJson(json);

  static const toJsonFactory = _$QuoteCurrencyEncodePost$RequestBodyToJson;
  Map<String, dynamic> toJson() =>
      _$QuoteCurrencyEncodePost$RequestBodyToJson(this);

  @JsonKey(name: 'recipient', includeIfNull: false)
  final String recipient;
  @JsonKey(name: 'amountIn', includeIfNull: false)
  final String amountIn;
  @JsonKey(name: 'amountOutMin', includeIfNull: false)
  final String amountOutMin;
  @JsonKey(name: 'data', includeIfNull: false)
  final Map<String, dynamic> data;
  static const fromJsonFactory = _$QuoteCurrencyEncodePost$RequestBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is QuoteCurrencyEncodePost$RequestBody &&
            (identical(other.recipient, recipient) ||
                const DeepCollectionEquality().equals(
                  other.recipient,
                  recipient,
                )) &&
            (identical(other.amountIn, amountIn) ||
                const DeepCollectionEquality().equals(
                  other.amountIn,
                  amountIn,
                )) &&
            (identical(other.amountOutMin, amountOutMin) ||
                const DeepCollectionEquality().equals(
                  other.amountOutMin,
                  amountOutMin,
                )) &&
            (identical(other.data, data) ||
                const DeepCollectionEquality().equals(other.data, data)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(recipient) ^
      const DeepCollectionEquality().hash(amountIn) ^
      const DeepCollectionEquality().hash(amountOutMin) ^
      const DeepCollectionEquality().hash(data) ^
      runtimeType.hashCode;
}

extension $QuoteCurrencyEncodePost$RequestBodyExtension
    on QuoteCurrencyEncodePost$RequestBody {
  QuoteCurrencyEncodePost$RequestBody copyWith({
    String? recipient,
    String? amountIn,
    String? amountOutMin,
    Map<String, dynamic>? data,
  }) {
    return QuoteCurrencyEncodePost$RequestBody(
      recipient: recipient ?? this.recipient,
      amountIn: amountIn ?? this.amountIn,
      amountOutMin: amountOutMin ?? this.amountOutMin,
      data: data ?? this.data,
    );
  }

  QuoteCurrencyEncodePost$RequestBody copyWithWrapped({
    Wrapped<String>? recipient,
    Wrapped<String>? amountIn,
    Wrapped<String>? amountOutMin,
    Wrapped<Map<String, dynamic>>? data,
  }) {
    return QuoteCurrencyEncodePost$RequestBody(
      recipient: (recipient != null ? recipient.value : this.recipient),
      amountIn: (amountIn != null ? amountIn.value : this.amountIn),
      amountOutMin: (amountOutMin != null
          ? amountOutMin.value
          : this.amountOutMin),
      data: (data != null ? data.value : this.data),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CommitmentCurrencyPost$RequestBody {
  const CommitmentCurrencyPost$RequestBody({
    required this.swapId,
    required this.signature,
    required this.transactionHash,
    this.logIndex,
    this.maxOverpaymentPercentage,
  });

  factory CommitmentCurrencyPost$RequestBody.fromJson(
    Map<String, dynamic> json,
  ) => _$CommitmentCurrencyPost$RequestBodyFromJson(json);

  static const toJsonFactory = _$CommitmentCurrencyPost$RequestBodyToJson;
  Map<String, dynamic> toJson() =>
      _$CommitmentCurrencyPost$RequestBodyToJson(this);

  @JsonKey(name: 'swapId', includeIfNull: false)
  final String swapId;
  @JsonKey(name: 'signature', includeIfNull: false)
  final String signature;
  @JsonKey(name: 'transactionHash', includeIfNull: false)
  final String transactionHash;
  @JsonKey(name: 'logIndex', includeIfNull: false)
  final int? logIndex;
  @JsonKey(name: 'maxOverpaymentPercentage', includeIfNull: false)
  final double? maxOverpaymentPercentage;
  static const fromJsonFactory = _$CommitmentCurrencyPost$RequestBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CommitmentCurrencyPost$RequestBody &&
            (identical(other.swapId, swapId) ||
                const DeepCollectionEquality().equals(other.swapId, swapId)) &&
            (identical(other.signature, signature) ||
                const DeepCollectionEquality().equals(
                  other.signature,
                  signature,
                )) &&
            (identical(other.transactionHash, transactionHash) ||
                const DeepCollectionEquality().equals(
                  other.transactionHash,
                  transactionHash,
                )) &&
            (identical(other.logIndex, logIndex) ||
                const DeepCollectionEquality().equals(
                  other.logIndex,
                  logIndex,
                )) &&
            (identical(
                  other.maxOverpaymentPercentage,
                  maxOverpaymentPercentage,
                ) ||
                const DeepCollectionEquality().equals(
                  other.maxOverpaymentPercentage,
                  maxOverpaymentPercentage,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(swapId) ^
      const DeepCollectionEquality().hash(signature) ^
      const DeepCollectionEquality().hash(transactionHash) ^
      const DeepCollectionEquality().hash(logIndex) ^
      const DeepCollectionEquality().hash(maxOverpaymentPercentage) ^
      runtimeType.hashCode;
}

extension $CommitmentCurrencyPost$RequestBodyExtension
    on CommitmentCurrencyPost$RequestBody {
  CommitmentCurrencyPost$RequestBody copyWith({
    String? swapId,
    String? signature,
    String? transactionHash,
    int? logIndex,
    double? maxOverpaymentPercentage,
  }) {
    return CommitmentCurrencyPost$RequestBody(
      swapId: swapId ?? this.swapId,
      signature: signature ?? this.signature,
      transactionHash: transactionHash ?? this.transactionHash,
      logIndex: logIndex ?? this.logIndex,
      maxOverpaymentPercentage:
          maxOverpaymentPercentage ?? this.maxOverpaymentPercentage,
    );
  }

  CommitmentCurrencyPost$RequestBody copyWithWrapped({
    Wrapped<String>? swapId,
    Wrapped<String>? signature,
    Wrapped<String>? transactionHash,
    Wrapped<int?>? logIndex,
    Wrapped<double?>? maxOverpaymentPercentage,
  }) {
    return CommitmentCurrencyPost$RequestBody(
      swapId: (swapId != null ? swapId.value : this.swapId),
      signature: (signature != null ? signature.value : this.signature),
      transactionHash: (transactionHash != null
          ? transactionHash.value
          : this.transactionHash),
      logIndex: (logIndex != null ? logIndex.value : this.logIndex),
      maxOverpaymentPercentage: (maxOverpaymentPercentage != null
          ? maxOverpaymentPercentage.value
          : this.maxOverpaymentPercentage),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CommitmentCurrencyRefundPost$RequestBody {
  const CommitmentCurrencyRefundPost$RequestBody({
    required this.transactionHash,
    this.logIndex,
    required this.refundAddressSignature,
  });

  factory CommitmentCurrencyRefundPost$RequestBody.fromJson(
    Map<String, dynamic> json,
  ) => _$CommitmentCurrencyRefundPost$RequestBodyFromJson(json);

  static const toJsonFactory = _$CommitmentCurrencyRefundPost$RequestBodyToJson;
  Map<String, dynamic> toJson() =>
      _$CommitmentCurrencyRefundPost$RequestBodyToJson(this);

  @JsonKey(name: 'transactionHash', includeIfNull: false)
  final String transactionHash;
  @JsonKey(name: 'logIndex', includeIfNull: false)
  final int? logIndex;
  @JsonKey(name: 'refundAddressSignature', includeIfNull: false)
  final String refundAddressSignature;
  static const fromJsonFactory =
      _$CommitmentCurrencyRefundPost$RequestBodyFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CommitmentCurrencyRefundPost$RequestBody &&
            (identical(other.transactionHash, transactionHash) ||
                const DeepCollectionEquality().equals(
                  other.transactionHash,
                  transactionHash,
                )) &&
            (identical(other.logIndex, logIndex) ||
                const DeepCollectionEquality().equals(
                  other.logIndex,
                  logIndex,
                )) &&
            (identical(other.refundAddressSignature, refundAddressSignature) ||
                const DeepCollectionEquality().equals(
                  other.refundAddressSignature,
                  refundAddressSignature,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(transactionHash) ^
      const DeepCollectionEquality().hash(logIndex) ^
      const DeepCollectionEquality().hash(refundAddressSignature) ^
      runtimeType.hashCode;
}

extension $CommitmentCurrencyRefundPost$RequestBodyExtension
    on CommitmentCurrencyRefundPost$RequestBody {
  CommitmentCurrencyRefundPost$RequestBody copyWith({
    String? transactionHash,
    int? logIndex,
    String? refundAddressSignature,
  }) {
    return CommitmentCurrencyRefundPost$RequestBody(
      transactionHash: transactionHash ?? this.transactionHash,
      logIndex: logIndex ?? this.logIndex,
      refundAddressSignature:
          refundAddressSignature ?? this.refundAddressSignature,
    );
  }

  CommitmentCurrencyRefundPost$RequestBody copyWithWrapped({
    Wrapped<String>? transactionHash,
    Wrapped<int?>? logIndex,
    Wrapped<String>? refundAddressSignature,
  }) {
    return CommitmentCurrencyRefundPost$RequestBody(
      transactionHash: (transactionHash != null
          ? transactionHash.value
          : this.transactionHash),
      logIndex: (logIndex != null ? logIndex.value : this.logIndex),
      refundAddressSignature: (refundAddressSignature != null
          ? refundAddressSignature.value
          : this.refundAddressSignature),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class VersionGet$Response {
  const VersionGet$Response({required this.version});

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
      version: (version != null ? version.value : this.version),
    );
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
    Map<String, dynamic> json,
  ) => _$SwapSubmarineIdInvoicePost$ResponseFromJson(json);

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
                const DeepCollectionEquality().equals(
                  other.expectedAmount,
                  expectedAmount,
                )) &&
            (identical(other.acceptZeroConf, acceptZeroConf) ||
                const DeepCollectionEquality().equals(
                  other.acceptZeroConf,
                  acceptZeroConf,
                )));
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
  SwapSubmarineIdInvoicePost$Response copyWith({
    String? bip21,
    double? expectedAmount,
    bool? acceptZeroConf,
  }) {
    return SwapSubmarineIdInvoicePost$Response(
      bip21: bip21 ?? this.bip21,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      acceptZeroConf: acceptZeroConf ?? this.acceptZeroConf,
    );
  }

  SwapSubmarineIdInvoicePost$Response copyWithWrapped({
    Wrapped<String>? bip21,
    Wrapped<double>? expectedAmount,
    Wrapped<bool>? acceptZeroConf,
  }) {
    return SwapSubmarineIdInvoicePost$Response(
      bip21: (bip21 != null ? bip21.value : this.bip21),
      expectedAmount: (expectedAmount != null
          ? expectedAmount.value
          : this.expectedAmount),
      acceptZeroConf: (acceptZeroConf != null
          ? acceptZeroConf.value
          : this.acceptZeroConf),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SwapSubmarineIdInvoiceAmountGet$Response {
  const SwapSubmarineIdInvoiceAmountGet$Response({required this.invoiceAmount});

  factory SwapSubmarineIdInvoiceAmountGet$Response.fromJson(
    Map<String, dynamic> json,
  ) => _$SwapSubmarineIdInvoiceAmountGet$ResponseFromJson(json);

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
                const DeepCollectionEquality().equals(
                  other.invoiceAmount,
                  invoiceAmount,
                )));
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
      invoiceAmount: invoiceAmount ?? this.invoiceAmount,
    );
  }

  SwapSubmarineIdInvoiceAmountGet$Response copyWithWrapped({
    Wrapped<double>? invoiceAmount,
  }) {
    return SwapSubmarineIdInvoiceAmountGet$Response(
      invoiceAmount: (invoiceAmount != null
          ? invoiceAmount.value
          : this.invoiceAmount),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SwapSubmarineIdRefundGet$Response {
  const SwapSubmarineIdRefundGet$Response({required this.signature});

  factory SwapSubmarineIdRefundGet$Response.fromJson(
    Map<String, dynamic> json,
  ) => _$SwapSubmarineIdRefundGet$ResponseFromJson(json);

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
                const DeepCollectionEquality().equals(
                  other.signature,
                  signature,
                )));
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
      signature: signature ?? this.signature,
    );
  }

  SwapSubmarineIdRefundGet$Response copyWithWrapped({
    Wrapped<String>? signature,
  }) {
    return SwapSubmarineIdRefundGet$Response(
      signature: (signature != null ? signature.value : this.signature),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SwapChainIdRefundGet$Response {
  const SwapChainIdRefundGet$Response({required this.signature});

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
                const DeepCollectionEquality().equals(
                  other.signature,
                  signature,
                )));
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
      signature: signature ?? this.signature,
    );
  }

  SwapChainIdRefundGet$Response copyWithWrapped({Wrapped<String>? signature}) {
    return SwapChainIdRefundGet$Response(
      signature: (signature != null ? signature.value : this.signature),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LightningCurrencyBolt12ReceivingGet$Response {
  const LightningCurrencyBolt12ReceivingGet$Response({required this.minCltv});

  factory LightningCurrencyBolt12ReceivingGet$Response.fromJson(
    Map<String, dynamic> json,
  ) => _$LightningCurrencyBolt12ReceivingGet$ResponseFromJson(json);

  static const toJsonFactory =
      _$LightningCurrencyBolt12ReceivingGet$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$LightningCurrencyBolt12ReceivingGet$ResponseToJson(this);

  @JsonKey(name: 'minCltv', includeIfNull: false)
  final int minCltv;
  static const fromJsonFactory =
      _$LightningCurrencyBolt12ReceivingGet$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningCurrencyBolt12ReceivingGet$Response &&
            (identical(other.minCltv, minCltv) ||
                const DeepCollectionEquality().equals(other.minCltv, minCltv)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(minCltv) ^ runtimeType.hashCode;
}

extension $LightningCurrencyBolt12ReceivingGet$ResponseExtension
    on LightningCurrencyBolt12ReceivingGet$Response {
  LightningCurrencyBolt12ReceivingGet$Response copyWith({int? minCltv}) {
    return LightningCurrencyBolt12ReceivingGet$Response(
      minCltv: minCltv ?? this.minCltv,
    );
  }

  LightningCurrencyBolt12ReceivingGet$Response copyWithWrapped({
    Wrapped<int>? minCltv,
  }) {
    return LightningCurrencyBolt12ReceivingGet$Response(
      minCltv: (minCltv != null ? minCltv.value : this.minCltv),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class LightningCurrencyBolt12FetchPost$Response {
  const LightningCurrencyBolt12FetchPost$Response({
    required this.invoice,
    this.magicRoutingHint,
  });

  factory LightningCurrencyBolt12FetchPost$Response.fromJson(
    Map<String, dynamic> json,
  ) => _$LightningCurrencyBolt12FetchPost$ResponseFromJson(json);

  static const toJsonFactory =
      _$LightningCurrencyBolt12FetchPost$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$LightningCurrencyBolt12FetchPost$ResponseToJson(this);

  @JsonKey(name: 'invoice', includeIfNull: false)
  final String invoice;
  @JsonKey(name: 'magicRoutingHint', includeIfNull: false)
  final ReverseBip21? magicRoutingHint;
  static const fromJsonFactory =
      _$LightningCurrencyBolt12FetchPost$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is LightningCurrencyBolt12FetchPost$Response &&
            (identical(other.invoice, invoice) ||
                const DeepCollectionEquality().equals(
                  other.invoice,
                  invoice,
                )) &&
            (identical(other.magicRoutingHint, magicRoutingHint) ||
                const DeepCollectionEquality().equals(
                  other.magicRoutingHint,
                  magicRoutingHint,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(invoice) ^
      const DeepCollectionEquality().hash(magicRoutingHint) ^
      runtimeType.hashCode;
}

extension $LightningCurrencyBolt12FetchPost$ResponseExtension
    on LightningCurrencyBolt12FetchPost$Response {
  LightningCurrencyBolt12FetchPost$Response copyWith({
    String? invoice,
    ReverseBip21? magicRoutingHint,
  }) {
    return LightningCurrencyBolt12FetchPost$Response(
      invoice: invoice ?? this.invoice,
      magicRoutingHint: magicRoutingHint ?? this.magicRoutingHint,
    );
  }

  LightningCurrencyBolt12FetchPost$Response copyWithWrapped({
    Wrapped<String>? invoice,
    Wrapped<ReverseBip21?>? magicRoutingHint,
  }) {
    return LightningCurrencyBolt12FetchPost$Response(
      invoice: (invoice != null ? invoice.value : this.invoice),
      magicRoutingHint: (magicRoutingHint != null
          ? magicRoutingHint.value
          : this.magicRoutingHint),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainCurrencyFeeGet$Response {
  const ChainCurrencyFeeGet$Response({required this.fee});

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
      fee: (fee != null ? fee.value : this.fee),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainCurrencyHeightGet$Response {
  const ChainCurrencyHeightGet$Response({required this.height});

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
      height: (height != null ? height.value : this.height),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainCurrencyTransactionIdGet$Response {
  const ChainCurrencyTransactionIdGet$Response({
    required this.hex,
    this.confirmations,
  });

  factory ChainCurrencyTransactionIdGet$Response.fromJson(
    Map<String, dynamic> json,
  ) => _$ChainCurrencyTransactionIdGet$ResponseFromJson(json);

  static const toJsonFactory = _$ChainCurrencyTransactionIdGet$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$ChainCurrencyTransactionIdGet$ResponseToJson(this);

  @JsonKey(name: 'hex', includeIfNull: false)
  final String hex;
  @JsonKey(name: 'confirmations', includeIfNull: false)
  final double? confirmations;
  static const fromJsonFactory =
      _$ChainCurrencyTransactionIdGet$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainCurrencyTransactionIdGet$Response &&
            (identical(other.hex, hex) ||
                const DeepCollectionEquality().equals(other.hex, hex)) &&
            (identical(other.confirmations, confirmations) ||
                const DeepCollectionEquality().equals(
                  other.confirmations,
                  confirmations,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(hex) ^
      const DeepCollectionEquality().hash(confirmations) ^
      runtimeType.hashCode;
}

extension $ChainCurrencyTransactionIdGet$ResponseExtension
    on ChainCurrencyTransactionIdGet$Response {
  ChainCurrencyTransactionIdGet$Response copyWith({
    String? hex,
    double? confirmations,
  }) {
    return ChainCurrencyTransactionIdGet$Response(
      hex: hex ?? this.hex,
      confirmations: confirmations ?? this.confirmations,
    );
  }

  ChainCurrencyTransactionIdGet$Response copyWithWrapped({
    Wrapped<String>? hex,
    Wrapped<double?>? confirmations,
  }) {
    return ChainCurrencyTransactionIdGet$Response(
      hex: (hex != null ? hex.value : this.hex),
      confirmations: (confirmations != null
          ? confirmations.value
          : this.confirmations),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainCurrencyTransactionPost$Response {
  const ChainCurrencyTransactionPost$Response({required this.id});

  factory ChainCurrencyTransactionPost$Response.fromJson(
    Map<String, dynamic> json,
  ) => _$ChainCurrencyTransactionPost$ResponseFromJson(json);

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
      id: (id != null ? id.value : this.id),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class QuoteCurrencyEncodePost$Response {
  const QuoteCurrencyEncodePost$Response({required this.calls});

  factory QuoteCurrencyEncodePost$Response.fromJson(
    Map<String, dynamic> json,
  ) => _$QuoteCurrencyEncodePost$ResponseFromJson(json);

  static const toJsonFactory = _$QuoteCurrencyEncodePost$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$QuoteCurrencyEncodePost$ResponseToJson(this);

  @JsonKey(name: 'calls', includeIfNull: false, defaultValue: <Call>[])
  final List<Call> calls;
  static const fromJsonFactory = _$QuoteCurrencyEncodePost$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is QuoteCurrencyEncodePost$Response &&
            (identical(other.calls, calls) ||
                const DeepCollectionEquality().equals(other.calls, calls)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(calls) ^ runtimeType.hashCode;
}

extension $QuoteCurrencyEncodePost$ResponseExtension
    on QuoteCurrencyEncodePost$Response {
  QuoteCurrencyEncodePost$Response copyWith({List<Call>? calls}) {
    return QuoteCurrencyEncodePost$Response(calls: calls ?? this.calls);
  }

  QuoteCurrencyEncodePost$Response copyWithWrapped({
    Wrapped<List<Call>>? calls,
  }) {
    return QuoteCurrencyEncodePost$Response(
      calls: (calls != null ? calls.value : this.calls),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class CommitmentCurrencyRefundPost$Response {
  const CommitmentCurrencyRefundPost$Response({required this.signature});

  factory CommitmentCurrencyRefundPost$Response.fromJson(
    Map<String, dynamic> json,
  ) => _$CommitmentCurrencyRefundPost$ResponseFromJson(json);

  static const toJsonFactory = _$CommitmentCurrencyRefundPost$ResponseToJson;
  Map<String, dynamic> toJson() =>
      _$CommitmentCurrencyRefundPost$ResponseToJson(this);

  @JsonKey(name: 'signature', includeIfNull: false)
  final String signature;
  static const fromJsonFactory =
      _$CommitmentCurrencyRefundPost$ResponseFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CommitmentCurrencyRefundPost$Response &&
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
      const DeepCollectionEquality().hash(signature) ^ runtimeType.hashCode;
}

extension $CommitmentCurrencyRefundPost$ResponseExtension
    on CommitmentCurrencyRefundPost$Response {
  CommitmentCurrencyRefundPost$Response copyWith({String? signature}) {
    return CommitmentCurrencyRefundPost$Response(
      signature: signature ?? this.signature,
    );
  }

  CommitmentCurrencyRefundPost$Response copyWithWrapped({
    Wrapped<String>? signature,
  }) {
    return CommitmentCurrencyRefundPost$Response(
      signature: (signature != null ? signature.value : this.signature),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ReferralGet$Response {
  const ReferralGet$Response({required this.id});

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
class SubmarinePair$Limits {
  const SubmarinePair$Limits({
    required this.minimal,
    this.minimalBatched,
    required this.maximal,
    required this.maximalZeroConf,
  });

  factory SubmarinePair$Limits.fromJson(Map<String, dynamic> json) =>
      _$SubmarinePair$LimitsFromJson(json);

  static const toJsonFactory = _$SubmarinePair$LimitsToJson;
  Map<String, dynamic> toJson() => _$SubmarinePair$LimitsToJson(this);

  @JsonKey(name: 'minimal', includeIfNull: false)
  final double minimal;
  @JsonKey(name: 'minimalBatched', includeIfNull: false)
  final double? minimalBatched;
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
                const DeepCollectionEquality().equals(
                  other.minimal,
                  minimal,
                )) &&
            (identical(other.minimalBatched, minimalBatched) ||
                const DeepCollectionEquality().equals(
                  other.minimalBatched,
                  minimalBatched,
                )) &&
            (identical(other.maximal, maximal) ||
                const DeepCollectionEquality().equals(
                  other.maximal,
                  maximal,
                )) &&
            (identical(other.maximalZeroConf, maximalZeroConf) ||
                const DeepCollectionEquality().equals(
                  other.maximalZeroConf,
                  maximalZeroConf,
                )));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(minimal) ^
      const DeepCollectionEquality().hash(minimalBatched) ^
      const DeepCollectionEquality().hash(maximal) ^
      const DeepCollectionEquality().hash(maximalZeroConf) ^
      runtimeType.hashCode;
}

extension $SubmarinePair$LimitsExtension on SubmarinePair$Limits {
  SubmarinePair$Limits copyWith({
    double? minimal,
    double? minimalBatched,
    double? maximal,
    double? maximalZeroConf,
  }) {
    return SubmarinePair$Limits(
      minimal: minimal ?? this.minimal,
      minimalBatched: minimalBatched ?? this.minimalBatched,
      maximal: maximal ?? this.maximal,
      maximalZeroConf: maximalZeroConf ?? this.maximalZeroConf,
    );
  }

  SubmarinePair$Limits copyWithWrapped({
    Wrapped<double>? minimal,
    Wrapped<double?>? minimalBatched,
    Wrapped<double>? maximal,
    Wrapped<double>? maximalZeroConf,
  }) {
    return SubmarinePair$Limits(
      minimal: (minimal != null ? minimal.value : this.minimal),
      minimalBatched: (minimalBatched != null
          ? minimalBatched.value
          : this.minimalBatched),
      maximal: (maximal != null ? maximal.value : this.maximal),
      maximalZeroConf: (maximalZeroConf != null
          ? maximalZeroConf.value
          : this.maximalZeroConf),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SubmarinePair$Fees {
  const SubmarinePair$Fees({required this.percentage, required this.minerFees});

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
                const DeepCollectionEquality().equals(
                  other.percentage,
                  percentage,
                )) &&
            (identical(other.minerFees, minerFees) ||
                const DeepCollectionEquality().equals(
                  other.minerFees,
                  minerFees,
                )));
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
      minerFees: minerFees ?? this.minerFees,
    );
  }

  SubmarinePair$Fees copyWithWrapped({
    Wrapped<double>? percentage,
    Wrapped<double>? minerFees,
  }) {
    return SubmarinePair$Fees(
      percentage: (percentage != null ? percentage.value : this.percentage),
      minerFees: (minerFees != null ? minerFees.value : this.minerFees),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ReversePair$Limits {
  const ReversePair$Limits({required this.minimal, required this.maximal});

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
                const DeepCollectionEquality().equals(
                  other.minimal,
                  minimal,
                )) &&
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
      minimal: minimal ?? this.minimal,
      maximal: maximal ?? this.maximal,
    );
  }

  ReversePair$Limits copyWithWrapped({
    Wrapped<double>? minimal,
    Wrapped<double>? maximal,
  }) {
    return ReversePair$Limits(
      minimal: (minimal != null ? minimal.value : this.minimal),
      maximal: (maximal != null ? maximal.value : this.maximal),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ReversePair$Fees {
  const ReversePair$Fees({required this.percentage, required this.minerFees});

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
                const DeepCollectionEquality().equals(
                  other.percentage,
                  percentage,
                )) &&
            (identical(other.minerFees, minerFees) ||
                const DeepCollectionEquality().equals(
                  other.minerFees,
                  minerFees,
                )));
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
  ReversePair$Fees copyWith({
    double? percentage,
    ReversePair$Fees$MinerFees? minerFees,
  }) {
    return ReversePair$Fees(
      percentage: percentage ?? this.percentage,
      minerFees: minerFees ?? this.minerFees,
    );
  }

  ReversePair$Fees copyWithWrapped({
    Wrapped<double>? percentage,
    Wrapped<ReversePair$Fees$MinerFees>? minerFees,
  }) {
    return ReversePair$Fees(
      percentage: (percentage != null ? percentage.value : this.percentage),
      minerFees: (minerFees != null ? minerFees.value : this.minerFees),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainPair$Limits {
  const ChainPair$Limits({
    required this.minimal,
    required this.maximal,
    required this.maximalZeroConf,
  });

  factory ChainPair$Limits.fromJson(Map<String, dynamic> json) =>
      _$ChainPair$LimitsFromJson(json);

  static const toJsonFactory = _$ChainPair$LimitsToJson;
  Map<String, dynamic> toJson() => _$ChainPair$LimitsToJson(this);

  @JsonKey(name: 'minimal', includeIfNull: false)
  final double minimal;
  @JsonKey(name: 'maximal', includeIfNull: false)
  final double maximal;
  @JsonKey(name: 'maximalZeroConf', includeIfNull: false)
  final double maximalZeroConf;
  static const fromJsonFactory = _$ChainPair$LimitsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainPair$Limits &&
            (identical(other.minimal, minimal) ||
                const DeepCollectionEquality().equals(
                  other.minimal,
                  minimal,
                )) &&
            (identical(other.maximal, maximal) ||
                const DeepCollectionEquality().equals(
                  other.maximal,
                  maximal,
                )) &&
            (identical(other.maximalZeroConf, maximalZeroConf) ||
                const DeepCollectionEquality().equals(
                  other.maximalZeroConf,
                  maximalZeroConf,
                )));
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

extension $ChainPair$LimitsExtension on ChainPair$Limits {
  ChainPair$Limits copyWith({
    double? minimal,
    double? maximal,
    double? maximalZeroConf,
  }) {
    return ChainPair$Limits(
      minimal: minimal ?? this.minimal,
      maximal: maximal ?? this.maximal,
      maximalZeroConf: maximalZeroConf ?? this.maximalZeroConf,
    );
  }

  ChainPair$Limits copyWithWrapped({
    Wrapped<double>? minimal,
    Wrapped<double>? maximal,
    Wrapped<double>? maximalZeroConf,
  }) {
    return ChainPair$Limits(
      minimal: (minimal != null ? minimal.value : this.minimal),
      maximal: (maximal != null ? maximal.value : this.maximal),
      maximalZeroConf: (maximalZeroConf != null
          ? maximalZeroConf.value
          : this.maximalZeroConf),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainPair$Fees {
  const ChainPair$Fees({required this.percentage, required this.minerFees});

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
                const DeepCollectionEquality().equals(
                  other.percentage,
                  percentage,
                )) &&
            (identical(other.minerFees, minerFees) ||
                const DeepCollectionEquality().equals(
                  other.minerFees,
                  minerFees,
                )));
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
  ChainPair$Fees copyWith({
    double? percentage,
    ChainPair$Fees$MinerFees? minerFees,
  }) {
    return ChainPair$Fees(
      percentage: percentage ?? this.percentage,
      minerFees: minerFees ?? this.minerFees,
    );
  }

  ChainPair$Fees copyWithWrapped({
    Wrapped<double>? percentage,
    Wrapped<ChainPair$Fees$MinerFees>? minerFees,
  }) {
    return ChainPair$Fees(
      percentage: (percentage != null ? percentage.value : this.percentage),
      minerFees: (minerFees != null ? minerFees.value : this.minerFees),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapTransaction$Transaction {
  const ChainSwapTransaction$Transaction({required this.id, this.hex});

  factory ChainSwapTransaction$Transaction.fromJson(
    Map<String, dynamic> json,
  ) => _$ChainSwapTransaction$TransactionFromJson(json);

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
      id: id ?? this.id,
      hex: hex ?? this.hex,
    );
  }

  ChainSwapTransaction$Transaction copyWithWrapped({
    Wrapped<String>? id,
    Wrapped<String?>? hex,
  }) {
    return ChainSwapTransaction$Transaction(
      id: (id != null ? id.value : this.id),
      hex: (hex != null ? hex.value : this.hex),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainSwapTransaction$Timeout {
  const ChainSwapTransaction$Timeout({required this.blockHeight, this.eta});

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
                const DeepCollectionEquality().equals(
                  other.blockHeight,
                  blockHeight,
                )) &&
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
      blockHeight: blockHeight ?? this.blockHeight,
      eta: eta ?? this.eta,
    );
  }

  ChainSwapTransaction$Timeout copyWithWrapped({
    Wrapped<double>? blockHeight,
    Wrapped<double?>? eta,
  }) {
    return ChainSwapTransaction$Timeout(
      blockHeight: (blockHeight != null ? blockHeight.value : this.blockHeight),
      eta: (eta != null ? eta.value : this.eta),
    );
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
                const DeepCollectionEquality().equals(
                  other.pubNonce,
                  pubNonce,
                )) &&
            (identical(other.transaction, transaction) ||
                const DeepCollectionEquality().equals(
                  other.transaction,
                  transaction,
                )) &&
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
  ChainSwapSigningRequest$ToSign copyWith({
    String? pubNonce,
    String? transaction,
    double? index,
  }) {
    return ChainSwapSigningRequest$ToSign(
      pubNonce: pubNonce ?? this.pubNonce,
      transaction: transaction ?? this.transaction,
      index: index ?? this.index,
    );
  }

  ChainSwapSigningRequest$ToSign copyWithWrapped({
    Wrapped<String>? pubNonce,
    Wrapped<String>? transaction,
    Wrapped<double>? index,
  }) {
    return ChainSwapSigningRequest$ToSign(
      pubNonce: (pubNonce != null ? pubNonce.value : this.pubNonce),
      transaction: (transaction != null ? transaction.value : this.transaction),
      index: (index != null ? index.value : this.index),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class SwapStatus$Transaction {
  const SwapStatus$Transaction({this.id, this.hex});

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

  SwapStatus$Transaction copyWithWrapped({
    Wrapped<String?>? id,
    Wrapped<String?>? hex,
  }) {
    return SwapStatus$Transaction(
      id: (id != null ? id.value : this.id),
      hex: (hex != null ? hex.value : this.hex),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Contracts$Network {
  const Contracts$Network({required this.chainId, required this.name});

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
                const DeepCollectionEquality().equals(
                  other.chainId,
                  chainId,
                )) &&
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
      chainId: chainId ?? this.chainId,
      name: name ?? this.name,
    );
  }

  Contracts$Network copyWithWrapped({
    Wrapped<double>? chainId,
    Wrapped<String>? name,
  }) {
    return Contracts$Network(
      chainId: (chainId != null ? chainId.value : this.chainId),
      name: (name != null ? name.value : this.name),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class Contracts$SwapContracts {
  const Contracts$SwapContracts({
    required this.etherSwap,
    required this.eRC20Swap,
  });

  factory Contracts$SwapContracts.fromJson(Map<String, dynamic> json) =>
      _$Contracts$SwapContractsFromJson(json);

  static const toJsonFactory = _$Contracts$SwapContractsToJson;
  Map<String, dynamic> toJson() => _$Contracts$SwapContractsToJson(this);

  @JsonKey(name: 'EtherSwap', includeIfNull: false)
  final String etherSwap;
  @JsonKey(name: 'ERC20Swap', includeIfNull: false)
  final String eRC20Swap;
  static const fromJsonFactory = _$Contracts$SwapContractsFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is Contracts$SwapContracts &&
            (identical(other.etherSwap, etherSwap) ||
                const DeepCollectionEquality().equals(
                  other.etherSwap,
                  etherSwap,
                )) &&
            (identical(other.eRC20Swap, eRC20Swap) ||
                const DeepCollectionEquality().equals(
                  other.eRC20Swap,
                  eRC20Swap,
                )));
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
      eRC20Swap: eRC20Swap ?? this.eRC20Swap,
    );
  }

  Contracts$SwapContracts copyWithWrapped({
    Wrapped<String>? etherSwap,
    Wrapped<String>? eRC20Swap,
  }) {
    return Contracts$SwapContracts(
      etherSwap: (etherSwap != null ? etherSwap.value : this.etherSwap),
      eRC20Swap: (eRC20Swap != null ? eRC20Swap.value : this.eRC20Swap),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ReversePair$Fees$MinerFees {
  const ReversePair$Fees$MinerFees({required this.lockup, required this.claim});

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
      lockup: lockup ?? this.lockup,
      claim: claim ?? this.claim,
    );
  }

  ReversePair$Fees$MinerFees copyWithWrapped({
    Wrapped<double>? lockup,
    Wrapped<double>? claim,
  }) {
    return ReversePair$Fees$MinerFees(
      lockup: (lockup != null ? lockup.value : this.lockup),
      claim: (claim != null ? claim.value : this.claim),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainPair$Fees$MinerFees {
  const ChainPair$Fees$MinerFees({required this.server, required this.user});

  factory ChainPair$Fees$MinerFees.fromJson(Map<String, dynamic> json) =>
      _$ChainPair$Fees$MinerFeesFromJson(json);

  static const toJsonFactory = _$ChainPair$Fees$MinerFeesToJson;
  Map<String, dynamic> toJson() => _$ChainPair$Fees$MinerFeesToJson(this);

  @JsonKey(name: 'server', includeIfNull: false)
  final double server;
  @JsonKey(name: 'user', includeIfNull: false)
  final ChainPair$Fees$MinerFees$User user;
  static const fromJsonFactory = _$ChainPair$Fees$MinerFeesFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainPair$Fees$MinerFees &&
            (identical(other.server, server) ||
                const DeepCollectionEquality().equals(other.server, server)) &&
            (identical(other.user, user) ||
                const DeepCollectionEquality().equals(other.user, user)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(server) ^
      const DeepCollectionEquality().hash(user) ^
      runtimeType.hashCode;
}

extension $ChainPair$Fees$MinerFeesExtension on ChainPair$Fees$MinerFees {
  ChainPair$Fees$MinerFees copyWith({
    double? server,
    ChainPair$Fees$MinerFees$User? user,
  }) {
    return ChainPair$Fees$MinerFees(
      server: server ?? this.server,
      user: user ?? this.user,
    );
  }

  ChainPair$Fees$MinerFees copyWithWrapped({
    Wrapped<double>? server,
    Wrapped<ChainPair$Fees$MinerFees$User>? user,
  }) {
    return ChainPair$Fees$MinerFees(
      server: (server != null ? server.value : this.server),
      user: (user != null ? user.value : this.user),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class ChainPair$Fees$MinerFees$User {
  const ChainPair$Fees$MinerFees$User({
    required this.claim,
    required this.lockup,
  });

  factory ChainPair$Fees$MinerFees$User.fromJson(Map<String, dynamic> json) =>
      _$ChainPair$Fees$MinerFees$UserFromJson(json);

  static const toJsonFactory = _$ChainPair$Fees$MinerFees$UserToJson;
  Map<String, dynamic> toJson() => _$ChainPair$Fees$MinerFees$UserToJson(this);

  @JsonKey(name: 'claim', includeIfNull: false)
  final double claim;
  @JsonKey(name: 'lockup', includeIfNull: false)
  final double lockup;
  static const fromJsonFactory = _$ChainPair$Fees$MinerFees$UserFromJson;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ChainPair$Fees$MinerFees$User &&
            (identical(other.claim, claim) ||
                const DeepCollectionEquality().equals(other.claim, claim)) &&
            (identical(other.lockup, lockup) ||
                const DeepCollectionEquality().equals(other.lockup, lockup)));
  }

  @override
  String toString() => jsonEncode(this);

  @override
  int get hashCode =>
      const DeepCollectionEquality().hash(claim) ^
      const DeepCollectionEquality().hash(lockup) ^
      runtimeType.hashCode;
}

extension $ChainPair$Fees$MinerFees$UserExtension
    on ChainPair$Fees$MinerFees$User {
  ChainPair$Fees$MinerFees$User copyWith({double? claim, double? lockup}) {
    return ChainPair$Fees$MinerFees$User(
      claim: claim ?? this.claim,
      lockup: lockup ?? this.lockup,
    );
  }

  ChainPair$Fees$MinerFees$User copyWithWrapped({
    Wrapped<double>? claim,
    Wrapped<double>? lockup,
  }) {
    return ChainPair$Fees$MinerFees$User(
      claim: (claim != null ? claim.value : this.claim),
      lockup: (lockup != null ? lockup.value : this.lockup),
    );
  }
}

String? rescuableSwapTypeNullableToJson(
  enums.RescuableSwapType? rescuableSwapType,
) {
  return rescuableSwapType?.value;
}

String? rescuableSwapTypeToJson(enums.RescuableSwapType rescuableSwapType) {
  return rescuableSwapType.value;
}

enums.RescuableSwapType rescuableSwapTypeFromJson(
  Object? rescuableSwapType, [
  enums.RescuableSwapType? defaultValue,
]) {
  return enums.RescuableSwapType.values.firstWhereOrNull(
        (e) => e.value == rescuableSwapType,
      ) ??
      defaultValue ??
      enums.RescuableSwapType.swaggerGeneratedUnknown;
}

enums.RescuableSwapType? rescuableSwapTypeNullableFromJson(
  Object? rescuableSwapType, [
  enums.RescuableSwapType? defaultValue,
]) {
  if (rescuableSwapType == null) {
    return null;
  }
  return enums.RescuableSwapType.values.firstWhereOrNull(
        (e) => e.value == rescuableSwapType,
      ) ??
      defaultValue;
}

String rescuableSwapTypeExplodedListToJson(
  List<enums.RescuableSwapType>? rescuableSwapType,
) {
  return rescuableSwapType?.map((e) => e.value!).join(',') ?? '';
}

List<String> rescuableSwapTypeListToJson(
  List<enums.RescuableSwapType>? rescuableSwapType,
) {
  if (rescuableSwapType == null) {
    return [];
  }

  return rescuableSwapType.map((e) => e.value!).toList();
}

List<enums.RescuableSwapType> rescuableSwapTypeListFromJson(
  List? rescuableSwapType, [
  List<enums.RescuableSwapType>? defaultValue,
]) {
  if (rescuableSwapType == null) {
    return defaultValue ?? [];
  }

  return rescuableSwapType
      .map((e) => rescuableSwapTypeFromJson(e.toString()))
      .toList();
}

List<enums.RescuableSwapType>? rescuableSwapTypeNullableListFromJson(
  List? rescuableSwapType, [
  List<enums.RescuableSwapType>? defaultValue,
]) {
  if (rescuableSwapType == null) {
    return defaultValue;
  }

  return rescuableSwapType
      .map((e) => rescuableSwapTypeFromJson(e.toString()))
      .toList();
}

String? restorableSwapTypeNullableToJson(
  enums.RestorableSwapType? restorableSwapType,
) {
  return restorableSwapType?.value;
}

String? restorableSwapTypeToJson(enums.RestorableSwapType restorableSwapType) {
  return restorableSwapType.value;
}

enums.RestorableSwapType restorableSwapTypeFromJson(
  Object? restorableSwapType, [
  enums.RestorableSwapType? defaultValue,
]) {
  return enums.RestorableSwapType.values.firstWhereOrNull(
        (e) => e.value == restorableSwapType,
      ) ??
      defaultValue ??
      enums.RestorableSwapType.swaggerGeneratedUnknown;
}

enums.RestorableSwapType? restorableSwapTypeNullableFromJson(
  Object? restorableSwapType, [
  enums.RestorableSwapType? defaultValue,
]) {
  if (restorableSwapType == null) {
    return null;
  }
  return enums.RestorableSwapType.values.firstWhereOrNull(
        (e) => e.value == restorableSwapType,
      ) ??
      defaultValue;
}

String restorableSwapTypeExplodedListToJson(
  List<enums.RestorableSwapType>? restorableSwapType,
) {
  return restorableSwapType?.map((e) => e.value!).join(',') ?? '';
}

List<String> restorableSwapTypeListToJson(
  List<enums.RestorableSwapType>? restorableSwapType,
) {
  if (restorableSwapType == null) {
    return [];
  }

  return restorableSwapType.map((e) => e.value!).toList();
}

List<enums.RestorableSwapType> restorableSwapTypeListFromJson(
  List? restorableSwapType, [
  List<enums.RestorableSwapType>? defaultValue,
]) {
  if (restorableSwapType == null) {
    return defaultValue ?? [];
  }

  return restorableSwapType
      .map((e) => restorableSwapTypeFromJson(e.toString()))
      .toList();
}

List<enums.RestorableSwapType>? restorableSwapTypeNullableListFromJson(
  List? restorableSwapType, [
  List<enums.RestorableSwapType>? defaultValue,
]) {
  if (restorableSwapType == null) {
    return defaultValue;
  }

  return restorableSwapType
      .map((e) => restorableSwapTypeFromJson(e.toString()))
      .toList();
}

String? swapSwapTypeStatsFromToGetSwapTypeNullableToJson(
  enums.SwapSwapTypeStatsFromToGetSwapType? swapSwapTypeStatsFromToGetSwapType,
) {
  return swapSwapTypeStatsFromToGetSwapType?.value;
}

String? swapSwapTypeStatsFromToGetSwapTypeToJson(
  enums.SwapSwapTypeStatsFromToGetSwapType swapSwapTypeStatsFromToGetSwapType,
) {
  return swapSwapTypeStatsFromToGetSwapType.value;
}

enums.SwapSwapTypeStatsFromToGetSwapType
swapSwapTypeStatsFromToGetSwapTypeFromJson(
  Object? swapSwapTypeStatsFromToGetSwapType, [
  enums.SwapSwapTypeStatsFromToGetSwapType? defaultValue,
]) {
  return enums.SwapSwapTypeStatsFromToGetSwapType.values.firstWhereOrNull(
        (e) => e.value == swapSwapTypeStatsFromToGetSwapType,
      ) ??
      defaultValue ??
      enums.SwapSwapTypeStatsFromToGetSwapType.swaggerGeneratedUnknown;
}

enums.SwapSwapTypeStatsFromToGetSwapType?
swapSwapTypeStatsFromToGetSwapTypeNullableFromJson(
  Object? swapSwapTypeStatsFromToGetSwapType, [
  enums.SwapSwapTypeStatsFromToGetSwapType? defaultValue,
]) {
  if (swapSwapTypeStatsFromToGetSwapType == null) {
    return null;
  }
  return enums.SwapSwapTypeStatsFromToGetSwapType.values.firstWhereOrNull(
        (e) => e.value == swapSwapTypeStatsFromToGetSwapType,
      ) ??
      defaultValue;
}

String swapSwapTypeStatsFromToGetSwapTypeExplodedListToJson(
  List<enums.SwapSwapTypeStatsFromToGetSwapType>?
  swapSwapTypeStatsFromToGetSwapType,
) {
  return swapSwapTypeStatsFromToGetSwapType?.map((e) => e.value!).join(',') ??
      '';
}

List<String> swapSwapTypeStatsFromToGetSwapTypeListToJson(
  List<enums.SwapSwapTypeStatsFromToGetSwapType>?
  swapSwapTypeStatsFromToGetSwapType,
) {
  if (swapSwapTypeStatsFromToGetSwapType == null) {
    return [];
  }

  return swapSwapTypeStatsFromToGetSwapType.map((e) => e.value!).toList();
}

List<enums.SwapSwapTypeStatsFromToGetSwapType>
swapSwapTypeStatsFromToGetSwapTypeListFromJson(
  List? swapSwapTypeStatsFromToGetSwapType, [
  List<enums.SwapSwapTypeStatsFromToGetSwapType>? defaultValue,
]) {
  if (swapSwapTypeStatsFromToGetSwapType == null) {
    return defaultValue ?? [];
  }

  return swapSwapTypeStatsFromToGetSwapType
      .map((e) => swapSwapTypeStatsFromToGetSwapTypeFromJson(e.toString()))
      .toList();
}

List<enums.SwapSwapTypeStatsFromToGetSwapType>?
swapSwapTypeStatsFromToGetSwapTypeNullableListFromJson(
  List? swapSwapTypeStatsFromToGetSwapType, [
  List<enums.SwapSwapTypeStatsFromToGetSwapType>? defaultValue,
]) {
  if (swapSwapTypeStatsFromToGetSwapType == null) {
    return defaultValue;
  }

  return swapSwapTypeStatsFromToGetSwapType
      .map((e) => swapSwapTypeStatsFromToGetSwapTypeFromJson(e.toString()))
      .toList();
}

String? swapSwapTypeStatsFromToGetReferralNullableToJson(
  enums.SwapSwapTypeStatsFromToGetReferral? swapSwapTypeStatsFromToGetReferral,
) {
  return swapSwapTypeStatsFromToGetReferral?.value;
}

String? swapSwapTypeStatsFromToGetReferralToJson(
  enums.SwapSwapTypeStatsFromToGetReferral swapSwapTypeStatsFromToGetReferral,
) {
  return swapSwapTypeStatsFromToGetReferral.value;
}

enums.SwapSwapTypeStatsFromToGetReferral
swapSwapTypeStatsFromToGetReferralFromJson(
  Object? swapSwapTypeStatsFromToGetReferral, [
  enums.SwapSwapTypeStatsFromToGetReferral? defaultValue,
]) {
  return enums.SwapSwapTypeStatsFromToGetReferral.values.firstWhereOrNull(
        (e) => e.value == swapSwapTypeStatsFromToGetReferral,
      ) ??
      defaultValue ??
      enums.SwapSwapTypeStatsFromToGetReferral.swaggerGeneratedUnknown;
}

enums.SwapSwapTypeStatsFromToGetReferral?
swapSwapTypeStatsFromToGetReferralNullableFromJson(
  Object? swapSwapTypeStatsFromToGetReferral, [
  enums.SwapSwapTypeStatsFromToGetReferral? defaultValue,
]) {
  if (swapSwapTypeStatsFromToGetReferral == null) {
    return null;
  }
  return enums.SwapSwapTypeStatsFromToGetReferral.values.firstWhereOrNull(
        (e) => e.value == swapSwapTypeStatsFromToGetReferral,
      ) ??
      defaultValue;
}

String swapSwapTypeStatsFromToGetReferralExplodedListToJson(
  List<enums.SwapSwapTypeStatsFromToGetReferral>?
  swapSwapTypeStatsFromToGetReferral,
) {
  return swapSwapTypeStatsFromToGetReferral?.map((e) => e.value!).join(',') ??
      '';
}

List<String> swapSwapTypeStatsFromToGetReferralListToJson(
  List<enums.SwapSwapTypeStatsFromToGetReferral>?
  swapSwapTypeStatsFromToGetReferral,
) {
  if (swapSwapTypeStatsFromToGetReferral == null) {
    return [];
  }

  return swapSwapTypeStatsFromToGetReferral.map((e) => e.value!).toList();
}

List<enums.SwapSwapTypeStatsFromToGetReferral>
swapSwapTypeStatsFromToGetReferralListFromJson(
  List? swapSwapTypeStatsFromToGetReferral, [
  List<enums.SwapSwapTypeStatsFromToGetReferral>? defaultValue,
]) {
  if (swapSwapTypeStatsFromToGetReferral == null) {
    return defaultValue ?? [];
  }

  return swapSwapTypeStatsFromToGetReferral
      .map((e) => swapSwapTypeStatsFromToGetReferralFromJson(e.toString()))
      .toList();
}

List<enums.SwapSwapTypeStatsFromToGetReferral>?
swapSwapTypeStatsFromToGetReferralNullableListFromJson(
  List? swapSwapTypeStatsFromToGetReferral, [
  List<enums.SwapSwapTypeStatsFromToGetReferral>? defaultValue,
]) {
  if (swapSwapTypeStatsFromToGetReferral == null) {
    return defaultValue;
  }

  return swapSwapTypeStatsFromToGetReferral
      .map((e) => swapSwapTypeStatsFromToGetReferralFromJson(e.toString()))
      .toList();
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
