import 'package:dart_nostr/dart_nostr.dart';

abstract class Event {
  NostrEvent event;
  Event(this.event);
}
