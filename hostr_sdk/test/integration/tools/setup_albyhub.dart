import 'dart:io';

import 'albyhub_client.dart';

Future<void> main(List<String> args) async {
  final parsed = _parseArgs(args);
  final url = parsed['url'];
  final appName = parsed['app-name'];
  final password = parsed['password'];
  final outputDir = parsed['output-dir'];
  final userPubkey = parsed['user-pubkey'];
  final limit = int.tryParse(parsed['limit'] ?? '') ?? 0;

  if (url == null || appName == null || password == null || outputDir == null) {
    _printUsageAndExit();
  }

  final albyHub = AlbyHubClient(
    baseUri: Uri.parse(url),
    unlockPassword: password,
  );

  try {
    final pairingUrl = await albyHub.getConnectionForPubkey(
      userPubkey ?? '',
      appName: appName,
      limit: limit,
    );

    if (pairingUrl == null || pairingUrl.isEmpty) {
      stderr.writeln('No pairing URL was returned.');
      exitCode = 1;
      return;
    }

    final dataDir = Directory(outputDir);
    final pairingFile = File('${dataDir.path}/pairing_urls.txt');
    final pairingDir = Directory('${dataDir.path}/pairing_urls');

    if (!pairingDir.existsSync()) {
      pairingDir.createSync(recursive: true);
    }

    pairingFile.writeAsStringSync(
      '$url: $pairingUrl\n',
      mode: FileMode.append,
      flush: true,
    );

    final filePubkey = (userPubkey != null && userPubkey.isNotEmpty)
        ? userPubkey
        : _nwcPubkeyFromPairingUrl(pairingUrl);

    if (filePubkey != null) {
      File(
        '${pairingDir.path}/$filePubkey',
      ).writeAsStringSync('$pairingUrl\n', flush: true);
      stdout.writeln('Saved pairing URL to ${pairingDir.path}/$filePubkey');
    } else {
      stderr.writeln(
        'Warning: no user pubkey supplied and could not parse NWC pubkey from pairing URL.',
      );
    }

    stdout.writeln('Pairing URL: $pairingUrl');
  } finally {
    albyHub.close();
  }
}

Map<String, String> _parseArgs(List<String> args) {
  final result = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    final key = args[i];
    if (!key.startsWith('--')) continue;
    if (i + 1 >= args.length) break;
    final value = args[i + 1];
    result[key.substring(2)] = value;
    i++;
  }
  return result;
}

String? _nwcPubkeyFromPairingUrl(String pairingUrl) {
  const prefix = 'nostr+walletconnect://';
  if (!pairingUrl.startsWith(prefix)) return null;
  final rest = pairingUrl.substring(prefix.length);
  final qIndex = rest.indexOf('?');
  final pubkey = qIndex == -1 ? rest : rest.substring(0, qIndex);
  final isHex64 = RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(pubkey);
  return isHex64 ? pubkey : null;
}

Never _printUsageAndExit() {
  stderr.writeln(
    'Usage: dart run test/integration/tools/setup_albyhub.dart '
    '--url <albyhub_url> --app-name <app_name> --password <unlock_password> '
    '--output-dir <docker_data_dir> [--user-pubkey <hex64>] [--limit <sats>]',
  );
  exit(1);
}
