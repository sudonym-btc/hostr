import 'package:injectable/injectable.dart';

import 'pay_models.dart';
import 'pay_state.dart';

abstract class PayOperation<
  T extends PayParameters,
  RD extends ResolvedDetails,
  CD extends CallbackDetails,
  CmpD extends CompletedDetails
> {
  final T params;
  RD? resolvedDetails;
  CD? callbackDetails;
  CmpD? completedDetails;
  PayOperation({@factoryParam required this.params});
  Future<RD> resolve();
  Future<CD> callback();
  Stream<PayState> execute();
}
