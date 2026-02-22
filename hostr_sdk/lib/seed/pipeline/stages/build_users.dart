import '../seed_context.dart';
import '../seed_pipeline_config.dart';
import '../seed_pipeline_models.dart';

/// Stage 1: Generate [SeedUser] objects with deterministic key pairs.
///
/// Respects global population settings from [SeedPipelineConfig] and
/// appends any [SeedUserSpec] overrides at the end.
List<SeedUser> buildUsers({
  required SeedContext ctx,
  required SeedPipelineConfig config,
}) {
  final users = <SeedUser>[];

  // ── Global random users ──
  final hostCount = ctx
      .countByRatio(config.userCount, config.hostRatio)
      .clamp(
        config.userCount > 1 ? 1 : 0,
        config.userCount > 1 ? config.userCount - 1 : 0,
      );

  for (var i = 0; i < config.userCount; i++) {
    final isHost = i < hostCount;
    final hasEvm = isHost && ctx.pickByRatio(config.hostHasEvmRatio);
    users.add(
      SeedUser(
        index: i,
        keyPair: ctx.deriveKeyPair(i),
        isHost: isHost,
        hasEvm: hasEvm,
        setupLnbits: config.setupLnbits,
      ),
    );
  }

  // ── Per-user overrides ──
  for (var o = 0; o < config.userOverrides.length; o++) {
    final spec = config.userOverrides[o];
    final index = config.userCount + o;
    users.add(
      SeedUser(
        index: index,
        keyPair: ctx.deriveKeyPair(index),
        isHost: spec.role == UserRole.host,
        hasEvm: spec.hasEvm,
        setupLnbits: spec.setupLnbits,
        spec: spec,
      ),
    );
  }

  return users;
}
