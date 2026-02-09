## Why

OPM has three disconnected mechanisms for configuration: literal env values on containers, standalone ConfigMap/Secret resources, and volume-mount references — but no way to wire them together. Containers cannot reference values from secrets or configmaps, forcing module authors to put sensitive values as plaintext literals in env (as the SimpleDatabase blueprint does today). This is the most common gap reported when modeling real-world Kubernetes workloads.

## What Changes

- **New `#ConfigSourceSchema`**: A unified abstraction for named configuration sources that can be either `config` (non-sensitive) or `secret` (sensitive), with data provided inline or via external reference
- **New `#ConfigSourceResource`**: A resource definition that attaches named config sources to a component, replacing the separate `#ConfigMapResource` and `#SecretResource`
- **Extended `#ContainerSchema.env`**: Each env var gains an optional `from` field to reference a key from a named config source, alongside the existing literal `value`
- **New config-source transformer**: A single transformer that emits K8s ConfigMaps or Secrets based on the source's `type` field; external refs emit nothing (resource already exists)
- **Updated workload transformers**: Resolve `env.from` references to K8s `valueFrom.secretKeyRef` or `valueFrom.configMapKeyRef` based on the referenced source's type
- **BREAKING**: `#ConfigMapResource` and `#SecretResource` are superseded by `#ConfigSourceResource`. Existing configmap/secret transformers are superseded by the config-source transformer.

This is a **self-contained experiment** in `experiments/001-config-sources/` — all affected modules (core, schemas, resources, traits, providers) will be copied into a single CUE module for rapid iteration before any changes land in the main catalog.

## Capabilities

### New Capabilities

- `config-source-schema`: The `#ConfigSourceSchema` definition — typed config/secret, inline data or external ref, and the env `from` reference schema
- `config-source-resource`: The `#ConfigSourceResource` definition and its `#ConfigSources` component helper
- `config-source-transformer`: K8s transformer that emits ConfigMap or Secret based on source type, and wires `env.from` to `valueFrom` in workload transformers
- `experiment-scaffold`: Self-contained CUE module under `experiments/001-config-sources/` with all dependencies inlined for isolated iteration

### Modified Capabilities

_(No existing spec requirements change — this is additive. The existing `configmaps-resource`, `secrets-resource`, and their transformers remain in the main catalog unchanged. The experiment may inform their future deprecation but does not modify them.)_

## Impact

- **Semver**: MINOR (additive capability, no breaking changes to published modules — experiment is isolated)
- **Modules affected (in experiment)**: schemas, resources, providers/kubernetes
- **API**: Non-breaking for consumers — `#ConfigMapResource` and `#SecretResource` continue to exist. `#ConfigSourceResource` is a new alternative. The env schema extension (`from` field) is additive (existing `value`-only usage remains valid).
- **Portability**: `#ConfigSourceSchema` is platform-agnostic. The `from` reference pattern (source + key) maps naturally to any platform that supports secret/config injection (K8s, ECS, Nomad, Cloud Run). Provider-specific concerns stay in the transformer.
- **Dependencies**: The experiment copies all needed modules into a single CUE module — no registry dependency during iteration.
