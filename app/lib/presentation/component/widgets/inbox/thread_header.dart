import 'package:flutter/material.dart';

class ThreadHeaderWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? image;
  final Widget? trailing;
  const ThreadHeaderWidget(
      {super.key,
      required this.title,
      required this.subtitle,
      this.image,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: image != null ? NetworkImage(image!) : null,
        child: image == null ? Text(title[0]) : null,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
    );
  }
}
