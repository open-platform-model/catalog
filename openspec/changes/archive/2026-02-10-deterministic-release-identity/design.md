## Context

The `core` CUE module (`opmodel.dev/core@v0`) defines `#Module` and `#ModuleRelease` as the foundational types for the OPM model. Currently, neither has a stable identifier beyond its metadata fields (name, fqn, version, namespace). The CLI companion change needs a deterministic, collision-proof UUID on each definition and each deployment slot to label Kubernetes resources for reliable discovery.

CUE v0.15.x provides `uuid.SHA1` as a builtin — UUID v5 generation from a namespace UUID and arbitrary data. This is a pure CUE computation, runtime-agnostic, and deterministic.

**Current `#Module.metadata`:**

```cue
metadata: {
    apiVersion!: #APIVersionType
    name!:       #NameType
    fqn:         #FQNType & "\(apiVersion)#\(_definitionName)"
    version!:    #VersionType
    // ... labels, annotations, etc.
}
```

**Current `#ModuleRelease.metadata`:**

```cue
metadata: {
    name!:      #NameType
    namespace!: string
    fqn:        #module.metadata.fqn
    version:    #module.metadata.version
    // ... labels, annotations
}
```

Both are wrapped in `close({...})`, so new fields must be added inside the struct definition — they cannot be added externally via unification.

## Goals / Non-Goals

**Goals:**

- Add `_OPMNamespace` constant and `#UUIDType` to `common.cue`
- Add computed `metadata.identity` to `#Module` (from fqn + version)
- Add computed `metadata.identity` to `#ModuleRelease` (from fqn + release name + namespace, version excluded)
- Ensure identity is non-overridable by users (CUE unification semantics enforce this naturally)
- Maintain full backwards compatibility with all existing modules

**Non-Goals:**

- CLI changes (separate companion change)
- Exposing identity in labels within the CUE schema (CLI handles label injection)
- Adding identity to `#Component`, `#Policy`, or other types

## Decisions

### Decision 1: `_OPMNamespace` as a hidden definition in `common.cue`

**Choice:** Define the OPM namespace UUID as `_OPMNamespace` (hidden definition, exported via `_#` prefix) in `common.cue`.

**Alternative considered:** Define it in `module.cue` or a new `identity.cue` file.

**Rationale:** `common.cue` already houses shared type definitions (`#NameType`, `#FQNType`, etc.). The namespace UUID is a shared constant used by both `module.cue` and `module_release.cue`. Using `_#` makes it a hidden definition — it won't appear in exported API but is available within the package. A separate file would add structural complexity for a single constant (Principle VII).

### Decision 2: Generate a custom OPM namespace UUID

**Choice:** Generate a new UUID v4 to serve as the OPM namespace, rather than reusing one of the RFC-defined namespace UUIDs (DNS, URL, OID, X.500).

**Rationale:** RFC 4122 namespace UUIDs have specific semantics — DNS namespace is for domain names, URL for URLs, etc. OPM identity strings (`"fqn:version"`) are neither domain names nor URLs. Using a custom namespace UUID avoids semantic confusion and prevents collisions with other systems that might hash similar-looking strings using RFC namespaces.

The UUID will be generated once, documented as immutable, and shared with the CLI codebase.

### Decision 3: `#UUIDType` as a regex constraint

**Choice:** Define `#UUIDType` as a regex-constrained string matching the standard UUID format.

```cue
#UUIDType: string & =~"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
```

**Alternative considered:** Using `uuid.Valid` from the `uuid` builtin for validation.

**Rationale:** A regex constraint is self-documenting, visible in schema inspection, and doesn't require importing `uuid` in `common.cue`. The `uuid` import is only needed in the files that call `uuid.SHA1`. The regex is strict (lowercase hex, standard format) which matches `uuid.SHA1` output exactly.

### Decision 4: Identity field placement inside `metadata`

**Choice:** Place `identity` as a direct field within `metadata`, alongside `fqn`, `version`, etc.

```cue
metadata: {
    // ... existing fields ...
    identity: #UUIDType & uuid.SHA1(_OPMNamespace, "\(fqn):\(version)")
}
```

**Rationale:** Identity is metadata about the definition/release — it belongs in `metadata`. Placing it at the top level would violate the established pattern where all identification fields live in `metadata`. The `#UUIDType &` constraint ensures the computed value is validated at definition time (Principle I).

### Decision 5: Non-settable via CUE unification semantics

**Choice:** The identity field is a concrete computed value. CUE's unification prevents override automatically — no extra validation code needed.

**Verified:** Setting `identity: "custom-value"` on a module produces a CUE conflict error:

```cue
test.identity: conflicting values "27f96e3f-..." and "some-custom-value"
```

**Rationale:** This is the CUE-native way to enforce read-only computed fields. No `error()` builtin or custom validation needed. The field computes to a concrete string, and CUE rejects any conflicting value.

### Decision 6: Release identity input format matches CLI computation

**Choice:** The string passed to `uuid.SHA1` uses colon-separated fields: `"{fqn}:{name}:{namespace}"` for releases, `"{fqn}:{version}"` for modules.

**Rationale:** The CLI must compute release identity in Go (since the release builder works with `#Module`, not `#ModuleRelease`). Both sides must use identical input strings. A simple colon-separated format is unambiguous — none of the constituent fields (fqn, name, namespace, version) can contain colons based on their type constraints (`#NameType`, `#FQNType`, `#VersionType`).

### Decision 7: Update `_testModule` and `_testModuleRelease` inline tests

**Choice:** The existing inline test values (`_testModule`, `_testModuleRelease`) require no changes — `identity` is auto-computed. However, we should verify they still evaluate cleanly after the change.

**Rationale:** Since `identity` is computed from existing required fields that are already set in the test values, CUE will automatically populate it. No explicit `identity` field needs to be added to test fixtures.

## Risks / Trade-offs

**[Risk] OPM namespace UUID must be identical in catalog and CLI.**
→ Mitigation: Document the UUID in both locations with a comment referencing the other. Add a cross-language test in the CLI that evaluates a CUE fixture and compares against Go computation.

**[Risk] `uuid` builtin availability in older CUE versions.**
→ Mitigation: `uuid` has been a CUE builtin since early versions. The project pins CUE v0.15.x. No compatibility concern.

**[Risk] Adding `import "uuid"` to `module.cue` and `module_release.cue` changes their import footprint.**
→ Mitigation: `uuid` is a CUE builtin — it adds no external dependency, no network fetch, no `cue.mod` change. It's equivalent to `import "strings"` which `common.cue` already uses.

**[Trade-off] The `identity` field adds 36 bytes (UUID string) to every module and release evaluation.**
→ Accepted. Negligible overhead. The computation is a single SHA1 hash — microseconds.

## Migration Plan

1. Add `_OPMNamespace`, `#UUIDType` to `common.cue`
2. Add `identity` to `#Module.metadata` and `#ModuleRelease.metadata`
3. Run `cue vet ./...` to validate all existing test fixtures and examples still pass
4. Publish updated `opmodel.dev/core` module to registry
5. CLI change can then consume the new field

**Rollback:** Remove the `identity` field and `uuid` import. No downstream breakage — CLI falls back to empty identity (existing behavior).

## Open Questions

_(none — all decisions resolved during exploration)_
