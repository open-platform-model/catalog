# Resource Name Override

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## Current Naming Architecture

All Kubernetes resource names produced by the OPM render pipeline follow two patterns:

- Workloads and services: `{release}-{component}`
- Secrets, ConfigMaps, PVCs: `{release}-{component}-{resource}`
- Immutable resources (any category): `{release}-{component}-{resource}-{hash}`

The content-hash suffix is appended only when the resource is declared immutable. It is derived from the resource's data content and changes when content changes.

Names are computed independently by each transformer using inline string interpolation. There is no shared helper and no central registry. Every transformer that produces a named resource contains its own formula:

```cue
// deployment_transformer.cue — current pattern
_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"

// secret_transformer.cue — current pattern
let _baseName = "\(_relName)-\(_compName)-\(secret.name)"
```

---

## Name Cross-Reference Consensus

Cross-references between Kubernetes resources (e.g., a Deployment referencing a Secret by name, or an HTTPRoute referencing a Gateway by name) work today because every transformer independently re-derives the same formula. There is no lookup, no registry, and no declared dependency. Correctness depends entirely on every transformer applying the same convention.

| Reference type | Producer | Consumer | Formula |
| --- | --- | --- | --- |
| Secret env var ref | SecretTransformer | DeploymentTransformer → `#ToK8sContainer` | `{release}-{secretName}` |
| Secret volume | SecretTransformer | DeploymentTransformer → `#ToK8sVolumes` | `{release}-{component}-{secretName}` |
| ConfigMap volume | ConfigMapTransformer | DeploymentTransformer → `#ToK8sVolumes` | `{release}-{component}-{cmName}[-hash]` |
| PVC volume | PVCTransformer | DeploymentTransformer → `#ToK8sVolumes` | `{release}-{component}-{volumeName}` |
| Gateway parentRef | GatewayTransformer | HTTPRouteTransformer | `{release}-{component}` |

Any deviation in any one transformer silently produces a broken reference at runtime.

---

## Design Flaw: No Override Mechanism

Component names are fixed at module definition time and are embedded in all resource names produced for that component. There is no field that lets a module author specify an alternative K8s base name.

The consequences:

- No way to customize the K8s resource name without modifying `component.metadata.name`.
- Changing `component.metadata.name` changes the names of ALL resources for that component — Deployments, Services, Secrets, ConfigMaps, PVCs — not just one.
- Cross-component references (e.g., an HTTPRoute pointing at a sibling Gateway) must hardcode an assumption about the sibling's transformed name. That name is only known after transformation, at which point the module CUE has already been evaluated.

---

## Concrete Example: The Gateway Module

The `modules/gateway` module defines two components: `gateway` (a Gateway resource) and `httpsRedirect` (an HTTPRoute that redirects HTTP to HTTPS). The HTTPRoute must reference the Gateway by its final Kubernetes name in `parentRefs[0].name`.

```cue
// modules/gateway/components.cue — the problem
httpsRedirect: {
    gw_resources.#HttpRoute
    spec: httpRoute: spec: {
        parentRefs: [{
            name: metadata.name   // BUG: references httpsRedirect's own metadata, not gateway's
            ...
        }]
    }
}
```

The `gateway` component's final K8s name is `{moduleReleaseName}-gateway`. The value of `moduleReleaseName` is supplied at deploy time via `ModuleRelease` — it is not known when the module CUE is authored. The module author cannot write `"\(moduleReleaseName)-gateway"` at definition time; that binding does not exist in the module's evaluation scope.

The current workaround is to reference `metadata.name` of the wrong component, which produces an incorrect `parentRef` in all non-trivial deployments.
