import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';

class ProfileChipWidget extends StatelessWidget {
  final String id;

  const ProfileChipWidget({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ProfileProvider(
      pubkey: id,
      builder: (context, snapshot) {
        var name = snapshot.data?.metadata.name ?? id;
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 200,
          ), // Set your desired max width here
          child: GestureDetector(
            onTap: () => ProfilePopup.show(context, id),
            child: Chip(
              shape: StadiumBorder(),
              avatar: snapshot.data?.metadata.picture != null
                  ? CircleAvatar(
                      child: ClipOval(
                        child: BlossomImage(
                          image: snapshot.data!.metadata.picture!,
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
        );
      },
    );
  }
}
