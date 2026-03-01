// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'rif_relay.swagger.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$RifRelay extends RifRelay {
  _$RifRelay([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = RifRelay;

  @override
  Future<Response<PingResponse>> _chainInfoGet({
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
  }) {
    final Uri $url = Uri.parse('/chain-info');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<PingResponse, PingResponse>($request);
  }

  @override
  Future<Response<dynamic>> _statusGet({
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
  }) {
    final Uri $url = Uri.parse('/status');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<RelayPost$Response>> _relayPost({
    required Object? body,
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
  }) {
    final Uri $url = Uri.parse('/relay');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<RelayPost$Response, RelayPost$Response>($request);
  }

  @override
  Future<Response<EstimatePost$Response>> _estimatePost({
    required Object? body,
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
  }) {
    final Uri $url = Uri.parse('/estimate');
    final $body = body;
    final Request $request = Request(
      'POST',
      $url,
      client.baseUrl,
      body: $body,
      tag: swaggerMetaData,
    );
    return client.send<EstimatePost$Response, EstimatePost$Response>($request);
  }

  @override
  Future<Response<Object>> _tokensGet({
    dynamic verifier,
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
  }) {
    final Uri $url = Uri.parse('/tokens');
    final Map<String, dynamic> $params = <String, dynamic>{
      'verifier': verifier,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<Object>> _contractsGet({
    dynamic verifier,
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
  }) {
    final Uri $url = Uri.parse('/contracts');
    final Map<String, dynamic> $params = <String, dynamic>{
      'verifier': verifier,
    };
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      parameters: $params,
      tag: swaggerMetaData,
    );
    return client.send<Object, Object>($request);
  }

  @override
  Future<Response<VerifiersGet$Response>> _verifiersGet({
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
  }) {
    final Uri $url = Uri.parse('/verifiers');
    final Request $request = Request(
      'GET',
      $url,
      client.baseUrl,
      tag: swaggerMetaData,
    );
    return client.send<VerifiersGet$Response, VerifiersGet$Response>($request);
  }
}
