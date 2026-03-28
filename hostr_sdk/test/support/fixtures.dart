/// Test fixture entry point.
///
/// Re-exports the seed pipeline and model stubs so test files need a single
/// import for fixture generation.
///
/// ```dart
/// import '../../support/fixtures.dart';
///
/// final seeds = TestSeedHelper();
/// final host = await seeds.freshHost();
/// final listing = host.listing;
/// ```
export 'package:hostr_sdk/seed/seed.dart'
    show
        SeedFactory,
        SeedPipelineConfig,
        SeedThread,
        SeedUser,
        SeedUserSpec,
        TestGuest,
        TestHost,
        TestSeedHelper,
        TestTrade,
        ThreadStageSpec;
export 'package:models/stubs/main.dart' show MockKeys;
