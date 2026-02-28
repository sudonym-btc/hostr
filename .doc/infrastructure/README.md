# Infrastructure

This stack now deploys a **single Compute Engine VM** that runs Docker Compose
for staging/production services (`relay`, `blossom`, `escrow`) with
`docker-compose.prod-tls.yml` (Let's Encrypt via `acme-companion`).

Kubernetes/GKE resources are no longer used.

## Apply Terraform

```bash
cd infrastructure
terraform init
terraform apply -var-file=var/shared.tfvars -var-file=var/staging.tfvars
```

For production:

```bash
terraform apply -var-file=var/shared.tfvars -var-file=var/production.tfvars
```

After apply, update your domain registrar NS records to the Cloud DNS name
servers shown in Terraform outputs / GCP Console.

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
