import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_chip.dart';
import 'package:models/main.dart';

class ReviewListItem extends StatelessWidget {
  final Review review;

  const ReviewListItem({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text(review.content),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        ProfileChipWidget(id: review.nip01Event.pubKey),
        // ZapListWidget(
        //     pubkey: review.anchor, builder: (e) => ZapReceiptWidget(zap: e))
      ])
    ]);
  }
}
