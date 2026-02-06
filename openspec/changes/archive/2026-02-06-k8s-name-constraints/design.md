## Context

`#NameType` is defined in `v0/core/common.cue` as `string & strings.MinRunes(1) & strings.MaxRunes(254)` — no format constraint beyond length. It is used for both `metadata.apiVersion` and `metadata.name` fields across 8 core definitions, despite these fields having fundamentally different value shapes:

- **`name`** values are identifiers like `"Container"`, `"StatelessWorkload"` (currently PascalCase)
- **`apiVersion`** values are domain paths like `"opmodel.dev/resources/workload@v0"` containing `/`, `.`, `@`

Additionally, 5 core definitions (`#Component`, `#Scope`, `#ModuleRelease`, `#BundleRelease`, `#Provider`) use bare `string` for their name fields instead of `#NameType`.

`#FQNType` regex enforces `#([A-Z][a-zA-Z0-9]*)` for the name segment. This PascalCase format must be preserved — it is an established contract.

`#NameSchema` in `v0/schemas/common.cue` is an identical duplicate of `#NameType` that is never referenced — dead code.

## Goals / Non-Goals

**Goals:**

- Enforce RFC 1123 DNS label format on all `name` fields via `#NameType`
- Introduce `#APIVersionType` to correctly constrain `apiVersion` fields
- Define a `#KebabToPascal` function using the Function Pattern for reusable kebab→PascalCase conversion
- Introduce a computed `_definitionName` field that uses `#KebabToPascal` to bridge kebab-case `name` to PascalCase for FQN interpolation
- Apply `#NameType` consistently to all definitions that have a name field
- Migrate all existing name values from PascalCase to kebab-case
- Clean up dead code (`#NameSchema`)

**Non-Goals:**

- Changing `#FQNType` regex or format — PascalCase name segment is preserved
- Changing the `apiVersion` string format itself (domain paths remain as-is)
- Adding namespace validation (separate concern)
- Versioning strategy for this breaking change (handled by release process)
- Fixing the inconsistent `apiVersion` patterns across transformers/providers (e.g., `"core.opmodel.dev/v0"` vs `"opmodel.dev/core/v0"`) — that is a separate issue

## Decisions

### 1. Split `#NameType` into two types

**Decision**: Introduce `#APIVersionType` for `apiVersion` fields; constrain `#NameType` to DNS labels only.

**Rationale**: A single type cannot serve both purposes. `apiVersion` values like `"opmodel.dev/traits/workload@v0"` contain characters (`/`, `.`, `@`) that are invalid DNS labels. Rather than a permissive union type, two purpose-specific types provide better compile-time safety.

**Alternative considered**: A single looser `#NameType` that allows both patterns — rejected because it defeats the purpose of tightening validation.

### 2. `#NameType` regex: `^[a-z0-9]([a-z0-9-]*[a-z0-9])?$` with max 63 chars

**Decision**: Use the Kubernetes DNS label subset of RFC 1123. Max 63 characters (Kubernetes label value limit), not 253 (DNS name limit).

**Rationale**: 63 chars is the Kubernetes limit for labels, namespace names, and most object name segments. 253 is for full DNS names which are not applicable here. The regex requires start/end with alphanumeric to match `kubectl` validation behavior.

**Implementation in CUE**:

```cue
#NameType: string & =~"^[a-z0-9]([a-z0-9-]*[a-z0-9])?$" & strings.MinRunes(1) & strings.MaxRunes(63)
```

The `MinRunes(1)` is technically redundant with the regex (which requires at least one char), but kept for readability. The `MaxRunes(63)` is not redundant — regex alone doesn't enforce length in CUE.

### 3. `#APIVersionType` regex: `^[a-z0-9.-]+(/[a-z0-9.-]+)*@v[0-9]+$`

**Decision**: Extract the apiVersion portion of `#FQNType`'s regex as a standalone type.

**Rationale**: This regex already exists implicitly in `#FQNType`. Making it explicit via `#APIVersionType` ensures `metadata.apiVersion` values are validated independently, not just when they happen to be interpolated into an FQN. Length constraint: `strings.MinRunes(1) & strings.MaxRunes(254)` retained from the original `#NameType`.

**Note**: The top-level `apiVersion` fields on core definitions (e.g., `apiVersion: "opmodel.dev/core/v0"`) are constrained to constant strings and don't use `@v` format. These remain string literals and don't need `#APIVersionType`. Only `metadata.apiVersion!` fields use the type.

### 4. Preserve `#FQNType` — introduce `#KebabToPascal` function and `_definitionName` field

**Decision**: Keep `#FQNType` regex unchanged. Define a reusable `#KebabToPascal` function in `v0/core/common.cue` using the Function Pattern (consistent with `#Matches` in `transformer.cue` and `#MatchTransformers` in `provider.cue`). Each definition's `metadata` block uses this function to compute a hidden `_definitionName` field, which the `fqn` field interpolates instead of `name`.

**Rationale**: The FQN PascalCase format is an established contract. Changing it would break external references and tooling. CUE's `strings` package has no built-in kebab→PascalCase function (`strings.ToTitle` and `strings.ToCamel` do not treat hyphens as word boundaries), so a custom function is needed. The Function Pattern keeps the conversion logic in one place and avoids duplicating it across 8 definition files.

**`#KebabToPascal` function** (defined in `v0/core/common.cue`, verified working in CUE v0.15.4):

```cue
#KebabToPascal: {
    X="in": string
    let _parts = strings.Split(X, "-")
    out: strings.Join([ for p in _parts {
        let _runes = strings.Runes(p)
        strings.ToUpper(strings.SliceRunes(p, 0, 1)) + strings.SliceRunes(p, 1, len(_runes))
    }], "")
}
```

Invoked via the standard Function Pattern: `(#KebabToPascal & {"in": value}).out`

**Usage in definitions** (each of the 8 definitions with an `fqn` field):

```cue
metadata: {
    name!:       #NameType
    apiVersion!: #APIVersionType
    _definitionName: (#KebabToPascal & {"in": name}).out
    fqn: #FQNType & "\(apiVersion)#\(_definitionName)"
}
```

**Conversion examples**:

| `name` (kebab) | `_definitionName` (PascalCase) | `fqn` |
|---|---|---|
| `"container"` | `"Container"` | `"...@v0#Container"` |
| `"stateless-workload"` | `"StatelessWorkload"` | `"...@v0#StatelessWorkload"` |
| `"pvc-transformer"` | `"PvcTransformer"` | `"...@v1#PvcTransformer"` |
| `"cron-job-config"` | `"CronJobConfig"` | `"...@v0#CronJobConfig"` |
| `"a"` | `"A"` | `"...@v0#A"` |

**Trade-off**: Acronyms lose their all-caps form (`PVC` → `Pvc`). This is acceptable because the conversion is mechanical and deterministic — given a `name`, the `_definitionName` and `fqn` are always predictable.

**Alternative considered**: Changing `#FQNType` to accept kebab-case — rejected because it breaks the established PascalCase FQN contract.

**Alternative considered**: A user-provided PascalCase field instead of computed — rejected because it introduces redundancy and risk of mismatch between `name` and the PascalCase value.

**Alternative considered**: Inlining the conversion logic in each definition's metadata — rejected because it duplicates logic across 8 files. The Function Pattern centralizes it in `common.cue`.

### 5. Remove `#NameSchema` from `v0/schemas/common.cue`

**Decision**: Remove rather than sync.

**Rationale**: It is dead code — zero references anywhere in the codebase. Keeping a synchronized duplicate invites drift. If `schemas` needs a name type in the future, it should import from `core`.

**Alternative considered**: Update `#NameSchema` to match — rejected because maintaining two identical definitions violates DRY and the Simplicity principle.

### 6. Name conversion: PascalCase to kebab-case

**Decision**: Mechanical conversion — insert hyphen before each uppercase letter boundary, then lowercase. Consecutive uppercase runs (acronyms like `PVC`) are treated as a single word.

**Mapping for acronym handling**:

| PascalCase | kebab-case |
|---|---|
| `Container` | `container` |
| `StatelessWorkload` | `stateless-workload` |
| `PVCTransformer` | `pvc-transformer` |
| `CronJobConfig` | `cron-job-config` |
| `SidecarContainers` | `sidecar-containers` |

**Rationale**: This matches the convention already used for component instance names (e.g., `"basic-component"`, `"test-deployment"`) and Kubernetes resource naming conventions.

### 7. Execution order: core types first, then fan out

**Decision**: Modify `v0/core/common.cue` first, then update core definitions, then downstream modules in dependency order.

**Rationale**: Core changes will immediately cause validation failures in downstream modules. Working in dependency order (core → schemas → resources/traits/blueprints/policies → providers → examples) ensures `cue vet` passes at each stage. Each module can be committed independently with Conventional Commits scoping.

## Risks / Trade-offs

**[Breaking change across all modules]** → Every module with definition instances needs updating. Mitigation: mechanical transformation, `cue vet ./...` validates completeness.

**[FQN value changes for acronym names]** → Definitions with acronym names (e.g., `PVCTransformer`) will have different FQN values (`#PvcTransformer` instead of `#PVCTransformer`). Mitigation: pre-v1 software, documented as MAJOR change. The FQN _format_ is preserved, only specific values change.

**[63 char limit may be too restrictive for some names]** → Current max was 254. No existing name exceeds 63 chars, so no practical impact. If future names need more, the limit can be raised.

**[Computed field adds indirection]** → `_definitionName` is a hidden field that users don't set directly but affects the FQN. Mitigation: it is deterministic and computed via `#KebabToPascal` — no user action needed. The `_` prefix signals it is internal/computed per CUE conventions.

## Migration Plan

1. Update `v0/core/common.cue` — redefine `#NameType`, add `#APIVersionType`, add `#KebabToPascal` function (keep `#FQNType` unchanged)
2. Update all core definitions (`v0/core/*.cue`) — retype `apiVersion` fields, apply `#NameType` to bare `string` name fields, add `_definitionName: (#KebabToPascal & {"in": name}).out`, update `fqn` interpolation to use `_definitionName`
3. Update `v0/schemas/common.cue` — remove `#NameSchema`
4. Update downstream modules in dependency order — migrate all name values and FQN reference keys
5. Run `cue vet ./...` in each module directory after changes
6. Run `cue fmt ./...` across the entire repo

Rollback: revert the commits. No data migration or state changes involved.
