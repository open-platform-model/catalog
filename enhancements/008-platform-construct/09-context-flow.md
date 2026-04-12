# Context Flow Diagram

Information flow from `#Platform` definition through to rendered Kubernetes resources.

## Context Hierarchy

```text
                              AUTHORING TIME
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐

  .opm/platforms/<name>/platform.cue
  ┌─────────────────────────────────────────────────────────────────────┐
  │ #Platform                                                  Layer 1  │
  │                                                                     │
  │  metadata: { name, type }                                           │
  │                                                                     │
  │  #ctx: #PlatformContext                                             │
  │  ├── runtime:                                                       │
  │  │     cluster.domain        "cluster.local"                        │
  │  │     route.domain?         (optional default)                     │
  │  └── platform:                                                      │
  │        { ... }               open struct, team-defined              │
  │                                                                     │
  │  #providers: [ordered]                                              │
  │  ├── opm.#Provider           priority 1 (highest)                   │
  │  ├── k8up.#Provider          priority 2                             │
  │  ├── certmgr.#Provider       priority 3                             │
  │  └── ...                                                            │
  │       │                                                             │
  │       └──▶ CUE unification ──▶ #composedTransformers              │
  │                                #provider (composed)                 │
  │                                #declaredResources                   │
  └──────────────────┬──────────────────────────┬───────────────────────┘
                     │ referenced by            │ composed provider
                     ▼                          │
  .opm/environments/<name>/environment.cue      │
  ┌─────────────────────────────────────────────┼───────────────────────┐
  │ #Environment                                │              Layer 2  │
  │                                             │                       │
  │  metadata: { name }                         │                       │
  │                                             │                       │
  │  #platform ────────▶ #Platform ────────────┘                       │
  │                                                                     │
  │  #ctx: #EnvironmentContext                                          │
  │  ├── runtime:                                                       │
  │  │     release.namespace     "dev"                                  │
  │  │     cluster.domain?       override platform (rare)               │
  │  │     route.domain?         "dev.example.com"                      │
  │  └── platform:                                                      │
  │        { ... }               env-specific extensions                │
  └──────────────────┬──────────────────────────────────────────────────┘
                     │ imported via #env
                     ▼
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

                              DEPLOY TIME
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐

  releases/<env>/<module>/release.cue
  ┌─────────────────────────────────────────────────────────────────────┐
  │ #ModuleRelease                                             Layer 3  │
  │                                                                     │
  │  metadata:                                                          │
  │    name          "jellyfin"                                         │
  │    namespace     "media"       (overrides env default)              │
  │    uuid          <generated>                                        │
  │                                                                     │
  │  #env: #Environment                                                 │
  │  #module: <module definition>                                       │
  │  values: { ... } ──────────▶ #config                               │
  │                                                                     │
  │  ┌──────────────────────────────────────────────────────────────┐   │
  │  │ #ContextBuilder                                              │   │
  │  │                                                              │   │
  │  │  INPUTS:                                                     │   │
  │  │    #platform    ◀── #env.#platform                          │   │
  │  │    #environment ◀── #env                                    │   │
  │  │    #release     ◀── metadata { name, namespace, uuid }      │   │
  │  │    #module      ◀── #moduleMetadata { name, version,        │   │
  │  │                                       fqn, uuid }            │   │
  │  │    #components  ◀── #module.#components (keys + meta)       │   │
  │  │                                                              │   │
  │  │  MERGE ORDER:                                                │   │
  │  │    Platform #ctx.runtime        (base defaults)              │   │
  │  │      └▶ Environment #ctx.runtime  (overrides)               │   │
  │  │           └▶ Release identity     (name, ns, uuid)          │   │
  │  │                └▶ Component keys  (computed names)          │   │
  │  │                                                              │   │
  │  │  Platform #ctx.platform & Environment #ctx.platform          │   │
  │  │    (CUE unification of open structs)                         │   │
  │  │                                                              │   │
  │  │  OUTPUT: #ModuleContext                                      │   │
  │  └────────────────────────────┬─────────────────────────────────┘   │
  │                               │                                     │
  │                               ▼                                     │
  │  let unifiedModule = #module & {                                    │
  │      #config: values                                                │
  │      #ctx:    _computedCtx  ◀── #ModuleContext                     │
  │  }                                                                  │
  └──────────────────┬──────────────────────────┬───────────────────────┘
                     │ unified components       │ composed provider
                     ▼                          ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │ #Module (unified)                                                   │
  │                                                                     │
  │  #ctx: #ModuleContext                                               │
  │  ├── runtime: #RuntimeContext                                       │
  │  │   ├── release:    { name, namespace, uuid }                      │
  │  │   ├── module:     { name, version, fqn, uuid }                   │
  │  │   ├── cluster:    { domain }                                     │
  │  │   ├── route?:     { domain }                                     │
  │  │   └── components:                                                │
  │  │         [name]: #ComponentNames                                  │
  │  │           resourceName   "{release}-{component}"                 │
  │  │           dns.local      resourceName                            │
  │  │           dns.namespaced resourceName.namespace                  │
  │  │           dns.svc        resourceName.namespace.svc              │
  │  │           dns.fqdn       resourceName.ns.svc.cluster.local       │
  │  │           hashes?        { configMaps, secrets }                 │
  │  └── platform: { ... }     (merged open struct)                     │
  │                                                                     │
  │  #config: values                                                    │
  │                                                                     │
  │  #components:                                                       │
  │    jellyfin:                                                        │
  │      references #ctx.runtime.route.domain                           │
  │      references #ctx.runtime.components.jellyfin.dns.fqdn           │
  └──────────────────┬──────────────────────────────────────────────────┘
                     │ components extracted
                     ▼
└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘

                            RENDER PIPELINE
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐

  ┌─────────────────────────────────────────────────────────────────────┐
  │ CLI (Go)                                                            │
  │                                                                     │
  │  1. Load release CUE value                                          │
  │  2. Extract #env.#platform.#provider (composed)                     │
  │  3. Evaluate unified components                                     │
  │                                                                     │
  │  ┌─────────────────────────────────────────────────────────────┐    │
  │  │ #MatchPlan                                                  │    │
  │  │                                                             │    │
  │  │  composed provider                                          │    │
  │  │    #composedTransformers                                    │    │
  │  │      { FQN ──▶ Transformer }                               │    │
  │  │                                                             │    │
  │  │  For each component:                                        │    │
  │  │    match labels, resources, traits                          │    │
  │  │    ──▶ select transformers                                 │    │
  │  │    ──▶ priority from #providers order                      │    │
  │  └────────────────────────────┬────────────────────────────────┘    │
  │                               │                                     │
  │                               ▼                                     │
  │  For each (component, transformer) pair:                            │
  │    injectContext() fills #TransformerContext                        │
  │    execute transformer                                              │
  │    collect output resources                                         │
  └──────────────────┬──────────────────────────────────────────────────┘
                     │
                     ▼
  ┌─────────────────────────────────────────────────────────────────────┐
  │ Rendered Kubernetes Resources                                       │
  │                                                                     │
  │  Deployment, Service, ConfigMap, PVC, Ingress,                      │
  │  K8up Schedule, Certificate, ...                                    │
  └─────────────────────────────────────────────────────────────────────┘

└ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘
```

## Layer Resolution Example

Concrete example: Jellyfin release in `dev` environment on `kind-opm-dev` platform.

```text
┌──────────────────┬─────────────────┬─────────────┬────────────────┐
│                  │ cluster.domain  │ namespace   │ route.domain   │
├──────────────────┼─────────────────┼─────────────┼────────────────┤
│ Layer 1 Platform │ "cluster.local" │ -           │ -              │
│ Layer 2 Env      │ -               │ "dev"       │ "dev.local"    │
│ Layer 3 Release  │ -               │ "media" *   │ -              │
├──────────────────┼─────────────────┼─────────────┼────────────────┤
│ Result           │ "cluster.local" │ "media"     │ "dev.local"    │
└──────────────────┴─────────────────┴─────────────┴────────────────┘

* Release metadata.namespace overrides environment default
```

## `#ctx` Two-Layer Structure

```text
#ctx: #ModuleContext
│
├── runtime: #RuntimeContext          OPM-owned, schema-validated
│   ├── release     { name, namespace, uuid }
│   ├── module      { name, version, fqn, uuid }
│   ├── cluster     { domain }
│   ├── route?      { domain }
│   └── components  [name]: #ComponentNames
│
└── platform: { ... }                 Platform-team-owned, open struct
    ├── (any fields)                  No catalog constraints
    ├── e.g., defaultStorageClass     Convention-governed naming
    └── e.g., capabilities            Platform-specific metadata
```

## Provider Composition

```text
┌─────────────────────────────────────────────────────────────┐
│ #Platform.#providers (ordered)                              │
│                                                             │
│  [0] opm.#Provider           16 transformers   priority 1   │
│  [1] k8up.#Provider           4 transformers   priority 2   │
│  [2] certmgr.#Provider        3 transformers   priority 3   │
│  [3] kubernetes.#Provider    16 transformers   priority 4   │
└────────────────────────────┬────────────────────────────────┘
                             │ CUE struct unification (by FQN key)
                             ▼
┌─────────────────────────────────────────────────────────────┐
│ #composedTransformers                                       │
│                                                             │
│  opmodel.dev/.../deployment-transformer@v1    (from opm)    │
│  opmodel.dev/.../service-transformer@v1       (from opm)    │
│  opmodel.dev/.../schedule-transformer@v1      (from k8up)   │
│  opmodel.dev/.../certificate-transformer@v1   (from cert)   │
│  ...                                                        │
│  Total: union of all provider transformer maps              │
├─────────────────────────────────────────────────────────────┤
│ FQN collision ──▶ CUE unification error (correct behavior) │
│ Multi-match    ──▶ priority order from #providers wins     │
└─────────────────────────────────────────────────────────────┘
```
