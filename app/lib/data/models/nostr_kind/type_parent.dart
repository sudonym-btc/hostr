import 'event.dart';

abstract class ParentTypeNostrEvent<ChildType extends Event> extends Event {
  final ChildType child;

  ParentTypeNostrEvent(
    super.nip01Event, {
    required this.child,
  });
}
