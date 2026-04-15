import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';

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
      key: ValueKey(id),
      pubkey: id,
      builder: (context, snapshot) {
        final name = snapshot.data?.metadata.name ?? id.substring(0, 8);
        final picture = snapshot.data?.metadata.picture;

        return AnimatedSize(
          duration: kAnimationDuration,
          curve: kAnimationCurve,
          alignment: alignment,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: () => ProfilePopup.show(context, id),
              child: AppChip.neutral.sm(
                label: Text(name, overflow: TextOverflow.ellipsis),
                avatar: AppAvatar.xxs(
                  image: picture,
                  pubkey: id,
                  label: snapshot.data?.metadata.getName() ?? '?',
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
