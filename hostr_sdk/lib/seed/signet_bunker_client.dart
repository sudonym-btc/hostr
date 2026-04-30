import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:hostr_sdk/util/http_client_factory.dart';

class SignetImportedKey {
  final String keyName;
  final String bunkerUri;
  final Map<String, dynamic> raw;

  const SignetImportedKey({
    required this.keyName,
    required this.bunkerUri,
    required this.raw,
  });
}

class SignetBunkerRequest {
  final String id;
  final String? keyName;
  final String method;
  final int? eventKind;
  final Map<String, dynamic> raw;

  const SignetBunkerRequest({
    required this.id,
    required this.keyName,
    required this.method,
    required this.eventKind,
    required this.raw,
  });

  factory SignetBunkerRequest.fromJson(Map<String, dynamic> json) {
    final preview = json['eventPreview'];
    final previewKind = preview is Map<String, dynamic>
        ? preview['kind']
        : null;
    return SignetBunkerRequest(
      id: json['id'].toString(),
      keyName: json['keyName'] as String?,
      method: json['method'] as String? ?? json['eventType'] as String? ?? '',
      eventKind: previewKind is num ? previewKind.toInt() : null,
      raw: json,
    );
  }
}

class SignetBunkerException implements Exception {
  final String message;
  final Uri uri;
  final int? statusCode;

  const SignetBunkerException(
    this.message, {
    required this.uri,
    this.statusCode,
  });

  @override
  String toString() => 'SignetBunkerException: $message';
}

/// Minimal HTTP client for Signet's local bunker admin API.
///
/// The seeder only needs key import, but the client keeps CSRF/cookie handling
/// here so CLI code does not have to know about Signet's browser-facing API.
class SignetBunkerClient {
  SignetBunkerClient({
    required Uri baseUri,
    http.Client? httpClient,
    Duration requestTimeout = const Duration(seconds: 20),
    int maxRateLimitRetries = 6,
    int maxTransientRetries = 6,
  }) : _baseUri = baseUri,
       _requestTimeout = requestTimeout,
       _maxRateLimitRetries = maxRateLimitRetries,
       _maxTransientRetries = maxTransientRetries,
       _client = httpClient ?? createPlatformHttpClient(),
       _ownsClient = httpClient == null {
    _enableBrowserCredentials(_client);
  }

  final Uri _baseUri;
  final Duration _requestTimeout;
  final int _maxRateLimitRetries;
  final int _maxTransientRetries;
  final http.Client _client;
  final bool _ownsClient;
  final Map<String, String> _cookies = <String, String>{};

  String? _csrfToken;

  Future<void> close() async {
    if (_ownsClient) _client.close();
  }

  Future<List<String>> keyNames() async {
    final json = await _jsonRequest('GET', '/keys');
    final keys = json['keys'];
    if (keys is! List) return const <String>[];
    return keys
        .whereType<Map<String, dynamic>>()
        .map((key) => key['name'])
        .whereType<String>()
        .toList(growable: false);
  }

  Future<void> deleteKey(String keyName) async {
    try {
      await revokeAppsForKey(keyName);
      await _jsonRequest(
        'DELETE',
        '/keys/${Uri.encodeComponent(keyName)}',
        csrf: true,
      );
    } on SignetBunkerException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
  }

  Future<void> deleteKeysWithPrefix(String prefix) async {
    for (final keyName in await keyNames()) {
      if (keyName.startsWith(prefix)) {
        await deleteKey(keyName);
      }
    }
  }

  Future<SignetImportedKey> importNsec({
    required String keyName,
    required String nsec,
    bool replaceExisting = true,
  }) async {
    if (replaceExisting) {
      await deleteKey(keyName);
    }

    final json = await _jsonRequest(
      'POST',
      '/keys',
      body: <String, Object?>{
        'keyName': keyName,
        'nsec': nsec,
        'encryption': 'none',
      },
      csrf: true,
    );

    return SignetImportedKey(
      keyName: keyName,
      bunkerUri:
          json['bunkerUri'] as String? ??
          (json['key'] as Map<String, dynamic>?)?['bunkerUri'] as String? ??
          '',
      raw: json,
    );
  }

  Future<Map<String, dynamic>> connectNostrConnect({
    required String uri,
    required String keyName,
    String trustLevel = 'full',
    String description = 'Hostr e2e nostrconnect approval',
  }) async {
    return _jsonRequest(
      'POST',
      '/nostrconnect',
      body: <String, Object?>{
        'uri': uri,
        'keyName': keyName,
        'trustLevel': trustLevel,
        'description': description,
      },
      csrf: true,
    );
  }

  Future<void> revokeApp(int appId) async {
    try {
      await _jsonRequest('POST', '/apps/$appId/revoke', csrf: true);
    } on SignetBunkerException catch (e) {
      if (e.statusCode != 404) rethrow;
    }
  }

  Future<void> revokeAppsForKey(String keyName) async {
    for (final app in await apps()) {
      if (app['keyName'] != keyName) continue;
      final id = app['id'];
      if (id is num) {
        await revokeApp(id.toInt());
      } else if (id is String) {
        final parsed = int.tryParse(id);
        if (parsed != null) await revokeApp(parsed);
      }
    }
  }

  Future<List<Map<String, dynamic>>> apps() async {
    final json = await _jsonRequest('GET', '/apps');
    final apps = json['apps'];
    if (apps is! List) return const <Map<String, dynamic>>[];
    return apps.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<void> updateAppTrustLevelForKey(
    String keyName,
    String trustLevel,
  ) async {
    final app = (await apps()).where((app) => app['keyName'] == keyName).first;
    await _jsonRequest(
      'PATCH',
      '/apps/${app['id']}',
      body: <String, Object?>{'trustLevel': trustLevel},
      csrf: true,
    );
  }

  Future<List<SignetBunkerRequest>> requests({
    String status = 'pending',
  }) async {
    final json = await _jsonRequest(
      'GET',
      '/requests?status=$status&limit=100',
    );
    final requests = json['requests'];
    if (requests is! List) return const <SignetBunkerRequest>[];
    return requests
        .whereType<Map<String, dynamic>>()
        .map(SignetBunkerRequest.fromJson)
        .toList(growable: false);
  }

  Future<SignetBunkerRequest> waitForPendingRequest({
    required String keyName,
    String? method,
    int? eventKind,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      SignetBunkerRequest? match;
      for (final request in await requests()) {
        if (request.keyName != keyName) continue;
        if (method != null && request.method != method) continue;
        if (eventKind != null && request.eventKind != eventKind) continue;
        match = request;
        break;
      }
      if (match != null) return match;

      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    throw TimeoutException(
      'Timed out waiting for Signet request '
      'keyName=$keyName method=$method eventKind=$eventKind',
      timeout,
    );
  }

  Future<void> approve(
    SignetBunkerRequest request, {
    String trustLevel = 'paranoid',
    bool alwaysAllow = false,
    int? allowKind,
    String appName = 'Hostr',
  }) async {
    await _jsonRequest(
      'POST',
      '/requests/${Uri.encodeComponent(request.id)}',
      body: <String, Object?>{
        'trustLevel': trustLevel,
        'alwaysAllow': alwaysAllow,
        'allowKind': ?allowKind,
        'appName': appName,
      },
      csrf: true,
    );
  }

  Future<void> approveBatch(
    List<SignetBunkerRequest> requests, {
    String trustLevel = 'full',
    bool alwaysAllow = true,
  }) async {
    if (requests.isEmpty) return;
    await _jsonRequest(
      'POST',
      '/requests/batch',
      body: <String, Object?>{
        'ids': requests.map((request) => request.id).toList(),
        'trustLevel': trustLevel,
        'alwaysAllow': alwaysAllow,
      },
      csrf: true,
    );
  }

  Future<void> approveNext({
    required String keyName,
    String? method,
    int? eventKind,
    String trustLevel = 'paranoid',
    bool alwaysAllow = false,
    int? allowKind,
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final request = await waitForPendingRequest(
      keyName: keyName,
      method: method,
      eventKind: eventKind,
      timeout: timeout,
    );
    await approve(
      request,
      trustLevel: trustLevel,
      alwaysAllow: alwaysAllow,
      allowKind: allowKind,
    );
  }

  Future<void> deny(SignetBunkerRequest request) async {
    await _jsonRequest(
      'DELETE',
      '/requests/${Uri.encodeComponent(request.id)}',
      csrf: true,
    );
  }

  Future<void> lockKey(String keyName) async {
    await _jsonRequest(
      'POST',
      '/keys/${Uri.encodeComponent(keyName)}/lock',
      csrf: true,
    );
  }

  Future<Map<String, dynamic>> _jsonRequest(
    String method,
    String path, {
    Map<String, Object?>? body,
    bool csrf = false,
  }) async {
    if (csrf) await _ensureCsrfToken();

    for (var attempt = 0; ; attempt++) {
      http.Response response;
      try {
        response = await _sendJsonRequest(method, path, body: body, csrf: csrf);
      } on TimeoutException catch (_) {
        if (attempt < _maxTransientRetries) {
          await Future<void>.delayed(_transientBackoff(attempt));
          continue;
        }
        rethrow;
      } on http.ClientException catch (_) {
        if (attempt < _maxTransientRetries) {
          await Future<void>.delayed(_transientBackoff(attempt));
          continue;
        }
        rethrow;
      } on SocketException catch (_) {
        if (attempt < _maxTransientRetries) {
          await Future<void>.delayed(_transientBackoff(attempt));
          continue;
        }
        rethrow;
      }
      _captureCookies(response);
      if (csrf &&
          response.statusCode == 403 &&
          response.body.toLowerCase().contains('csrf')) {
        _csrfToken = null;
        await _ensureCsrfToken();
        response = await _sendJsonRequest(method, path, body: body, csrf: csrf);
        _captureCookies(response);
      }

      if (response.statusCode == 429 && attempt < _maxRateLimitRetries) {
        await Future<void>.delayed(_retryAfter(response));
        continue;
      }

      if (_isTransientStatus(response.statusCode) &&
          attempt < _maxTransientRetries) {
        await Future<void>.delayed(_transientBackoff(attempt));
        continue;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw SignetBunkerException(
          '$method $path failed with ${response.statusCode}: ${response.body}',
          uri: _baseUri.resolve(path),
          statusCode: response.statusCode,
        );
      }
      if (response.body.trim().isEmpty) return <String, dynamic>{};

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return <String, dynamic>{'value': decoded};
    }
  }

  Future<http.Response> _sendJsonRequest(
    String method,
    String path, {
    Map<String, Object?>? body,
    required bool csrf,
  }) async {
    final request = http.Request(method, _baseUri.resolve(path));
    request.headers['accept'] = 'application/json';
    if (body != null) request.headers['content-type'] = 'application/json';
    if (_cookies.isNotEmpty) {
      request.headers['cookie'] = _cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
    }
    if (csrf && _csrfToken != null) {
      request.headers['x-csrf-token'] = _csrfToken!;
    }
    if (body != null) request.body = jsonEncode(body);

    return http.Response.fromStream(
      await _client.send(request).timeout(_requestTimeout),
    );
  }

  Future<void> _ensureCsrfToken() async {
    if (_csrfToken != null) return;

    final response = await http.Response.fromStream(
      await _client
          .send(
            http.Request('GET', _baseUri.resolve('/csrf-token'))
              ..headers['accept'] = 'application/json',
          )
          .timeout(_requestTimeout),
    );
    _captureCookies(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SignetBunkerException(
        'GET /csrf-token failed with ${response.statusCode}: ${response.body}',
        uri: _baseUri.resolve('/csrf-token'),
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    _csrfToken = decoded['csrfToken'] as String? ?? decoded['token'] as String?;
  }

  void _captureCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) return;

    for (final part in setCookie.split(RegExp(r', (?=[^;,]+=)'))) {
      final cookie = part.split(';').first;
      final separator = cookie.indexOf('=');
      if (separator <= 0) continue;
      _cookies[cookie.substring(0, separator)] = cookie.substring(
        separator + 1,
      );
    }
  }

  Duration _retryAfter(http.Response response) {
    final retryAfterHeader = response.headers['retry-after'];
    if (retryAfterHeader != null) {
      final seconds = int.tryParse(retryAfterHeader.trim());
      if (seconds != null && seconds > 0) {
        return Duration(seconds: seconds);
      }
    }
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['retryAfter'] is num) {
        return Duration(seconds: (decoded['retryAfter'] as num).ceil());
      }
    } catch (_) {}
    return const Duration(seconds: 5);
  }

  bool _isTransientStatus(int statusCode) =>
      statusCode == 408 ||
      statusCode == 425 ||
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504;

  Duration _transientBackoff(int attempt) {
    final milliseconds = 250 * (attempt + 1);
    return Duration(milliseconds: milliseconds.clamp(250, 2000));
  }
}

void _enableBrowserCredentials(http.Client client) {
  try {
    (client as dynamic).withCredentials = true;
  } catch (_) {}
}
