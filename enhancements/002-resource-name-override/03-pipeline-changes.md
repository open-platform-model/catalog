# Pipeline Changes (Go + CUE)

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-25       |
| **Authors** | OPM Contributors |

---

## Go: `cli/pkg/render/execute.go`

The existing `injectContext()` function (lines 167–244) builds the CUE context struct that is unified into each transformer before execution. It must be extended with a `resolvedNames` computation step that runs once before the transformer loop, and an injection step inside `injectContext()`.

### New helper: `computeResolvedNames`

```go
// Before executeTransforms loop:
resolvedNames := computeResolvedNames(rel, schemaComponents)

// New helper:
func computeResolvedNames(rel *module.Release, components cue.Value) map[string]string {
    result := map[string]string{}
    // Iterate components; check for metadata.nameOverride
    // If present: use override value
    // If absent: "{releaseName}-{componentName}"
    return result
}
```

The function iterates every component key in the release's `components` struct. For each component it looks up `metadata.nameOverride`. If the field is concrete and present, its string value is used directly. If absent or bottom, the default formula `"{releaseName}-{componentName}"` is applied. The resulting map covers every component key, including those that have no transformer (e.g., config-only components).

### Extended `injectContext`

```go
// Inside injectContext():
unified = unified.FillPath(
    cue.MakePath(cue.Def("context"), cue.Def("resolvedNames")),
    cueCtx.Encode(resolvedNames),
)
```

The `injectContext()` signature gains a `resolvedNames map[string]string` parameter. All existing call sites pass the pre-computed map. No other signature changes are required.

---

## CUE: Catalog Changes

| File | Change |
| --- | --- |
| `catalog/core/v1alpha1/component/component.cue` | Add `nameOverride?: t.#NameType` to `metadata` struct |
| `catalog/core/v1alpha1/transformer/transformer.cue` | Add `#resolvedNames: {[string]: string}` to `#TransformerContext` |
| `catalog/opm/v1alpha1/schemas/resource_name.cue` | New file: `#ResourceName` and `#ResourceNamePrefixed` helpers |
| All 18 transformer files | Replace inline `"\(release)-\(component)"` with `#ResourceName` |
| `container_helpers.cue` | Pass resolved base name instead of raw release/component prefix pair |

---

## Transformer Migration Pattern

Every transformer that computes a Kubernetes resource name must be updated. The before/after pattern is mechanical and uniform across all 18 files.

**Before:**

```cue
_name: "\(#context.#moduleReleaseMetadata.name)-\(#component.metadata.name)"
```

**After:**

```cue
_name: (schemas.#ResourceName & {
    release:   #context.#moduleReleaseMetadata.name
    component: #context.#componentMetadata.name
    if #component.metadata.nameOverride != _|_ {
        override: #component.metadata.nameOverride
    }
}).out
```

Sub-resource names (secrets, ConfigMaps, PVCs) additionally wrap `#ResourceNamePrefixed`:

```cue
_secretName: (schemas.#ResourceNamePrefixed & {
    base:     _name
    resource: secret.name
}).out
```

### Cross-component references in route transformers

Transformers that produce cross-component references (e.g., HTTPRouteTransformer producing a `parentRefs` entry that points at a sibling Gateway) read from `#context.#resolvedNames` instead of re-deriving the formula:

```cue
// Read sibling Gateway's resolved name from context
parentRefs: [{
    name: #context.#resolvedNames[_parentGatewayComponentKey]
    ...
}]
```

`_parentGatewayComponentKey` is the string key of the gateway component as declared in the module's `components` struct (e.g., `"gateway"`). The module author sets this via `nameOverride` on the gateway component; the transformer reads the pre-resolved value from context. No formula is re-derived in the transformer.
