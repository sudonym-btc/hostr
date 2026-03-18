/// Composable seed pipeline for deterministic test data generation.
///
/// Use [SeedFactory] for pure-data generation (no I/O, no network).
/// Use [Seeder] + [SeedSink] for the full pipeline with outcome resolution.
/// Use [TestSeedHelper] for surgical per-entity test helpers.
/// Use [TestSink] for in-memory tests (no Docker, no chain).
/// Use [InfrastructureSink] for real infrastructure (CLI relay-seeder).
library;

export 'pipeline/fake/fake_escrow_ledger.dart';
export 'pipeline/fake/fake_identity_registry.dart';
export 'pipeline/seed_context.dart';
export 'pipeline/seed_factory.dart';
export 'pipeline/seed_pipeline_config.dart';
export 'pipeline/seed_pipeline_models.dart';
export 'pipeline/seeder.dart';
export 'pipeline/sink/infrastructure_sink.dart';
export 'pipeline/sink/seed_sink.dart';
export 'pipeline/sink/test_sink.dart';
export 'pipeline/test_seed_helper.dart';
export 'relay_seed.dart';
