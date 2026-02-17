# Bundled H3 native binaries

This folder vendors native H3 shared libraries for `models` when running outside Flutter (`dart run`).

## Why this exists

Per `h3_dart` / `h3_ffi` docs, VM usage expects a native library loaded via `H3Factory().byPath(...)`.
The package does not publish universal prebuilt VM binaries for all platforms in one place; the recommended path is to build from source.

Source references:

- https://pub.dev/packages/h3_dart
- https://github.com/festelo/h3_dart/tree/master/h3_dart#setup
- https://github.com/festelo/h3_dart/tree/master/h3_ffi#setup

## Bundled files

- `macos/libh3.dylib`
- `linux/libh3.so`
- `windows/h3.dll`

## Runtime resolution

`H3Engine.bundled()` resolves package root and loads the platform file above.

Override path explicitly with env var:

- `HOSTR_H3_LIBRARY=/absolute/path/to/libh3.*`

## Rebuilding binaries

### macOS

Build from `h3_dart` repository using `scripts/build_h3.sh` and copy `h3_ffi/c/h3/build/lib/libh3.dylib`.

### Linux

Build with Linux toolchain (native Linux or container) and copy `libh3.so`.

### Windows

Build with Windows toolchain (native Windows/MSVC/MinGW or cross-compile) and copy `h3.dll`.
