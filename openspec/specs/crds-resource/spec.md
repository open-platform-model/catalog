### Requirement: CRD schema definition

The system SHALL provide a `#CRDSchema` in the `schemas` module that captures the essential fields of a Kubernetes CustomResourceDefinition in a structured, type-safe way. The schema SHALL include:

- `group!: string` — the API group (e.g., `"grafana.integreatly.org"`)
- `names!` — with required `kind!: string`, `plural!: string`, and optional `singular?: string`, `shortNames?: [...string]`, `categories?: [...string]`
- `scope!: *"Namespaced" | "Cluster"` — defaulting to `"Namespaced"`
- `versions!: [...#CRDVersionSchema]` — at least one version entry, each with `name!: string`, `served!: bool`, `storage!: bool`, and optional `schema?: {openAPIV3Schema: {...}}`, `subresources?: {...}`, `additionalPrinterColumns?: [...{...}]`

#### Scenario: Minimal valid CRD schema

- **WHEN** a user provides only the required fields (`group`, `names.kind`, `names.plural`, `scope`, one version with `name`, `served`, `storage`)
- **THEN** CUE validation SHALL succeed

#### Scenario: CRD schema with openAPIV3Schema

- **WHEN** a user provides an arbitrary `versions[].schema.openAPIV3Schema` struct
- **THEN** CUE validation SHALL succeed regardless of the schema's content (open struct)

#### Scenario: Missing required field rejected

- **WHEN** a user omits a required field (e.g., `group`)
- **THEN** CUE validation SHALL reject the definition at evaluation time

### Requirement: CRDs resource definition

The system SHALL provide a `#CRDsResource` in the `resources/extension` package as a map-based OPM resource where each key names a CRD entry and each value conforms to `#CRDSchema`.

#### Scenario: Single CRD in resource

- **WHEN** a component's `spec.crds` map contains one entry
- **THEN** the resource SHALL validate successfully

#### Scenario: Multiple CRDs in resource

- **WHEN** a component's `spec.crds` map contains multiple entries with distinct keys
- **THEN** the resource SHALL validate all entries against `#CRDSchema`

### Requirement: CRDs component helper

The system SHALL provide a `#CRDs: core.#Component` helper that pre-wires `#CRDsResource` and sets the `"transformer.opmodel.dev/list-output": true` annotation, so users can construct CRD-bearing components without manually wiring the resource FQN.

#### Scenario: CRDs component validates

- **WHEN** a user constructs a `#CRDs` component with a valid `spec.crds` map
- **THEN** CUE validation SHALL succeed

### Requirement: Kubernetes apiextensions schema wrapper

The system SHALL expose `#CustomResourceDefinition` from `cue.dev/x/k8s.io/apiextensions-apiserver/pkg/apis/apiextensions/v1` via a new `opmodel.dev/schemas/kubernetes/apiextensions/v1@v1` package, consistent with how other K8s types are wrapped.

#### Scenario: Wrapper re-exports upstream type

- **WHEN** a transformer imports `opmodel.dev/schemas/kubernetes/apiextensions/v1@v1`
- **THEN** `#CustomResourceDefinition` SHALL be available and structurally identical to the upstream type

### Requirement: CRD Kubernetes transformer

The system SHALL provide a `#CRDTransformer` in the `providers/kubernetes` module that:

- Declares `#CRDsResource` as its required resource
- Iterates over the `spec.crds` map
- Emits one `CustomResourceDefinition` object per entry, validated against `#CustomResourceDefinition`
- Sets standard K8s metadata (`name`, `labels`) on each emitted object
- Is registered in the Kubernetes provider's transformer map

#### Scenario: Single CRD transforms to one CustomResourceDefinition

- **WHEN** a component with one `spec.crds` entry is processed by `#CRDTransformer`
- **THEN** the transformer output SHALL contain exactly one `CustomResourceDefinition` object with the correct `apiVersion: "apiextensions.k8s.io/v1"` and `kind: "CustomResourceDefinition"`

#### Scenario: Multiple CRDs transform to multiple CustomResourceDefinitions

- **WHEN** a component with N entries in `spec.crds` is processed
- **THEN** the transformer output SHALL contain N `CustomResourceDefinition` objects, one per entry

#### Scenario: Transformer output validates against K8s schema

- **WHEN** the transformer is evaluated via `cue vet -c -t test`
- **THEN** the output SHALL unify successfully with `#CustomResourceDefinition` without error

#### Scenario: Transformer registered in provider

- **WHEN** the Kubernetes provider is evaluated
- **THEN** `#CRDTransformer.metadata.fqn` SHALL appear as a key in the provider's `transformers` map
