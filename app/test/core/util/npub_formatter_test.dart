import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/core/util/npub_formatter.dart';

void main() {
  const pubkey =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  test('formatNpub encodes hex pubkeys as npubs', () {
    final npub = formatNpub(pubkey);

    expect(npub, startsWith('npub1'));
    expect(npub, hasLength(63));
  });

  test('formatNpubPreview returns the compact npub prefix', () {
    expect(
      formatNpubPreview(pubkey),
      '${formatNpub(pubkey).substring(0, kNpubPreviewLength)}...',
    );
  });

  test('formatNpubPreview compacts already encoded npubs', () {
    const npub =
        'npub1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqvzpeny';

    expect(formatNpubPreview(npub), 'npub1qqq...');
  });
}
