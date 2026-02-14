import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../util/main.dart';
import '../../../auth/auth.dart';
import 'swap_in_models.dart';
import 'swap_in_state.dart';

abstract class SwapInOperation extends Cubit<SwapInState> {
  final CustomLogger logger;
  final Auth auth;
  final SwapInParams params;

  SwapInOperation({
    required this.auth,
    required this.logger,
    @factoryParam required this.params,
  }) : super(SwapInInitialised());

  Future<SwapInFees> estimateFees();
  Future<void> execute();
}
