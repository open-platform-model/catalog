# Testing in the OPM Catalog

This document explains how tests work in the OPM catalog, how to run them, and how to write new ones. The catalog uses CUE's native build tag system — there is no separate test runner or test framework. Tests are CUE files that are gated behind a build tag and evaluated via `cue vet`.

## How it works

CUE's `@if(test)` build tag gates test files out of normal evaluation. When you run `cue vet` without any tags, test files are invisible — they are not loaded, evaluated, or type-checked. When you pass `-t test`, CUE includes those files and evaluates every field in the package, including the hidden `_testXxx` fields defined in your test files.

**The assertion mechanism is unification.** There is no `assert()` function or matcher library. If you write:

```cue
_testMyCase: (#MyTransformer.#transform & {
    #component: { ... }
    #context:   someCtx
}).output & {
    apiVersion: "apps/v1"
    kind:       "Deployment"
}
```

CUE unifies the actual output with the expected fragment. If they are compatible, the test passes silently. If they conflict — for example, the actual `kind` is `"StatefulSet"` but you expected `"Deployment"` — CUE raises a type conflict error, and `cue vet` exits non-zero. The test harness is the type system itself.

## Test layers

The catalog uses two test layers depending on context.

### Layer 1 — CUE tests (`*_tests.cue` files)

Used for transformer tests and schema/resource definition tests. These files are tagged with `@if(test)` and contain hidden fields that assert on transformer output or definition structure.

### Layer 2 — Data fixture tests (`testdata/`)

Used in `v1alpha1/` for validating YAML/JSON examples against CUE definitions. These files do not use the `@if(test)` tag; they are validated by running `cue vet -d '#Definition'` against individual fixture files.

Fixture naming conventions:

- `*_valid_*.yaml` or `*_valid_*.json` — must pass validation
- `*_invalid_*.yaml` or `*_invalid_*.json` — must fail validation

## File naming conventions

| File | Purpose |
|---|---|
| `test_helpers.cue` | Shared test utilities; no `@if(test)` tag required |
| `{name}_transformer_tests.cue` | Unit tests for a single transformer (3–4 representative cases) |
| `{name}_matrix_tests.cue` | Combinatorial tests covering optional field combinations (8–12 cases) |
| `{name}_tests.cue` | Schema or resource definition tests (v1alpha1 pattern) |

## The `#TestCtx` helper

Every transformer package that contains tests includes a `test_helpers.cue` file with a `#TestCtx` helper. This helper synthesizes a minimal, concrete `#TransformerContext` so that tests do not need to construct one from scratch.

```cue
// test_helpers.cue
package transformers

#TestCtx: {
    release:   string
    namespace: string
    component: string
    out: #TransformerContext & {
        releaseId:    "00000000-0000-0000-0000-000000000000"
        releaseName:  release
        namespace:    namespace
        componentFqn: release + "." + namespace + "." + component
    }
}
```

Key properties of `#TestCtx`:

- Uses the RFC 4122 nil UUID (`00000000-0000-0000-0000-000000000000`) for `releaseId`. This makes test output deterministic — no random UUIDs to deal with.
- Constructs `componentFqn` by joining `release`, `namespace`, and `component` with dots.
- Returns a concrete `#TransformerContext` via the `.out` field.

Usage in a test:

```cue
let _ctx = (#TestCtx & {
    release:   "myapp"
    namespace: "default"
    component: "web"
}).out
```

If your transformer package is in a new provider module, copy `test_helpers.cue` verbatim from an existing transformer package. The file is identical across all provider modules.

## Writing a unit test

Unit tests live in `{name}_transformer_tests.cue` and cover 3–4 representative cases: the minimal valid input, one or two meaningful optional field combinations, and any edge cases that are specific to the transformer.

### File structure

Every test file must start with the `@if(test)` tag on its first line, followed by the package declaration.

```cue
@if(test)

package transformers

import (
    // import the transformer definition under test if needed
)
```

### Assertion pattern

Test fields are hidden (prefixed with `_`) so they do not appear in normal evaluation output.

```cue
_testMinimalDeployment: (#DeploymentTransformer.#transform & {
    #component: {
        name: "web"
        spec: {
            image:    "nginx:latest"
            replicas: 1
        }
    }
    #context: (#TestCtx & {
        release:   "myapp"
        namespace: "default"
        component: "web"
    }).out
}).output & {
    apiVersion: "apps/v1"
    kind:       "Deployment"
    metadata: {
        name:      "myapp-web"
        namespace: "default"
    }
    spec: replicas: 1
}
```

The right-hand side of `& { ... }` is the expected fragment. You only need to assert on the fields you care about — unification is structural and partial. Fields in the actual output that you do not mention in the expected fragment are ignored.

### Naming convention

Name each test field `_test` followed by a description in camelCase: `_testMinimal`, `_testExplicitReplicas`, `_testWithEnvVars`, `_testTlsListener`. The `_` prefix ensures the field is hidden at runtime.

## Writing a matrix test

Matrix tests live in `{name}_matrix_tests.cue` and provide exhaustive coverage of optional field combinations. The goal is to catch regressions when optional fields interact — for example, a transformer that behaves differently when both `tls` and `issuerRef` are set simultaneously.

A matrix test defines a base component and then varies one field at a time across 8–12 assertions. The pattern uses `let` bindings to avoid repetition.

```cue
@if(test)

package transformers

let _base = {
    name: "gw"
    spec: gatewayClassName: "istio"
    spec: listeners: [{
        name:     "http"
        port:     80
        protocol: "HTTP"
    }]
}

let _ctx = (#TestCtx & {
    release:   "myapp"
    namespace: "default"
    component: "gw"
}).out

// Minimal: no optional fields
_matrixMinimal: (#GatewayTransformer.#transform & {
    #component: _base
    #context:   _ctx
}).output & {
    kind: "Gateway"
}

// With TLS listener
_matrixWithTls: (#GatewayTransformer.#transform & {
    #component: _base & {spec: listeners: [{
        name:     "https"
        port:     443
        protocol: "HTTPS"
        tls: mode: "Terminate"
    }]}
    #context: _ctx
}).output & {
    spec: listeners: [{tls: mode: "Terminate"}]
}

// With issuerRef annotation
_matrixWithIssuerRef: (#GatewayTransformer.#transform & {
    #component: _base & {spec: issuerRef: {name: "letsencrypt", kind: "ClusterIssuer"}}
    #context:   _ctx
}).output & {
    metadata: annotations: "cert-manager.io/cluster-issuer": "letsencrypt"
}
```

## Running tests

### Using Task (preferred)

From the `catalog/` directory:

```bash
# Run all v1alpha2 tests
task test:v1alpha2

# Run all v1alpha2 tests with concreteness checks
task test:v1alpha2:strict

# Run v1alpha1 schema/resource/fixture tests
task check
```

### Using raw `cue` commands

From the module root (e.g., `catalog/v1alpha2/opm/`):

```bash
# Run all transformer tests in the OPM module
cue vet -t test ./providers/kubernetes/transformers/...

# Run with concreteness checks (confirms all output fields are concrete values)
cue vet -c -t test ./providers/kubernetes/transformers/...

# Run tests in a provider module
cd modules/gateway_api
cue vet -t test ./providers/kubernetes/transformers/...

cd catalog/v1alpha2/cert_manager
cue vet -t test ./providers/kubernetes/transformers/...
```

### Targeting a single package

If you want to test only one transformer without running the entire directory tree, target the package path directly:

```bash
cd catalog/v1alpha2/opm
cue vet -t test ./providers/kubernetes/transformers/
```

CUE evaluates all files in the package together, so this runs all test files in that directory in one pass.

## Copy-paste templates

### Unit test file skeleton

```cue
@if(test)

package transformers

_testMinimal: (#FooTransformer.#transform & {
    #component: {
        name: "my-foo"
        spec: {
            // required fields only
        }
    }
    #context: (#TestCtx & {
        release:   "myapp"
        namespace: "default"
        component: "my-foo"
    }).out
}).output & {
    // assert on key output fields
    apiVersion: "example.io/v1"
    kind:       "Foo"
    metadata: name: "myapp-my-foo"
}

_testWithOptionalField: (#FooTransformer.#transform & {
    #component: {
        name: "my-foo"
        spec: {
            // required + one optional field
        }
    }
    #context: (#TestCtx & {
        release:   "myapp"
        namespace: "default"
        component: "my-foo"
    }).out
}).output & {
    // assert on output that reflects the optional field
}
```

### Matrix test file skeleton

```cue
@if(test)

package transformers

let _base = {
    name: "my-foo"
    spec: {
        // required fields with concrete defaults
    }
}

let _ctx = (#TestCtx & {
    release:   "myapp"
    namespace: "default"
    component: "my-foo"
}).out

_matrixMinimal: (#FooTransformer.#transform & {
    #component: _base
    #context:   _ctx
}).output & {
    kind: "Foo"
}

_matrixWithFieldA: (#FooTransformer.#transform & {
    #component: _base & {spec: fieldA: "value"}
    #context:   _ctx
}).output & {
    spec: someOutput: "value"
}

_matrixWithFieldB: (#FooTransformer.#transform & {
    #component: _base & {spec: fieldB: true}
    #context:   _ctx
}).output & {
    metadata: annotations: "example.io/b": "true"
}
```

## Relationship to the existing `TESTING.md`

A shorter reference document also exists at `catalog/v1alpha2/opm/providers/kubernetes/transformers/TESTING.md`. That file is a transformer-specific quick reference for contributors working directly inside the OPM provider. This document is the authoritative top-level guide covering all test tiers and all modules.
