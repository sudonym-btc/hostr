import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:provider/single_child_widget.dart';
import 'package:rxdart/rxdart.dart';

/// Provides the user's [ProfileMetadata] and automatically refreshes
/// whenever [MetadataUseCase.updates] fires (e.g. after an edit).
class ProfileProvider extends SingleChildStatefulWidget {
  final String pubkey;
  final Widget Function(
    BuildContext context,
    AsyncSnapshot<ProfileMetadata?> profile,
  )?
  builder;
  final Function(ProfileMetadata? metadata)? onDone;

  const ProfileProvider({
    super.key,
    required this.pubkey,
    this.builder,
    this.onDone,
  });

  @override
  State<ProfileProvider> createState() => _ProfileProviderState();
}

class _ProfileProviderState extends SingleChildState<ProfileProvider> {
  static final _logger = CustomLogger(tag: 'app.profile-provider');
  late Future<ProfileMetadata?> _future;
  StreamSubscription? _updatesSub;
  StreamSubscription? _relaySub;
  Set<String>? _knownRelayUrls;
  bool _hasLoaded = false;
  ProfileMetadata? _lastMetadata;

  @override
  void initState() {
    super.initState();
    _future = _load();
    final hostr = getIt<Hostr>();

    _updatesSub = hostr.metadata.updates.listen((updatedProfile) {
      if (!mounted) return;
      if (updatedProfile.pubKey == widget.pubkey) {
        _hasLoaded = true;
        _lastMetadata = updatedProfile;
        widget.onDone?.call(updatedProfile);
        setState(() {
          _future = Future.value(updatedProfile);
        });
      }
    });

    // When a new relay connects, force-refresh the profile in case
    // a newer version exists on that relay.
    _relaySub = hostr.relays
        .connectivity()
        .debounceTime(const Duration(seconds: 2))
        .listen((relays) {
          final urls = relays.keys.toSet();
          if (_knownRelayUrls != null &&
              urls.difference(_knownRelayUrls!).isNotEmpty) {
            if (!mounted) return;
            if (!_shouldRefreshAfterRelayChange()) {
              _knownRelayUrls = urls;
              return;
            }
            setState(() {
              _future = _refreshNip65ThenLoad();
            });
          }
          _knownRelayUrls = urls;
        });
  }

  Future<ProfileMetadata?> _load({bool forceRefresh = false}) {
    return getIt<Hostr>().metadata
        .loadMetadata(widget.pubkey, forceRefresh: forceRefresh)
        .then((m) {
          _hasLoaded = true;
          _lastMetadata = m;
          if (m == null) {
            _logger.w(
              'Profile metadata missing for ${widget.pubkey}'
              ' (forceRefresh=$forceRefresh)',
            );
          }
          widget.onDone?.call(m);
          return m;
        })
        .catchError((error, stackTrace) {
          _logger.e(
            'Profile metadata load failed for ${widget.pubkey}'
            ' (forceRefresh=$forceRefresh)',
            error: error,
            stackTrace: stackTrace,
          );
          throw error;
        });
  }

  /// Refreshes the NIP-65 relay list so the JIT engine discovers the
  /// pubkey's write relays, then force-refreshes the profile metadata.
  Future<ProfileMetadata?> _refreshNip65ThenLoad() async {
    return _load(forceRefresh: true);
  }

  bool _shouldRefreshAfterRelayChange() {
    return _hasLoaded && _lastMetadata == null;
  }

  @override
  void didUpdateWidget(ProfileProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pubkey != widget.pubkey) {
      _hasLoaded = false;
      _lastMetadata = null;
      setState(() {
        _future = _load();
      });
    }
  }

  @override
  void dispose() {
    unawaited(_updatesSub?.cancel());
    unawaited(_relaySub?.cancel());
    super.dispose();
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return FutureBuilder<ProfileMetadata?>(
      future: _future,
      builder: (context, snapshot) {
        return widget.builder != null
            ? widget.builder!(context, snapshot)
            : child ?? const SizedBox.shrink();
      },
    );
  }
}
