# Asset index

Last updated: 2026-03-14

## Bundled Flutter assets

These files ship through the Flutter asset bundle and are available on iOS, Android, and web builds via `Image.asset(...)`, `AssetImage(...)`, `DefaultAssetBundle`, or the registered font family.

### Images

- `assets/images/listing_placeholder.jpg`
- `assets/images/profile_placeholder.jpg`
- `assets/images/logo/logo.svg`
- `assets/images/logo/logo_no_text.svg`
- `assets/images/logo/generated/logo_android_foreground_1024.png`
- `assets/images/logo/generated/logo_android_monochrome_1024.png`
- `assets/images/logo/generated/logo_app_padded_1024.png`
- `assets/images/logo/generated/logo_base_1024.png`
- `assets/images/logo/generated/logo_ios_dark_transparent_1024.png`
- `assets/images/logo/generated/logo_ios_tinted_grayscale_1024.png`
- `assets/images/logo/generated/logo_notification_white_1024.png`
- `assets/images/nostr_clients/damus.png`
- `assets/images/nostr_clients/primal.svg`

### Fonts

- `assets/fonts/inter/Inter-Variable.ttf`
- `assets/fonts/inter/Inter-Italic-Variable.ttf`
- `assets/fonts/inter/OFL.txt`

Registered family:

- `Inter`

## Web public assets

These files are served directly from `app/web/` at the web root.

- `favicon.png`
- `icons/Icon-192.png`
- `icons/Icon-512.png`
- `icons/Icon-maskable-192.png`
- `icons/Icon-maskable-512.png`
- `manifest.json`
- `sqlite3.wasm`

## Access rules

- App UI assets live under `assets/` and are declared in [pubspec.yaml](../pubspec.yaml).
- Web shell assets live under `web/` and are referenced by [index.html](../web/index.html) or [manifest.json](../web/manifest.json).
- macOS `.DS_Store` files were removed so they do not leak into Flutter bundles.
- The app theme now uses the bundled `Inter` family as the closest open-source match to the previous iOS system look.
