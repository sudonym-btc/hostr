class PayState {}

class PayInitialised extends PayState {}

class PayResolveInitiated extends PayState {}

class PayResolved extends PayState {}

class PayCallbackInitiated extends PayState {}

class PayCallbackComplete extends PayState {}

class PayInFlight extends PayState {}

class PayCancelled extends PayState {}

class PayExpired extends PayState {}

class PayCompleted extends PayState {}

class PayFailed extends PayState {
  final String error;
  PayFailed(this.error);
}
