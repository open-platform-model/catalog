## Why

`#NameType` currently allows any string between 1-254 characters with no format constraints. This is too permissive — names flow into Kubernetes object metadata (labels, resource names, namespaces) where they must conform to RFC 1123 DNS label rules. Enforcing this at definition time prevents runtime failures and aligns with the Type Safety First principle. It also improves CLI tooling that relies on predictable name formats.

## What Changes

- **BREAKING**: Redefine `#NameType` in `v0/core/common.cue` to enforce Kubernetes DNS label format: lowercase alphanumeric with hyphens, max 63 characters (RFC 1123)
- **BREAKING**: Introduce `#APIVersionType` to replace `#NameType` on `apiVersion` fields, since apiVersion values contain `/`, `@`, `.` characters that are incompatible with DNS labels
- Introduce a computed `_definitionName` field that converts kebab-case `name` to PascalCase for FQN interpolation — `#FQNType` regex remains unchanged
- Update all `apiVersion!: #NameType` fields across core definitions to use `#APIVersionType` instead
- Update `#NameSchema` in `v0/schemas/common.cue` to match the new `#NameType` constraint (or remove it — it's currently unused dead code)
- Update all definition `name` field values that currently use PascalCase to conform to the new kebab-case DNS label constraint
- Fix inconsistencies: apply `#NameType` to `#Component`, `#Scope`, `#ModuleRelease`, `#BundleRelease`, and `#Provider` metadata name fields that currently use bare `string`

## Capabilities

### New Capabilities

- `k8s-name-type`: Redefine `#NameType` with DNS label regex, introduce `#APIVersionType`, add `_definitionName` computed field for FQN compatibility, update type assignments across all core definitions
- `name-value-migration`: Migrate all existing `name` values (PascalCase like `"StatelessWorkload"`) to kebab-case DNS-compliant form (like `"stateless-workload"`) and update all references

### Modified Capabilities
<!-- No existing specs to modify -->

## Impact

- **Affected modules**: `core`, `schemas`, `resources`, `traits`, `blueprints`, `policies`, `providers`, `examples` — every module that instantiates a definition with a `name` or `apiVersion` field
- **Breaking change**: This is a breaking change but **no API version bump** — the project is in active pre-v1 development and breaking changes are expected. No SemVer major bump or module version increment will be performed.
- **FQN format preserved**: `#FQNType` regex stays unchanged (`#([A-Z][a-zA-Z0-9]*)`). FQN values will change because PascalCase names are now computed from kebab-case (e.g., `#PVCTransformer` → `#PvcTransformer`), but the PascalCase format is preserved
- **Downstream consumers**: Any external code referencing OPM definitions by PascalCase name will need updating
