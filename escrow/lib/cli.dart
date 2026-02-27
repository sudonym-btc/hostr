import 'dart:async';
import 'dart:io';

import 'package:args/args.dart';
import 'package:escrow/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_state.dart';
import 'package:interact_cli/interact_cli.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

/// Allow self-signed certificates so the escrow daemon can connect to local
/// relay/blossom/etc. over TLS without a trusted CA chain.
class _PermissiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, __, ___) => true;
    return client;
  }
}

void main(List<String> arguments) async {
  HttpOverrides.global = _PermissiveHttpOverrides();
  final String relayUrl =
      Platform.environment['NOSTR_RELAY'] ?? 'wss://relay.hostr.development';
  final String privateKey =
      Platform.environment['PRIVATE_KEY'] ?? MockKeys.escrow.privateKey!;
  final String rpcUrl =
      Platform.environment['RPC_URL'] ?? 'http://localhost:8545';
  final String blossomUrl = Platform.environment['BLOSSOM_URL'] ??
      'https://blossom.hostr.development';
  final String environment = Platform.environment['ENV'] ?? 'dev';
  final String contractAddress = Platform.environment['CONTRACT_ADDR'] ??
      '0x7a2088a1bFc9d81c55368AE168C2C02570cB814F';

  await setupInjection(
    relayUrl: relayUrl,
    rpcUrl: rpcUrl,
    blossomUrl: blossomUrl,
    environment: environment,
  );
  final hostr = getIt<Hostr>();

  await hostr.auth.signin(privateKey);

  final ourProfile = await hostr.metadata
      .getOne(Filter(authors: [hostr.auth.activeKeyPair!.publicKey]));

  final ourEscrowService = EscrowService(
      pubKey: hostr.auth.activeKeyPair!.publicKey,
      tags: EventTags([]),
      content: EscrowServiceContent(
          pubkey: hostr.auth.activeKeyPair!.publicKey,
          evmAddress: hostr.auth.getActiveEvmKey().address.eip55With0x,
          contractAddress: contractAddress,
          contractBytecodeHash: 'MockBytecodeHash',
          chainId: (await hostr.evm.supportedEvmChains[0].client.getChainId())
              .toInt(),
          maxDuration: Duration(days: 365),
          type: EscrowType.EVM));

  print(ourProfile);

  final parser = ArgParser()
    ..addCommand('start')
    ..addCommand('list-pending');

  final fundCmd = parser.addCommand('fund');
  fundCmd
    ..addOption('amount', help: 'Amount to fund the escrow', mandatory: true);

  final arbitrateCmd = parser.addCommand('arbitrate');
  arbitrateCmd
    ..addOption('tradeId',
        help: 'Trade ID string to arbitrate', mandatory: true)
    ..addOption('forward',
        help: 'Forward ratio as double, strictly between 0 and 1',
        mandatory: true);

  final auditCmd = parser.addCommand('audit');
  auditCmd.addOption('tradeId', help: 'Trade ID to audit', mandatory: true);

  final threadsCmd = parser.addCommand('threads');
  threadsCmd.addOption(
    'threadId',
    abbr: 't',
    help: 'Thread anchor/ID to display messages for (omit to list all threads)',
  );

  final argResults = parser.parse(arguments);

  switch (argResults.command?.name) {
    case 'start':
      print('Starting escrow service');

      final contract = hostr.evm.supportedEvmChains[0]
          .getSupportedEscrowContract(ourEscrowService);
      await contract.ensureDeployed();

      await getIt<Hostr>().escrows.upsert(ourEscrowService);

      break;

    case 'fund':
      final cmd = argResults.command;
      final amount = cmd?['amount'] as String?;
      final swapOp = hostr.evm.supportedEvmChains[0].swapIn(SwapInParams(
          evmKey: hostr.auth.getActiveEvmKey(),
          amount: BitcoinAmount.fromInt(BitcoinUnit.sat, int.parse(amount!))));
      swapOp.execute();
      swapOp.stream
          .doOnData(print)
          .whereType<SwapInPaymentProgress>()
          .map((e) => e.paymentState)
          .whereType<PayExternalRequired>()
          .listen((event) {
        print(
            'Swap event: ${(event.callbackDetails as LightningCallbackDetails).invoice.paymentRequest}');
      });
      break;
    case 'list-pending':
      final contract = hostr.evm
          .getChainForEscrowService(ourEscrowService)
          .getSupportedEscrowContract(ourEscrowService);

      final streamer = contract.allEvents(
          ContractEventsParams(
              arbiterEvmAddress: hostr.auth.getActiveEvmKey().address),
          null);

      streamer.stream.listen(
          (data) => print('Received event: ${(data as dynamic).tradeId}'));
      break;
    case 'list-active':
      break;
    case 'list-closed':
      break;
    case 'create-service':
      break;
    case 'update-service':
      break;
    case 'delete-service':
      break;
    case 'arbitrate':
      final cmd = argResults.command;
      final tradeId = cmd?['tradeId'] as String?;
      final forwardRaw = cmd?['forward'] as String?;
      if (tradeId == null || tradeId.isEmpty || forwardRaw == null) {
        exitCode = 64;
        return;
      }

      final forward = double.tryParse(forwardRaw);
      if (forward == null || forward <= 0 || forward >= 1) {
        print(
            'Invalid forward value. Must be a number strictly between 0 and 1.');
        exitCode = 64;
        return;
      }

      final contract = hostr.evm
          .getChainForEscrowService(ourEscrowService)
          .getSupportedEscrowContract(ourEscrowService);

      final txHash = await contract.arbitrate(
        ContractArbitrateParams(
          tradeId: tradeId,
          forward: forward,
          ethKey: hostr.auth.getActiveEvmKey(),
        ),
      );
      print('Arbitrate tx: $txHash');
      break;
    case 'audit':
      final cmd = argResults.command;
      final tradeId = cmd?['tradeId'] as String?;
      if (tradeId == null || tradeId.isEmpty) {
        print('--tradeId is required');
        exitCode = 64;
        return;
      }
      final result = await hostr.tradeAudit.audit(tradeId);
      print(result.format());
      break;
    case 'threads':
      final cmd = argResults.command;
      String? threadId = cmd?['threadId'] as String?;

      final threadsSvc = hostr.messaging.threads;

      // ── Sync with spinner ───────────────────────────────────────────────
      final spinner = Spinner(
        icon: '✓',
        rightPrompt: (state) => switch (state) {
          SpinnerStateType.inProgress => 'Loading threads…',
          SpinnerStateType.done => 'Threads loaded',
          SpinnerStateType.failed => 'Failed to load threads',
        },
      ).interact();

      threadsSvc.sync();
      await threadsSvc.status
          .firstWhere((s) => s is StreamStatusQueryComplete)
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => StreamStatusQueryComplete(),
          );
      spinner.done();

      // ── If no threadId given, show a Select to pick one ─────────────────
      if (threadId == null) {
        final anchors = threadsSvc.threads.keys.toList();
        if (anchors.isEmpty) {
          print('No threads found.');
          break;
        }

        final options = anchors.map((anchor) {
          final count = threadsSvc.threads[anchor]!.state.value.messages.length;
          return '$anchor  ($count messages)';
        }).toList();

        final idx = Select(
          prompt: 'Select a thread',
          options: options,
        ).interact();

        threadId = anchors[idx];
      }

      // ── Detail view ─────────────────────────────────────────────────────
      await _runThreadDetail(hostr, threadsSvc, threadId);
      break;
    default:
      print('Unknown command');
  }
}

// ── Thread detail ────────────────────────────────────────────────────────────

Future<void> _runThreadDetail(
  Hostr hostr,
  Threads threadsSvc,
  String threadId,
) async {
  final thread = threadsSvc.threads[threadId];
  if (thread == null) {
    print('Thread not found: $threadId');
    exitCode = 1;
    return;
  }

  final myPubkey = hostr.auth.activeKeyPair!.publicKey;

  // Load profiles for every participant (with spinner).
  final profiles = <String, ProfileMetadata?>{};
  final profileSpinner = Spinner(
    icon: '✓',
    rightPrompt: (state) => switch (state) {
      SpinnerStateType.inProgress => 'Loading participant profiles…',
      SpinnerStateType.done => 'Profiles loaded',
      SpinnerStateType.failed => 'Some profiles could not be loaded',
    },
  ).interact();

  for (final pubkey in thread.state.value.participantPubkeys) {
    profiles[pubkey] = await hostr.metadata.loadMetadata(pubkey);
  }
  profileSpinner.done();

  // Buyer = sender of the first reservation request; seller = the other party.
  final reservations = thread.state.value.reservationRequests;
  final buyerPubkey =
      reservations.isNotEmpty ? reservations.first.pubKey : null;

  print('');
  print('── Thread: $threadId ──');

  // Print history in chronological order.
  for (final msg in thread.state.value.sortedMessages) {
    _printThreadMessage(msg, profiles, myPubkey, buyerPubkey);
  }

  // Watch for inbound messages arriving while we are in the reply loop.
  thread.messages.stream.listen((msg) async {
    if (!profiles.containsKey(msg.pubKey)) {
      profiles[msg.pubKey] = await hostr.metadata.loadMetadata(msg.pubKey);
    }
    // Print above the current Input prompt.
    print('');
    _printThreadMessage(msg, profiles, myPubkey, buyerPubkey);
  });

  // Interactive reply loop — press Enter with empty input or Ctrl-C to exit.
  print('');
  print('─── Enter a reply, or leave blank to exit ───');
  while (true) {
    final reply = Input(prompt: 'Reply').interact();
    if (reply.trim().isEmpty) break;
    try {
      await thread.replyText(reply.trim());
    } catch (e) {
      print('Send error: $e');
    }
  }
}

// ── Thread-message helpers ───────────────────────────────────────────────────

void _printThreadMessage(
  Message msg,
  Map<String, ProfileMetadata?> profiles,
  String myPubkey,
  String? buyerPubkey,
) {
  final profile = profiles[msg.pubKey];
  final name = profile?.metadata.name ??
      profile?.metadata.displayName ??
      msg.pubKey.substring(0, 8);

  final role = msg.pubKey == myPubkey
      ? 'escrow'
      : msg.pubKey == buyerPubkey
          ? 'buyer'
          : 'seller';

  final dt =
      DateTime.fromMillisecondsSinceEpoch(msg.createdAt * 1000).toLocal();
  final timeStr =
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  final dateStr = '$timeStr, ${_formatDate(dt)}';

  final content = msg.content.isNotEmpty ? msg.content : '[event]';
  print('- $name ($role): $content');
  print('  $dateStr');
}

String _formatDate(DateTime dt) =>
    '${dt.day}${_daySuffix(dt.day)} ${_monthAbbr(dt.month)} ${dt.year}';

String _daySuffix(int day) {
  if (day >= 11 && day <= 13) return 'th';
  switch (day % 10) {
    case 1:
      return 'st';
    case 2:
      return 'nd';
    case 3:
      return 'rd';
    default:
      return 'th';
  }
}

String _monthAbbr(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}
