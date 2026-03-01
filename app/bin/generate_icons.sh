#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_SVG="$ROOT_DIR/assets/images/logo/logo_no_text.svg"   # icon-only (no text) for app icons & notifications
LOGO_SVG="$ROOT_DIR/assets/images/logo/logo.svg"           # full logo with text (kept for in-app use)
OUT_DIR="$ROOT_DIR/assets/images/logo/generated"
ANDROID_RES_DIR="$ROOT_DIR/android/app/src/main/res"

if ! command -v magick >/dev/null 2>&1; then
  echo "Error: ImageMagick ('magick') is required but not installed."
  exit 1
fi

if [[ ! -f "$ICON_SVG" ]]; then
  echo "Error: icon SVG not found at: $ICON_SVG"
  exit 1
fi

mkdir -p "$OUT_DIR"

BASE="$OUT_DIR/logo_base_1024.png"
APP_PADDED="$OUT_DIR/logo_app_padded_1024.png"
ANDROID_FOREGROUND="$OUT_DIR/logo_android_foreground_1024.png"
ANDROID_MONOCHROME="$OUT_DIR/logo_android_monochrome_1024.png"
IOS_DARK_TRANSPARENT="$OUT_DIR/logo_ios_dark_transparent_1024.png"
IOS_TINTED_GRAYSCALE="$OUT_DIR/logo_ios_tinted_grayscale_1024.png"
NOTIFICATION_WHITE="$OUT_DIR/logo_notification_white_1024.png"

echo "Generating icon source PNGs from $ICON_SVG ..."

# 1) Canonical raster from icon SVG (no text, no added padding)
magick -background none "$ICON_SVG" -resize 1024x1024 -gravity center -extent 1024x1024 "$BASE"

# 2) App icon source with safe visual padding on white background
magick -size 1024x1024 xc:'#FFFFFF' \( "$BASE" -resize 820x820 \) -gravity center -composite "$APP_PADDED"

# 3) Android adaptive inputs
cp "$BASE" "$ANDROID_FOREGROUND"
magick "$BASE" -alpha on -fill black -colorize 100 "$ANDROID_MONOCHROME"

# 4) iOS 18+ dark/tinted variants
cp "$BASE" "$IOS_DARK_TRANSPARENT"
magick "$BASE" -colorspace Gray "$IOS_TINTED_GRAYSCALE"

# 5) Android notification small-icon base (white on transparent)
magick "$BASE" -alpha on -fill white -colorize 100 "$NOTIFICATION_WHITE"

echo "Generating Android notification icons ..."
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  case "$density" in
    mdpi) size=24 ;;
    hdpi) size=36 ;;
    xhdpi) size=48 ;;
    xxhdpi) size=72 ;;
    xxxhdpi) size=96 ;;
  esac
  # Keep a bit of padding for status-bar rendering clarity
  inner=$((size * 20 / 24))
  out_dir="$ANDROID_RES_DIR/drawable-$density"
  mkdir -p "$out_dir"

  magick -size "${size}x${size}" xc:none \
    \( "$NOTIFICATION_WHITE" -resize "${inner}x${inner}" \) \
    -gravity center -composite \
    "$out_dir/app_icon.png"
done

# Fallback drawable for any qualifier misses
mkdir -p "$ANDROID_RES_DIR/drawable"
cp "$ANDROID_RES_DIR/drawable-mdpi/app_icon.png" "$ANDROID_RES_DIR/drawable/app_icon.png"

cat <<EOF

Done.

Generated launcher sources:
  $APP_PADDED
  $ANDROID_FOREGROUND
  $ANDROID_MONOCHROME
  $IOS_DARK_TRANSPARENT
  $IOS_TINTED_GRAYSCALE

Generated Android notification icons:
  $ANDROID_RES_DIR/drawable-*/app_icon.png

Next step:
  cd "$ROOT_DIR"
  dart run flutter_launcher_icons

EOF
