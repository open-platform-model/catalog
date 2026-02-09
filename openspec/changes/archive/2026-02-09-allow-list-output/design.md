## Context

`#Component` is a closed struct that aggregates resources, traits, and blueprints into a unified `spec`. Transformers consume components and produce provider-specific output — currently always a single object (`{apiVersion, kind, ...}`), except for `#PVCTransformer` which produces a keyed map (`{volumeName: {apiVersion, kind, ...}, ...}`).

The CLI and other consumers need to know whether a transformer's output is a single object or a map so they can correctly serialize/iterate results. Today this knowledge is implicit — only the PVC transformer produces map output, and only because `#VolumesResource` uses a map-based `#spec`. There is no signal on the component itself.

The codebase already distinguishes between labels ("used for definition selection and matching") and annotations ("behavior hints, not used for categorization"). `#Component` already inherits annotations from its resources automatically (`component.cue:40-43`).

## Goals / Non-Goals

**Goals:**

- Signal to consumers that a component's transformer output is a map rather than a single object
- Use the existing annotation propagation mechanism — no schema changes to `#Component`
- Keep the signal runtime-agnostic — it describes output shape, not provider-specific behavior

**Non-Goals:**

- Changing transformer output structures (PVC transformer already works correctly)
- Adding list-output awareness to transformers themselves (consumers read the annotation, transformers don't need to)
- Supporting dynamic/conditional output shapes within a single transformer

## Decisions

### 1. Use an annotation instead of a top-level field

Place the signal as a `transformer.opmodel.dev/list-output` annotation on the resource, not as a new field on `#Component`.

```cue
#VolumesResource: close(core.#Resource & {
    metadata: {
        // ...existing fields...
        annotations: {
            "transformer.opmodel.dev/list-output": true
        }
    }
    // ...
})
```

The annotation propagates to the component automatically via the existing inheritance comprehension in `component.cue`:

```cue
annotations?: {
    for _, resource in #resources if resource.metadata.annotations != _|_ {
        for ak, av in resource.metadata.annotations {
            (ak): av
        }
    }
}
```

**Rationale:**
- Annotations are already defined as "behavior hints" in the codebase — this is exactly that.
- The propagation mechanism is already built and tested. No changes to `#Component` or its closed struct.
- Ownership lives on the resource (`#VolumesResource`), which is the entity that knows it's plural. The component doesn't need to know — it just inherits.
- `#LabelsAnnotationsType` already supports booleans: `[string]: string | int | bool | [...]`.

**Alternative considered:** Top-level `listOutput: *false | bool` field on `#Component`. Rejected because:
- Requires modifying a closed struct in core for what is essentially a behavior hint.
- Requires each composition struct (e.g., `#Volumes`) to manually set the field — the resource can't signal it on its own.
- Adds a dedicated field for a concern that fits naturally into the existing annotation system.

### 2. Annotation lives on the resource, not the composition struct

The annotation is set on `#VolumesResource` directly, not on `#Volumes` (the composition struct).

```
#VolumesResource ──annotation──▶ #Component.metadata.annotations
                    (automatic via existing comprehension)

vs.

#Volumes ──manual set──▶ #Component.listOutput
                          (would require schema change)
```

**Rationale:** The resource is the entity that is intrinsically plural. The composition struct (`#Volumes`) shouldn't have to know about this — it just adds the resource to the component, and the annotation flows automatically.

### 3. Consumer semantics: absence means single output

Consumers check for the annotation and treat its absence as `false` (single output). There is no default value baked into a schema — the annotation is either present or not.

```
if annotations["transformer.opmodel.dev/list-output"] == true → map output
otherwise → single output
```

**Rationale:** This follows standard annotation semantics — presence signals behavior, absence means default behavior. No schema default needed.

### 4. Only plural resources carry the annotation

Plural resources are those whose `#spec` uses a map pattern (`[key=string]: ...`). These resources carry the annotation:

- `#VolumesResource` — `volumes: [volumeName=string]: ...`
- `#ConfigMapsResource` — `configMaps: [name=string]: ...`
- `#SecretsResource` — `secrets: [name=string]: ...`

Singular resources (`#ContainerResource`, `#WorkloadIdentityResource`) do not set the annotation.

Future plural resources follow the same pattern: add `"transformer.opmodel.dev/list-output": true` to their metadata annotations.

## Risks / Trade-offs

**[Less discoverable than a dedicated field]** → Consumers must know the annotation key. Mitigated by documenting the key as a well-known constant and by the sibling CLI change using it explicitly.

**[Multiple plural resources in one component]** → If two plural resources both set the annotation to `true`, CUE unification of `true & true` is `true`. No conflict.

**[Annotation type not constrained]** → The annotation map accepts any value matching `#LabelsAnnotationsType`. A consumer could technically set it to a non-boolean. Mitigated by convention and documentation. A future validation rule could enforce the type if needed.
