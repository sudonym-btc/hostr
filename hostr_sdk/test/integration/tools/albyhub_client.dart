export 'albyhub_client_fixed.dart';

/*

class AlbyHubClient {
  final Uri baseUri;
  final String unlockPassword;
  final HttpClient _httpClient;
  String? _lastAuthToken;
  final Map<String, Cookie> _cookieJar = <String, Cookie>{};
  String? _lastAuthToken;
  AlbyHubClient({
    required this.baseUri,
    required this.unlockPassword,
    HttpClient? httpClient,
  }) : _httpClient =
           httpClient ??
           (HttpClient()
             ..badCertificateCallback =
                 (X509Certificate _, String __, int ___) => true);

  Future<void> setup() async {
    final response = await _request(
      method: 'POST',
      path: '/api/setup',
      body: {'unlockPassword': unlockPassword},
      throwOnHttpError: false,
    );
      final Map<String, Cookie> _cookieJar = <String, Cookie>{};

    final error = response.map['error']?.toString();
    if (error != null &&
        error.isNotEmpty &&
        !error.contains('already set up')) {
      throw StateError('Failed to setup AlbyHub: $error');
    }
  }

  Future<void> start() async {
    final response = await _request(
      method: 'POST',
      path: '/api/start',
      body: {'unlockPassword': unlockPassword},
      throwOnHttpError: false,
    );

    _lastAuthToken = _extractToken(response.map) ?? _lastAuthToken;

    final error = response.map['error']?.toString();
    if (error != null &&
        error.isNotEmpty &&
        !error.contains('already started')) {
      throw StateError('Failed to start AlbyHub: $error');
    }
  }

  Future<String> unlock({String permission = 'full'}) async {
    final response = await _request(
      method: 'POST',
      path: '/api/unlock',
      body: {'permission': permission, 'unlockPassword': unlockPassword},
      throwOnHttpError: false,
    );

    final token = _extractToken(response.map);
    if (token != null && token.isNotEmpty) {
      _lastAuthToken = token;
      return token;
    }

    final error = response.map['error']?.toString();
    if (error != null && error.isNotEmpty) {
      throw StateError('Failed to unlock AlbyHub: $error');
    }

    final message = response.map['message']?.toString().toLowerCase() ?? '';
    if (message.contains('already unlocked')) {
      if (_lastAuthToken != null && _lastAuthToken!.isNotEmpty) {
        return _lastAuthToken!;
      }

      // Retry start, some versions only emit token there.
        final token = _extractToken(response.map) ?? _extractTokenFromCookies(response);
        method: 'POST',
        path: '/api/start',
        body: {'unlockPassword': unlockPassword},
        throwOnHttpError: false,
      );
      final startToken = _extractToken(startResponse.map);
      if (startToken != null && startToken.isNotEmpty) {
        _lastAuthToken = startToken;
        return startToken;
      }

      // Retry unlock once in case state changed between calls.
      final retryResponse = await _request(
        method: 'POST',
        path: '/api/unlock',
        body: {'permission': permission, 'unlockPassword': unlockPassword},
        throwOnHttpError: false,
      );
      final retryToken = _extractToken(retryResponse.map);
      if (retryToken != null && retryToken.isNotEmpty) {
        _lastAuthToken = retryToken;
        return retryToken;
      }
          final startToken =
              _extractToken(startResponse.map) ??
              _extractTokenFromCookies(startResponse);

    throw StateError('Unlock succeeded but no token was returned.');
  }

  Future<CreateAppResponse> createApp({
    required String token,
    required String appName,
    required String userPubkey,
    int maxAmount = 0,
    String budgetRenewal = 'yearly',
    List<String> scopes = const [
      'pay_invoice',
          final retryToken =
              _extractToken(retryResponse.map) ??
              _extractTokenFromCookies(retryResponse);
      'get_balance',
      'make_invoice',
      'lookup_invoice',
      'list_transactions',
      'notifications',
    ],
        return _lastAuthToken ?? '';
    Map<String, dynamic> metadata = const {},
    String returnTo = '',
    Map<String, dynamic> otherSettings = const {},
        String? token,
    final payload = <String, dynamic>{
      'name': appName,
      'pubkey': userPubkey,
      'budgetRenewal': budgetRenewal,
      'maxAmount': maxAmount,
      'metadata': metadata,
      'returnTo': returnTo,
      'scopes': scopes,
      'isolated': isolated,
      'unlockPassword': unlockPassword,
      ...otherSettings,
    };

    final response = await _request(
      method: 'POST',
      path: '/api/apps',
      body: payload,
      bearerToken: token,
    );

    return CreateAppResponse.fromJson(response.map);
  }

  Future<String?> getConnectionForUser(
    KeyPair keyPair, {
    String appName = 'test',
    int limit = 0,
    String budgetRenewal = 'yearly',
    List<String>? scopes,
    Map<String, dynamic> otherSettings = const {},
  }) {
    return getConnectionForPubkey(
      keyPair.publicKey,
      appName: appName,
      limit: limit,
          bearerToken: token,
      scopes: scopes,
      otherSettings: otherSettings,
    );
  }

  Future<String?> getConnectionForPubkey(
    String userPubkey, {
    String appName = 'test',
    int limit = 0,
    String budgetRenewal = 'yearly',
    List<String>? scopes,
    Map<String, dynamic> otherSettings = const {},
  }) async {
    await setup();
    await start();
    final token = await unlock();

    final appResponse = await createApp(
      token: token,
      appName: appName,
      userPubkey: userPubkey,
      maxAmount: limit,
      budgetRenewal: budgetRenewal,
      scopes:
          scopes ??
          const [
            'pay_invoice',
            'get_info',
            'get_balance',
            'make_invoice',
            'lookup_invoice',
            'list_transactions',
            'notifications',
          ],
      otherSettings: otherSettings,
        var appResponse = await createApp(
          token: token.isEmpty ? null : token,
    return appResponse.pairingUri;
  }

  Future<HealthResponse> health() async {
    final response = await _request(method: 'GET', path: '/api/health');
    return HealthResponse.fromJson(response.map);
  }

  Future<SwapInfoResponse> getSwapInInfo({required String token}) async {
    final response = await _request(
      method: 'GET',
      path: '/api/swaps/in/info',
      bearerToken: token,
    );
    return SwapInfoResponse.fromJson(response.map);
  }


        if ((appResponse.pairingUri == null || appResponse.pairingUri!.isEmpty) &&
            _looksLikeAuthError(appResponse)) {
          final retryToken = await unlock();
          appResponse = await createApp(
            token: retryToken.isEmpty ? null : retryToken,
            appName: appName,
            userPubkey: userPubkey,
            maxAmount: limit,
            budgetRenewal: budgetRenewal,
            scopes:
                scopes ??
                const [
                  'pay_invoice',
                  'get_info',
                  'get_balance',
                  'make_invoice',
                  'lookup_invoice',
                  'list_transactions',
                  'notifications',
                ],
            otherSettings: otherSettings,
          );
        }
  Future<SwapResponse> initiateSwapIn({
    required String token,
    required int swapAmount,
  }) async {
    final response = await _request(
      method: 'POST',
      path: '/api/swaps/in',
      body: {'swapAmount': swapAmount, 'destination': ''},
      bearerToken: token,
    );
    return SwapResponse.fromJson(response.map);
  }

  Future<ListSwapsResponse> listSwaps({required String token}) async {
    final response = await _request(
      method: 'GET',
      path: '/api/swaps',
      bearerToken: token,
    );

    final swaps = (response.map['swaps'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => SwapResponse.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ListSwapsResponse(swaps: swaps);
  }

  Future<SwapResponse> lookupSwap({
    required String token,
    required String swapId,
  }) async {
    final response = await _request(
      method: 'GET',
      path: '/api/swaps/$swapId',
      bearerToken: token,
    );
    return SwapResponse.fromJson(response.map);
  }

  Future<_HttpResponseJson> _request({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? bearerToken,
    bool throwOnHttpError = true,
  }) async {
    final request = switch (method) {
      'GET' => await _httpClient.getUrl(baseUri.resolve(path)),
      'POST' => await _httpClient.postUrl(baseUri.resolve(path)),
      _ => throw UnsupportedError('Unsupported method: $method'),
    };

    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (body != null) {
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.write(jsonEncode(body));
    }
    if (bearerToken != null && bearerToken.isNotEmpty) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $bearerToken',
      );
    }

    final response = await request.close();
    final responseBody = await utf8.decodeStream(response);

    for (final cookie in response.cookies) {
      _cookieJar[cookie.name] = cookie;
    }

    Map<String, dynamic> decodedMap = <String, dynamic>{};
    if (responseBody.trim().isNotEmpty) {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        decodedMap = decoded;
      }
    }

        if (_cookieJar.isNotEmpty) {
          request.cookies.addAll(_cookieJar.values);
        }
    if (throwOnHttpError && response.statusCode >= 400) {
      final message =
          decodedMap['message']?.toString() ??
          decodedMap['error']?.toString() ??
          'HTTP ${response.statusCode}';
      throw StateError('AlbyHub request failed: $message');
    }

    return _HttpResponseJson(statusCode: response.statusCode, map: decodedMap);
  }

  void close() {
    _httpClient.close(force: true);
  }

  String? _extractToken(Map<String, dynamic> map) {
    final candidates = [map['token'], map['accessToken'], map['jwt']];

    for (final candidate in candidates) {
      final value = candidate?.toString();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }
        return _HttpResponseJson(
          statusCode: response.statusCode,
          map: decodedMap,
          cookies: response.cookies,
        );

class CreateAppResponse {
  final String? pairingUri;
  final String? error;
  final String? message;

  const CreateAppResponse({this.pairingUri, this.error, this.message});
        final candidates = [
          map['token'],
          map['accessToken'],
          map['access_token'],
          map['jwt'],
          map['bearer'],
          (map['data'] is Map ? (map['data'] as Map)['token'] : null),
          (map['data'] is Map ? (map['data'] as Map)['accessToken'] : null),
          (map['data'] is Map ? (map['data'] as Map)['access_token'] : null),
        ];
  factory CreateAppResponse.fromJson(Map<String, dynamic> json) {
    return CreateAppResponse(
      pairingUri: json['pairingUri']?.toString(),
      error: json['error']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

class HealthResponse {

      String? _extractTokenFromCookies(_HttpResponseJson response) {
        final cookie = response.cookies.firstWhere(
          (c) =>
              c.name.toLowerCase() == 'token' ||
              c.name.toLowerCase() == 'access_token' ||
              c.name.toLowerCase() == 'jwt',
          orElse: () => Cookie('', ''),
        );

        if (cookie.name.isEmpty || cookie.value.isEmpty) {
          return null;
        }

        return cookie.value;
      }

      bool _looksLikeAuthError(CreateAppResponse response) {
        final error = (response.error ?? '').toLowerCase();
        final message = (response.message ?? '').toLowerCase();
        return error.contains('unauthorized') ||
            error.contains('token') ||
            error.contains('forbidden') ||
            message.contains('unauthorized') ||
            message.contains('token') ||
            message.contains('forbidden');
      }
  final List<dynamic> alarms;

  const HealthResponse({required this.alarms});

  factory HealthResponse.fromJson(Map<String, dynamic> json) {
      final List<Cookie> cookies;
    return HealthResponse(alarms: (json['alarms'] as List?) ?? const []);
      const _HttpResponseJson({
        required this.statusCode,
        required this.map,
        required this.cookies,
      });
}

class SwapInfoResponse {
  final double albyServiceFee;
  final double boltzServiceFee;
  final int boltzNetworkFee;
  final int minAmount;
  final int maxAmount;

  const SwapInfoResponse({
    required this.albyServiceFee,
    required this.boltzServiceFee,
    required this.boltzNetworkFee,
    required this.minAmount,
    required this.maxAmount,
  });

  factory SwapInfoResponse.fromJson(Map<String, dynamic> json) {
    return SwapInfoResponse(
      albyServiceFee: (json['albyServiceFee'] as num?)?.toDouble() ?? 0,
      boltzServiceFee: (json['boltzServiceFee'] as num?)?.toDouble() ?? 0,
      boltzNetworkFee: (json['boltzNetworkFee'] as num?)?.toInt() ?? 0,
      minAmount: (json['minAmount'] as num?)?.toInt() ?? 0,
      maxAmount: (json['maxAmount'] as num?)?.toInt() ?? 0,
    );
  }
}

class SwapResponse {
  final String id;
  final String state;
  final String? invoice;
  final int? sendAmount;
  final int? receiveAmount;

  const SwapResponse({
    required this.id,
    required this.state,
    this.invoice,
    this.sendAmount,
    this.receiveAmount,
  });

  factory SwapResponse.fromJson(Map<String, dynamic> json) {
    return SwapResponse(
      id: json['id']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      invoice: json['invoice']?.toString(),
      sendAmount: (json['sendAmount'] as num?)?.toInt(),
      receiveAmount: (json['receiveAmount'] as num?)?.toInt(),
    );
  }
}

class ListSwapsResponse {
  final List<SwapResponse> swaps;

  const ListSwapsResponse({required this.swaps});
}

class _HttpResponseJson {
  final int statusCode;
  final Map<String, dynamic> map;

  const _HttpResponseJson({required this.statusCode, required this.map});
}

*/
