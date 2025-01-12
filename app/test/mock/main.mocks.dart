// Mocks generated by Mockito 5.4.5 from annotations
// in hostr/test/mock/main.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i5;

import 'package:dart_nostr/dart_nostr.dart' as _i6;
import 'package:hostr/core/main.dart' as _i3;
import 'package:hostr/data/sources/local/key_storage.dart' as _i4;
import 'package:hostr/data/sources/local/nwc_storage.dart' as _i7;
import 'package:hostr/data/sources/local/secure_storage.dart' as _i2;
import 'package:mockito/mockito.dart' as _i1;

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

class _FakeSecureStorage_0 extends _i1.SmartFake implements _i2.SecureStorage {
  _FakeSecureStorage_0(
    Object parent,
    Invocation parentInvocation,
  ) : super(
          parent,
          parentInvocation,
        );
}

class _FakeCustomLogger_1 extends _i1.SmartFake implements _i3.CustomLogger {
  _FakeCustomLogger_1(
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
class MockKeyStorage extends _i1.Mock implements _i4.KeyStorage {
  MockKeyStorage() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.SecureStorage get storage => (super.noSuchMethod(
        Invocation.getter(#storage),
        returnValue: _FakeSecureStorage_0(
          this,
          Invocation.getter(#storage),
        ),
      ) as _i2.SecureStorage);

  @override
  set storage(_i2.SecureStorage? _storage) => super.noSuchMethod(
        Invocation.setter(
          #storage,
          _storage,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.CustomLogger get logger => (super.noSuchMethod(
        Invocation.getter(#logger),
        returnValue: _FakeCustomLogger_1(
          this,
          Invocation.getter(#logger),
        ),
      ) as _i3.CustomLogger);

  @override
  set logger(_i3.CustomLogger? _logger) => super.noSuchMethod(
        Invocation.setter(
          #logger,
          _logger,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i5.Future<_i6.NostrKeyPairs?> getActiveKeyPair() => (super.noSuchMethod(
        Invocation.method(
          #getActiveKeyPair,
          [],
        ),
        returnValue: _i5.Future<_i6.NostrKeyPairs?>.value(),
      ) as _i5.Future<_i6.NostrKeyPairs?>);

  @override
  dynamic set(String? item) => super.noSuchMethod(Invocation.method(
        #set,
        [item],
      ));
}

/// A class which mocks [NwcStorage].
///
/// See the documentation for Mockito's code generation for more information.
class MockNwcStorage extends _i1.Mock implements _i7.NwcStorage {
  MockNwcStorage() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i2.SecureStorage get storage => (super.noSuchMethod(
        Invocation.getter(#storage),
        returnValue: _FakeSecureStorage_0(
          this,
          Invocation.getter(#storage),
        ),
      ) as _i2.SecureStorage);

  @override
  set storage(_i2.SecureStorage? _storage) => super.noSuchMethod(
        Invocation.setter(
          #storage,
          _storage,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i3.CustomLogger get logger => (super.noSuchMethod(
        Invocation.getter(#logger),
        returnValue: _FakeCustomLogger_1(
          this,
          Invocation.getter(#logger),
        ),
      ) as _i3.CustomLogger);

  @override
  set logger(_i3.CustomLogger? _logger) => super.noSuchMethod(
        Invocation.setter(
          #logger,
          _logger,
        ),
        returnValueForMissingStub: null,
      );

  @override
  _i5.Future<List<String>> get() => (super.noSuchMethod(
        Invocation.method(
          #get,
          [],
        ),
        returnValue: _i5.Future<List<String>>.value(<String>[]),
      ) as _i5.Future<List<String>>);

  @override
  dynamic set(List<String>? items) => super.noSuchMethod(Invocation.method(
        #set,
        [items],
      ));
}
