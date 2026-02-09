import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:models/main.dart';

class ThreadMessageWidget extends StatelessWidget {
  final ProfileMetadata counterparty;
  final Message item;

  bool get isSentByMe => item.pubKey == counterparty.pubKey;

  const ThreadMessageWidget({
    super.key,
    required this.counterparty,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: CustomPadding(
        top: 0.2,
        bottom: 0.2,
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSentByMe
                ? Theme.of(context).primaryColorDark
                : Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            item.content,
            style: TextStyle(color: isSentByMe ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}
