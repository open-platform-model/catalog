# Transformer Test Convention

This directory uses CUE-native tests tagged with `@if(test)`. Tests run via:

```bash
# Structural tests (no concreteness requirement):
cd catalog/v1alpha2/opm
cue vet -t test ./providers/...

# All v1alpha2 tests via Taskfile:
cd catalog/
task test:v1alpha2
```

## Test File Layout

- Every `*_tests.cue` file begins with `@if(test)` on line 1
- Package matches the package under test: `package transformers`
- Test fields are hidden: `_testXxx: ...`
- Assertions use CUE unification: compute output, then unify with expected struct

## Assertion Pattern

```cue
_testMyTransformerMinimal: (#MyTransformer.#transform & {
    #component: {
        metadata: name: "my-app"
        spec: container: {
            name:  "my-app"
            image: { repository: "nginx", tag: "1.27", digest: "" }
        }
    }
    #context: (#TestCtx & {
        release:   "my-release"
        namespace: "default"
        component: "my-app"
    }).out
}).output & {
    // Assert only fields you know statically.
    // CUE unification fails if the computed value conflicts with these assertions.
    apiVersion: "apps/v1"
    kind:       "Deployment"
    metadata: {
        name:      "my-release-my-app"
        namespace: "default"
    }
}
```

## Test Context Helper

Use `#TestCtx` from `test_helpers.cue` to build a concrete `#TransformerContext`:

```cue
let _ctx = (#TestCtx & {
    release:   "my-release"   // module release name
    namespace: "default"      // target namespace
    component: "my-app"       // component name
}).out
```

## Concreteness Note

Transformer tests run without `-c` (concreteness flag) because transformer outputs
include intermediate computed fields that depend on optional trait defaults.

Tests tagged `@if(test)` that produce fully-concrete values (e.g., schema conformance
tests) can be run with `task test:v1alpha2:strict` which adds `-c`.

## Naming Conventions

| File | What it tests |
|---|---|
| `test_helpers.cue` | Shared test utilities (`#TestCtx`) |
| `deployment_transformer_tests.cue` | `#DeploymentTransformer` |
| `service_transformer_tests.cue` | `#ServiceTransformer` |
| `gateway_transformer_tests.cue` | `#GatewayTransformer` |
| `http_route_transformer_tests.cue` | `#HttpRouteTransformer` |
| `certificate_transformer_tests.cue` | `#CertificateTransformer` |

## Combinatorial Test Matrix

### Purpose

Transformer tests fall into two tiers:

| Tier | File pattern | Coverage |
|------|-------------|----------|
| **Unit tests** | `*_transformer_tests.cue` | 3–4 hand-picked representative cases per transformer |
| **Matrix tests** | `*_matrix_tests.cue` | Systematic combinations of optional fields |

Matrix tests increase confidence that each optional field is correctly propagated (or correctly absent) in every combination with other optional fields.

### Coverage Strategy

For a transformer with **N optional fields**, the full power set is **2^N** combinations. We apply the following selection strategy:

| N | 2^N | Selected |
|---|-----|----------|
| ≤3 | ≤8 | All combinations |
| 4 | 16 | All combinations |
| 5 | 32 | ≤12 (each field alone + key pairs + kitchen sink) |
| 6+ | 64+ | ≤12 (each field alone + key pairs + kitchen sink) |

The "kitchen sink" test always exercises all optional fields simultaneously.

### Matrix Files

| File | Transformer | Optional fields | Combinations |
|------|-------------|-----------------|--------------|
| `gateway_matrix_tests.cue` | `#GatewayTransformer` | hostname, tls(mode+certRef), allowedRoutes, issuerRef, addresses | 11 |
| `http_route_matrix_tests.cue` | `#HttpRouteTransformer` | gatewayRef, hostnames, path match, headers | 8 |
| `certificate_matrix_tests.cue` | `#CertificateTransformer` | dnsNames, ipAddresses, commonName, duration+renewBefore, privateKey, usages | 9 |
| `issuer_matrix_tests.cue` | `#IssuerTransformer` / `#ClusterIssuerTransformer` | acme\|ca\|selfSigned\|vault + ACME solver variants | 6 |

### Running Matrix Tests

Matrix tests use the same `@if(test)` tag as unit tests and run together:

```bash
# Run all transformer tests (unit + matrix combined)
cd catalog/v1alpha2/opm
cue vet -t test ./providers/kubernetes/transformers/...

# From the catalog/ directory
task test:v1alpha2
```

### Future: Automated Fuzzing

The matrix files cover representative combinations by hand. For exhaustive property-based testing, a future Go-based fuzzing harness would:

1. **Read** transformer definitions from the CUE module
2. **Generate** all valid permutations of optional fields using random sampling
3. **Evaluate** each permutation with `cue eval` and assert schema validity
4. **Report** which combinations produce unexpected outputs or CUE errors

A stub for this tool lives at `catalog/v1alpha2/opm/cmd/transformer-fuzz/` (planned — not yet implemented).
