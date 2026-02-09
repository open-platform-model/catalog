## 1. Experiment Scaffold

- [x] 1.1 Initialize CUE module at `experiments/001-config-sources/` with `cue.mod/module.cue` (no external deps)
- [x] 1.2 Copy `v0/core/*.cue` into `experiments/001-config-sources/core/`, remove nested `cue.mod/`
- [x] 1.3 Copy `v0/schemas/*.cue` into `experiments/001-config-sources/schemas/`, remove nested `cue.mod/`
- [x] 1.4 Copy `v0/resources/**/*.cue` into `experiments/001-config-sources/resources/`, remove nested `cue.mod/`
- [x] 1.5 Copy `v0/traits/**/*.cue` into `experiments/001-config-sources/traits/`, remove nested `cue.mod/`
- [x] 1.6 Copy `v0/providers/**/*.cue` into `experiments/001-config-sources/providers/`, remove nested `cue.mod/`
- [x] 1.7 Rewrite all import paths from `opmodel.dev/<pkg>@v0` to local package paths (e.g., `example.com/config-sources/<pkg>`)
- [x] 1.8 Validate baseline: `cue vet ./...` passes with copied (unmodified) definitions

## 2. Schema Changes

- [x] 2.1 Add `#ConfigSourceSchema` to `schemas/config.cue` with `type`, `data`, `externalRef` fields and mutual exclusivity constraint
- [x] 2.2 Extend `#ContainerSchema.env` in `schemas/workload.cue` to support `from: { source, key }` alongside existing `value`, with mutual exclusivity constraint
- [x] 2.3 Validate schema changes: `cue vet ./...` passes

## 3. Resource Definition

- [x] 3.1 Create `resources/config/config_source.cue` with `#ConfigSourceResource` and `#ConfigSources` component helper
- [x] 3.2 Validate resource definition: `cue vet ./...` passes

## 4. Config Source Transformer

- [x] 4.1 Create `providers/kubernetes/transformers/config_source_transformer.cue` that emits ConfigMap or Secret based on source type, skips external refs, uses `{component}-{source}` naming
- [x] 4.2 Register the transformer in `providers/kubernetes/provider.cue`
- [x] 4.3 Validate transformer: `cue vet ./...` passes

## 5. Workload Transformer Updates

- [x] 5.1 Update deployment transformer to resolve `env.from` references — look up `configSources`, emit `valueFrom.secretKeyRef` or `valueFrom.configMapKeyRef` with correct name resolution (generated vs external)
- [x] 5.2 Update statefulset transformer with same `env.from` resolution logic
- [x] 5.3 Update daemonset transformer with same `env.from` resolution logic
- [x] 5.4 Update job transformer with same `env.from` resolution logic
- [x] 5.5 Update cronjob transformer with same `env.from` resolution logic
- [x] 5.6 Validate all transformer updates: `cue vet ./...` passes

## 6. Examples and Validation

- [x] 6.1 Create example component with inline config source, inline secret source, and external ref source — env vars using both `value` and `from`
- [x] 6.2 Create example module wrapping the component with `#config`/`values` parameterization
- [x] 6.3 Verify transformer output with `cue eval` — confirm emitted ConfigMap, Secret, and Deployment with `valueFrom` refs
- [x] 6.4 Final validation: `cue vet ./...` passes on entire experiment
- [x] 6.5 Run `cue fmt ./...` to ensure formatting
