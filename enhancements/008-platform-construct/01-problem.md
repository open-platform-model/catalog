# Problem: Module Blindness and Monolithic Providers

## Problem 1: Modules Are Blind to Deployment Context

A `#Module` defines components that reference `#config` for all user-supplied values. This is correct for operator-provided configuration — image tags, storage sizes, replica counts. It is not correct for values that the runtime already knows and that no operator should need to supply manually.

When a Jellyfin module needs to advertise its public URL, the operator should not have to set `publishedServerUrl: "https://jellyfin.home.example.com"` in their values. The release name is `jellyfin`, the route domain is `home.example.com`, and the URL is a direct derivation. The module author knows the derivation rule. The operator knows the domain. But the module has no way to express that derivation — it cannot see the release name or the route domain at definition time.

The same blindness affects every value that depends on deployment identity.

### Affected Categories

**Release identity** — The release name and namespace are fixed by `#ModuleRelease` at deploy time. Components cannot reference them. Any component spec that embeds a release-specific string must either leave it as a user-supplied `#config` field (forcing the operator to repeat what the runtime already knows) or hardcode a placeholder that will be wrong in any non-default deployment.

**Cluster environment** — `clusterDomain` (typically `cluster.local`) and `routeDomain` (e.g., `home.example.com`) are environment properties. They differ between clusters. No module can reference them today because there is no binding for them in the module's evaluation scope.

**Computed Kubernetes resource names** — Every Kubernetes resource produced by the render pipeline follows the pattern `{release}-{component}`. Sub-resources follow `{release}-{component}-{resource}`. Module components that need to form these names — for example, to set an environment variable pointing to a sibling Service's DNS address — must either hardcode a guess or defer to a user-supplied config value. The name is deterministic once the release name is known, but the release name is not available in the module's scope.

```cue
// modules/jellyfin/components.cue — current workaround
// The operator must manually supply the full URL.
// There is no way to derive it from deployment identity.
if #config.publishedServerUrl != _|_ {
    JELLYFIN_PublishedServerUrl: {
        name:  "JELLYFIN_PublishedServerUrl"
        value: #config.publishedServerUrl
    }
}
```

**Content hashes for immutable resources** — `#ContentHash` and `#ImmutableName` exist in `core/v1alpha1/schemas/schemas.cue` and are used by individual transformers to compute names for immutable ConfigMaps and Secrets. This computation is scattered across transformers. There is no central place where a module component can reference the content hash for an immutable resource it depends on. The hash only exists as a side-effect of transformer execution, which happens after module evaluation.

### Why `#config` Is Not the Answer

`#config` is the user-values contract. It is constrained to be OpenAPI v3-compatible — no CUE templating, no comprehensions. Adding deployment-identity fields to `#config` would:

- Force operators to re-supply values the runtime already knows
- Break the separation between "what the operator configures" and "what the environment provides"
- Create duplication and potential inconsistency (operator sets `releaseName: "jellyfin"` but `#ModuleRelease.metadata.name` is `"jellyfin-prod"`)

Runtime context must be a separate input, injected by the runtime rather than supplied by the operator.

### Why `#TransformerContext` Is Not the Answer

`#TransformerContext` already carries release metadata and component metadata into transformers. It is the right model for transformer-level concerns. But it exists only in the transformer's evaluation scope. Module components — the `#components` map — are evaluated before transformers run. Components cannot reference `#TransformerContext`.

The consequence: components cannot derive values from release identity, and transformers must produce those values independently. Any time a component needs to know "what will my Service be named?", the information is unavailable until it is too late to use it in the component definition.

---

## Problem 2: Monolithic Provider — No Composition Point

OPM has a `#Provider` construct that registers transformers. The runtime passes a single provider to the matcher. Today, the Kubernetes provider (`opm/v1alpha1/providers/kubernetes/provider.cue`) registers 16 core transformers. K8up has its own provider (`k8up/v1alpha1/providers/kubernetes/provider.cue`) with 4 backup transformers. These exist independently with no composition mechanism.

RFC-0001 defines a `#Platform` concept for platform identity and context (capabilities, defaultDomain), but this exists only as an RFC — no CUE definition in `core/v1alpha1/`.

### Gap 1: No Composition Point for Capability Providers

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

### Gap 2: RFC-0001's Platform Has No Provider Binding

RFC-0001's `#PlatformContext` includes `capabilities: [...string]` — but this is a string list with no semantic connection to actual providers:

```cue
context: {
    capabilities: ["k8up", "cert-manager"]  // just strings, no effect on rendering
}
```

The platform "knows" it has K8up (as a label) but cannot automatically include K8up's transformers in the rendering pipeline.

### Concrete Example

K8up has its own provider with 4 backup transformers. The cluster has K8up installed. Today there is no way to compose the K8up provider with the base Kubernetes provider and pass the composed transformer set to the matcher.

Claim/offer-specific gaps (`#declaredClaims`, matcher claim matching) are addressed by enhancements [006](../006-claim-primitive/) and [007](../007-offer-primitive/).

### Why Existing Workarounds Fail

Manual provider merging works in CUE but is fragile, undocumented, and invisible to the CLI. The CLI cannot reason about platform capabilities or which providers are composed for a given deployment target.
