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
  Future<void> setupServer({
    required String baseUrl,
    required String adminEmail,
    required String adminPassword,
    required String extensionName,
    String? nostrPrivateKey,
    List<String> usernames = const [],
    bool ensureTipsLink = false,
  }) async {
    await _setupLnbitsServer(
      cfg: _LnbitsServerConfig(
        baseUrl: baseUrl,
        adminEmail: adminEmail,
        adminPassword: adminPassword,
        extensionName: extensionName,
        nostrPrivateKey: nostrPrivateKey,
      ),
      usernames: usernames,
      ensureTipsLink: ensureTipsLink,
    );
  }

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

  /// Sets up NIP-05 entries on LNbits via the nostrnip5 extension.
  ///
  /// [nip05ByDomain] maps each domain to a map of {local_part → hex pubkey}.
  /// Returns a map of {domain → nostrnip5 domain ID} for domains that were
  /// successfully created.
  Future<Map<String, String>> setupNip05ByDomain({
    required Map<String, Map<String, String>> nip05ByDomain,
    required LnbitsSetupConfig config,
  }) async {
    if (nip05ByDomain.isEmpty) {
      return {};
    }

    final domainIds = <String, String>{};
    final servers = _resolveLnbitsServerConfigs(config);
    for (final entry in nip05ByDomain.entries) {
      final domain = entry.key;
      final server = servers[domain];
      if (server == null) {
        print(
          'No LNbits server mapping for domain "$domain". Skipping NIP-05.',
        );
        continue;
      }

      final domainId = await _setupNostrnip5(
        cfg: server,
        domain: domain,
        entries: entry.value,
      );
      if (domainId != null) {
        domainIds[domain] = domainId;
      }
    }
    return domainIds;
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
    bool ensureTipsLink = true,
  }) async {
    print('Setting up LNbits on ${cfg.baseUrl}...');

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
        await _ensureExtensionEnabled(
          authed,
          cfg.extensionName,
          archive:
              'https://github.com/lnbits/${cfg.extensionName}/archive/refs/tags/v1.3.0.zip',
          version: '1.3.0',
        );
        await _ensureExtensionEnabled(
          authed,
          'nostrnip5',
          archive:
              'https://github.com/lnbits/nostrnip5/archive/refs/tags/v1.0.4.zip',
          version: '1.0.4',
        );

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

        if (ensureTipsLink) {
          await _ensureLnurlpLink(
            baseUrl: cfg.baseUrl,
            bearerToken: token,
            walletApiKey: wallet.adminkey,
            walletId: wallet.id,
            username: 'tips',
            description: 'tips',
          );
        }
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

  Future<void> _ensureExtensionEnabled(
    Lnbits api,
    String extensionName, {
    required String archive,
    required String version,
  }) async {
    final installResponse = await api.apiV1ExtensionPost(
      body: CreateExtension(
        extId: extensionName,
        archive: archive,
        sourceRepo:
            'https://raw.githubusercontent.com/lnbits/lnbits-extensions/main/extensions.json',
        version: version,
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
    try {
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
        throw Exception('Failed creating lnurlp link for $username: $response');
      }
    } on HttpException catch (e) {
      if (e.message.contains('Username already taken')) {
        return;
      }
      rethrow;
    }
  }

  Future<String?> _setupNostrnip5({
    required _LnbitsServerConfig cfg,
    required String domain,
    required Map<String, String> entries, // local_part → hex pubkey
  }) async {
    print('Setting up nostrnip5 on ${cfg.baseUrl} for domain $domain...');

    final unauth = _createLnbitsClient(baseUrl: cfg.baseUrl);
    try {
      final loginResponse = await unauth.apiV1AuthPost(
        body: LoginUsernamePassword(
          username: cfg.adminEmail,
          password: cfg.adminPassword,
        ),
      );

      final token = _extractAccessToken(loginResponse.body);
      if (token == null || token.isEmpty) {
        throw Exception(
          'Failed to retrieve LNbits access token from ${cfg.baseUrl}',
        );
      }

      final authed = _createLnbitsClient(
        baseUrl: cfg.baseUrl,
        bearerToken: token,
      );
      try {
        await _ensureExtensionEnabled(
          authed,
          'nostrnip5',
          archive:
              'https://github.com/lnbits/nostrnip5/archive/refs/tags/v1.0.4.zip',
          version: '1.0.4',
        );

        final walletsResponse = await authed.apiV1WalletsGet();
        final wallets = walletsResponse.body;
        if (wallets == null || wallets.isEmpty) {
          throw Exception('No wallets found at ${cfg.baseUrl}');
        }
        final wallet = wallets.first;

        final domainId = await _ensureNostrnip5Domain(
          baseUrl: cfg.baseUrl,
          bearerToken: token,
          walletApiKey: wallet.adminkey,
          walletId: wallet.id,
          domain: domain,
        );

        // The activate endpoint calls update_ln_address() which requires
        // NIP-05 settings (lnaddress_api_endpoint + admin key). Create them
        // once so every subsequent activate call succeeds.
        await _ensureNostrnip5Settings(
          baseUrl: cfg.baseUrl,
          bearerToken: token,
          walletApiKey: wallet.adminkey,
        );

        final sorted = entries.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        for (final entry in sorted) {
          await _ensureNostrnip5Address(
            baseUrl: cfg.baseUrl,
            bearerToken: token,
            walletApiKey: wallet.adminkey,
            domainId: domainId,
            localPart: entry.key,
            pubkey: entry.value,
          );
        }

        print(
          'nostrnip5: created ${sorted.length} NIP-05 entries for $domain '
          '(domainId=$domainId)',
        );

        return domainId;
      } finally {
        authed.client.dispose();
      }
    } finally {
      unauth.client.dispose();
    }
  }

  /// Ensures the nostrnip5 NIP-05 settings exist so that `activate_address`
  /// (which internally calls `update_ln_address`) can create lnurlp pay links.
  ///
  /// The GET /settings endpoint returns a default object with
  /// `lnaddress_api_endpoint: "https://nostr.com"` even when nothing is
  /// persisted, so we always PUT to guarantee settings are stored.
  Future<void> _ensureNostrnip5Settings({
    required String baseUrl,
    required String bearerToken,
    required String walletApiKey,
  }) async {
    final headers = {
      'Authorization': 'Bearer $bearerToken',
      'X-Api-Key': walletApiKey,
    };

    try {
      await _jsonRequest(
        method: 'PUT',
        uri: Uri.parse('$baseUrl/nostrnip5/api/v1/settings'),
        headers: headers,
        body: {
          'lnaddress_api_endpoint': baseUrl,
          'lnaddress_api_admin_key': walletApiKey,
        },
      );
      print(
        '[lnbits][nip05] NIP-05 settings saved '
        '(lnaddress endpoint → $baseUrl)',
      );
    } catch (e) {
      print('[lnbits][nip05] Warning: failed to save NIP-05 settings: $e');
    }
  }

  /// Creates a nostrnip5 domain if it doesn't exist yet. Returns the domain ID.
  Future<String> _ensureNostrnip5Domain({
    required String baseUrl,
    required String bearerToken,
    required String walletApiKey,
    required String walletId,
    required String domain,
  }) async {
    final headers = {
      'Authorization': 'Bearer $bearerToken',
      'X-Api-Key': walletApiKey,
    };

    // Check if domain already exists.
    try {
      final domains = await _jsonRequest(
        method: 'GET',
        uri: Uri.parse('$baseUrl/nostrnip5/api/v1/domains'),
        headers: headers,
        returnList: true,
      );
      if (domains is List) {
        for (final d in domains) {
          if (d is Map<String, dynamic> &&
              d['domain']?.toString().toLowerCase() == domain.toLowerCase()) {
            final existingId = d['id'].toString();
            print(
              '[lnbits][nip05] Domain "$domain" already exists '
              '(id=$existingId). Reusing.',
            );
            return existingId;
          }
        }
        print(
          '[lnbits][nip05] Domain "$domain" not found among '
          '${domains.length} existing domain(s). Creating...',
        );
      }
    } catch (e) {
      print(
        '[lnbits][nip05] Could not list existing domains: $e. '
        'Attempting to create "$domain"...',
      );
    }

    final response = await _jsonRequest(
      method: 'POST',
      uri: Uri.parse('$baseUrl/nostrnip5/api/v1/domain'),
      headers: headers,
      body: {
        'wallet': walletId,
        'currency': 'sats',
        // nostrnip5 treats cost=0 as "cannot compute price" (0 is falsy in
        // Python). Use 1 sat so the price check passes; no invoice is created
        // because addresses are activated directly by the admin.
        'cost': 1,
        'domain': domain,
      },
    );

    final domainId = response['id']?.toString();
    if (domainId == null || domainId.isEmpty) {
      throw Exception('Failed to create nostrnip5 domain "$domain": $response');
    }
    print('[lnbits][nip05] Created domain "$domain" (id=$domainId)');
    return domainId;
  }

  /// Creates and activates a NIP-05 address in a nostrnip5 domain.
  Future<void> _ensureNostrnip5Address({
    required String baseUrl,
    required String bearerToken,
    required String walletApiKey,
    required String domainId,
    required String localPart,
    required String pubkey,
  }) async {
    final headers = {
      'Authorization': 'Bearer $bearerToken',
      'X-Api-Key': walletApiKey,
    };

    try {
      final response = await _jsonRequest(
        method: 'POST',
        uri: Uri.parse('$baseUrl/nostrnip5/api/v1/domain/$domainId/address'),
        headers: headers,
        body: {
          'domain_id': domainId,
          'local_part': localPart,
          'pubkey': pubkey,
          'years': 1,
          'create_invoice': false,
        },
      );

      final addressId = response['id']?.toString();
      if (addressId != null && addressId.isNotEmpty) {
        // Activate the address so it appears in nostr.json lookups.
        // The activate endpoint also calls update_ln_address(), which tries
        // to create a lnurlp pay link. If that link was already created by
        // setupUsernamesByDomain the call will 500 — but the address is
        // already marked active in the DB before that step, so we treat
        // the error as non-fatal.
        try {
          await _jsonRequest(
            method: 'PUT',
            uri: Uri.parse(
              '$baseUrl/nostrnip5/api/v1/domain/$domainId/address/$addressId/activate',
            ),
            headers: headers,
          );
          print(
            '[lnbits][nip05] Created & activated address '
            '$localPart (id=$addressId, pubkey=${pubkey.substring(0, 8)}...)',
          );
        } catch (e) {
          // activate_address() persists active=true before update_ln_address()
          // runs, so the NIP-05 lookup will still work even if the lnurlp
          // link creation fails (e.g. duplicate username).
          print(
            '[lnbits][nip05] Created address $localPart (id=$addressId). '
            'Activate returned an error (non-fatal): $e',
          );
        }
      } else {
        print(
          '[lnbits][nip05] Warning: address creation for $localPart '
          'returned no id: $response',
        );
      }
    } on HttpException catch (e) {
      if (e.message.contains('already') ||
          e.message.contains('exists') ||
          e.message.contains('not available')) {
        print('[lnbits][nip05] Address $localPart already exists. Skipping.');
        return;
      }
      print('[lnbits][nip05] Error creating address $localPart: ${e.message}');
      rethrow;
    }
  }

  Future<dynamic> _jsonRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    Object? body,
    bool returnList = false,
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

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw HttpException(
          'HTTP ${response.statusCode} for ${uri.path}: $raw',
          uri: uri,
        );
      }

      if (raw.isEmpty) {
        return returnList ? <dynamic>[] : <String, dynamic>{};
      }

      final decoded = jsonDecode(raw);

      if (returnList) {
        return decoded is List ? decoded : [decoded];
      }

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{'value': decoded};
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
