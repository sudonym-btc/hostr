import 'dart:convert';
import 'dart:io';

import 'package:chopper/chopper.dart' as chopper;
import 'package:hostr_sdk/datasources/swagger_generated/lnbits.swagger.dart';

class LnbitsSetupConfig {
  final String lnbits1BaseUrl;
  final String lnbits2BaseUrl;
  final String lnbitsAdminEmail;
  final String lnbitsAdminPassword;
  final String lnbitsExtensionName;
  final String? lnbitsNostrPrivateKey;

  const LnbitsSetupConfig({
    required this.lnbits1BaseUrl,
    required this.lnbits2BaseUrl,
    required this.lnbitsAdminEmail,
    required this.lnbitsAdminPassword,
    required this.lnbitsExtensionName,
    this.lnbitsNostrPrivateKey,
  });

  factory LnbitsSetupConfig.fromEnvironment({
    String? lnbits1BaseUrl,
    String? lnbits2BaseUrl,
    String? lnbitsAdminEmail,
    String? lnbitsAdminPassword,
    String? lnbitsExtensionName,
    String? lnbitsNostrPrivateKey,
  }) {
    final env = Platform.environment;
    final host = (env['LNBITS_HOST'] ?? 'localhost').trim();

    return LnbitsSetupConfig(
      lnbits1BaseUrl:
          lnbits1BaseUrl ?? 'http://$host:${env['LNBITS_1_PORT'] ?? '5055'}',
      lnbits2BaseUrl:
          lnbits2BaseUrl ?? 'http://$host:${env['LNBITS_2_PORT'] ?? '5056'}',
      lnbitsAdminEmail:
          lnbitsAdminEmail ?? env['LNBITS_ADMIN_EMAIL'] ?? 'admin@example.com',
      lnbitsAdminPassword:
          lnbitsAdminPassword ??
          env['LNBITS_ADMIN_PASSWORD'] ??
          'adminpassword',
      lnbitsExtensionName:
          lnbitsExtensionName ?? env['LNBITS_EXTENSION_NAME'] ?? 'lnurlp',
      lnbitsNostrPrivateKey:
          lnbitsNostrPrivateKey ?? env['LNBITS_NOSTR_PRIVATE_KEY'],
    );
  }
}

class LnbitsDatasource {
  Future<void> setupUsernamesByDomain({
    required Map<String, Set<String>> usernamesByDomain,
    required LnbitsSetupConfig config,
  }) async {
    if (usernamesByDomain.isEmpty) {
      return;
    }

    final servers = _resolveLnbitsServerConfigs(config);
    for (final entry in usernamesByDomain.entries) {
      final domain = entry.key;
      final server = servers[domain];
      if (server == null) {
        print('No LNbits server mapping for domain "$domain". Skipping.');
        continue;
      }

      await _setupLnbitsServer(cfg: server, usernames: entry.value.toList());
    }
  }

  Map<String, _LnbitsServerConfig> _resolveLnbitsServerConfigs(
    LnbitsSetupConfig config,
  ) {
    return {
      'lnbits1.hostr.development': _LnbitsServerConfig(
        baseUrl: config.lnbits1BaseUrl,
        adminEmail: config.lnbitsAdminEmail,
        adminPassword: config.lnbitsAdminPassword,
        extensionName: config.lnbitsExtensionName,
        nostrPrivateKey: config.lnbitsNostrPrivateKey,
      ),
      'lnbits2.hostr.development': _LnbitsServerConfig(
        baseUrl: config.lnbits2BaseUrl,
        adminEmail: config.lnbitsAdminEmail,
        adminPassword: config.lnbitsAdminPassword,
        extensionName: config.lnbitsExtensionName,
        nostrPrivateKey: config.lnbitsNostrPrivateKey,
      ),
    };
  }

  Future<void> _setupLnbitsServer({
    required _LnbitsServerConfig cfg,
    required List<String> usernames,
  }) async {
    if (usernames.isEmpty) {
      return;
    }

    print(
      'Setting up LNbits on ${cfg.baseUrl} for ${usernames.length} users...',
    );

    final unauth = _createLnbitsClient(baseUrl: cfg.baseUrl);
    try {
      await unauth.apiV1AuthFirstInstallPut(
        body: UpdateSuperuserPassword(
          username: cfg.adminEmail,
          password: cfg.adminPassword,
          passwordRepeat: cfg.adminPassword,
        ),
      );

      final loginResponse = await unauth.apiV1AuthPost(
        body: LoginUsernamePassword(
          username: cfg.adminEmail,
          password: cfg.adminPassword,
        ),
      );

      final token = _extractAccessToken(loginResponse.body);
      if (token == null || token.isEmpty) {
        throw Exception(
          'Failed to retrieve LNbits access token from ${cfg.baseUrl}: ${loginResponse.body}',
        );
      }

      final authed = _createLnbitsClient(
        baseUrl: cfg.baseUrl,
        bearerToken: token,
      );
      try {
        await _ensureExtensionEnabled(authed, cfg.extensionName);

        final walletsResponse = await authed.apiV1WalletsGet();
        final wallets = walletsResponse.body;
        if (wallets == null || wallets.isEmpty) {
          throw Exception(
            'No LNbits wallets found at ${cfg.baseUrl} for admin user ${cfg.adminEmail}.',
          );
        }

        final wallet = wallets.first;

        if (cfg.nostrPrivateKey != null && cfg.nostrPrivateKey!.isNotEmpty) {
          await _configureLnurlpNostrKey(
            baseUrl: cfg.baseUrl,
            bearerToken: token,
            nostrPrivateKey: cfg.nostrPrivateKey!,
          );
        }

        final sorted = usernames.toSet().toList()..sort();
        for (final username in sorted) {
          await _ensureLnurlpLink(
            baseUrl: cfg.baseUrl,
            bearerToken: token,
            walletApiKey: wallet.adminkey,
            walletId: wallet.id,
            username: username,
            description: 'seed profile $username',
          );
        }

        await _ensureLnurlpLink(
          baseUrl: cfg.baseUrl,
          bearerToken: token,
          walletApiKey: wallet.adminkey,
          walletId: wallet.id,
          username: 'tips',
          description: 'tips',
        );
      } finally {
        authed.client.dispose();
      }
    } finally {
      unauth.client.dispose();
    }
  }

  Lnbits _createLnbitsClient({required String baseUrl, String? bearerToken}) {
    final interceptors = <chopper.Interceptor>[];
    if (bearerToken != null && bearerToken.isNotEmpty) {
      interceptors.add(
        chopper.HeadersInterceptor({'Authorization': 'Bearer $bearerToken'}),
      );
    }

    return Lnbits.create(
      baseUrl: Uri.parse(baseUrl),
      interceptors: interceptors,
    );
  }

  Future<void> _ensureExtensionEnabled(Lnbits api, String extensionName) async {
    final installResponse = await api.apiV1ExtensionPost(
      body: CreateExtension(
        extId: extensionName,
        archive:
            'https://github.com/lnbits/lnurlp/archive/refs/tags/v1.3.0.zip',
        sourceRepo:
            'https://raw.githubusercontent.com/lnbits/lnbits-extensions/main/extensions.json',
        version: '1.3.0',
      ),
    );

    if (!installResponse.isSuccessful) {
      final detail = _extractDetail(installResponse.body);
      final already = detail?.toLowerCase().contains('already') ?? false;
      if (!already) {
        throw Exception(
          'LNbits extension install failed: ${installResponse.body}',
        );
      }
    }

    final enableResponse = await api.apiV1ExtensionExtIdEnablePut(
      extId: extensionName,
    );
    if (!enableResponse.isSuccessful) {
      final detail = _extractDetail(enableResponse.body);
      final already = detail?.toLowerCase().contains('already') ?? false;
      if (!already) {
        throw Exception(
          'LNbits extension enable failed: ${enableResponse.body}',
        );
      }
    }
  }

  Future<void> _configureLnurlpNostrKey({
    required String baseUrl,
    required String bearerToken,
    required String nostrPrivateKey,
  }) async {
    final settingsUri = Uri.parse('$baseUrl/lnurlp/api/v1/settings');
    final settings = await _jsonRequest(
      method: 'GET',
      uri: settingsUri,
      headers: {'Authorization': 'Bearer $bearerToken'},
    );

    settings['nostr_private_key'] = nostrPrivateKey;

    await _jsonRequest(
      method: 'PUT',
      uri: settingsUri,
      headers: {'Authorization': 'Bearer $bearerToken'},
      body: settings,
    );
  }

  Future<void> _ensureLnurlpLink({
    required String baseUrl,
    required String bearerToken,
    required String walletApiKey,
    required String walletId,
    required String username,
    required String description,
  }) async {
    final response = await _jsonRequest(
      method: 'POST',
      uri: Uri.parse('$baseUrl/lnurlp/api/v1/links'),
      headers: {
        'Authorization': 'Bearer $bearerToken',
        'X-Api-Key': walletApiKey,
      },
      body: {
        'comment_chars': 0,
        'description': description,
        'max': 10000000,
        'min': 1,
        'username': username,
        'wallet': walletId,
        'zaps': true,
      },
    );

    final detail = response['detail']?.toString();
    if (detail != null && detail.isNotEmpty) {
      if (detail.toLowerCase().contains('username already taken')) {
        return;
      }
      throw Exception('Failed creating lnurlp link for $username: $response');
    }
  }

  Future<Map<String, dynamic>> _jsonRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final client = HttpClient();
    try {
      final request = await client.openUrl(method, uri);
      request.headers.contentType = ContentType.json;

      if (headers != null) {
        headers.forEach((key, value) {
          request.headers.set(key, value);
        });
      }

      if (body != null) {
        request.write(jsonEncode(body));
      }

      final response = await request.close();
      final raw = await utf8.decodeStream(response);
      final decoded = raw.isEmpty ? <String, dynamic>{} : jsonDecode(raw);
      final map = decoded is Map<String, dynamic>
          ? decoded
          : Map<String, dynamic>.from(decoded as Map);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'HTTP ${response.statusCode} for ${uri.path}: $map',
          uri: uri,
        );
      }

      return map;
    } finally {
      client.close(force: true);
    }
  }

  String? _extractAccessToken(dynamic body) {
    final map = _asJsonMap(body);
    return map['access_token']?.toString();
  }

  String? _extractDetail(dynamic body) {
    final map = _asJsonMap(body);
    return map['detail']?.toString();
  }

  Map<String, dynamic> _asJsonMap(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body;
    }
    if (body is Map) {
      return Map<String, dynamic>.from(body);
    }
    if (body is String && body.isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return {'detail': body};
      }
    }
    return <String, dynamic>{};
  }
}

class _LnbitsServerConfig {
  final String baseUrl;
  final String adminEmail;
  final String adminPassword;
  final String extensionName;
  final String? nostrPrivateKey;

  const _LnbitsServerConfig({
    required this.baseUrl,
    required this.adminEmail,
    required this.adminPassword,
    required this.extensionName,
    this.nostrPrivateKey,
  });
}
