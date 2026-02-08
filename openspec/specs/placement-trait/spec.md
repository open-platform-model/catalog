## Requirements

### Requirement: Placement schema definition

The schemas module SHALL define a `#PlacementSchema` that specifies workload placement intent in a provider-agnostic way. The schema SHALL include an optional `spreadAcross` field constrained to `"zones"`, `"regions"`, or `"hosts"` (default `"zones"`) expressing the desired failure domain distribution. The schema SHALL include an optional `requirements` field as a string-to-string map for expressing node/host selection criteria. The schema SHALL include an optional `platformOverrides` open struct as an escape hatch for provider-specific placement details.

#### Scenario: Schema validates zone spread

- **WHEN** a component specifies `placement: { spreadAcross: "zones" }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema validates with node requirements

- **WHEN** a component specifies `placement: { requirements: { "gpu": "true", "tier": "high-memory" } }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema validates combined spread and requirements

- **WHEN** a component specifies `placement: { spreadAcross: "regions", requirements: { "tier": "dedicated" } }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema rejects invalid spread target

- **WHEN** a component specifies `placement: { spreadAcross: "racks" }`
- **THEN** the schema SHALL reject the value because `spreadAcross` MUST be one of `"zones"`, `"regions"`, or `"hosts"`

#### Scenario: Schema accepts platform overrides

- **WHEN** a component specifies `placement: { spreadAcross: "zones", platformOverrides: { tolerations: [{ key: "dedicated", operator: "Equal", value: "gpu", effect: "NoSchedule" }] } }`
- **THEN** the schema SHALL accept the value because `platformOverrides` is an open struct

### Requirement: Placement trait definition

The traits module SHALL define a `#PlacementTrait` in `traits/workload/placement.cue` that wraps `#PlacementSchema`. The trait SHALL declare `appliesTo: [workload_resources.#ContainerResource]`. The trait SHALL provide `#defaults` with `spreadAcross: "zones"`.

#### Scenario: Trait composes with a stateless workload

- **WHEN** a component includes `#Container` resource and `#Placement` trait
- **THEN** the component SHALL validate successfully and expose `spec.placement` in its spec

#### Scenario: Trait default provides zone-level spread

- **WHEN** a component includes `#Placement` without specifying values
- **THEN** the trait defaults SHALL set `spreadAcross: "zones"`

### Requirement: Placement abstraction is provider-agnostic

The `spreadAcross` and `requirements` fields SHALL use provider-neutral vocabulary. Provider-specific translation (e.g., mapping `"zones"` to Kubernetes `topologySpreadConstraints` with `topology.kubernetes.io/zone`) SHALL be the responsibility of the provider's transformer, not the trait definition.

#### Scenario: Same placement spec works across providers

- **WHEN** a component specifies `placement: { spreadAcross: "zones", requirements: { "gpu": "true" } }`
- **THEN** a Kubernetes transformer SHALL map this to `topologySpreadConstraints` and `nodeSelector`
- **THEN** a different provider transformer SHALL map this to its own equivalent constructs
