import 'package:ndk/ndk.dart';

import 'event.dart';

abstract class ParentTypeNostrEvent<ChildType extends Event,
    TagsType extends EventTags> extends Event<TagsType> {
  final ChildType? child;

  ParentTypeNostrEvent(
      {required String pubKey,
      required int kind,
      required EventTagsParser<TagsType> tagParser,
      this.child,
      String? content,
      required TagsType tags,
      String? sig,
      String? id,
      int? createdAt})
      : super(
          pubKey: pubKey,
          kind: kind,
          tagParser: tagParser,
          content: child?.toString() ?? content!,
          tags: tags,
          sig: sig,
          id: id,
          createdAt: createdAt,
        ) {}

  ParentTypeNostrEvent.fromNostrEvent(
    Nip01Event e, {
    required super.tagParser,
    this.child,
  }) : super.fromNostrEvent(e);
}
