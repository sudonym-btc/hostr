import 'pay_models.dart';

class PayState {
  final PayParameters params;
  final ResolvedDetails? resolvedDetails;
  final CallbackDetails? callbackDetails;
  PayState({required this.params, this.resolvedDetails, this.callbackDetails});
}

class PayInitialised extends PayState {
  PayInitialised({required super.params});
}

class PayResolveInitiated extends PayState {
  PayResolveInitiated({required super.params});
}

class PayResolved<T extends ResolvedDetails> extends PayState {
  final T details;
  PayResolved({required super.params, required this.details})
    : super(resolvedDetails: details);
}

class PayCallbackInitiated extends PayState {
  PayCallbackInitiated({required super.params});
}

class PayCallbackComplete<T extends CallbackDetails> extends PayState {
  final T details;
  PayCallbackComplete({required super.params, required this.details})
    : super(callbackDetails: details);
}

class PayInFlight extends PayState {
  PayInFlight({required super.params});
}

class PayCancelled extends PayState {
  PayCancelled({required super.params});
}

class PayExpired extends PayState {
  PayExpired({required super.params});
}

class PayCompleted<T extends CompletedDetails> extends PayState {
  final T details;
  PayCompleted({required super.params, required this.details});
}

class PayFailed extends PayState {
  final String error;
  PayFailed(this.error, {required super.params});
}
