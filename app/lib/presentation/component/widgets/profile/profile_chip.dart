import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';
import 'package:hostr/presentation/layout/app_layout.dart';

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
        final name = snapshot.data?.metadata.name ?? id.substring(0, 8);
        final picture = snapshot.data?.metadata.picture;

        return AnimatedSize(
          duration: kAnimationDuration,
          curve: kAnimationCurve,
          alignment: alignment,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: AppSurface(
              steps: 2,
              shape: StadiumBorder(
                side: BorderSide(
                  color: AppSurface.stepped(context, 3),
                  width: 1,
                ),
              ),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: () => ProfilePopup.show(context, id),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: AppSpacing.of(context).xxs,
                    right: AppSpacing.of(context).xs,
                    top: AppSpacing.of(context).xxs,
                    bottom: AppSpacing.of(context).xxs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppAvatar.xxs(
                        image: picture,
                        pubkey: id,
                        label: snapshot.data?.metadata.getName() ?? '?',
                      ),
                      Gap.horizontal.xxs(),
                      Flexible(
                        child: Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          softWrap: false,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
