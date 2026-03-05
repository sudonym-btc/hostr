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

### Seeding secrets after a fresh Terraform deploy

After `scripts/deploy.sh staging` (or `production`) completes, the Secret
Manager **containers** exist but have **no versions** yet. You need to seed them
before the VM can start the escrow daemon.

#### 1. Generate and store the escrow key

Generate a fresh Nostr private key and store it in one step:

```bash
# From the repo root
PROJECT_ID="hostr-staging-d4c52998"  # or hostr-production-d3ba05b4

cd escrow && dart run bin/generate_nsec.dart | \
  gcloud secrets versions add ESCROW_PRIVATE_KEY \
    --project="$PROJECT_ID" --data-file=-
```

Or if you already have a key:

```bash
echo -n "<nsec-hex>" | \
  gcloud secrets versions add ESCROW_PRIVATE_KEY \
    --project="$PROJECT_ID" --data-file=-
```

#### 2. Store the blossom dashboard password

```bash
echo -n "<password>" | \
  gcloud secrets versions add BLOSSOM_DASHBOARD_PASSWORD \
    --project="$PROJECT_ID" --data-file=-
```

#### 3. Verify the escrow pubkey

Derive the Nostr pubkey from the stored secret to confirm it's correct and
to get the value needed for the app's `bootstrapEscrowPubkeys` config:

```bash
./scripts/escrow-pubkey.sh "$PROJECT_ID"
```

This outputs the pubkey. Update the corresponding config in
`app/lib/config/env/{staging,production}.config.dart`:

```dart
static const _hostrEscrowPubkey = '<pubkey-from-above>';
```

#### 4. Deploy the contract and set the address

Deploy the MultiEscrow contract to Rootstock (see the escrow README), then set
`ESCROW_CONTRACT_ADDR` in `.env.staging` or `.env.prod`:

```
ESCROW_CONTRACT_ADDR=0x<deployed-address>
```

This value is **not** a secret — it's committed to the repo in the env file.

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
