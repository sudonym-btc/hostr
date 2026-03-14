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

sync_maps_api_key_env() {
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
      echo "Unsupported environment for GOOGLE_MAPS_API_KEY sync: $target_env" >&2
      return 64
      ;;
  esac

  local key_file="$INFRA_DIR/_local_outputs/$target_env/maps_api_key.txt"

  if [[ ! -f "$key_file" ]]; then
    echo "Maps API key file not found, skipping env sync: $key_file" >&2
    return 0
  fi

  if [[ ! -f "$env_file" ]]; then
    echo "Env file not found, skipping GOOGLE_MAPS_API_KEY sync: $env_file" >&2
    return 0
  fi

  local key_value
  key_value="$(tr -d '\r\n' < "$key_file")"

  if [[ -z "$key_value" ]]; then
    echo "Maps API key file is empty, skipping env sync: $key_file" >&2
    return 0
  fi

  node - "$env_file" "$key_value" <<'NODE'
const fs = require('fs');

const [envFile, keyValue] = process.argv.slice(2);
const key = 'GOOGLE_MAPS_API_KEY';

const content = fs.readFileSync(envFile, 'utf8');
const lines = content.split(/\r?\n/);
let replaced = false;

for (let i = 0; i < lines.length; i += 1) {
  if (lines[i].startsWith(`${key}=`)) {
    lines[i] = `${key}=${keyValue}`;
    replaced = true;
    break;
  }
}

if (!replaced) {
  if (lines.length > 0 && lines[lines.length - 1] !== '') {
    lines.push('');
  }
  lines.push(`${key}=${keyValue}`);
}

fs.writeFileSync(envFile, `${lines.join('\n').replace(/\n*$/, '')}\n`);
NODE

  echo "Synced GOOGLE_MAPS_API_KEY to $env_file"
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

sync_maps_api_key_env "$TARGET_ENV"

PROJECT_ID="$(terraform output -raw project_id)"
VM_NAME="$(terraform output -raw compose_vm_name)"
ZONE="$(terraform output -raw compose_vm_zone)"

echo ""
read -rp "Reset VM to trigger redeploy? [y/N] " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
  gcloud compute instances reset "$VM_NAME" \
    --project "$PROJECT_ID" \
    --zone "$ZONE"
  echo "VM reset triggered."
fi

echo ""
echo "Deploy complete for $TARGET_ENV (project: $PROJECT_ID)."
