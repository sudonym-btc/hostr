bool shouldUseProcessH3Library() => false;

String? resolvePlatformDefaultH3LibraryPath() => null;

String resolveBundledH3LibraryPath() {
  throw UnsupportedError(
      'Bundled H3 library path is only available on IO platforms.');
}
