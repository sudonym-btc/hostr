import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/data/models/main.dart';
import 'package:injectable/injectable.dart';

import 'base.repository.dart';

abstract class MessageRepository extends BaseRepository<MessageType> {
  MessageRepository() : super() {
    creator = (NostrEvent event) {
      return MessageType.fromNostrEvent(event);
    };
  }
}

@Injectable(as: MessageRepository)
class ProdMessageRepository extends MessageRepository {}
