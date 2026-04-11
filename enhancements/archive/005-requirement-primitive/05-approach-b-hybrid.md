# Approach B: Hybrid

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Overview

Separate the concern into two layers:

1. **Traits** declare the contract (module author writes these)
2. **PolicyRules** enforce compliance (platform team writes these)

This approach keeps each primitive type within its natural semantics: traits describe capabilities, policies govern them.

---

## Schema: `#BackupTrait` (contract)

```cue
#BackupTrait: prim.#Trait & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/traits/data"
        version:    "v1"
        name:       "backup"
        description: "Declares periodic backup for a component's persistent data"
        labels: {
            "trait.opmodel.dev/category": "data"
        }
    }
    appliesTo: [...]  // Any component with persistent data
    spec: close({backup: #BackupSchema})
}
```

The `#BackupSchema` is identical to `#BackupPolicySchema` from [Approach A](04-approach-a-pure-policy.md) minus the enforcement wrapper:

```cue
#BackupSchema: {
    // What to protect
    targets: [...{
        volume!:   string
        mountPath: string
    }]

    // How to prepare for a consistent snapshot
    preBackupHook?: {
        image!:   string
        command!: [...string]
        volumeMount?: {
            volume!:   string
            mountPath: *"/data" | string
        }
    }

    // Scheduling and retention
    schedule:      *"0 2 * * *" | string
    checkSchedule: *"0 4 * * 0" | string
    pruneSchedule: *"0 5 * * 0" | string
    retention: {
        keepDaily:   *7 | int
        keepWeekly:  *4 | int
        keepMonthly: *6 | int
    }

    // Backend
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

---

## Schema: `#RestoreTrait` (contract)

```cue
#RestoreTrait: prim.#Trait & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/traits/data"
        version:    "v1"
        name:       "restore"
        description: "Declares how the platform should restore this component from backup"
        labels: {
            "trait.opmodel.dev/category": "data"
        }
    }
    appliesTo: [...]  // Any component with backup trait
    spec: close({restore: #RestoreSchema})
}
```

The `#RestoreSchema` is identical to `#RestorePolicySchema` from [Approach A](04-approach-a-pure-policy.md):

```cue
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

---

## Schema: `#BackupCompliancePolicyRule` (enforcement)

```cue
#BackupCompliancePolicyRule: prim.#PolicyRule & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/policies/data"
        version:    "v1"
        name:       "backup-compliance"
        description: "Enforces that targeted components have backup and restore traits"
    }
    enforcement: {
        mode:        "deployment"
        onViolation: "block"
    }
    spec: close({backupCompliance: {
        // Validates that targeted components have both backup and restore traits
        requireBackupTrait:  *true | bool
        requireRestoreTrait: *true | bool
    }})
}
```

---

## Composition

The traits compose into the component spec (like Scaling, Expose, etc.):

```cue
jellyfin: component.#Component & backup.#BackupTrait & restore.#RestoreTrait & {
    spec: {
        // From BackupTrait
        backup: {
            targets: [{volume: "config", mountPath: "/config"}]
            preBackupHook: {
                image: "alpine:3.19"
                command: ["sh", "-c", "apk add --no-cache sqlite && sqlite3 ..."]
            }
            backend: values.backup.backend
            // schedule, retention use defaults
        }
        // From RestoreTrait
        restore: {
            targets: [{volume: "config", mountPath: "/config"}]
            healthCheck: { path: "/health", port: 8096 }
        }
    }
}
```

The compliance policy is applied separately by the platform team to enforce that all stateful workloads have both traits.

---

## Discussion: Traits as Contracts

Traits in OPM are defined as "behavioral modifiers that express preferences." Backup and restore stretch this: they are not preferences, they are **operational contracts**. A trait like `#Scaling` says "I prefer 3 replicas" — the platform may or may not honor it. A restore policy says "here is the contract for bringing me back" — the platform *must* honor it for DR to work.

This works within the existing model if we accept that some traits carry stronger semantics than others. The alternative is a new primitive type — see [02-design.md](02-design.md) for the open question.
