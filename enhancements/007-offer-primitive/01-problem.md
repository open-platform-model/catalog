# Problem Statement — `#Offer` Primitive

## Current State

Enhancement 006 introduced `#Claim` as a component-level primitive: "what does this component need from the platform?" Enhancement 008 introduced `#Platform` as a composition construct that merges providers and their transformers. The `#Transformer` gained `requiredClaims`/`optionalClaims` for matcher-based claim routing, and `#Provider` gained `#declaredClaims` auto-computation.

Claims are fulfilled through two paths: operational claims are fulfilled by transformer matching (e.g., K8up's `BackupTransformer` matches components with `#BackupClaim`), and data claims are fulfilled by external binding in `ModuleRelease` values.

There is no mechanism for a module to declare what it provides to the platform.

## Gap 1: No Capability Declaration

When K8up is installed on a cluster, it brings backup and restore capabilities. But the K8up module definition has no way to say "I provide backup capability." The platform has no way to know what an installed module contributes beyond its transformers.

| Direction | Primitive | Level | Status |
|-----------|-----------|-------|--------|
| "I need X" | `#Claim` | Component | Exists (006) |
| "I provide X" | ??? | Module | Missing |

Without an explicit capability declaration, the platform cannot answer: "What capabilities are available?" or "Can this module's claims be satisfied?"

## Gap 2: Platform Cannot Validate Claim Fulfillment at Install Time

Enhancement 008's `unhandledClaims` detects claims that no transformer handles — but only at render time. There is no install-time validation:

```text
# What should happen when deploying a module:
1. Module declares #BackupClaim on a component
2. Platform checks: "Is backup capability offered by any installed module?"
3. If not: reject or warn before rendering

# What actually happens:
1. Module declares #BackupClaim
2. Rendering proceeds
3. unhandledClaims warns AFTER the fact — no transformer matched
```

A future OPM Kubernetes controller needs pre-deployment validation. Without `#Offer`, the controller has no data source for "what can this platform do?"

## Gap 3: Capability Providers Cannot Package Everything Together

K8up, Velero, cert-manager, and similar projects want to ship a single OPM module that includes:

1. The Kubernetes operator (components)
2. The capability declaration ("I offer backup")
3. The transformers that implement it

Today, a module has `#components` and `#policies`. The transformers live on a separate `#Provider`. There is no place to declare the capability that ties them together. The module author must separately maintain the module and the provider with no formal link.

## Gap 4: No Web UI / Service Catalog Source

A platform dashboard should show installed capabilities:

```text
Platform: production
Capabilities:
  backup@v1      [x] offered by: k8up (v1.2.0)
  restore@v1     [x] offered by: k8up (v1.2.0)
  postgres@v1    [x] offered by: cnpg (v1.0.0)
  certificate@v1 [ ] not offered
  redis@v1       [ ] not offered
```

This requires a structured data source — not just transformer presence, but explicit declarations of what each module offers and which claim it satisfies.

## Concrete Example

K8up publishes an OPM module. Today:

```cue
// k8up/module.cue — what exists today
k8upModule: #Module & {
    #components: {
        "operator": #StatelessWorkload & {
            spec: container: image: "ghcr.io/k8up-io/k8up:v2"
        }
    }
}

// k8up/providers/kubernetes/provider.cue — separate, no formal link to module
#K8upProvider: provider.#Provider & {
    #transformers: {
        (schedule_t.metadata.fqn): schedule_t
        (prebackup_t.metadata.fqn): prebackup_t
    }
}
```

What should exist:

```cue
// k8up/module.cue — module declares its capabilities
k8upModule: #Module & {
    #components: {
        "operator": #StatelessWorkload & { ... }
    }
    #offers: {
        (ops.#BackupOffer.metadata.fqn):  #K8upBackupOffer
        (ops.#RestoreOffer.metadata.fqn): #K8upRestoreOffer
    }
}

// The offer carries its transformers — everything is linked
#K8upBackupOffer: ops.#BackupOffer & {
    #transformers: {
        (schedule_t.metadata.fqn): schedule_t
        (prebackup_t.metadata.fqn): prebackup_t
    }
}
```

## Why Existing Workarounds Fail

The only workaround is relying on transformer presence in `#Provider.#declaredClaims` as an implicit capability signal. This fails because:

- Data claims (Postgres, Redis, S3) have no transformers — `#declaredClaims` cannot detect them
- There is no structured link between the module that runs the operator and the provider that registers its transformers
- The CLI and future controller cannot distinguish "this claim has no transformer" from "this capability is not installed"
- No version information is associated with the implicit capability
