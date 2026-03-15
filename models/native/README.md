# Bundled native binaries

This folder vendors native shared libraries for `models` when running outside Flutter (`dart run`).

## Why this exists

Per `h3_dart` / `h3_ffi` docs, VM usage expects a native library loaded via `H3Factory().byPath(...)`.
The package does not publish universal prebuilt VM binaries for all platforms in one place; the recommended path is to build from source.

Similarly, `coinlib` on Dart VM expects a native secp256k1 library to be present on disk. The Flutter app can use `coinlib_flutter`, but pure Dart packages in this monorepo need committed binaries so a fresh clone can run tests without extra setup.

Source references:

- https://pub.dev/packages/h3_dart
- https://github.com/festelo/h3_dart/tree/master/h3_dart#setup
- https://github.com/festelo/h3_dart/tree/master/h3_ffi#setup

## Bundled files

### H3

- `macos/libh3.dylib`
- `linux/libh3.so`
- `windows/h3.dll`

Optional architecture-specific variants are also supported:

- `macos/arm64/libh3.dylib`
- `macos/x86_64/libh3.dylib`
- `linux/arm64/libh3.so`
- `linux/x86_64/libh3.so`
- `windows/x86_64/h3.dll`

### secp256k1

- `macos/libsecp256k1.dylib`
- `linux/libsecp256k1.so`
- `windows/secp256k1.dll`

Optional architecture-specific variants are also supported:

- `macos/arm64/libsecp256k1.dylib`
- `macos/x86_64/libsecp256k1.dylib`
- `linux/arm64/libsecp256k1.so`
- `linux/x86_64/libsecp256k1.so`
- `windows/x86_64/secp256k1.dll`

## Runtime resolution

`H3Engine.bundled()` resolves package root and loads the platform file above.
If an architecture-specific file exists, it is preferred. If not, it falls back
to the legacy platform path (for example `linux/libh3.so`).

The secp256k1 loader uses the same package-root resolution strategy and stages
the matching bundled binary into the current package `build/` directory before
calling into `coinlib`.

Override path explicitly with env var:

- `HOSTR_H3_LIBRARY=/absolute/path/to/libh3.*`

## Rebuilding binaries

### macOS

Build from `h3_dart` repository using `scripts/build_h3.sh` and copy `h3_ffi/c/h3/build/lib/libh3.dylib`.

For secp256k1, run `dart run coinlib:build_macos` from the `models/` package and copy:

- `build/libsecp256k1.dylib`
- `native/macos/arm64/libsecp256k1.dylib` (via `lipo -extract arm64`)
- `native/macos/x86_64/libsecp256k1.dylib` (via `lipo -extract x86_64`)

### Linux

Build with Linux toolchain (native Linux or container) and copy `libh3.so`.

For secp256k1, run `dart run coinlib:build_linux` from the `models/` package and copy:

- `build/libsecp256k1.so`
- `native/linux/arm64/libsecp256k1.so` or `native/linux/x86_64/libsecp256k1.so`

### Windows

Build with Windows toolchain (native Windows/MSVC/MinGW or cross-compile) and copy `h3.dll`.

For secp256k1, run `dart run coinlib:build_windows_crosscompile` from the `models/` package and copy:

- `build/secp256k1.dll`
- `native/windows/x86_64/secp256k1.dll`
