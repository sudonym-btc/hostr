# Signet development images

Compose pins Signet 1.20.0 at one source revision and builds both the daemon and
dashboard with this shared Dockerfile. Dependencies come from Signet's frozen
lockfile; Hostr does not maintain a second dependency graph.

The images use pnpm 12.4.2 with the current `allowBuilds` workspace configuration.
Hostr supplies that configuration and the upstream HTTP proxy override directly,
so upstream package-manager settings do not select an older pnpm during builds.
The dashboard runtime reuses the locked dependencies from the build stage.

Node 24.21.0 is the latest Node 24 LTS release. Signet's locked
`better-sqlite3` 12.6.2 does not compile against Node 26's V8 API
(`PropertyCallbackInfo::This` was removed), so these external service images use
the supported LTS release. Hostr's own Node packages continue to use Node 26.
Both stages use the same pinned image digest to preserve the native module ABI.

Build both targets with the normal Hostr test Compose configuration:

```sh
source scripts/lib/hostr-common.sh
hostr_load_env "$PWD" test
hostr_compose_cmd test build signet signet-ui
```
