# Problem Statement — `#Claim` Primitive & Policy Broadening

## Current State

OPM components are defined using three primitives: Resource ("what exists"), Trait ("how it behaves"), and Blueprint ("reusable pattern of Resources + Traits"). The platform team governs deployments using PolicyRules composed into Policies.

Module authors control the implementation of Resources and Traits — they specify the container image, the replica count, the health check path. But when a component needs something the *platform* must provide — a database connection, backup scheduling, a TLS certificate — there is no primitive for that.

## Gap 1: No Primitive for Platform-Fulfilled Needs

The litmus test: **who controls the implementation?**

| Primitive | Question | Who controls |
|-----------|----------|-------------|
| `#Resource` | "What must exist?" | Module author |
| `#Trait` | "How does it behave?" | Module author |
| `#Blueprint` | "What is the pattern?" | Module author |
| `???` | "What does it need from the platform?" | **Platform fulfills** |

When a module author writes `spec: container: image: "nginx"`, they control the implementation. When a module author says "I need a Postgres database," they declare the need — the platform decides whether it's RDS, Cloud SQL, or an in-cluster StatefulSet. This is a fundamentally different ownership model with no primitive to express it.

## Gap 2: Blueprint Cannot Compose Platform Needs

Enhancement 005 introduced `#Requirement` at the module level with `appliesTo` targeting. But module-level primitives cannot participate in Blueprints. This creates second-class primitives:

```cue
// This should be possible, but isn't with module-level requirements
#BackedUpStatefulWorkload: #Blueprint & {
    composedResources: { container, volumes }
    composedTraits: { scaling, healthCheck }
    composedRequirements: { backup }  // NOT POSSIBLE with module-level design
}
```

If Blueprints are OPM's composition mechanism for reusable patterns, every primitive should be composable in Blueprints.

## Gap 3: Policy Serves Only One Direction

`#Policy` currently contains `#PolicyRule` — governance from the platform team. But module authors also have cross-component concerns:

- "To restore this module, restore the database first, then the app, verify health"
- "These components need shared networking"

These are module-author declarations that span multiple components. Today, `#SharedNetwork` is modeled as a PolicyRule even though the module author writes it, misrepresenting ownership.

## Gap 4: Data Dependencies Are Hardcoded

```cue
// Current: no contract, no type safety, no platform fulfillment
spec: container: env: {
    DB_HOST:     { name: "DB_HOST",     value: "pg.svc.cluster.local" }
    DB_PASSWORD: { name: "DB_PASSWORD", value: "hardcoded-or-manual" }
}
```

No typed contract for "I need Postgres." The platform cannot validate, provision, or fulfill.

## Gap 5: Backup and Restore Are Manual

Backup requires hand-coded K8up components (~60 lines per module). Restore is a 12+ step manual `kubectl` procedure. Both were validated in a kind-opm-dev test battery (2026-03-28) that exposed hidden requirements like OPM management labels and secret recreation.

## Concrete Example

### What should exist:

```cue
// Blueprint composes the backup claim
#BackedUpStatefulWorkload: #Blueprint & {
    composedResources: { container, volumes }
    composedTraits: { scaling, healthCheck }
    composedClaims: { backup }
}

// Component uses the Blueprint + adds a Postgres claim
jellyfin: #BackedUpStatefulWorkload & data.#PostgresClaim & {
    spec: {
        container: { image: repository: "linuxserver/jellyfin" }
        backup: { targets: [{volume: "config"}], backend: #config.backup.backend }
        postgres: { /* platform fills host, port, password at deploy time */ }
        container: env: {
            DB_HOST: spec.postgres.host  // typed, CUE-validated
        }
    }
}

// Module-level policy orchestrates restore across components
#policies: {
    "restore-plan": #Policy & {
        appliesTo: components: ["jellyfin"]
        #orchestrations: {
            restore: #RestoreOrchestration & {
                healthCheck: { path: "/health", port: 8096 }
                disasterRecovery: { managedByOPM: true }
            }
        }
    }
}
```
