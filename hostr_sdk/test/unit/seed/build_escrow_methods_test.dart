@Tags(['unit'])
library;

import 'package:hostr_sdk/seed/pipeline/seed_factory.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_config.dart';
import 'package:hostr_sdk/seed/pipeline/seeder.dart';
import 'package:hostr_sdk/seed/pipeline/sink/test_sink.dart';
import 'package:models/stubs/main.dart' show MockKeys;
import 'package:test/test.dart';

void main() {
  group('buildEscrowMethods', () {
    test(
      'declares trusted escrow, scoped payment forms, and created_at',
      () async {
        final factory = SeedFactory(
          config: const SeedPipelineConfig(
            seed: 77,
            userCount: 0,
            tbtcAddress: '0x948b3c65b89DF0B4894ABE91E6D02FE579834F8F',
            usdtAddress: '0x712516e61C8B383dF4A63CFe83d7701Bce54B03e',
            userOverrides: [SeedUserSpec.host(listingCount: 0)],
          ),
        );
        final users = factory.buildUsers();

        final methods = await factory.buildEscrowMethods(
          users,
          createdAt: 1770000000,
        );

        final method = methods.single;
        expect(method.createdAt, 1770000000);
        expect(
          method.trustedEscrowPubkeys,
          contains(MockKeys.escrow.publicKey),
        );
        expect(method.supportedContractBytecodeHashes, isNotEmpty);
        expect(method.acceptedPaymentForms, isNotEmpty);
        expect(method.evmAddress, startsWith('0x'));
        expect(method.evmAddressProof, startsWith('0x'));
        expect(method.acceptedPaymentForms.map((form) => form.appId).toSet(), {
          'hostr',
        });
      },
    );

    test(
      'full seeder publishes replacement escrow methods at run time',
      () async {
        final now = DateTime.utc(2026, 1, 1, 12);
        final seeder = Seeder(
          config: const SeedPipelineConfig(
            seed: 99,
            userCount: 0,
            tbtcAddress: '0x948b3c65b89DF0B4894ABE91E6D02FE579834F8F',
            usdtAddress: '0x712516e61C8B383dF4A63CFe83d7701Bce54B03e',
            userOverrides: [SeedUserSpec.host(listingCount: 0)],
          ),
        );

        final data = await seeder.seed(TestSink(), now: now);

        final method = data.escrowMethods.single;
        expect(method.createdAt, now.millisecondsSinceEpoch ~/ 1000);
        expect(
          method.trustedEscrowPubkeys,
          contains(MockKeys.escrow.publicKey),
        );
      },
    );
  });
}
