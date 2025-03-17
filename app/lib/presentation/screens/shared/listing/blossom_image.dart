import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/ndk.dart';

class BlossomImage extends StatelessWidget {
  final String image;
  final String pubkey;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final AlignmentGeometry? alignment;
  const BlossomImage(
      {super.key,
      required this.image,
      required this.pubkey,
      this.height,
      this.width,
      this.fit,
      this.alignment});

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
              return Image.network(
                '${snapshot.data!.first}/$image',
                fit: fit ?? BoxFit.cover,
                alignment: alignment ?? Alignment.center,
                width: width,
                height: height,
              );
            }
          });
    } else if (isNetworkPath(image)) {
      // Handle network path case
      return Image.network(
        image,
        fit: fit ?? BoxFit.cover,
        alignment: alignment ?? Alignment.center,
        width: width,
        height: height,
      );
    } else {
      // Handle invalid image path case
      return const Placeholder();
    }
  }
}
