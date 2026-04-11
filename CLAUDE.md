# Catalog repository guide

## Purpose

Repo defines + publishes Open Platform Model catalog as versioned CUE modules.
Source of truth for reusable definitions and artifacts. Most changes in `v1alpha1/`, docs, and OpenSpec files.

## Repository Rules

- Guidance from this file, `CONSTITUTION.md`, and Taskfiles.
- Keep changes small; split broad requests into tiny steps.

## Entrypoint

Read on entry:

- Read `CONSTITUTION.md` before changing implementation.
- Read `docs/STYLE.md` before writing/editing docs.
- Keep `v1alpha1/INDEX.md` updated when adding/removing/renaming definitions.
  Run `task generate:index` from `catalog/` to regenerate all INDEX.md files.
  Run `task generate:index:check` to verify INDEX.md files up-to-date.
  Review generated output before commit — script extracts doc comments as descriptions.
  Keep paths relative to `v1alpha1/` (e.g. `core/bundle/bundle.cue`, not absolute).
  Keep Project Structure tree in sync with new/removed directories.

## Repository Layout

```text
adr/                   Architecture Decision Records
v1alpha1/
  core/                Base constructs and primitives
  enhancements/        Design documentation for possible future features and ADRs
  schemas/             Shared schemas and Kubernetes schema mirrors
  resources/           Resource definitions
  traits/              Trait definitions
  blueprints/          Blueprint definitions
  providers/           Providers and transformers
  examples/            Example definitions validated separately
.tasks/                Shared Taskfile fragments
versions.yml           Published module version + checksum
```

## Architecture Decision Records

ADRs capture significant technical decisions with context and consequences.

- Location: `adr/`
- Template: `adr/TEMPLATE.md`
- Naming: `NNN-kebab-case-title.md` (three-digit, zero-padded)

### Creating a new ADR

1. Copy `adr/TEMPLATE.md` to `adr/NNN-title.md` using next available number.
2. Set status to `Proposed`.
3. Fill in Context, Decision, Consequences.
4. Update status to `Accepted` once agreed.

### Updating an ADR

- Never delete ADR — update status instead.
- Retire: set status to `Deprecated`.
- Replace: set status to `Superseded by ADR-NNN`, create new ADR.
- One decision per ADR.

## Environment Notes

- `v1alpha1/cue.mod/module.cue` requires CUE `v0.15.0`+.
- Local env has `cue v0.16.0`.
- Task commands set `CUE_REGISTRY` automatically.
- For raw `cue` commands outside `task`, export:

    ```bash
    export CUE_REGISTRY='opmodel.dev=localhost:5000+insecure,registry.cue.works'
    ```

## Build And Dev Commands

Workflows in `Taskfile.yml`.

### Common Commands

- `task fmt` - run `cue fmt ./...` in `v1alpha1/`
- `task vet` - validate `core/`, `schemas/`, `resources/`, `traits/`, `blueprints/`, `providers/`
- `task vet CONCRETE=true` - same with `cue vet -c`
- `task vet:examples` - validate `v1alpha1/examples/` separately
- `task vet:examples CONCRETE=true` - examples with concreteness checks
- `task test` - run test harness for CUE tests and fixtures
- `task eval` - evaluate all CUE under `v1alpha1/`
- `task eval OUTPUT=out.cue` - write eval output to file
- `task tidy` - run `cue mod tidy` in `v1alpha1/`
- `task check` - run `task fmt` then `task vet`

### Single-Test Workflows

No dedicated single-test Task target. Use raw `cue` commands.

- Run one positive CUE test package:

```bash
cd v1alpha1
cue vet -c -t test ./resources/extension/...
```

- Run one specific `*_tests.cue` file with its package:

```bash
cd v1alpha1
cue vet -c -t test ./resources/extension/... ./resources/extension/crd_tests.cue
```

- Run one data fixture against one definition when `testdata/` fixtures exist:

```bash
cd v1alpha1
cue vet -d '#DefinitionName' ./... path/to/testdata/example_valid_case.yaml
```

- Fixture naming:
  - `*_valid_*.yaml` or `*.json` must pass
  - `*_invalid_*.yaml` or `*.json` must fail

## Test Model Used Here

- Layer 1: `*_tests.cue` tagged `@if(test)` run via `cue vet -c -t test ./...`
- Layer 2: `testdata/*.yaml` and `testdata/*.json` run via `cue vet -d '#Definition'`
- Hidden test fields like `_testSomething` = normal assertion style
- Exported test fields avoided unless test depends on concreteness

## CUE Style Guidelines

### Core Syntax

- `#` prefixes for definitions: `#Module`, `#ContainerResource`, `#ScalingTrait`
- `_` prefixes for hidden fields/scratch bindings: `_secrets`, `_allFields`, `let _k8sName = ...`
- `!` for required, `?` for optional fields
- `*` for explicit defaults
- Prefer `close({...})` for specs that reject unknown fields
- Keep definitions declarative; no imperative/runtime logic

### Packages and File Organization

- Package names short, lowercase, domain-scoped: `module`, `schemas`, `workload`, `transformers`
- Group definitions by domain directory, not file type
- Follow existing filenames: `container.cue`, `scaling.cue`, `secret_transformer.cue`
- Keep tests near definitions using `*_tests.cue`

### Imports

- Use import blocks when file follows that style
- Alias imports for clarity/collision avoidance: `prim`, `schemas`, `k8scorev1`
- Keep aliases short, semantic
- Prefer stable package-level aliases for reused imports when CUE tracking needs it

### Naming

- Definitions: PascalCase with `#` prefix
- Resource/trait names often end in `Resource`, `Trait`, `Defaults`, or transformer suffix
- Metadata `name`: kebab-case strings
- Map keys descriptive, often reused as defaults: `name: string | *key`
- Hidden test names: `_test...`

### Schema Design

- Reuse shared schemas from `opmodel.dev/opm/v1alpha1/schemas@v1` — no duplicating constraints
- Compose via unification, not copying fields
- Keep module/resource/trait/blueprint boundaries clear
- Express intent as schemas+constraints, not procedural validation
- Preserve runtime agnosticism except in provider-specific transformers

### Types and Constraints

- Prefer precise schema types over `_`
- Use regex, list, string constraints for structural validation
- Use comprehensions and `let` bindings for derived values
- Keep schemas OpenAPI-compatible where comments require OpenAPIv3
- Use deterministic computed fields for FQNs, UUIDs, generated names

### Error Handling and Validation

- Prefer failing by constraint+unification over loose schemas
- `cue vet -c` for concrete checks, not just structural validity
- `error()` for custom messages when plain conflict unclear
- Reject invalid config at definition time; no deferring to runtime

### Comments and Documentation

- Comment when intent/dispatch logic/naming non-obvious
- Keep comments technical, specific; no trivial narration
- Preserve existing section-separator styles
- Markdown diagrams/tables: ASCII-safe markers (`[x]`, `[ ]`, `OK`, `FAIL`); no Unicode checkmarks

## Change Discipline

- Validate with `task fmt` and `task vet` before done
- `task vet CONCRETE=true` when changing value-producing definitions or concreteness-dependent tests
- `task vet:examples` if change affects examples or top-level composition
- Update `versions.yml` only for intentional version-management work
- No unrelated cleanup unless it directly helps change

## Commit Guidance

- Conventional Commits: `type(scope): description`
- Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`
- Scope = module/domain: `feat(core): ...`, `fix(traits): ...`
- OpenSpec work: use change-related naming from repository constitution
- Never add AI attribution to commit messages
