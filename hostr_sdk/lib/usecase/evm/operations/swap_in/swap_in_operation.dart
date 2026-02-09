import 'package:injectable/injectable.dart';

import '../../../../util/main.dart';
import '../../../auth/auth.dart';
import 'swap_in_models.dart';
import 'swap_in_state.dart';

abstract class SwapInOperation {
  final CustomLogger logger = CustomLogger();
  final Auth auth;
  final SwapInParams params;

  SwapInOperation({required this.auth, @factoryParam required this.params});

  Future<BitcoinAmount> estimateFees();
  Stream<SwapInState> execute();
}
