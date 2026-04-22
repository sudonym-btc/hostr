import 'dart:async';

import 'package:blurhash_dart/blurhash_dart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/data/sources/blossom_image_variant.dart';
import 'package:hostr/data/sources/image_preloader.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/ui/image_load_error.dart';
import 'package:hostr/presentation/component/widgets/ui/image_loading_shimmer.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:image/image.dart' as img;
import 'package:models/main.dart';

class BlossomImage extends StatefulWidget {
  final String image;
  final String pubkey;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final AlignmentGeometry? alignment;
  final ImageErrorWidgetBuilder? errorBuilder;
  final List<IMeta> imageMetas;
  final BlossomImageVariantHint variantHint;

  const BlossomImage({
    super.key,
    required this.image,
    required this.pubkey,
    this.height,
    this.width,
    this.fit,
    this.alignment,
    this.errorBuilder,
    this.imageMetas = const [],
    this.variantHint = BlossomImageVariantHint.none,
  });

  @override
  State<BlossomImage> createState() => _BlossomImageState();
}

class _BlossomImageState extends State<BlossomImage> {
  static final _logger = CustomLogger();
  static final Map<String, Uint8List> _blurhashBytes = {};

  static final _sha256Regex = RegExp(r'^[a-fA-F0-9]{64}$');
  static final _networkRegex = RegExp(r'^(http|https):\/\/');
  static const _maxImageLoadRetries = 3;
  static const _maxResolveRetries = 5;
  static const _retryDelay = Duration(milliseconds: 700);

  Future<String?>? _resolveFuture;
  String? _resolveImage;
  String? _resolvePubkey;
  int _resolveAttempt = 0;
  int _imageLoadAttempt = 0;
  Timer? _resolveRetryTimer;
  Timer? _imageRetryTimer;

  bool isSha256(String input) => _sha256Regex.hasMatch(input);

  bool isNetworkPath(String input) => _networkRegex.hasMatch(input);

  @override
  void didUpdateWidget(covariant BlossomImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image != widget.image ||
        oldWidget.pubkey != widget.pubkey ||
        oldWidget.variantHint != widget.variantHint ||
        !listEquals(oldWidget.imageMetas, widget.imageMetas)) {
      _resetLoadState();
    }
  }

  @override
  void dispose() {
    _resolveRetryTimer?.cancel();
    _imageRetryTimer?.cancel();
    super.dispose();
  }

  void _resetLoadState() {
    _resolveFuture = null;
    _resolveImage = null;
    _resolvePubkey = null;
    _resolveAttempt = 0;
    _imageLoadAttempt = 0;
    _resolveRetryTimer?.cancel();
    _resolveRetryTimer = null;
    _imageRetryTimer?.cancel();
    _imageRetryTimer = null;
  }

  Future<String?> _resolveImageRef(ImagePreloader preloader, String imageRef) {
    if (_resolveFuture != null &&
        _resolveImage == imageRef &&
        _resolvePubkey == widget.pubkey) {
      return _resolveFuture!;
    }

    _resolveImage = imageRef;
    _resolvePubkey = widget.pubkey;
    _resolveFuture = preloader.resolveImageRef(imageRef, pubkey: widget.pubkey);
    return _resolveFuture!;
  }

  Widget _error(BuildContext context, Object error, StackTrace? stackTrace) {
    final builder = widget.errorBuilder;
    if (builder != null) return builder(context, error, stackTrace);
    return ImageLoadError(width: widget.width, height: widget.height);
  }

  Widget _networkImage(String url, {String? blurhash}) {
    return Image.network(
      key: ValueKey('$url:$_imageLoadAttempt'),
      url,
      fit: widget.fit ?? BoxFit.cover,
      alignment: widget.alignment ?? Alignment.center,
      width: widget.width,
      height: widget.height,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        final loaded = wasSynchronouslyLoaded || frame != null;
        return SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedOpacity(
                opacity: loaded ? 0 : 1,
                duration: kAnimationDuration,
                curve: kAnimationCurve,
                child: _loadingPlaceholder(blurhash),
              ),
              AnimatedOpacity(
                opacity: loaded ? 1 : 0,
                duration: kAnimationDuration,
                curve: kAnimationCurve,
                child: child,
              ),
            ],
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _networkError(context, url, blurhash, error, stackTrace),
    );
  }

  Widget _networkError(
    BuildContext context,
    String url,
    String? blurhash,
    Object error,
    StackTrace? stackTrace,
  ) {
    if (_imageLoadAttempt < _maxImageLoadRetries) {
      _logger.w(
        'BlossomImage: network load failed for $url; retrying '
        '${_imageLoadAttempt + 1}/$_maxImageLoadRetries',
        error: error,
        stackTrace: stackTrace,
      );
      _scheduleImageRetry();
      return _loadingPlaceholder(blurhash);
    }

    return _error(context, error, stackTrace);
  }

  Widget _loadingPlaceholder(String? blurhash) {
    final preview = _blurhashPreview(blurhash);
    if (preview != null) return preview;
    return ImageLoadingShimmer(width: widget.width, height: widget.height);
  }

  Widget? _blurhashPreview(String? blurhash) {
    if (blurhash == null || blurhash.isEmpty) return null;

    late final Uint8List bytes;
    try {
      bytes = _blurhashBytes.putIfAbsent(blurhash, () {
        final decoded = BlurHash.decode(blurhash).toImage(32, 32);
        return Uint8List.fromList(img.encodePng(decoded));
      });
    } catch (error, stackTrace) {
      _logger.w(
        'BlossomImage: failed to decode blurhash',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }

    return Image.memory(
      bytes,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.cover,
      alignment: widget.alignment ?? Alignment.center,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      errorBuilder: (context, error, stackTrace) =>
          ImageLoadingShimmer(width: widget.width, height: widget.height),
    );
  }

  void _scheduleImageRetry() {
    if (_imageRetryTimer != null) return;
    _imageRetryTimer = Timer(_retryDelay, () {
      if (!mounted) return;
      setState(() {
        _imageRetryTimer = null;
        _imageLoadAttempt += 1;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final preloader = getIt<ImagePreloader>();
    final candidate = BlossomImageVariantResolver.resolve(
      imageRef: widget.image,
      imageMetas: widget.imageMetas,
      hint: widget.variantHint,
    );
    final imageRef = candidate.ref;
    final blurhash = candidate.meta?.blurhash;

    if (isSha256(imageRef)) {
      // Check if the preloader already resolved this hash.
      final cachedUrl = preloader.getResolvedUrl(imageRef, widget.pubkey);
      if (cachedUrl != null) {
        return _networkImage(cachedUrl, blurhash: blurhash);
      }

      // Fall back to resolving via the preloader (caches for next time).
      return FutureBuilder<String?>(
        future: _resolveImageRef(preloader, imageRef),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            if (_resolveAttempt < _maxResolveRetries) {
              _logger.w(
                'BlossomImage: error resolving hash=$imageRef '
                'pubkey=${widget.pubkey}; retrying '
                '${_resolveAttempt + 1}/$_maxResolveRetries',
                error: snapshot.error,
              );
              _scheduleResolveRetry();
              return _loadingPlaceholder(blurhash);
            }

            _logger.e(
              'BlossomImage: failed resolving hash=$imageRef '
              'pubkey=${widget.pubkey}',
              error: snapshot.error,
            );
            return _error(
              context,
              snapshot.error ?? 'Failed to resolve Blossom image',
              snapshot.stackTrace,
            );
          }
          if (snapshot.connectionState != ConnectionState.done ||
              snapshot.data == null) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data == null) {
              if (_resolveAttempt < _maxResolveRetries) {
                _logger.w(
                  'BlossomImage: resolved to null for hash=$imageRef '
                  'pubkey=${widget.pubkey}; retrying '
                  '${_resolveAttempt + 1}/$_maxResolveRetries',
                );
                _scheduleResolveRetry();
                return _loadingPlaceholder(blurhash);
              }

              _logger.w(
                'BlossomImage: resolved to null for hash=$imageRef '
                'pubkey=${widget.pubkey} after $_maxResolveRetries retries — '
                'no blossom servers?',
              );
              return _error(context, 'Blossom image resolved to null', null);
            }
            return _loadingPlaceholder(blurhash);
          }
          _logger.d(
            'BlossomImage: resolved hash=$imageRef to ${snapshot.data}',
          );
          return _networkImage(snapshot.data!, blurhash: blurhash);
        },
      );
    } else if (isNetworkPath(imageRef)) {
      return _networkImage(imageRef, blurhash: blurhash);
    } else {
      _logger.w('BlossomImage: unrecognised image ref format: $imageRef');
      return _error(context, 'Unrecognised image ref format: $imageRef', null);
    }
  }

  void _scheduleResolveRetry() {
    if (_resolveRetryTimer != null) return;
    _resolveRetryTimer = Timer(_retryDelay, () {
      if (!mounted) return;
      setState(() {
        _resolveRetryTimer = null;
        _resolveAttempt += 1;
        _resolveFuture = null;
      });
    });
  }
}
