import 'pay_models.dart';

class PayState {
  final PayParameters params;
  final ResolvedDetails? resolvedDetails;
  final CallbackDetails? callbackDetails;
  PayState({required this.params, this.resolvedDetails, this.callbackDetails});

  String get stateName => 'unknown';

  Map<String, Object?> toJson() => {
    'state': stateName,
    'params': params.toJson(),
    if (resolvedDetails != null) 'resolvedDetails': resolvedDetails!.toJson(),
    if (callbackDetails != null) 'callbackDetails': callbackDetails!.toJson(),
  };
}

class PayInitialised extends PayState {
  PayInitialised({required super.params});

  @override
  String get stateName => 'initialised';
}

class PayResolveInitiated extends PayState {
  PayResolveInitiated({required super.params});

  @override
  String get stateName => 'resolveInitiated';
}

class PayResolved<T extends ResolvedDetails> extends PayState {
  final T details;
  final int effectiveMinAmount;
  final int effectiveMaxAmount;
  PayResolved({
    required super.params,
    required this.details,
    required this.effectiveMinAmount,
    required this.effectiveMaxAmount,
  }) : super(resolvedDetails: details);

  @override
  String get stateName => 'resolved';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'details': details.toJson(),
    'effectiveMinAmount': effectiveMinAmount,
    'effectiveMaxAmount': effectiveMaxAmount,
  };
}

class PayCallbackInitiated extends PayState {
  PayCallbackInitiated({required super.params});

  @override
  String get stateName => 'callbackInitiated';
}

class PayCallbackComplete<T extends CallbackDetails> extends PayState {
  final T details;
  PayCallbackComplete({required super.params, required this.details})
    : super(callbackDetails: details);

  @override
  String get stateName => 'callbackComplete';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'details': details.toJson(),
  };
}

class PayInFlight extends PayState {
  PayInFlight({required super.params});

  @override
  String get stateName => 'inFlight';
}

class PayExternalRequired<T extends CallbackDetails> extends PayState {
  /// If NWC was attempted but failed, this contains the error.
  final String? nwcError;
  PayExternalRequired({
    required super.params,
    required super.callbackDetails,
    this.nwcError,
  });

  @override
  String get stateName => 'externalRequired';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    if (nwcError != null) 'nwcError': nwcError,
  };
}

class PayCancelled extends PayState {
  PayCancelled({required super.params});

  @override
  String get stateName => 'cancelled';
}

class PayExpired extends PayState {
  PayExpired({required super.params});

  @override
  String get stateName => 'expired';
}

class PayCompleted<T extends CompletedDetails> extends PayState {
  final T details;
  PayCompleted({required super.params, required this.details});

  @override
  String get stateName => 'completed';

  @override
  Map<String, Object?> toJson() => {
    ...super.toJson(),
    'details': details.toJson(),
  };
}

class PayFailed extends PayState {
  final String error;
  PayFailed(this.error, {required super.params});

  @override
  String get stateName => 'failed';

  @override
  Map<String, Object?> toJson() => {...super.toJson(), 'error': error};
}
