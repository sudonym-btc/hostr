# Release Guide

This document covers the full release lifecycle: branching, PRs, versioning, CI secrets, and deploying staging and production builds to the App Store and Play Store.

---

## Branch Strategy

```
main          ← production-ready code; triggers releases
next          ← pre-release / RC staging area
feature/*     ← new features, branched from main
fix/*         ← bug fixes, branched from main
chore/*       ← non-functional changes (deps, CI, docs)
```

### Rules

- `main` and `next` are protected. Direct pushes are blocked.
- All changes enter via a **Pull Request** targeting `main` (or `next` for pre-releases).
- PRs require the `Quality Gate` CI check to pass before merging.
- Commit messages must follow **[Conventional Commits](https://www.conventionalcommits.org/)** — semantic-release reads these to determine the next version.

### Commit message format

```
<type>(<scope>): <short description>

feat(app): add lightning invoice QR scanner
fix(sdk): handle relay disconnect gracefully
chore(ci): update Flutter version to 3.41.1
docs: add release guide
```

| Prefix                               | Version bump    |
| ------------------------------------ | --------------- |
| `feat:`                              | minor (`0.x.0`) |
| `fix:`, `refactor:`, `perf:`         | patch (`0.0.x`) |
| `feat!:` / `BREAKING CHANGE:` footer | major (`x.0.0`) |
| `chore:`, `docs:`, `test:`, `ci:`    | no release      |

---

## Pull Request Workflow

1. Branch from `main`: `git checkout -b feat/my-feature`
2. Push and open a PR against `main`.
3. CI runs automatically:
   - **Change detection** determines which test suites are relevant.
   - Only affected suites run (`hostr_sdk`, `app`).
   - The `Quality Gate` job is the required status check.
4. Merge via **Squash and Merge** to keep `main` history linear.

---

## Versioning

Version is managed by **[semantic-release](https://github.com/semantic-release/semantic-release)** based on commit history since the last tag. The version in `app/pubspec.yaml` is updated automatically as part of the release step (via `.releaserc.yml` `prepareCmd`).

### Build numbers

Both Android (AAB) and iOS (IPA) use **`github.run_number`** as the build number. This is:

- Monotonically increasing across all workflow runs in the repo.
- Identical for Android and iOS builds triggered in the same workflow run, ensuring consistent build numbers across both stores.
- Never requires an external API call to calculate.

The semantic version string (`x.y.z`) is kept in sync via `pubspec.yaml`. The build number and version string together uniquely identify every build.

---

## Environments

There are two deployed environments, each with their own backend, app build, and CI secrets.

|                        | Staging                          | Production                       |
| ---------------------- | -------------------------------- | -------------------------------- |
| **Backend**            | `staging.hostr.network`          | `hostr.network`                  |
| **Flutter entrypoint** | `lib/main_staging.dart`          | `lib/main_production.dart`       |
| **Dart env**           | `Env.staging`                    | `Env.prod`                       |
| **Play Store track**   | `internal`                       | `production` (manual promotion)  |
| **TestFlight**         | `staging` group                  | `production` group               |
| **GitHub Environment** | `staging`                        | `production`                     |
| **TLS**                | Let's Encrypt via acme-companion | Let's Encrypt via acme-companion |

### When each build is triggered

| Event                                        | Staging build    | Production build |
| -------------------------------------------- | ---------------- | ---------------- |
| Merge to `main`                              | ✅ Automatically | ❌               |
| GitHub Release published by semantic-release | ✅               | ✅               |
| `workflow_dispatch` with `track: internal`   | Optionally       | —                |
| `workflow_dispatch` with `track: production` | —                | Optionally       |

A production build is always preceded by a passing staging build (same release version).

---

## CI Pipeline Overview

```
PR / push
    │
    ▼
[changes]          ← dorny/paths-filter: detect app / sdk / escrow changes
    │
    ├── [test_sdk]  (only if hostr_sdk/** or models/** changed)
    └── [test_app]  (only if app/** or hostr_sdk/** or models/** changed)
                │
                ▼
         [quality_gate]   ← skipped jobs count as passing; failed/cancelled = block
                │
                ▼ (main branch, push only)
          [release]       ← semantic-release: bump version, create GitHub Release
                │
                ▼ (GitHub Release published event)
     ┌──────────┴──────────┐
[build_android_staging] [build_ios_staging]
[build_android_prod]    [build_ios_prod]
```

---

## Required CI Secrets

Secrets are scoped to **GitHub Environments** (`staging` and `production`). Go to:
`Settings → Environments → <environment> → Environment secrets`

### Shared (both environments)

These are identical values in both environments unless you use separate developer accounts per environment.

| Secret                          | How to obtain                                               |
| ------------------------------- | ----------------------------------------------------------- |
| `APP_STORE_CONNECT_ISSUER_ID`   | App Store Connect → Users & Access → Integrations → Keys    |
| `APP_STORE_CONNECT_KEY_ID`      | Same page — the key ID shown next to your API key           |
| `APP_STORE_CONNECT_PRIVATE_KEY` | Contents of the `.p8` file downloaded when creating the key |

### Android (per environment)

| Secret                      | How to obtain                                                     |
| --------------------------- | ----------------------------------------------------------------- |
| `ANDROID_KEYSTORE_BASE64`   | `base64 -i upload-keystore.jks \| pbcopy`                         |
| `ANDROID_KEYSTORE_PASSWORD` | Password used when creating the keystore                          |
| `ANDROID_KEY_ALIAS`         | Alias used when creating the keystore                             |
| `ANDROID_KEY_PASSWORD`      | Key password (often same as keystore password)                    |
| `GOOGLE_PLAY_CREDENTIALS`   | Service account JSON — paste the **contents** of the `.json` file |

> ⚠️ Use separate upload keystores for staging and production. If a staging keystore is compromised, it cannot be used to push to the production track.

### iOS (per environment)

| Secret                            | How to obtain                                        |
| --------------------------------- | ---------------------------------------------------- |
| `IOS_DISTRIBUTION_CERT_BASE64`    | `base64 -i Certificates.p12 \| pbcopy`               |
| `IOS_DISTRIBUTION_CERT_PASSWORD`  | Password set when exporting the `.p12` from Keychain |
| `IOS_PROVISIONING_PROFILE_BASE64` | `base64 -i hostr_appstore.mobileprovision \| pbcopy` |

> Staging and production share the same bundle ID (`com.sudonym.hostr`), the same App Store Distribution certificate, and the same provisioning profile. They differ only in the Dart entrypoint (`main_staging.dart` vs `main_production.dart`), which sets the backend URL. Use separate TestFlight groups (e.g. "Internal — Staging" vs "Internal — Production") to control who receives which build. The CI workflow overrides signing settings in `Release.xcconfig` at build time — locally, the project defaults to Automatic signing for development.

### Cloud Deploy (per environment)

| Secret                    | How to obtain                                            |
| ------------------------- | -------------------------------------------------------- |
| `GCP_SERVICE_ACCOUNT_KEY` | GCP Console → IAM → Service Accounts → create key (JSON) |

Repository/Environment variable required for Terraform remote state:

| Variable          | Description                                                    |
| ----------------- | -------------------------------------------------------------- |
| `TF_STATE_BUCKET` | GCS bucket name created by `infrastructure/project` bootstrap. |

Deployment is executed by the **Infrastructure Deploy** workflow
([.github/workflows/infra_deploy.yaml](../../.github/workflows/infra_deploy.yaml)),
which applies Terraform and then resets the compose VM to trigger the startup
deploy script.

---

## Preparing a Release Manually

In normal operation, semantic-release handles this automatically. If you need to cut a release manually:

```bash
# Ensure you are on main with a clean working tree
git checkout main && git pull

# Dry-run to preview what semantic-release would do
npx semantic-release --dry-run

# Trigger CI to do the real release by pushing a conventional commit
git commit --allow-empty -m "chore(release): trigger release"
git push
```

---

## Promoting a Staging Build to Production

After validating the staging build on internal TestFlight / Play internal track:

1. Go to **Actions → Build & Deploy → Run workflow**.
2. Select `track: production`.
3. The workflow builds with `lib/main_production.dart` (pointing to `hostr.network`) and uploads directly to the production track.

Alternatively, on Android you can promote within the Play Console without a rebuild (the same AAB from the internal track is promoted). On iOS, promote the same TestFlight build to App Store review.

> 🔒 The `production` GitHub Environment requires **manual approval** before the job runs. Configure this under `Settings → Environments → production → Required reviewers`.

---

## Adding Secrets to the VM (Cloud Services)

Runtime secrets are stored in **Google Secret Manager** and fetched onto the VM
at deploy time. Required keys are:

- `ESCROW_PRIVATE_KEY`
- `BLOSSOM_DASHBOARD_PASSWORD`

Non-sensitive runtime values (`DOMAIN`, `LETSENCRYPT_EMAIL`, `RPC_URL`,
`ESCROW_CONTRACT_ADDR`) are sourced from `.env.staging` / `.env.prod`.

See [.doc/infrastructure/README.md](../infrastructure/README.md) for the
`hostr-fetch-secrets` flow and example commands.
