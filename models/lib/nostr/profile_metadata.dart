import 'package:ndk/ndk.dart';

import 'event.dart';
import 'imeta.dart';

class ProfileMetadata extends Event {
  static const List<int> kinds = [Metadata.kKind];
  static final EventTagsParser<EventTags> _tagParser = EventTags.new;

  ProfileMetadata.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(e, tagParser: _tagParser);

  Metadata get metadata => Metadata.fromEvent(this);

  List<IMeta> get imageMetas => tags
      .where((tag) => tag.isNotEmpty && tag.first == 'imeta')
      .map(IMeta.fromTag)
      .where((meta) => meta.url.isNotEmpty)
      .toList();

  IMeta? get pictureIMeta {
    final picture = metadata.picture;
    if (picture == null || picture.isEmpty) return null;
    for (final meta in imageMetas) {
      if (meta.url == picture) return meta;
    }
    return null;
  }

  String? get evmAddress {
    return this
        .tags
        .firstWhere((tag) => tag[0] == 'i' && tag[1] == 'evm:address')[2];
  }

  /// Returns a new [ProfileMetadata] with the EVM address tag set.
  ///
  /// This reconstructs the underlying event so the id is recomputed.
  /// Mutating tags in-place would leave the `late final` id stale,
  /// causing relays to reject the event with "invalid id".
  ProfileMetadata withEvmAddress(String address) {
    final updatedTags = List<List<String>>.from(
      tags.where((t) => !(t[0] == 'i' && t[1] == 'evm:address')),
    )..add(['i', 'evm:address', address]);

    // Construct without id so Nip01Event auto-computes it from the new tags.
    final rebuilt = Nip01Event(
      pubKey: pubKey,
      kind: kind,
      tags: updatedTags,
      content: content,
      createdAt: createdAt,
    );
    return ProfileMetadata.fromNostrEvent(rebuilt);
  }

  ProfileMetadata withImageMetas(Iterable<IMeta> metas) {
    final updatedTags = List<List<String>>.from(
      tags.where((tag) => tag.isEmpty || tag.first != 'imeta'),
    )..addAll(metas.where((meta) => meta.url.isNotEmpty).map((m) => m.toTag()));

    final rebuilt = Nip01Event(
      pubKey: pubKey,
      kind: kind,
      tags: updatedTags,
      content: content,
      createdAt: createdAt,
    );
    return ProfileMetadata.fromNostrEvent(rebuilt);
  }
}
