# The `#Platform` Construct

## Purpose

`#Platform` is a pure capability manifest for a cluster. It composes a base provider with zero or more capability providers into a unified transformer registry (`#composedTransformers`), and contributes platform-level `#ctx` defaults (cluster domain, platform extensions) typed as `#PlatformContext` (see [03-schema.md](03-schema.md)).

`#Platform` carries no runtime connection details (kubeContext, kubeConfig). Those are sourced externally. See [03-schema.md](03-schema.md) for the formal CUE definition.

---

## File Layout

```text
.opm/
  platforms/
    acme-prod-01/
      platform.cue
    kind-opm-dev/
      platform.cue
```

Each platform is its own CUE package under `.opm/platforms/<name>/`. The package name is the platform name with hyphens replaced by underscores.

---

## Defining a Platform

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

---

## How Composition Works

Each provider exports a `#transformers` map keyed by transformer FQN. `#Platform` unifies all provider maps into `#composedTransformers` via CUE struct unification:

```text
Base Kubernetes Provider (#transformers):
  opmodel.dev/.../deployment-transformer@v1:  DeploymentTransformer
  opmodel.dev/.../service-transformer@v1:     ServiceTransformer
  opmodel.dev/.../pvc-transformer@v1:         PVCTransformer
  ... (16 total)

K8up Capability Provider (#transformers):
  opmodel.dev/.../schedule-transformer@v1:       ScheduleTransformer
  opmodel.dev/.../pre-backup-pod-transformer@v1: PreBackupPodTransformer
  ... (4 total)

CUE Unification -> #composedTransformers:
  All 20 transformers in one map
```

FQNs are globally unique by construction (module path prefix). Maps from different providers merge cleanly. If two providers register the same FQN, CUE unification errors — which is correct behavior. FQN collision indicates a genuine conflict that must be resolved by the platform operator.

---

## Provider Ordering

The `#providers` list is ordered. Earlier entries have higher priority. Priority applies when multiple transformers from different providers match the same component (same `requiredLabels`, `requiredResources`, `requiredTraits`): the transformer from the higher-priority provider wins.

Example: both `opm.#Provider` and `kubernetes.#Provider` may include a `DeploymentTransformer`. They carry different FQNs, so both enter `#composedTransformers` without collision. When both match a given component, the OPM transformer (priority 1) is selected over the generic Kubernetes transformer (lower priority). The exact conflict detection and resolution rules are specified in [06-module-integration.md](06-module-integration.md).

---

## Different Capabilities per Environment

The same module deploys unchanged to platforms with different provider sets. A module deployed to a platform that includes `k8up.#Provider` receives backup transformers; deployed to a platform without K8up, those transformers are absent from `#composedTransformers` and are never matched. Claim fulfillment and capability warnings are covered by [enhancement 006](../006-claim-primitive/).

---

## Capability Module Author Experience

No new pattern is required. Providers already export a `#transformers` map. The only addition this enhancement requires is `metadata.type` on the provider:

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

## Related Documents

- [03-schema.md](03-schema.md) — `#Platform` schema definition: `#composedTransformers`, `#provider`, `#declaredResources`
- [05-environment.md](05-environment.md) — `#Environment` targets a `#Platform`
- [06-module-integration.md](06-module-integration.md) — how the CLI extracts the composed provider and resolves transformer conflicts
