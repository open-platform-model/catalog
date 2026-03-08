## ADDED Requirements

### Requirement: Release-prefixed K8s resource naming

All Kubernetes transformer outputs in `v1alpha1/providers/kubernetes/transformers/` SHALL name resources as `"{moduleReleaseName}-{componentName}"` instead of `"{componentName}"`. This enables multiple releases of the same module to coexist in a single namespace without name collisions.

#### Scenario: Deployment resource name
- **WHEN** a Deployment transformer renders a component named `"web"` for a release named `"prod"`
- **THEN** the Deployment's `metadata.name` SHALL be `"prod-web"`

#### Scenario: Service resource name
- **WHEN** a Service transformer renders for component `"api"` in release `"staging"`
- **THEN** the Service's `metadata.name` SHALL be `"staging-api"`

#### Scenario: StatefulSet serviceName matches resource name
- **WHEN** a StatefulSet transformer renders for component `"db"` in release `"prod"`
- **THEN** `metadata.name` and `spec.serviceName` SHALL both be `"prod-db"`

#### Scenario: HPA scaleTargetRef uses prefixed name
- **WHEN** an HPA transformer renders for a component in release `"prod"`
- **THEN** `spec.scaleTargetRef.name` SHALL use the release-prefixed name matching the actual Deployment/StatefulSet name

#### Scenario: Ingress backend uses prefixed service name
- **WHEN** an Ingress transformer renders backend service references
- **THEN** the backend `service.name` SHALL use the release-prefixed name matching the actual Service name

### Requirement: Release prefix propagated to container helpers

`#ToK8sContainer`, `#ToK8sContainers`, and `#ToK8sVolumes` helper functions in `v1alpha1/providers/kubernetes/transformers/container_helpers.cue` SHALL accept an optional `#releasePrefix` parameter. When set, secret environment variable references and PVC claim names SHALL be prefixed with the release name.

#### Scenario: Secret env var reference with release prefix
- **WHEN** a container has an env var referencing `from: {$secretName: "db-creds"}` and `#releasePrefix` is `"prod"`
- **THEN** the K8s env var's `secretKeyRef.name` SHALL be `"prod-db-creds"`

#### Scenario: PVC claim name with release prefix
- **WHEN** a volume has `persistentClaim` source and `#releasePrefix` is `"prod"`
- **THEN** the PVC `claimName` SHALL be `"prod-{volumeName}"`

### Requirement: Namespace from moduleReleaseMetadata

All transformers SHALL read namespace from `#context.#moduleReleaseMetadata.namespace` instead of a flat `#context.namespace` field. No `| *"default"` fallback SHALL be used — namespace is always required from the release metadata.

#### Scenario: Namespace set from release metadata
- **WHEN** a transformer renders a K8s resource and `#moduleReleaseMetadata.namespace` is `"production"`
- **THEN** `metadata.namespace` on the output resource SHALL be `"production"`
