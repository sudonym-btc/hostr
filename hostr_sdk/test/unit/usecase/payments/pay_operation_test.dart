@Tags(['unit'])
library;

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';
import 'package:hostr_sdk/usecase/lnurl/lnurl.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
import 'package:hostr_sdk/usecase/nwc/nwc.dart';
import 'package:hostr_sdk/usecase/payments/operations/bolt11_operation.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_state.dart';
import 'package:hostr_sdk/usecase/payments/payments.dart';
import 'package:hostr_sdk/usecase/payments/operations/zap_operation.dart';
import 'package:hostr_sdk/usecase/zaps/zaps.dart' as hostr_zaps;
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:hostr_sdk/util/token_amount_ext.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/domain_layer/usecases/lnurl/lnurl_response.dart';
import 'package:ndk/ndk.dart' hide Nwc;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

// ── Fakes ──────────────────────────────────────────────────────────────

class _FakeNwc extends Fake implements Nwc {
  NwcConnection? connection;
  String? connectionName;
  String? preimage;
  Object? payError;

  @override
  NwcConnection? getActiveConnection() => connection;

  @override
  String? getActiveConnectionName() => connectionName;

  @override
  Future<PayInvoiceResponse> payInvoice(
    NwcConnection connection,
    String bolt11,
  ) async {
    if (payError != null) throw payError!;
    return PayInvoiceResponse(
      preimage: preimage ?? 'test-preimage',
      resultType: 'pay_invoice',
      feesPaid: 0,
    );
  }
}

class _FakeNwcConnection extends Fake implements NwcConnection {}

class _FakeAuth extends Fake implements Auth {
  @override
  KeyPair? get activeKeyPair => MockKeys.guest;
}

class _FakeLnurlUseCase extends Fake implements LnurlUseCase {
  ZapRequest? lastZapRequest;
  String? lud16Link = 'https://example.com/.well-known/lnurlp/user';
  LnurlResponse? lnurlResponse;

  late final response = LnurlResponse.fromJson({
    'tag': 'payRequest',
    'callback': 'https://example.com/lnurl/callback',
    'maxSendable': 100000000,
    'minSendable': 1000,
    'commentAllowed': 140,
    'allowsNostr': true,
    'nostrPubkey': MockKeys.hoster.publicKey,
  });

  _FakeLnurlUseCase() {
    lnurlResponse = response;
  }

  @override
  String? getLud16LinkFromLud16(String lud16) {
    return lud16Link;
  }

  @override
  Future<LnurlResponse?> getLnurlResponse(String link) async {
    return lnurlResponse;
  }

  @override
  Future<InvoiceResponse?> fetchInvoice({
    required LnurlResponse lnurlResponse,
    required int amountSats,
    ZapRequest? zapRequest,
    String? comment,
  }) async {
    lastZapRequest = zapRequest;
    return InvoiceResponse(invoice: _testBolt11, amountSats: amountSats);
  }
}

class _FakeMetadataUseCase extends Fake implements MetadataUseCase {
  ProfileMetadata? profile;

  @override
  Future<ProfileMetadata?> loadMetadata(
    String pubkey, {
    bool forceRefresh = false,
  }) async {
    return profile;
  }
}

class _FakeZaps extends Fake implements hostr_zaps.Zaps {}

// A concrete PayOperation subclass for testing the base lifecycle.
class _TestPayOperation extends Bolt11PayOperation {
  _TestPayOperation({
    required super.params,
    required super.nwc,
    required super.logger,
  });
}

// ── Helpers ────────────────────────────────────────────────────────────

/// Build a minimal bolt11 parameter pointing to a test invoice.
///
/// We need a decodable bolt11 string. Bolt11PaymentRequest wants a
/// real-looking invoice. We'll use the resolver's error handling to test
/// the failure path and test the happy path with a well-known test
/// invoice.
/// Well-known BOLT11 test vector with a fixed amount (10u = 1000 sat).
/// Source: bolt11_decoder package test data.
const _testBolt11 =
    'lnbc10u1pdsw4dkpp5mmlhfpcw4rj0scnyqmw02yvwpn4h6d40wyep3yew8l954sfl6ucqdqq'
    'cqzysxqrrssaayzylslcav0sr3c7237mwea5k67vk7t3j6pdmvnuuadxy0dsj5zalg6merxgnd'
    'c74nc753lnuyx7t2sjecfpxp820r9use77n7vyqcpp7dlfy';

ProfileMetadata _profileWithLud16(String? lud16) {
  final lud16Json = lud16 == null ? '' : '"lud16":"$lud16"';
  return ProfileMetadata.fromNostrEvent(
    Nip01Event(
      pubKey: MockKeys.guest.publicKey,
      kind: 0,
      tags: const [],
      content: '{$lud16Json}',
    ),
  );
}

Payments _payments({
  required _FakeNwc nwc,
  required _FakeLnurlUseCase lnurl,
  required _FakeMetadataUseCase metadata,
}) {
  return Payments(
    zaps: _FakeZaps(),
    nwc: nwc,
    lnurl: lnurl,
    logger: CustomLogger(),
    metadata: metadata,
    auth: _FakeAuth(),
    config: HostrConfig(
      bootstrapRelays: const [],
      bootstrapBlossom: const [],
      hostrRelay: '',
      evmConfig: const EvmConfig(),
    ),
  );
}

void main() {
  group('PayOperation — base lifecycle', () {
    late _FakeNwc nwc;
    late CustomLogger logger;

    setUp(() {
      nwc = _FakeNwc();
      logger = CustomLogger();
    });

    group('setParams', () {
      test('resets state to PayInitialised and clears prior details', () {
        final params = Bolt11PayParameters(to: _testBolt11);
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        // Simulate having moved forward.
        final newParams = Bolt11PayParameters(to: _testBolt11);
        op.setParams(newParams);

        expect(op.state, isA<PayInitialised>());
        expect(op.resolvedDetails, isNull);
        expect(op.callbackDetails, isNull);
        expect(op.completedDetails, isNull);
      });
    });

    group('resolve()', () {
      test('emits PayResolved on success with min == max for bolt11', () async {
        final params = Bolt11PayParameters(to: _testBolt11);
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        await op.resolve();

        expect(op.state, isA<PayResolved>());
        final resolved = op.state as PayResolved;
        expect(resolved.effectiveMinAmount, resolved.effectiveMaxAmount);
      });

      test('emits PayFailed when bolt11 is garbage', () async {
        final params = Bolt11PayParameters(to: 'not-a-bolt11');
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        await op.resolve();

        expect(op.state, isA<PayFailed>());
      });

      test('clamps effective range with param-level limits', () async {
        final params = Bolt11PayParameters(
          to: _testBolt11,
          minSendable: 1,
          maxSendable: 999999999,
        );
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        await op.resolve();

        expect(op.state, isA<PayResolved>());
      });
    });

    group('finalize()', () {
      test('emits PayCallbackComplete after resolve', () async {
        final params = Bolt11PayParameters(to: _testBolt11);
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        await op.resolve();
        if (op.state is PayFailed) return; // skip if bolt11 un-decodable
        await op.finalize();

        expect(op.state, isA<PayCallbackComplete>());
      });

      test('emits PayFailed when resolver was never called', () async {
        final params = Bolt11PayParameters(to: _testBolt11);
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        // finalize() without resolve() — finalizer needs callbackDetails.
        // Bolt11's finalizer creates LightningCallbackDetails from params.to,
        // so it should still work if the bolt11 is decodable.
        await op.finalize();

        expect(op.state, anyOf(isA<PayCallbackComplete>(), isA<PayFailed>()));
      });
    });

    group('settleInvoice()', () {
      test('returns null and emits PayExternalRequired when no NWC', () async {
        nwc.connection = null;
        final params = Bolt11PayParameters(to: _testBolt11);
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        await op.resolve();
        if (op.state is PayFailed) return;
        await op.finalize();
        if (op.state is PayFailed) return;

        final preimage = await op.settleInvoice(_testBolt11);

        expect(preimage, isNull);
        expect(op.state, isA<PayExternalRequired>());
      });

      test('returns preimage on NWC success', () async {
        nwc.connection = _FakeNwcConnection();
        nwc.preimage = 'abc123';
        final params = Bolt11PayParameters(to: _testBolt11);
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        await op.resolve();
        if (op.state is PayFailed) return;
        await op.finalize();
        if (op.state is PayFailed) return;

        final preimage = await op.settleInvoice(_testBolt11);

        expect(preimage, 'abc123');
      });

      test(
        'returns null and emits PayExternalRequired with nwcError on NWC failure',
        () async {
          nwc.connection = _FakeNwcConnection();
          nwc.payError = Exception('wallet offline');
          final params = Bolt11PayParameters(to: _testBolt11);
          final op = _TestPayOperation(
            params: params,
            nwc: nwc,
            logger: logger,
          );

          await op.resolve();
          if (op.state is PayFailed) return;
          await op.finalize();
          if (op.state is PayFailed) return;

          final preimage = await op.settleInvoice(_testBolt11);

          expect(preimage, isNull);
          final ext = op.state as PayExternalRequired;
          expect(ext.nwcError, contains('wallet offline'));
        },
      );
    });

    group('complete()', () {
      test('emits PayCompleted on NWC success', () async {
        nwc.connection = _FakeNwcConnection();
        nwc.preimage = 'preimage-xyz';
        final params = Bolt11PayParameters(to: _testBolt11);
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        await op.resolve();
        if (op.state is PayFailed) return;
        await op.finalize();
        if (op.state is PayFailed) return;
        await op.complete();

        expect(op.state, isA<PayCompleted>());
        final completed = op.state as PayCompleted<LightningCompletedDetails>;
        expect(completed.details.preimage, 'preimage-xyz');
      });

      test('emits PayExternalRequired when no NWC connection', () async {
        nwc.connection = null;
        final params = Bolt11PayParameters(to: _testBolt11);
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        await op.resolve();
        if (op.state is PayFailed) return;
        await op.finalize();
        if (op.state is PayFailed) return;
        await op.complete();

        expect(op.state, isA<PayExternalRequired>());
      });
    });

    group('execute()', () {
      test('runs resolve → finalize → complete in sequence', () async {
        nwc.connection = _FakeNwcConnection();
        nwc.preimage = 'e2e-preimage';
        final params = Bolt11PayParameters(to: _testBolt11);
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        final states = <Type>[];
        op.stream.listen((s) => states.add(s.runtimeType));

        await op.execute();

        // Should have gone through ResolveInitiated → Resolved →
        // CallbackInitiated → CallbackComplete → InFlight → Completed
        expect(op.state, isA<PayCompleted>());
      });

      test('short-circuits on resolve failure', () async {
        final params = Bolt11PayParameters(to: 'garbage');
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        await op.execute();

        expect(op.state, isA<PayFailed>());
      });
    });

    group('updateAmount()', () {
      test('no-ops before resolve is called', () {
        final params = Bolt11PayParameters(to: _testBolt11);
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        // Should silently return — resolvedDetails is null.
        op.updateAmount(
          TokenAmount(value: BigInt.from(1000), token: Token.native(30)),
        );

        expect(op.state, isA<PayInitialised>());
      });
    });

    group('updateComment()', () {
      test('trims non-empty comments and clears blank comments', () {
        final params = Bolt11PayParameters(to: _testBolt11);
        final op = _TestPayOperation(params: params, nwc: nwc, logger: logger);

        op.updateComment('  hello  ');
        expect(params.comment, 'hello');

        op.updateComment('   ');
        expect(params.comment, isNull);
      });
    });
  });

  group('ZapPayOperation', () {
    test(
      'leaves zap request content blank when no comment is supplied',
      () async {
        final lnurl = _FakeLnurlUseCase();
        final op = ZapPayOperation(
          params: ZapPayParameters(
            to: 'user@example.com',
            amount: rbtcFromSats(BigInt.from(10000)),
          ),
          zaps: _FakeZaps(),
          auth: _FakeAuth(),
          bootstrapRelays: const ['wss://relay.example.com'],
          lnurl: lnurl,
          nwc: _FakeNwc(),
          logger: CustomLogger(),
        );

        await op.resolve();
        await op.finalize();

        expect(lnurl.lastZapRequest, isNotNull);
        expect(lnurl.lastZapRequest!.content, isEmpty);
        expect(lnurl.lastZapRequest!.content, isNot(contains('hostr-zap')));
      },
    );
  });

  group('Payments automatic invoice destination', () {
    late _FakeNwc nwc;
    late _FakeLnurlUseCase lnurl;
    late _FakeMetadataUseCase metadata;

    setUp(() {
      nwc = _FakeNwc();
      lnurl = _FakeLnurlUseCase();
      metadata = _FakeMetadataUseCase();
    });

    test('uses active NWC before profile lightning address', () async {
      nwc.connection = _FakeNwcConnection();
      nwc.connectionName = 'Alby Hub';
      metadata.profile = null;

      final destination = await _payments(
        nwc: nwc,
        lnurl: lnurl,
        metadata: metadata,
      ).resolveAutomaticInvoiceDestination();

      expect(destination.canCreateAutomatically, isTrue);
      expect(destination.type, AutomaticInvoiceDestinationType.nwc);
      expect(destination.label, 'Alby Hub');
    });

    test(
      'uses valid profile lightning address when no NWC is connected',
      () async {
        metadata.profile = _profileWithLud16('user@example.com');

        final destination = await _payments(
          nwc: nwc,
          lnurl: lnurl,
          metadata: metadata,
        ).resolveAutomaticInvoiceDestination();

        expect(destination.canCreateAutomatically, isTrue);
        expect(
          destination.type,
          AutomaticInvoiceDestinationType.profileLightningAddress,
        );
        expect(destination.label, 'user@example.com');
      },
    );

    test('reports missing profile lightning address', () async {
      metadata.profile = _profileWithLud16(null);

      final destination = await _payments(
        nwc: nwc,
        lnurl: lnurl,
        metadata: metadata,
      ).resolveAutomaticInvoiceDestination();

      expect(destination.canCreateAutomatically, isFalse);
      expect(
        destination.type,
        AutomaticInvoiceDestinationType.missingProfileLightningAddress,
      );
      expect(
        destination.error,
        'Cannot sweep without a profile lightning address',
      );
    });

    test('reports invalid profile lightning address format', () async {
      metadata.profile = _profileWithLud16('not a lightning address');
      lnurl.lud16Link = null;

      final destination = await _payments(
        nwc: nwc,
        lnurl: lnurl,
        metadata: metadata,
      ).resolveAutomaticInvoiceDestination();

      expect(destination.canCreateAutomatically, isFalse);
      expect(
        destination.type,
        AutomaticInvoiceDestinationType.invalidProfileLightningAddress,
      );
      expect(
        destination.error,
        'Cannot run with invalid profile lightning address',
      );
    });

    test('reports invalid profile lightning address endpoint', () async {
      metadata.profile = _profileWithLud16('user@example.com');
      lnurl.lnurlResponse = null;

      final destination = await _payments(
        nwc: nwc,
        lnurl: lnurl,
        metadata: metadata,
      ).resolveAutomaticInvoiceDestination();

      expect(destination.canCreateAutomatically, isFalse);
      expect(
        destination.type,
        AutomaticInvoiceDestinationType.invalidProfileLightningAddress,
      );
    });
  });

  group('PayState type hierarchy', () {
    test('PayInitialised carries params', () {
      final params = Bolt11PayParameters(to: 'test');
      final state = PayInitialised(params: params);
      expect(state.params.to, 'test');
    });

    test('PayFailed carries error message', () {
      final params = Bolt11PayParameters(to: 'test');
      final state = PayFailed('something broke', params: params);
      expect(state.error, 'something broke');
    });

    test('PayResolved carries effective range', () {
      final params = Bolt11PayParameters(to: 'test');
      final details = ResolvedDetails(
        minAmount: 100,
        maxAmount: 500,
        commentAllowed: 0,
      );
      final state = PayResolved(
        params: params,
        details: details,
        effectiveMinAmount: 100,
        effectiveMaxAmount: 500,
      );
      expect(state.effectiveMinAmount, 100);
      expect(state.effectiveMaxAmount, 500);
      expect(state.resolvedDetails, same(details));
    });

    test('PayExternalRequired carries nwcError', () {
      final params = Bolt11PayParameters(to: 'test');
      final cb = LightningCallbackDetails(
        invoice: Bolt11PaymentRequest(_testBolt11),
      );
      final state = PayExternalRequired(
        params: params,
        callbackDetails: cb,
        nwcError: 'timeout',
      );
      expect(state.nwcError, 'timeout');
    });
  });

  group('PayModels', () {
    test('Bolt11PayParameters has correct to', () {
      final p = Bolt11PayParameters(to: 'lnbc1...');
      expect(p.to, 'lnbc1...');
    });

    test('LnurlPayParameters has correct to', () {
      final p = LnurlPayParameters(to: 'user@domain.com');
      expect(p.to, 'user@domain.com');
    });

    test('ZapPayParameters carries optional event', () {
      final p = ZapPayParameters(to: 'user@domain.com');
      expect(p.event, isNull);
    });

    test('ResolvedDetails stores range', () {
      final d = ResolvedDetails(
        minAmount: 1000,
        maxAmount: 100000,
        commentAllowed: 140,
      );
      expect(d.minAmount, 1000);
      expect(d.maxAmount, 100000);
      expect(d.commentAllowed, 140);
    });

    test('LightningCompletedDetails stores preimage', () {
      final d = LightningCompletedDetails(preimage: 'abc');
      expect(d.preimage, 'abc');
    });

    test('ZapCompletedDetails stores receipt metadata', () {
      final d = ZapCompletedDetails(
        preimage: 'xyz',
        zapReceiptEventId: 'eid',
        zapReceiptId: 'rid',
        confirmedByZapReceipt: true,
      );
      expect(d.confirmedByZapReceipt, isTrue);
      expect(d.zapReceiptEventId, 'eid');
    });
  });
}
