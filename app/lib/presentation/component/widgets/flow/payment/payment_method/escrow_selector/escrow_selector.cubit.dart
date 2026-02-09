import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrows/escrows.dart';
import 'package:models/main.dart';

class EscrowSelectorCubit extends Cubit<EscrowSelectorState> {
  ReservationRequest reservationRequest;
  ProfileMetadata counterparty;
  EscrowSelectorCubit({
    required this.reservationRequest,
    required this.counterparty,
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
      emit(EscrowSelectorError('Failed to load escrows: $e'));
    }
  }
}

class EscrowSelectorState {}

class EscrowSelectorLoading extends EscrowSelectorState {}

class EscrowSelectorLoaded extends EscrowSelectorState {
  EscrowService selectedEscrow;
  MutualEscrowResult result;
  EscrowSelectorLoaded({required this.selectedEscrow, required this.result});
}

class EscrowSelectorError extends EscrowSelectorState {
  final String message;
  EscrowSelectorError(this.message);
}
