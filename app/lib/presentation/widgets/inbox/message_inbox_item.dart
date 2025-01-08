// import 'package:dart_nostr/dart_nostr.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:hostr/data/main.dart';
// import 'package:hostr/injection.dart';
// import 'package:hostr/logic/main.dart';

// class MessageInboxItem extends StatelessWidget {
//   MessageType0 thread;
//   MessageInboxItem({super.key, required this.thread});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider<ListCubit>(
//         create: (_) =>
//             ListCubit(getIt<MessageRepository>())..setFilter(NostrFilter()),
//         child:
//             BlocBuilder<ListCubit, ListCubitState>(builder: (context, state) {
//           return ListTile(
//               leading: Icon(Icons.search),
//               title: Text('Where?'),
//               subtitle: Text('When?'),
//               trailing: null);
//         }));
//   }
// }
