# CLI Integration — Unified K8up Backup Directive

## Overview

The OPM CLI reads the `restore` block from `#K8upBackupDirective` to provide backup browsing and restore commands. It uses the `repository` block from the same directive to connect to the backing Restic/Kopia repository. The `#K8upBackupDirective`'s scheduling fields (`schedule`, `checkSchedule`, `pruneSchedule`, `retention`) are ignored by the CLI — they only concern the transformer.

Restore is CLI-driven and human-in-the-loop (D25). The controller does not orchestrate restore; it yields to the CLI via a `coordination.k8s.io/v1` Lease (D24). The CLI's real responsibilities during restore are cluster mutation (workload scaling), external tool invocation (Restic/Kopia), and S3 access.

---

## Directive Discovery

To serve any backup/restore command, the CLI:

1. Evaluates the ModuleRelease CUE (module + release values).
2. Iterates `#policies` on the resolved module.
3. For each policy, checks `#directives` for the `#K8upBackupDirective` FQN.
4. Extracts the concrete `spec.k8upBackup` (with `repository` and `restore` populated from release values).

In v1, **at most one** `#K8upBackupDirective` may appear across a module's policies (see 07-open-questions.md Q3). The CLI fails fast if it finds more than one.

From the extracted value the CLI derives:

- Repository connection — `repository.s3`, `repository.password`, `repository.format`.
- Components in scope — keys of `restore`.
- Per-component restore procedure — `requiresScaleDown`, `healthCheck`.
- Restore order — definition order of `restore` keys.

---

## Commands

### `opm backup list <release>`

Show whether a release has a backup directive and summarize its shape. Does not connect to the repository.

```
$ opm backup list kind-opm-dev/jellyfin

Repository: restic @ s3://garage-garage.garage.svc:3900/jellyfin-backups

Component     ScaleDown  HealthCheck
jellyfin      yes        :8096/health
```

For multi-component modules, restore order is shown:

```
$ opm backup list kind-opm-dev/myapp

Repository: restic @ s3://garage-garage.garage.svc:3900/myapp-backups

#  Component     ScaleDown  HealthCheck
1  database      yes        -
2  app           no         :8080/healthz
```

### `opm backup snapshots <release> [component]`

Browse snapshots in the repository.

```
$ opm backup snapshots kind-opm-dev/jellyfin

ID        Date                 Host          Paths          Size
a1b2c3d4  2026-04-01 02:00:05  jellyfin-0    /config        1.2 GiB
e5f6g7h8  2026-03-31 02:00:03  jellyfin-0    /config        1.2 GiB
i9j0k1l2  2026-03-30 02:00:04  jellyfin-0    /config        1.1 GiB
```

Implementation:
1. Read `repository.format` to pick `restic` or `kopia`.
2. Resolve S3 credentials + repository password (read referenced Secrets from the cluster when they are references, not literals).
3. Connect and list snapshots.

### `opm backup browse <release> <component> --snapshot <id> [path]`

Navigate the file tree within a specific snapshot.

```
$ opm backup browse kind-opm-dev/jellyfin jellyfin --snapshot a1b2c3d4 /config/data

Type  Name             Size      Modified
dir   cache/           -         2026-04-01 01:59:30
file  jellyfin.db      48.2 MiB  2026-04-01 01:59:55
file  library.db       892 MiB   2026-04-01 01:59:55
dir   metadata/        -         2026-03-28 14:22:10
```

### `opm backup download <release> <component> --snapshot <id> <path>`

Download a file or directory from a snapshot to the local workstation.

```
$ opm backup download kind-opm-dev/jellyfin jellyfin --snapshot a1b2c3d4 /config/data/library.db

Downloading library.db (892 MiB)... done
Saved to ./library.db
```

Directories download as `.tar.gz`.

### `opm restore run <release> [component] --snapshot <id>`

Execute a restore. This is the command that mutates the cluster.

```
$ opm restore run kind-opm-dev/jellyfin --snapshot a1b2c3d4

Restore plan (1 component):
  1. jellyfin: acquire lease → scale down → restore config → scale up → health check :8096/health → release lease

Proceed? [y/N] y

Acquired lease opm-restore-jellyfin (60s / renew 20s)

[jellyfin]
  Scaling down... done
  Restoring volume config from snapshot a1b2c3d4... done (2m 15s)
  Scaling up... done
  Health check :8096/health... healthy

Released lease opm-restore-jellyfin

Restore complete.
```

Multi-component restores follow the directive's definition order:

```
$ opm restore run kind-opm-dev/myapp --snapshot a1b2c3d4

Restore plan (2 components, ordered):
  1. database: scale down → restore data → scale up
  2. app: restore uploads → health check :8080/healthz

Proceed? [y/N] y

Acquired lease opm-restore-myapp (60s / renew 20s)

[1/2 database]
  Scaling down... done
  Restoring volume data from snapshot a1b2c3d4... done (5m 30s)
  Scaling up... done

[2/2 app]
  Restoring volume uploads from snapshot a1b2c3d4... done (1m 12s)
  Health check :8080/healthz... healthy

Released lease opm-restore-myapp

Restore complete.
```

---

## Restore Procedure

For each component in `restore` (in definition order):

1. If `requiresScaleDown` is true: scale the component's workload(s) to 0 replicas; wait for pod termination.
2. For each volume mounted by the component, invoke the backup tool (`restic`/`kopia`) with the chosen snapshot to restore file content into the PVC.
3. If the workload was scaled down, scale back up to the original replica count.
4. If `healthCheck` is set, poll the endpoint until it returns 2xx or the timeout expires.

Between steps 1 and 3, the controller must not intervene — the Lease described next is how that is guaranteed.

---

## Lease-Based Pause

The CLI acquires a `coordination.k8s.io/v1` Lease for the duration of `opm restore run`. The controller's reconcile loop checks the Lease and skips reconcile while it is held and unexpired. Once the Lease is released (or expires after a CLI crash), the controller resumes normal reconcile.

### Acquisition

```
apiVersion: coordination.k8s.io/v1
kind: Lease
metadata:
  name:      opm-restore-<release-name>        # proposed; see Q2
  namespace: <release-namespace>               # proposed; see Q2
spec:
  holderIdentity:       "opm-cli@<user>@<host>"
  leaseDurationSeconds: 60                     # baseline; tune via measurement
  acquireTime:          <RFC3339>
  renewTime:            <RFC3339>
```

The CLI renews the Lease every ~20s during restore. If the CLI crashes mid-restore, the Lease expires after `leaseDurationSeconds` and the controller resumes.

### Release

On successful completion, the CLI deletes the Lease. On normal user cancel (Ctrl-C), the CLI releases the Lease and attempts a best-effort cleanup of partial state before exiting.

### Stale-lock recovery

If a prior run crashed without releasing (e.g., kill -9), the Lease still auto-expires. If a user genuinely needs to interrupt a healthy in-progress restore from another terminal, they delete the Lease manually (`kubectl delete lease opm-restore-<release-name>`). See 07-open-questions.md Q2 for the open design points on naming, duration, namespace, and explicit override flags.

### RBAC

The CLI needs `create`, `get`, `update`, and `delete` on `leases.coordination.k8s.io` in the target namespace. If the user's kubeconfig does not grant those verbs, the CLI fails with a clear error before starting the restore procedure.

---

## Authentication

The CLI resolves credentials from the directive's `repository` block:

1. Read `repository.s3.endpoint`, `.bucket` as literals.
2. For `accessKeyID`, `secretAccessKey`, and `password`, follow the `schemas.#Secret` discriminator:
   - OPM-managed references (the `$opm` discriminator is set): read the referenced Secret from the cluster via kubeconfig.
   - Plain `{name, key}`: read the Secret directly.
3. Select the backup tool based on `repository.format`.

---

## Error Handling

| Scenario | Behavior |
|---|---|
| No `#K8upBackupDirective` in release | Error: `No backup directive found in release 'X'` |
| More than one `#K8upBackupDirective` in release | Error: `Multiple backup directives found — only one is allowed per module (see enhancement 009 Q3)` |
| Repository unreachable | Error: `Cannot connect to repository at {endpoint}. Check network and credentials.` |
| Secret referenced but not found in cluster | Error: `Secret '{secretName}' not found in namespace '{namespace}'.` |
| Unsupported format | Error: `Repository format '{format}' not supported. Install the required tool.` |
| Snapshot not found | Error: `Snapshot '{id}' not found in repository.` |
| Component not in `restore` block | Error: `Component '{name}' not listed in the directive's restore block.` |
| Cannot acquire Lease (held by another process) | Error: `Another restore is in progress for this release (lease held by {holder} until {renewTime}). Wait for it to finish or delete the lease manually.` |
| RBAC denied on Lease | Error: `User lacks permission to manage leases in namespace '{namespace}'. Ask a cluster admin.` |
| Health check fails after restore | Warning: `Health check failed for '{component}' after restore. Workload may need manual intervention.` (Lease still released; workload left scaled up.) |

---

## Idempotency and Resume — v1 scope

`opm restore run` is not resumable in v1. A mid-run crash leaves the cluster in an intermediate state: the workload may be scaled down, the volume may be partially restored, the health check may never have run. Recovery is manual — inspect cluster state, decide whether to rerun the restore from the same snapshot, or to roll forward with a later snapshot.

Moving restore to a controller-orchestrated `RestoreJob` CRD (rejected for v1 in D25) is the path to robust resume. Revisit if restore frequency grows past "rare, high-stakes."

---

## What is not in scope for the CLI

- The `schedule`, `checkSchedule`, `pruneSchedule`, `retention` fields of the directive. These are transformer-only concerns.
- Pre-backup hooks. Those are `#PreBackupHookTrait` on the component, consumed by the K8up PreBackupPod transformer. The CLI does not invoke them during restore.
- Multi-release restore coordination. One release, one run.
