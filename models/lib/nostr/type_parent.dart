import 'package:ndk/ndk.dart';

import 'event.dart';

abstract class ParentTypeNostrEvent<ChildType extends Event> extends Event {
  final ChildType? child;

  ParentTypeNostrEvent(
      {required super.pubKey,
      required super.kind,
      this.child,
      String? content,
      required super.tags,
      super.sig,
      super.id,
      super.createdAt})
      : super(content: child?.toString() ?? content!) {}

  ParentTypeNostrEvent.fromNostrEvent(
    Nip01Event e, {
    this.child,
  }) : super.fromNostrEvent(e);
}
