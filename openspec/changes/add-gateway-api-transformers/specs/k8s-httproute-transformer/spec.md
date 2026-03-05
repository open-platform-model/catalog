## ADDED Requirements

### Requirement: HTTPRoute transformer definition

The Kubernetes provider SHALL include a `#HttpRouteTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredTraits` containing the HttpRoute trait FQN (`opmodel.dev/traits/network@v0#HttpRoute`). It SHALL have no `requiredLabels` and no `requiredResources`.

#### Scenario: Transformer matches component with HttpRoute trait

- **WHEN** a component has `#HttpRouteTrait` in its `#traits`
- **THEN** the `#HttpRouteTransformer` SHALL match via the standard `#Matches` mechanism

#### Scenario: Transformer does not match component without HttpRoute trait

- **WHEN** a component does not have `#HttpRouteTrait` in its `#traits`
- **THEN** the `#HttpRouteTransformer` SHALL NOT match

### Requirement: HTTPRoute output structure

The transformer SHALL always emit a valid `gateway.networking.k8s.io/v1 HTTPRoute` object when matched. The output SHALL include `apiVersion: "gateway.networking.k8s.io/v1"`, `kind: "HTTPRoute"`, `metadata` with name, namespace, and labels from `#TransformerContext`, and `spec` derived from the HttpRoute trait.

#### Scenario: Basic HTTPRoute with hostnames

- **WHEN** a component defines an HttpRoute trait with `hostnames: ["app.example.com"]` and `rules: [{ matches: [{ path: { value: "/api", type: "Prefix" } }], backendPort: 8080 }]`
- **THEN** the output SHALL be an HTTPRoute with `spec.hostnames: ["app.example.com"]` and one rule with a match for path `/api` of type `PathPrefix`, with `backendRefs` containing an entry for the component service on port 8080

#### Scenario: Gateway parent reference

- **WHEN** a component defines an HttpRoute trait with `gatewayRef: { name: "my-gateway", namespace: "infra" }`
- **THEN** the output HTTPRoute SHALL include `spec.parentRefs` with one entry: `name: "my-gateway"`, `namespace: "infra"`

#### Scenario: No gateway reference

- **WHEN** a component defines an HttpRoute trait without `gatewayRef`
- **THEN** the output HTTPRoute SHALL NOT include `spec.parentRefs`

#### Scenario: Backend references the component Service

- **WHEN** a component named "my-app" with HttpRoute trait (`rules: [{ backendPort: 80 }]`) is transformed
- **THEN** each rule's `backendRefs` SHALL contain `name: "my-app"` (derived from `#component.metadata.name`), `port: 80` (from `backendPort`), and `kind: "Service"`

#### Scenario: Path type mapping

- **WHEN** a component defines path matches with OPM types `"Prefix"`, `"Exact"`, or `"RegularExpression"`
- **THEN** the HTTPRoute SHALL map them to Gateway API types `"PathPrefix"`, `"Exact"`, or `"RegularExpression"` respectively

#### Scenario: Header matching

- **WHEN** a component defines an HttpRoute rule with `matches: [{ headers: [{ name: "x-env", value: "canary" }] }]`
- **THEN** the HTTPRoute rule SHALL include a match with `headers: [{ name: "x-env", value: "canary", type: "Exact" }]`

#### Scenario: HTTP method matching

- **WHEN** a component defines an HttpRoute rule with `matches: [{ method: "POST" }]`
- **THEN** the HTTPRoute rule SHALL include a match with `method: "POST"`

#### Scenario: No matches (catch-all rule)

- **WHEN** a component defines an HttpRoute rule without `matches`
- **THEN** the HTTPRoute rule SHALL have no `matches` field (Gateway API treats this as a catch-all) and SHALL include `backendRefs` for the backend

#### Scenario: No hostnames

- **WHEN** a component defines an HttpRoute trait without `hostnames`
- **THEN** the output HTTPRoute SHALL NOT include `spec.hostnames`

#### Scenario: Multiple rules

- **WHEN** a component defines multiple HttpRoute rules
- **THEN** the output HTTPRoute SHALL produce one `spec.rules` entry per OPM rule

### Requirement: HTTPRoute transformer is primary

The `#HttpRouteTransformer` SHALL always produce output when matched, regardless of whether `gatewayRef` or `ingressClassName` are set. This makes it the primary routing transformer.

#### Scenario: Output produced with gatewayRef

- **WHEN** a component has HttpRoute trait with `gatewayRef` set
- **THEN** the transformer SHALL produce an HTTPRoute with `parentRefs`

#### Scenario: Output produced without gatewayRef

- **WHEN** a component has HttpRoute trait without `gatewayRef`
- **THEN** the transformer SHALL still produce an HTTPRoute (without `parentRefs`)

#### Scenario: Output produced alongside Ingress fallback

- **WHEN** a component has HttpRoute trait with `ingressClassName` set and no `gatewayRef`
- **THEN** the transformer SHALL still produce an HTTPRoute, and the Ingress transformer MAY also produce an Ingress

### Requirement: Provider registration

The `#HttpRouteTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the HTTPRoute transformer

### Requirement: Metadata conventions

The transformer SHALL follow standard metadata conventions.

#### Scenario: Metadata structure

- **WHEN** evaluating `#HttpRouteTransformer.metadata`
- **THEN** it SHALL have `apiVersion: "opmodel.dev/providers/kubernetes/transformers@v0"`, `name: "http-route-transformer"`, and labels `"core.opmodel.dev/trait-type": "network"` and `"core.opmodel.dev/resource-type": "httproute"`

### Requirement: Test data

A test component exercising the HTTPRoute transformer SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the HTTPRoute transformer test data SHALL validate successfully
