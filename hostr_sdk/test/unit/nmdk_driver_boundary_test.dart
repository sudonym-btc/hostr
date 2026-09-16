@Tags(['unit'])
library;

import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/datasources/app_database.dart';
import 'package:hostr_sdk/hostr.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:marketplace_evm/util/telemetry.dart';
import 'package:marketplace_evm/marketplace_evm.dart' as driver;
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test(
    'independent Hostr scopes retain their own driver dependencies',
    () async {
      final first = _hostr('first');
      final second = _hostr('second');
      addTearDown(() async {
        await first.dispose();
        await second.dispose();
        first.config.appDatabase.db.close();
        second.config.appDatabase.db.close();
      });

      // Interleaved construction must keep each session isolated.
      final firstChain = first.evm.configuredChains.single;
      final secondChain = second.evm.configuredChains.single;
      expect(firstChain.config.id, 'first');
      expect(secondChain.config.id, 'second');
      expect(firstChain.auth, same(first.auth));
      expect(secondChain.auth, same(second.auth));
      expect(firstChain.payments, same(first.payments));
      expect(secondChain.payments, same(second.payments));
      expect(firstChain.nwc, same(first.nwc));
      expect(secondChain.nwc, same(second.nwc));

      expect(first.auth.operationStateStore, same(first.operationStateStore));
      expect(second.auth.operationStateStore, same(second.operationStateStore));
      expect(first.auth.swapInTracker, same(first.swapInTracker));
      expect(second.auth.swapOutTracker, same(second.swapOutTracker));
      expect(
        first.operationStateStore,
        isNot(same(second.operationStateStore)),
      );

      await Future.wait([
        first.evm.init(),
        first.evm.init(),
        second.evm.init(),
      ]);
      expect(first.evm.configuredChains.single, same(firstChain));
      expect(second.evm.configuredChains.single, same(secondChain));
    },
  );

  test('Hostr exposes its registered NMDK driver instances', () async {
    final hostr = _hostr('identity');
    addTearDown(() async {
      await hostr.dispose();
      hostr.config.appDatabase.db.close();
    });

    expect(hostr.evm, same(hostr.scope<driver.Evm>()));
    expect(hostr.fundsMonitor, same(hostr.scope<driver.FundsMonitorService>()));
    expect(
      hostr.operationStateStore,
      same(hostr.scope<driver.OperationStateStore>()),
    );

    final driver.EvmPaymentEvents events = hostr.userSubscriptions;
    expect(events.paymentEvents$, same(hostr.userSubscriptions.paymentEvents$));
  });
}

Hostr _hostr(String id) => Hostr(
  environment: Env.test,
  config: HostrConfig(
    bootstrapRelays: const [],
    bootstrapBlossom: const [],
    hostrRelay: '',
    evmConfig: driver.EvmConfig(
      chains: [
        driver.EvmChainConfig(
          id: id,
          chainId: 30,
          nativeDenomination: 'BTC',
          rpcUrls: const ['http://127.0.0.1:1'],
        ),
      ],
    ),
    appDatabase: AppDatabase(sqlite3.openInMemory()),
    telemetry: Telemetry(enableExport: false),
  ),
);
