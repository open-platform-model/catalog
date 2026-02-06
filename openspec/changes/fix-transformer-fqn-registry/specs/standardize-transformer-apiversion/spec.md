## ADDED Requirements

### Requirement: Single apiVersion convention for all transformers

All transformer definitions within a provider package SHALL use the same `metadata.apiVersion` format. The format SHALL follow the established OPM domain path convention: `opmodel.dev/providers/<provider-name>/transformers@v<major>`.

For the Kubernetes provider, all seven transformers SHALL use `"opmodel.dev/providers/kubernetes/transformers@v0"`.

The current inconsistency — two transformers using `"transformer.opmodel.dev/workload@v1"` while five use `"opmodel.dev/providers/kubernetes/transformers@v0"` — SHALL be resolved by standardizing on the majority pattern.

#### Scenario: Deployment transformer apiVersion standardized

- **WHEN** inspecting `#DeploymentTransformer.metadata.apiVersion`
- **THEN** the value SHALL be `"opmodel.dev/providers/kubernetes/transformers@v0"`

#### Scenario: DaemonSet transformer apiVersion standardized

- **WHEN** inspecting `#DaemonSetTransformer.metadata.apiVersion`
- **THEN** the value SHALL be `"opmodel.dev/providers/kubernetes/transformers@v0"`

#### Scenario: All seven transformers share the same apiVersion

- **WHEN** inspecting `metadata.apiVersion` on `#DeploymentTransformer`, `#StatefulSetTransformer`, `#DaemonSetTransformer`, `#JobTransformer`, `#CronJobTransformer`, `#ServiceTransformer`, and `#PVCTransformer`
- **THEN** all seven SHALL have the value `"opmodel.dev/providers/kubernetes/transformers@v0"`

### Requirement: Transformer FQN values reflect standardized apiVersion

After standardizing `apiVersion`, each transformer's computed `fqn` (via `_definitionName` from `#KebabToPascal`) SHALL reflect the new uniform apiVersion.

| Transformer | `name` | Expected `fqn` |
|---|---|---|
| Deployment | `"deployment-transformer"` | `"opmodel.dev/providers/kubernetes/transformers@v0#DeploymentTransformer"` |
| StatefulSet | `"statefulset-transformer"` | `"opmodel.dev/providers/kubernetes/transformers@v0#StatefulsetTransformer"` |
| DaemonSet | `"daemonset-transformer"` | `"opmodel.dev/providers/kubernetes/transformers@v0#DaemonsetTransformer"` |
| Job | `"job-transformer"` | `"opmodel.dev/providers/kubernetes/transformers@v0#JobTransformer"` |
| CronJob | `"cronjob-transformer"` | `"opmodel.dev/providers/kubernetes/transformers@v0#CronjobTransformer"` |
| Service | `"service-transformer"` | `"opmodel.dev/providers/kubernetes/transformers@v0#ServiceTransformer"` |
| PVC | `"pvc-transformer"` | `"opmodel.dev/providers/kubernetes/transformers@v0#PvcTransformer"` |

#### Scenario: Deployment transformer FQN computed correctly

- **WHEN** evaluating `#DeploymentTransformer.metadata.fqn`
- **THEN** the value SHALL be `"opmodel.dev/providers/kubernetes/transformers@v0#DeploymentTransformer"`

#### Scenario: DaemonSet transformer FQN computed correctly

- **WHEN** evaluating `#DaemonSetTransformer.metadata.fqn`
- **THEN** the value SHALL be `"opmodel.dev/providers/kubernetes/transformers@v0#DaemonsetTransformer"`

#### Scenario: CUE validation passes after standardization

- **WHEN** running `cue vet ./...` in the providers module
- **THEN** validation SHALL pass with zero errors
