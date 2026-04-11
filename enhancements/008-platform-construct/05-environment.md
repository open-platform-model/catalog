# `#Environment` Construct

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-11       |
| **Authors** | OPM Contributors |

---

## Purpose

`#Environment` is the user-facing deployment target. It binds a name to a `#Platform` (capabilities) and contributes environment-level `#ctx` overrides (namespace, route domain). `#ModuleRelease` targets an environment, not a platform directly.

Separating environment from platform reflects real-world topology: one cluster (platform) hosts multiple environments (dev, staging, prod) that differ in namespace, domains, and context — not in capabilities.

`#Environment` does not override `#config` (values). It only contributes to `#ctx`.

---

## Schema

New file: `catalog/core/v1alpha1/environment/environment.cue`

```cue
#Environment: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Environment"

    metadata: {
        name!:        #NameType
        description?: string
    }

    // Target platform — determines available capabilities and providers.
    // Multiple environments can reference the same platform.
    #platform!: platform.#Platform

    // Environment-level context contributions (Layer 3 in the context hierarchy).
    // Overrides platform-level #ctx defaults for this environment.
    // Uses the same #ctx structure from enhancement 003.
    #ctx: {
        runtime: {
            release: {
                // Default namespace for releases in this environment.
                // Individual ModuleReleases can override via metadata.namespace.
                namespace: string
            }
            cluster?: {
                // Override platform's cluster domain if this environment
                // targets a cluster with a non-default domain.
                domain: string
            }
            route?: {
                // Environment-specific route domain.
                // Typically varies per environment: "dev.example.com" vs "example.com".
                domain: string
            }
        }
        // Inherits platform.platform extensions; can add env-specific extensions.
        platform: { ... }
    }
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

`#Environment.#ctx` is Layer 3 in the context resolution hierarchy:

```text
Layer 1: CUE defaults
  cluster.domain: "cluster.local"

Layer 2: #Platform.#ctx
  Platform-level facts: cluster domain, platform extensions
  e.g., cluster.domain: "cluster.local", platform.defaultStorageClass: "local-path"

Layer 3: #Environment.#ctx                           ← this construct
  Environment-level overrides: namespace, route domain
  e.g., release.namespace: "dev", route.domain: "dev.example.com"

Layer 4: #ModuleRelease
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
#ctx.runtime.release.name:      "jellyfin"        (Layer 4: release identity)
#ctx.runtime.release.namespace: "media"            (Layer 4: overrides env "production")
#ctx.runtime.release.uuid:      "..."              (Layer 4: release identity)
#ctx.runtime.module:            { ... }            (Layer 4: module metadata)
#ctx.runtime.cluster.domain:    "cluster.local"    (Layer 2: platform default)
#ctx.runtime.route.domain:      "example.com"        (Layer 3: environment override)
#ctx.runtime.components:        { ... }            (Layer 4: computed per-component)
#ctx.platform.defaultStorageClass: "local-path"    (Layer 2: platform extension)
```

### `#ContextBuilder` Changes

The `#ContextBuilder` (enhancement 003) gains `#platform` and `#environment` inputs, replacing the inline `#environment` struct:

```cue
#ContextBuilder: {
    #platform:    platform.#Platform
    #environment: environment.#Environment
    #release:     { name: t.#NameType, namespace: string, uuid: t.#UUIDType }
    #module:      { name: t.#NameType, version: t.#VersionType, fqn: string, uuid: t.#UUIDType }
    #components:  [string]: _

    // Resolve cluster domain: environment overrides platform default
    let _clusterDomain = *#environment.#ctx.runtime.cluster.domain |
                         #platform.#ctx.runtime.cluster.domain

    out: ctx.#ModuleContext & {
        runtime: {
            release: #release
            module:  #module
            cluster: domain: _clusterDomain
            if #environment.#ctx.runtime.route != _|_ {
                route: #environment.#ctx.runtime.route
            }
            components: {
                for compName, _ in #components {
                    (compName): {
                        _releaseName:   #release.name
                        _namespace:     #release.namespace
                        _clusterDomain: _clusterDomain
                        _compName:      compName
                    }
                }
            }
        }
        platform: #platform.#ctx.platform & #environment.#ctx.platform
    }
}
```

---

## How `#ModuleRelease` Targets an Environment

`#ModuleRelease` has an `#env` field that imports the target environment. The environment carries the platform reference and context:

```cue
// releases/dev/jellyfin/release.cue
package jellyfin

import (
    jellyfin "opmodel.dev/jellyfin/v1alpha1@v1"
    env "opmodel.dev/config@v1/.opm/environments/dev"
)

#env: env.#Environment

metadata: {
    name:      "jellyfin"
    namespace: "media"  // overrides environment default "dev"
}

#module: jellyfin.#Module

values: {
    port: 8096
    storage: config: {
        type: "pvc"
        size: "20Gi"
    }
}
```

The `#env` field replaces enhancement 003's inline `#environment` struct on `#ModuleRelease`. The release author imports the environment package directly; it carries both the platform reference (capabilities, providers) and the base runtime context.

`metadata.namespace` on the release overrides the environment's default namespace when the release needs a different one.

---

## Relationship to Enhancement 003

Enhancement 003 defines `#environment` as an inline optional field on `#ModuleRelease` with `clusterDomain` and `routeDomain`. This enhancement supersedes that with the `#Environment` construct:

| Enhancement 003 (inline) | Enhancement 008 (`#Environment`) |
| --- | --- |
| `#ModuleRelease.#environment.clusterDomain` | `#Platform.#ctx.runtime.cluster.domain` |
| `#ModuleRelease.#environment.routeDomain` | `#Environment.#ctx.runtime.route.domain` |
| No namespace default | `#Environment.#ctx.runtime.release.namespace` |
| No platform reference | `#Environment.#platform` references `#Platform` |
| Populated by CLI flags or config | Imported from `.opm/environments/<env>/` via `#ModuleRelease.#env` |
| Single flat struct | Layered: Platform → Environment → Release |

The `#ContextBuilder` output (`#ModuleContext`) is unchanged — modules still read `#ctx.runtime.cluster.domain`, `#ctx.runtime.route.domain`, etc. Only the input side changes.

---

## CLI Commands

```bash
# Deploy targeting an environment
opm release apply releases/dev/jellyfin/release.cue --environment dev

# List available environments
opm environment list
```

Output:

```
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

```
Environment: prod
Platform: acme-prod-01 (kubernetes)
Namespace: production
Route domain: example.com
Cluster domain: cluster.local

Platform capabilities:
  Providers: opm, k8up, cert-manager, gateway-api, kubernetes
  Total transformers: 41
```
