# Backup Trait

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-28       |
| **Authors** | OPM Contributors |

---

## Current Backup Architecture

Backup support in OPM modules is implemented per-module. Each module that needs backup defines its own:

1. A `backup?:` optional config schema in `module.cue` (~20 lines)
2. Conditional K8up Schedule and PreBackupPod components in `components.cue` (~30 lines)
3. Direct imports of the K8up catalog (`opmodel.dev/k8up/v1alpha1`)

The config schema and component wiring are nearly identical across modules. The only meaningful differences are:

- The PVC name to back up
- The pre-backup hook commands (SQLite WAL checkpoint, RCON commands, pg_dump, or nothing)
- Minor schedule variations

---

## Duplication Across Modules

Jellyfin and Seerr both define the same backup config structure:

```cue
backup?: {
    configPvcName: string
    schedule: *"0 2 * * *" | string
    s3: {
        endpoint: string
        bucket: string
        accessKeyID: schemas.#Secret
        secretAccessKey: schemas.#Secret
    }
    repoPassword: schemas.#Secret
    retention: {
        keepDaily: *7 | int
        keepWeekly: *4 | int
        keepMonthly: *6 | int
    }
    checkSchedule: *"0 4 * * 0" | string
    pruneSchedule: *"0 5 * * 0" | string
}
```

Both modules then generate the same K8up Schedule structure from this config, with identical S3 backend wiring, identical retention mapping, and identical schedule propagation. The PreBackupPod differs only in the sqlite3 command targets.

---

## Maintenance Cost

Adding backup to a new module requires:

1. Copying the backup config schema from an existing module
2. Copying the K8up Schedule component generation logic
3. Adapting the PreBackupPod for the new application's consistency requirements
4. Adding the K8up catalog as a module dependency
5. Testing the full integration

Steps 1, 2, and 4 are pure boilerplate. Any fix or improvement to the backup pattern (e.g., adding podSecurityContext support, changing retention defaults) must be applied to every module individually.

---

## Implementation Coupling

Each module directly imports K8up catalog resources and constructs K8up-specific CRs. This means:

- Modules are coupled to K8up as the backup provider
- The backup "contract" (what the module author cares about) is entangled with the backup "implementation" (K8up Schedule/PreBackupPod specifics)
- Switching backup providers would require modifying every module

---

## Hook Diversity

Pre-backup hooks vary significantly across applications:

| Application | Hook type | What it does |
| --- | --- | --- |
| Jellyfin | SQLite WAL checkpoint | `sqlite3 PRAGMA wal_checkpoint(TRUNCATE)` on 2 databases |
| Seerr | SQLite WAL checkpoint | Same, 1 database, conditional on no PostgreSQL |
| Minecraft | RCON command | `rcon save-all`, `rcon save-off` before backup, `rcon save-on` after |
| PostgreSQL app | pg_dump | Dump database to file before PVC backup |
| Static files | None | Just back up the PVC as-is |

A generic solution must support all of these without requiring the backup trait to understand each application's specifics.

---

## File Ownership and Permissions

K8up uses Restic under the hood. Restic preserves file ownership (UID/GID) and permissions in backup metadata. However, restoring ownership requires the restore pod to run as root. K8up's official recommendation is to use `podSecurityContext` with `fsGroup` and `fsGroupChangePolicy: OnRootMismatch` for volume access, but this does not guarantee UID/GID restoration.

A generic backup trait should allow configuring the security context for backup and restore pods, but this is deferred to a future iteration.
