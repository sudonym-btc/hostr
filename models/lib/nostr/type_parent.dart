import 'package:ndk/ndk.dart';

import 'event.dart';

abstract class ParentTypeNostrEvent<ChildType extends Event,
    TagsType extends EventTags> extends Event<TagsType> {
  final ChildType? child;

  ParentTypeNostrEvent(
      {required super.pubKey,
      required super.kind,
      required super.tagParser,
      this.child,
      String? content,
      required super.tags,
      super.sig,
      super.id,
      super.createdAt})
      : super(content: child?.toString() ?? content!) {}

  ParentTypeNostrEvent.fromNostrEvent(
    Nip01Event e, {
    required super.tagParser,
    this.child,
  }) : super.fromNostrEvent(e);
}
