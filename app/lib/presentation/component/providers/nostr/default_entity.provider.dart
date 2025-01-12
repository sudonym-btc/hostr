import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/main.dart';

abstract class DefaultEntityProvider<Type extends NostrEvent>
    extends StatelessWidget {
  /// Provide the kinds that this type is propagated as
  final List<int> kinds;

  /// Provide e if you want to search for a specific event
  final String? e;

  /// Provide a if you want to search for a specific anchor tag
  final String? a;

  /// Provide a builder if you want to consume the cubit right away
  final BlocWidgetBuilder<EntityCubitState<Type>>? builder;

  /// Provide a child if you want to consume the cubit later
  final Widget? child;

  DefaultEntityProvider(
      {super.key,
      required this.kinds,
      this.e,
      this.a,
      this.builder,
      this.child}) {
    /// A builder or a child must be provided
    assert(builder != null || child != null);
    assert(builder == null || child == null);

    /// e and a cannot be provided at the same time
    assert(e == null || a == null);
    assert(e != null || a != null);
  }

  @override
  Widget build(BuildContext context) {
    Widget consumer = child != null
        ? child!
        : BlocBuilder<EntityCubit<Type>, EntityCubitState<Type>>(
            builder: builder!);

    return BlocProvider<EntityCubit<Type>>(
        create: (context) => EntityCubit<Type>(
            filter: NostrFilter(
                kinds: kinds,
                a: a != null ? [a!] : null,
                e: e != null ? [e!] : null))
          ..get(),
        child: consumer);
  }
}
