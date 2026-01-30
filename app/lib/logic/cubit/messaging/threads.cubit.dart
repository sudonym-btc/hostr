import 'package:hostr/data/main.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:models/nostr/message.dart';

class ThreadsCubit extends HydratedCubit<List<Message>> {
  final Threads threads;
  final List<Message> messages = [];

  ThreadsCubit(this.threads) : super([]);

  void sync() {
    threads.populateMessages(messages);
    threads.sync();
  }

  void stop() {
    threads.stop();
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
