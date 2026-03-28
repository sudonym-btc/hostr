import 'package:models/main.dart';

import '../entity_factory.dart';
import '../seed_context.dart';
import '../seed_pipeline_models.dart';

/// Stage 2: Build kind-0 profile metadata events for all users.
///
/// Also builds the static escrow service profile.

// ─── Profile building ───────────────────────────────────────────────────────

Future<List<ProfileMetadata>> buildProfiles({
  required SeedContext ctx,
  required List<SeedUser> users,
  EntityFactory? factory,
}) async {
  final f = factory ?? EntityFactory(ctx: ctx);
  return Future.wait(
    users.map((user) async {
      final identSeed = user.index + ctx.seed;
      final role = user.isHost ? 'host' : 'guest';
      final idx = user.index + 1;
      return f.profile(
        signer: user.keyPair,
        seed: identSeed,
        isHost: user.isHost,
        lud16: '$role$idx@lnbits.hostr.development',
        nip05: '$role$idx@lnbits.hostr.development',
        hasEvm: user.hasEvm,
        createdAt: ctx.timestampDaysAfter(user.index + 1),
      );
    }),
  );
}

Future<ProfileMetadata> buildEscrowProfile({
  required SeedContext ctx,
  EntityFactory? factory,
}) async {
  final f = factory ?? EntityFactory(ctx: ctx);
  return f.escrowProfile(
    createdAt: ctx.baseDate.millisecondsSinceEpoch ~/ 1000,
  );
}

// ─── Escrow trust / method lists ────────────────────────────────────────────

Future<List<EscrowService>> buildEscrowServices({
  required String contractAddress,
  required String multiEscrowBytecodeHash,
  EntityFactory? factory,
}) async {
  final f = factory ?? EntityFactory();
  return f.escrowServices(
    contractAddress: contractAddress,
    multiEscrowBytecodeHash: multiEscrowBytecodeHash,
  );
}

Future<List<EscrowMethod>> buildEscrowMethods({
  required SeedContext ctx,
  required List<SeedUser> users,
  required String multiEscrowBytecodeHash,
  required int chainId,
  String? tbtcAddress,
  String? usdtAddress,
  EntityFactory? factory,
}) async {
  final f = factory ?? EntityFactory(ctx: ctx);
  final methods = <EscrowMethod>[];
  for (final user in users) {
    methods.add(
      await f.escrowMethod(
        signer: user.keyPair,
        multiEscrowBytecodeHash: multiEscrowBytecodeHash,
        chainId: chainId,
        tbtcAddress: tbtcAddress,
        usdtAddress: usdtAddress,
        createdAt: ctx.baseDate.millisecondsSinceEpoch ~/ 1000,
      ),
    );
  }
  return methods;
}
