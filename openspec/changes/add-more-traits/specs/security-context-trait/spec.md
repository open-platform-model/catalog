## ADDED Requirements

### Requirement: SecurityContext schema definition

The schemas module SHALL define a `#SecurityContextSchema` that specifies container and pod-level security constraints. The schema SHALL include fields for `runAsNonRoot` (bool, default true), `runAsUser` (optional int), `runAsGroup` (optional int), `readOnlyRootFilesystem` (bool, default false), `allowPrivilegeEscalation` (bool, default false), and `capabilities` (optional struct with `add` and `drop` string lists, `drop` defaulting to `["ALL"]`).

#### Scenario: Schema validates a minimal security context

- **WHEN** a component specifies `securityContext: { runAsNonRoot: true }`
- **THEN** the schema SHALL accept the value with all other fields using their defaults

#### Scenario: Schema rejects invalid capability names

- **WHEN** a component specifies `securityContext: { capabilities: { add: [123] } }`
- **THEN** the schema SHALL reject the value because capability names MUST be strings

#### Scenario: Schema accepts full security hardening

- **WHEN** a component specifies `securityContext: { runAsNonRoot: true, runAsUser: 1000, runAsGroup: 1000, readOnlyRootFilesystem: true, allowPrivilegeEscalation: false, capabilities: { drop: ["ALL"] } }`
- **THEN** the schema SHALL accept the value

### Requirement: SecurityContext trait definition

The traits module SHALL define a `#SecurityContextTrait` in `traits/security/security_context.cue` that wraps `#SecurityContextSchema`. The trait SHALL declare `appliesTo: [workload_resources.#ContainerResource]`. The trait SHALL provide `#defaults` with `runAsNonRoot: true` and `allowPrivilegeEscalation: false`.

#### Scenario: Trait composes with a stateless workload component

- **WHEN** a component includes both `#Container` resource and `#SecurityContext` trait
- **THEN** the component SHALL validate successfully and expose `spec.securityContext` in its spec

#### Scenario: Trait provides safe defaults

- **WHEN** a component includes `#SecurityContext` trait without specifying values
- **THEN** the trait defaults SHALL set `runAsNonRoot: true` and `allowPrivilegeEscalation: false`
