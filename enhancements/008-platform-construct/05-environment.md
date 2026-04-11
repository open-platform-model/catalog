# The `#Environment` Construct

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-11       |
| **Authors** | OPM Contributors |

---

## Purpose

`#Environment` is the user-facing deployment target. It binds a name to a `#Platform` and contributes environment-level context overrides. Multiple environments can reference the same platform. `#Environment` does not override `#config` (values). It only contributes to `#ctx`.

Separating environment from platform reflects real-world topology: one cluster (platform) hosts multiple environments (dev, staging, prod) that differ in namespace, domains, and context — not in capabilities.

---

## Schema

`#Environment.#ctx` is typed as `ctx.#EnvironmentContext` (see [03-schema.md](03-schema.md)).

```cue
#Environment: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Environment"
    metadata: { name!, description? }
    #platform!: platform.#Platform
    #ctx: ctx.#EnvironmentContext
}
```

### Field Ownership

| Field | Required | Who sets it | Purpose |
| --- | --- | --- | --- |
| `metadata.name` | Yes | Environment author | Human-readable environment identifier |
| `#platform` | Yes | Environment author | Reference to `#Platform` in `.opm/platforms/` |
| `#ctx.runtime.release.namespace` | Yes | Environment author | Default namespace for all releases in this environment |
| `#ctx.runtime.cluster.domain` | No | Environment author | Override platform's cluster domain (rare) |
| `#ctx.runtime.route.domain` | No | Environment author | Environment-specific ingress/route domain |
| `#ctx.platform` | No | Environment author | Additional platform-team extensions for this environment |

---

## File Layout

Each environment gets its own directory under `.opm/environments/`:

```text
.opm/
  platforms/
    acme-prod-01/
      platform.cue
    kind-opm-dev/
      platform.cue
  environments/
    dev/
      environment.cue
    staging/
      environment.cue
    prod/
      environment.cue
```

Environment names are user-chosen. Common patterns:

- Short names: `dev`, `staging`, `prod`
- Cluster-qualified: `acme-prod-01-dev`, `acme-prod-01-staging`
- Team-qualified: `team-alpha-dev`

---

## Examples

### Development environment (local kind cluster)

```cue
// .opm/environments/dev/environment.cue
package dev

import (
    core "opmodel.dev/core/v1alpha1/environment@v1"
    platform "opmodel.dev/config@v1/.opm/platforms/kind-opm-dev"
)

#Environment: core.#Environment & {
    metadata: name: "dev"
    #platform: platform.#Platform
    #ctx: runtime: {
        release: namespace: "dev"
        route: domain: "dev.local"
    }
}
```

### Production environment

```cue
// .opm/environments/prod/environment.cue
package prod

import (
    core "opmodel.dev/core/v1alpha1/environment@v1"
    platform "opmodel.dev/config@v1/.opm/platforms/acme-prod-01"
)

#Environment: core.#Environment & {
    metadata: name:        "prod"
    metadata: description: "Production environment on acme-prod-01"
    #platform: platform.#Platform
    #ctx: runtime: {
        release: namespace: "production"
        route: domain: "example.com"
    }
}
```

### Staging environment (same cluster as prod, different namespace/domain)

```cue
// .opm/environments/staging/environment.cue
package staging

import (
    core "opmodel.dev/core/v1alpha1/environment@v1"
    platform "opmodel.dev/config@v1/.opm/platforms/acme-prod-01"
)

#Environment: core.#Environment & {
    metadata: name: "staging"
    #platform: platform.#Platform  // same cluster as prod
    #ctx: runtime: {
        release: namespace: "staging"
        route: domain: "staging.example.com"
    }
}
```

Multiple environments can target the same platform. The platform describes what the cluster can do; the environment describes how a particular slice of the cluster is used.

---

## Sharing Environments

Since each environment is its own CUE package, it can be published as a CUE module and imported by other teams:

```cue
// A release importing a shared environment from a published module
import (
    env "opmodel.dev/team-infra/v1/environments/prod@v1"
)

#env: env.#Environment
```

This enables team-wide consistency: one team publishes the environment definitions, all developers consume the same platform + context configuration.

---

## Context Hierarchy

`#Environment.#ctx` is Layer 2 in the context resolution hierarchy:

```text
Layer 1: #Platform.#ctx (#PlatformContext)
  Platform-level facts: cluster domain, platform extensions
  e.g., cluster.domain: "cluster.local", platform.defaultStorageClass: "local-path"

Layer 2: #Environment.#ctx (#EnvironmentContext)      ← this construct
  Environment-level overrides: namespace, route domain
  e.g., release.namespace: "dev", route.domain: "dev.example.com"

Layer 3: #ModuleRelease → #ModuleContext
  Release-level identity: name, uuid, module metadata, components
  Can override namespace: metadata.namespace: "media"
```

### Resolution Example

Given:

- Platform `acme-prod-01`: `#ctx.runtime.cluster.domain: "cluster.local"`, `#ctx.platform.defaultStorageClass: "local-path"`
- Environment `prod`: `#ctx.runtime.release.namespace: "production"`, `#ctx.runtime.route.domain: "example.com"`
- ModuleRelease `jellyfin`: `metadata.namespace: "media"`, `metadata.name: "jellyfin"`

The `#ContextBuilder` produces:

```text
#ctx.runtime.release.name:      "jellyfin"         (Layer 3: release identity)
#ctx.runtime.release.namespace: "media"            (Layer 3: overrides env "production")
#ctx.runtime.release.uuid:      "..."              (Layer 3: release identity)
#ctx.runtime.module:            { ... }            (Layer 3: module metadata)
#ctx.runtime.cluster.domain:    "cluster.local"    (Layer 1: platform default)
#ctx.runtime.route.domain:      "example.com"      (Layer 2: environment override)
#ctx.runtime.components:        { ... }            (Layer 3: computed per-component)
#ctx.platform.defaultStorageClass: "local-path"    (Layer 1: platform extension)
```

---

## CLI Commands

```bash
# List available environments
opm environment list
```

Output:

```text
NAME      PLATFORM       NAMESPACE    ROUTE DOMAIN
dev       kind-opm-dev   dev          dev.local
staging   acme-prod-01      staging      staging.example.com
prod      acme-prod-01      production   example.com
```

```bash
# Inspect environment details
opm environment show prod
```

Output:

```text
Environment: prod
Platform: acme-prod-01 (kubernetes)
Namespace: production
Route domain: example.com
Cluster domain: cluster.local

Platform capabilities:
  Providers: opm, k8up, cert-manager, gateway-api, kubernetes
  Total transformers: 41
```

---

## Related Documents

- [03-schema.md](03-schema.md) — `#Environment`, `#EnvironmentContext` schema definitions
- [04-platform.md](04-platform.md) — `#Platform` construct that environments target
- [06-module-integration.md](06-module-integration.md) — how `#ModuleRelease` targets an environment
