# Solution: Name Override + Resolved Names Context

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## Design Goals

- Allow module authors to specify a custom K8s base name for any component
- Allow cross-component name references within a module without knowing the release name at authoring time
- Preserve existing default behavior (`{release}-{component}`) when no override is set
- Single source of truth for name computation — no more convention consensus across transformers
- Immutability content-hash suffix is always appended regardless of whether an override is set

---

## Non-Goals (v1)

- Cross-module name references
- Release-author name overrides (deployment-time override via `ModuleRelease.values`)
- Per-resource sub-name overrides (component-level base name only; sub-resource names remain derived)

---

## Schema Changes

### 1. `#Component.metadata.nameOverride`

A new optional field on every component's metadata block:

```cue
// catalog/core/v1alpha1/component/component.cue
#Component: {
    metadata: {
        name!:         t.#NameType
        nameOverride?: t.#NameType   // Optional. If set, replaces {release}-{component} as the K8s base name.
        labels?:       t.#LabelsAnnotationsType
        annotations?:  t.#LabelsAnnotationsType
    }
    ...
}
```

`nameOverride` must satisfy `t.#NameType` — the same DNS label-safe constraint as `metadata.name`. When absent, all existing behavior is unchanged.

### 2. `#TransformerContext.#resolvedNames`

A new map field injected into every transformer's context by the Go pipeline:

```cue
// catalog/core/v1alpha1/transformer/transformer.cue
#TransformerContext: {
    ...
    // resolvedNames maps every component key in the current release to its
    // computed K8s base name. Transformers use this for cross-component references.
    #resolvedNames: {[string]: string}
}
```

The map is keyed by component key (the field name in the `components` struct, e.g., `"gateway"`). The value is the fully resolved K8s base name for that component — either the override value or the default formula result.

---

## `#ResourceName` Helper

A new shared helper replaces all inline `"\(release)-\(component)"` string interpolations across all transformer files:

```cue
// catalog/opm/v1alpha1/schemas/resource_name.cue
#ResourceName: {
    release:   string
    component: string
    override?: string
    out:       string
    if override != _|_ { out: override }
    if override == _|_ { out: "\(release)-\(component)" }
}

// Variant for sub-resources (secrets, configmaps, PVCs)
#ResourceNamePrefixed: {
    base:     string   // output of #ResourceName
    resource: string   // sub-resource identifier
    out:      "\(base)-\(resource)"
}
```

`override` must satisfy `t.#NameType`. The `#ResourceNamePrefixed` helper derives sub-resource names from the resolved base name, so overrides propagate automatically to all derived names.

---

## Name Resolution Flow

The Go pipeline resolves names before the transformer loop runs and injects the result into every transformer's context:

```
ModuleRelease
  → components: {gateway: {metadata: nameOverride: "main-gw"}, ...}
  → Go pipeline pre-computes resolvedNames map:
      resolvedNames["gateway"]       = "main-gw"                // nameOverride wins
      resolvedNames["httpsRedirect"] = "prod-v1-httpsRedirect"  // default formula
  → resolvedNames injected into #TransformerContext
  → Transformers read #context.#resolvedNames["gateway"] for cross-refs
```

Transformers do not compute cross-component names themselves. They read the pre-computed map. This eliminates the convention-consensus problem: there is one computation site and one result.

---

## Cross-Component Reference Pattern (Module Author)

When a component needs to reference a sibling's K8s name, the module author:

1. Sets `nameOverride` on the sibling, making the name stable and known at definition time
2. References that override value via CUE struct cross-reference — no runtime lookup required

```cue
// modules/gateway/components.cue — corrected
#components: {
    gateway: {
        gw_resources.#Gateway
        metadata: nameOverride: #config.gateway.name | *"main-gateway"
        spec: gateway: { ... }
    }
    if #config.httpRedirect.enabled {
        httpsRedirect: {
            gw_resources.#HttpRoute
            spec: httpRoute: spec: {
                parentRefs: [{
                    // CUE struct cross-reference — resolves at definition time
                    name: #components.gateway.metadata.nameOverride
                    ...
                }]
            }
        }
    }
}
```

This works because `#components` is a CUE value — sibling fields can be referenced directly within the same struct. No new language features are required. The cross-reference is evaluated by CUE at module evaluation time, before the Go pipeline runs.

At transform time, the HTTPRoute transformer reads `#context.#resolvedNames["gateway"]` to produce the correct `parentRefs[0].name` in the output manifest.

---

## Immutability Hash Interaction

The content-hash suffix is appended after name resolution. The override replaces only the base name segment; immutability behavior is unchanged:

```
nameOverride: "my-secret"
immutable: true
→ final K8s name: "my-secret-{contenthash}"
```

Transformers that handle immutable resources apply the hash to the resolved base name, not to the raw formula. The `#ResourceNamePrefixed` helper always takes the resolved `base` as input, so the hash step composes correctly regardless of whether an override was set.
