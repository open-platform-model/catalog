# Problem: Modules Are Blind to Deployment Context

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## The Gap

A `#Module` defines components that reference `#config` for all user-supplied values. This is correct for configuration that the operator provides — image tags, storage sizes, replica counts. It is not correct for values that the runtime already knows and that no operator should need to supply manually.

When a Jellyfin module needs to advertise its public URL, the operator should not have to set `publishedServerUrl: "https://jellyfin.home.example.com"` in their values. The release name is `jellyfin`, the route domain is `home.example.com`, and the URL is a direct derivation. The module author knows the derivation rule. The operator knows the domain. But the module has no way to express that derivation — it cannot see the release name or the route domain at definition time.

The same blindness affects every value that depends on deployment identity.

---

## Affected Categories

### Release identity

The release name and namespace are fixed by the `#ModuleRelease` at deploy time. Components cannot reference them. Any component spec that embeds a release-specific string must either:

- Leave it as a user-supplied `#config` field (forcing the operator to repeat what the runtime already knows), or
- Hardcode a placeholder that will be wrong in any non-default deployment.

### Cluster environment

`clusterDomain` (typically `cluster.local`) and `routeDomain` (e.g., `home.example.com`) are environment properties. They differ between clusters. No module can reference them today because there is no binding for them in the module's evaluation scope.

### Computed Kubernetes resource names

Every Kubernetes resource produced by the render pipeline is named using the pattern `{release}-{component}`. Sub-resources follow `{release}-{component}-{resource}`. Immutable resources append a content hash.

Module components that need to form these names — for example, to set an environment variable pointing to a sibling Service's DNS address — must either hardcode a guess or defer to a user-supplied config value. Neither is correct. The name is deterministic once the release name is known, but the release name is not available in the module's scope.

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

### Content hashes for immutable resources

`#ContentHash` and `#ImmutableName` exist in `catalog/core/v1alpha1/schemas/schemas.cue` and are used by individual transformers to compute names for immutable ConfigMaps and Secrets. The hash is computed from the resource's data map and appended to the resource name to ensure Kubernetes creates a new resource when content changes.

This computation is scattered across transformers. There is no central place where a module component can say "the immutable ConfigMap named `logging` for this component has this content hash." The hash only exists as a side-effect of transformer execution, which happens after module evaluation.

---

## Why `#config` Is Not the Answer

`#config` is the user-values contract. It is constrained to be OpenAPI v3-compatible — no CUE templating, no comprehensions. It represents inputs that operators supply. Adding deployment-identity fields to `#config` would:

- Force operators to re-supply values the runtime already knows
- Break the separation between "what the operator configures" and "what the environment provides"
- Create duplication and potential inconsistency (operator sets `releaseName: "jellyfin"` but the `#ModuleRelease.metadata.name` is `"jellyfin-prod"`)

Runtime context must be a separate input, injected by the runtime rather than supplied by the operator.

---

## Why `#TransformerContext` Is Not the Answer

`#TransformerContext` already carries release metadata and component metadata into transformers. It is the right model for transformer-level concerns. But it exists only in the transformer's evaluation scope. Module components — the `#components` map — are evaluated before transformers run. Components cannot reference `#TransformerContext`.

The consequence: components cannot derive values from release identity, and transformers must produce those values independently. Any time a component needs to know "what will my Service be named?", the information is unavailable until it is too late to use it in the component definition.
