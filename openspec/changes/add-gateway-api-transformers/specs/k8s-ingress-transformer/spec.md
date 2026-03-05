## MODIFIED Requirements

### Requirement: Ingress transformer definition

The Kubernetes provider SHALL include a `#IngressTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredTraits` containing the HttpRoute trait FQN. It SHALL NOT require the Expose trait or any separate Ingress trait. It SHALL have no `requiredLabels`.

#### Scenario: Transformer matches component with HttpRoute trait

- **WHEN** a component has `#HttpRouteTrait` in its `#traits`
- **THEN** the `#IngressTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without HttpRoute trait

- **WHEN** a component does not have `#HttpRouteTrait` in its `#traits`
- **THEN** the `#IngressTransformer` SHALL not match

### Requirement: Ingress output structure

The transformer SHALL emit a valid Kubernetes `networking.k8s.io/v1/Ingress` object only when the HttpRoute trait has `ingressClassName` set AND `gatewayRef` is absent. When these conditions are not met, the transformer SHALL produce an empty output. The Ingress output SHALL include `apiVersion: "networking.k8s.io/v1"`, `kind: "Ingress"`, `metadata` with name, namespace, and labels from `#TransformerContext`, and `spec` with rules derived from the HttpRoute trait.

#### Scenario: Ingress produced when ingressClassName set without gatewayRef

- **WHEN** a component defines an HttpRoute trait with `ingressClassName: "nginx"` and no `gatewayRef`
- **THEN** the output SHALL be a valid Ingress resource with `spec.ingressClassName: "nginx"`

#### Scenario: No output when gatewayRef is present

- **WHEN** a component defines an HttpRoute trait with `gatewayRef: { name: "my-gateway" }`
- **THEN** the transformer SHALL produce an empty output (Gateway API HTTPRoute transformer handles this)

#### Scenario: No output when both gatewayRef and ingressClassName are present

- **WHEN** a component defines an HttpRoute trait with both `gatewayRef` and `ingressClassName` set
- **THEN** the transformer SHALL produce an empty output (Gateway API takes precedence)

#### Scenario: No output when neither field is set

- **WHEN** a component defines an HttpRoute trait with neither `gatewayRef` nor `ingressClassName`
- **THEN** the transformer SHALL produce an empty output (Gateway API HTTPRoute is the default primary)

#### Scenario: Single host with path routing

- **WHEN** a component defines an HttpRoute trait with `ingressClassName: "nginx"`, `hostnames: ["app.example.com"]`, no `gatewayRef`, and `rules: [{ matches: [{ path: { value: "/api", type: "Prefix" } }], backendPort: 8080 }]`
- **THEN** the output SHALL be an Ingress with one rule for `host: "app.example.com"` containing a path `/api` with `pathType: "Prefix"` and backend `service.port.number: 8080`

#### Scenario: Backend references the component Service

- **WHEN** a component named "my-app" with HttpRoute trait (`ingressClassName: "nginx"`, no `gatewayRef`, `rules: [{ backendPort: 80 }]`) is transformed
- **THEN** each Ingress path's `backend` SHALL reference `service.name: "my-app"` (derived from `#component.metadata.name`) and `service.port.number: 80` (from `backendPort`)

#### Scenario: No hostnames specified

- **WHEN** a component defines an HttpRoute trait with `ingressClassName` set, no `gatewayRef`, and no `hostnames`
- **THEN** the output Ingress SHALL emit rules without the `host` field (matching all hosts)

### Requirement: TLS configuration

When the HttpRoute trait specifies TLS configuration (via `#RouteAttachmentSchema`) and the Ingress fallback conditions are met, the output SHALL include `spec.tls` entries.

#### Scenario: TLS with certificate reference

- **WHEN** a component defines an HttpRoute trait with `ingressClassName: "nginx"`, no `gatewayRef`, `tls: { mode: "Terminate", certificateRef: { name: "app-tls" } }`, and `hostnames: ["app.example.com"]`
- **THEN** the output Ingress SHALL include `spec.tls` with `hosts: ["app.example.com"]` and `secretName: "app-tls"`

#### Scenario: No TLS when not specified

- **WHEN** a component defines an HttpRoute trait with `ingressClassName` set, no `gatewayRef`, and no `tls`
- **THEN** the output Ingress SHALL NOT include `spec.tls`

### Requirement: Provider registration

The `#IngressTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the Ingress transformer

### Requirement: Test data

Test components exercising both the fallback and skip conditions of the Ingress transformer SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the Ingress transformer test data SHALL validate successfully
