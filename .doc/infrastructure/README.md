# Infrastructure

Infrastructure is split into **two Terraform stacks**:

| Stack           | Path                        | State                             | Purpose                                    |
| --------------- | --------------------------- | --------------------------------- | ------------------------------------------ |
| **Bootstrap**   | `infrastructure/bootstrap/` | Local (checked into `.gitignore`) | State bucket, DNS zones, MX, NS delegation |
| **Environment** | `infrastructure/`           | GCS remote (per-env prefix)       | Compute VM, VPC, secrets, DNS A records    |

The compute stack deploys a **single Compute Engine VM** that runs Docker Compose
for staging/production services (`relay`, `blossom`, `escrow`) with
`docker-compose.prod-tls.yml` (Let's Encrypt via `acme-companion`).

## Fresh setup in a new GCP account

1. Create two GCP projects manually (or via `gcloud`).
2. Update project IDs in `infrastructure/bootstrap/terraform.tfvars` and `infrastructure/var/{staging,production}.tfvars`.
3. Run the bootstrap stack:
   ```bash
   scripts/bootstrap.sh
   ```
4. Deploy each environment:
   ```bash
   scripts/deploy.sh staging
   scripts/deploy.sh production
   ```
5. Update your domain registrar NS records to the values shown in bootstrap outputs.
6. Seed runtime secrets in Secret Manager (see below).

## Local deployment

### Bootstrap (once / rare)

```bash
scripts/bootstrap.sh
```

Creates: GCS state bucket, Cloud DNS zones (parent + staging child), MX records, NS delegation.

### Environment deploy

```bash
scripts/deploy.sh staging
# or
scripts/deploy.sh production
```

This initialises the GCS backend, runs `terraform apply`, and optionally resets the VM.

The state bucket name is read from `infrastructure/bootstrap/terraform.tfvars`.
You can override it with `TF_STATE_BUCKET` env var.

## CI deployment

The GitHub Actions workflow (`.github/workflows/infra_deploy.yaml`) handles
environment deploys automatically. It requires the `TF_STATE_BUCKET` repository
variable to be set.

Bootstrap is **not** run in CI — it's a one-time local operation.

## Runtime secrets (Secret Manager)

Terraform creates the required Secret Manager secret containers for:

- `ESCROW_PRIVATE_KEY`
- `BLOSSOM_DASHBOARD_PASSWORD`

Non-sensitive runtime values like `DOMAIN`, `LETSENCRYPT_EMAIL`, `RPC_URL`, and
`ESCROW_CONTRACT_ADDR` are read from `.env.staging` / `.env.prod`.

You can seed values either:

1. via Terraform variable `compose_runtime_secret_values` (sensitive map), or
2. manually in GCP Secret Manager.

Manual example:

```bash
PROJECT_ID="<terraform output project_id>"

echo "<escrow-private-key>" | gcloud secrets versions add ESCROW_PRIVATE_KEY --project "$PROJECT_ID" --data-file=-
echo "<blossom-dashboard-password>" | gcloud secrets versions add BLOSSOM_DASHBOARD_PASSWORD --project "$PROJECT_ID" --data-file=-
```

## Deployment behavior

The VM startup/deploy script:

1. Pulls the repo branch.
2. Fetches secrets from Secret Manager into `/opt/hostr/.env.runtime`.
3. Writes `ESCROW_CONTRACT_ADDR` to `docker/data/escrow/contract_addr`.
4. Runs:

```bash
docker compose \
    --env-file /opt/hostr/.env.runtime \
    --profile <staging|prod> \
    -f docker-compose.yml \
    -f docker-compose.prod-tls.yml \
    up -d --build --remove-orphans
```

So TLS is always deployed through `docker-compose.prod-tls.yml` in
staging/production.
