## Why

The `#ReplicasTrait` currently models replication as a bare integer (`int & >=1 & <=1000`), which only supports static replica counts. Real workloads need autoscaling (HPA-style), and the current schema has no place for it. Renaming to `#ScalingTrait` and evolving the schema to a struct with `count` + `auto?` creates a single, coherent scaling abstraction that covers both static and dynamic horizontal scaling.

The `#ResourceLimitTrait` name focuses on limits rather than the full compute profile. Renaming to `#SizingTrait` aligns with the Trait naming convention ("How is it sized?") and creates room for future vertical autoscaling (VPA) via an `auto?` field, mirroring the Scaling trait pattern.

Both are breaking changes best done now while the catalog is pre-1.0.

## What Changes

### Replicas → Scaling

- **BREAKING**: Rename `#ReplicasTrait` → `#ScalingTrait`, `#Replicas` → `#Scaling`, `#ReplicasSchema` → `#ScalingSchema`, `#ReplicasDefaults` → `#ScalingDefaults`
- **BREAKING**: Rename trait file `traits/workload/replicas.cue` → `traits/workload/scaling.cue`
- **BREAKING**: Rename trait metadata `name: "replicas"` → `name: "scaling"`, changing the FQN from `opmodel.dev/traits/workload@v0#Replicas` to `opmodel.dev/traits/workload@v0#Scaling`
- **BREAKING**: Evolve `#ScalingSchema` from bare `int` to struct: `{ count: int, auto?: #AutoscalingSpec }`
- **BREAKING**: All `spec.replicas` fields become `spec.scaling` (struct) across schemas, blueprints, transformers, and examples
- Update all FQN string references in transformer `optionalTraits` maps
- Update all transformer logic to read `spec.scaling.count` instead of `spec.replicas`
- Update user-facing `#config` fields in examples to use `scaling` naming

### ResourceLimit → Sizing

- **BREAKING**: Rename `#ResourceLimitTrait` → `#SizingTrait`, `#ResourceLimit` → `#Sizing`, `#ResourceLimitSchema` → `#SizingSchema`, `#ResourceLimitDefaults` → `#SizingDefaults`
- **BREAKING**: Rename trait file `traits/workload/resource_limit.cue` → `traits/workload/sizing.cue`
- **BREAKING**: Rename trait metadata `name: "resource-limit"` → `name: "sizing"`, changing the FQN from `opmodel.dev/traits/workload@v0#ResourceLimit` to `opmodel.dev/traits/workload@v0#Sizing`
- **BREAKING**: Rename spec field `spec.resourceLimit` → `spec.sizing`
- Add optional `auto?: #VerticalAutoscalingSpec` to `#SizingSchema` for future VPA support (stub, not implemented by any transformer)

## Capabilities

### New Capabilities

- `scaling-schema`: Defines the new `#ScalingSchema` struct with static `count` and optional `auto` (autoscaling spec) fields, replacing the bare-int `#ReplicasSchema`
- `sizing-schema`: Defines the renamed `#SizingSchema` with existing `cpu?`/`memory?` fields and a new optional `auto` (vertical autoscaling spec) stub, replacing `#ResourceLimitSchema`

### Modified Capabilities

_None — no existing specs are affected._

## Impact

- **SemVer**: MAJOR (breaking schema and API changes)
- **Modules affected**: schemas, traits, providers, blueprints, examples, core (inline examples)
- **Files touched**: ~16 files (~14 for Scaling, ~2 for Sizing)
- **Downstream**: Any external consumers referencing `#ReplicasTrait`, `#ReplicasSchema`, `spec.replicas`, `#ResourceLimitTrait`, `#ResourceLimitSchema`, or `spec.resourceLimit` will break
- **No portability impact**: This is a schema-level rename, provider-agnostic by nature
