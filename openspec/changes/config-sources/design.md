## Context

OPM currently has three disconnected config mechanisms:

1. **Literal env values** — `#ContainerSchema.env` only accepts `name`/`value` string pairs
2. **Standalone resources** — `#ConfigMapResource` and `#SecretResource` create K8s objects but have no wiring to containers
3. **Volume references** — `#VolumeSchema` can reference `configMap` and `secret` by embedding their schemas for file mounts

The SimpleDatabase blueprint demonstrates the problem: it puts database passwords as plaintext strings in `env.value` because there's no alternative. The standalone Secret resource creates a K8s Secret but nothing connects it to the container that needs it.

This experiment unifies config/secret handling under a single `ConfigSource` abstraction and adds `env.from` references to wire them to containers.

### Experiment structure

All work happens in `experiments/001-config-sources/` as a single self-contained CUE module. The full module dependency chain (core → schemas → resources → traits → providers → examples) is flattened into one module using CUE packages. No registry dependencies.

## Goals / Non-Goals

**Goals:**

- Unified abstraction for config and secrets that covers inline data and external references
- Type-safe wiring from config sources to container env vars via `from` references
- Platform-agnostic schema — `from: { source, key }` maps to any platform with secret injection
- Backward-compatible env schema — existing `value`-only usage remains valid
- Working K8s transformer output (ConfigMap/Secret resources + `valueFrom` on containers)
- Validate the design through a self-contained experiment before committing to catalog changes

**Non-Goals:**

- `envFrom` (bulk injection of all keys from a source) — deferred, can be added later
- `fieldRef` / `resourceFieldRef` (K8s downward API) — K8s-specific, doesn't belong in core
- Cross-component config source references — config sources are scoped to their component
- External secret operator integration (Vault, ESO) — the `externalRef` pattern provides the hook; specific integrations are provider extensions
- Replacing existing `#ConfigMapResource` / `#SecretResource` in the main catalog — this experiment informs that decision but doesn't execute it
- Volume mount integration with config sources — volumes continue to work as-is; unifying volume refs through config sources is a future consideration

## Decisions

### D1: Unified ConfigSource over separate ConfigMap/Secret resources

**Decision**: Introduce a single `#ConfigSourceSchema` with a `type` discriminator (`"config"` | `"secret"`) instead of maintaining separate resources.

**Rationale**: The only semantic difference between a ConfigMap and a Secret is sensitivity — the shape (named key-value data) is identical. A single abstraction with a type field reduces the concept count (Principle VII) and makes the transformer simpler. The type field gives providers enough information to emit the right K8s resource.

**Alternative considered**: Keep separate resources, add a wiring trait. Rejected because it introduces a new concept (the wiring trait) while keeping two existing ones — net complexity increase.

### D2: `from` on env vars, not injection semantics on the source

**Decision**: The container's `env.from` field references a config source ("pull" model). The config source does not declare where its values should be injected ("push" model).

**Rationale**: This follows OPM's composability principle — resources describe "what exists" independently, the consumer (container) declares what it needs. A push model would couple the config source to the container, violating separation of concerns. It also matches the existing volume mount pattern: volumes exist independently, containers declare mounts.

**Alternative considered**: Injection semantics on the source (`inject.asEnv`, `inject.asVolume`). Rejected because it inverts the dependency — the source would need to know about the container.

### D3: External refs are simple string names

**Decision**: `externalRef.name` is a plain string. No namespace, no structured reference.

**Rationale**: Namespacing is a provider concern. OPM models intent ("I need the secret called X"), not placement. The transformer resolves the name in the target platform's context. Adding namespace would leak K8s concepts into the core schema.

**Alternative considered**: Structured ref with optional namespace. Rejected as K8s-specific — other platforms don't have namespaces in the same way.

### D4: `from` references are documented as intended for external resources

**Decision**: The `from` field is semantically intended for referencing resources external to the module (managed by Vault, platform team, pre-existing in cluster). This is documented, not structurally enforced.

**Rationale**: CUE can't distinguish "this string names something inside my module" from "this string names something external" at the schema level. Structural enforcement would require a complex reference resolution system that violates Principle VII. Documentation plus convention is sufficient for v0.

### D5: Inline data sources generate named K8s resources

**Decision**: When a config source has inline `data`, the transformer emits a K8s ConfigMap or Secret with a deterministic name: `{component-name}-{source-name}`.

**Rationale**: Deterministic naming enables idempotent deployments and makes the generated resource predictable. The component-name prefix avoids collisions when multiple components define sources with the same name.

### D6: External ref sources emit no K8s resource

**Decision**: When a config source has `externalRef`, the transformer emits nothing for that source. It only uses the ref name when resolving `env.from` to `valueFrom`.

**Rationale**: External resources already exist — emitting a duplicate would conflict. The transformer's job is to wire the reference, not create the resource.

### D7: Env `from` resolution happens in the workload transformer

**Decision**: The workload transformers (deployment, statefulset, etc.) resolve `env.from` by looking up the referenced source in `component.spec.configSources` and emitting the appropriate `valueFrom.secretKeyRef` or `valueFrom.configMapKeyRef`.

**Rationale**: The workload transformer already builds the container spec. Adding a separate resolution pass would split container construction across two transformers, making the output harder to reason about. The config-source transformer handles resource creation; the workload transformer handles env wiring.

### D8: Experiment uses flat package structure

**Decision**: The experiment module uses CUE packages under a single module (`experiments/001-config-sources/`) to flatten the dependency chain: `core/`, `schemas/`, `resources/`, `providers/`, `examples/`.

**Rationale**: Publishing to a registry for every iteration is too slow. A single module with packages lets us `cue vet ./...` and `cue eval` locally. The package structure mirrors the real module layout so changes can be ported back.

## Risks / Trade-offs

**[Divergence from main catalog]** The experiment copies modules and modifies them in isolation. If the main catalog evolves during the experiment, the copies may drift.
→ Mitigation: Keep the experiment short-lived. Port findings back promptly. The experiment only modifies schemas, one resource, and transformers — a bounded surface.

**[Schema migration if adopted]** If ConfigSource replaces ConfigMap/Secret resources in the main catalog, existing modules using those resources will need migration.
→ Mitigation: The experiment validates the design before any migration commitment. Migration can be incremental — both old and new resources can coexist during transition.

**[Env `from` validation is not cross-field]** CUE cannot validate that `env.from.source` actually names a config source defined in `configSources` on the same component. An invalid reference would only fail at transform time.
→ Mitigation: Acceptable for v0. The transformer should produce a clear error when a source reference doesn't resolve. Cross-field validation can be added later if CUE gains the capability or via a custom validator.

**[No `envFrom` support]** Bulk injection is deferred. Users who want all keys from a source as env vars must enumerate them individually.
→ Mitigation: Explicit enumeration is more readable and debuggable. `envFrom` can be added as a future enhancement without breaking changes.
