# K8up CUE Module

## Summary

CUE type definitions and passthrough transformers for K8up backup operator resources. This module allows OPM modules to declare K8up Schedule, PreBackupPod, Backup, and Restore resources that render as native K8up CRs with OPM context applied.

## Contents

| Path | Description |
|---|---|
| `schemas/backup.cue` | Open schemas for all K8up CR types |
| `resources/backup/` | OPM resource definitions for Schedule, PreBackupPod, Backup, Restore |
| `providers/kubernetes/` | Passthrough transformers that render K8up CRs |

## Usage

Import the resource types in your module's `components.cue`:

```cue
import (
    k8up_backup "opmodel.dev/k8up/v1alpha1/resources/backup@v1"
)

#components: {
    "backup-schedule": {
        k8up_backup.#Schedule
        spec: schedule: spec: {
            backend: {
                repoPasswordSecretRef: { name: "restic-repo", key: "password" }
                s3: {
                    endpoint: "http://garage-s3:3900"
                    bucket: "backups"
                    accessKeyIDSecretRef: { name: "s3-creds", key: "access-key" }
                    secretAccessKeySecretRef: { name: "s3-creds", key: "secret-key" }
                }
            }
            backup: schedule: "0 2 * * *"
            check: schedule: "0 4 * * 0"
            prune: {
                schedule: "0 5 * * 0"
                retention: {
                    keepDaily: 7
                    keepWeekly: 4
                    keepMonthly: 6
                }
            }
        }
    }
}
```

## Design

Follows the gateway_api passthrough pattern — open schemas accept the full K8up CR spec, and transformers apply OPM name/namespace/labels without modifying the spec.
