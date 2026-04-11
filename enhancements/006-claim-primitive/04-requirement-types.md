# Requirement Types — `#Requires` Construct

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

---

## Overview

Requirement types define operational contracts — things the platform must do for the module. Unlike interfaces, requirements target components via `appliesTo` and do not expose wirable fields.

This document defines the initial requirement types. Schemas are carried forward from enhancement 005 (requirement primitive).

---

## Data Protection Requirements

### `#BackupRequirement`

```cue
#BackupRequirement: prim.#Requirement & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/requirements/data"
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

### `#RestoreRequirement`

```cue
#RestoreRequirement: prim.#Requirement & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/requirements/data"
        version:    "v1"
        name:       "restore"
        description: "Declares how the platform should restore this component from backup"
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

---

## Network Requirements

### `#SharedNetworkRequirement`

Migrated from `#PolicyRule` — this is a module-author declaration, not a platform governance rule.

```cue
#SharedNetworkRequirement: prim.#Requirement & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/requirements/network"
        version:    "v1"
        name:       "shared-network"
        description: "Declares that targeted components share a network namespace"
    }
    #spec: close({sharedNetwork: #SharedNetworkSchema})
}

#SharedNetworkSchema: {
    networkConfig: {
        dnsPolicy: *"ClusterFirst" | "Default" | "None"
        dnsConfig?: {
            nameservers: [...string]
            searches: [...string]
            options: [...{
                name:   string
                value?: int
            }]
        }
    }
}
```

---

## Future Requirement Types

| Requirement | Module declares | Platform fulfills |
|-------------|----------------|-------------------|
| `#DnsRequirement` | "I need a DNS record for this hostname" | Creates DNS record via external-dns, Route53, etc. |
| `#CertificateRequirement` | "I need a TLS certificate for these domains" | Provisions via cert-manager, ACME, etc. |
| `#StorageRequirement` | "I need persistent storage with these characteristics" | Provisions PV/PVC with appropriate storage class |

These are not designed in this enhancement but validate that `#Requirement` is a general-purpose primitive.
