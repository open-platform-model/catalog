## Requirements

### Requirement: GracefulShutdown schema definition

The schemas module SHALL define a `#GracefulShutdownSchema` that specifies workload termination behavior. The schema SHALL include a `terminationGracePeriodSeconds` field (optional int, default 30) and an optional `preStopCommand` field (list of strings) for running a command before the workload receives SIGTERM.

#### Scenario: Schema validates with default grace period

- **WHEN** a component specifies `gracefulShutdown: {}`
- **THEN** the schema SHALL accept the value with `terminationGracePeriodSeconds` defaulting to 30

#### Scenario: Schema validates custom grace period

- **WHEN** a component specifies `gracefulShutdown: { terminationGracePeriodSeconds: 120 }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema validates with preStop command

- **WHEN** a component specifies `gracefulShutdown: { terminationGracePeriodSeconds: 60, preStopCommand: ["/bin/sh", "-c", "sleep 10"] }`
- **THEN** the schema SHALL accept the value

#### Scenario: Schema rejects negative grace period

- **WHEN** a component specifies `gracefulShutdown: { terminationGracePeriodSeconds: -1 }`
- **THEN** the schema SHALL reject the value because the grace period MUST be a non-negative integer

### Requirement: GracefulShutdown trait definition

The traits module SHALL define a `#GracefulShutdownTrait` in `traits/workload/graceful_shutdown.cue` that wraps `#GracefulShutdownSchema`. The trait SHALL declare `appliesTo: [workload_resources.#ContainerResource]`. The trait SHALL provide `#defaults` with `terminationGracePeriodSeconds: 30`.

#### Scenario: Trait composes with any workload type

- **WHEN** a component of any workload type includes `#GracefulShutdown` trait
- **THEN** the component SHALL validate successfully and expose `spec.gracefulShutdown` in its spec

#### Scenario: Trait provides a reasonable default

- **WHEN** a component includes `#GracefulShutdown` without specifying values
- **THEN** the trait defaults SHALL set `terminationGracePeriodSeconds: 30`
