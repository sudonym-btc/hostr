import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class EscrowSelectorCubit extends Cubit<EscrowSelectorState> {
  final Reservation negotiateReservation;
  final ProfileMetadata counterparty;
  EscrowSelectorCubit({
    required this.negotiateReservation,
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
        debugPrint(
          'EscrowSelectorCubit.load: no compatible escrows. '
          'buyer=${getIt<Hostr>().auth.activeKeyPair!.publicKey} '
          'seller=${counterparty.pubKey} '
          'buyerMethod=${escrows.buyerMethod?.id} '
          'buyerTrusted=${escrows.buyerMethod?.trustedEscrowPubkeys} '
          'buyerHashes=${escrows.buyerMethod?.supportedContractBytecodeHashes} '
          'sellerMethod=${escrows.sellerMethod?.id} '
          'sellerTrusted=${escrows.sellerMethod?.trustedEscrowPubkeys} '
          'sellerHashes=${escrows.sellerMethod?.supportedContractBytecodeHashes}',
        );
        emit(EscrowSelectorError('No mutual escrows found'));
        return;
      }

      // Select the first mutual escrow by default
      final selectedEscrow = escrows.compatibleServices[0];

      emit(
        EscrowSelectorLoaded(selectedEscrow: selectedEscrow, result: escrows),
      );
    } catch (e, stackTrace) {
      debugPrint('$e\n$stackTrace');
      emit(EscrowSelectorError('Failed to load escrows'));
    }
  }

  void changeSelection(EscrowService escrow) {
    if (state is EscrowSelectorLoaded) {
      final loaded = state as EscrowSelectorLoaded;
      if (loaded.selectedEscrow?.pubKey == escrow.pubKey) return;
      emit(EscrowSelectorLoaded(selectedEscrow: escrow, result: loaded.result));
    }
  }

  Future<EscrowServiceSelected?> select() async {
    if (state is EscrowSelectorLoaded &&
        (state as EscrowSelectorLoaded).selectedEscrow != null) {
      final loadedState = state as EscrowSelectorLoaded;
      final tradeId = negotiateReservation.getDtag()!;
      final selected = EscrowServiceSelected(
        pubKey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
        tags: EscrowServiceSelectedTags([]),
        content: EscrowServiceSelectedContent(
          service: loadedState.selectedEscrow!,
          sellerMethods: loadedState.result.sellerMethod!,
        ),
      );
      final participants = {
        negotiateReservation.pubKey,
        ...negotiateReservation.parsedTags.getTags('p'),
      };
      final threads = getIt<Hostr>().messaging.threads;
      final thread =
          threads.findTradeThread(
            tradeId: tradeId,
            participants: participants,
          ) ??
          _findThreadByTradeIdAndReservation(threads, tradeId);
      if (thread == null) {
        final matches = threads.findByConversationTag(tradeId);
        debugPrint(
          'EscrowSelectorCubit.select: no thread found for '
          'tradeId=$tradeId participants=$participants '
          'candidateCount=${matches.length}',
        );
        return selected;
      }
      await thread.replyEventAndWait(selected);
      return selected;
    }
    return null;
  }

  Thread? _findThreadByTradeIdAndReservation(Threads threads, String tradeId) {
    final matches = threads.findByConversationTag(tradeId);
    if (matches.isEmpty) return null;

    for (final thread in matches) {
      final requests = thread.state.value.reservationRequests;
      if (requests.any((request) => request.id == negotiateReservation.id)) {
        return thread;
      }
    }

    final reservationMatches = matches
        .where(
          (thread) => thread.state.value.reservationRequests.any(
            (request) => request.getDtag() == tradeId,
          ),
        )
        .toList(growable: false);
    if (reservationMatches.length == 1) return reservationMatches.single;
    if (matches.length == 1) return matches.single;
    return null;
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
