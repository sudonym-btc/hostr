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
