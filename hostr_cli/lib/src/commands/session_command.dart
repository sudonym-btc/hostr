import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/ndk.dart';
import 'package:path/path.dart' as p;

import '../output/qr.dart';
import '../storage/cli_key_value_storage.dart';
import 'base.dart';

class SessionCommand extends Command<int> {
  SessionCommand({required IOSink stdout, required IOSink stderr}) {
    addSubcommand(SessionEnsureCommand(stdout: stdout, stderr: stderr));
    addSubcommand(SessionConnectCommand(stdout: stdout, stderr: stderr));
    addSubcommand(SessionResetCommand(stdout: stdout, stderr: stderr));
  }

  @override
  final String name = 'session';

  @override
  final String description =
      'Manage Hostr identity and local CLI session state.';
}

class SessionEnsureCommand extends HostrCliCommand {
  SessionEnsureCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption(
        'nsec',
        help: 'Import a local nsec/private key if not signed in.',
      )
      ..addOption('mnemonic', help: 'Import a mnemonic if not signed in.')
      ..addOption(
        'bunker-url',
        help: 'Connect to an existing NIP-46 bunker URL.',
      )
      ..addFlag(
        'connect',
        help: 'Start an interactive Nostr Connect login if no session exists.',
      )
      ..addFlag(
        'ensure-seed',
        help: 'Create or restore the Hostr account seed.',
      )
      ..addFlag('ensure-profile', help: 'Require that profile metadata exists.')
      ..addFlag(
        'ensure-seller-config',
        help: 'Ensure seller escrow configuration exists.',
      );
  }

  @override
  final String name = 'ensure';

  @override
  final String description = 'Ensure an authenticated Hostr session exists.';

  @override
  Future<HostrCliResult> runCommand() async {
    final context = await createContext();
    try {
      final hostr = context.hostr;
      final imported = await _maybeSignin(hostr);
      if (!await hostr.auth.isAuthenticated() &&
          argResults?['connect'] == true) {
        await _connectWithNostrConnect(hostr);
      }
      if (!await hostr.auth.isAuthenticated()) {
        return failure(
          'auth_required',
          'No active Hostr session.',
          hint: 'Pass --nsec, --mnemonic, --bunker-url, or --connect.',
        );
      }

      if (hostr.auth.needsBunkerRecovery) {
        await hostr.auth.retryBunkerSessionRestore();
      }

      final pubkey = hostr.auth.activePubkey!;
      final ensured = <String>[];
      if (argResults?['ensure-seed'] == true) {
        await hostr.accountSeedStore.ensureReady();
        ensured.add('seed');
      }
      if (argResults?['ensure-profile'] == true) {
        final profile = await hostr.metadata.loadMetadata(pubkey);
        if (profile == null) {
          return failure(
            'profile_required',
            'No profile metadata exists for the active pubkey.',
            hint: 'Create or edit profile metadata before continuing.',
            details: {'pubkey': pubkey},
          );
        }
        ensured.add('profile');
      }
      if (argResults?['ensure-seller-config'] == true) {
        await hostr.metadata.ensureSellerConfig(pubkey);
        ensured.add('seller_config');
      }

      return ok({
        'authenticated': true,
        'pubkey': pubkey,
        'credentialType': hostr.auth.isBunkerBacked
            ? 'bunker'
            : hostr.auth.isMnemonicBacked
            ? 'mnemonic'
            : hostr.auth.hasLocalPrivateKey
            ? 'private_key'
            : 'unknown',
        'imported': imported,
        'ensured': ensured,
      });
    } finally {
      await context.dispose();
    }
  }

  Future<bool> _maybeSignin(Hostr hostr) async {
    if (await hostr.auth.isAuthenticated()) return false;
    final bunkerUrl = argResults?['bunker-url'] as String?;
    final nsec = argResults?['nsec'] as String?;
    final mnemonic = argResults?['mnemonic'] as String?;
    final input = bunkerUrl ?? nsec ?? mnemonic;
    if (input == null || input.trim().isEmpty) return false;
    await hostr.auth.signin(input);
    return true;
  }
}

class SessionConnectCommand extends HostrCliCommand {
  SessionConnectCommand({required super.stdout, required super.stderr}) {
    argParser
      ..addOption(
        'timeout-seconds',
        defaultsTo: '180',
        help: 'How long to wait for the signer to connect.',
      )
      ..addFlag(
        'print-only',
        negatable: false,
        help: 'Print the nostrconnect URI and QR, then exit without waiting.',
      );
  }

  @override
  final String name = 'connect';

  @override
  final String description = 'Start an interactive Nostr Connect login.';

  @override
  Future<HostrCliResult> runCommand() async {
    final context = await createContext();
    try {
      final nostrConnect = buildNostrConnect(context.hostr);
      if (nostrConnect == null) {
        return failure('relay_required', 'No Hostr relay is configured.');
      }

      final uri = nostrConnect.nostrConnectURL;
      final terminalQr = renderTerminalQr(uri);
      final qrImage = renderQrImageDataUri(uri);
      if (!jsonOutput) {
        stdout.writeln(
          'Scan this with your Nostr app to log in to your Hostr account.',
        );
        stdout.writeln(uri);
        stdout.writeln('qr-image-data-uri: $qrImage');
        stdout.writeln(terminalQr);
      }
      if (argResults?['print-only'] == true) {
        return ok({
          'displayTitle': 'Log in to Hostr',
          'displayMessage':
              'Scan this with your Nostr app to log in to your Hostr account.',
          'nostrconnect': uri,
          'qr': terminalQr,
          'qrImage': qrImage,
        });
      }

      final timeoutSeconds =
          int.tryParse((argResults?['timeout-seconds'] as String?) ?? '') ??
          180;
      await context.hostr.auth
          .signinWithNostrConnect(
            nostrConnect,
            authCallback: (challenge) {
              if (!jsonOutput && challenge.trim().isNotEmpty) {
                stderr.writeln(challenge);
              }
            },
          )
          .timeout(Duration(seconds: timeoutSeconds));
      return ok({
        'authenticated': true,
        'pubkey': context.hostr.auth.activePubkey,
        'credentialType': 'bunker',
      });
    } finally {
      await context.dispose();
    }
  }
}

class SessionResetCommand extends HostrCliCommand {
  SessionResetCommand({required super.stdout, required super.stderr}) {
    argParser.addFlag(
      'yes',
      abbr: 'y',
      negatable: false,
      help: 'Confirm deletion of local Hostr CLI session state.',
    );
  }

  @override
  final String name = 'reset';

  @override
  final String description = 'Delete local Hostr CLI auth, seed, and state.';

  @override
  Future<HostrCliResult> runCommand() async {
    if (argResults?['yes'] != true) {
      return failure(
        'confirmation_required',
        'Refusing to delete local session state without --yes.',
        hint: 'Run hostr session reset --yes.',
        retryable: true,
      );
    }

    final options = cliOptions;
    final storage = CliKeyValueStorage(
      stateDir: Directory(
        p.join(options.stateDir.path, options.environment.name),
      ),
      allowInsecureFileStorage: true,
    );
    for (final key in const [
      HostrSDKStorage.authKey,
      HostrSDKStorage.seedKey,
      HostrSDKStorage.nwcKey,
      HostrSDKStorage.relaysKey,
    ]) {
      await storage.delete(key);
    }

    final dbFile = File(
      p.join(options.stateDir.path, '${options.environment.name}.sqlite3'),
    );
    if (await dbFile.exists()) {
      await dbFile.delete();
    }
    final envDir = Directory(
      p.join(options.stateDir.path, options.environment.name),
    );
    if (await envDir.exists()) {
      await envDir.delete(recursive: true);
    }

    return ok({'reset': true, 'stateDir': options.stateDir.path});
  }
}

NostrConnect? buildNostrConnect(
  Hostr hostr, {
  String appName = 'Hostr CLI',
  String appUrl = 'https://hostr.network',
}) {
  final relay = hostr.config.hostrRelay.trim();
  if (relay.isEmpty) return null;
  return NostrConnect(
    relays: [relay],
    appName: appName,
    appUrl: appUrl,
    appImageUrl:
        'https://hostr.network/assets/assets/images/logo/generated/logo_base_1024.png',
    perms: const [
      'sign_event',
      'nip44_encrypt',
      'nip44_decrypt',
      'nip04_encrypt',
      'nip04_decrypt',
    ],
  );
}

Future<void> _connectWithNostrConnect(Hostr hostr) async {
  final nostrConnect = buildNostrConnect(hostr);
  if (nostrConnect == null) {
    throw HostrCliException('relay_required', 'No Hostr relay is configured.');
  }
  stdout.writeln(nostrConnect.nostrConnectURL);
  stdout.writeln(
    'qr-image-data-uri: ${renderQrImageDataUri(nostrConnect.nostrConnectURL)}',
  );
  stdout.writeln(renderTerminalQr(nostrConnect.nostrConnectURL));
  await hostr.auth.signinWithNostrConnect(nostrConnect);
}
