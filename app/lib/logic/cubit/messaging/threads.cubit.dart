import 'package:hostr/data/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:models/nostr/message.dart';

class ThreadsCubit extends HydratedCubit<List<Message>> {
  final Hostr nostrService;
  final List<Message> messages = [];

  ThreadsCubit(this.nostrService) : super([]);

  void sync() {
    nostrService.messaging.threads.populateMessages(messages);
    nostrService.messaging.threads.sync();
  }

  void stop() {
    nostrService.messaging.threads.stop();
  }

  @override
  Future<void> close() async {
    stop();
    return super.close();
  }

  @override
  List<Message> fromJson(Map<String, dynamic> json) {
    return json['messages'].map(Message.safeFromNostrEvent).toList<Message>();
  }

  @override
  Map<String, dynamic>? toJson(List<Message> state) {
    return {'messages': state.map((message) => message.toString()).toList()};
  }
}
