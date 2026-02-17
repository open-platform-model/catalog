# RFC-0001: Environment Definition

| Field        | Value                              |
|--------------|------------------------------------|
| **Status**   | Draft                              |
| **Created**  | 2026-02-16                         |
| **Authors**  | OPM Contributors                   |

## Summary

Introduce a two-layer architecture for deployment targeting:

1. **`#Platform`** — defines physical cluster connection info (kubeContext, kubeConfig) and platform context (well-known fields like defaultDomain, defaultStorageClass, capabilities). Lives in `.opm/platform.cue`.
2. **`#Environment`** — binds a platform to a namespace and value overrides. Lives on `#ModuleRelease.environments` map.

Users define named platforms once (the shared infrastructure with its capabilities), then design per-release environment topologies by mapping platforms to namespaces and value overrides. Different modules can slice the same set of platforms in different ways — one module might have staging/production, another might have dev/staging/prod-us/prod-eu.

The CLI selects an environment via `-e <name>` (required when a release has environments). CUE validates type compatibility of environment values against the module's `#config` schema; Go handles the deep merge and renders components with the effective (merged) values.

This design separates infrastructure targeting (WHERE — platforms) from deployment topology (HOW — environments), inspired by Timoni's Runtime concept but giving users full control over topology definition per release. Platform context provides well-known fields (like `defaultDomain`) that module authors can reference, with concrete values populated at deploy time.

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
│  │  ns: staging        │  │  ns: production      │                   │
│  │                     │  │                      │                   │
│  │  myapp (1 replica)  │  │  myapp (3 replicas)  │                   │
│  │  debug logging      │  │  info logging        │                   │
│  │  staging DB         │  │  production DB       │                   │
│  └─────────────────────┘  └─────────────────────┘                    │
│                                                                      │
│  Same cluster. Different namespaces. Different config.               │
│  The ONLY differences are environment-specific values.               │
│                                                                      │
│  Desired:                                                            │
│  1. Define "staging" and "production" environments once              │
│  2. Each environment carries: cluster context + namespace + overlays │
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

- The separation of infrastructure targeting from application deployment is the right pattern. OPM adopts this with `#Platform` (where clusters live + their capabilities) and `#Environment` (how to deploy).
- OPM diverges by putting environment topology **on the release**, not in a global Runtime/Platform file. This gives per-module topology freedom.
- The runtime value query mechanism (fetching from live cluster) is out of scope for OPM's initial design. Deferred to Platform Context Queries (future RFC).
- Timoni's `@timoni()` attribute injection requires CUE-level attribute support. OPM uses Go-level value merging instead, which is simpler and gives true override semantics.
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

- KubeVela's topology policy maps to OPM's `#Platform` and `#Environment.namespace`.
- KubeVela's override policy maps to OPM's `#Environment.values` (but OPM uses value merging, not component patching).
- KubeVela's workflow ordering is left to the orchestrator in OPM.
- KubeVela's external policy pattern validates the idea of reusable definitions, which OPM applies to `#Platform`.

### Comparison

```text
┌──────────────────────┬──────────────────┬──────────────────┬──────────────────┐
│                      │ Timoni Runtime   │ KubeVela         │ OPM (proposed)   │
├──────────────────────┼──────────────────┼──────────────────┼──────────────────┤
│ Definition location  │ Separate file    │ Inline / external│ Two-layer:       │
│                      │                  │                  │ platform + env   │
│ Cluster targeting    │ kubeContext      │ clusterSelector  │ Platform         │
│ Namespace targeting  │ Per-instance     │ namespaceSelector│ On environment   │
│ Platform context     │ Runtime vars     │ N/A              │ PlatformContext  │
│ Topology design      │ External (global)│ External (global)│ Per-release map  │
│ Value overrides      │ CUE attributes   │ Component patch  │ Go deep merge    │
│ Override precedence  │ Runtime wins     │ Patch replaces   │ Environment wins │
│ Deployment ordering  │ Built-in (seq.)  │ Workflow steps   │ External (orch.) │
│ Context queries      │ K8s API queries  │ N/A              │ Deferred         │
│ Reusable across apps │ [x]              │ [x] (external)   │ [x] (platforms)  │
│ Per-app topology     │ [ ]              │ [ ]              │ [x] (envs map)   │
│ CUE-native           │ [x]              │ [ ] (YAML/CRD)   │ [x]              │
│ Schema validation    │ CUE evaluation   │ CRD validation   │ CUE + Go         │
└──────────────────────┴──────────────────┴──────────────────┴──────────────────┘
```

### Why Platform + Environment Two-Layer Architecture

Both Timoni and KubeVela validate the pattern of separating infrastructure targeting from application definition. OPM adopts this pattern with a two-layer architecture (`#Platform` + `#Environment`) because:

1. **Reusability at the infrastructure layer.** `#Platform` definitions are shared across all modules. Changing a platform's kubeContext or context fields updates all modules that reference it.
2. **Platform capabilities as first-class values.** `#PlatformContext` provides well-known fields (defaultDomain, defaultStorageClass, capabilities) that module authors can reference. Shapes are known at authoring time, values are concrete at deploy time.
3. **Topology freedom at the release layer.** Each `#ModuleRelease` defines its own environment map. One module might have staging/production, another might have dev/staging/prod-us/prod-eu. No global environment registry forces a single topology on all modules.
4. **Separation of concerns.** Module authors define what the module needs (`#config`) and can reference well-known platform context. Platform operators define where infrastructure lives and what it provides (`#Platform`). Release authors design the deployment topology (`environments` map on `#ModuleRelease`).
5. **CUE-native.** Unlike Timoni's `@timoni()` attributes (which require CLI-level injection), both `#Platform` and `#Environment` are regular CUE structs. They participate in CUE evaluation, type checking, and tooling.
6. **Go merge for override semantics.** CUE unification is commutative and cannot express "last wins." Go's deep merge gives true override semantics that CUE alone cannot provide.

## Design

### `#Platform` Definition

A new CUE definition in `v0/core/platform.cue` representing a deployment target with cluster connection info and platform capabilities:

```cue
package core

// #Platform: Defines how to connect to a Kubernetes cluster and what
// capabilities/context the platform provides.
// Stored in .opm/platform.cue and referenced by #Environment definitions.
// Separates infrastructure targeting (WHERE) from deployment topology (HOW).
#Platform: close({
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Platform"

    // Kubernetes context name (must match a context in kubeconfig)
    kubeContext!: string

    // Optional path to kubeconfig file (defaults to ~/.kube/config or $KUBECONFIG)
    kubeConfig?: string

    // Platform context — well-known fields that module authors can reference.
    // Values are concrete for this platform, shapes are known at authoring time.
    context?: #PlatformContext
})
```

**Field semantics:**

| Field         | Required | Purpose                                                   |
|---------------|----------|-----------------------------------------------------------|
| `kubeContext` | Yes      | Context name from kubeconfig (e.g., "minikube", "eks-prod") |
| `kubeConfig`  | No       | Path to kubeconfig file (defaults to standard locations)  |
| `context`     | No       | Platform-specific context (see `#PlatformContext` below)   |

**Design rationale:** `#Platform` answers two questions: "how do I reach this cluster?" (kubeContext) and "what does this cluster provide?" (context). The `#Environment` definition (below) binds a platform to a namespace and value overrides, answering "how do I deploy this release?"

### `#PlatformContext` Definition

A new CUE definition in `v0/core/platform.cue` defining well-known fields that platforms can provide:

```cue
package core

// #PlatformContext: Well-known fields that platforms can provide.
// Module authors reference these shapes in their schemas/config.
// Platform operators populate concrete values in .opm/platform.cue.
// Future: values can be queried from live cluster state (separate RFC).
#PlatformContext: {
    // Network context
    defaultDomain?:    string   // Default domain suffix for HTTPRoute (e.g., "staging.example.com")
    ingressClassName?: string   // Default ingress class (e.g., "nginx", "alb", "traefik")
    gatewayRef?: {              // Default Gateway API gateway reference
        name!:      string
        namespace?: string
    }
    certificateRef?: {          // Default TLS certificate reference
        name!:      string
        namespace?: string
    }

    // Storage context
    defaultStorageClass?: string  // Default storage class (e.g., "gp3", "premium-rwo", "standard")

    // Security context
    defaultRunAsUser?:  int   // Default non-root UID for containers
    defaultRunAsGroup?: int   // Default GID for containers

    // Registry context
    imageRegistry?: string  // Default image registry prefix (e.g., "registry.internal.company.com")

    // Platform capabilities
    capabilities?: [...string]  // What this platform supports (e.g., ["cert-manager", "service-mesh", "gpu"])
}
```

**Well-known fields by category:**

| Category | Field | Purpose | Example |
|----------|-------|---------|---------|
| Network | `defaultDomain` | Default domain for HTTPRoute hostnames | `"staging.example.com"` |
| Network | `ingressClassName` | Default ingress controller | `"nginx"` |
| Network | `gatewayRef` | Default Gateway API gateway | `{name: "main-gateway"}` |
| Network | `certificateRef` | Default TLS certificate | `{name: "wildcard-cert"}` |
| Storage | `defaultStorageClass` | Default persistent volume class | `"gp3"` |
| Security | `defaultRunAsUser` | Default non-root UID | `1000` |
| Security | `defaultRunAsGroup` | Default GID | `1000` |
| Registry | `imageRegistry` | Image registry prefix | `"registry.internal"` |
| Capabilities | `capabilities` | Platform feature list | `["cert-manager", "gpu"]` |

### Platform Configuration (`.opm/platform.cue`)

Users define named platforms in `.opm/platform.cue` (or any `.cue` file in `.opm/` — the CLI loads the entire directory as a package):

```cue
package opm

import "opmodel.dev/core@v0"

// Named platforms — the shared infrastructure with capabilities
platforms: [string]: core.#Platform
platforms: {
    "dev": {
        kubeContext: "minikube"
        context: {
            defaultDomain:       "dev.local"
            ingressClassName:    "nginx"
            defaultStorageClass: "standard"
            capabilities: ["cert-manager"]
        }
    }
    "staging": {
        kubeContext: "eks-us-west-2"
        context: {
            defaultDomain:       "staging.example.com"
            ingressClassName:    "alb"
            defaultStorageClass: "gp3"
            certificateRef: {
                name:      "wildcard-staging"
                namespace: "cert-manager"
            }
            capabilities: ["cert-manager", "service-mesh", "external-dns"]
        }
    }
    "prod-us": {
        kubeContext: "eks-us-east-1"
        context: {
            defaultDomain:       "example.com"
            ingressClassName:    "alb"
            defaultStorageClass: "gp3"
            defaultRunAsUser:    1000
            defaultRunAsGroup:   1000
            certificateRef: {
                name:      "wildcard-prod"
                namespace: "cert-manager"
            }
            imageRegistry: "registry.internal.company.com"
            capabilities: ["cert-manager", "service-mesh", "external-dns", "gpu"]
        }
    }
}
```

**Key properties:**

- **Type-safe.** The map conforms to `[string]: core.#Platform`, validated by CUE.
- **Reusable.** Multiple modules reference the same platform definitions.
- **Git tracking is user's choice.** Some teams commit `.opm/platform.cue` (shared infrastructure), others gitignore it (personal dev clusters). Document both patterns.
- **No secrets.** kubeContext is just a reference to an entry in the user's existing kubeconfig. Credentials remain in `~/.kube/config` or wherever the user manages them.

### `#Environment` Definition

A new CUE definition in `v0/core/environment.cue`:

```cue
package core

// #Environment: Defines a deployment target by binding a platform
// to a namespace and value overrides.
// Lives on #ModuleRelease.environments map. Users design their own topology
// by defining which platforms+namespaces constitute each environment.
// Value overrides are applied by Go with environment-wins precedence.
#Environment: close({
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Environment"

    metadata: {
        name!:        #NameType   // "staging", "production", "dev"
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // Required reference to a platform (cluster connection + context)
    platform!: #Platform

    // Target namespace for this environment
    namespace?: string

    // Value overrides — partial subset of the module's #config
    // Applied by Go: effectiveValues = deepMerge(release.values, env.values)
    // CUE validates type compatibility at ModuleRelease level
    values?: _
})

#EnvironmentMap: [string]: #Environment
```

**Field semantics:**

| Field                  | Required | Purpose                                                            |
|------------------------|----------|--------------------------------------------------------------------|
| `metadata.name`        | Yes      | Human-readable identifier ("staging", "production")                |
| `metadata.labels`      | No       | Labels propagated to K8s resources via transformer                 |
| `metadata.annotations` | No       | Annotations for tooling hints                                      |
| `platform`             | Yes      | Reference to a `#Platform` (cluster connection + context)          |
| `namespace`            | No       | Target namespace for this environment                              |
| `values`               | No       | Partial value overrides (must type-check against module `#config`) |

**Why `values?: _` (unconstrained in `#Environment`):** The environment is defined on the `#ModuleRelease` but is not coupled to the module's schema. It cannot reference `#module.#config` at the definition site. Type validation happens at the `#ModuleRelease` level where both the module and environment are known (see [CUE-Level Partial Validation](#cue-level-partial-validation)).

### Updated `#ModuleRelease`

The release gains an optional `environments?` map. When defined, the user can design a custom topology for this release by mapping environment names to runtime contexts, namespaces, and value overrides.

**Key changes:**

1. `metadata.namespace` is **conditionally required**: required when no `environments` map exists, optional when environments provide it.
2. `environments?: #EnvironmentMap` — a map of environment definitions keyed by name (e.g., `"staging"`, `"production"`).
3. The CLI requires `-e <name>` when applying a release with environments. The selected environment determines namespace, runtime context, and value overrides.
4. Identity hash includes the selected environment name (when applicable).
5. CUE validates that each environment's `values` is type-compatible with `#module.#config`.
6. Go computes effective values by deep-merging release values with environment values (environment wins).

Changes from current `#ModuleRelease` (additions/changes marked with `// NEW` or `// CHANGED`):

```cue
package core

import "uuid"

#ModuleRelease: close({
    apiVersion: "opmodel.dev/core/v0"
    kind:       "ModuleRelease"

    metadata: {
        name!:      #NameType
        // CHANGED: conditionally required — omit when environments provide it
        namespace?: string
        version:    #moduleMetadata.version

        // NEW: Identity computation depends on selected environment
        // CLI injects _selectedEnvironment at apply time when -e is used
        _selectedEnvironment?: string
        _identityInput: "\(#moduleMetadata.fqn):\(name):\(namespace)"
        if _selectedEnvironment != _|_ {
            _identityInput: "\(#moduleMetadata.fqn):\(name):\(namespace):\(_selectedEnvironment)"
        }
        identity: #UUIDType & uuid.SHA1(OPMNamespace, _identityInput)

        labels?: #LabelsAnnotationsType
        labels: {if #moduleMetadata.labels != _|_ {#moduleMetadata.labels}} & {
            "module-release.opmodel.dev/name":    "\(name)"
            "module-release.opmodel.dev/version": "\(version)"
            "module-release.opmodel.dev/uuid":    "\(identity)"
            // NEW: environment label when selected via CLI
            if _selectedEnvironment != _|_ {
                "module-release.opmodel.dev/environment": "\(_selectedEnvironment)"
            }
        }
        annotations?: #LabelsAnnotationsType
        annotations: {if #moduleMetadata.annotations != _|_ {#moduleMetadata.annotations}}
    }

    #module!:        #Module
    #moduleMetadata: #module.metadata

    // NEW: optional environments map
    environments?: #EnvironmentMap

    // NEW: CUE-level partial validation of environment values
    // Validates all environments in the map against module config
    if environments != _|_ {
        for envName, env in environments {
            if env.values != _|_ {
                _envValuesTypeCheck: "\(envName)": #module.#config & env.values
            }
        }
    }

    // Base values (developer intent)
    // Go computes: effectiveValues = deepMerge(values, selectedEnv.values)
    // Go validates: effectiveValues against #module.#config
    // Go renders: components with effectiveValues
    _#module: #module & {#config: values}
    components: _#module.#components

    policies?: [Id=string]: #Policy
    if _#module.#policies != _|_ {
        policies: _#module.#policies
    }

    values: close(#module.#config)
})

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
│    Example:  UUIDv5(ns, "opmodel.dev/m@v0#App:myapp:default")        │
│                                                                      │
│  With environment (CLI applies with -e <name>):                      │
│    identity = UUIDv5(OPMNamespace, "fqn:name:namespace:envName")     │
│    Example:  UUIDv5(ns, "opmodel.dev/m@v0#App:myapp:staging:stg")    │
│                                                                      │
│  The environment name (from the environments map key) is appended    │
│  after the namespace, separated by a colon. The CLI injects the      │
│  selected environment name as _selectedEnvironment during apply.     │
│                                                                      │
│  This means:                                                         │
│  • Same release applied to different envs has different identities   │
│    (correct — each env is a distinct deployment).                    │
│  • A release without environments has the same identity as           │
│    today (backward compatible).                                      │
│  • The namespace in the identity input comes from the selected       │
│    environment.namespace if defined, else metadata.namespace.        │
└──────────────────────────────────────────────────────────────────────┘
```

### CUE-Level Partial Validation

Environment values must be type-compatible with the module's `#config` schema. Since `#Environment` is defined independently of any module, validation happens at the `#ModuleRelease` level where both are known:

```cue
// In #ModuleRelease:
if #environment != _|_
if #environment.values != _|_ {
    _envValuesTypeCheck: #module.#config & #environment.values
}
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
│    replicaCount: 3          ← int & 3 = 3            OK              │
│    replicaCount: "three"    ← int & "three" = _|_    CUE ERROR       │
│    logLevel: "verbose"      ← disjunction miss       CUE ERROR       │
│    bogusField: true         ← not in #config*        UNDETECTED      │
│                                                                      │
│  *Unknown fields are caught by Go after merge, not by CUE.           │
│   CUE's unification adds extra fields to open structs silently.      │
│   Go validates the merged result against close(#module.#config)      │
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
│          validate against            ← Go: CUE eval of               │
│          close(#module.#config)         close(#module.#config)       │
│                     │                                                │
│          render components           ← Go: re-evaluate module        │
│          with effectiveValues           with effective values        │
│                     │                                                │
│          inject into                 ← Go: populate                  │
│          #TransformerContext            #environmentMetadata         │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

**Deep merge rules:**

1. **Scalar fields:** Environment value replaces release value. 2. **Struct fields:** Recursively merge. Environment fields override release
   fields at each level. 3. **Missing fields:** If a field exists in the release but not in the environment, the release value is kept. If a field exists in the environment but not in the release, the environment value is added.
2. **Validation:** After merge, the effective values are validated against `close(#module.#config)` via CUE evaluation. This catches unknown fields introduced by the environment and ensures all required fields are present.

**Why Go, not CUE:** CUE unification is commutative — `{a: 1} & {a: 2}` is an error, not `2`. There is no "last wins" in CUE. True override semantics require imperative merge logic. Go's `deepMerge` function provides this naturally, while CUE continues to serve its strength: schema validation.

### Updated `#TransformerContext`

The transformer context carries environment metadata and platform context into each transformer during rendering. This enables transformers to:
- Generate environment-aware Kubernetes resources (labels, annotations)
- Access platform capabilities and defaults (storage classes, ingress classes, domain names)

Changes from current `#TransformerContext` (additions marked with `// NEW`):

```cue
#TransformerContext: {
    #moduleReleaseMetadata: {
        name!:        #NameType
        namespace!:   #NameType
        fqn:          string
        version:      string
        identity:     #UUIDType
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // NEW: environment metadata (optional, absent when no environment)
    #environmentMetadata?: {
        name!:        #NameType
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // NEW: platform context (optional, absent when no platform or no context)
    #platformContext?: #PlatformContext

    #componentMetadata: {
        name!:        #NameType
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    name:      string // Injected during rendering (release name)
    namespace: string // Injected during rendering (target namespace)

    // Existing computed labels (unchanged)
    moduleLabels: {
        if #moduleReleaseMetadata.labels != _|_ {
            for k, v in #moduleReleaseMetadata.labels {
                (k): "\(v)"
            }
        }
    }

    moduleAnnotations: {
        if #moduleReleaseMetadata.annotations != _|_ {
            for k, v in #moduleReleaseMetadata.annotations {
                (k): "\(v)"
            }
        }
    }

    componentLabels: {
        "app.kubernetes.io/name": #componentMetadata.name
        if #componentMetadata.labels != _|_ {
            for k, v in #componentMetadata.labels {
                if !strings.HasPrefix(k, "transformer.opmodel.dev/") {
                    (k): "\(v)"
                }
            }
        }
    }

    componentAnnotations: {
        if #componentMetadata.annotations != _|_ {
            for k, v in #componentMetadata.annotations {
                if !strings.HasPrefix(k, "transformer.opmodel.dev/") {
                    (k): "\(v)"
                }
            }
        }
    }

    controllerLabels: {
        "app.kubernetes.io/managed-by": "open-platform-model"
        "app.kubernetes.io/name":       #componentMetadata.name
        "app.kubernetes.io/instance":   #componentMetadata.name
        "app.kubernetes.io/version":    #moduleReleaseMetadata.version
    }

    // NEW: environment labels
    environmentLabels: {
        if #environmentMetadata != _|_ {
            "environment.opmodel.dev/name": #environmentMetadata.name
            if #environmentMetadata.labels != _|_ {
                for k, v in #environmentMetadata.labels {
                    (k): "\(v)"
                }
            }
        }
    }

    // NEW: environment annotations
    environmentAnnotations: {
        if #environmentMetadata != _|_ {
            if #environmentMetadata.annotations != _|_ {
                for k, v in #environmentMetadata.annotations {
                    (k): "\(v)"
                }
            }
        }
    }

    // Updated: labels now include environment labels
    labels: {[string]: string}
    labels: {
        for k, v in moduleLabels {
            (k): "\(v)"
        }
        for k, v in componentLabels {
            (k): "\(v)"
        }
        for k, v in controllerLabels {
            (k): "\(v)"
        }
        for k, v in environmentLabels {   // NEW
            (k): "\(v)"
        }
        ...
    }

    // Updated: annotations now include environment annotations
    annotations: {[string]: string}
    annotations: {
        for k, v in moduleAnnotations {
            (k): "\(v)"
        }
        for k, v in componentAnnotations {
            (k): "\(v)"
        }
        for k, v in environmentAnnotations {   // NEW
            (k): "\(v)"
        }
        ...
    }
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

### Platform Context: Well-Known Shapes, Concrete Values

The platform context mechanism separates **shape** from **value**:

- **Module authors** reference well-known context fields in their module definitions. The shapes are known at authoring time (e.g., `defaultDomain: string`), but values are abstract.
- **Platform operators** provide concrete values in `.opm/platform.cue` for each platform (e.g., `defaultDomain: "staging.example.com"`).
- **At deploy time**, the CLI injects the selected platform's context into the transformer context, making values available during rendering.

**Example: HTTPRoute using platform's defaultDomain**

```cue
// Module definition
#Module: {
    #config: {
        subdomain?: string  // e.g., "api", "www"
    }
    
    #components: {
        web: #Component & {
            #resources: {
                container: #Container & {
                    image: "myapp:v1"
                }
            }
            #traits: {
                httpRoute: #HTTPRoute & {
                    // Module author references well-known platform context
                    // Shape is known (string), value is concrete at deploy time
                    hostnames: ["\(#config.subdomain).\(#platformContext.defaultDomain)"]
                }
            }
        }
    }
}

// Platform definition (.opm/platform.cue)
platforms: {
    "staging": {
        kubeContext: "eks-us-west-2"
        context: {
            defaultDomain: "staging.example.com"  // concrete value
        }
    }
    "production": {
        kubeContext: "eks-us-east-1"
        context: {
            defaultDomain: "example.com"  // different concrete value
        }
    }
}

// Release
myapp: #ModuleRelease & {
    #module: myModule
    values: { subdomain: "api" }
    environments: {
        "staging": {
            platform:  platforms.staging
            namespace: "staging"
        }
        "production": {
            platform:  platforms.production
            namespace: "production"
        }
    }
}

// Result when deployed:
// $ opm apply myapp -e staging
//   → HTTPRoute hostname: "api.staging.example.com"
// $ opm apply myapp -e production
//   → HTTPRoute hostname: "api.example.com"
```

**Future: Query-Based Context Population**

The current design requires platform operators to manually populate context fields in `.opm/platform.cue`. A future RFC will introduce a query mechanism to fetch context values from live cluster state:

```cue
// Future: platform with queries (deferred to separate RFC)
platforms: {
    "staging": {
        kubeContext: "eks-us-west-2"
        queries: [
            {
                field: "context.defaultStorageClass"
                query: "k8s:storage.k8s.io/v1:StorageClass"
                filter: "metadata.annotations['storageclass.kubernetes.io/is-default-class'] == 'true'"
                extract: "metadata.name"
            },
            {
                field: "context.ingressClassName"
                query: "k8s:networking.k8s.io/v1:IngressClass"
                filter: "metadata.annotations['ingressclass.kubernetes.io/is-default-class'] == 'true'"
                extract: "metadata.name"
            }
        ]
    }
}
```

This would allow platform context to be dynamically populated from cluster resources (StorageClasses, IngressClasses, Secrets, ConfigMaps, CRDs), avoiding manual synchronization. See [Deferred Work: Platform Context Queries](#platform-context-queries) for details.

### CLI Integration

The OPM CLI (`opm`) gains environment selection via the `-e, --environment` flag:

```bash
# Apply a release to a specific environment
opm apply <release-name> -e staging

# When a release has environments, -e is required
opm apply myapp -e production

# Build and render with effective values for an environment
opm build <release-name> -e staging

# Diff against the cluster specified by the environment's runtime
opm diff <release-name> -e production
```

**CLI behavior:**

1. **Load `.opm/platform.cue`:** The CLI loads all `.cue` files in `.opm/` as a CUE package, extracting the `platforms` map.
2. **Load the release:** The CLI evaluates the user's CUE files to get the `#ModuleRelease`.
3. **Environment selection:**
   - If the release has `environments`, the CLI **requires** `-e <name>`.
   - The CLI looks up `environments[<name>]` from the release.
   - It resolves the environment's `platform` reference against the `platforms` map.
   - It extracts `namespace` (from environment or release default), `values`, and `platform.context`.
4. **Inject selected environment:** The CLI injects `_selectedEnvironment: "<name>"` into the CUE evaluation context. This triggers the identity hash computation with the environment name.
5. **Go merge pipeline:** The CLI runs the Go deep merge (`deepMerge(release.values, env.values)`), validates the effective values against `#module.#config`, and re-evaluates the module with effective values.
6. **Render components:** Components are rendered with effective values. The `#TransformerContext` receives:
   - `#environmentMetadata` populated from the selected environment
   - `#platformContext` populated from the platform's `context` field
7. **Apply to cluster:** The CLI switches to the kubeContext specified by `environment.platform.kubeContext` (and optionally `kubeConfig`), then applies the rendered resources to the target namespace.

**Example flow:**

```text
┌──────────────────────────────────────────────────────────────────────┐
│  $ opm apply myapp -e staging                                        │
│                                                                      │
│  1. CLI loads .opm/platform.cue → extracts platforms map             │
│  2. CLI loads project CUE files → evaluates myapp release            │
│  3. CLI validates: myapp.environments.staging exists                 │
│  4. CLI resolves: staging.platform → platforms["staging-eks"]        │
│  5. CLI extracts: namespace, values, platform.context                │
│  6. CLI injects: _selectedEnvironment="staging" into eval            │
│  7. Go merge: effectiveValues = deepMerge(myapp.values, env.values)  │
│  8. Go validates: effectiveValues against #module.#config            │
│  9. Go re-evaluates: module with effectiveValues                     │
│ 10. Transformers render: components with effective values +          │
│     #platformContext (defaultDomain, storageClass, etc.)             │
│ 11. CLI switches: kubeconfig context to "eks-us-west-2"             │
│ 12. CLI applies: rendered K8s resources to "staging" namespace       │
│                                                                      │
│  Result: myapp deployed to staging with platform context available   │
└──────────────────────────────────────────────────────────────────────┘
```

**Backward compatibility:** Releases without `environments` continue to work as today. The `-e` flag is ignored (or errors) when the release has no environments map.

## Scenarios

### Scenario A: Basic Environment with Platform and Namespace

```text
Platform (.opm/platform.cue):
    platforms: {
        "staging-cluster": {
            kubeContext: "eks-us-west-2-staging"
            context: {
                defaultDomain:       "staging.example.com"
                defaultStorageClass: "gp3"
            }
        }
    }

Release:
    myapp: #ModuleRelease & {
        metadata: name: "myapp"
        #module: myModule
        values: { image: "myapp:v2" }
        environments: {
            "staging": {
                metadata: name: "staging"
                platform:  platforms["staging-cluster"]
                namespace: "staging"
                values: { replicaCount: 1 }
            }
        }
    }

CLI:
    $ opm apply myapp -e staging

Result:
    metadata.namespace: "staging"   (from environment)
    metadata.identity:  UUIDv5(ns, "fqn:myapp:staging:staging")
    labels include: environment.opmodel.dev/name: "staging"
    Cluster context: eks-us-west-2-staging (from platform)
    Platform context available to transformers: defaultDomain, defaultStorageClass
    Effective values: { image: "myapp:v2", replicaCount: 1 }

[x]
```

### Scenario B: Same Cluster, Different Environments

```text
Platform (.opm/platform.cue):
    platforms: {
        "shared-cluster": {
            kubeContext: "eks-us-west-2"
            context: {
                defaultStorageClass: "gp3"
                ingressClassName:    "alb"
            }
        }
    }

Release (single release, multiple environments):
    myapp: #ModuleRelease & {
        metadata: name: "myapp"
        #module: myModule
        values: { image: "myapp:v2" }
        environments: {
            "staging": {
                metadata: name: "staging"
                platform:  platforms["shared-cluster"]  // same platform
                namespace: "staging"
                values: { replicaCount: 1, logLevel: "debug" }
            }
            "production": {
                metadata: name: "production"
                platform:  platforms["shared-cluster"]  // same platform
                namespace: "production"
                values: { replicaCount: 3, logLevel: "info" }
            }
        }
    }

CLI:
    $ opm apply myapp -e staging
    $ opm apply myapp -e production

Go merge results:
    staging effective:    { image: "myapp:v2", replicaCount: 1, logLevel: "debug" }
    production effective: { image: "myapp:v2", replicaCount: 3, logLevel: "info" }

Identities differ (different env name in hash):
    staging identity  = UUIDv5(ns, "fqn:myapp:staging:staging")
    production identity = UUIDv5(ns, "fqn:myapp:production:production")

Same cluster, different namespaces, different effective values.
Both environments share platform context (storage class, ingress class). [x]
```

### Scenario C: No Environment — Backward Compatible

```text
Release (no #environment):
    myapp: #ModuleRelease & {
        metadata: { name: "myapp", namespace: "default" }
        #module: myModule
        values: { image: "myapp:v2", replicaCount: 1 }
    }

Result:
    metadata.namespace: "default"
    metadata.identity:  UUIDv5(ns, "fqn:myapp:default")   // same as today

    No environment labels on rendered resources.
    No Go merge needed — values used as-is.
    _envValuesTypeCheck: not evaluated (guarded by if).

Identical behavior to current OPM. [x]
```

### Scenario D: Environment Value Override — Environment Wins

```text
Module:
    #config: {
        image!:        string       replicaCount:  *1 | int
        logLevel:      *"info" | "debug" | "warn" | "error"
    }

Release:
    values: {
        image:        "myapp:v2"
        replicaCount: 2          // developer wants 2
        logLevel:     "debug"    // developer wants debug
    }

Environment:
    values: {
        replicaCount: 5          // ops overrides to 5
    }

Go deepMerge (env wins):
    effective: {
        image:        "myapp:v2"    // from release (env doesn't set it)
        replicaCount: 5             // from environment (overrides release's 2)
        logLevel:     "debug"       // from release (env doesn't set it)
    }

Go validates effective against close(#module.#config): OK

Environment wins for replicaCount. Release values kept for unoverridden fields. [x]
```

### Scenario E: CUE Type-Check Catches Invalid Environment Values

```text
Module:
    #config: {
        replicaCount: int
        logLevel:     "debug" | "info" | "warn" | "error"
    }

Environment:
    values: {
        replicaCount: "three"     // string, not int
    }

CUE evaluation of _envValuesTypeCheck:
    #module.#config & #environment.values = { replicaCount: int, logLevel: ... } & { replicaCount: "three" }  = _|_  (int & "three" is bottom)

Result: CUE error during evaluation. Caught before Go merge runs.

  error: #ModuleRelease._envValuesTypeCheck.replicaCount:     conflicting values int and "three"

[x]
```

### Scenario F: Multiple Modules, Shared Platform

```text
Platform (.opm/platform.cue):
    platforms: {
        "staging-cluster": {
            kubeContext: "eks-staging"
            context: {
                defaultDomain:       "staging.example.com"
                defaultStorageClass: "gp3"
                ingressClassName:    "nginx"
            }
        }
    }

Releases (different modules, same environment pattern):
    frontend: #ModuleRelease & {
        metadata: name: "frontend"
        #module: frontendModule
        values: { image: "frontend:v3", port: 3000 }
        environments: {
            "staging": {
                metadata: name: "staging"
                platform:  platforms["staging-cluster"]
                namespace: "staging"
                values: { replicaCount: 1 }
            }
        }
    }

    backend: #ModuleRelease & {
        metadata: name: "backend"
        #module: backendModule
        values: { image: "backend:v2", port: 8080 }
        environments: {
            "staging": {
                metadata: name: "staging"
                platform:  platforms["staging-cluster"]  // same platform ref
                namespace: "staging"
                values: { replicaCount: 1 }
            }
        }
    }

CLI:
    $ opm apply frontend -e staging
    $ opm apply backend -e staging

Both releases:
    - Share the same cluster context, namespace, and platform context.
    - Both get replicaCount: 1 from their environment values.
    - Both carry environment.opmodel.dev/name: "staging" label.
    - Both have access to platform context (defaultDomain, storageClass, etc.).
    - Different identities (different module FQNs and release names).

Change staging platform context once in .opm/platform.cue → all modules updated. [x]
```

### Scenario G: Environment Without Namespace — Release Provides It

```text
Platform (.opm/platform.cue):
    platforms: {
        "prod-cluster": {
            kubeContext: "eks-prod"
            context: {
                defaultDomain:       "example.com"
                defaultStorageClass: "gp3"
            }
        }
    }

Release:
    myapp: #ModuleRelease & {
        metadata: { name: "myapp", namespace: "myapp-prod" }  // explicit namespace
        #module: myModule
        values: { image: "myapp:v2" }
        environments: {
            "production": {
                metadata: name: "production"
                platform:  platforms["prod-cluster"]
                // No namespace — release provides it
                values: { replicaCount: 3 }
            }
        }
    }

CLI:
    $ opm apply myapp -e production

Result:
    metadata.namespace: "myapp-prod"   // from release (env has no namespace)
    Cluster context: eks-prod          // from platform
    Platform context available: defaultDomain, defaultStorageClass
    Effective values: { image: "myapp:v2", replicaCount: 3 }

Environment provides platform + values. Release provides namespace. [x]
```

### Scenario H: Multi-Module Topology Freedom

```text
Platform (.opm/platform.cue):
    platforms: {
        "dev-cluster": {
            kubeContext: "minikube"
            context: {
                defaultDomain:       "dev.local"
                defaultStorageClass: "standard"
            }
        }
        "staging-eks": {
            kubeContext: "eks-us-west-2"
            context: {
                defaultDomain:       "staging.example.com"
                defaultStorageClass: "gp3"
                ingressClassName:    "alb"
            }
        }
        "prod-us": {
            kubeContext: "eks-us-east-1"
            context: {
                defaultDomain:       "example.com"
                defaultStorageClass: "gp3"
                ingressClassName:    "alb"
            }
        }
        "prod-eu": {
            kubeContext: "eks-eu-west-1"
            context: {
                defaultDomain:       "eu.example.com"
                defaultStorageClass: "gp3"
                ingressClassName:    "alb"
            }
        }
    }

Module A (simple staging/prod):
    moduleA: #ModuleRelease & {
        metadata: name: "moduleA"
        #module: moduleADef
        values: { image: "a:v1" }
        environments: {
            "staging":    { platform: platforms["staging-eks"], namespace: "a-staging" }
            "production": { platform: platforms["prod-us"],     namespace: "a-prod" }
        }
    }

Module B (multi-region prod):
    moduleB: #ModuleRelease & {
        metadata: name: "moduleB"
        #module: moduleBDef
        values: { image: "b:v1" }
        environments: {
            "staging":  { platform: platforms["staging-eks"], namespace: "b-staging" }
            "prod-us":  { platform: platforms["prod-us"],     namespace: "b-prod" }
            "prod-eu":  { platform: platforms["prod-eu"],     namespace: "b-prod" }
        }
    }

Module C (dev-only):
    moduleC: #ModuleRelease & {
        metadata: name: "moduleC"
        #module: moduleCDef
        values: { image: "c:dev" }
        environments: {
            "dev": { platform: platforms["dev-cluster"], namespace: "c-dev" }
        }
    }

CLI:
    $ opm apply moduleA -e production    → deploys to prod-us (domain: example.com)
    $ opm apply moduleB -e prod-eu       → deploys to prod-eu (domain: eu.example.com)
    $ opm apply moduleC -e dev           → deploys to minikube (domain: dev.local)

Total topology freedom per module. Platforms reused across all modules.
Each platform provides different context (domains, storage classes, ingress).
Users design their own environment topology for each release. [x]
```

## Open Questions

### Q1: Runtime Value Queries from Cluster State

Timoni Runtime supports querying live Kubernetes resources (Secrets, ConfigMaps, CRDs) at apply time and injecting their values into the bundle. Should `#Environment` support a similar mechanism?

**Current position:** Deferred. The initial design focuses on static environment definitions. Runtime queries add significant complexity (cluster connectivity during evaluation, error handling for missing resources, optional vs required queries). They can be added as a future extension without breaking the current schema.

### Q2: Should `#BundleRelease` Support Environments?

`#BundleRelease` currently has no namespace and no environment concept. Bundles contain multiple modules, each potentially targeting different environments.

**Current position:** Deferred. Start with `#ModuleRelease` only. If bundles need environment support, it could be added at the bundle level (one environment for the entire bundle) or per-module within the bundle. The per-module approach is more flexible but more complex.

### Q3: Environment Inheritance or Composition

Should environments support inheritance or composition patterns? For example, defining a "base-production" environment template and regional variants:

```cue
_baseProd: {  // helper, not an #Environment
    values: { replicaCount: 3, logLevel: "info" }
}

myapp: #ModuleRelease & {
    environments: {
        "prod-us": #Environment & {
            _baseProd
            metadata: name: "prod-us"
            runtime:   runtimes["prod-us-cluster"]
            namespace: "production"
        }
        "prod-eu": #Environment & {
            _baseProd
            metadata: name: "prod-eu"
            runtime:   runtimes["prod-eu-cluster"]
            namespace: "production"
            values: { region: "eu-west-1" }  // extends _baseProd.values
        }
    }
}
```

**Current position:** Deferred. CUE's native struct embedding already provides composition for non-values fields. For `values`, the same "last wins" limitation exists (CUE unification is commutative). Users can use CUE helpers or explicit value spreading for now. A future design could add a `base?: string` field to `#Environment` that references another environment in the map, with Go-level merge semantics.

### Q4: Environment Groups

Timoni's Runtime uses `group` to categorize clusters into environments (e.g., all "production" clusters). Should `#Environment` support a `group` field for similar categorization?

**Current position:** Not needed in the initial design. OPM delegates deployment ordering to the orchestrator and does not need to group environments for sequential rollout. If grouping becomes useful for tooling or reporting, it can be added as an optional metadata field without schema changes.

## Deferred Work

### BundleRelease Environment Support

Extend `#BundleRelease` with an `environments` map, mirroring the `#ModuleRelease` extension. Design considerations: should each module within the bundle have its own environment topology, or should the bundle-level environments apply uniformly to all modules? The per-module approach is more flexible but requires careful CLI design for selection (`-e <bundle-env>` vs per-module environment specification).

### Platform Context Queries

Add a `queries` field to `#Platform` that fetches live Kubernetes resources (StorageClasses, IngressClasses, Secrets, ConfigMaps, CRDs) at apply time and populates `#PlatformContext` fields. This would bring OPM closer to Timoni's Runtime value query model. 

**Design questions for future RFC:**

- **Query syntax:** How to express "fetch the default StorageClass" or "get Secret value from field X"?
- **Field mapping:** How to map query results to `#PlatformContext` fields?
- **Error handling:** What happens when a queried resource doesn't exist? Optional vs required queries?
- **Caching:** Should query results be cached? For how long?
- **Security:** Reading arbitrary cluster state has permission implications. Should queries be scoped by RBAC?
- **Placement:** Should queries live on `#Platform` (cluster-level) or `#Environment` (deployment-level)?

**Example vision (syntax TBD):**

```cue
platforms: {
    "staging": {
        kubeContext: "eks-us-west-2"
        queries: [
            {
                field: "context.defaultStorageClass"
                query: "k8s:storage.k8s.io/v1:StorageClass"
                filter: "metadata.annotations['storageclass.kubernetes.io/is-default-class'] == 'true'"
                extract: "metadata.name"
            },
            {
                field: "context.ingressClassName"
                query: "k8s:networking.k8s.io/v1:IngressClass"
                filter: "metadata.annotations['ingressclass.kubernetes.io/is-default-class'] == 'true'"
                extract: "metadata.name"
            },
            {
                field: "context.certificateRef.name"
                query: "k8s:v1:Secret:cert-manager"
                filter: "metadata.name == 'wildcard-staging'"
                extract: "metadata.name"
            }
        ]
    }
}
```

This would eliminate manual synchronization between platform definitions and actual cluster state.

### Deployment Ordering and Rollout Strategy

Define how environments are ordered during multi-environment deployments (e.g., staging before production, canary before full rollout). This is explicitly left to the orchestrator in the current design. If OPM gains a built-in apply pipeline, ordering could be expressed as a separate `#DeploymentPlan` or `#Rollout` definition that references environments in sequence.

## References

- [Timoni Bundle Runtime](https://timoni.sh/bundle-runtime/) — Runtime   definition, cluster targeting, runtime value queries
- [Timoni Multi-cluster Deployments](https://timoni.sh/bundle-multi-cluster/) —   Multi-cluster operations with Runtime
- [KubeVela Multi-Environment](https://kubevela.io/docs/end-user/policies/envbinding/) —   env-binding policy for multi-environment deployments
- [KubeVela Multi-Cluster Application](https://kubevela.io/docs/case-studies/multi-cluster/) —   topology and override policies for multi-cluster
- OPM `#ModuleRelease` — `v0/core/module_release.cue`
- OPM `#TransformerContext` — `v0/core/transformer.cue`
- OPM `#Module` — `v0/core/module.cue`
