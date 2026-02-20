import 'dart:io';

import 'package:hostr_sdk/datasources/alby/alby.dart';
import 'package:hostr_sdk/datasources/lnbits/lnbits.dart';

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
  final lnbitsExtensionName = env['LNBITS_EXTENSION_NAME'] ?? 'lnurlp';
  final lnbitsNostrPrivateKey = env['LNBITS_NOSTR_PRIVATE_KEY'];

  print('Unlocking AlbyHub instances...');
  await _unlockAlby(alby1Url, albyPassword);
  await _unlockAlby(alby2Url, albyPassword);

  print('Unlocking LNbits instances...');
  await _unlockLnbits(
    lnbits1Url,
    lnbitsAdminEmail,
    lnbitsAdminPassword,
    lnbitsExtensionName,
    lnbitsNostrPrivateKey,
  );
  await _unlockLnbits(
    lnbits2Url,
    lnbitsAdminEmail,
    lnbitsAdminPassword,
    lnbitsExtensionName,
    lnbitsNostrPrivateKey,
  );

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
  } finally {
    client.close();
  }

  print('AlbyHub unlocked: $url');
}

Future<void> _unlockLnbits(
  String baseUrl,
  String adminEmail,
  String adminPassword,
  String extensionName,
  String? nostrPrivateKey,
) async {
  final datasource = LnbitsDatasource();
  await datasource.setupServer(
    baseUrl: baseUrl,
    adminEmail: adminEmail,
    adminPassword: adminPassword,
    extensionName: extensionName,
    nostrPrivateKey: nostrPrivateKey,
  );

  print('LNbits unlocked: $baseUrl');
}

String _buildHttpUrl({required String host, required String port}) {
  return 'http://$host:$port';
}

String _buildHttpsUrl({required String host, required String port}) {
  return 'https://$host:$port';
}
