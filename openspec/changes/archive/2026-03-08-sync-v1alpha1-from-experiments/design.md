## Context

The catalog's `v1alpha1/` CUE definitions have diverged from a refactored version in `../cli/experiments/factory/v1alpha1/`. The experiments version was developed to fix structural issues (monolithic core package, import cycles) and add features (bundle instances, release-prefixed naming, declarative matching). This catalog is the source-of-truth consumed by the CLI and module authors, so it must be updated.

This is a CUE definition sync operation. The experiments directory is the authoritative source; the catalog's `v1alpha1/` gets overwritten. No Go code exists in this repository.

## Goals / Non-Goals

**Goals:**
- Sync all CUE definition files from `../cli/experiments/factory/v1alpha1/` into `v1alpha1/`
- Restructure `v1alpha1/core/` from flat files to per-domain sub-packages
- Add new definitions: `#BundleRelease`, `#BundleInstance`, `#MatchPlan`, `#OpmSecretsComponent`
- Apply release-prefixed naming to all K8s transformer outputs
- Fix HPA and Ingress transformer bugs (missing release-prefix on names and cross-references)
- Add Minecraft bundle examples alongside existing generic examples
- Update `v1alpha1/INDEX.md` to reflect new structure
- Validate all CUE evaluates cleanly after sync (`task vet`)

**Non-Goals:**
- Modifying CLI Go code (separate change in CLI repo)
- Removing the experiments directory after sync
- Changing schema definitions (`v1alpha1/schemas/` — already identical between both)
- Modifying CUE module dependencies (`v1alpha1/cue.mod/`)

## Decisions

### 1. Copy-overwrite strategy (not incremental merge)

The experiments version is the authoritative source. Rather than cherry-picking individual changes, we overwrite the catalog's files with the experiments versions wholesale, then apply bug fixes on top.

**Rationale:** The experiments version was developed as a cohesive refactor. Incremental merging risks introducing inconsistencies between files that were designed to work together. A clean overwrite ensures internal consistency.

**Alternative considered:** File-by-file diff and selective merge — rejected because every file differs (import paths changed globally) and selective merging would be error-prone.

### 2. Fix HPA/Ingress bugs during migration (not after)

The HPA transformer is missing release-prefix on `metadata.name` and `scaleTargetRef.name`. The Ingress transformer is missing release-prefix on `metadata.name` and backend `service.name`. These are fixed as part of this sync.

**Rationale:** Shipping known-broken transformers to the catalog would create immediate issues for anyone using HPA or Ingress. The fixes are small and well-understood.

### 3. Keep both example sets

Generic examples (basic_module, multi_tier, component examples) are preserved. Minecraft examples are added in new subdirectories.

**Rationale:** Generic examples serve as documentation for individual definition types. Minecraft examples demonstrate real-world multi-module bundles. They serve different purposes.

### 4. Phase ordering: core first, then leaf files

Core types must be correct before resources/traits/blueprints/providers can reference them. The migration follows dependency order: core → resources/traits/blueprints → providers/transformers → examples → metadata.

**Rationale:** CUE import resolution requires all referenced packages to exist. Creating core sub-packages first prevents evaluation errors during the sync.

## Risks / Trade-offs

- **[CLI incompatibility]** The new TransformerContext shape (no flat `name`/`namespace`, uses `#moduleReleaseMetadata.namespace`) will break CLI Go code that reads these fields from CUE output. → Mitigation: CLI adaptation is a tracked follow-up change in the CLI repo.

- **[Breaking resource names]** Release-prefixed naming (`"{release}-{component}"`) changes all K8s resource names. Existing deployments would see new resources created alongside old ones. → Mitigation: This is a known breaking change documented in the proposal. Users must re-deploy.

- **[Import path breakage]** Any external CUE modules importing `opmodel.dev/core@v1` will break. → Mitigation: The package split changes internal import paths; external consumers import via the catalog module path.

- **[CUE evaluation failure]** If any file has a typo or incorrect reference after bulk copy, `cue vet` will catch it. → Mitigation: Run `task vet` as the final validation step.
