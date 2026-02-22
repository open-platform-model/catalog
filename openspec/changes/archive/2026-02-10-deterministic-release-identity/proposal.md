## Why

OPM modules and releases have no stable, deterministic identifier that survives across deployments and version upgrades. The CLI needs a collision-proof identity to label cluster resources for reliable discovery — especially for `mod delete`, `mod status`, and future `mod list`. By adding computed `metadata.identity` fields to `#Module` and `#ModuleRelease` using CUE's `uuid.SHA1` builtin (UUID v5), every definition and deployment slot gets a reproducible identifier derived from its existing metadata fields, with zero user input required.

This is the **catalog side** of a two-part change. A companion CLI change with the same name consumes these identity fields for resource labeling and discovery.

## What Changes

- Add a `OPMNamespace` UUID constant to `core/common.cue` — a fixed UUID v5 namespace for all OPM identity computations
- Add `metadata.identity` (computed, read-only) to `#Module` — UUID v5 of `"{fqn}:{version}"`
- Add `metadata.identity` (computed, read-only) to `#ModuleRelease` — UUID v5 of `"{fqn}:{name}:{namespace}"` (version deliberately excluded for stability across upgrades)
- Add `import "uuid"` to the affected CUE files
- Add a `#UUIDType` validation type to `common.cue` for the identity field

## Capabilities

### New Capabilities

- `module-identity`: Defines the `OPMNamespace` constant, the `#UUIDType` constraint, the identity computation on `#Module.metadata`, and the identity computation on `#ModuleRelease.metadata`

### Modified Capabilities

_(none — no existing catalog specs are affected at the requirement level)_

## Impact

- **SemVer**: MINOR — new computed field added to existing definitions. No breaking changes. All existing modules continue to validate unchanged. The `uuid` field is auto-computed from existing required fields.
- **CUE module affected**: `core` (`opmodel.dev/core@v0`)
- **Files changed**:
  - `v0/core/common.cue` — `OPMNamespace` constant, `#UUIDType`
  - `v0/core/module.cue` — `import "uuid"`, `metadata.identity` field
  - `v0/core/module_release.cue` — `import "uuid"`, `metadata.identity` field
- **API surface**: Non-breaking addition. `metadata.identity` is a computed field — module authors don't set it, it derives from existing fields. The `close()` on both definitions means it must be added inside the struct, not externally.
- **Downstream consumers**: The CLI change (`deterministic-release-identity`) reads `metadata.identity` via `LookupPath`. Older CLI versions that don't read it will silently ignore it. No breakage.
- **Portability**: No provider-specific concerns. UUID computation is pure CUE, runtime-agnostic.
