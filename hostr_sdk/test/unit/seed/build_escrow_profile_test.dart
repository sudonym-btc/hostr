import 'package:hostr_sdk/seed/pipeline/seed_factory.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_config.dart';
import 'package:test/test.dart';

void main() {
  group('buildEscrowProfile', () {
    test('uses configured name + picture', () async {
      final factory = SeedFactory(
        config: const SeedPipelineConfig(
          escrowProfileName: 'Hostr Escrow',
          escrowProfilePicture: 'https://example.com/logo.png',
          userCount: 0,
        ),
      );

      final profile = await factory.buildEscrowProfile();
      final metadata = profile.metadata;

      expect(metadata.name, 'Hostr Escrow');
      expect(metadata.displayName, 'Hostr Escrow');
      expect(metadata.picture, 'https://example.com/logo.png');
      expect(
        profile.tags.where(
          (tag) => tag.length >= 2 && tag[0] == 'i' && tag[1] == 'evm:address',
        ),
        isEmpty,
      );
    });
  });
}
