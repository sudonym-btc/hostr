import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';

class ThreadMessageWidget extends StatelessWidget {
  final String counterpartyPubkey;
  final GiftWrap<Seal<Message>> item;

  const ThreadMessageWidget(
      {super.key, required this.counterpartyPubkey, required this.item});

  @override
  Widget build(BuildContext context) {
    bool isSentByMe = item.child.pubkey == counterpartyPubkey;

    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.all(10),
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        decoration: BoxDecoration(
          color: isSentByMe ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          item.child.child.content!,
          style: TextStyle(
            color: isSentByMe ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
