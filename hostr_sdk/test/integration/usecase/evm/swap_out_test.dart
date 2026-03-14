@Tags(['integration', 'docker'])
library;

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/data_layer/data_sources/http_request.dart';
import 'package:ndk/data_layer/repositories/lnurl_http_impl.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl.dart';
import 'package:test/test.dart';

import '../../../support/integration_test_harness.dart';

/// Fetches a real BOLT-11 invoice for [amountSats] from the LNbits
/// `tips@lnbits1.hostr.development` Lightning Address.
Future<String> _fetchLnurlInvoice(int amountSats) async {
  final lnurl = Lnurl(
    transport: LnurlTransportHttpImpl(HttpRequestDS(http.Client())),
  );
  final link = Lnurl.getLud16LinkFromLud16('tips@lnbits1.hostr.development');
  final response = await lnurl.getLnurlResponse(link!);
  final invoiceResponse = await lnurl.fetchInvoice(
    lnurlResponse: response!,
    amountSats: amountSats,
  );
  return invoiceResponse!.invoice;
}

void _printElapsed(String label, Stopwatch sw) {
  print('[timing][swap_out_test] $label: ${sw.elapsedMilliseconds} ms');
}

void main() {
  late IntegrationTestHarness harness;

  setUp(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_swap_out_it',
      logLevel: Level.warning,
      cleanHydratedStorage: true,
    );
  });

  tearDownAll(() {
    IntegrationTestHarness.resetLogLevel();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test(
    'swap out emits expected state flow when NWC is connected',
    () async {
      final hostr = harness.hostr;

      await harness.signInAndConnectNwc(
        user: harness.fundedKeys[0],
        appNamePrefix: 'swap-out-it',
      );

      final swapOut = hostr.evm.rootstock.swapOutAll().first;

      final emittedStates = <SwapOutState>[swapOut.state];
      final sub = swapOut.stream.listen(emittedStates.add);

      await swapOut.execute();
      await sub.cancel();

      expect(emittedStates.first, isA<SwapOutInitialised>());
      expect(
        emittedStates.any((state) => state is SwapOutAwaitingOnChain),
        isTrue,
      );
      expect(emittedStates.any((state) => state is SwapOutFunded), isTrue);
      // Use the synchronous state getter for the terminal check — the Cubit
      // updates `state` synchronously in emit(), but the broadcast
      // StreamController (sync: false in Bloc 9) delivers stream events via
      // microtasks, so `emittedStates.last` may lag behind.
      expect(swapOut.state, isA<SwapOutCompleted>());
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  test(
    'submitExternalInvoice rejects invalid invoice then accepts valid one',
    () async {
      final sw = Stopwatch()..start();
      // Sign in without NWC so _acquireInvoice falls through to external.
      await harness.hostr.auth.signin(MockKeys.guest.privateKey!);

      await harness.anvil.setBalance(
        address: harness.hostr.auth.getActiveEvmKey().address.eip55With0x,
        amountWei: BitcoinAmount.fromInt(BitcoinUnit.sat, 100000).getInWei,
      );

      // ── Attempt 1: submit an invalid invoice → swap fails ──────────
      final swapOut1 = harness.hostr.evm.rootstock.swapOutAll().first;
      final states1 = <SwapOutState>[swapOut1.state];
      final sub1 = swapOut1.stream.listen(states1.add);

      final run1 = swapOut1.execute();
      await expectLater(
        swapOut1.stream,
        emitsThrough(isA<SwapOutExternalInvoiceRequired>()),
      );

      expect(
        () => swapOut1.submitExternalInvoice('invalid-invoice'),
        throwsStateError,
      );

      expect(
        states1.any((s) => s is SwapOutAwaitingOnChain),
        isFalse,
        reason: 'Invalid invoice should never reach on-chain step',
      );

      // ── Attempt 2: submit a valid LNURL-fetched invoice → completes ─

      // Extract the exact amount Boltz requires and fetch a real invoice.
      final required$ = swapOut1.state as SwapOutExternalInvoiceRequired;
      final requiredSats = required$.invoiceAmount.getInSats.toInt();
      final validInvoice = await _fetchLnurlInvoice(requiredSats);

      swapOut1.submitExternalInvoice(validInvoice);
      await run1;
      await sub1.cancel();

      expect(swapOut1.state, isA<SwapOutCompleted>());
      expect(states1.any((s) => s is SwapOutExternalInvoiceRequired), isTrue);
      expect(states1.any((s) => s is SwapOutAwaitingOnChain), isTrue);
      expect(states1.any((s) => s is SwapOutFunded), isTrue);
      _printElapsed('test: external invoice flow', sw);
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
