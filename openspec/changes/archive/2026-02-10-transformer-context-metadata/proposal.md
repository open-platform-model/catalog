## Why

`#TransformerContext` metadata fields are untyped (`_`) in the published `core@v0.1.12`, meaning transformers operate without schema validation on the metadata they receive. The `module-id` label exists locally on `#Module` but is not published, and `#ModuleRelease` has no `release-id` label at all — so rendered K8s resources carry no identity labels. Additionally, `transformer.opmodel.dev/*` annotations (like `list-output`) flow through to K8s resource output despite being pipeline-internal signals.

## What Changes

- **BREAKING**: `#TransformerContext.#moduleReleaseMetadata` typed as `#ModuleRelease.metadata` instead of `_` (previously `#moduleMetadata: _`)
- **BREAKING**: `#TransformerContext.#componentMetadata` typed as `#Component.metadata` instead of `_`
- Add `module-release.opmodel.dev/uuid` label to `#ModuleRelease.metadata.labels`, computed from `uuid`
- Ensure `module.opmodel.dev/uuid` label on `#Module.metadata.labels` is published (exists locally, missing from published `core@v0.1.12`)
- Filter `transformer.opmodel.dev/*` labels and annotations from `componentLabels` and `componentAnnotations` in `#TransformerContext`, so they never reach K8s resource output
- Update provider test fixtures (`test_data.cue`) to satisfy the new typed metadata constraints

This is a **MINOR** change (new labels, stricter typing). The breaking rename from `#moduleMetadata` to `#moduleReleaseMetadata` only affects downstream consumers who directly reference the hidden field — the published API already uses `#moduleMetadata: _` which no external consumer should depend on for structure.

## Capabilities

### New Capabilities

- `release-identity-label`: Requirements for the `module-release.opmodel.dev/uuid` label on `#ModuleRelease.metadata.labels`
- `transformer-label-filtering`: Requirements for stripping `transformer.opmodel.dev/*` labels and annotations from K8s resource output in `#TransformerContext`

### Modified Capabilities

- `module-identity`: Adding requirement that `module.opmodel.dev/uuid` label is present on `#Module.metadata.labels` and propagates through `#ModuleRelease` to K8s resources
- `list-output-flag`: Adding requirement that `transformer.opmodel.dev/*` annotations are filtered from K8s output (the annotation still propagates to components for pipeline use, but `#TransformerContext` strips it from rendered output)

## Impact

- **core module**: `module.cue`, `module_release.cue`, `transformer.cue`, `component.cue` (read-only, metadata shape reference)
- **providers module**: `transformers/test_data.cue` — must supply full `#ModuleRelease.metadata` and `#Component.metadata` shapes
- **All downstream modules** (providers, examples, blueprints): Must `tidy` after core is republished to pick up new version
- **External consumers**: Any code constructing `#TransformerContext` manually must provide typed metadata instead of freeform structs
