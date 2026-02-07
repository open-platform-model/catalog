## Context

The OPM catalog has two resources today: `#ContainerResource` (`resources/workload/container.cue`) and `#VolumesResource` (`resources/storage/volume.cue`). Both follow a consistent three-layer pattern:

1. **Schema** in `schemas/` — defines the data shape (e.g., `#ContainerSchema`)
2. **Resource definition** in `resources/<category>/` — wraps schema with `core.#Resource`, exposes `#spec` and `#defaults`
3. **Component mixin** (e.g., `#Container`, `#Volumes`) — adds the resource to a component's `#resources` map via FQN

Schemas for ConfigMap (`#ConfigMapSchema`) and Secret (`#SecretSchema`) already exist in `schemas/config.cue`. WorkloadIdentity has no schema yet.

The `resources` module depends on `core` and `schemas`. No new dependency edges are introduced.

## Goals / Non-Goals

**Goals:**

- Add ConfigMap, Secret, and WorkloadIdentity as first-class OPM resources
- Follow the established three-layer resource pattern exactly
- Ensure all three are composable into blueprints and matchable by transformers via FQN
- Maintain full provider-agnosticism — resources express intent only

**Non-Goals:**

- K8s transformers for these resources (covered by `add-transformers` change)
- `envFrom` / bulk env injection into containers (deferred)
- RBAC rules, role bindings, or IAM policies attached to WorkloadIdentity (future scope)
- Blueprint updates to compose these resources (separate change)
- Modifying existing resources or schemas

## Decisions

### 1. Module organization: `resources/config/` and `resources/security/`

ConfigMap and Secret go under `resources/config/` as a new category. WorkloadIdentity goes under `resources/security/`. This mirrors the existing `resources/workload/` and `resources/storage/` categorization.

**Alternative considered**: Put all three under `resources/workload/` since they're consumed by workloads. Rejected because the resource category reflects what the resource *is*, not who consumes it. Config and identity are distinct concerns from compute.

**Composition**: Components compose these resources by embedding the mixin (e.g., `config_resources.#ConfigMapMixin`), which adds the resource FQN to `#resources`. Transformers match on the FQN. No coupling between resource categories.

### 2. ConfigMap and Secret are separate resources

Each gets its own file and FQN rather than a combined "ConfigResource" with a type discriminator.

**Rationale**: Different schemas (`data: [string]: string` vs `type + data`), different security implications, different transformer behavior. Separate resources allow independent matching and policy application (e.g., encryption-at-rest for secrets only).

### 3. WorkloadIdentity schema is minimal

```text
#WorkloadIdentitySchema: {
    name!:           string
    automountToken?: bool | *false
}
```

Only `name` and `automountToken`. No RBAC, no IAM role bindings, no policy attachments.

**Justification**: Start with the minimal viable identity (Principle VII — YAGNI). A workload needs a name and a token-mounting decision. Everything else is platform-specific and belongs in traits or provider extensions. Extending the schema later is a non-breaking MINOR change.

### 4. Schema placement

`#WorkloadIdentitySchema` goes in a new `schemas/security.cue` file. ConfigMap and Secret schemas already exist in `schemas/config.cue` — no changes needed.

### 5. No labels on new resources

The Container resource sets `"core.opmodel.dev/workload-type"` because workload transformers match on it. The new resources don't need workload-type labels — they're matched by resource FQN in transformer `requiredResources`. No additional labels are needed.

### 6. Component mixin naming convention

Following existing patterns: the component mixin for ConfigMap is `#ConfigMap` (not `#ConfigMapComponent`), for Secret is `#Secret`, for WorkloadIdentity is `#WorkloadIdentity`. Each mixin adds the resource to `#resources` and nothing more.

**Ownership boundaries**: Module authors embed these mixins into components. Platform operators can extend via CUE unification. Consumers receive concrete values through ModuleRelease.

### 7. Type safety

All three resources constrain their `#spec` field using the corresponding schema. CUE structural typing ensures invalid configuration is rejected at definition time. The `close()` wrapper on resource definitions prevents extra fields.

## Risks / Trade-offs

**[Risk] New `resources/config/` CUE package** → The resources module currently has `workload` and `storage` packages. Adding `config` and `security` packages requires updating `resources/cue.mod/module.cue` if it has explicit package declarations. **Mitigation**: CUE module config is minimal; verify with `task vet`.

**[Risk] apiVersion namespace collision** → ConfigMap and Secret both use `opmodel.dev/resources/config@v0`. WorkloadIdentity uses `opmodel.dev/resources/security@v0`. These are new namespaces — no collision possible with existing FQNs.

**[Trade-off] Minimal WorkloadIdentity schema** → May need expansion later for labels, annotations, or policy references. Accept this — extending a schema is non-breaking. Shipping less now reduces design surface and aligns with Principle VII.

**[Trade-off] Secret schema stores base64 strings** → The existing `#SecretSchema` uses `data: [string]: string` for base64-encoded values. This is a convention, not enforced by CUE constraints. Accept for now — adding a base64 validation regex is a future enhancement.
