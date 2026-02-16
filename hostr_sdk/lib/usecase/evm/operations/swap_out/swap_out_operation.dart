import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../util/main.dart';
import '../../../auth/auth.dart';
import 'swap_out_models.dart';
import 'swap_out_state.dart';

abstract class SwapOutOperation extends Cubit<SwapOutState> {
  final CustomLogger logger;
  final Auth auth;
  final SwapOutParams params;

  SwapOutOperation({
    required this.auth,
    required this.logger,
    @factoryParam required this.params,
  }) : super(SwapOutInitialised());

  Future<SwapOutFees> estimateFees();
  Future<void> execute();
}
