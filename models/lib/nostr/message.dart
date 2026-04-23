import 'dart:convert';
import 'dart:core';

import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import '../nostr_parser.dart';
import 'event.dart';
import 'type_parent.dart';

class MessageTags extends EventTags with ReferencesThread<MessageTags> {
  MessageTags(super.tags);
}

abstract class Message<T extends Event>
    extends ParentTypeNostrEvent<T, MessageTags> {
  static const List<int> kinds = [kNostrKindDM, kNostrKindJsonMessage];
  static final EventTagsParser<MessageTags> _tagParser = MessageTags.new;

  factory Message({
    required String pubKey,
    required MessageTags tags,
    T? child,
    String? content,
    int? createdAt,
    String? id,
    String? sig,
  }) {
    if (child != null) {
      return JsonMessage<T>(
        pubKey: pubKey,
        tags: tags,
        child: child,
        content: content,
        createdAt: createdAt,
        id: id,
        sig: sig,
      );
    }
    return TextMessage(
      pubKey: pubKey,
      tags: tags,
      content: content ?? '',
      createdAt: createdAt,
      id: id,
      sig: sig,
    ) as Message<T>;
  }

  Message._({
    required String pubKey,
    required int kind,
    required MessageTags tags,
    T? child,
    String? content,
    int? createdAt,
    String? id,
    String? sig,
  }) : super(
          pubKey: pubKey,
          kind: kind,
          tags: tags,
          child: child,
          content: content,
          createdAt: createdAt,
          id: id,
          sig: sig,
          tagParser: _tagParser,
        );

  factory Message.fromNostrEvent(Nip01Event e, T? child) {
    if (child != null || JsonMessage.kinds.contains(e.kind)) {
      return JsonMessage<T>.fromNostrEvent(e, child);
    }
    return TextMessage.fromNostrEvent(e) as Message<T>;
  }

  Message._fromNostrEvent(Nip01Event e, {T? child})
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          child: child,
        );

  static Event? parseChild(Nip01Event e) {
    try {
      return parser(Nip01EventModel.fromJson(jsonDecode(e.content)));
    } catch (e) {
      // Only sometimes is the message content meant to be of JSON type
      // print(e);
      // print('error parsing message child event');
      return null;
    }
  }

  static Message<Event> safeParse(Nip01Event e) {
    final child = parseChild(e);
    if (child != null || JsonMessage.kinds.contains(e.kind)) {
      return JsonMessage<Event>.fromNostrEvent(e, child);
    }
    return TextMessage.fromNostrEvent(e);
  }
}

class TextMessage extends Message<Event> {
  static const List<int> kinds = [kNostrKindDM];

  TextMessage({
    required String pubKey,
    required MessageTags tags,
    required String content,
    int? createdAt,
    String? id,
    String? sig,
  }) : super._(
          pubKey: pubKey,
          tags: tags,
          content: content,
          createdAt: createdAt,
          id: id,
          sig: sig,
          kind: kNostrKindDM,
        );

  TextMessage.fromNostrEvent(Nip01Event e) : super._fromNostrEvent(e);
}

class JsonMessage<T extends Event> extends Message<T> {
  static const List<int> kinds = [kNostrKindJsonMessage];

  JsonMessage({
    required String pubKey,
    required MessageTags tags,
    required T child,
    String? content,
    int? createdAt,
    String? id,
    String? sig,
  }) : super._(
          pubKey: pubKey,
          tags: tags,
          child: child,
          content: content,
          createdAt: createdAt,
          id: id,
          sig: sig,
          kind: kNostrKindJsonMessage,
        );

  JsonMessage.fromNostrEvent(Nip01Event e, T? child)
      : super._fromNostrEvent(e, child: child);

  static JsonMessage<Event> safeParse(Nip01Event e) =>
      JsonMessage<Event>.fromNostrEvent(e, Message.parseChild(e));
}
