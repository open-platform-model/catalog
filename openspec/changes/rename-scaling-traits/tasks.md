## 1. Scaling Schema Definitions

- [ ] 1.1 Add `#AutoscalingSpec`, `#MetricSpec`, and `#MetricTargetSpec` definitions to `v0/schemas/workload.cue`
- [ ] 1.2 Replace `#ReplicasSchema` with `#ScalingSchema` struct (`count` + `auto?`) in `v0/schemas/workload.cue`
- [ ] 1.3 Rename `replicas?:` to `scaling?:` in `#StatelessWorkloadSchema` (`v0/schemas/workload.cue:174`)
- [ ] 1.4 Rename `replicas?:` to `scaling?:` in `#StatefulWorkloadSchema` (`v0/schemas/workload.cue:188`)

## 2. Sizing Schema Definitions

- [ ] 2.1 Add `#VerticalAutoscalingSpec` definition to `v0/schemas/workload.cue`
- [ ] 2.2 Rename `#ResourceLimitSchema` to `#SizingSchema` and add `auto?: #VerticalAutoscalingSpec` field in `v0/schemas/workload.cue`
- [ ] 2.3 Rename `resourceLimit?:` to `sizing?:` in `#StatelessWorkloadSchema` if present
- [ ] 2.4 Rename `resourceLimit?:` to `sizing?:` in `#StatefulWorkloadSchema` if present

## 3. Scaling Trait Definition

- [ ] 3.1 Create `v0/traits/workload/scaling.cue` with `#ScalingTrait`, `#Scaling`, `#ScalingDefaults` using new schema and `name: "scaling"`
- [ ] 3.2 Delete `v0/traits/workload/replicas.cue`

## 4. Sizing Trait Definition

- [ ] 4.1 Create `v0/traits/workload/sizing.cue` with `#SizingTrait`, `#Sizing`, `#SizingDefaults` using new schema and `name: "sizing"`
- [ ] 4.2 Delete `v0/traits/workload/resource_limit.cue`

## 5. Blueprints

- [ ] 5.1 Update `v0/blueprints/workload/stateless_workload.cue`: `#ReplicasTrait` → `#ScalingTrait`, `#Replicas` → `#Scaling`, `statelessWorkload.replicas` → `statelessWorkload.scaling`, `replicas:` → `scaling:`
- [ ] 5.2 Update `v0/blueprints/workload/stateful_workload.cue`: same renames as 5.1
- [ ] 5.3 Update `v0/blueprints/data/simple_database.cue`: trait refs + `replicas: 1` → `scaling: count: 1`
- [ ] 5.4 Update any blueprint references to `#ResourceLimitTrait`/`#ResourceLimit` → `#SizingTrait`/`#Sizing`

## 6. Kubernetes Transformers

- [ ] 6.1 Update `v0/providers/kubernetes/transformers/deployment_transformer.cue`: FQN key `...#Replicas` → `...#Scaling`, trait ref `#ReplicasTrait` → `#ScalingTrait`, default extraction to `.defaults.count`, field access `spec.replicas` → `spec.scaling.count`
- [ ] 6.2 Update `v0/providers/kubernetes/transformers/statefulset_transformer.cue`: same pattern as 6.1
- [ ] 6.3 Update any transformer references to `#ResourceLimitTrait` → `#SizingTrait`, `spec.resourceLimit` → `spec.sizing`

## 7. Core Inline Examples

- [ ] 7.1 Update `v0/core/component.cue`: inline `#Replicas` trait example → `#Scaling` (FQN key, name, description, `#spec: replicas:` → `#spec: scaling:`, `spec.replicas:` → `spec.scaling:`)
- [ ] 7.2 Update `v0/core/module.cue`: `spec: replicas:` → `spec: scaling: count:`
- [ ] 7.3 Update `v0/core/trait.cue`: comment references from `"replicas"` → `"scaling"`

## 8. Examples

- [ ] 8.1 Update `v0/examples/components/basic_component.cue`: `#Replicas` → `#Scaling`, `replicas:` → `scaling: count:`
- [ ] 8.2 Update `v0/examples/components/stateful_workload.cue`: same pattern
- [ ] 8.3 Update `v0/examples/components/database_components.cue`: 3 components, trait refs + field renames
- [ ] 8.4 Update `v0/examples/modules/basic_module.cue`: config fields `replicas` → `scaling`, spec mapping `replicas:` → `scaling: count:`
- [ ] 8.5 Update `v0/examples/modules/multi_tier_module.cue`: same pattern as 8.4

## 9. Documentation

- [ ] 9.1 Update `docs/core/primitives.md`: Trait section — replace `Replicas` with `Scaling` and `ResourceLimit` with `Sizing` in description, examples list, CUE snippets (`#ReplicasTrait` → `#ScalingTrait`, `name: "replicas"` → `name: "scaling"`, `#spec: replicas:` → `#spec: scaling:`)
- [ ] 9.2 Update `docs/core/primitives.md`: Blueprint section — replace `#ReplicasTrait` → `#ScalingTrait` in composed traits example, `replicas:` → `scaling:` in spec example
- [ ] 9.3 Update `docs/core/primitives.md`: Trait metadata comment `"replicas"` → `"scaling"`
- [ ] 9.4 Update `docs/core/interface-architecture-rfc.md`: replace "Number of replicas" reference if appropriate

## 10. Validation

- [ ] 10.1 Run `task fmt` to format all changed files
- [ ] 10.2 Run `task vet` to validate all modules pass
- [ ] 10.3 Run `task eval` on providers module to verify transformer output still produces correct K8s `replicas:` field in Deployment/StatefulSet specs
- [ ] 10.4 Grep for any remaining `#Replicas`, `#ReplicasSchema`, `#ReplicasDefaults`, `#ReplicasTrait` references
- [ ] 10.5 Grep for any remaining `#ResourceLimit`, `#ResourceLimitSchema`, `#ResourceLimitDefaults`, `#ResourceLimitTrait`, `resourceLimit` references
- [ ] 10.6 Grep `docs/core/` for any remaining `Replicas`, `ResourceLimit`, `resourceLimit` references that should have been updated
