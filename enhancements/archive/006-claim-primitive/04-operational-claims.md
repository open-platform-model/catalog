# Operational Claims & Policy Orchestrations

## Overview

Operational claims are `#Claim` definitions without `#shape` — the platform acts on the component rather than injecting data. Policy orchestrations are `#Orchestration` definitions that coordinate across components at the module level.

---

## Component-Level Claims

### `#BackupClaim`

Declares that a component's persistent data needs periodic backup.

```cue
#BackupClaim: prim.#Claim & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/claims/data"
        version:    "v1"
        name:       "backup"
        description: "Declares periodic backup for a component's persistent data"
    }
    #spec: close({backup: #BackupSchema})
}

#BackupSchema: {
    targets: [...{
        volume!:   string
        mountPath: string
    }]
    preBackupHook?: {
        image!:   string
        command!: [...string]
        volumeMount?: {
            volume!:   string
            mountPath: *"/data" | string
        }
    }
    schedule:      *"0 2 * * *" | string
    checkSchedule: *"0 4 * * 0" | string
    pruneSchedule: *"0 5 * * 0" | string
    retention: {
        keepDaily:   *7 | int
        keepWeekly:  *4 | int
        keepMonthly: *6 | int
    }
    backend: {
        s3: {
            endpoint!:        string
            bucket!:          string
            accessKeyID!:     schemas.#Secret
            secretAccessKey!: schemas.#Secret
        }
        repoPassword!: schemas.#Secret
    }
}
```

### Usage in a component

```cue
jellyfin: #StatefulWorkload & data.#BackupClaim & {
    spec: {
        container: { image: repository: "linuxserver/jellyfin" }
        backup: {
            targets: [{volume: "config", mountPath: "/config"}]
            preBackupHook: {
                image: "alpine:3.19"
                command: ["sh", "-c", "apk add --no-cache sqlite && sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE);'"]
                volumeMount: {volume: "config", mountPath: "/config"}
            }
            backend: #config.backup.backend
        }
    }
}
```

### Usage in a Blueprint

```cue
#BackedUpStatefulWorkload: #Blueprint & {
    composedResources: { container, volumes }
    composedTraits: { scaling, healthCheck }
    composedClaims: {
        (data.#BackupClaim.metadata.fqn): data.#BackupClaim
    }
}
```

---

## Module-Level Orchestrations

### `#RestoreOrchestration`

Declares how the platform should restore the module — used by `opm release restore`.

```cue
#RestoreOrchestration: prim.#Orchestration & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/orchestrations/data"
        version:    "v1"
        name:       "restore"
        description: "Declares how the platform should restore targeted components from backup"
    }
    #spec: close({restore: #RestoreSchema})
}

#RestoreSchema: {
    targets: [...{
        volume!:   string
        mountPath: string
    }]
    healthCheck: {
        path!: string
        port!: int
    }
    inPlace: {
        requiresScaleDown: *true | bool
    }
    disasterRecovery: {
        managedByOPM: *true | bool
    }
}
```

### `#SharedNetworkOrchestration`

Declares that targeted components share a network namespace. Migrated from `#PolicyRule`.

```cue
#SharedNetworkOrchestration: prim.#Orchestration & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/orchestrations/network"
        version:    "v1"
        name:       "shared-network"
        description: "Declares that targeted components share a network namespace"
    }
    #spec: close({sharedNetwork: #SharedNetworkSchema})
}
```

### Usage in Policy

```cue
#Module & {
    #policies: {
        "restore-plan": #Policy & {
            appliesTo: components: ["jellyfin"]
            #orchestrations: {
                (ops.#RestoreOrchestration.metadata.fqn): ops.#RestoreOrchestration & {
                    #spec: restore: {
                        targets: [{volume: "config", mountPath: "/config"}]
                        healthCheck: { path: "/health", port: 8096 }
                        inPlace: { requiresScaleDown: true }
                        disasterRecovery: { managedByOPM: true }
                    }
                }
            }
        }
    }
}
```

---

## The Split: Component vs Module

| Concern | Level | Primitive | Why |
|---------|-------|-----------|-----|
| "Back up this component's /config" | Component | `#BackupClaim` | Single-component, Blueprint-composable |
| "How to restore the module after disaster" | Module (Policy) | `#RestoreOrchestration` | Cross-component, references order and health checks |
| "These components share networking" | Module (Policy) | `#SharedNetworkOrchestration` | Multi-component targeting |
| "I need a Postgres connection" | Component | `#PostgresClaim` | Single-component, Blueprint-composable |

**Rule of thumb:** If it describes *what a single component needs*, it's a Claim. If it describes *how multiple components coordinate*, it's an Orchestration in Policy.

---

## Future Types

| Type | Level | Primitive |
|------|-------|-----------|
| `#DnsClaim` | Component | "I need a DNS record" |
| `#CertificateClaim` | Component | "I need a TLS certificate" |
| `#StorageClaim` | Component | "I need persistent storage with these characteristics" |
| `#MigrationOrchestration` | Module (Policy) | "Run database migrations before starting the app" |
