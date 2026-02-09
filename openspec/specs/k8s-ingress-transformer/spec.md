## Purpose

Specifies the Kubernetes Ingress transformer, which converts OPM HttpRoute trait configuration into Kubernetes `networking.k8s.io/v1/Ingress` objects.

## Requirements

### Requirement: Ingress transformer definition

The Kubernetes provider SHALL include a `#IngressTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredTraits` containing the HttpRoute trait FQN. It SHALL NOT require the Expose trait or any separate Ingress trait. It SHALL have no `requiredLabels`.

#### Scenario: Transformer matches component with HttpRoute trait

- **WHEN** a component has `#HttpRouteTrait` in its `#traits`
- **THEN** the `#IngressTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without HttpRoute trait

- **WHEN** a component does not have `#HttpRouteTrait` in its `#traits`
- **THEN** the `#IngressTransformer` SHALL not match

### Requirement: Ingress output structure

The transformer SHALL emit a valid Kubernetes `networking.k8s.io/v1/Ingress` object. The output SHALL include `apiVersion: "networking.k8s.io/v1"`, `kind: "Ingress"`, `metadata` with name, namespace, and labels from `#TransformerContext`, and `spec` with rules derived from the HttpRoute trait.

#### Scenario: Single host with path routing

- **WHEN** a component defines an HttpRoute trait with `hostnames: ["app.example.com"]` and `rules: [{ matches: [{ path: { value: "/api", type: "Prefix" } }], backendPort: 8080 }]`
- **THEN** the output SHALL be an Ingress with one rule for `host: "app.example.com"` containing a path `/api` with `pathType: "Prefix"` and backend `service.port.number: 8080`

#### Scenario: Backend references the component Service

- **WHEN** a component named "my-app" with HttpRoute trait (`rules: [{ backendPort: 80 }]`) is transformed
- **THEN** each Ingress path's `backend` SHALL reference `service.name: "my-app"` (derived from `#component.metadata.name`) and `service.port.number: 80` (from `backendPort`)

#### Scenario: Multiple paths under one host

- **WHEN** a component defines an HttpRoute trait with one hostname and rules containing multiple path matches
- **THEN** the output Ingress rule SHALL contain all paths under that host

#### Scenario: Path type defaults to Prefix

- **WHEN** a component defines an HttpRoute with a path match where `type` defaults to `"Prefix"`
- **THEN** the Ingress path SHALL use `pathType: "Prefix"`

#### Scenario: No hostnames specified

- **WHEN** a component defines an HttpRoute trait without `hostnames`
- **THEN** the output Ingress SHALL emit rules without the `host` field (matching all hosts)

### Requirement: TLS configuration

When the HttpRoute trait specifies TLS configuration (via `#RouteAttachmentSchema`), the output SHALL include `spec.tls` entries.

#### Scenario: TLS with certificate reference

- **WHEN** a component defines an HttpRoute trait with `tls: { mode: "Terminate", certificateRef: { name: "app-tls" } }` and `hostnames: ["app.example.com"]`
- **THEN** the output Ingress SHALL include `spec.tls` with `hosts: ["app.example.com"]` and `secretName: "app-tls"`

#### Scenario: No TLS when not specified

- **WHEN** a component defines an HttpRoute trait without `tls`
- **THEN** the output Ingress SHALL NOT include `spec.tls`

### Requirement: Ingress class

When the HttpRoute trait specifies `ingressClassName` (via `#RouteAttachmentSchema`), the output SHALL include `spec.ingressClassName`.

#### Scenario: Custom ingress class

- **WHEN** a component defines an HttpRoute trait with `ingressClassName: "nginx"`
- **THEN** the output Ingress SHALL include `spec.ingressClassName: "nginx"`

### Requirement: Provider registration

The `#IngressTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the Ingress transformer

### Requirement: Test data

A test component exercising the Ingress transformer SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the Ingress transformer test data SHALL validate successfully
