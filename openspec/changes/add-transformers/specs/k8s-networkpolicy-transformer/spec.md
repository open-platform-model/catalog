## ADDED Requirements

### Requirement: NetworkPolicy transformer definition

The Kubernetes provider SHALL include a `#NetworkPolicyTransformer` that conforms to `core.#Transformer`. It SHALL declare `requiredTraits` or a matching mechanism that identifies components governed by a NetworkRules policy. Since NetworkRules is a scope-level policy and the current transformer matching is component-based, the transformer SHALL operate on component-level network rule data when available.

#### Scenario: Transformer matches component with network rules

- **WHEN** a component has network rule configuration in its spec (ingress/egress rules)
- **THEN** the `#NetworkPolicyTransformer` SHALL match

#### Scenario: Transformer does not match component without network rules

- **WHEN** a component has no network rule configuration
- **THEN** the `#NetworkPolicyTransformer` SHALL not match

### Requirement: NetworkPolicy output structure

The transformer SHALL emit a valid Kubernetes `networking.k8s.io/v1/NetworkPolicy` object. The output SHALL include `apiVersion: "networking.k8s.io/v1"`, `kind: "NetworkPolicy"`, `metadata` with name, namespace, and labels from `#TransformerContext`, and `spec` with `podSelector`, `policyTypes`, and ingress/egress rules.

#### Scenario: Ingress-only network policy

- **WHEN** a component defines network rules with ingress rules and no egress rules
- **THEN** the output SHALL be a NetworkPolicy with `spec.policyTypes: ["Ingress"]` and `spec.ingress` populated from the rule definitions

#### Scenario: Egress-only network policy

- **WHEN** a component defines network rules with egress rules and no ingress rules
- **THEN** the output SHALL be a NetworkPolicy with `spec.policyTypes: ["Egress"]` and `spec.egress` populated from the rule definitions

#### Scenario: Deny-all network policy

- **WHEN** a component defines network rules with `denyAll: true`
- **THEN** the output SHALL be a NetworkPolicy with `spec.podSelector` matching the component and empty ingress/egress arrays (denying all traffic)

#### Scenario: Pod selector uses component labels

- **WHEN** a component with network rules is transformed
- **THEN** the NetworkPolicy `spec.podSelector.matchLabels` SHALL use the component labels from `#TransformerContext.componentLabels`

### Requirement: Provider registration

The `#NetworkPolicyTransformer` SHALL be registered in the Kubernetes provider's `transformers` map with a valid FQN key.

#### Scenario: Transformer is registered

- **WHEN** the Kubernetes provider definition is evaluated
- **THEN** the `transformers` map SHALL contain an entry for the NetworkPolicy transformer

### Requirement: Test data

A test component exercising the NetworkPolicy transformer SHALL exist in the transformers test data file.

#### Scenario: Test validates without errors

- **WHEN** `task vet` is run on the providers module
- **THEN** the NetworkPolicy transformer test data SHALL validate successfully
