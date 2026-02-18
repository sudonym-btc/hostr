import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:provider/single_child_widget.dart';

class DefaultEntityProvider<Type extends Event>
    extends SingleChildStatelessWidget {
  final CrudUseCase<Type> crud;

  /// Provide the kinds that this type is propagated as
  final List<int> kinds;

  /// Provide e if you want to search for a specific event
  final String? e;

  /// Provide a if you want to search for a specific anchor tag
  final String? a;

  /// Provide if you want to search for a specific pubkey
  final String? pubkey;

  final Function(Type)? onDone;

  /// Provide a builder if you want to consume the cubit right away
  final BlocWidgetBuilder<EntityCubitState<Type>>? builder;

  /// Provide a child if you want to consume the cubit later
  final Widget? child;

  DefaultEntityProvider({
    super.key,
    required this.kinds,
    this.e,
    this.pubkey,
    required this.crud,
    this.onDone,
    this.a,
    this.builder,
    this.child,
  }) {
    assert(builder == null || child == null);

    /// e and a cannot be provided at the same time
    assert(e == null || a == null);
    assert(a != null || e != null || pubkey != null);
  }

  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    final Widget? consumer =
        child ??
        this.child ??
        (builder != null
            ? BlocBuilder<EntityCubit<Type>, EntityCubitState<Type>>(
                builder: builder!,
              )
            : null);

    return BlocProvider<EntityCubit<Type>>(
      create: (context) =>
          EntityCubit<Type>(
              filter: Filter(
                kinds: kinds,
                authors: pubkey != null
                    ? [pubkey!]
                    : (a != null ? [getPubKeyFromAnchor(a!)] : null),
                dTags: a != null ? [getDTagFromAnchor(a!)] : null,
                eTags: e != null ? [e!] : null,
              ),
              crud: crud,
            )
            ..get().then((value) {
              if (onDone != null && value != null) {
                onDone!(value);
              }
            }),
      child: consumer,
    );
  }
}
