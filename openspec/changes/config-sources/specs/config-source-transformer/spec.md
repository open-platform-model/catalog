## ADDED Requirements

### Requirement: Config source resource emission

The config-source transformer SHALL iterate over all entries in `component.spec.configSources` and emit platform-native resources for entries with inline `data`. Entries with `externalRef` SHALL NOT produce any output resource.

#### Scenario: Inline config source emits ConfigMap

- **WHEN** a config source has `type: "config"` and `data: { KEY: "value" }`
- **THEN** the K8s transformer SHALL emit a `v1/ConfigMap` with the data

#### Scenario: Inline secret source emits Secret

- **WHEN** a config source has `type: "secret"` and `data: { password: "hunter2" }`
- **THEN** the K8s transformer SHALL emit a `v1/Secret` with type `Opaque` and the data

#### Scenario: External ref emits nothing

- **WHEN** a config source has `externalRef: { name: "prod-creds" }`
- **THEN** the K8s transformer SHALL NOT emit any resource for that source

#### Scenario: Multiple sources on one component

- **WHEN** a component defines three config sources (two inline, one external)
- **THEN** the transformer SHALL emit exactly two K8s resources (one per inline source)

### Requirement: Deterministic resource naming

Resources emitted by the config-source transformer SHALL use a deterministic naming convention: `{component-name}-{source-name}`.

#### Scenario: Naming convention

- **WHEN** component `web-app` defines config source `db-credentials`
- **THEN** the emitted K8s Secret SHALL have metadata name `web-app-db-credentials`

#### Scenario: Name uniqueness across components

- **WHEN** component `frontend` and component `backend` both define a source named `app-config`
- **THEN** the emitted resources SHALL be named `frontend-app-config` and `backend-app-config` respectively

### Requirement: Env from resolution in workload transformers

Workload transformers (deployment, statefulset, daemonset, job, cronjob) SHALL resolve `env.from` references by looking up the referenced source in the same component's `configSources` and emitting the appropriate platform-native injection mechanism.

#### Scenario: Env from secret source resolves to secretKeyRef

- **WHEN** container env var has `from: { source: "db-credentials", key: "password" }`
- **AND** `configSources["db-credentials"]` has `type: "secret"`
- **THEN** the K8s transformer SHALL emit `valueFrom.secretKeyRef` with `name` resolved from the source and `key: "password"`

#### Scenario: Env from config source resolves to configMapKeyRef

- **WHEN** container env var has `from: { source: "app-settings", key: "LOG_LEVEL" }`
- **AND** `configSources["app-settings"]` has `type: "config"`
- **THEN** the K8s transformer SHALL emit `valueFrom.configMapKeyRef` with `name` resolved from the source and `key: "LOG_LEVEL"`

#### Scenario: Env from external ref uses external name

- **WHEN** container env var has `from: { source: "vault-creds", key: "api-key" }`
- **AND** `configSources["vault-creds"]` has `externalRef: { name: "prod-vault-creds" }`
- **THEN** the K8s transformer SHALL use `name: "prod-vault-creds"` in the `valueFrom` ref (the external name, not the source name)

#### Scenario: Env from inline source uses generated name

- **WHEN** container env var has `from: { source: "db-credentials", key: "password" }`
- **AND** `configSources["db-credentials"]` has inline `data`
- **AND** the component name is `web-app`
- **THEN** the K8s transformer SHALL use `name: "web-app-db-credentials"` in the `valueFrom` ref

#### Scenario: Literal env vars unchanged

- **WHEN** container env var has `value: "production"` (no `from` field)
- **THEN** the workload transformer SHALL emit a literal `value` env var as today
- **AND** `configSources` SHALL have no effect on literal env vars

### Requirement: Transformer matching

The config-source transformer SHALL match components that have the `#ConfigSourceResource` in their resource map. It SHALL NOT require specific labels for matching.

#### Scenario: Component with ConfigSources matches

- **WHEN** a component includes `#ConfigSources` (composing the resource)
- **THEN** the config-source transformer SHALL match and process the component

#### Scenario: Component without ConfigSources does not match

- **WHEN** a component does not include `#ConfigSources`
- **THEN** the config-source transformer SHALL not match
- **AND** existing workload transformer behavior SHALL be unchanged
