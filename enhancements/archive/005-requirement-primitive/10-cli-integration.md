# CLI Integration — Backup & Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Overview

The CLI gains a new command group under `opm release` that reads backup and restore declarations from rendered releases and orchestrates operations against the cluster. This document describes the command surface and execution flow, independent of which catalog approach (A, B, or C) is chosen — all produce the same data in the rendered release.

> **Note:** Approach C (Pure Trait) does not include a restore declaration. If Approach C is chosen, `opm release restore` would require a follow-up enhancement to add restore support. The `opm release backup` and `opm release snapshots` commands work with all approaches.

## Command Surface

### `opm release restore`

```
opm release restore <release.cue> --snapshot <id> [flags]

Flags:
  --snapshot string       Snapshot ID to restore (required)
  --scenario string       Restore scenario: "inPlace" or "disasterRecovery" (default: "inPlace")
  --dry-run               Show what would happen without executing
  --force                 Skip confirmation prompt
  --timeout duration      Timeout for restore operation (default: 10m)
  --kubeconfig string     Path to kubeconfig
  --context string        Kubernetes context
  --namespace string      Override target namespace
```

### `opm release backup`

```
opm release backup <release.cue> [flags]

Flags:
  --wait                  Wait for backup to complete (default: true)
  --timeout duration      Timeout for backup operation (default: 10m)
```

### `opm release snapshots`

```
opm release snapshots <release.cue|name> [flags]

Flags:
  --output string         Output format: "table" or "json" (default: "table")
```

## Execution Flow: In-Place Restore

When the operator runs:
```
opm release restore releases/.../jellyfin/release.cue --snapshot 574dc25a
```

The CLI executes:

1. **Render** the release to extract backup and restore declarations from component specs
2. **Resolve** component-level volume names to concrete K8s PVC names using the inventory
3. **Resolve** workload references to concrete K8s resource names using the inventory
4. **Prompt** the operator for confirmation (unless `--force`)
5. **Scale down** the workload(s) listed in the restore declaration
6. **Wait** for pods to terminate
7. **Apply** a K8up Restore CR targeting the resolved PVC(s) with the specified snapshot
8. **Wait** for the K8up Restore to reach `condition=completed`
9. **Scale up** the workload(s) back to their original replica count
10. **Wait** for pods to reach ready state
11. **Health check** using the declared HTTP path and port
12. **Report** success or failure

## Execution Flow: Disaster Recovery

When the operator runs:
```
opm release restore releases/.../jellyfin/release.cue \
  --snapshot 574dc25a --scenario disasterRecovery
```

The CLI executes:

1. **Render** the release to extract declarations
2. **Check** if the target namespace exists; if not, create it
3. **Identify** required secrets from the backup backend config
4. **Prompt** the operator for secret values (or accept `--secrets-from <file>`)
5. **Create** secrets in the namespace, labeled with `app.kubernetes.io/managed-by: open-platform-model` if the declaration specifies `managedByOPM: true`
6. **Create** the target PVC(s) with correct size, storage class, and OPM management labels
7. **Apply** K8up Restore CR
8. **Wait** for restore completion
9. **Run** `opm release apply` on the same release file (full redeploy)
10. **Wait** for workload ready
11. **Health check**
12. **Report** success or failure

## Inventory Integration

The CLI uses the existing `ReleaseInventoryRecord` to resolve symbolic references:

| Declaration reference | Resolved via |
|-----------------|-------------|
| Volume name `"config"` | Inventory entry with `Kind: PersistentVolumeClaim`, `Component: "jellyfin"` |
| Workload reference | Inventory entry with `Kind: StatefulSet` or `Kind: Deployment`, matched by component |
| Backup schedule | Inventory entry with `Kind: Schedule` (K8up) |

For disaster recovery (no inventory exists), the CLI renders the release to compute what the resource names *would be*, then creates prerequisites accordingly.

## Error Handling

| Failure | CLI behavior |
|---------|-------------|
| No restore declaration in release | Error: "release does not declare a restore policy" |
| Snapshot not found | Error: "snapshot <id> not found in repository" |
| Scale-down timeout | Error with rollback: scale workload back up |
| Restore CR fails | Error: print K8up restore logs |
| Health check fails after restore | Warning: "restore completed but health check failed — investigate manually" |
| DR: secret values not provided | Error: prompt for values or `--secrets-from` |

## Relationship to poc-controller

The controller can implement the same execution flows by:

1. Watching for a custom `RestoreRequest` CR (OPM-level, not K8up-level)
2. Reading the restore declaration from the rendered release (same CUE evaluation)
3. Executing the same sequence of steps as the CLI

The declaration is the shared contract; the CLI and controller are independent executors.
