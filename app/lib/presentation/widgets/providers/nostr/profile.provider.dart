import 'package:dart_nostr/nostr/model/request/filter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/models/nostr_kind/profile.dart';
import 'package:hostr/logic/cubit/entity/entity.cubit.dart';

class ProfileProvider extends StatelessWidget {
  final String id;
  final BlocWidgetBuilder<EntityCubitState<Profile>> builder;
  const ProfileProvider({super.key, required this.id, required this.builder});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EntityCubit<Profile>>(
        create: (context) => EntityCubit<Profile>(
            filter: NostrFilter(kinds: Profile.kinds, p: [id]))
          ..get(),
        child: BlocBuilder<EntityCubit<Profile>, EntityCubitState<Profile>>(
            builder: builder));
  }
}
