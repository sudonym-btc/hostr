import 'package:ndk/ndk.dart';

import 'event.dart';

abstract class ParentTypeNostrEvent<ChildType extends Event> extends Event {
  final ChildType? child;

  ParentTypeNostrEvent.fromNostrEvent(
    Nip01Event e, {
    this.child,
  }) : super.fromNostrEvent(e);
}
