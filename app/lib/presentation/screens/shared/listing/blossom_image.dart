import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/ndk.dart';

class BlossomImage extends StatelessWidget {
  final String image;
  final String pubkey;
  const BlossomImage({super.key, required this.image, required this.pubkey});

  bool isSha256(String input) {
    final regex = RegExp(r'^[a-fA-F0-9]{64}$');
    return regex.hasMatch(input);
  }

  bool isNetworkPath(String input) {
    final regex = RegExp(r'^(http|https):\/\/');
    return regex.hasMatch(input);
  }

  @override
  Widget build(BuildContext context) {
    if (isSha256(image)) {
      // Handle SHA-256 hash case
      return FutureBuilder(
          future: getIt<Ndk>()
              .blossomUserServerList
              .getUserServerList(pubkeys: [pubkey]),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            } else {
              return Image.network('${snapshot.data!.first}/$image',
                  fit: BoxFit.cover);
            }
          });
    } else if (isNetworkPath(image)) {
      // Handle network path case
      return Image.network(image, fit: BoxFit.cover);
    } else {
      // Handle invalid image path case
      return const Placeholder();
    }
  }
}
