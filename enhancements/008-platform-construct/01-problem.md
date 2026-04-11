# Problem Statement — `#Platform` Construct & Provider Composition

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

---

## Current State

OPM has a `#Provider` construct that registers transformers. The runtime passes a single provider to the matcher. Today, the Kubernetes provider (`opm/v1alpha1/providers/kubernetes/provider.cue`) registers 16 core transformers. K8up has its own provider (`k8up/v1alpha1/providers/kubernetes/provider.cue`) with 4 backup transformers. These exist independently with no composition mechanism.

RFC-0001 defines a `#Platform` concept for platform identity and context (capabilities, defaultDomain), but this exists only as an RFC — no CUE definition in `core/v1alpha1/`.

## Gap 1: No Composition Point for Capability Providers

When K8up is deployed on a cluster, its backup transformers should be available to the rendering pipeline alongside core transformers. But the runtime receives ONE provider. The only option is manually merging transformer maps:

```cue
// Manual merge — undocumented, fragile
import (
    k8s "opmodel.dev/opm/v1alpha1/providers/kubernetes"
    k8up "opmodel.dev/k8up/v1alpha1/providers/kubernetes"
)
myProvider: provider.#Provider & {
    metadata: { name: "custom", description: "manual merge", version: "0.1.0" }
    #transformers: k8s.#Provider.#transformers & k8up.#Provider.#transformers
}
```

This defeats the modularity of separate capability modules. The CLI cannot reason about which capabilities are available or warn about missing ones.

## Gap 2: RFC-0001's Platform Has No Provider Binding

RFC-0001's `#PlatformContext` includes `capabilities: [...string]` — but this is a string list with no semantic connection to actual providers:

```cue
context: {
    capabilities: ["k8up", "cert-manager"]  // just strings, no effect on rendering
}
```

The platform "knows" it has K8up (as a label) but cannot automatically include K8up's transformers in the rendering pipeline.

## Concrete Example

K8up has its own provider with 4 backup transformers. The cluster has K8up installed. Today there is no way to compose the K8up provider with the base Kubernetes provider and pass the composed transformer set to the matcher.

Claim/offer-specific gaps (`#declaredClaims`, matcher claim matching) are addressed by enhancements [006](../006-claim-primitive/) and [007](../007-offer-primitive/).

## Why Existing Workarounds Fail

Manual provider merging works in CUE but is fragile, undocumented, and invisible to the CLI. The CLI cannot reason about platform capabilities or which providers are composed for a given deployment target.
