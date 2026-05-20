import 'package:ndk/ndk.dart' show Nip19;

const int kNpubPreviewLength = 8;

String formatNpub(String pubkey) {
  final normalized = pubkey.trim();
  if (normalized.isEmpty || Nip19.isPubkey(normalized)) return normalized;

  try {
    return Nip19.encodePubKey(normalized);
  } catch (_) {
    return normalized;
  }
}

String formatNpubPreview(String pubkey, {int length = kNpubPreviewLength}) {
  final npub = formatNpub(pubkey);
  if (length <= 0 || npub.length <= length) return npub;
  return '${npub.substring(0, length)}...';
}
