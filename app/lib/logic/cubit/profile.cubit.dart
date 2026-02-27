import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/export.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Metadata, Nip01Event;

/// Cubit responsible for loading and caching a single user's profile metadata.
///
/// **Ownership convention:** This cubit does not hold subscriptions and does
/// not override [close]. It is expected to be created and closed by its owner
/// (typically [ThreadCubit]). Do **not** create instances of this cubit
/// without ensuring the owner will call [close] when done, otherwise the
/// cubit will leak.
class ProfileCubit extends Cubit<EntityCubitState<ProfileMetadata>> {
  final CustomLogger logger = CustomLogger();
  final MetadataUseCase metadataUseCase;

  ProfileCubit({required this.metadataUseCase})
    : super(const EntityCubitState<ProfileMetadata>(data: null));

  ProfileMetadata _fallbackProfile(String pubkey) {
    final event = Nip01Event(
      pubKey: pubkey,
      kind: Metadata.kKind,
      tags: const [],
      content: '{}',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    return ProfileMetadata.fromNostrEvent(event);
  }

  Future<ProfileMetadata?> load(String pubkey) async {
    if (isClosed) return null;
    emit(state.copyWith(active: true));
    try {
      final metadata = await metadataUseCase.loadMetadata(pubkey);
      final resolved = metadata ?? _fallbackProfile(pubkey);
      if (metadata == null) {
        logger.w('Profile metadata missing for $pubkey, using fallback');
      }
      if (isClosed) return resolved;
      emit(EntityCubitState(data: resolved, active: false));
      return resolved;
    } catch (e, stackTrace) {
      logger.e("Error loading profile metadata for $pubkey: $e $stackTrace");
      if (isClosed) return null;
      emit(EntityCubitStateError(data: state.data, error: e));
      return null;
    }
  }
}
