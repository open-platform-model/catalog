## Context

The `#TransformerContext` is the bridge between OPM metadata and rendered provider resources. It receives module release and component metadata, computes label/annotation groups, and merges them into the final `labels` and `annotations` applied to output resources.

Current state (local, unpublished):
- `#TransformerContext.#moduleReleaseMetadata` is already typed as `#ModuleRelease.metadata` and `#componentMetadata` as `#Component.metadata` in local `transformer.cue`
- `#Module.metadata.labels` already includes `module.opmodel.dev/uuid` locally
- `#ModuleRelease.metadata.labels` already includes `module-release.opmodel.dev/uuid` locally
- The provider `test_data.cue` still uses the old `#moduleMetadata` field name with a freeform struct — this evaluates against the **published** `core@v0.1.12` which still has `#moduleMetadata: _`
- `transformer.opmodel.dev/*` annotations (e.g., `list-output`) propagate from components through `componentAnnotations` to the merged `annotations` on rendered resources — they should be stripped

## Goals / Non-Goals

**Goals:**
- Identity labels (`module.opmodel.dev/uuid`, `module-release.opmodel.dev/uuid`) appear on all rendered provider resources via `moduleLabels`
- `#TransformerContext` metadata fields are schema-validated against `#ModuleRelease.metadata` and `#Component.metadata`
- Pipeline-internal `transformer.opmodel.dev/*` labels and annotations are filtered from `componentLabels` and `componentAnnotations` before reaching rendered output
- Test fixtures satisfy the typed metadata constraints
- Publish updated `core` module so downstream modules resolve the new definitions

**Non-Goals:**
- Changing the `#Matches` logic — matching still operates on unfiltered `component.metadata.labels`
- Introducing a general label classification system (e.g., matchLabels vs outputLabels on `#Resource`/`#Trait`)
- Filtering `moduleLabels` — module-level labels are identity/ownership labels that always belong on output
- Changing label keys or naming conventions — the current `module.opmodel.dev/*` and `module-release.opmodel.dev/*` conventions are kept as-is

## Decisions

### 1. Filter by prefix convention in `#TransformerContext`

**Decision:** Add `strings.HasPrefix` filtering in `componentLabels` and `componentAnnotations` comprehensions to exclude keys starting with `transformer.opmodel.dev/`.

**Rationale:** This is the lightest-touch approach — a single prefix convention, applied in one place (`transformer.cue`), with no schema changes to `#Resource`, `#Trait`, or `#Component`. The `transformer.opmodel.dev/` prefix is already used by `list-output` and establishes the convention for pipeline-internal signals.

**Alternative considered:** Source-based separation (adding `matchLabels` field to `#Resource`/`#Trait` metadata). Rejected because it changes the resource/trait schema, increases surface area, and the prefix convention is sufficient for current needs.

**Implementation:** Add `import "strings"` to `transformer.cue` and wrap the `componentLabels` and `componentAnnotations` comprehensions:

```cue
componentLabels: {
    "app.kubernetes.io/name": #componentMetadata.name
    if #componentMetadata.labels != _|_ {
        for k, v in #componentMetadata.labels
        if !strings.HasPrefix(k, "transformer.opmodel.dev/") {
            (k): "\(v)"
        }
    }
}

componentAnnotations: {
    if #componentMetadata.annotations != _|_ {
        for k, v in #componentMetadata.annotations
        if !strings.HasPrefix(k, "transformer.opmodel.dev/") {
            (k): "\(v)"
        }
    }
}
```

### 2. Test fixtures constructed locally in `test_data.cue`

**Decision:** Replace the freeform `#moduleMetadata` struct in `test_data.cue` with locally-constructed `_testModule` (`core.#Module`), `_testModuleRelease` (`core.#ModuleRelease`), and `_testComponent` (`core.#Component`) fixtures. Reference their `.metadata` fields in `_testContext` to satisfy the typed metadata constraints.

**Rationale:** CUE's `_`-prefixed fields are package-private — `core._testModuleRelease` cannot be referenced from the `providers` package. Constructing local fixtures typed against the core definitions guarantees schema compatibility while respecting CUE's visibility rules.

**Implementation:**

```cue
_testModule: core.#Module & {
    metadata: {
        apiVersion: "test.module.dev/modules@v0"
        name:       "test-module"
        version:    "0.1.0"
    }
    // ...config and values...
}

_testModuleRelease: core.#ModuleRelease & {
    metadata: {
        name:      "test-release"
        namespace: "default"
    }
    #module: _testModule
    values: { ... }
}

_testContext: core.#TransformerContext & {
    #moduleReleaseMetadata: _testModuleRelease.metadata
    #componentMetadata:     _testComponent.metadata
    name:      "test-release"
    namespace: "default"
}
```

### 3. No filtering on `moduleLabels` or `moduleAnnotations`

**Decision:** Module-level labels (including identity UUIDs, name, version) are never filtered. Only `componentLabels` and `componentAnnotations` are filtered.

**Rationale:** Module labels are ownership/identity labels that must appear on every rendered resource. There is no current or foreseeable need for pipeline-internal module labels. If that changes, the same prefix convention can be applied to `moduleLabels` later.

## Risks / Trade-offs

**[CUE `strings.HasPrefix` in comprehension guards]** → CUE evaluates comprehension guards lazily. `strings.HasPrefix` is a pure function on concrete strings, so this is safe. Verified with CUE v0.15.4.

**[`close()` and definition fields]** → `#TransformerContext` uses `close()` but CUE's `close()` does not restrict `#`-prefixed definition fields. This means renaming `#moduleMetadata` to `#moduleReleaseMetadata` doesn't cause a conflict with stale references in the same package — but it also means stale references silently introduce new unconstrained fields. The fix is ensuring test_data.cue uses the correct field names after the change.

**[Published vs local divergence]** → The local `core` module has already diverged from published `core@v0.1.12`. All downstream modules (providers, examples, etc.) resolve against the published version. After implementation, `core` must be published and all downstream modules must `tidy` to pick up the new version. This is the standard cascade publish workflow.

**[Test fixture coupling]** → Provider test fixtures are locally constructed but typed against core definitions (`core.#Module`, `core.#ModuleRelease`, `core.#Component`). If core's metadata schema changes, provider test fixtures will fail to evaluate — this is intentional, as it surfaces type mismatches immediately. The local construction avoids cross-module references to `_`-prefixed (package-private) fields.

## Open Questions

None — all decisions were resolved during exploration.
