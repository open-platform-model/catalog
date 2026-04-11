# Design — `#Platform`, `#Environment` & Provider Composition

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

---

## Design Goals

- `#Platform` composes a base provider with zero or more capability providers into a unified transformer registry
- `#Platform` contributes platform-level `#ctx` defaults (cluster domain, platform extensions) following the enhancement 003 `#ctx` pattern
- `#Environment` is a new construct that targets a `#Platform` and contributes environment-level `#ctx` overrides (namespace, route domain)
- `#ModuleRelease` targets an `#Environment` (not a `#Platform` directly)
- Capability modules (K8up, cert-manager) contribute transformers via their existing provider exports — no new pattern needed
- CUE struct unification handles composition naturally; FQN collisions produce CUE errors (correct behavior)
- The matcher receives the composed transformer map unchanged (no matcher changes for composition)
- `#Platform` is a pure capability manifest — no runtime connection details (kubeContext, kubeConfig); those are sourced externally

## Non-Goals

- Runtime provider discovery (auto-detecting what is installed on the cluster)
- Runtime connection details (kubeContext, kubeConfig) — these belong to a separate runtime config mechanism
- `#Environment` overriding `#config` (values) — environments only contribute to `#ctx`
- Claim/offer changes to `#Transformer`, `#Provider`, and matcher — owned by enhancements [006](../006-claim-primitive/) and [007](../007-offer-primitive/)

---

## Context Hierarchy

`#ctx.runtime` fields are populated through a layered override hierarchy. Each layer can set or override fields from the previous layer. The `#ContextBuilder` (enhancement 003) unifies all layers into the final `#ModuleContext`.

```text
Layer 1: CUE defaults
  cluster.domain: "cluster.local"

Layer 2: #Platform.#ctx
  Platform-level facts — cluster domain, platform extensions
  e.g., cluster.domain: "cluster.local", platform.defaultStorageClass: "local-path"

Layer 3: #Environment.#ctx
  Environment-level overrides — namespace, route domain
  e.g., release.namespace: "dev", route.domain: "dev.example.com"

Layer 4: #ModuleRelease
  Release-level identity — name, uuid, module metadata, components
  Can override namespace: metadata.namespace: "media"
```

Each layer uses the same `#ctx` structure from enhancement 003. CUE unification merges them naturally — concrete values override defaults, later layers override earlier layers.

---

## The `#Platform` Construct

New file: `catalog/core/v1alpha1/platform/platform.cue`

`#Platform` combines platform identity, provider composition, and platform-level context:

```cue
#Platform: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Platform"

    metadata: {
        name!:        #NameType
        description?: string
    }

    // Platform type — all providers must match
    type!: string  // e.g., "kubernetes"

    // Platform-level context contributions (Layer 2)
    // Sets base defaults for #ctx.runtime that environments can override.
    // Uses the same #ctx structure from enhancement 003.
    #ctx: {
        runtime: {
            cluster: {
                domain: *"cluster.local" | string
            }
            route?: {
                domain: string
            }
        }
        // Platform-team extensions — open struct for platform-specific fields.
        // Not schema-validated by OPM; conventions left to platform teams.
        platform: {
            defaultStorageClass?: string
            capabilities?:        [...string]  // Informational — actual capability is provider presence
            ...
        }
    }

    // Provider composition (WITH WHAT)
    // Providers are listed in priority order — first match wins when multiple
    // transformers have the same matching criteria (see Provider Ordering below)
    #providers!: [...provider.#Provider]

    // Composed transformer registry — CUE unification of all providers
    #composedTransformers: transformer.#TransformerMap & {
        for _, p in #providers {
            p.#transformers
        }
    }

    // The composed provider — passed to the matcher unchanged
    #provider: provider.#Provider & {
        metadata: {
            name:        metadata.name
            description: "Platform-composed provider"
            type:        type
            version:     "0.0.0"  // Platform version, not individual provider version
        }
        #transformers: #composedTransformers
    }

    // Auto-computed from composed transformers
    #declaredResources: #provider.#declaredResources
    #declaredTraits:    #provider.#declaredTraits
    // #declaredClaims, #composedOffers, #satisfiedClaims added by enhancements 006/007
}
```

### How Composition Works

CUE struct unification merges transformer maps from all providers. Each transformer has a unique FQN (guaranteed by modulePath prefix), so maps merge cleanly:

```text
Base Kubernetes Provider (#transformers):
  opmodel.dev/.../deployment-transformer@v1:  DeploymentTransformer
  opmodel.dev/.../service-transformer@v1:     ServiceTransformer
  opmodel.dev/.../pvc-transformer@v1:         PVCTransformer
  ... (16 total)

K8up Capability Provider (#transformers):
  opmodel.dev/.../schedule-transformer@v1:      ScheduleTransformer
  opmodel.dev/.../pre-backup-pod-transformer@v1: PreBackupPodTransformer
  ... (4 total)

CUE Unification → #composedTransformers:
  All 20 transformers in one map
```

If two providers register a transformer with the same FQN, CUE unification errors — which is correct. FQN collision means a genuine conflict.

### Provider Ordering

When multiple transformers from different providers match the same component (same `requiredLabels`, `requiredResources`, `requiredTraits`), the provider order determines precedence. The `#providers` list is ordered — earlier providers take priority.

This matters when a platform includes both a domain-specific provider and a generic Kubernetes provider that both handle the same resource type. For example:

```text
Platform providers (in order):
  1. OPM          — DeploymentTransformer (opinionated, OPM-aware)
  2. K8up         — BackupTransformer (domain-specific)
  3. Cert-Manager — CertificateTransformer (domain-specific)
  4. Gateway API  — HTTPRouteTransformer (domain-specific)
  5. Kubernetes   — DeploymentTransformer (generic, full K8s API coverage)
```

Both provider 1 (OPM) and provider 5 (Kubernetes) have a DeploymentTransformer. They have different FQNs (different modulePaths) but match the same components. The platform order says: "use OPM's transformer first; fall back to Kubernetes only for resources OPM doesn't handle."

The render pipeline resolves this: when multiple transformers match a component for overlapping output types, the transformer from the higher-priority provider wins. The exact conflict detection and resolution rules need further design, but the ordering provides the mechanism.

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
        opm.#Provider,           // 1st priority: OPM core
        k8up.#Provider,          // 2nd: backup capability
        certmgr.#Provider,       // 3rd: certificate capability
        gatewayapi.#Provider,    // 4th: gateway routing
        kubernetes.#Provider,    // 5th: generic K8s (catch-all)
    ]
}
```

---

## The `#Environment` Construct

See [05-environment.md](05-environment.md) for full details: schema, file layout, context resolution, and `#ContextBuilder` changes.

`#Environment` targets a `#Platform` and contributes environment-level `#ctx` overrides (namespace, route domain). It is the user-facing deployment target — `#ModuleRelease` embeds an environment, not a platform directly.

New file: `catalog/core/v1alpha1/environment/environment.cue`

```cue
#Environment: {
    apiVersion: "opmodel.dev/core/v1alpha1"
    kind:       "Environment"

    metadata: {
        name!:        #NameType
        description?: string
    }

    #platform!: platform.#Platform

    #ctx: {
        runtime: {
            release: namespace: string
            cluster?: domain:   string
            route?:   domain:   string
        }
        platform: { ... }
    }
}
```

Environments live in `.opm/environments/<env>/environment.cue`. Also available as `#Config.environments` in CLI config (inline or imported from a published CUE module).

---

## Changes to Existing Constructs

### `#Provider` gains `type` field

Providers declare their platform type (e.g., `"kubernetes"`, `"docker-compose"`). All providers within a Platform must share the same type — a Platform is homogeneous.

File: `catalog/core/v1alpha1/provider/provider.cue`

```cue
#Provider: {
    metadata: {
        name:        #NameType
        description: string
        version:     string
        type!:       string          // NEW: e.g., "kubernetes", "docker-compose"
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }
    // ...
}
```

This enables the Platform to validate that all composed providers target the same platform type:

```cue
// All providers in a Platform must have the same type
#Platform: {
    type!: string  // e.g., "kubernetes"
    // Validation: #baseProvider.metadata.type == type
    // Validation: all capability providers have metadata.type == type
}
```

Claim/offer-related changes to `#Transformer`, `#Provider`, and the matcher are owned by their respective enhancements:

- `requiredClaims`/`optionalClaims` on `#Transformer`, `#declaredClaims` on `#Provider`, matcher claim matching → [enhancement 006](../006-claim-primitive/)
- `#offers`, `#declaredOffers` on `#Provider`, `#composedOffers`/`#satisfiedClaims` on `#Platform` → [enhancement 007](../007-offer-primitive/)

---

## Before / After

### Before (manual merge, no composition point):

```cue
// User manually creates a merged provider — undocumented, fragile
import (
    k8s "opmodel.dev/opm/v1alpha1/providers/kubernetes"
    k8up "opmodel.dev/k8up/v1alpha1/providers/kubernetes"
)
customProvider: provider.#Provider & {
    metadata: { name: "custom", description: "manual merge", version: "0.1.0" }
    #transformers: k8s.#Provider.#transformers & k8up.#Provider.#transformers
}
// Then somehow pass customProvider to the matcher...
```

### After (`#Platform` + `#Environment`):

```cue
// .opm/platforms/kind-opm-dev/platform.cue
package kind_opm_dev

import (
    core "opmodel.dev/core/v1alpha1/platform@v1"
    opm "opmodel.dev/opm/v1alpha1/providers/kubernetes"
    k8up "opmodel.dev/k8up/v1alpha1/providers/kubernetes"
    certmgr "opmodel.dev/cert_manager/v1alpha1/providers/kubernetes"
)

#Platform: core.#Platform & {
    metadata: name: "kind-opm-dev"
    type: "kubernetes"
    #ctx: {
        runtime: cluster: domain: "cluster.local"
        platform: defaultStorageClass: "standard"
    }
    #providers: [
        opm.#Provider,       // OPM core transformers (priority 1)
        k8up.#Provider,      // K8up backup transformers
        certmgr.#Provider,   // cert-manager transformers
    ]
}
```

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
// #Environment.#platform.#provider has all 20+ transformers
// #Environment.#platform.#declaredResources / #declaredTraits list available definitions
```

---

## Integration with the Render Pipeline

The render pipeline changes are minimal:

```text
Today:
  CLI loads Provider → passes to #MatchPlan → matcher produces match results

After:
  CLI loads #env → extracts #env.#platform.#provider → passes to #MatchPlan
  CLI merges platform.#ctx + environment.#ctx + release identity → #ContextBuilder → #ModuleContext
  Matcher unchanged
```

The matcher's interface (`#provider: provider.#Provider`) is unchanged. Platform composition and context resolution are layers above the matcher.

### Relationship to Enhancement 003

Enhancement 003 defines `#environment` as an inline optional field on `#ModuleRelease`. This enhancement replaces that with the `#Environment` construct:

| Enhancement 003 (inline) | Enhancement 008 (construct) |
| --- | --- |
| `#ModuleRelease.#environment.clusterDomain` | `#Platform.#ctx.runtime.cluster.domain` |
| `#ModuleRelease.#environment.routeDomain` | `#Environment.#ctx.runtime.route.domain` |
| No namespace default | `#Environment.#ctx.runtime.release.namespace` |
| No platform reference | `#Environment.#platform` references `#Platform` |
| Populated by CLI flags or config | Imported from `.opm/environments/<env>/` via `#ModuleRelease.#env` |

The `#ContextBuilder` inputs change from a single `#environment` struct to the resolved platform + environment + release layers. The output (`#ModuleContext`) is unchanged.
