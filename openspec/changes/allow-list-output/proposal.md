## Why

Transformers currently produce either a single resource or a map of resources (e.g., the PVC transformer emits one PVC per volume entry), but there is no signal on `#Component` to indicate which output shape to expect. Downstream consumers — particularly the CLI — need to know whether a transformer's output is a single object or a keyed map so they can correctly serialize and display results. Without an explicit flag, consumers must hard-code knowledge of which resources are plural, breaking composability.

## What Changes

- Add a `transformer.opmodel.dev/list-output` annotation on plural resources (currently only `#VolumesResource`).
- The annotation propagates to `#Component` automatically via the existing annotation inheritance mechanism — no changes to `#Component` itself.
- Downstream consumers read `component.metadata.annotations["transformer.opmodel.dev/list-output"]` to determine whether output is a single resource or a map. Absence of the annotation means single output (false).
- Only resources whose `#spec` uses a map pattern (plural resources) carry this annotation. Singular resources do not set it.

## Capabilities

### New Capabilities

- `list-output-flag`: An annotation on plural resources that signals whether transformer output should be treated as a list/map. Covers the annotation key, placement on resources, propagation to components, and consumer semantics.

### Modified Capabilities

_(none — no existing spec requirements change)_

## Impact

- **resources/storage module** (`v0/resources/storage/volume.cue`): `#VolumesResource` gains the `transformer.opmodel.dev/list-output: true` annotation on its metadata.
- **core module**: No changes — annotation propagation already exists on `#Component`.
- **providers/kubernetes module**: No transformer changes required. The PVC transformer already produces a map.
- **examples module**: Existing examples continue to work; absence of annotation means single output.
- **SemVer**: MINOR — additive annotation, non-breaking.
- **Sibling change**: A corresponding `allow-list-output` change in the CLI repo will consume this annotation.
