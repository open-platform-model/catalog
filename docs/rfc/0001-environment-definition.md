# RFC-0001: Environment Definition

| Field        | Value                              |
|--------------|------------------------------------|
| **Status**   | Draft                              |
| **Created**  | 2026-02-16                         |
| **Authors**  | OPM Contributors                   |

## Summary

Introduce `#Environment` as a reusable, first-class CUE definition for deployment targets. An environment encapsulates cluster context, target namespace, and value overrides — decoupling operational concerns from module release definitions.

`#ModuleRelease` gains an optional `#environment?` reference. When set, the environment provides the deployment namespace, injects its name into the release identity hash, and supplies value overrides that are merged by Go with environment-wins precedence. CUE validates type compatibility of environment values against the module's `#config` schema; Go handles the deep merge and renders components with the effective (merged) values.

This design is inspired by Timoni's Runtime concept but uses a separate `#Environment` definition rather than a runtime-level fan-out, keeping each `#ModuleRelease` concrete and self-contained.

## Motivation

### Current State

Today, `#ModuleRelease` has a single `namespace` field as its only form of deployment targeting:

```cue
#ModuleRelease: close({
    metadata: {         name!:      #NameType
        namespace!: string  // "target environment" per comment         // ...
    }     #module!: #Module
    values:   close(#module.#config)     // ...
})
```

This works for single-cluster, single-environment deployments. But it has concrete gaps:

1. **No cluster context.** There is no way to express which Kubernetes cluster a release targets. Teams deploying to multiple clusters must manage this externally (kubeconfig switching, CI pipeline configuration, wrapper scripts).

2. **No environment-specific value overrides.** Deploying the same module to staging and production requires creating two releases with fully duplicated `values` blocks. If the module has 20 config fields and only `replicaCount` differs between environments, the user must still copy all 20 fields into each release.

3. **No reusable environment definitions.** If 10 modules all deploy to the same staging cluster with the same namespace, each release independently hardcodes the namespace. There is no shared definition for "staging" that can be referenced across modules.

4. **No environment identity.** The release identity hash (`fqn:name:namespace`) does not include any environment concept. Labels on rendered Kubernetes resources carry no environment information, making it difficult to filter or identify resources by environment.

```text
┌───────────────────────────────────────────────────────────────────┐
│                    OPM Today                                      │
│                                                                   │
│  myapp-staging: #ModuleRelease & {                                │
│      metadata: { name: "myapp", namespace: "staging" }            │
│      values: {                                                    │
│          image: "myapp:v2"                                        │
│          replicaCount: 1     ← must hardcode                      │
│          logLevel: "debug"   ← duplicated                         │
│          dbHost: "db.stg"    ← duplicated                         │
│      }                                                            │
│  }                                                                │
│                                                                   │
│  myapp-prod: #ModuleRelease & {                                   │
│      metadata: { name: "myapp", namespace: "production" }         │
│      values: {                                                    │
│          image: "myapp:v2"                                        │
│          replicaCount: 3     ← only this differs                  │
│          logLevel: "debug"   ← duplicated                         │
│          dbHost: "db.prd"    ← duplicated                         │
│      }                                                            │
│  }                                                                │
│                                                                   │
│  No cluster targeting. No shared environment definition.          │
│  No environment labels on K8s resources.                          │
└───────────────────────────────────────────────────────────────────┘
```

### The Multi-Environment Problem

The core motivating scenario: deploying the same module to multiple environments that may coexist within the same Kubernetes cluster.

```text
┌──────────────────────────────────────────────────────────────────────┐
│  MULTI-ENVIRONMENT SCENARIO                                          │
│                                                                      │
│  Cluster: eks-us-west-2                                              │
│  ┌─────────────────────┐  ┌─────────────────────┐                    │
│  │  ns: staging         │  │  ns: production      │                   │
│  │                      │  │                      │                   │
│  │  myapp (1 replica)   │  │  myapp (3 replicas)  │                   │
│  │  debug logging       │  │  info logging        │                   │
│  │  staging DB          │  │  production DB       │                   │
│  └─────────────────────┘  └─────────────────────┘                    │
│                                                                      │
│  Same cluster. Different namespaces. Different config.               │
│  The ONLY differences are environment-specific values.               │
│                                                                      │
│  Desired:                                                            │
│  1. Define "staging" and "production" environments once               │
│  2. Each environment carries: cluster context + namespace + overlays  │
│  3. Releases reference an environment, provide base values only      │
│  4. Environment values override release values (ops wins)            │
│  5. K8s resources carry environment labels for filtering             │
│                                                                      │
│  Also works across clusters:                                         │
│  Cluster: eks-us-east-1 (production)                                 │
│  Cluster: eks-eu-west-1 (production)                                 │
│  Same environment definition, different cluster contexts.            │
└──────────────────────────────────────────────────────────────────────┘
```

Multiple environments on the same cluster is common in development and small organizations. Multiple environments across clusters is common in production fleets. The `#Environment` definition must handle both.

### Why Now

The module and release definitions are stabilizing. Adding environment support now — before a broader ecosystem of modules and releases exists — avoids a disruptive migration later. The design integrates cleanly with the existing identity model, label propagation, and transformer context.

## Prior Art

### Timoni Runtime

Timoni is the closest architectural analog to OPM — both CUE-based, CLI-driven, and module-oriented. Timoni's Runtime is a **separate CUE definition** that lives alongside bundles and provides three capabilities:

1. **Cluster targeting.** Named clusters with `group` (environment) and `kubeContext`. 2. **Runtime values.** Queries Kubernetes API at deploy time (Secrets, ConfigMaps, etc.) and injects values into the bundle.
3. **Built-in variables.** `TIMONI_CLUSTER_NAME` and `TIMONI_CLUSTER_GROUP` are automatically available in bundles.

```cue
// Timoni Runtime definition runtime: {
    apiVersion: "v1alpha1"     name:       "fleet"
    clusters: {         "preview-eu-1": {
            group:       "staging"             kubeContext: "eks-eu-west-2"
        }         "prod-eu-1": {
            group:       "production"             kubeContext: "eks-eu-west-1"
        }     }
    values: [{         query: "k8s:v1:Secret:infra:redis-auth"
        for: {             "REDIS_PASS": "obj.data.password"
        }     }]
}
```

Bundles reference runtime values via `@timoni()` CUE attributes:

```cue
bundle: {     _env: string @timoni(runtime:string:TIMONI_CLUSTER_GROUP)

    instances: {         app: {
            module: url: "oci://ghcr.io/modules/app"             namespace: "apps"
            values: {                 if _env == "staging"    { replicas: 1 }
                if _env == "production" { replicas: 3 }             }
        }     }
}
```

**Key design choices:**

- Runtime is external to the module/bundle instance — purely operational.
- Deployment is sequential by group order. Staging failure stops production.
- The `timoni bundle apply` command iterates over clusters, deploying to each.
- Runtime values are fetched from the live cluster at apply time.

**Relevance to OPM:**

- The separation of environment definition from module instance is the right   pattern. OPM adopts this.
- The runtime value query mechanism (fetching from live cluster) is out of scope   for OPM's initial design. Deferred.
- Timoni's `@timoni()` attribute injection requires CUE-level attribute support.   OPM uses Go-level value merging instead, which is simpler and gives true
override semantics.
- Timoni's group-based deployment ordering is left to the orchestrator in OPM.

### KubeVela Multi-Environment

KubeVela uses **policies** and **workflow steps** inline in the Application CRD to handle multi-cluster and multi-environment deployments:

1. **`topology` policy.** Declares destination clusters (by name or label    selector) and optional namespace override.
2. **`override` policy.** Per-environment config patches (image, replicas, traits). 3. **`deploy` workflow step.** Orchestrates which topology + override policies
   to apply and in what order. 4. **`env-binding` policy (deprecated).** The original multi-env approach that
bundled placement, patches, and component selection into one policy per    environment. Superseded by topology + override in KubeVela v1.3+.

```yaml
# KubeVela Application with multi-environment policies
apiVersion: core.oam.dev/v1beta1 kind: Application
spec:   components:
    - name: app       type: webservice
      properties:         image: nginx
  policies:     - name: topology-staging
      type: topology       properties:
        clusters: ["cluster-staging"]     - name: topology-prod
      type: topology       properties:
        clusterLabelSelector:           region: production
    - name: override-prod       type: override
      properties:         components:
          - type: webservice             traits:
              - type: scaler                 properties:
                  replicas: 3   workflow:
    steps:       - type: deploy
        name: deploy-staging         properties:
          policies: ["topology-staging"]       - type: deploy
        name: deploy-prod         properties:
          auto: false  # manual approval           policies: ["topology-prod", "override-prod"]
```

**Key design choices:**

- Everything is inline in the Application CRD. Self-contained but tightly   coupled.
- Policies can be defined externally (as standalone CRDs) and referenced by   applications.
- Override policies patch components — they do not merge values.
- Workflow steps control deployment ordering with manual approval gates.

**Relevance to OPM:**

- KubeVela's topology policy maps to OPM's `#Environment.cluster` and   `#Environment.namespace`.
- KubeVela's override policy maps to OPM's `#Environment.values` (but OPM uses   value merging, not component patching).
- KubeVela's workflow ordering is left to the orchestrator in OPM.
- KubeVela's external policy pattern validates the idea of reusable, standalone
environment definitions.

### Comparison

```text
┌──────────────────────┬──────────────────┬──────────────────┬──────────────────┐
│                      │ Timoni Runtime   │ KubeVela         │ OPM (proposed)   │
├──────────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Definition location  │ Separate file    │ Inline / external│ Separate def     │
│ Cluster targeting    │ kubeContext      │ clusterSelector  │ kubeContext       │
│ Namespace targeting  │ Per-instance     │ namespaceSelector│ On environment   │
│ Value overrides      │ CUE attributes   │ Component patch  │ Go deep merge    │
│ Override precedence  │ Runtime wins     │ Patch replaces   │ Environment wins │
│ Deployment ordering  │ Built-in (seq.)  │ Workflow steps   │ External (orch.) │
│ Runtime queries      │ K8s API queries  │ N/A              │ Deferred         │
│ Reusable across apps │ [x]              │ [x] (external)   │ [x]              │
│ CUE-native           │ [x]              │ [ ] (YAML/CRD)   │ [x]              │
│ Schema validation    │ CUE evaluation   │ CRD validation   │ CUE + Go         │
└──────────────────────┴──────────────────┴──────────────────┴──────────────────┘
```

### Why a Separate `#Environment` Definition

Both Timoni and KubeVela validate the pattern of separating environment configuration from application definition. OPM adopts this pattern with a dedicated `#Environment` type because:

1. **Reusability.** One environment definition shared across N module releases.    Changing the staging cluster context updates all modules at once.
2. **Separation of concerns.** Module authors define what the module needs    (`#config`). Operators define where and how it runs (`#Environment`).
3. **CUE-native.** Unlike Timoni's `@timoni()` attributes (which require    CLI-level injection), `#Environment` is a regular CUE struct. It participates
   in CUE evaluation, type checking, and tooling. 4. **Go merge for override semantics.** CUE unification is commutative and
cannot express "last wins." Go's deep merge gives true override semantics    that CUE alone cannot provide.

## Design

### `#Environment` Definition

A new CUE definition in `v0/core/environment.cue`:

```cue
package core

// #Environment: Defines a deployment target with cluster context, // namespace, and value overrides.
// Reusable across multiple ModuleReleases. // Value overrides are applied by Go with environment-wins precedence.
#Environment: close({
    apiVersion: "opmodel.dev/core/v0"     kind:       "Environment"

    metadata: {         name!:        #NameType   // "staging", "production", "dev"
        labels?:      #LabelsAnnotationsType         annotations?: #LabelsAnnotationsType
    }

    // Target cluster (omit to use current kubeconfig context)     cluster?: {
        kubeContext!: string   // must match a context in kubeconfig         kubeConfig?:  string  // optional path to kubeconfig file
    }

    // Default namespace for releases targeting this environment     namespace?: string

    // Value overrides — partial subset of the module's #config     // Applied by Go: effectiveValues = deepMerge(release.values, env.values)
    // CUE validates type compatibility at ModuleRelease level     values?: _
})

#EnvironmentMap: [string]: #Environment
```

**Field semantics:**

| Field                  | Required | Purpose                                                            |
|------------------------|----------|--------------------------------------------------------------------|
| `metadata.name`        | Yes      | Human-readable identifier ("staging", "production")                |
| `metadata.labels`      | No       | Labels propagated to K8s resources via transformer                 |
| `metadata.annotations` | No       | Annotations for tooling hints                                      |
| `cluster.kubeContext`  | No*      | Selects a context from kubeconfig                                  |
| `cluster.kubeConfig`   | No       | Path to kubeconfig file (defaults to `~/.kube/config`)             |
| `namespace`            | No       | Default namespace for releases in this environment                 |
| `values`               | No       | Partial value overrides (must type-check against module `#config`) |

\* If `cluster` is omitted entirely, the current kubeconfig context is used.

**Why `values?: _` (unconstrained in `#Environment`):** The environment is defined independently of any specific module. It cannot reference `#module.#config` at the definition site. Type validation happens at the `#ModuleRelease` level where both the module and environment are known (see [CUE-Level Partial Validation](#cue-level-partial-validation)).

### Updated `#ModuleRelease`

The release gains an optional `#environment?` reference. When set:

1. The environment's `namespace` provides the release namespace (if set). 2. The environment's `name` is included in the identity hash.
3. An environment label is added to the release labels. 4. CUE validates that `#environment.values` is type-compatible with
   `#module.#config`. 5. Go computes effective values by deep-merging release values with environment
values (environment wins).

Changes from current `#ModuleRelease` (additions marked with `// NEW`):

```cue
package core

import "uuid"

#ModuleRelease: close({
    apiVersion: "opmodel.dev/core/v0"     kind:       "ModuleRelease"

    metadata: {         name!:      #NameType
        namespace!: string         version:    #moduleMetadata.version

        // NEW: Identity includes environment name when set         // Backward compatible: no environment = same hash as before
        _identityInput: "\(#moduleMetadata.fqn):\(name):\(namespace)"         if #environment != _|_ {
            _identityInput:                 "\(#moduleMetadata.fqn):\(name):\(namespace):\(#environment.metadata.name)"
        }         identity: #UUIDType & uuid.SHA1(OPMNamespace, _identityInput)

        labels?: #LabelsAnnotationsType         labels: {if #moduleMetadata.labels != _|_ {#moduleMetadata.labels}} & {
            "module-release.opmodel.dev/name":    "\(name)"             "module-release.opmodel.dev/version": "\(version)"
            "module-release.opmodel.dev/uuid":    "\(identity)"             // NEW: environment label when set
            if #environment != _|_ {                 "module-release.opmodel.dev/environment": "\(#environment.metadata.name)"
            }         }
        annotations?: #LabelsAnnotationsType         annotations: {if #moduleMetadata.annotations != _|_ {#moduleMetadata.annotations}}
    }

    #module!:        #Module     #moduleMetadata: #module.metadata

    // NEW: optional environment reference     #environment?: #Environment

    // NEW: if environment provides namespace, use it     if #environment != _|_ if #environment.namespace != _|_ {
        metadata: namespace: #environment.namespace     }

    // NEW: CUE-level partial validation of environment values     // Ensures type compatibility with module config (see design section)
    if #environment != _|_ if #environment.values != _|_ {         _envValuesTypeCheck: #module.#config & #environment.values
    }

    // Base values (developer intent)     // Go computes: effectiveValues = deepMerge(values, env.values)
    // Go validates: effectiveValues against #module.#config     // Go renders: components with effectiveValues
    _#module: #module & {#config: values}     components: _#module.#components

    policies?: [Id=string]: #Policy     if _#module.#policies != _|_ {
        policies: _#module.#policies     }

    values: close(#module.#config) })

#ModuleReleaseMap: [string]: #ModuleRelease
```

### Identity Hash

The identity hash determines the UUID for a module release. The current formula is `SHA1(fqn:name:namespace)`. With environments, the formula becomes:

```text
┌──────────────────────────────────────────────────────────────────────┐
│  IDENTITY HASH                                                       │
│                                                                      │
│  Without environment (backward compatible):                          │
│    identity = UUIDv5(OPMNamespace, "fqn:name:namespace")             │
│    Example:  UUIDv5(ns, "opmodel.dev/m@v0#App:myapp:default")       │
│                                                                      │
│  With environment:                                                   │
│    identity = UUIDv5(OPMNamespace, "fqn:name:namespace:envName")     │
│    Example:  UUIDv5(ns, "opmodel.dev/m@v0#App:myapp:staging:stg")   │
│                                                                      │
│  The environment name is appended after the namespace, separated     │
│  by a colon. When no environment is set, the hash is identical       │
│  to the current formula — no breaking change.                        │
│                                                                      │
│  This means:                                                         │
│  • Two releases with same name+namespace but different envs          │
│    have different identities (correct).                              │
│  • A release without an environment has the same identity as         │
│    today (backward compatible).                                      │
└──────────────────────────────────────────────────────────────────────┘
```

### CUE-Level Partial Validation

Environment values must be type-compatible with the module's `#config` schema. Since `#Environment` is defined independently of any module, validation happens at the `#ModuleRelease` level where both are known:

```cue
// In #ModuleRelease: if #environment != _|_ if #environment.values != _|_ {
    _envValuesTypeCheck: #module.#config & #environment.values }
```

This catches type mismatches at CUE evaluation time:

```text
┌──────────────────────────────────────────────────────────────────────┐
│  CUE PARTIAL VALIDATION                                              │
│                                                                      │
│  Module #config:                                                     │
│    replicaCount: int                                                 │
│    image:        string                                              │
│    logLevel:     "debug" | "info" | "warn" | "error"                 │
│                                                                      │
│  Environment values:                                                 │
│    replicaCount: 3          ← int & 3 = 3            OK             │
│    replicaCount: "three"    ← int & "three" = _|_    CUE ERROR      │
│    logLevel: "verbose"      ← disjunction miss       CUE ERROR      │
│    bogusField: true         ← not in #config*        UNDETECTED      │
│                                                                      │
│  *Unknown fields are caught by Go after merge, not by CUE.          │
│   CUE's unification adds extra fields to open structs silently.     │
│   Go validates the merged result against close(#module.#config)     │
│   which rejects unknown fields.                                      │
│                                                                      │
│  Summary:                                                            │
│  • CUE catches: type mismatches, constraint violations               │
│  • Go catches: unknown fields, completeness after merge              │
└──────────────────────────────────────────────────────────────────────┘
```

This two-layer validation (CUE for types, Go for completeness) is intentional. CUE's type system catches the most common errors early — during `cue vet` or editor feedback — while Go handles the merge-dependent validations that CUE cannot express.

### Go Merge Pipeline

The Go merge pipeline runs after CUE evaluation and before component rendering. It implements environment-wins value merging:

```text
┌──────────────────────────────────────────────────────────────────────┐
│  GO MERGE PIPELINE                                                   │
│                                                                      │
│  ┌───────────────┐     ┌────────────────┐                            │
│  │ ModuleRelease │     │  Environment   │                            │
│  │   .values     │     │    .values     │                            │
│  │  (base)       │     │  (overrides)   │                            │
│  └───────┬───────┘     └───────┬────────┘                            │
│          │                     │                                     │
│          └──────────┬──────────┘                                     │
│                     │                                                │
│               deepMerge()           ← Go: environment values win     │
│                     │                                                │
│          ┌──────────▼──────────┐                                     │
│          │  effectiveValues    │                                     │
│          └──────────┬──────────┘                                     │
│                     │                                                │
│          validate against            ← Go: CUE eval of              │
│          close(#module.#config)         close(#module.#config)       │
│                     │                                                │
│          render components           ← Go: re-evaluate module       │
│          with effectiveValues           with effective values        │
│                     │                                                │
│          inject into                 ← Go: populate                  │
│          #TransformerContext            #environmentMetadata         │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**Deep merge rules:**

1. **Scalar fields:** Environment value replaces release value. 2. **Struct fields:** Recursively merge. Environment fields override release
   fields at each level. 3. **Missing fields:** If a field exists in the release but not in the
environment, the release value is kept. If a field exists in the environment    but not in the release, the environment value is added.
4. **Validation:** After merge, the effective values are validated against    `close(#module.#config)` via CUE evaluation. This catches unknown fields
   introduced by the environment and ensures all required fields are present.

**Why Go, not CUE:** CUE unification is commutative — `{a: 1} & {a: 2}` is an error, not `2`. There is no "last wins" in CUE. True override semantics require imperative merge logic. Go's `deepMerge` function provides this naturally, while CUE continues to serve its strength: schema validation.

### Updated `#TransformerContext`

The transformer context carries environment metadata into each transformer during rendering. This enables transformers to generate environment-aware Kubernetes resources (labels, annotations).

Changes from current `#TransformerContext` (additions marked with `// NEW`):

```cue
#TransformerContext: {
    #moduleReleaseMetadata: {         name!:        #NameType
        namespace!:   #NameType         fqn:          string
        version:      string         identity:     #UUIDType
        labels?:      #LabelsAnnotationsType         annotations?: #LabelsAnnotationsType
    }

    // NEW: environment metadata (optional, absent when no environment)     #environmentMetadata?: {
        name!:        #NameType         labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType     }

    #componentMetadata: {         name!:        #NameType
        labels?:      #LabelsAnnotationsType         annotations?: #LabelsAnnotationsType
    }

    name:      string // Injected during rendering (release name)     namespace: string // Injected during rendering (target namespace)

    // Existing computed labels (unchanged)     moduleLabels: {
        if #moduleReleaseMetadata.labels != _|_ {             for k, v in #moduleReleaseMetadata.labels {
                (k): "\(v)"             }
        }     }

    moduleAnnotations: {         if #moduleReleaseMetadata.annotations != _|_ {
            for k, v in #moduleReleaseMetadata.annotations {                 (k): "\(v)"
            }         }
    }

    componentLabels: {         "app.kubernetes.io/name": #componentMetadata.name
        if #componentMetadata.labels != _|_ {             for k, v in #componentMetadata.labels {
                if !strings.HasPrefix(k, "transformer.opmodel.dev/") {                     (k): "\(v)"
                }             }
        }     }

    componentAnnotations: {         if #componentMetadata.annotations != _|_ {
            for k, v in #componentMetadata.annotations {                 if !strings.HasPrefix(k, "transformer.opmodel.dev/") {
                    (k): "\(v)"                 }
            }         }
    }

    controllerLabels: {         "app.kubernetes.io/managed-by": "open-platform-model"
        "app.kubernetes.io/name":       #componentMetadata.name         "app.kubernetes.io/instance":   #componentMetadata.name
        "app.kubernetes.io/version":    #moduleReleaseMetadata.version     }

    // NEW: environment labels     environmentLabels: {
        if #environmentMetadata != _|_ {             "environment.opmodel.dev/name": #environmentMetadata.name
            if #environmentMetadata.labels != _|_ {                 for k, v in #environmentMetadata.labels {
                    (k): "\(v)"                 }
            }         }
    }

    // NEW: environment annotations     environmentAnnotations: {
        if #environmentMetadata != _|_ {             if #environmentMetadata.annotations != _|_ {
                for k, v in #environmentMetadata.annotations {                     (k): "\(v)"
                }             }
        }     }

    // Updated: labels now include environment labels     labels: {[string]: string}
    labels: {         for k, v in moduleLabels {
            (k): "\(v)"         }
        for k, v in componentLabels {             (k): "\(v)"
        }         for k, v in controllerLabels {
            (k): "\(v)"         }
        for k, v in environmentLabels {   // NEW             (k): "\(v)"
        }         ...
    }

    // Updated: annotations now include environment annotations     annotations: {[string]: string}
    annotations: {         for k, v in moduleAnnotations {
            (k): "\(v)"         }
        for k, v in componentAnnotations {             (k): "\(v)"
        }         for k, v in environmentAnnotations {   // NEW
            (k): "\(v)"         }
        ...     }
}
```

When a release has an environment, the Go rendering pipeline populates `#environmentMetadata` from `#environment.metadata`. When no environment is set, `#environmentMetadata` is absent, and `environmentLabels` evaluates to an empty struct — no change to rendered output.

### Label Propagation

With an environment set, Kubernetes resources receive an additional label:

```text
┌──────────────────────────────────────────────────────────────────────┐
│  LABEL PROPAGATION                                                   │
│                                                                      │
│  Without environment:                                                │
│    labels:                                                           │
│      app.kubernetes.io/managed-by: open-platform-model               │
│      app.kubernetes.io/name: myapp                                   │
│      app.kubernetes.io/instance: myapp                               │
│      app.kubernetes.io/version: 0.1.0                                │
│      module-release.opmodel.dev/name: myapp                          │
│      module-release.opmodel.dev/version: 0.1.0                       │
│      module-release.opmodel.dev/uuid: <uuid>                         │
│                                                                      │
│  With environment "production":                                      │
│    labels:                                                           │
│      ... (all of the above) ...                                      │
│      module-release.opmodel.dev/environment: production    ← NEW     │
│      environment.opmodel.dev/name: production              ← NEW     │
│                                                                      │
│  The module-release label is on the release metadata (for release     │
│  identification). The environment.opmodel.dev label is on rendered    │
│  K8s resources (for environment-based filtering via kubectl).        │
│                                                                      │
│  kubectl get pods -l environment.opmodel.dev/name=production         │
└──────────────────────────────────────────────────────────────────────┘
```

## Scenarios

### Scenario A: Basic Environment with Cluster and Namespace

```text
Environment:   staging: #Environment & {
      metadata: name: "staging"       cluster: kubeContext: "eks-us-west-2-staging"
      namespace: "staging"   }

Release:   myapp: #ModuleRelease & {
      metadata: name: "myapp"       // namespace comes from staging.namespace = "staging"
      #module:      myModule       #environment: staging
      values: { image: "myapp:v2", replicaCount: 1 }   }

Result:   metadata.namespace: "staging"
  metadata.identity:  UUIDv5(ns, "fqn:myapp:staging:staging")   labels include: environment.opmodel.dev/name: "staging"
  Cluster context: eks-us-west-2-staging

[x]
```

### Scenario B: Same Cluster, Different Environments

```text
Environments:   staging: #Environment & {
      metadata: name: "staging"       cluster: kubeContext: "eks-us-west-2"    // same cluster
      namespace: "staging"       values: { replicaCount: 1, logLevel: "debug" }
  }

  production: #Environment & {       metadata: name: "production"
      cluster: kubeContext: "eks-us-west-2"    // same cluster       namespace: "production"
      values: { replicaCount: 3, logLevel: "info" }   }

Releases:   myappStg: #ModuleRelease & {
      metadata: name: "myapp"       #module: myModule
      #environment: staging       values: { image: "myapp:v2" }
  }

  myappProd: #ModuleRelease & {       metadata: name: "myapp"
      #module: myModule       #environment: production
      values: { image: "myapp:v2" }   }

Go merge results:   myappStg effective:  { image: "myapp:v2", replicaCount: 1, logLevel: "debug" }
  myappProd effective: { image: "myapp:v2", replicaCount: 3, logLevel: "info" }

Identities differ (different env name in hash):   myappStg.identity  = UUIDv5(ns, "fqn:myapp:staging:staging")
  myappProd.identity = UUIDv5(ns, "fqn:myapp:production:production")

Same cluster, different namespaces, different effective values. [x]
```

### Scenario C: No Environment — Backward Compatible

```text
Release (no #environment):   myapp: #ModuleRelease & {
      metadata: { name: "myapp", namespace: "default" }       #module: myModule
      values: { image: "myapp:v2", replicaCount: 1 }   }

Result:   metadata.namespace: "default"
  metadata.identity:  UUIDv5(ns, "fqn:myapp:default")   // same as today   No environment labels on rendered resources.
  No Go merge needed — values used as-is.   _envValuesTypeCheck: not evaluated (guarded by if).

Identical behavior to current OPM. [x]
```

### Scenario D: Environment Value Override — Environment Wins

```text
Module:   #config: {
      image!:        string       replicaCount:  *1 | int
      logLevel:      *"info" | "debug" | "warn" | "error"   }

Release:   values: {
      image:        "myapp:v2"       replicaCount: 2          // developer wants 2
      logLevel:     "debug"    // developer wants debug   }

Environment:   values: {
      replicaCount: 5          // ops overrides to 5   }

Go deepMerge (env wins):   effective: {
      image:        "myapp:v2"    // from release (env doesn't set it)       replicaCount: 5             // from environment (overrides release's 2)
      logLevel:     "debug"       // from release (env doesn't set it)   }

Go validates effective against close(#module.#config): OK

Environment wins for replicaCount. Release values kept for unoverridden fields. [x]
```

### Scenario E: CUE Type-Check Catches Invalid Environment Values

```text
Module:   #config: {
      replicaCount: int       logLevel:     "debug" | "info" | "warn" | "error"
  }

Environment:   values: {
      replicaCount: "three"     // string, not int   }

CUE evaluation of _envValuesTypeCheck:   #module.#config & #environment.values
  = { replicaCount: int, logLevel: ... } & { replicaCount: "three" }   = _|_  (int & "three" is bottom)

Result: CUE error during evaluation. Caught before Go merge runs.

  error: #ModuleRelease._envValuesTypeCheck.replicaCount:     conflicting values int and "three"

[x]
```

### Scenario F: Multiple Modules Sharing Same Environment

```text
Environment:   staging: #Environment & {
      metadata: name: "staging"       cluster: kubeContext: "eks-staging"
      namespace: "staging"       values: { replicaCount: 1 }
  }

Releases:   frontend: #ModuleRelease & {
      metadata: name: "frontend"       #module: frontendModule
      #environment: staging       values: { image: "frontend:v3", port: 3000 }
  }

  backend: #ModuleRelease & {       metadata: name: "backend"
      #module: backendModule       #environment: staging
      values: { image: "backend:v2", port: 8080 }   }

Both releases:   - Share the same cluster context and namespace.
  - Both get replicaCount: 1 from the environment.   - Both carry environment.opmodel.dev/name: "staging" label.
  - Different identities (different module FQNs and release names).

Change staging cluster context once → all modules updated. [x]
```

### Scenario G: Environment Without Namespace — Release Provides It

```text
Environment:   production: #Environment & {
      metadata: name: "production"       cluster: kubeContext: "eks-prod"
      // No namespace — each release decides its own       values: { replicaCount: 3 }
  }

Release:   myapp: #ModuleRelease & {
      metadata: { name: "myapp", namespace: "myapp-prod" }       #module: myModule
      #environment: production       values: { image: "myapp:v2" }
  }

Result:   metadata.namespace: "myapp-prod"   // from release (env has no namespace)
  Cluster context: eks-prod          // from environment   Effective values include replicaCount: 3 from environment.

Environment provides cluster + values. Release provides namespace. [x]
```

### Scenario H: Environment Namespace Fills Release Namespace

```text
Environment:   staging: #Environment & {
      metadata: name: "staging"       namespace: "staging-ns"
  }

Release:   myapp: #ModuleRelease & {
      metadata: name: "myapp"       // namespace not explicitly set — environment fills it
      #module: myModule       #environment: staging
      values: { image: "myapp:v2" }   }

CUE evaluation:   The conditional `if #environment.namespace != _|_` fires.
  metadata: namespace: "staging-ns"

Result:   metadata.namespace: "staging-ns"   // from environment
  metadata.identity: UUIDv5(ns, "fqn:myapp:staging-ns:staging")

[x]
```

## Open Questions

### Q1: Runtime Value Queries from Cluster State

Timoni Runtime supports querying live Kubernetes resources (Secrets, ConfigMaps, CRDs) at apply time and injecting their values into the bundle. Should `#Environment` support a similar mechanism?

**Current position:** Deferred. The initial design focuses on static environment definitions. Runtime queries add significant complexity (cluster connectivity during evaluation, error handling for missing resources, optional vs required queries). They can be added as a future extension without breaking the current schema.

### Q2: Should `#BundleRelease` Support Environments?

`#BundleRelease` currently has no namespace and no environment concept. Bundles contain multiple modules, each potentially targeting different environments.

**Current position:** Deferred. Start with `#ModuleRelease` only. If bundles need environment support, it could be added at the bundle level (one environment for the entire bundle) or per-module within the bundle. The per-module approach is more flexible but more complex.

### Q3: Environment Inheritance

Should environments support inheritance? For example, a "base-production" environment with common settings, and regional variants that extend it:

```cue
baseProd: #Environment & {     values: { replicaCount: 3, logLevel: "info" }
}

prodEU: #Environment & {     baseProd
    metadata: name: "prod-eu"     cluster: kubeContext: "eks-eu-west-1"
    namespace: "production"     values: { region: "eu-west-1" }   // How to merge with baseProd values?
}
```

**Current position:** Deferred. CUE's native struct embedding already provides a form of composition for the non-values fields. Value inheritance hits the same "last wins" limitation that motivates Go merge for release + environment. Environment-to-environment inheritance would require a separate merge pass, adding complexity. Users can achieve similar results with CUE helper definitions or explicit value spreading.

### Q4: Environment Groups

Timoni's Runtime uses `group` to categorize clusters into environments (e.g., all "production" clusters). Should `#Environment` support a `group` field for similar categorization?

**Current position:** Not needed in the initial design. OPM delegates deployment ordering to the orchestrator and does not need to group environments for sequential rollout. If grouping becomes useful for tooling or reporting, it can be added as an optional metadata field without schema changes.

## Deferred Work

### BundleRelease Environment Support

Extend `#BundleRelease` with an optional `#environment?` reference, mirroring the `#ModuleRelease` extension. Design considerations: should the bundle-level environment apply to all modules, or should each module within the bundle have its own environment?

### Runtime Value Queries

Add a `values` array to `#Environment` (or a separate `#Runtime` definition) that queries live Kubernetes resources and injects their values. This would bring OPM closer to Timoni's Runtime model. Key design questions: query syntax, error handling for missing resources, caching, and security implications of reading arbitrary cluster state.

### Deployment Ordering and Rollout Strategy

Define how environments are ordered during multi-environment deployments (e.g., staging before production, canary before full rollout). This is explicitly left to the orchestrator in the current design. If OPM gains a built-in apply pipeline, ordering could be expressed as a separate `#DeploymentPlan` or `#Rollout` definition.

### CLI Integration

The OPM CLI (`opm`) will need updates to support environments:

- `opm mod apply --environment <name>`: Select which environment to use.
- `opm mod build --environment <name>`: Build with effective (merged) values.
- `opm mod diff --environment <name>`: Diff against the cluster specified by the   environment's kubeContext.
- Environment-aware kubeconfig context switching.

## References

- [Timoni Bundle Runtime](https://timoni.sh/bundle-runtime/) — Runtime   definition, cluster targeting, runtime value queries
- [Timoni Multi-cluster Deployments](https://timoni.sh/bundle-multi-cluster/) —   Multi-cluster operations with Runtime
- [KubeVela Multi-Environment](https://kubevela.io/docs/end-user/policies/envbinding/) —   env-binding policy for multi-environment deployments
- [KubeVela Multi-Cluster Application](https://kubevela.io/docs/case-studies/multi-cluster/) —   topology and override policies for multi-cluster
- OPM `#ModuleRelease` — `v0/core/module_release.cue`
- OPM `#TransformerContext` — `v0/core/transformer.cue`
- OPM `#Module` — `v0/core/module.cue`
