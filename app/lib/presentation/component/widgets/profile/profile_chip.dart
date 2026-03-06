import 'package:flutter/material.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';

class ProfileChipWidget extends StatelessWidget {
  final String id;
  final AlignmentGeometry alignment;

  const ProfileChipWidget({
    super.key,
    required this.id,
    this.alignment = Alignment.centerLeft,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileProvider(
      pubkey: id,
      builder: (context, snapshot) {
        final name = snapshot.data?.metadata.name ?? id;
        final picture = snapshot.data?.metadata.picture;

        return AnimatedSize(
          duration: kAnimationDuration,
          curve: kAnimationCurve,
          alignment: alignment,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: GestureDetector(
              onTap: () => ProfilePopup.show(context, id),
              child: Chip(
                shape: const StadiumBorder(),
                avatar: picture != null
                    ? CircleAvatar(
                        child: ClipOval(
                          child: BlossomImage(
                            image: picture,
                            pubkey: id,
                            width: 32,
                            height: 32,
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : CircleAvatar(backgroundColor: Colors.grey),
                label: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
