#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ICON_SVG="$ROOT_DIR/assets/images/logo/logo_no_text.svg"   # icon-only (no text) for launchers, favicons, notifications
LOGO_SVG="$ROOT_DIR/assets/images/logo/logo.svg"           # full logo with wordmark for branded logo and splash renders
OUT_DIR="$ROOT_DIR/assets/images/logo/generated"
CATALOG_DIR="$OUT_DIR/catalog"
TMP_DIR="$OUT_DIR/.tmp"
ANDROID_RES_DIR="$ROOT_DIR/android/app/src/main/res"
WEB_DIR="$ROOT_DIR/web"
WEB_ICONS_DIR="$WEB_DIR/icons"

BRAND_DARK="#241C36"
BRAND_LIGHT="#FFFFFF"

ICON_MASTER_SIZE=2048
LOGO_MASTER_SIZE=4096

ICON_SIZES=(24 32 48 64 96 128 180 192 256 384 512 1024)
LOGO_GEOMETRIES=(128x128 256x256 512x512 1024x1024 1600x900 1920x1080)
VARIANTS=(brand white black grayscale light dark)

trap 'rm -rf "$TMP_DIR"' EXIT

if ! command -v magick >/dev/null 2>&1; then
  echo "Error: ImageMagick ('magick') is required but not installed."
  exit 1
fi

if [[ ! -f "$ICON_SVG" ]]; then
  echo "Error: icon SVG not found at: $ICON_SVG"
  exit 1
fi

if [[ ! -f "$LOGO_SVG" ]]; then
  echo "Error: full logo SVG not found at: $LOGO_SVG"
  exit 1
fi

mkdir -p "$OUT_DIR" "$CATALOG_DIR" "$TMP_DIR" "$WEB_ICONS_DIR"
rm -rf "$CATALOG_DIR/favicon" "$CATALOG_DIR/splash"

BASE="$OUT_DIR/logo_base_1024.png"
APP_PADDED="$OUT_DIR/logo_app_padded_1024.png"
ANDROID_FOREGROUND="$OUT_DIR/logo_android_foreground_1024.png"
ANDROID_MONOCHROME="$OUT_DIR/logo_android_monochrome_1024.png"
IOS_DARK_TRANSPARENT="$OUT_DIR/logo_ios_dark_transparent_1024.png"
IOS_TINTED_GRAYSCALE="$OUT_DIR/logo_ios_tinted_grayscale_1024.png"
NOTIFICATION_WHITE="$OUT_DIR/logo_notification_white_1024.png"
STARTUP_LOGO_LIGHT="$OUT_DIR/logo_startup_light_512.png"
STARTUP_LOGO_DARK="$OUT_DIR/logo_startup_dark_512.png"
NAVBAR_LOGO_LIGHT="$OUT_DIR/logo_navbar_light_512.png"
NAVBAR_LOGO_DARK="$OUT_DIR/logo_navbar_dark_512.png"

ICON_MASTER="$TMP_DIR/icon_master.png"
LOGO_MASTER="$TMP_DIR/logo_master.png"

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

render_logo_variant() {
  local source_png="$1"
  local variant="$2"
  local geometry="$3"
  local output="$4"
  local width_pct="${5:-82}"
  local height_pct="${6:-48}"
  local width="${geometry%x*}"
  local height="${geometry#*x}"
  local max_width
  local max_height
  max_width=$((width * width_pct / 100))
  max_height=$((height * height_pct / 100))

  mkdir -p "$(dirname "$output")"

  case "$variant" in
    brand)
      magick -size "${width}x${height}" xc:none \
        \( "$source_png" -resize "${max_width}x${max_height}" \) \
        -gravity center -composite \
        "$output"
      ;;
    white)
      magick -size "${width}x${height}" xc:none \
        \( "$source_png" -resize "${max_width}x${max_height}" -alpha on -fill white -colorize 100 \) \
        -gravity center -composite \
        "$output"
      ;;
    black)
      magick -size "${width}x${height}" xc:none \
        \( "$source_png" -resize "${max_width}x${max_height}" -alpha on -fill black -colorize 100 \) \
        -gravity center -composite \
        "$output"
      ;;
    grayscale)
      magick -size "${width}x${height}" xc:none \
        \( "$source_png" -resize "${max_width}x${max_height}" -colorspace Gray \) \
        -gravity center -composite \
        "$output"
      ;;
    light)
      magick -size "${width}x${height}" xc:"$BRAND_LIGHT" \
        \( "$source_png" -resize "${max_width}x${max_height}" \) \
        -gravity center -composite \
        "$output"
      ;;
    dark)
      magick -size "${width}x${height}" xc:"$BRAND_DARK" \
        \( "$source_png" -resize "${max_width}x${max_height}" -alpha on -fill white -colorize 100 \) \
        -gravity center -composite \
        "$output"
      ;;
    *)
      echo "Error: unsupported logo variant '$variant'" >&2
      exit 1
      ;;
  esac
}

echo "Generating master rasters from SVG sources ..."
magick -background none "$ICON_SVG" -resize "${ICON_MASTER_SIZE}x${ICON_MASTER_SIZE}" -gravity center -extent "${ICON_MASTER_SIZE}x${ICON_MASTER_SIZE}" "$ICON_MASTER"
magick -background none "$LOGO_SVG" -resize "${LOGO_MASTER_SIZE}x${LOGO_MASTER_SIZE}" -gravity center -extent "${LOGO_MASTER_SIZE}x${LOGO_MASTER_SIZE}" "$LOGO_MASTER"

echo "Rendering icon catalogs (launcher, notification, app logo) ..."

for variant in "${VARIANTS[@]}"; do
  for size in "${ICON_SIZES[@]}"; do
    render_square_variant "$ICON_MASTER" "$variant" "$size" "$CATALOG_DIR/icon/$variant/icon_${size}x${size}.png" 82
  done

  for geometry in "${LOGO_GEOMETRIES[@]}"; do
    render_logo_variant "$LOGO_MASTER" "$variant" "$geometry" "$CATALOG_DIR/logo/$variant/logo_${geometry}.png" 84 52
  done
done

echo "Refreshing launcher source PNGs ..."
cp "$CATALOG_DIR/icon/brand/icon_1024x1024.png" "$BASE"
cp "$CATALOG_DIR/icon/light/icon_1024x1024.png" "$APP_PADDED"
cp "$CATALOG_DIR/icon/brand/icon_1024x1024.png" "$ANDROID_FOREGROUND"
cp "$CATALOG_DIR/icon/black/icon_1024x1024.png" "$ANDROID_MONOCHROME"
cp "$CATALOG_DIR/icon/brand/icon_1024x1024.png" "$IOS_DARK_TRANSPARENT"
cp "$CATALOG_DIR/icon/grayscale/icon_1024x1024.png" "$IOS_TINTED_GRAYSCALE"
cp "$CATALOG_DIR/icon/white/icon_1024x1024.png" "$NOTIFICATION_WHITE"
cp "$CATALOG_DIR/logo/brand/logo_512x512.png" "$STARTUP_LOGO_LIGHT"
cp "$CATALOG_DIR/logo/white/logo_512x512.png" "$STARTUP_LOGO_DARK"
cp "$CATALOG_DIR/logo/brand/logo_512x512.png" "$NAVBAR_LOGO_LIGHT"
cp "$CATALOG_DIR/logo/white/logo_512x512.png" "$NAVBAR_LOGO_DARK"

echo "Generating Android notification icons ..."
for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  case "$density" in
    mdpi) size=24 ;;
    hdpi) size=36 ;;
    xhdpi) size=48 ;;
    xxhdpi) size=72 ;;
    xxxhdpi) size=96 ;;
  esac

  out_dir="$ANDROID_RES_DIR/drawable-$density"
  mkdir -p "$out_dir"
  render_square_variant "$ICON_MASTER" white "$size" "$out_dir/app_icon.png" 84
done

mkdir -p "$ANDROID_RES_DIR/drawable"
cp "$ANDROID_RES_DIR/drawable-mdpi/app_icon.png" "$ANDROID_RES_DIR/drawable/app_icon.png"

echo "Syncing web shell icons ..."
cp "$CATALOG_DIR/icon/light/icon_64x64.png" "$WEB_DIR/favicon.png"
cp "$CATALOG_DIR/icon/light/icon_192x192.png" "$WEB_ICONS_DIR/Icon-192.png"
cp "$CATALOG_DIR/icon/light/icon_512x512.png" "$WEB_ICONS_DIR/Icon-512.png"
cp "$CATALOG_DIR/icon/light/icon_192x192.png" "$WEB_ICONS_DIR/Icon-maskable-192.png"
cp "$CATALOG_DIR/icon/light/icon_512x512.png" "$WEB_ICONS_DIR/Icon-maskable-512.png"

cat <<EOF

Done.

Generated catalogs:
  $CATALOG_DIR/icon/<variant>/icon_<size>.png
  $CATALOG_DIR/logo/<variant>/logo_<geometry>.png

Refreshed launcher sources:
  $APP_PADDED
  $ANDROID_FOREGROUND
  $ANDROID_MONOCHROME
  $IOS_DARK_TRANSPARENT
  $IOS_TINTED_GRAYSCALE
  $NOTIFICATION_WHITE
  $STARTUP_LOGO_LIGHT
  $STARTUP_LOGO_DARK
  $NAVBAR_LOGO_LIGHT
  $NAVBAR_LOGO_DARK

Refreshed web shell icons:
  $WEB_DIR/favicon.png
  $WEB_ICONS_DIR/Icon-192.png
  $WEB_ICONS_DIR/Icon-512.png
  $WEB_ICONS_DIR/Icon-maskable-192.png
  $WEB_ICONS_DIR/Icon-maskable-512.png

Generated Android notification icons:
  $ANDROID_RES_DIR/drawable-*/app_icon.png

Next step:
  cd "$ROOT_DIR"
  dart run flutter_launcher_icons

EOF
