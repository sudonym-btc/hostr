import 'package:flutter/material.dart';
import 'package:hostr/data/sources/image_preloader.dart';
import 'package:hostr/injection.dart';

class BlossomImage extends StatelessWidget {
  final String image;
  final String pubkey;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final AlignmentGeometry? alignment;
  const BlossomImage({
    super.key,
    required this.image,
    required this.pubkey,
    this.height,
    this.width,
    this.fit,
    this.alignment,
  });

  static final _sha256Regex = RegExp(r'^[a-fA-F0-9]{64}$');
  static final _networkRegex = RegExp(r'^(http|https):\/\/');

  bool isSha256(String input) => _sha256Regex.hasMatch(input);

  bool isNetworkPath(String input) => _networkRegex.hasMatch(input);

  Widget _networkImage(String url) {
    return Image.network(
      url,
      fit: fit ?? BoxFit.cover,
      alignment: alignment ?? Alignment.center,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) => const Placeholder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preloader = getIt<ImagePreloader>();

    if (isSha256(image)) {
      // Check if the preloader already resolved this hash.
      final cachedUrl = preloader.getResolvedUrl(image, pubkey);
      if (cachedUrl != null) {
        return _networkImage(cachedUrl);
      }

      // Fall back to resolving via the preloader (caches for next time).
      return FutureBuilder<String?>(
        future: preloader.resolveImageRef(image, pubkey: pubkey),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done ||
              snapshot.data == null) {
            return SizedBox(
              width: width,
              height: height,
              child: const Center(child: CircularProgressIndicator()),
            );
          }
          return _networkImage(snapshot.data!);
        },
      );
    } else if (isNetworkPath(image)) {
      return _networkImage(image);
    } else {
      return const Placeholder();
    }
  }
}
