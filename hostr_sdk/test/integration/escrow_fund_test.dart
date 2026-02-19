import 'dart:io';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart';

import 'tools/fund_anvil.dart';

void main() {
  late Hostr hostr;

  setUpAll(() async {
    final storageDir = Directory(
      '${Directory.systemTemp.path}/hostr_escrow_fund_it',
    );
    if (!storageDir.existsSync()) {
      storageDir.createSync(recursive: true);
    }

    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(storageDir.path),
    );
  });

  tearDown(() async {
    await hostr.dispose();
    await getIt.reset();
  });

  test(
    'escrow fund emits expected state flow and confirms transaction',
    () async {
      hostr = Hostr(
        environment: Env.dev,
        config: HostrConfig(
          logs: CustomLogger(),
          bootstrapRelays: ['ws://relay.hostr.development'],
          bootstrapBlossom: ['http://blossom.hostr.development'],
          rootstockConfig: _DevelopmentRootstockConfig(),
        ),
      );

      hostr.start();
      await hostr.auth.signin(MockKeys.guest.privateKey!);

      await fundAnvilAddress(
        hostr.auth.getActiveEvmKey().address.eip55With0x,
        balanceWei: BigInt.parse('2000000000000000000'),
      );

      final contractAddress =
          Platform.environment['CONTRACT_ADDR'] ??
          '0x7a2088a1bFc9d81c55368AE168C2C02570cB814F';

      final escrowService = MOCK_ESCROWS(
        contractAddress: contractAddress,
      ).first;
      final sellerProfile = ProfileMetadata.fromNostrEvent(MOCK_PROFILES.first);
      final tradeId = DateTime.now().microsecondsSinceEpoch
          .toRadixString(16)
          .padLeft(64, '0');

      final now = DateTime.now().toUtc();
      final reservationRequest = ReservationRequest(
        pubKey: MockKeys.guest.publicKey,
        tags: ReservationRequestTags([
          [kListingRefTag, MOCK_LISTINGS.first.anchor!],
          ['d', tradeId],
        ]),
        content: ReservationRequestContent(
          start: now.add(const Duration(days: 1)),
          end: now.add(const Duration(days: 2)),
          quantity: 1,
          amount: Amount(currency: Currency.BTC, value: BigInt.from(100000)),
          salt: 'escrow-fund-it-salt',
        ),
        createdAt: now.millisecondsSinceEpoch ~/ 1000,
      ).signAs(MockKeys.guest, ReservationRequest.fromNostrEvent);

      final operation = hostr.escrow.fund(
        EscrowFundParams(
          escrowService: escrowService,
          reservationRequest: reservationRequest,
          sellerProfile: sellerProfile,
          amount: reservationRequest.parsedContent.amount,
        ),
      );

      final emittedStates = <EscrowFundState>[operation.state];
      final sub = operation.stream.listen(emittedStates.add);

      await operation.execute();
      emittedStates.add(operation.state);
      await sub.cancel();

      expect(emittedStates.first, isA<EscrowFundInitialised>());
      expect(operation.state, isA<EscrowFundCompleted>());
      expect(emittedStates.whereType<EscrowFundCompleted>(), isNotEmpty);

      final completed = operation.state as EscrowFundCompleted;
      final txHash = _extractTxHash(completed.transactionInformation);
      expect(txHash, isNotNull);

      final receipt = await getIt<Evm>().rootstock.awaitReceipt(txHash!);
      expect(_isReceiptSuccessful(receipt), isTrue);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}

String? _extractTxHash(TransactionInformation tx) {
  final dynamic d = tx;
  final hash = d.hash?.toString() ?? d.id?.toString();
  if (hash == null || hash.isEmpty) return null;
  return hash;
}

bool _isReceiptSuccessful(TransactionReceipt receipt) {
  final dynamic status = (receipt as dynamic).status;
  if (status == null) return true;
  if (status is bool) return status;
  if (status is int) return status == 1;
  if (status is BigInt) return status == BigInt.one;
  final normalized = status.toString().toLowerCase();
  return normalized == '1' || normalized == '0x1' || normalized == 'true';
}

class _DevelopmentRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 33;

  @override
  String get rpcUrl => 'http://localhost:8545';

  @override
  BoltzConfig get boltz => _DevelopmentBoltzConfig();
}

class _DevelopmentBoltzConfig extends BoltzConfig {
  @override
  String get apiUrl => 'http://localhost:9001/v2';

  @override
  String get rifRelayUrl => 'http://localhost:8090';

  @override
  String get rifRelayCallVerifier =>
      '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707';

  @override
  String get rifRelayDeployVerifier =>
      '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';

  @override
  String get rifSmartWalletFactoryAddress =>
      '0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE';
}
