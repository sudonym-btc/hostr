/// Inline media metadata for Nostr `imeta` tags.
///
/// NIP-92 stores media hints as `["imeta", "url ...", "m ...", ...]`,
/// reusing the NIP-94 field names for file metadata.
class IMeta {
  final String url;
  final String? mime;
  final String? sha256;
  final String? originalSha256;
  final int? size;
  final String? dimensions;
  final String? blurhash;
  final String? thumbnail;
  final String? image;
  final String? alt;
  final List<String> fallback;

  const IMeta({
    required this.url,
    this.mime,
    this.sha256,
    this.originalSha256,
    this.size,
    this.dimensions,
    this.blurhash,
    this.thumbnail,
    this.image,
    this.alt,
    this.fallback = const [],
  });

  factory IMeta.fromTag(List<String> tag) {
    final values = <String, List<String>>{};
    for (final entry in tag.skip(1)) {
      final space = entry.indexOf(' ');
      if (space <= 0) continue;
      final key = entry.substring(0, space);
      final value = entry.substring(space + 1);
      values.putIfAbsent(key, () => []).add(value);
    }

    String? first(String key) {
      final entries = values[key];
      return entries == null || entries.isEmpty ? null : entries.first;
    }

    return IMeta(
      url: first('url') ?? '',
      mime: first('m'),
      sha256: first('x'),
      originalSha256: first('ox'),
      size: int.tryParse(first('size') ?? ''),
      dimensions: first('dim'),
      blurhash: first('blurhash'),
      thumbnail: first('thumb'),
      image: first('image'),
      alt: first('alt'),
      fallback: List.unmodifiable(values['fallback'] ?? const []),
    );
  }

  List<String> toTag() {
    return [
      'imeta',
      'url $url',
      if (mime != null && mime!.isNotEmpty) 'm $mime',
      if (sha256 != null && sha256!.isNotEmpty) 'x $sha256',
      if (originalSha256 != null && originalSha256!.isNotEmpty)
        'ox $originalSha256',
      if (size != null) 'size $size',
      if (dimensions != null && dimensions!.isNotEmpty) 'dim $dimensions',
      if (blurhash != null && blurhash!.isNotEmpty) 'blurhash $blurhash',
      if (thumbnail != null && thumbnail!.isNotEmpty) 'thumb $thumbnail',
      if (image != null && image!.isNotEmpty) 'image $image',
      if (alt != null && alt!.isNotEmpty) 'alt $alt',
      ...fallback.where((url) => url.isNotEmpty).map((url) => 'fallback $url'),
    ];
  }

  List<String> toImageTag() {
    return [
      'image',
      url,
      if (dimensions != null && dimensions!.isNotEmpty) dimensions!,
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IMeta &&
          other.url == url &&
          other.mime == mime &&
          other.sha256 == sha256 &&
          other.originalSha256 == originalSha256 &&
          other.size == size &&
          other.dimensions == dimensions &&
          other.blurhash == blurhash &&
          other.thumbnail == thumbnail &&
          other.image == image &&
          other.alt == alt &&
          _listEquals(other.fallback, fallback);

  @override
  int get hashCode => Object.hash(
        url,
        mime,
        sha256,
        originalSha256,
        size,
        dimensions,
        blurhash,
        thumbnail,
        image,
        alt,
        Object.hashAll(fallback),
      );

  static bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
