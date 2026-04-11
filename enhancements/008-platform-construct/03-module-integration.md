# Module Integration — `#Platform`, `#Environment` & Provider Composition

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

---

## Platform Operator Experience

### Defining a Platform

Platform operators define platforms in `.opm/platforms/<name>/platform.cue`. A platform composes providers in priority order and sets platform-level context defaults:

```cue
// .opm/platforms/acme-prod-01/platform.cue
package acme_prod_01

import (
    core "opmodel.dev/core/v1alpha1/platform@v1"
    opm "opmodel.dev/opm/v1alpha1/providers/kubernetes"
    k8up "opmodel.dev/k8up/v1alpha1/providers/kubernetes"
    certmgr "opmodel.dev/cert_manager/v1alpha1/providers/kubernetes"
    gatewayapi "opmodel.dev/gateway_api/v1alpha1/providers/kubernetes"
    kubernetes "opmodel.dev/kubernetes/v1/providers/kubernetes"
)

#Platform: core.#Platform & {
    metadata: name: "acme-prod-01"
    type: "kubernetes"
    #ctx: {
        runtime: cluster: domain: "cluster.local"
        platform: {
            defaultStorageClass: "local-path"
            capabilities: ["k8up", "cert-manager", "gateway-api"]
        }
    }
    #providers: [
        opm.#Provider,        // OPM core (priority 1)
        k8up.#Provider,       // backup capability
        certmgr.#Provider,    // TLS certificates
        gatewayapi.#Provider, // gateway routing
        kubernetes.#Provider, // generic K8s (catch-all)
    ]
}
```

```cue
// .opm/platforms/kind-opm-dev/platform.cue
package kind_opm_dev

import (
    core "opmodel.dev/core/v1alpha1/platform@v1"
    opm "opmodel.dev/opm/v1alpha1/providers/kubernetes"
    k8up "opmodel.dev/k8up/v1alpha1/providers/kubernetes"
    certmgr "opmodel.dev/cert_manager/v1alpha1/providers/kubernetes"
    kubernetes "opmodel.dev/kubernetes/v1/providers/kubernetes"
)

#Platform: core.#Platform & {
    metadata: name: "kind-opm-dev"
    type: "kubernetes"
    #ctx: {
        runtime: cluster: domain: "cluster.local"
        platform: {
            defaultStorageClass: "standard"
            capabilities: ["k8up", "cert-manager"]
        }
    }
    #providers: [
        opm.#Provider,
        k8up.#Provider,
        certmgr.#Provider,
        kubernetes.#Provider,
    ]
}
```

Provider order matters: when multiple transformers match the same component, the transformer from the higher-priority (earlier) provider wins.

### Defining Environments

Environments target a platform and set environment-level context. Each environment is its own CUE package in `.opm/environments/<env>/environment.cue`, importing the platform it targets:

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

```cue
// .opm/environments/prod/environment.cue
package prod

import (
    core "opmodel.dev/core/v1alpha1/environment@v1"
    platform "opmodel.dev/config@v1/.opm/platforms/acme-prod-01"
)

#Environment: core.#Environment & {
    metadata: name: "prod"
    #platform: platform.#Platform
    #ctx: runtime: {
        release: namespace: "production"
        route: domain: "example.com"
    }
}
```

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

### Different Capabilities per Environment

The same module can deploy to environments backed by platforms with different provider sets. A module deployed to a platform with K8up gets backup transformers; deployed to a platform without K8up, those transformers are absent. Claim fulfillment and warnings are covered by [enhancement 006](../006-claim-primitive/).

---

## Capability Module Author Experience

Capability module authors already follow the right pattern. K8up's provider exists at `k8up/v1alpha1/providers/kubernetes/provider.cue`. No new pattern is needed — this enhancement only requires providers to add `metadata.type`:

```cue
// k8up/v1alpha1/providers/kubernetes/provider.cue
#Provider: provider.#Provider & {
    metadata: {
        name:        "k8up"
        type:        "kubernetes"  // NEW: required for Platform composition
        description: "K8up backup operator transformers"
        version:     "0.1.0"
    }
    #transformers: {
        (schedule_t.metadata.fqn):        schedule_t
        (pre_backup_pod_t.metadata.fqn):  pre_backup_pod_t
        (restore_t.metadata.fqn):         restore_t
        (secret_t.metadata.fqn):          secret_t
    }
}
```

Claim/offer integration for capability modules is covered by enhancements [006](../006-claim-primitive/) and [007](../007-offer-primitive/).

---

## Release Author Experience

### Targeting an Environment

`#ModuleRelease` targets an environment via `#env`. The environment carries the platform reference and context:

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

The `metadata.namespace: "media"` overrides the environment's default namespace (`"dev"`). The context hierarchy resolves:

- `#ctx.runtime.cluster.domain` → `"cluster.local"` (from platform)
- `#ctx.runtime.route.domain` → `"dev.local"` (from environment)
- `#ctx.runtime.release.namespace` → `"media"` (from release, overriding environment's `"dev"`)
- `#ctx.runtime.release.name` → `"jellyfin"` (from release metadata)

---

## CLI Workflow

### Deploy with Environment

```bash
opm release apply releases/dev/jellyfin/release.cue --environment dev
```

The CLI:

1. Loads `#env` from the release (imported from `.opm/environments/<env>/`)
2. Extracts `#env.#platform.#provider` (composed transformer registry)
3. Merges `platform.#ctx` + `environment.#ctx` + release identity via `#ContextBuilder`
4. Runs `#MatchPlan` with the composed provider
5. Renders matched transformers to platform resources

### Check Environment / Platform Capabilities

```bash
opm platform capabilities acme-prod-01
```

Output:

```
Platform: acme-prod-01
Type: kubernetes
Providers (5):
  opm (v0.1.0, 16 transformers)
  k8up (v0.1.0, 4 transformers)
  cert-manager (v0.1.0, 3 transformers)
  gateway-api (v0.1.0, 2 transformers)
  kubernetes (v1.0.0, 16 transformers)

Total transformers: 41
```

```bash
opm environment list
```

Output:

```
NAME      PLATFORM       NAMESPACE    ROUTE DOMAIN
dev       kind-opm-dev   dev          dev.local
staging   acme-prod-01      staging      staging.example.com
prod      acme-prod-01      production   example.com
```

---

## Relationship to Bundle Deployments

Bundles remain provider-agnostic. The environment is selected at deploy time:

```bash
opm bundle apply bundles/media-stack/bundle-release.cue --environment prod
```

All modules in the bundle are rendered against the same environment's platform composed provider. Each module release can override namespace from the environment default.
