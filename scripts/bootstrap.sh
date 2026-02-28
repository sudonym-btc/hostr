#!/usr/bin/env bash
# bootstrap.sh — Creates GCP projects, state bucket, and DNS zones.
# Uses LOCAL state (kept in infrastructure/bootstrap/).
set -euo pipefail

for cmd in terraform gcloud; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "$cmd is required" >&2
    exit 127
  fi
done

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BOOTSTRAP_DIR="$ROOT_DIR/infrastructure/bootstrap"
INFRA_VAR_DIR="$ROOT_DIR/infrastructure/var"

cd "$BOOTSTRAP_DIR"

terraform init
terraform apply

# Read generated project IDs and propagate to env tfvars
STAGING_ID="$(terraform output -raw staging_project_id)"
PRODUCTION_ID="$(terraform output -raw production_project_id)"
STATE_BUCKET="$(terraform output -raw state_bucket_name)"

sed -i '' "s|^project_id.*|project_id  = \"${STAGING_ID}\"|" "$INFRA_VAR_DIR/staging.tfvars"
sed -i '' "s|^project_id.*|project_id  = \"${PRODUCTION_ID}\"|" "$INFRA_VAR_DIR/production.tfvars"

echo ""
echo "=== Bootstrap complete ==="
echo ""
echo "  Production: $PRODUCTION_ID"
echo "  Staging:    $STAGING_ID"
echo "  State:      $STATE_BUCKET"
echo ""
echo "  Updated infrastructure/var/{staging,production}.tfvars with new project IDs."
echo ""
echo "  Next steps:"
echo "    1. scripts/deploy.sh staging"
echo "    2. scripts/deploy.sh production"
echo "    3. Update domain registrar NS to:"
terraform output -json production_name_servers
echo "    4. Commit updated tfvars to git"
