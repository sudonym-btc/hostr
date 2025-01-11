import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/data/models/nostr_kind/event.dart';

abstract class ParentTypeNostrEvent<ChildType extends NostrEvent>
    extends Event {
  final ChildType child;

  const ParentTypeNostrEvent(
      {required this.child,
      required super.content,
      required super.createdAt,
      required super.id,
      required super.kind,
      required super.pubkey,
      required super.sig,
      required super.tags});
}
