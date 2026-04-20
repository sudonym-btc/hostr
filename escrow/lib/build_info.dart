import 'dart:io';

const _commitShaDefine = String.fromEnvironment('COMMIT_SHA');
const _buildDateDefine = String.fromEnvironment('BUILD_DATE');

String _firstNonEmpty(List<String?> values, String fallback) {
  for (final value in values) {
    if (value != null && value.isNotEmpty) return value;
  }
  return fallback;
}

/// Build metadata for the escrow daemon and CLI.
class BuildInfo {
  static String get commitSha => _firstNonEmpty(
        [_commitShaDefine, Platform.environment['COMMIT_SHA']],
        'dev',
      );

  static String get buildDate => _firstNonEmpty(
        [_buildDateDefine, Platform.environment['BUILD_DATE']],
        '',
      );

  static String get label =>
      buildDate.isEmpty ? commitSha : 'Build $buildDate · $commitSha';
}
