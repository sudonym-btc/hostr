import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:provider/single_child_widget.dart';

/// Provides the user's [ProfileMetadata] and automatically refreshes
/// whenever [MetadataUseCase.updates] fires (e.g. after an edit).
class ProfileProvider extends SingleChildStatefulWidget {
  final String pubkey;
  final Function(BuildContext context, AsyncSnapshot<ProfileMetadata?> profile)?
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
  late Future<ProfileMetadata?> _future;
  StreamSubscription? _updatesSub;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _updatesSub = getIt<Hostr>().metadata.updates.listen((_) {
      if (mounted) {
        setState(() {
          _future = _load();
        });
      }
    });
  }

  Future<ProfileMetadata?> _load() {
    return getIt<Hostr>().metadata.loadMetadata(widget.pubkey).then((m) {
      widget.onDone?.call(m);
      return m;
    });
  }

  @override
  void didUpdateWidget(ProfileProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pubkey != widget.pubkey) {
      setState(() {
        _future = _load();
      });
    }
  }

  @override
  void dispose() {
    _updatesSub?.cancel();
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
