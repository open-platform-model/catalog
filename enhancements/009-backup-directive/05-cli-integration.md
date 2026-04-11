# CLI Integration — `#RestoreDirective`

## Overview

The OPM CLI reads `#RestoreDirective` from module policies to provide backup browsing and restore commands. The CLI evaluates the module's CUE, discovers the restore directive, and uses `repository` to connect to the backup repository. The `#K8upBackupDirective` is not read by the CLI — it is consumed only by the transformer.

---

## Directive Discovery

The CLI discovers the restore directive by:

1. Evaluating the module release CUE (module + release values)
2. Iterating `#policies` on the resolved module
3. For each policy, checking `#directives` for the `#RestoreDirective` FQN
4. Extracting `spec.restore` with concrete values from the release

This gives the CLI:
- Repository connection info (`repository.s3`, `repository.repoPassword`, `repository.format`)
- Which components have backups (`components` keys)
- What resources were backed up per component (`volumes`, `configMaps`, `secrets`)
- Restore procedures per component (`requiresScaleDown`, `healthCheck`)
- Restore order (definition order of `components`)

---

## Commands

### `opm restore list <release>`

List all components with restore directives in a release.

```
$ opm restore list kind-opm-dev/jellyfin

Repository: restic @ s3://garage-garage.garage.svc:3900/jellyfin-backups

Component     Volumes          ConfigMaps  Secrets  ScaleDown  HealthCheck
jellyfin      config           -           -        yes        :8096/health
```

For multi-component modules, restore order is shown:

```
$ opm restore list kind-opm-dev/myapp

Repository: restic @ s3://garage-garage.garage.svc:3900/myapp-backups

#  Component     Volumes     ConfigMaps   Secrets  ScaleDown  HealthCheck
1  database      data        -            -        yes        -
2  app           uploads     app-config   -        no         :8080/healthz
```

### `opm restore snapshots <release> [component]`

Browse snapshots in the repository.

```
$ opm restore snapshots kind-opm-dev/jellyfin

ID        Date                 Host          Paths          Size
a1b2c3d4  2026-04-01 02:00:05  jellyfin-0    /config        1.2 GiB
e5f6g7h8  2026-03-31 02:00:03  jellyfin-0    /config        1.2 GiB
i9j0k1l2  2026-03-30 02:00:04  jellyfin-0    /config        1.1 GiB
```

Implementation:
1. Read `repository.format` to select tool (restic or kopia)
2. Resolve S3 credentials from release values (read secrets from cluster if needed)
3. Connect to repository and list snapshots
4. Display snapshot metadata

### `opm restore browse <release> <component> --snapshot <id> [path]`

Navigate the file tree within a specific snapshot.

```
$ opm restore browse kind-opm-dev/jellyfin jellyfin --snapshot a1b2c3d4 /config/data

Type  Name             Size      Modified
dir   cache/           -         2026-04-01 01:59:30
file  jellyfin.db      48.2 MiB  2026-04-01 01:59:55
file  library.db       892 MiB   2026-04-01 01:59:55
dir   metadata/        -         2026-03-28 14:22:10
dir   plugins/         -         2026-03-15 09:30:00
```

### `opm restore run <release> [component] --snapshot <id>`

Execute a restore procedure based on the restore directive.

```
$ opm restore run kind-opm-dev/jellyfin --snapshot a1b2c3d4

Restore plan (1 component):
  1. jellyfin: scale down → restore config → scale up → health check :8096/health

Proceed? [y/N] y

[jellyfin]
  Scaling down... done
  Restoring volume config from snapshot a1b2c3d4... done (2m 15s)
  Scaling up... done
  Health check :8096/health... healthy

Restore complete.
```

For multi-component modules, the CLI follows definition order:

```
$ opm restore run kind-opm-dev/myapp --snapshot a1b2c3d4

Restore plan (2 components, ordered):
  1. database: scale down → restore data → scale up
  2. app: restore uploads, app-config → health check :8080/healthz

Proceed? [y/N] y

[1/2 database]
  Scaling down... done
  Restoring volume data from snapshot a1b2c3d4... done (5m 30s)
  Scaling up... done

[2/2 app]
  Restoring volume uploads from snapshot a1b2c3d4... done (1m 12s)
  Restoring configmap app-config... done
  Health check :8080/healthz... healthy

Restore complete.
```

Restore procedure per component:

1. If `requiresScaleDown` is true: scale workload to 0 replicas
2. For each volume in `components[name].volumes`: restore from snapshot
3. For each configMap/secret: restore from API export
4. If scaled down: scale workload back to original replica count
5. If `healthCheck` is set: poll endpoint until 200 or timeout

### `opm restore download <release> <component> --snapshot <id> <path>`

Download a file or directory from a snapshot.

```
$ opm restore download kind-opm-dev/jellyfin jellyfin --snapshot a1b2c3d4 /config/data/library.db

Downloading library.db (892 MiB)... done
Saved to ./library.db
```

Directories are downloaded as tar.gz archives.

---

## Authentication

The CLI resolves credentials from the restore directive's `repository` field:

1. Read `repository.s3` for endpoint, bucket, credentials
2. When credentials reference Kubernetes secrets (`{secretName, remoteKey}`), read from cluster via kubeconfig
3. Read `repository.repoPassword` for Restic/Kopia repository encryption key
4. Select tool based on `repository.format` (`restic` or `kopia`)

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| No restore directive found | Error: "No restore directive found in release 'Y'" |
| Repository unreachable | Error: "Cannot connect to repository at {endpoint}. Check network and credentials." |
| Secret not found in cluster | Error: "Secret '{secretName}' not found in namespace '{namespace}'." |
| Unsupported format | Error: "Repository format '{format}' not supported. Install the required tool." |
| Restore health check fails | Warning: "Health check failed for '{component}'. Workload may need manual intervention." |
| Snapshot not found | Error: "Snapshot '{id}' not found in repository." |
| Component not in directive | Error: "Component '{name}' not found in restore directive." |
