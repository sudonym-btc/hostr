// Mocks generated by Mockito 5.4.5 from annotations
// in hostr/mocks/main.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i9;

import 'package:flutter_bloc/flutter_bloc.dart' as _i10;
import 'package:hostr/core/main.dart' as _i2;
import 'package:hostr/data/main.dart' as _i6;
import 'package:hostr/data/sources/local/secure_storage.dart' as _i3;
import 'package:hostr/logic/cubit/nwc.cubit.dart' as _i5;
import 'package:hostr/logic/services/nwc.dart' as _i4;
import 'package:mockito/mockito.dart' as _i1;
import 'package:ndk/ndk.dart' as _i7;
import 'package:ndk/shared/nips/nip01/key_pair.dart' as _i8;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeCustomLogger_0 extends _i1.SmartFake implements _i2.CustomLogger {
  _FakeCustomLogger_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeSecureStorage_1 extends _i1.SmartFake implements _i3.SecureStorage {
  _FakeSecureStorage_1(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeNwcService_2 extends _i1.SmartFake implements _i4.NwcService {
  _FakeNwcService_2(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeNwcCubitState_3 extends _i1.SmartFake implements _i5.NwcCubitState {
  _FakeNwcCubitState_3(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeKeyStorage_4 extends _i1.SmartFake implements _i6.KeyStorage {
  _FakeKeyStorage_4(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeNwcStorage_5 extends _i1.SmartFake implements _i6.NwcStorage {
  _FakeNwcStorage_5(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeNdk_6 extends _i1.SmartFake implements _i7.Ndk {
  _FakeNdk_6(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeGetInfoResponse_7 extends _i1.SmartFake
    implements _i7.GetInfoResponse {
  _FakeGetInfoResponse_7(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakePayInvoiceResponse_8 extends _i1.SmartFake
    implements _i7.PayInvoiceResponse {
  _FakePayInvoiceResponse_8(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeMakeInvoiceResponse_9 extends _i1.SmartFake
    implements _i7.MakeInvoiceResponse {
  _FakeMakeInvoiceResponse_9(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

/// A class which mocks [KeyStorage].
///
/// See the documentation for Mockito's code generation for more information.
class MockKeyStorage extends _i1.Mock implements _i6.KeyStorage {
  MockKeyStorage() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.CustomLogger get logger => (super.noSuchMethod(
        Invocation.getter(#logger),
        returnValue: _FakeCustomLogger_0(
          this,
          Invocation.getter(#logger),
        ),
      ) as _i2.CustomLogger);

  @override
  set logger(_i2.CustomLogger? _logger) => super.noSuchMethod(
        Invocation.setter(
          #logger,
          _logger,
        ),
        returnValueForMissingStub: null,
      );

  @override
  set keyPair(_i8.KeyPair? _keyPair) => super.noSuchMethod(
        Invocation.setter(
          #keyPair,
          _keyPair,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i9.Future<_i8.KeyPair?> getActiveKeyPair() => (super.noSuchMethod(
        Invocation.method(
          #getActiveKeyPair,
          [],
        ),
        returnValue: _i9.Future<_i8.KeyPair?>.value(),
      ) as _i9.Future<_i8.KeyPair?>);

  @override
  dynamic set(String? item) => super.noSuchMethod(Invocation.method(
        #set,
        [item],
      ));
}

/// A class which mocks [NwcStorage].
///
/// See the documentation for Mockito's code generation for more information.
class MockNwcStorage extends _i1.Mock implements _i6.NwcStorage {
  MockNwcStorage() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.SecureStorage get storage => (super.noSuchMethod(
        Invocation.getter(#storage),
        returnValue: _FakeSecureStorage_1(
          this,
          Invocation.getter(#storage),
        ),
      ) as _i3.SecureStorage);

  @override
  set storage(_i3.SecureStorage? _storage) => super.noSuchMethod(
        Invocation.setter(
          #storage,
          _storage,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i2.CustomLogger get logger => (super.noSuchMethod(
        Invocation.getter(#logger),
        returnValue: _FakeCustomLogger_0(
          this,
          Invocation.getter(#logger),
        ),
      ) as _i2.CustomLogger);

  @override
  set logger(_i2.CustomLogger? _logger) => super.noSuchMethod(
        Invocation.setter(
          #logger,
          _logger,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i9.Future<List<dynamic>> get() => (super.noSuchMethod(
        Invocation.method(
          #get,
          [],
        ),
        returnValue: _i9.Future<List<dynamic>>.value(<dynamic>[]),
      ) as _i9.Future<List<dynamic>>);

  @override
  _i9.Future<Uri?> getUri() => (super.noSuchMethod(
        Invocation.method(
          #getUri,
          [],
        ),
        returnValue: _i9.Future<Uri?>.value(),
      ) as _i9.Future<Uri?>);

  @override
  dynamic set(List<String>? items) => super.noSuchMethod(Invocation.method(
        #set,
        [items],
      ));
}

/// A class which mocks [NwcCubit].
///
/// See the documentation for Mockito's code generation for more information.
class MockNwcCubit extends _i1.Mock implements _i5.NwcCubit {
  MockNwcCubit() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.CustomLogger get logger => (super.noSuchMethod(
        Invocation.getter(#logger),
        returnValue: _FakeCustomLogger_0(
          this,
          Invocation.getter(#logger),
        ),
      ) as _i2.CustomLogger);

  @override
  set logger(_i2.CustomLogger? _logger) => super.noSuchMethod(
        Invocation.setter(
          #logger,
          _logger,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i4.NwcService get nwcService => (super.noSuchMethod(
        Invocation.getter(#nwcService),
        returnValue: _FakeNwcService_2(
          this,
          Invocation.getter(#nwcService),
        ),
      ) as _i4.NwcService);

  @override
  set nwcService(_i4.NwcService? _nwcService) => super.noSuchMethod(
        Invocation.setter(
          #nwcService,
          _nwcService,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i5.NwcCubitState get state => (super.noSuchMethod(
        Invocation.getter(#state),
        returnValue: _FakeNwcCubitState_3(
          this,
          Invocation.getter(#state),
        ),
      ) as _i5.NwcCubitState);

  @override
  _i9.Stream<_i5.NwcCubitState> get stream => (super.noSuchMethod(
        Invocation.getter(#stream),
        returnValue: _i9.Stream<_i5.NwcCubitState>.empty(),
      ) as _i9.Stream<_i5.NwcCubitState>);

  @override
  bool get isClosed => (super.noSuchMethod(
        Invocation.getter(#isClosed),
        returnValue: false,
      ) as bool);

  @override
  _i9.Future<dynamic> connect(String? str) => (super.noSuchMethod(
        Invocation.method(
          #connect,
          [str],
        ),
        returnValue: _i9.Future<dynamic>.value(),
      ) as _i9.Future<dynamic>);

  @override
  _i9.Future<dynamic> checkInfo() => (super.noSuchMethod(
        Invocation.method(
          #checkInfo,
          [],
        ),
        returnValue: _i9.Future<dynamic>.value(),
      ) as _i9.Future<dynamic>);

  @override
  void emit(_i5.NwcCubitState? state) => super.noSuchMethod(
        Invocation.method(
          #emit,
          [state],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void onChange(_i10.Change<_i5.NwcCubitState>? change) => super.noSuchMethod(
        Invocation.method(
          #onChange,
          [change],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void addError(
    Object? error, [
    StackTrace? stackTrace,
  ]) =>
      super.noSuchMethod(
        Invocation.method(
          #addError,
          [
            error,
            stackTrace,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  void onError(
    Object? error,
    StackTrace? stackTrace,
  ) =>
      super.noSuchMethod(
        Invocation.method(
          #onError,
          [
            error,
            stackTrace,
          ],
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i9.Future<void> close() => (super.noSuchMethod(
        Invocation.method(
          #close,
          [],
        ),
        returnValue: _i9.Future<void>.value(),
        returnValueForMissingStub: _i9.Future<void>.value(),
      ) as _i9.Future<void>);
}

/// A class which mocks [NwcService].
///
/// See the documentation for Mockito's code generation for more information.
class MockNwcService extends _i1.Mock implements _i4.NwcService {
  MockNwcService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.CustomLogger get logger => (super.noSuchMethod(
        Invocation.getter(#logger),
        returnValue: _FakeCustomLogger_0(
          this,
          Invocation.getter(#logger),
        ),
      ) as _i2.CustomLogger);

  @override
  set logger(_i2.CustomLogger? _logger) => super.noSuchMethod(
        Invocation.setter(
          #logger,
          _logger,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.KeyStorage get keyStorage => (super.noSuchMethod(
        Invocation.getter(#keyStorage),
        returnValue: _FakeKeyStorage_4(
          this,
          Invocation.getter(#keyStorage),
        ),
      ) as _i6.KeyStorage);

  @override
  set keyStorage(_i6.KeyStorage? _keyStorage) => super.noSuchMethod(
        Invocation.setter(
          #keyStorage,
          _keyStorage,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i6.NwcStorage get nwcStorage => (super.noSuchMethod(
        Invocation.getter(#nwcStorage),
        returnValue: _FakeNwcStorage_5(
          this,
          Invocation.getter(#nwcStorage),
        ),
      ) as _i6.NwcStorage);

  @override
  set nwcStorage(_i6.NwcStorage? _nwcStorage) => super.noSuchMethod(
        Invocation.setter(
          #nwcStorage,
          _nwcStorage,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i7.Ndk get nostr => (super.noSuchMethod(
        Invocation.getter(#nostr),
        returnValue: _FakeNdk_6(
          this,
          Invocation.getter(#nostr),
        ),
      ) as _i7.Ndk);

  @override
  set nostr(_i7.Ndk? _nostr) => super.noSuchMethod(
        Invocation.setter(
          #nostr,
          _nostr,
        ),
        returnValueForMissingStub: null,
      );

  @override
  dynamic save(String? uri) => super.noSuchMethod(Invocation.method(
        #save,
        [uri],
      ));

  @override
  _i9.Future<_i7.GetInfoResponse> getInfo(String? nwc) => (super.noSuchMethod(
        Invocation.method(
          #getInfo,
          [nwc],
        ),
        returnValue:
            _i9.Future<_i7.GetInfoResponse>.value(_FakeGetInfoResponse_7(
          this,
          Invocation.method(
            #getInfo,
            [nwc],
          ),
        )),
      ) as _i9.Future<_i7.GetInfoResponse>);

  @override
  _i9.Future<_i7.PayInvoiceResponse> payInvoice(
    String? invoice,
    int? amount,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #payInvoice,
          [
            invoice,
            amount,
          ],
        ),
        returnValue:
            _i9.Future<_i7.PayInvoiceResponse>.value(_FakePayInvoiceResponse_8(
          this,
          Invocation.method(
            #payInvoice,
            [
              invoice,
              amount,
            ],
          ),
        )),
      ) as _i9.Future<_i7.PayInvoiceResponse>);

  @override
  _i9.Future<_i7.MakeInvoiceResponse> makeInvoice(int? amountSats) =>
      (super.noSuchMethod(
        Invocation.method(
          #makeInvoice,
          [amountSats],
        ),
        returnValue: _i9.Future<_i7.MakeInvoiceResponse>.value(
            _FakeMakeInvoiceResponse_9(
          this,
          Invocation.method(
            #makeInvoice,
            [amountSats],
          ),
        )),
      ) as _i9.Future<_i7.MakeInvoiceResponse>);
}
