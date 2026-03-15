#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_SVG="$ROOT_DIR/assets/images/logo/logo_no_text.svg"
OUT_DIR="$ROOT_DIR/assets/images/logo/generated"
TMP_DIR="$OUT_DIR/.tmp"

BRAND_DARK="#241C36"
BRAND_LIGHT="#FFFFFF"

ICON_MASTER_SIZE=2048
OUTPUT_SIZE=1024
NAVBAR_SIZE=512

trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v magick >/dev/null 2>&1; then
  echo "Error: ImageMagick ('magick') is required but not installed."
  exit 1
fi

if [[ ! -f "$ICON_SVG" ]]; then
  echo "Error: icon SVG not found at: $ICON_SVG"
  exit 1
fi

mkdir -p "$OUT_DIR" "$TMP_DIR"
rm -rf "$OUT_DIR/catalog"

BASE="$OUT_DIR/logo_base_1024.png"
APP_PADDED="$OUT_DIR/logo_app_padded_1024.png"
ANDROID_FOREGROUND="$OUT_DIR/logo_android_foreground_1024.png"
ANDROID_MONOCHROME="$OUT_DIR/logo_android_monochrome_1024.png"
IOS_DARK_TRANSPARENT="$OUT_DIR/logo_ios_dark_transparent_1024.png"
IOS_TINTED_GRAYSCALE="$OUT_DIR/logo_ios_tinted_grayscale_1024.png"
NOTIFICATION_WHITE="$OUT_DIR/logo_notification_white_1024.png"
NAVBAR_LIGHT="$OUT_DIR/logo_navbar_light_512.png"
NAVBAR_DARK="$OUT_DIR/logo_navbar_dark_512.png"

ICON_MASTER="$TMP_DIR/icon_master.png"

render_square_variant() {
  local source_png="$1"
  local variant="$2"
  local size="$3"
  local output="$4"
  local inner_pct="${5:-82}"
  local inner
  inner=$((size * inner_pct / 100))

  mkdir -p "$(dirname "$output")"

  case "$variant" in
    brand)
      magick -size "${size}x${size}" xc:none \
        \( "$source_png" -resize "${inner}x${inner}" \) \
        -gravity center -composite \
        "$output"
      ;;
    white)
      magick -size "${size}x${size}" xc:none \
        \( "$source_png" -resize "${inner}x${inner}" -alpha on -fill white -colorize 100 \) \
        -gravity center -composite \
        "$output"
      ;;
    black)
      magick -size "${size}x${size}" xc:none \
        \( "$source_png" -resize "${inner}x${inner}" -alpha on -fill black -colorize 100 \) \
        -gravity center -composite \
        "$output"
      ;;
    grayscale)
      magick -size "${size}x${size}" xc:none \
        \( "$source_png" -resize "${inner}x${inner}" -colorspace Gray \) \
        -gravity center -composite \
        "$output"
      ;;
    light)
      magick -size "${size}x${size}" xc:"$BRAND_LIGHT" \
        \( "$source_png" -resize "${inner}x${inner}" \) \
        -gravity center -composite \
        "$output"
      ;;
    dark)
      magick -size "${size}x${size}" xc:"$BRAND_DARK" \
        \( "$source_png" -resize "${inner}x${inner}" -alpha on -fill white -colorize 100 \) \
        -gravity center -composite \
        "$output"
      ;;
    *)
      echo "Error: unsupported square variant '$variant'" >&2
      exit 1
      ;;
  esac
}

echo "Generating master rasters from SVG sources ..."
magick -background none "$ICON_SVG" -resize "${ICON_MASTER_SIZE}x${ICON_MASTER_SIZE}" -gravity center -extent "${ICON_MASTER_SIZE}x${ICON_MASTER_SIZE}" "$ICON_MASTER"

echo "Rendering canonical 1024px launcher source PNGs ..."
render_square_variant "$ICON_MASTER" brand "$OUTPUT_SIZE" "$BASE" 82
render_square_variant "$ICON_MASTER" light "$OUTPUT_SIZE" "$APP_PADDED" 82
render_square_variant "$ICON_MASTER" brand "$OUTPUT_SIZE" "$ANDROID_FOREGROUND" 82
render_square_variant "$ICON_MASTER" black "$OUTPUT_SIZE" "$ANDROID_MONOCHROME" 82
render_square_variant "$ICON_MASTER" brand "$OUTPUT_SIZE" "$IOS_DARK_TRANSPARENT" 82
render_square_variant "$ICON_MASTER" grayscale "$OUTPUT_SIZE" "$IOS_TINTED_GRAYSCALE" 82
render_square_variant "$ICON_MASTER" white "$OUTPUT_SIZE" "$NOTIFICATION_WHITE" 82

echo "Rendering themed navbar icon assets ..."
render_square_variant "$ICON_MASTER" light "$NAVBAR_SIZE" "$NAVBAR_LIGHT" 82
render_square_variant "$ICON_MASTER" dark "$NAVBAR_SIZE" "$NAVBAR_DARK" 82

cat <<EOF

Done.

Refreshed launcher sources:
  $BASE
  $APP_PADDED
  $ANDROID_FOREGROUND
  $ANDROID_MONOCHROME
  $IOS_DARK_TRANSPARENT
  $IOS_TINTED_GRAYSCALE
  $NOTIFICATION_WHITE

Refreshed navbar assets:
  $NAVBAR_LIGHT
  $NAVBAR_DARK

Next step:
  cd "$ROOT_DIR"
  dart run flutter_launcher_icons

EOF
