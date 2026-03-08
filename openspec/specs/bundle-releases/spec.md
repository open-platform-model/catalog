## ADDED Requirements

### Requirement: BundleInstance type defines per-instance metadata

The catalog SHALL define `#BundleInstance` in `v1alpha1/core/bundle/` with fields: `module` (a `#Module`), `metadata` (containing required `name` and `namespace`, optional `labels` and `annotations`), and optional `values` constrained to the module's `#config` schema. Each instance within a bundle represents a concrete module deployment target.

#### Scenario: BundleInstance with explicit namespace
- **WHEN** a `#BundleInstance` is defined with `metadata.namespace: "game-servers"`
- **THEN** the instance SHALL carry that namespace for use in release generation

#### Scenario: BundleInstance name defaults to map key
- **WHEN** a `#BundleInstance` is keyed as `"minecraft"` in the bundle's `#instances` map and `metadata.name` is not explicitly set
- **THEN** `metadata.name` SHALL default to `"minecraft"`

### Requirement: Bundle uses instances instead of modules

`#Bundle.#modules` SHALL be replaced with `#Bundle.#instances`, typed as `[string]: #BundleInstance`. Each entry maps an instance name to a `#BundleInstance` containing a module reference, deployment metadata, and optional values.

#### Scenario: Bundle with multiple instances of the same module
- **WHEN** a bundle defines two instances pointing to the same module but with different namespaces
- **THEN** both instances SHALL be valid and carry independent metadata

### Requirement: Bundle uses BundleFQNType

`#Bundle.metadata.fqn` SHALL use `#BundleFQNType` (format: `path/name:vN`) instead of `#ModuleFQNType`. The `#BundleFQNType` regex SHALL be defined in `v1alpha1/core/types/types.cue` and match `^[a-z0-9.-]+(/[a-z0-9.-]+)*/[a-z0-9]([a-z0-9-]*[a-z0-9])?:v[0-9]+$`.

#### Scenario: Bundle FQN uses major version format
- **WHEN** a bundle has `modulePath: "opmodel.dev/bundles"`, `name: "game-stack"`, `version: "v1"`
- **THEN** `fqn` SHALL evaluate to `"opmodel.dev/bundles/game-stack:v1"`

### Requirement: Bundle supports policies

`#Bundle` SHALL include an optional `#policies` field typed as `[string]: #Policy`, enabling bundle-level governance rules that apply across all instances.

#### Scenario: Bundle with a security policy
- **WHEN** a bundle defines a policy under `#policies`
- **THEN** the policy SHALL be accessible on the bundle definition

### Requirement: BundleRelease generates ModuleReleases per instance

The catalog SHALL define `#BundleRelease` in `v1alpha1/core/bundlerelease/` that takes a `#bundle` and `values`, and generates a `releases` map containing one `#ModuleRelease` per instance. Each release SHALL have `name` set to `"{bundleReleaseName}-{instanceName}"`, `namespace` from the instance metadata, `#module` from the instance, and `values` from the instance (if provided).

#### Scenario: BundleRelease with two instances
- **WHEN** a `#BundleRelease` named `"prod"` references a bundle with instances `"minecraft"` (namespace `"mc-ns"`) and `"monitor"` (namespace `"mon-ns"`)
- **THEN** `releases` SHALL contain `"minecraft"` as a `#ModuleRelease` with name `"prod-minecraft"` and namespace `"mc-ns"`
- **AND** `releases` SHALL contain `"monitor"` as a `#ModuleRelease` with name `"prod-monitor"` and namespace `"mon-ns"`

#### Scenario: BundleRelease UUID is deterministic
- **WHEN** a `#BundleRelease` is created with a name and bundle reference
- **THEN** `metadata.uuid` SHALL be computed as `SHA1(OPMNamespace, bundleFQN + ":" + name)`
