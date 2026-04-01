# Rendering Pipeline — `#Claim` Primitive

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

---

## Overview

Claims introduce a second rendering path alongside trait transformers. Data claims use a resolver for value injection. Operational claims use transformers for platform resource generation. Both are independent from the trait transformer pipeline.

## Two Independent Rendering Paths

```text
Path A: Traits (existing)       Path B: Claims (new)

Component spec                  Component spec
    |                               |
    v                               v
Trait Transformers              Claim Resolver (data claims)
    |                           Claim Transformers (operational claims)
    |                               |
    v                               v
K8s Deployment,                 Env vars with concrete values,
Service, HPA, etc.              K8up Schedule, PreBackupPod, etc.
```

**Path independence:** Traits do not know about claims. A `#BackupClaim` does not implicitly create resources in the trait pipeline. Each path can evolve independently.

## Data Claim Resolution

The claim resolver handles value injection for claims with `#shape`:

1. **Accept values** from ModuleRelease (external binding)
2. **Validate completeness** — all required shape fields have values
3. **Validate types** — values match `#shape` constraints
4. **Inject values** — concrete values flow to component spec references

```text
Render pipeline:
  1. CUE evaluation: Module + Release values unified
     spec.postgres.host = "pg.svc.cluster.local" (from release values)

  2. Claim validation:
     All required fields in #PostgresClaim.#shape fulfilled? [x]
     Type constraints satisfied? [x]

  3. Component rendering:
     spec.container.env.DB_HOST = "pg.svc.cluster.local" (resolved)

  4. Trait transformer pass: generates K8s Deployment, Service, etc.
  5. Claim transformer pass: generates K8up Schedule, etc.
```

## Operational Claim Transformation

Operational claims (no `#shape`) use transformers that match via FQN:

```cue
#BackupTransformer: transformer.#Transformer & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/providers/kubernetes/transformers"
        name:       "backup-transformer"
    }
    requiredClaims: {
        (data.#BackupClaim.metadata.fqn): data.#BackupClaim
    }
    #transform: {
        #component: _
        #context:   transformer.#TransformerContext
        output: { /* K8up Schedule CR */ }
    }
}
```

## Orchestration Handling

Orchestrations in Policy are not rendered to platform resources by default. They are read by:

- **The CLI** for operation-time commands (`opm release restore`)
- **The controller** for automated orchestration (future)
- **Transformers** when the orchestration produces deploy-time resources (e.g., `#SharedNetworkOrchestration` generates NetworkPolicy)

## Combined Example

```text
Jellyfin module with #BackupClaim + #PostgresClaim + #RestoreOrchestration:

1. Claim resolver:
   spec.postgres.host -> "pg.svc.cluster.local" (from release values)
   spec.postgres.port -> 5432

2. Trait transformers:
   StatefulsetTransformer -> StatefulSet (with resolved env vars)
   ServiceTransformer -> Service

3. Claim transformers:
   BackupTransformer -> K8up Schedule + PreBackupPod

4. Orchestration (not rendered):
   RestoreOrchestration -> registered with CLI for opm release restore
```

## Transformer Registration

Claim transformers are linked to their corresponding `#Offer` definitions. A capability provider (K8up, Velero) packages the Offer with its Transformers. The Provider derives its transformer registry from its Offers:

```cue
// Offer carries its transformers (enhancement 007)
#K8upBackupOffer: ops.#BackupOffer & {
    #transformers: {
        (schedule_t.metadata.fqn):    schedule_t
        (prebackup_t.metadata.fqn):   prebackup_t
    }
}

// Provider derives transformers from offers
#K8upProvider: provider.#Provider & {
    #offers: {
        (#K8upBackupOffer.metadata.fqn): #K8upBackupOffer
    }
    #transformers: {
        for _, o in #offers {
            if o.#transformers != _|_ {
                o.#transformers
            }
        }
    }
}
```

Claim transformers register alongside trait transformers in the composed provider:

```cue
// Platform composes all providers (enhancement 008)
#Platform & {
    #providers: [opm.#Provider, k8up.#Provider, kubernetes.#Provider]
    // #composedTransformers includes both trait and claim transformers
}
```

## Note: Resolver Design Needs Investigation

The exact mechanism for data claim value injection depends on the CUE late-binding spike (see 05-fulfillment.md). The rendering pipeline design is stable regardless — the resolver sits between value provision and component rendering.
