import 'swap.cubit.dart';

class SwapOutCubit extends SwapCubit {}

class SwapOutCubitStateRefunding extends SwapCubitState {}

class SwapOutCubitStateRefundingCollaborative
    extends SwapOutCubitStateRefunding {}

class SwapOutCubitStateRefundingCollaborativeFailed
    extends SwapOutCubitStateRefunding {}

class SwapOutCubitStateRefundingCollaborativeSucceeded
    extends SwapOutCubitStateRefunding {}

class SwapOutCubitStateRefundingFailed extends SwapOutCubitStateRefunding {}
