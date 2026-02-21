import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class EscrowSelectorCubit extends Cubit<EscrowSelectorState> {
  final ReservationRequest reservationRequest;
  final ProfileMetadata counterparty;
  final Function(EscrowService) onDone;
  EscrowSelectorCubit({
    required this.reservationRequest,
    required this.counterparty,
    required this.onDone,
  }) : super(EscrowSelectorLoading());

  void load() async {
    emit(EscrowSelectorLoading());
    try {
      // Load mutual escrows
      final escrows = await getIt<Hostr>().escrows.determineMutualEscrow(
        getIt<Hostr>().auth.activeKeyPair!.publicKey,
        counterparty.pubKey,
      );

      if (escrows.compatibleServices.isEmpty) {
        emit(EscrowSelectorError('No mutual escrows found'));
        return;
      }

      // Select the first mutual escrow by default
      final selectedEscrow = escrows.compatibleServices[0];

      emit(
        EscrowSelectorLoaded(selectedEscrow: selectedEscrow, result: escrows),
      );
    } catch (e, stackTrace) {
      print(stackTrace);
      emit(EscrowSelectorError('Failed to load escrows'));
    }
  }

  Future<void> select() async {
    if (state is EscrowSelectorLoaded &&
        (state as EscrowSelectorLoaded).selectedEscrow != null) {
      final loadedState = state as EscrowSelectorLoaded;
      await getIt<Hostr>()
          .messaging
          .threads
          .threads[reservationRequest.getDtag()!]!
          .replyEvent(
            EscrowServiceSelected(
              pubKey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
              tags: EscrowServiceSelectedTags([]),
              content: EscrowServiceSelectedContent(
                service: loadedState.selectedEscrow!,
                sellerTrusts: loadedState.result.hostTrust!,
                sellerMethods: loadedState.result.hostMethod!,
              ),
            ),
          );
      onDone(loadedState.selectedEscrow!);
    }
  }
}

class EscrowSelectorState {}

class EscrowSelectorLoading extends EscrowSelectorState {}

class EscrowSelectorLoaded extends EscrowSelectorState {
  EscrowService? selectedEscrow;
  MutualEscrowResult result;
  EscrowSelectorLoaded({required this.selectedEscrow, required this.result});
}

class EscrowSelectorError extends EscrowSelectorState {
  final String message;
  EscrowSelectorError(this.message);
}
