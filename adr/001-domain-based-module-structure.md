# ADR-001: Domain-Based Module Structure

## Status

Accepted (retroactive, 2026-03)

## Context

The catalog originally existed as a single monolithic CUE module under `v1alpha1/` with a flat internal layout:

```text
v1alpha1/
  core/           # Module, ModuleRelease, Component, primitives
  schemas/        # Shared schemas (Kubernetes, network, storage, etc.)
  resources/      # All resource definitions (config, extension, security, storage, workload)
  traits/         # All trait definitions (network, security, workload)
  blueprints/     # All blueprint definitions
  providers/      # All provider transformers (Kubernetes)
```

Everything shipped as one module — OPM's own abstractions, Kubernetes schema mirrors, Gateway API types, and cert-manager types were all coupled together.

This created several problems:

1. **Forced adoption of the full catalog.** Consumers who only needed core primitives or a single integration (e.g. cert-manager) had to pull in everything, including unrelated schemas and providers.

2. **No independent versioning.** A breaking change to a Gateway API resource forced a version bump for the entire catalog, even though core primitives and OPM resources were unaffected.

3. **Extensibility ceiling.** Adding support for a new ecosystem (e.g. K8up, a future Istio module) meant modifying the monolithic module — there was no way to extend the catalog without touching it.

4. **Unclear dependency direction.** With everything in one module, it was not obvious which definitions depended on which. Core primitives and ecosystem-specific integrations lived at the same level.

A `v1alpha2/` directory was briefly prototyped (2026-03-23) to explore the domain split while keeping the original `v1alpha1/` intact, but maintaining two parallel structures proved impractical. The decision was made to restructure `v1alpha1/` directly.

## Decision

Split the monolithic catalog into independently versioned CUE domain modules, each published under `opmodel.dev/<domain>/v1alpha1@v1`. The restructuring happened on 2026-03-24.

The resulting modules and their dependency graph:

```text
core/v1alpha1          (no internal deps)
  ^
  |
opm/v1alpha1           (depends on core)
  ^
  |--- cert_manager/v1alpha1   (depends on core + opm)
  |
gateway_api/v1alpha1   (depends on core only)
  |
k8up/v1alpha1          (depends on core only)
  |
kubernetes/v1          (standalone K8s schema reference)
```

**Mapping from old to new:**

| Old location | New module |
|---|---|
| `v1alpha1/core/` (primitives, module, component, etc.) | `core/v1alpha1/` |
| `v1alpha1/schemas/`, `v1alpha1/resources/`, `v1alpha1/traits/`, `v1alpha1/blueprints/`, `v1alpha1/providers/` | `opm/v1alpha1/` |
| Gateway API schemas, resources, traits, transformers | `gateway_api/v1alpha1/` |
| cert-manager resources and transformers | `cert_manager/v1alpha1/` |

**Design rules for domain modules:**

- `core` has zero internal dependencies and defines only the abstract primitives (#Module, #ModuleRelease, #Component, #Resource, #Trait, #Blueprint, #Policy, #Transformer, #Bundle).
- Each domain module depends on `core` and optionally on `opm` if it needs OPM-specific types (e.g. cert-manager uses OPM's secret schemas).
- Each domain module owns its own resources, traits, schemas, and provider transformers — no cross-domain file references.
- Each module is independently versioned and published to the CUE registry.

**Alternatives considered:**

- **Keep the monolith, use CUE package-level separation only.** This would avoid multi-module complexity but would not solve the forced-adoption or independent-versioning problems. Rejected because CUE packages within a single module cannot be versioned or consumed independently.

- **One module per resource/trait definition.** Maximum granularity, but would create dozens of tiny modules with complex cross-dependencies and a high coordination cost for publishing. Rejected as over-engineering.

- **v1alpha2 as the new structure.** Briefly attempted, but maintaining two parallel API versions with identical semantics was confusing and doubled the testing surface. Rejected in favor of restructuring v1alpha1 in place.

## Consequences

**Positive:**

- New ecosystem integrations (K8up, future modules) can be added as new domain modules without modifying existing ones.
- Consumers import only what they need — a module using only cert-manager pulls `core` and `cert_manager`, not the full OPM resource set.
- Breaking changes in one domain do not force version bumps in others.
- The dependency graph makes architectural layering explicit: core is the foundation, OPM builds on it, ecosystem modules extend either or both.

**Negative:**

- Publishing is more complex — each module must be published separately and dependency versions coordinated across modules.
- CUE import paths are longer (`opmodel.dev/opm/v1alpha1/resources/workload` vs the old `resources/workload`).
- Cross-module changes (e.g. a core primitive change that affects OPM) require publishing core first, then updating dependents — no single atomic commit across modules.
- The build system (`Taskfile.yml`) needed rework to iterate over multiple module directories for fmt, vet, test, and publish commands.
