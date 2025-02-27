import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_chip.dart';

class ReviewListItem extends StatelessWidget {
  final Review review;

  const ReviewListItem({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(review.content),
      subtitle: Row(children: [
        ProfileChipWidget(id: review.nip01Event.pubKey),
        // ZapListWidget(
        //     pubkey: review.anchor, builder: (e) => ZapReceiptWidget(zap: e))
      ]),
    );
  }
}
