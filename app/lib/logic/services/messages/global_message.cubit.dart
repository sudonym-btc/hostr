import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:injectable/injectable.dart';

@singleton
class GlobalMessageCubit extends ListCubit<NostrEvent> {
  GlobalMessageCubit() : super(kinds: [NOSTR_KIND_GIFT_WRAP]);
}
