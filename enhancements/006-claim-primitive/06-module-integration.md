# Module Integration — `#Claim` Primitive

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

---

## Overview

This document shows how module authors use Claims and Orchestrations in practice.

---

## Data Claims: Wiring Pattern

```cue
import (
    claims "opmodel.dev/opm/v1alpha1/claims/data@v1"
    workload "opmodel.dev/opm/v1alpha1/blueprints/workload@v1"
)

userApi: workload.#StatelessWorkload & claims.#PostgresClaim & claims.#RedisClaim & {
    spec: {
        container: {
            image: repository: "myapp/user-api"
            env: {
                DATABASE_HOST: spec.postgres.host
                DATABASE_PORT: "\(spec.postgres.port)"
                DATABASE_NAME: spec.postgres.dbName
                DATABASE_USER: spec.postgres.username
                DATABASE_PASSWORD: spec.postgres.password
                REDIS_HOST: spec.redis.host
                REDIS_PORT: "\(spec.redis.port)"
            }
        }
        scaling: count: 3
        postgres: {}  // platform fills at deploy time
        redis: {}     // platform fills at deploy time
    }
}
```

## Operational Claims: Backup

```cue
import claims "opmodel.dev/opm/v1alpha1/claims/data@v1"

jellyfin: workload.#StatefulWorkload & claims.#BackupClaim & {
    spec: {
        container: { image: repository: "linuxserver/jellyfin" }
        scaling: count: 1
        backup: {
            targets: [{volume: "config", mountPath: "/config"}]
            preBackupHook: {
                image: "alpine:3.19"
                command: ["sh", "-c", "apk add --no-cache sqlite && sqlite3 /config/data/library.db 'PRAGMA wal_checkpoint(TRUNCATE);' && sqlite3 /config/data/jellyfin.db 'PRAGMA wal_checkpoint(TRUNCATE);'"]
                volumeMount: {volume: "config", mountPath: "/config"}
            }
            backend: #config.backup.backend
        }
    }
}
```

## Blueprint Composition

```cue
#BackedUpStatefulWorkload: #Blueprint & {
    composedResources: {
        (workload.#ContainerResource.metadata.fqn): workload.#ContainerResource
        (storage.#VolumesResource.metadata.fqn):    storage.#VolumesResource
    }
    composedTraits: {
        (workload.#ScalingTrait.metadata.fqn):     workload.#ScalingTrait
        (workload.#HealthCheckTrait.metadata.fqn): workload.#HealthCheckTrait
    }
    composedClaims: {
        (data.#BackupClaim.metadata.fqn): data.#BackupClaim
    }
}

// Usage: backup is included by the Blueprint
jellyfin: #BackedUpStatefulWorkload & {
    spec: {
        container: { image: repository: "linuxserver/jellyfin" }
        scaling: count: 1
        backup: {
            targets: [{volume: "config", mountPath: "/config"}]
            backend: #config.backup.backend
        }
    }
}
```

## Policy Orchestrations: Restore

```cue
import ops "opmodel.dev/opm/v1alpha1/orchestrations/data@v1"

#Module & {
    #components: {
        "jellyfin": jellyfin
    }

    #policies: {
        "restore-plan": #Policy & {
            appliesTo: components: ["jellyfin"]
            #orchestrations: {
                (ops.#RestoreOrchestration.metadata.fqn): ops.#RestoreOrchestration & {
                    #spec: restore: {
                        targets: [{volume: "config", mountPath: "/config"}]
                        healthCheck: { path: "/health", port: 8096 }
                        inPlace: { requiresScaleDown: true }
                        disasterRecovery: { managedByOPM: true }
                    }
                }
            }
        }
    }
}
```

## Mixing Everything

```cue
#Module & {
    #components: {
        "api": workload.#StatelessWorkload
            & claims.#PostgresClaim
            & claims.#RedisClaim
            & claims.#BackupClaim & {
            spec: {
                container: {
                    image: repository: "myapp/api"
                    env: {
                        DB_HOST: spec.postgres.host
                        REDIS_URL: spec.redis.host
                    }
                }
                scaling: count: 3
                postgres: {}
                redis: {}
                backup: {
                    targets: [{volume: "data", mountPath: "/data"}]
                    backend: #config.backup.backend
                }
            }
        }
    }

    #policies: {
        "restore-plan": #Policy & {
            appliesTo: components: ["api"]
            #orchestrations: {
                (ops.#RestoreOrchestration.metadata.fqn): ops.#RestoreOrchestration & {
                    #spec: restore: {
                        targets: [{volume: "data", mountPath: "/data"}]
                        healthCheck: { path: "/health", port: 8080 }
                    }
                }
            }
        }
    }
}
```

## Release Configuration

```cue
mr.#ModuleRelease & {
    #module: myModule
    values: {
        // Data claim values (platform fills)
        postgres: {
            host: "prod-db.rds.amazonaws.com"
            port: 5432
            dbName: "users"
            username: "app"
            password: { secretName: "db-creds", remoteKey: "password" }
        }
        redis: { host: "redis.cache.svc", port: 6379 }

        // Backup backend (environment-specific)
        backup: backend: {
            s3: {
                endpoint: "http://minio.storage.svc:9000"
                bucket: "api-backup"
                accessKeyID: { secretName: "backup-s3", remoteKey: "access-key" }
                secretAccessKey: { secretName: "backup-s3", remoteKey: "secret-key" }
            }
            repoPassword: { secretName: "backup-restic", remoteKey: "password" }
        }
    }
}
```

## Migration Path

### From hardcoded K8up components

**Before:** `modules/jellyfin/components.cue` contains ~60 lines of K8up Schedule and PreBackupPod.

**After:** Add `#BackupClaim` to the component. Add `#RestoreOrchestration` to module policies. K8up resources generated by transformer.

### From hardcoded env vars

**Before:** `DB_HOST: "pg.svc.cluster.local"` hardcoded in component.

**After:** `DB_HOST: spec.postgres.host` wired from `#PostgresClaim`. Release provides concrete values.

### From `#SharedNetwork` as PolicyRule

**Before:** `#policies: { "net": network.#SharedNetwork & { ... } }`

**After:** `#policies: { "net": #Policy & { #orchestrations: { sharedNetwork: ... } } }`
