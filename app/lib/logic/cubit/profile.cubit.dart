import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/export.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class ProfileCubit extends Cubit<EntityCubitState<ProfileMetadata>> {
  final CustomLogger logger = CustomLogger();
  final MetadataUseCase metadataUseCase;

  ProfileCubit({required this.metadataUseCase})
    : super(const EntityCubitState<ProfileMetadata>(data: null));

  Future<ProfileMetadata?> load(String pubkey) async {
    emit(state.copyWith(active: true));
    try {
      final metadata = await metadataUseCase.loadMetadata(pubkey);
      if (metadata == null) {
        logger.w('Profile metadata missing for $pubkey');
      }
      emit(EntityCubitState(data: metadata, active: false));
      return metadata;
    } catch (e, stackTrace) {
      logger.e("Error loading profile metadata for $pubkey: $e $stackTrace");
      emit(EntityCubitStateError(data: state.data, error: e));
      return null;
    }
  }
}
