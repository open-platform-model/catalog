## Context

The current `#ReplicasSchema` is a bare integer (`int & >=1 & <=1000 | *1`). This shape is referenced across ~14 files and ~61 sites in schemas, traits, blueprints, transformers, and examples. All references use the field name `replicas` and the FQN `opmodel.dev/traits/workload@v0#Replicas`.

The current `#ResourceLimitSchema` defines `cpu?` and `memory?` with `request`/`limit` pairs. It is referenced in 2 files (schema + trait definition) with no blueprint, transformer, or example references yet. The FQN is `opmodel.dev/traits/workload@v0#ResourceLimit`.

The catalog is pre-1.0, making this the right time for breaking renames. The `add-transformers` change (parallel work) will need the `auto` field to emit HPA resources.

## Goals / Non-Goals

**Goals:**

- Rename all identifiers from `Replicas`/`replicas` to `Scaling`/`scaling`
- Rename all identifiers from `ResourceLimit`/`resourceLimit` to `Sizing`/`sizing`
- Evolve the Scaling schema from bare int to struct with `count` + `auto?`
- Add VPA stub (`auto?`) to Sizing schema for future vertical autoscaling
- Maintain type safety: all existing validation constraints carry forward
- Keep transformers functional: static `count` path produces identical K8s output
- Add `sizing?` and `securityContext?` fields to all `close()`d workload schemas so downstream transformers can read them from `#component.spec`

**Non-Goals:**

- Implementing the HPA transformer (belongs in `add-transformers` change)
- Implementing a VPA transformer (future work)
- Adding autoscaling to any blueprint or example (future work)
- Backfilling any migration tooling for downstream consumers

## Decisions

### 1. Struct shape: `{ count, auto? }` over union type

**Decision**: Use a struct with `count` (defaulted int) and optional `auto` field.

**Alternative considered**: CUE disjunction `(int & >=1 & <=1000) | #AutoscalingSpec`. Rejected because:

- CUE disjunctions with mixed types (int vs struct) produce confusing error messages
- Transformers would need type-switching logic (`if (_scaling & int) != _|_`)
- No way to express "initial count" alongside autoscaling

The struct approach lets `count` always be present (with default `1`) and `auto` overlay independently.

```cue
#ScalingSchema: {
    count: int & >=1 & <=1000 | *1
    auto?: #AutoscalingSpec
}
```

### 2. `#AutoscalingSpec` as a separate named definition

**Decision**: Define `#AutoscalingSpec` as its own definition in `schemas/workload.cue`, not inlined inside `#ScalingSchema`.

**Rationale**: The autoscaling spec is complex enough (metrics list, behavior, custom metrics) that inlining it would make `#ScalingSchema` hard to read. A named definition also lets the HPA transformer reference it directly.

```cue
#AutoscalingSpec: {
    min!:     int & >=1
    max!:     int & >=1
    metrics!: [_, ...#MetricSpec]
    behavior?: {
        scaleUp?:   { stabilizationWindowSeconds?: int }
        scaleDown?: { stabilizationWindowSeconds?: int }
    }
}

#MetricSpec: {
    type!: "cpu" | "memory" | "custom"
    target!: #MetricTargetSpec
    if type == "custom" {
        metricName!: string
    }
}

#MetricTargetSpec: {
    averageUtilization?: int & >=1 & <=100
    averageValue?:       string
}
```

### 3. File rename via delete-and-create, not git mv

**Decision**: Delete old trait files and create new ones.

**Rationale**: The content changes substantially (not just the filename). Git will detect the rename via content similarity. Using `git mv` followed by edits produces the same result but adds an unnecessary step.

Applies to both `replicas.cue` → `scaling.cue` and `resource_limit.cue` → `sizing.cue`.

### 4. Scaling defaults shape change

**Decision**: `#ScalingDefaults` becomes a struct default, not a bare int default.

Current: `#ReplicasDefaults: schemas.#ReplicasSchema & int | *1`
New: `#ScalingDefaults: schemas.#ScalingSchema & { count: *1 }`

Transformer default extraction changes from:

```cue
_replicas: *optionalTraits["...#Replicas"].#defaults | int
```

to:

```cue
_scalingCount: *optionalTraits["...#Scaling"].#defaults.count | int
```

### 5. Execution order: bottom-up through the dependency chain

**Decision**: Apply changes in module dependency order to keep `task vet` passing at each step:

1. `schemas/workload.cue` — new schema definitions (both Scaling and Sizing)
2. `traits/workload/scaling.cue` — new Scaling trait file (delete old after)
3. `traits/workload/sizing.cue` — new Sizing trait file (delete old after)
4. `blueprints/` — update trait references and field names
5. `providers/kubernetes/transformers/` — update FQN keys and field access
6. `core/` — update inline examples
7. `examples/` — update components and modules
8. Delete `traits/workload/replicas.cue` and `traits/workload/resource_limit.cue`

Steps 2–7 must happen atomically (single commit) since removing the old traits while anything still references them would break validation.

### 6. Workload schemas get `scaling?` not `scaling!`

**Decision**: The field remains optional in `#StatelessWorkloadSchema` and `#StatefulWorkloadSchema`, matching current behavior where `replicas?` is optional.

When omitted, the trait default of `{ count: 1 }` applies through the transformer's default extraction.

### 7. ResourceLimit → Sizing rename

**Decision**: Rename all identifiers from `ResourceLimit`/`resourceLimit` to `Sizing`/`sizing`.

**Rationale**: "Sizing" passes the Trait "how" test ("How is it sized?") while "ResourceLimit" focuses narrowly on limits. The rename broadens the trait's semantic scope to cover the full compute profile (requests, limits, and future auto-tuning).

Current references are limited to 2 files (`schemas/workload.cue` and `traits/workload/resource_limit.cue`), making this a low-risk rename.

### 8. VPA stub in SizingSchema

**Decision**: Add `auto?: #VerticalAutoscalingSpec` to `#SizingSchema` alongside existing `cpu?`/`memory?` fields.

**Rationale**: Mirrors the Scaling trait pattern (`auto?` for horizontal autoscaling). Having the field defined now means future VPA support won't require another schema breakage.

The stub is not implemented by any transformer — it's a forward declaration only.

```cue
#SizingSchema: {
    cpu?: {
        request!: string & =~"^[0-9]+m$"
        limit!:   string & =~"^[0-9]+m$"
    }
    memory?: {
        request!: string & =~"^[0-9]+[MG]i$"
        limit!:   string & =~"^[0-9]+[MG]i$"
    }
    auto?: #VerticalAutoscalingSpec
}

#VerticalAutoscalingSpec: {
    updateMode?: "Auto" | "Initial" | "Off" | *"Auto"
    controlledResources?: [...("cpu" | "memory")]
}
```

### 9. Add `sizing?` and `securityContext?` to all workload schemas

**Decision**: While touching the `close()`d workload schemas to rename `replicas` → `scaling`, also add `sizing?` and `securityContext?` fields to all five workload schemas (`#StatelessWorkloadSchema`, `#StatefulWorkloadSchema`, `#DaemonWorkloadSchema`, `#TaskWorkloadSchema`, `#ScheduledTaskWorkloadSchema`).

**Rationale**: The `add-transformers` change needs to wire Sizing (renamed from ResourceLimit) and SecurityContext traits into workload transformer outputs. Transformers read from `#component.spec.*`, which is constrained by these `close()`d schemas. Without these fields, components using these traits would fail validation before reaching the transformer. Adding them here avoids touching the same schemas a second time.

Both fields are optional, matching the pattern of existing trait fields (`healthCheck?`, `scaling?`).

The `securityContext?` field references `#SecurityContextSchema` from `schemas/security.cue` (added by the completed `add-more-traits` change). This requires adding an import of the security schemas package to `schemas/workload.cue`.

## Risks / Trade-offs

**[Risk: Big-bang commit]** All ~16 files must change simultaneously since the old and new FQNs can't coexist.
→ **Mitigation**: The change is mechanical (rename + restructure). Run `task vet` after each logical group. The single commit is unavoidable but low-risk given the rename is straightforward.

**[Risk: Missed reference]** A `replicas` or `resourceLimit` reference could be missed, causing CUE validation failure.
→ **Mitigation**: The exploration phase identified all reference sites via grep. Run `task vet` across all modules as the final validation gate. Any missed reference will fail validation.

**[Risk: Downstream breakage]** External consumers using old identifiers will break.
→ **Mitigation**: Catalog is pre-1.0 and SemVer allows breaking changes in MAJOR bumps. No known external consumers yet.

**[Trade-off: Struct overhead for simple case]** Users who just want `replicas: 3` now write `scaling: count: 3` — slightly more verbose.
→ **Accepted**: The struct enables autoscaling without future schema breakage. One extra nesting level is a reasonable cost.

**[Trade-off: VPA stub without implementation]** The `auto?` field in `#SizingSchema` has no transformer support yet.
→ **Accepted**: Defining the field now prevents future schema breakage. The field is optional and has no impact on current functionality.
