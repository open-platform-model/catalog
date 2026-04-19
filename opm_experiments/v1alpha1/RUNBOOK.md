# Runbook — Backup with `#K8upBackupDirective` (experimental)

A concrete, step-by-step guide for using `opm_experiments/v1alpha1` to back up
an OPM module via K8up. Companion to
`catalog/enhancements/009-backup-directive/`.

**Status:** experimental — shape may change. Use only in dev/kind clusters.

---

## What you get today

- Module authors declare `#K8upBackupDirective` inside a `#Policy`.
- Components carrying `#PreBackupHookTrait` get a K8up `PreBackupPod` emitted for them.
- The K8up Schedule transformer renders a real `Schedule` CR, K8up runs it, snapshots land in S3.
- Restore directive metadata (`restore.*`) is parsed and validated, but **the `opm restore` CLI is not yet implemented** — restore is manual via K8up `Restore` CRs for now.

---

## What's missing (tracked in `07-open-questions.md`)

| Gap | Impact | Workaround |
|---|---|---|
| Q1: PVC annotation | K8up won't find PVCs unless annotated OR operator runs with `skipWithoutAnnotation: false` | Configure K8up operator globally (see §2.3) |
| Q2: `opm restore run` + Lease pause | Can't drive restore from CLI yet | Create K8up `Restore` CR by hand (see §7) |
| Graduation to `opm/v1alpha1` | FQN and import paths will change | Pin to exact version; expect breaking changes |
| PVC naming convention | Transformer assumes `{release}-{component}-{volume}` | Verify against your module's actual PVC names |

---

## 1. Prerequisites

### 1.1 Local OCI registry

```bash
cd ~/Dev/open-platform-model/catalog
task registry:start
# registry should respond on localhost:5000
curl -sf http://localhost:5000/v2/ > /dev/null && echo OK
```

### 1.2 Shell environment

```bash
export CUE_REGISTRY='opmodel.dev=localhost:5000+insecure,registry.cue.works'
export OPM_REGISTRY='opmodel.dev=localhost:5000+insecure,registry.cue.works'
```

### 1.3 Cluster state (kind-opm-dev)

- K8up operator installed and running in `k8up` namespace.
- S3 backend reachable (Garage deployed in `garage` namespace, endpoint `http://garage-garage.garage.svc:3900`).
- Restic repo password + S3 access/secret keys stored as K8s Secrets in the release namespace.

Confirm:

```bash
kubectl -n k8up get pods
kubectl -n garage get svc
```

### 1.4 K8up operator: include ALL PVCs in scope (Q1 workaround)

The directive no longer enumerates PVCs. K8up decides which PVCs to back up.
For now set the operator to back up every PVC in the release namespace:

```bash
kubectl -n k8up set env deployment/k8up BACKUP_SKIP_WITHOUT_ANNOTATION=false
# or patch the Helm values if installed via Helm
```

Alternative: annotate target PVCs manually — `kubectl annotate pvc <name> k8up.io/backup=true`.

---

## 2. Publish the experimental catalog locally

From `catalog/`:

```bash
cd ~/Dev/open-platform-model/catalog

# Sanity: everything green first.
task fmt
task vet
task test

# Publish all locally-changed domain modules (core, opm_experiments).
task publish:smart
```

`publish:smart` computes a checksum per domain and bumps the version of any
module whose CUE files changed. On first run it will publish
`opm_experiments/v1alpha1@v0.1.0` (and core if you changed it) to the local
registry and update `versions.yml`.

Verify:

```bash
task version
# ...
# opm_experiments/v1alpha1:  v0.1.0
```

---

## 3. Wire the experimental catalog into your module

### 3.1 Add the dependency

Edit `modules/<your-module>/cue.mod/module.cue`:

```cue
module: "opmodel.dev/modules/<your-module>@v1"
language: version: "v0.15.0"
source: kind: "self"

deps: {
    "opmodel.dev/core/v1alpha1@v1": { v: "v1.3.5" }
    "opmodel.dev/opm/v1alpha1@v1":  { v: "v1.5.6" }

    // NEW — experimental backup directive + trait
    "opmodel.dev/opm_experiments/v1alpha1@v1": { v: "v0.1.0" }
}
```

Then from the workspace root:

```bash
cd ~/Dev/open-platform-model
task update-deps
```

This refreshes pins across all dependent modules. **Never edit version pins
manually** — always use `task update-deps`.

### 3.2 Replace direct K8up catalog imports

If the module imports `opmodel.dev/k8up/v1alpha1/resources/backup@v1` to
compose `#Schedule` / `#PreBackupPod` components, remove those imports and the
components they build. The directive + trait replace them.

---

## 4. Write the module against the new shape

### 4.1 The workload component (e.g., `jellyfin`)

Attach the `#PreBackupHookTrait` to any component that needs quiescing (SQLite
checkpoint, pg_dump, RCON flush). Components without quiescing needs don't
need the trait.

```cue
package jellyfin

import (
    // ... existing imports ...
    exp_traits "opmodel.dev/opm_experiments/v1alpha1/traits@v1"
)

#components: {
    jellyfin: {
        resources_workload.#Container
        resources_storage.#Volumes
        // ... existing composition ...

        // NEW — pre-backup quiescing hook
        if #config.backup != _|_ {
            #traits: {
                (exp_traits.#PreBackupHookTrait.metadata.fqn): exp_traits.#PreBackupHookTrait & {
                    spec: preBackupHook: {
                        image: "alpine:3.21"
                        command: ["sh", "-c", """
                            sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE)' && \
                            sqlite3 /config/data/jellyfin.db  'PRAGMA wal_checkpoint(TRUNCATE)'
                            """]
                        volumeMount: {
                            volume:    "config"
                            mountPath: "/config"
                        }
                    }
                }
            }
        }

        metadata: name: "jellyfin"
        spec: { /* ... existing spec ... */ }
    }
}
```

### 4.2 The backup policy

Add a `#Policy` carrying the `#K8upBackupDirective`. One directive per module
(multiple backup directives per module is rejected — see Q3).

```cue
// In the same package file (or a dedicated policies.cue):

import (
    policy "opmodel.dev/core/v1alpha1/policy@v1"
    exp_directives "opmodel.dev/opm_experiments/v1alpha1/directives@v1"
)

#policies: {
    if #config.backup != _|_ {
        "backup": policy.#Policy & {
            appliesTo: components: [#components.jellyfin]

            #directives: {
                (exp_directives.#K8upBackupDirective.metadata.fqn):
                    exp_directives.#K8upBackupDirective & {
                        #spec: k8upBackup: {
                            schedule:  #config.backup.schedule
                            retention: #config.backup.retention
                            repository: #config.backup.repository

                            restore: jellyfin: {
                                requiresScaleDown: true
                                healthCheck: {
                                    path: "/health"
                                    port: 8096
                                }
                            }
                        }
                    }
            }
        }
    }
}
```

### 4.3 Update `#config.backup`

Rename / reshape if the module previously used a `backend` block:

```cue
#config: {
    backup?: {
        schedule!: string

        repository!: {
            format: *"restic" | "kopia"
            s3!: {
                endpoint!:        string
                bucket!:          string
                accessKeyID!:     _
                secretAccessKey!: _
            }
            password!: _
        }

        retention: {
            keepDaily:   *7 | int
            keepWeekly:  *4 | int
            keepMonthly: *6 | int
        }
    }
    // ... other config ...
}
```

---

## 5. Configure the release

Edit `releases/<env>/<module>/release.cue`:

```cue
values: {
    // ... existing values ...

    backup: {
        schedule: "0 2 * * *"

        repository: {
            format: "restic"
            s3: {
                endpoint: "http://garage-garage.garage.svc:3900"
                bucket:   "jellyfin-backups"
                accessKeyID: {
                    secretName: "jellyfin-backup-s3"
                    remoteKey:  "access-key-id"
                }
                secretAccessKey: {
                    secretName: "jellyfin-backup-s3"
                    remoteKey:  "secret-access-key"
                }
            }
            password: {
                secretName: "jellyfin-backup-restic"
                remoteKey:  "password"
            }
        }

        retention: {
            keepDaily:   7
            keepWeekly:  4
            keepMonthly: 6
        }
    }
}
```

Pre-create the referenced Secrets in the release namespace if they don't already exist:

```bash
kubectl -n jellyfin create secret generic jellyfin-backup-s3 \
    --from-literal=access-key-id='...' \
    --from-literal=secret-access-key='...'

kubectl -n jellyfin create secret generic jellyfin-backup-restic \
    --from-literal=password='...'
```

---

## 6. Build, apply, verify

### 6.1 Module publish

```bash
cd ~/Dev/open-platform-model/modules
task check      # fmt + vet + tidy
task publish    # publishes module to local registry
```

### 6.2 Build and apply the release

```bash
cd ~/Dev/open-platform-model/releases
opm release build   kind_opm_dev/jellyfin
opm release diff    kind_opm_dev/jellyfin    # sanity check
opm release apply   kind_opm_dev/jellyfin
```

### 6.3 Verify the Schedule was created

```bash
kubectl -n jellyfin get schedule.k8up.io
# NAME                        SCHEDULE      AGE
# jellyfin-jellyfin-backup    0 2 * * *     1m

kubectl -n jellyfin get prebackuppod.k8up.io
# NAME                             AGE
# jellyfin-jellyfin-pre-backup     1m
```

Describe both to see backend + schedule details:

```bash
kubectl -n jellyfin describe schedule.k8up.io jellyfin-jellyfin-backup
kubectl -n jellyfin describe prebackuppod.k8up.io jellyfin-jellyfin-pre-backup
```

### 6.4 Force a backup run (don't wait for the cron)

```bash
kubectl -n jellyfin create -f - <<'EOF'
apiVersion: k8up.io/v1
kind: Backup
metadata:
  generateName: jellyfin-adhoc-
spec:
  backend:
    repoPasswordSecretRef:
      name: jellyfin-backup-restic
      key:  password
    s3:
      endpoint: http://garage-garage.garage.svc:3900
      bucket:   jellyfin-backups
      accessKeyIDSecretRef:
        name: jellyfin-backup-s3
        key:  access-key-id
      secretAccessKeySecretRef:
        name: jellyfin-backup-s3
        key:  secret-access-key
EOF

kubectl -n jellyfin get backups.k8up.io -w
```

Wait for `STATUS: Finished`.

### 6.5 Browse snapshots from the workstation

With `restic` installed locally:

```bash
export AWS_ACCESS_KEY_ID='...'          # from jellyfin-backup-s3
export AWS_SECRET_ACCESS_KEY='...'
export RESTIC_PASSWORD='...'            # from jellyfin-backup-restic
export RESTIC_REPOSITORY='s3:http://localhost:<garage-port>/jellyfin-backups'
# port-forward if Garage isn't directly reachable:
#   kubectl -n garage port-forward svc/garage-garage 3900:3900

restic snapshots
```

---

## 7. Manual restore (until `opm restore` lands)

Until the CLI implements `opm restore run`, drive restore by hand.

### 7.1 Scale the workload down

```bash
kubectl -n jellyfin scale deploy jellyfin --replicas=0
# or statefulset, depending on how the module renders
kubectl -n jellyfin get pods -w    # wait for termination
```

### 7.2 Create a K8up Restore CR

```bash
kubectl -n jellyfin create -f - <<'EOF'
apiVersion: k8up.io/v1
kind: Restore
metadata:
  generateName: jellyfin-restore-
spec:
  snapshot: <snapshot-id-from-restic-snapshots>
  restoreMethod:
    folder:
      claimName: jellyfin-jellyfin-config   # {release}-{component}-{volume}
  backend:
    repoPasswordSecretRef:
      name: jellyfin-backup-restic
      key:  password
    s3:
      endpoint: http://garage-garage.garage.svc:3900
      bucket:   jellyfin-backups
      accessKeyIDSecretRef:
        name: jellyfin-backup-s3
        key:  access-key-id
      secretAccessKeySecretRef:
        name: jellyfin-backup-s3
        key:  secret-access-key
EOF

kubectl -n jellyfin get restores.k8up.io -w
```

### 7.3 Scale back up and verify

```bash
kubectl -n jellyfin scale deploy jellyfin --replicas=1
kubectl -n jellyfin port-forward svc/jellyfin 8096:8096
curl -sI http://localhost:8096/health
```

---

## 8. Troubleshooting

### "No PVCs backed up" / Backup finishes with 0 files

- Did you set `BACKUP_SKIP_WITHOUT_ANNOTATION=false` on the operator, OR annotate PVCs? (§1.4 / Q1)
- `kubectl -n jellyfin get pvc -o yaml | grep k8up.io/backup` — annotation present?

### Schedule CR created but no Backup runs

- `kubectl -n jellyfin describe schedule.k8up.io <name>` — look for backend reference errors.
- Confirm Secrets exist and keys are correct.

### PreBackupPod fails with "volume <name> not found"

- The transformer assumes PVC naming `{release}-{component}-{volume}`.
- Check actual PVC names: `kubectl -n jellyfin get pvc`.
- If your module renders PVCs differently, adjust the transformer's `_pvcName`
  expression in
  `opm_experiments/v1alpha1/providers/kubernetes/transformers/k8up_pre_backup_pod.cue`
  to match — this is a known caveat and one of the reasons this catalog is
  experimental.

### `cue vet` fails with "field not allowed: k8upBackup"

- You're on `core` < v1.3.5. The `#Directive` primitive needs the
  `#KebabToCamel` helper that landed in v1.3.5. Republish core locally:

  ```bash
  cd catalog && task publish:core
  cd ../ && task update-deps
  ```

### "Another restore is in progress"

- Not a real CLI yet — this message is described in the design but not
  implemented. A real lease-based pause will be added once `opm restore run`
  lands. For now, assume nothing else will reconcile during your manual
  restore, or suspend any Flux / controller that might.

---

## 9. Rolling back

If the experiment goes sideways:

1. Remove the `#policies.backup` block from the module.
2. Remove the `#PreBackupHookTrait` from components.
3. Remove `opm_experiments` from `cue.mod/module.cue`.
4. Republish the module (`cd modules && task publish`).
5. `opm release apply` — the Schedule and PreBackupPod CRs will be pruned from
   the cluster by the controller's inventory reconciliation.
6. Existing Restic snapshots in S3 are not affected. Data is safe.

---

## 10. Graduation checklist

Before asking to graduate this out of `opm_experiments`, confirm:

- [ ] At least two distinct modules using the directive (Jellyfin + one more).
- [ ] Full backup → destroy → restore → verify cycle completed on each.
- [ ] PVC annotation strategy (Q1) decided and documented.
- [ ] `opm restore run` + Lease pause (Q2) implemented and exercised.
- [ ] Second provider directive drafted in `opm_experiments` (e.g.,
  `#VeleroBackupDirective`) to pressure-test the `restore` sub-block.

See `catalog/enhancements/009-backup-directive/07-open-questions.md` for full
graduation criteria.

---

## References

- Design: `catalog/enhancements/009-backup-directive/02-design.md`
- Transformers: `.../03-transformer-integration.md`
- Module examples: `.../04-module-integration.md`
- CLI spec (future): `.../05-cli-integration.md`
- Open questions: `.../07-open-questions.md`
- K8up docs: <https://k8up.io>
