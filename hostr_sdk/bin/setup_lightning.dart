import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/datasources/alby/alby.dart';
import 'package:hostr_sdk/datasources/swagger_generated/lnbits.swagger.dart';

Future<void> main() async {
  final env = Platform.environment;

  final albyPassword = env['ALBYHUB_PASSWORD'] ?? 'Testing123!';
  final alby1Url =
      env['ALBYHUB_1_URL'] ??
      _buildHttpsUrl(
        host: env['ALBYHUB_HOST'] ?? 'localhost',
        port: env['ALBYHUB_1_PORT'] ?? '12345',
      );
  final alby2Url =
      env['ALBYHUB_2_URL'] ??
      _buildHttpsUrl(
        host: env['ALBYHUB_HOST'] ?? 'localhost',
        port: env['ALBYHUB_2_PORT'] ?? '12346',
      );

  final lnbits1Url =
      env['LNBITS_1_URL'] ??
      _buildHttpUrl(
        host: env['LNBITS_HOST'] ?? 'localhost',
        port: env['LNBITS_1_PORT'] ?? '5055',
      );
  final lnbits2Url =
      env['LNBITS_2_URL'] ??
      _buildHttpUrl(
        host: env['LNBITS_HOST'] ?? 'localhost',
        port: env['LNBITS_2_PORT'] ?? '5056',
      );
  final lnbitsAdminEmail = env['LNBITS_ADMIN_EMAIL'] ?? 'admin@example.com';
  final lnbitsAdminPassword = env['LNBITS_ADMIN_PASSWORD'] ?? 'adminpassword';

  print('Unlocking AlbyHub instances...');
  await _unlockAlby(alby1Url, albyPassword);
  await _unlockAlby(alby2Url, albyPassword);

  print('Unlocking LNbits instances...');
  await _unlockLnbits(lnbits1Url, lnbitsAdminEmail, lnbitsAdminPassword);
  await _unlockLnbits(lnbits2Url, lnbitsAdminEmail, lnbitsAdminPassword);

  print('Lightning services unlocked.');
}

Future<void> _unlockAlby(String url, String password) async {
  final client = AlbyHubClient(
    baseUri: Uri.parse(url),
    unlockPassword: password,
  );

  try {
    await client.setup();
    await client.start();
    final token = await client.unlock();
    if (token.isEmpty) {
      throw StateError('AlbyHub unlock did not return a token.');
    }
    print('AlbyHub unlocked: $url');
  } finally {
    client.close();
  }
}

Future<void> _unlockLnbits(
  String baseUrl,
  String adminEmail,
  String adminPassword,
) async {
  final api = Lnbits.create(baseUrl: Uri.parse(baseUrl));
  try {
    await api.apiV1AuthFirstInstallPut(
      body: UpdateSuperuserPassword(
        username: adminEmail,
        password: adminPassword,
        passwordRepeat: adminPassword,
      ),
    );

    final login = await api.apiV1AuthPost(
      body: LoginUsernamePassword(
        username: adminEmail,
        password: adminPassword,
      ),
    );
    final token = _extractAccessToken(login.body);

    if (token == null || token.isEmpty) {
      throw StateError(
        'LNbits unlock/login failed for $baseUrl: ${login.body}',
      );
    }

    print('LNbits unlocked: $baseUrl');
  } finally {
    api.client.dispose();
  }
}

String? _extractAccessToken(dynamic body) {
  if (body is Map<String, dynamic>) {
    return body['access_token']?.toString();
  }
  if (body is Map) {
    return body['access_token']?.toString();
  }
  if (body is String && body.isNotEmpty) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return decoded['access_token']?.toString();
      }
    } catch (_) {
      return null;
    }
  }
  return null;
}

String _buildHttpUrl({required String host, required String port}) {
  return 'http://$host:$port';
}

String _buildHttpsUrl({required String host, required String port}) {
  return 'https://$host:$port';
}
