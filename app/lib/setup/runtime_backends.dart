import 'package:coinlib_flutter/coinlib_flutter.dart' as coinlib_flutter;
import 'package:h3_flutter/h3_flutter.dart';
import 'package:models/main.dart' show setSecp256k1LoaderOverride;
import 'package:models/util/location/h3.dart'
    show H3BackendKind, getH3BackendSelection, setH3FactoryOverride;

const _flutterH3OverrideLabel = 'h3_flutter.H3Factory.load()';

void configureOptimalRuntimeBackends() {
  setSecp256k1LoaderOverride(
    coinlib_flutter.loadCoinlib,
    label: 'coinlib_flutter.loadCoinlib()',
  );
  setH3FactoryOverride(
    () => const H3Factory().load(),
    label: _flutterH3OverrideLabel,
  );
}

void validateFlutterRuntimeBackends() {
  final h3Selection = getH3BackendSelection();
  if (h3Selection == null ||
      h3Selection.kind != H3BackendKind.override ||
      h3Selection.source != _flutterH3OverrideLabel) {
    throw StateError(
      'Expected H3 backend $_flutterH3OverrideLabel but got '
      '${h3Selection?.describe() ?? 'nothing selected'}',
    );
  }
}
