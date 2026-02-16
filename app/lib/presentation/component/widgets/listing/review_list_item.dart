import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:models/main.dart';

class ReviewListItem extends StatelessWidget {
  final Review review;

  const ReviewListItem({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            ProfileChipWidget(id: review.pubKey),
            // ZapListWidget(
            //     pubkey: review.anchor, builder: (e) => ZapReceiptWidget(zap: e))
          ],
        ),
        SizedBox(height: 4),

        MessageContainer(
          isSentByMe: false,
          child: Text(review.parsedContent.content),
        ),
        SizedBox(height: 4),
        Text(
          formatDate(
            DateTime.fromMillisecondsSinceEpoch(review.createdAt * 1000),
          ),
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
