## Why

The `../cli/experiments/factory/v1alpha1/` directory contains a heavily refactored version of this catalog's `v1alpha1/` CUE definitions. These changes fix structural issues (monolithic `core` package, import cycles), add missing capabilities (BundleRelease, declarative matching), and implement release-aware resource naming to prevent multi-release collisions. The catalog must be updated to incorporate these fixes before further development builds on the stale version. This is a MAJOR change due to breaking resource naming and package restructuring.

## What Changes

- **Core package decomposition**: Split monolithic `package core` (flat files in `v1alpha1/core/`) into per-domain sub-packages (`core/types/`, `core/primitives/`, `core/component/`, `core/module/`, `core/modulerelease/`, `core/bundle/`, `core/bundlerelease/`, `core/provider/`, `core/transformer/`, `core/policy/`, `core/helpers/`, `core/matcher/`)
- **Release-prefixed K8s resource naming**: All transformer outputs now name resources as `"{release}-{component}"` instead of `"{component}"`, enabling multiple releases in one namespace — **BREAKING**
- **Bundle model overhaul**: `#Bundle.#modules` → `#Bundle.#instances` with new `#BundleInstance` type; new `#BundleRelease` definition for concrete bundle deployments — **BREAKING**
- **AutoSecrets in CUE**: `opm-secrets` component generation moved from CLI-time to CUE-time via new `core/helpers/autosecrets.cue`, resolving the core→resources import cycle
- **Declarative matching**: New `core/matcher/matcher.cue` implements component→transformer matching in CUE (`#MatchResult`, `#MatchPlan`)
- **TransformerContext changes**: Removed flat `name`/`namespace` fields; namespace accessed via `#moduleReleaseMetadata.namespace`; added `module-release.opmodel.dev/name` label — **BREAKING**
- **Import path updates**: All resources, traits, blueprints, and transformers updated from `core "opmodel.dev/core@v1"` to split imports (`prim`, `component`, `transformer`, etc.)
- **Bug fixes**: HPA and Ingress transformers missing release-prefix on resource names and cross-references
- **Test fixtures removed**: All `_test*` data removed from core definition files
- **New examples**: Real-world Minecraft server bundle examples added alongside existing generic examples

## Capabilities

### New Capabilities
- `bundle-releases`: BundleRelease type and bundle instance model for deploying multi-module bundles with per-instance metadata and namespace targeting
- `cue-matcher`: Declarative component-to-transformer matching engine in CUE (#MatchResult, #MatchPlan) — enables CUE-side matching alongside Go-side matching
- `cue-autosecrets`: Auto-generated opm-secrets component built in CUE at evaluation time instead of CLI deploy-time

### Modified Capabilities
- `core-transformer`: TransformerContext loses flat `name`/`namespace`, gains `module-release.opmodel.dev/name` label; all transformers use `#moduleReleaseMetadata` for namespace access
- `release-identity-labeling`: K8s resources now named `"{release}-{component}"` with release-prefix propagated through container helpers, secret refs, and PVC claims
- `component-matching`: Matching logic now expressible in CUE via `#MatchPlan`; Go-side matching in CLI may need to delegate or coexist

## Impact

- **CUE modules affected**: core, resources, traits, blueprints, providers (~65 files modified or added in `v1alpha1/`)
- **CLI consumers**: `../cli/internal/builder/`, `../cli/internal/loader/`, `../cli/internal/core/transformer/` will need updates to handle new CUE context structure (separate change in CLI repo)
- **Existing modules**: Any module consuming this catalog will see **BREAKING** resource name changes (release-prefix) requiring re-deployment
- **Import paths**: All CUE consumers of `opmodel.dev/core@v1` must update to split package imports
