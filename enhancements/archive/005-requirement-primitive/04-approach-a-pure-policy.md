# Approach A: Pure Policy

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Overview

Use the existing `#PolicyRule` primitive to model both backup and restore contracts. This approach stays within the current primitive taxonomy but may require expanding what `#PolicyRule` means.

---

## Schema: `#BackupPolicyRule`

```cue
#BackupPolicyRule: prim.#PolicyRule & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/policies/data"
        version:    "v1"
        name:       "backup"
        description: "Declares periodic backup for a component's persistent data"
    }

    enforcement: {
        mode:        "deployment"  // Validated at deploy time, not runtime
        onViolation: "block"       // Missing backup config blocks deployment
        // Note: enforcement semantics may need expansion — see discussion below
    }

    spec: close({backup: #BackupPolicySchema})
}

#BackupPolicySchema: {
    // What to protect
    targets: [...{
        volume!:   string          // Component-level volume name
        mountPath: string          // Where the volume is mounted
    }]

    // How to prepare for a consistent snapshot
    preBackupHook?: {
        image!:   string           // Container image with backup tooling
        command!: [...string]      // Command to run (e.g., SQLite WAL checkpoint)
        volumeMount?: {
            volume!:   string      // Which volume to mount into the hook container
            mountPath: *"/data" | string
        }
    }

    // Scheduling and retention contract
    schedule:      *"0 2 * * *" | string
    checkSchedule: *"0 4 * * 0" | string
    pruneSchedule: *"0 5 * * 0" | string
    retention: {
        keepDaily:   *7 | int
        keepWeekly:  *4 | int
        keepMonthly: *6 | int
    }

    // Backend — provided by the release, not the module
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

## Schema: `#RestorePolicyRule`

```cue
#RestorePolicyRule: prim.#PolicyRule & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/policies/data"
        version:    "v1"
        name:       "restore"
        description: "Declares how the platform should restore this component from backup"
    }

    enforcement: {
        mode:        "deployment"
        onViolation: "warn"        // Missing restore policy warns but does not block
    }

    spec: close({restore: #RestorePolicySchema})
}

#RestorePolicySchema: {
    // What to restore — references volumes declared in the component
    targets: [...{
        volume!:   string          // Component-level volume name
        mountPath: string          // Where the volume is mounted
    }]

    // Health verification after restore
    healthCheck: {
        path!: string              // HTTP path (e.g., "/health")
        port!: int                 // Container port
    }

    // Scenario: in-place restore (workload and PVC exist)
    inPlace: {
        requiresScaleDown: *true | bool
    }

    // Scenario: full disaster recovery (namespace gone)
    disasterRecovery: {
        // The managedByOPM flag tells the platform to label manually-created
        // resources with app.kubernetes.io/managed-by: open-platform-model
        // so that opm release apply can adopt them.
        managedByOPM: *true | bool
    }
}
```

---

## Composition

Policies group `#PolicyRule` instances and target them to components via `appliesTo`:

```cue
#Policy & {
    metadata: name: "data-protection"

    #rules: {
        (#BackupPolicyRule.metadata.fqn):  #BackupPolicyRule
        (#RestorePolicyRule.metadata.fqn): #RestorePolicyRule
    }

    appliesTo: {
        matchLabels: {
            "core.opmodel.dev/workload-type": "stateful"
        }
    }
}
```

---

## Discussion: PolicyRule Scope Expansion

The existing `#PolicyRule` primitive was designed for governance — "every stateful workload must have resource limits." The `enforcement` field (`mode`, `onViolation`) reflects this: it describes what happens when a rule is *violated*.

Using PolicyRule for backup/restore stretches this meaning. A BackupPolicy is not primarily about enforcement — it is a **contract declaration**. The `enforcement` field becomes awkward: what does `onViolation: "block"` mean for a restore policy? "Block the restore if the policy is missing"? That is enforcement of the *existence* of a policy, not enforcement of the policy itself.

This approach may require expanding `#PolicyRule` to support contract semantics alongside enforcement semantics, or it may indicate that a new primitive is warranted.
