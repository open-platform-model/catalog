# CLI Integration — `#Directive` Primitive: Backup & Restore

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Accepted         |
| **Created** | 2026-04-02       |
| **Authors** | OPM Contributors |

---

## Overview

The OPM CLI reads `#BackupDirective` from module policies to provide backup management commands. The CLI evaluates the module's CUE, discovers policies with backup directives, and uses the directive's S3 backend config to interact with Restic repositories.

---

## Directive Discovery

The CLI discovers backup directives by:

1. Evaluating the module release CUE (module + release values)
2. Iterating `#policies` on the resolved module
3. For each policy, checking `#directives` for the `#BackupDirective` FQN
4. Extracting the directive's `spec.backup` schema with concrete values from the release

This gives the CLI:
- Which components have backup configured
- S3 backend credentials for accessing the Restic repository
- Restore requirements (health check, scale-down)

---

## Commands

### `opm backup list <release>`

List all components with backup directives in a release.

```
$ opm backup list kind-opm-dev/jellyfin

Component     Schedule       Targets                  Hook     Restore
jellyfin      0 2 * * *      jellyfin-config:/config  sqlite   yes
```

Fields:
- **Component**: component name from `appliesTo`
- **Schedule**: backup cron schedule
- **Targets**: PVC name and mount path
- **Hook**: "none" if no `preBackupHook`, otherwise a short description derived from the image/command
- **Restore**: "yes" if `restore` block is present, "no" otherwise

### `opm backup snapshots <release> [component]`

Browse Restic snapshots using the S3 backend from the directive.

```
$ opm backup snapshots kind-opm-dev/jellyfin jellyfin

ID        Date                 Host          Paths          Size
a1b2c3d4  2026-04-01 02:00:05  jellyfin-0    /config        1.2 GiB
e5f6g7h8  2026-03-31 02:00:03  jellyfin-0    /config        1.2 GiB
i9j0k1l2  2026-03-30 02:00:04  jellyfin-0    /config        1.1 GiB
```

Implementation:
1. Resolve S3 credentials from release values (read secrets from cluster if needed)
2. Use the Restic library or CLI to list snapshots from the configured repository
3. Display snapshot metadata

### `opm backup browse <release> <component> --snapshot <id> [path]`

Navigate the file tree within a specific snapshot.

```
$ opm backup browse kind-opm-dev/jellyfin jellyfin --snapshot a1b2c3d4 /config/data

Type  Name             Size      Modified
dir   cache/           -         2026-04-01 01:59:30
file  jellyfin.db      48.2 MiB  2026-04-01 01:59:55
file  library.db       892 MiB   2026-04-01 01:59:55
dir   metadata/        -         2026-03-28 14:22:10
dir   plugins/         -         2026-03-15 09:30:00
```

### `opm backup restore <release> <component> --snapshot <id>`

Execute a restore procedure based on the directive's restore description.

```
$ opm backup restore kind-opm-dev/jellyfin jellyfin --snapshot a1b2c3d4

Restore plan for jellyfin (kind-opm-dev/jellyfin):
  1. Scale down jellyfin deployment to 0 replicas
  2. Create K8up Restore CR targeting PVC jellyfin-config from snapshot a1b2c3d4
  3. Wait for restore to complete
  4. Scale up jellyfin deployment to original replica count
  5. Verify health check: GET :8096/health

Proceed? [y/N] y

[1/5] Scaling down jellyfin... done
[2/5] Creating K8up Restore CR... done
[3/5] Waiting for restore... done (2m 15s)
[4/5] Scaling up jellyfin... done
[5/5] Verifying health... healthy

Restore complete.
```

Restore procedure derived from the directive:

1. If `restore.requiresScaleDown` is true: scale the workload to 0 replicas
2. Create a K8up Restore CR targeting each PVC in `targets` from the specified snapshot
3. Monitor restore status
4. Scale workload back to original replica count
5. If `restore.healthCheck` is set: poll the health endpoint until it returns 200

### `opm backup download <release> <component> --snapshot <id> <path>`

Download a file or directory from a snapshot.

```
$ opm backup download kind-opm-dev/jellyfin jellyfin --snapshot a1b2c3d4 /config/data/library.db

Downloading library.db (892 MiB)... done
Saved to ./library.db
```

Directories are downloaded as tar.gz archives.

---

## Authentication

The CLI resolves S3 credentials from the release values. When credentials reference Kubernetes secrets (`{secretName, remoteKey}`), the CLI reads them from the cluster using the current kubeconfig context.

The Restic repository password is similarly resolved from the release values.

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| No backup directive found | Error: "No backup directive found for component 'X' in release 'Y'" |
| S3 backend unreachable | Error: "Cannot connect to S3 endpoint: {endpoint}. Check network and credentials." |
| Secret not found in cluster | Error: "Secret '{secretName}' not found in namespace '{namespace}'. Ensure the secret exists." |
| Restore health check fails | Warning: "Health check failed after restore. Workload may need manual intervention." |
| Snapshot not found | Error: "Snapshot '{id}' not found in repository." |
| No restore block defined | Warning: "No restore description found. Creating K8up Restore CR without automated procedure." |
