## ADDED Requirements

### Requirement: HealthCheck trait wired into workload transformer output

The Deployment, StatefulSet, and DaemonSet transformers SHALL extract the HealthCheck trait from the component spec and emit `livenessProbe` and `readinessProbe` on the main container in the K8s output. HealthCheck SHALL remain an optional trait on these transformers.

#### Scenario: Component with liveness and readiness probes

- **WHEN** a stateless component defines `healthCheck` with both `livenessProbe` (httpGet on port 8080, path "/healthz") and `readinessProbe` (httpGet on port 8080, path "/ready")
- **THEN** the Deployment transformer output SHALL include `livenessProbe` and `readinessProbe` on the first container in `spec.template.spec.containers`

#### Scenario: Component with only readiness probe

- **WHEN** a stateless component defines `healthCheck` with only `readinessProbe`
- **THEN** the Deployment transformer output SHALL include `readinessProbe` on the main container and SHALL NOT include `livenessProbe`

#### Scenario: Component without HealthCheck trait

- **WHEN** a stateless component does not define `healthCheck`
- **THEN** the Deployment transformer output SHALL NOT include `livenessProbe` or `readinessProbe` on any container

#### Scenario: Probes apply to main container only

- **WHEN** a stateless component defines both `healthCheck` and `sidecarContainers`
- **THEN** the probes SHALL be emitted only on the first container (main container), not on sidecar containers

#### Scenario: Probe with exec command

- **WHEN** a stateful component defines `healthCheck` with `livenessProbe.exec.command: ["pg_isready"]`
- **THEN** the StatefulSet transformer output SHALL include a liveness probe with `exec.command: ["pg_isready"]`

#### Scenario: Probe timing parameters

- **WHEN** a component defines `healthCheck` with `readinessProbe.initialDelaySeconds: 10` and `readinessProbe.periodSeconds: 5`
- **THEN** the transformer output SHALL include those timing parameters on the readiness probe

### Requirement: Sizing trait wired into workload transformer output

All workload transformers (Deployment, StatefulSet, DaemonSet, Job, CronJob) SHALL declare Sizing as an optional trait, extract it from the component spec, and emit `resources` (requests and limits) on the main container in the K8s output.

#### Scenario: Component with CPU and memory limits

- **WHEN** a stateless component defines `sizing` with `cpu: { request: "100m", limit: "500m" }` and `memory: { request: "128Mi", limit: "256Mi" }`
- **THEN** the Deployment transformer output SHALL include `resources.requests.cpu: "100m"`, `resources.limits.cpu: "500m"`, `resources.requests.memory: "128Mi"`, `resources.limits.memory: "256Mi"` on the main container

#### Scenario: Component with only memory limits

- **WHEN** a component defines `sizing` with only `memory: { request: "64Mi", limit: "128Mi" }`
- **THEN** the transformer output SHALL include memory resources and SHALL NOT include CPU resources

#### Scenario: Component without Sizing trait

- **WHEN** a component does not define `sizing`
- **THEN** the transformer output SHALL NOT include a `resources` field on the container (beyond any resources already in the Container schema)

#### Scenario: Sizing on Job workload

- **WHEN** a task component defines `sizing`
- **THEN** the Job transformer output SHALL include `resources` on the main container

### Requirement: SecurityContext trait wired into workload transformer output

All workload transformers SHALL declare SecurityContext as an optional trait, extract it from the component spec, and emit pod-level and container-level `securityContext` fields in the K8s output. Pod-level fields: `runAsNonRoot`, `runAsUser`, `runAsGroup`. Container-level fields: `readOnlyRootFilesystem`, `allowPrivilegeEscalation`, `capabilities`.

#### Scenario: Component with full security context

- **WHEN** a stateless component defines `securityContext` with `runAsNonRoot: true`, `runAsUser: 1000`, `runAsGroup: 1000`, `readOnlyRootFilesystem: true`, `allowPrivilegeEscalation: false`, `capabilities: { drop: ["ALL"] }`
- **THEN** the Deployment transformer output SHALL include pod-level `securityContext: { runAsNonRoot: true, runAsUser: 1000, runAsGroup: 1000 }` and container-level `securityContext: { readOnlyRootFilesystem: true, allowPrivilegeEscalation: false, capabilities: { drop: ["ALL"] } }` on the main container

#### Scenario: Component with only pod-level security context

- **WHEN** a component defines `securityContext` with only `runAsNonRoot: true`
- **THEN** the transformer output SHALL include pod-level `securityContext: { runAsNonRoot: true }` and SHALL NOT include container-level securityContext

#### Scenario: Component without SecurityContext trait

- **WHEN** a component does not define `securityContext`
- **THEN** the transformer output SHALL NOT include `securityContext` at pod or container level

#### Scenario: SecurityContext on DaemonSet

- **WHEN** a daemon component defines `securityContext`
- **THEN** the DaemonSet transformer output SHALL include the appropriate securityContext fields

### Requirement: Existing transformer output is unchanged when traits are absent

Adding new optional traits to existing workload transformers SHALL NOT change the output for components that do not use those traits. The existing test data SHALL continue to produce identical output.

#### Scenario: Deployment without new traits produces same output

- **WHEN** a stateless component with only a Container resource (no HealthCheck, Sizing, or SecurityContext) is transformed
- **THEN** the Deployment output SHALL be identical to the output before this change

### Requirement: Updated test data

Test components exercising the new trait wiring SHALL be added to the transformers test data file, covering each trait on at least one workload type.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** all test data (existing and new) SHALL validate successfully
