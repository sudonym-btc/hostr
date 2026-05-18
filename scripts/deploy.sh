#!/usr/bin/env bash
# deploy.sh — Deploy per-environment infrastructure (VM, DNS records, secrets).
# Uses GCS remote state via the bucket created by bootstrap.sh.
set -euo pipefail

TARGET_ENV="${1:-staging}"
case "$TARGET_ENV" in
  staging|production) ;;
  *)
    echo "Usage: $0 [staging|production]" >&2
    exit 64
    ;;
esac

for cmd in terraform gcloud; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required" >&2
    exit 127
  fi
done

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INFRA_DIR="$ROOT_DIR/infrastructure"
BOOTSTRAP_DIR="$INFRA_DIR/bootstrap"

write_env_value() {
  local env_file="$1"
  local key="$2"
  local value="$3"

  node - "$env_file" "$key" "$value" <<'NODE'
const fs = require('fs');

const [envFile, key, value] = process.argv.slice(2);

const content = fs.readFileSync(envFile, 'utf8');
const lines = content.split(/\r?\n/);
let replaced = false;

for (let i = 0; i < lines.length; i += 1) {
  if (lines[i].startsWith(`${key}=`)) {
    lines[i] = `${key}=${value}`;
    replaced = true;
    break;
  }
}

if (!replaced) {
  if (lines.length > 0 && lines[lines.length - 1] !== '') {
    lines.push('');
  }
  lines.push(`${key}=${value}`);
}

fs.writeFileSync(envFile, `${lines.join('\n').replace(/\n*$/, '')}\n`);
NODE
}

sync_env_value_from_file() {
  local env_file="$1"
  local key="$2"
  local value_file="$3"
  local label="$4"

  if [[ ! -f "$value_file" ]]; then
    echo "$label file not found, skipping env sync: $value_file" >&2
    return 0
  fi

  local value
  value="$(tr -d '\r\n' < "$value_file")"

  if [[ -z "$value" ]]; then
    echo "$label file is empty, skipping env sync: $value_file" >&2
    return 0
  fi

  write_env_value "$env_file" "$key" "$value"
  echo "Synced $key to $env_file"
}

sync_maps_env() {
  local target_env="$1"
  local env_file=""

  case "$target_env" in
    staging)
      env_file="$ROOT_DIR/.env.staging"
      ;;
    production)
      env_file="$ROOT_DIR/.env.prod"
      ;;
    *)
      echo "Unsupported environment for Google Maps env sync: $target_env" >&2
      return 64
      ;;
  esac

  if [[ ! -f "$env_file" ]]; then
    echo "Env file not found, skipping Google Maps env sync: $env_file" >&2
    return 0
  fi

  sync_env_value_from_file \
    "$env_file" \
    "GOOGLE_MAPS_API_KEY" \
    "$INFRA_DIR/_local_outputs/$target_env/maps_api_key.txt" \
    "Maps API key"

  sync_env_value_from_file \
    "$env_file" \
    "GOOGLE_MAPS_WEB_MAP_ID" \
    "$INFRA_DIR/_local_outputs/$target_env/maps_web_map_id.txt" \
    "Maps web map ID"

  sync_env_value_from_file \
    "$env_file" \
    "GOOGLE_MAPS_ANDROID_MAP_ID" \
    "$INFRA_DIR/_local_outputs/$target_env/maps_android_map_id.txt" \
    "Maps Android map ID"

  sync_env_value_from_file \
    "$env_file" \
    "GOOGLE_MAPS_IOS_MAP_ID" \
    "$INFRA_DIR/_local_outputs/$target_env/maps_ios_map_id.txt" \
    "Maps iOS map ID"
}

# Resolve state bucket name from bootstrap state or env var.
TF_STATE_BUCKET="${TF_STATE_BUCKET:-}"
if [[ -z "$TF_STATE_BUCKET" ]]; then
  TF_STATE_BUCKET="$(terraform -chdir="$BOOTSTRAP_DIR" output -raw state_bucket_name 2>/dev/null || true)"
fi
if [[ -z "$TF_STATE_BUCKET" ]]; then
  echo "Cannot determine state bucket. Set TF_STATE_BUCKET or run bootstrap.sh first." >&2
  exit 1
fi

echo "Environment:  $TARGET_ENV"
echo "State bucket: $TF_STATE_BUCKET"
echo ""

cd "$INFRA_DIR"

terraform init -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET}" \
  -backend-config="prefix=hostr/infrastructure/${TARGET_ENV}"

terraform apply \
  -var-file="var/shared.tfvars" \
  -var-file="var/${TARGET_ENV}.tfvars"

sync_maps_env "$TARGET_ENV"

PROJECT_ID="$(terraform output -raw project_id)"
MIG_NAME="$(terraform output -raw compose_mig_name)"
ZONE="$(terraform output -raw compose_vm_zone)"

echo ""
read -rp "Replace compose MIG VM to trigger redeploy? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  gcloud compute instance-groups managed rolling-action replace "$MIG_NAME" \
    --project "$PROJECT_ID" \
    --zone "$ZONE" \
    --max-surge=0 \
    --max-unavailable=1 \
    --replacement-method=recreate
  echo "MIG replacement triggered."
fi

echo ""
echo "Deploy complete for $TARGET_ENV (project: $PROJECT_ID)."
