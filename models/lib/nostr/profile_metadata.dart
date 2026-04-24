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
