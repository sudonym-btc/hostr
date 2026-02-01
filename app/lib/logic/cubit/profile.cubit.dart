import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/metadata/metadata.dart';
import 'package:models/main.dart';

class ProfileCubit extends Cubit<ProfileCubitState> {
  final MetadataUseCase metadataUseCase;

  ProfileCubit({required this.metadataUseCase})
    : super(const ProfileCubitState(data: null));

  Future<ProfileMetadata?> load(String pubkey) async {
    emit(state.copyWith(active: true));
    try {
      final metadata = await metadataUseCase.loadMetadata(pubkey);
      emit(ProfileCubitState(data: metadata, active: false));
      return metadata;
    } catch (e) {
      emit(ProfileCubitStateError(data: state.data, error: e));
      return null;
    }
  }
}

class ProfileCubitState extends Equatable {
  final ProfileMetadata? data;
  final bool active;

  const ProfileCubitState({required this.data, this.active = false});

  ProfileCubitState copyWith({ProfileMetadata? data, bool? active}) =>
      ProfileCubitState(data: data ?? this.data, active: active ?? this.active);

  @override
  List<Object?> get props => [data, active];
}

class ProfileCubitStateError extends ProfileCubitState {
  final dynamic error;
  const ProfileCubitStateError({required super.data, required this.error});
}
