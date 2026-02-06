## 1. Core Types in common.cue

- [x] 1.1 Redefine `#NameType` in `v0/core/common.cue` with RFC 1123 DNS label regex (`^[a-z0-9]([a-z0-9-]*[a-z0-9])?$`) and `strings.MaxRunes(63)`
- [x] 1.2 Add `#APIVersionType` in `v0/core/common.cue` with regex `^[a-z0-9.-]+(/[a-z0-9.-]+)*@v[0-9]+$` and `strings.MaxRunes(254)`
- [x] 1.3 Add `#KebabToPascal` function in `v0/core/common.cue` using the Function Pattern (`X="in"` / `.out`) with `strings.Split`, `strings.ToUpper`, `strings.SliceRunes`, `strings.Join`
- [x] 1.4 Verify `#FQNType` regex is unchanged — must still be `^([a-z0-9.-]+(?:/[a-z0-9.-]+)*)@v([0-9]+)#([A-Z][a-zA-Z0-9]*)$`

## 2. Core Definitions — Retype Fields and Add _definitionName

- [x] 2.1 Update `v0/core/module.cue` — change `metadata.apiVersion!` to `#APIVersionType`, add `_definitionName: (#KebabToPascal & {"in": name}).out`, update `fqn` to interpolate `_definitionName`
- [x] 2.2 Update `v0/core/resource.cue` — change `metadata.apiVersion!` to `#APIVersionType`, add `_definitionName` and update `fqn`
- [x] 2.3 Update `v0/core/trait.cue` — change `metadata.apiVersion!` to `#APIVersionType`, add `_definitionName` and update `fqn`
- [x] 2.4 Update `v0/core/blueprint.cue` — change `metadata.apiVersion!` to `#APIVersionType`, add `_definitionName` and update `fqn`
- [x] 2.5 Update `v0/core/policy.cue` — change `metadata.apiVersion!` to `#APIVersionType`, add `_definitionName` and update `fqn`
- [x] 2.6 Update `v0/core/transformer.cue` — change `metadata.apiVersion!` to `#APIVersionType`, add `_definitionName` and update `fqn`
- [x] 2.7 Update `v0/core/bundle.cue` — change `metadata.apiVersion!` to `#APIVersionType`, add `_definitionName` and update `fqn`
- [x] 2.8 Update `v0/core/template.cue` — change `metadata.apiVersion!` to `#APIVersionType`, change top-level `apiVersion` and `kind` fields from `#NameType` to string literals, add `_definitionName` and update `fqn`

## 3. Core Definitions — Apply #NameType to Bare String Fields

- [x] 3.1 Update `v0/core/component.cue` — change `metadata.name!: string` to `metadata.name!: #NameType`
- [x] 3.2 Update `v0/core/scope.cue` — change `metadata.name!: string` to `metadata.name!: #NameType`
- [x] 3.3 Update `v0/core/module_release.cue` — change `metadata.name!: string` to `metadata.name!: #NameType`
- [x] 3.4 Update `v0/core/bundle_release.cue` — change `metadata.name!: string` to `metadata.name!: #NameType`
- [x] 3.5 Update `v0/core/provider.cue` — change `metadata.name: string` to `metadata.name: #NameType`

## 4. Schemas Module — Remove Dead Code

- [x] 4.1 Remove `#NameSchema` from `v0/schemas/common.cue` (dead code, zero references)

## 5. Migrate Name Values — Core Test Fixtures

- [x] 5.1 Update `_testModule` in `v0/core/module.cue` — change `name: "TestModule"` to `name: "test-module"`, update `apiVersion` if needed
- [x] 5.2 Update `_testComponent` in `v0/core/component.cue` — update resource and trait FQN map keys to match new `_definitionName`-derived FQNs
- [x] 5.3 Update `_testModuleRelease` in `v0/core/module_release.cue` — verify `name: "test-release"` already conforms (it does)

## 6. Migrate Name Values — Resources

- [x] 6.1 Update `v0/resources/workload/container.cue` — change `name: "Container"` to `name: "container"`
- [x] 6.2 Update `v0/resources/storage/volume.cue` — change `name: "Volumes"` to `name: "volumes"`

## 7. Migrate Name Values — Traits

- [x] 7.1 Update `v0/traits/workload/replicas.cue` — change `name: "Replicas"` to `name: "replicas"`
- [x] 7.2 Update `v0/traits/workload/update_strategy.cue` — change `name: "UpdateStrategy"` to `name: "update-strategy"`
- [x] 7.3 Update `v0/traits/workload/sidecar_containers.cue` — change `name: "SidecarContainers"` to `name: "sidecar-containers"`
- [x] 7.4 Update `v0/traits/workload/restart_policy.cue` — change `name: "RestartPolicy"` to `name: "restart-policy"`
- [x] 7.5 Update `v0/traits/workload/resource_limit.cue` — change `name: "ResourceLimit"` to `name: "resource-limit"`
- [x] 7.6 Update `v0/traits/workload/job_config.cue` — change `name: "JobConfig"` to `name: "job-config"`
- [x] 7.7 Update `v0/traits/workload/init_containers.cue` — change `name: "InitContainers"` to `name: "init-containers"`
- [x] 7.8 Update `v0/traits/workload/health_check.cue` — change `name: "HealthCheck"` to `name: "health-check"`
- [x] 7.9 Update `v0/traits/workload/cron_job_config.cue` — change `name: "CronJobConfig"` to `name: "cron-job-config"`
- [x] 7.10 Update `v0/traits/network/expose.cue` — change `name: "Expose"` to `name: "expose"`
- [x] 7.11 Update `v0/traits/security/encryption.cue` — change `name: "Encryption"` to `name: "encryption"`

## 8. Migrate Name Values — Blueprints

- [x] 8.1 Update `v0/blueprints/workload/stateless_workload.cue` — change `name: "StatelessWorkload"` to `name: "stateless-workload"`
- [x] 8.2 Update `v0/blueprints/workload/stateful_workload.cue` — change `name: "StatefulWorkload"` to `name: "stateful-workload"`
- [x] 8.3 Update `v0/blueprints/workload/task_workload.cue` — change `name: "TaskWorkload"` to `name: "task-workload"`
- [x] 8.4 Update `v0/blueprints/workload/scheduled_task_workload.cue` — change `name: "ScheduledTaskWorkload"` to `name: "scheduled-task-workload"`
- [x] 8.5 Update `v0/blueprints/workload/daemon_workload.cue` — change `name: "DaemonWorkload"` to `name: "daemon-workload"`
- [x] 8.6 Update `v0/blueprints/data/simple_database.cue` — change `name: "SimpleDatabase"` to `name: "simple-database"`

## 9. Migrate Name Values — Policies

- [x] 9.1 Update `v0/policies/network/shared_network.cue` — change `name: "SharedNetwork"` to `name: "shared-network"`
- [x] 9.2 Update `v0/policies/network/network_rules.cue` — change `name: "NetworkRules"` to `name: "network-rules"`

## 10. Migrate Name Values — Providers and Transformers

- [x] 10.1 Update `v0/providers/kubernetes/provider.cue` — change `name: "kubernetes"` (already lowercase, verify it passes `#NameType`)
- [x] 10.2 Update `v0/providers/kubernetes/transformers/deployment_transformer.cue` — change `name: "DeploymentTransformer"` to `name: "deployment-transformer"`
- [x] 10.3 Update `v0/providers/kubernetes/transformers/statefulset_transformer.cue` — change `name: "StatefulsetTransformer"` to `name: "statefulset-transformer"`
- [x] 10.4 Update `v0/providers/kubernetes/transformers/daemonset_transformer.cue` — change `name: "DaemonSetTransformer"` to `name: "daemonset-transformer"`
- [x] 10.5 Update `v0/providers/kubernetes/transformers/job_transformer.cue` — change `name: "JobTransformer"` to `name: "job-transformer"`
- [x] 10.6 Update `v0/providers/kubernetes/transformers/cronjob_transformer.cue` — change `name: "CronJobTransformer"` to `name: "cronjob-transformer"`
- [x] 10.7 Update `v0/providers/kubernetes/transformers/service_transformer.cue` — change `name: "ServiceTransformer"` to `name: "service-transformer"`
- [x] 10.8 Update `v0/providers/kubernetes/transformers/pvc_transformer.cue` — change `name: "PVCTransformer"` to `name: "pvc-transformer"`
- [x] 10.9 Update `v0/providers/kubernetes/transformers/test_data.cue` — update all FQN reference keys to match new `_definitionName`-derived values
- [x] 10.10 Update `v0/providers/registry.cue` — update any FQN reference keys

## 11. Migrate Name Values — Examples

- [x] 11.1 Update `v0/examples/modules/basic_module.cue` — change `name: "BasicModule"` to `name: "basic-module"`, update FQN map keys
- [x] 11.2 Update `v0/examples/modules/multi_tier_module.cue` — change `name: "MultiTierModule"` to `name: "multi-tier-module"`, update FQN map keys
- [x] 11.3 Update `v0/examples/components/basic_component.cue` — update FQN map keys for resources and traits
- [x] 11.4 Update `v0/examples/components/daemon_workload.cue` — update FQN map keys
- [x] 11.5 Update `v0/examples/components/database_components.cue` — update FQN map keys
- [x] 11.6 Update `v0/examples/components/scheduled_task_workload.cue` — update FQN map keys
- [x] 11.7 Update `v0/examples/components/stateful_workload.cue` — update FQN map keys
- [x] 11.8 Update `v0/examples/components/task_workload.cue` — update FQN map keys

## 12. Validation

- [x] 12.1 Run `cue fmt ./...` in each module directory (`v0/core`, `v0/schemas`, `v0/resources`, `v0/traits`, `v0/blueprints`, `v0/policies`, `v0/providers`, `v0/examples`)
- [x] 12.2 Run `cue vet ./...` in each module directory to verify all definitions validate
- [x] 12.3 Run `cue eval ./...` in each module directory to verify all definitions evaluate without errors and inspect output
- [x] 12.4 Run `cue vet -c ./...` in each module directory to force concreteness checks on test fixtures and examples
