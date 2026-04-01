# Well-Known Offers — `#Offer` Primitive

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-04-01       |
| **Authors** | OPM Contributors |

---

## Overview

Every well-known Claim from enhancement 006 has a paired well-known Offer. These are published in the OPM catalog as standard definitions that capability providers implement.

The well-known Offer definitions live alongside their paired Claims under `opm/v1alpha1/`. They define the contract — any provider that implements the Offer must satisfy the same claim shape or transformer requirements.

## Claim/Offer Pairs

| Claim (006) | Offer (007) | Flavor | Module path |
|-------------|-------------|--------|-------------|
| `#BackupClaim` | `#BackupOffer` | Capability | `opmodel.dev/opm/v1alpha1/offers/ops` |
| `#PostgresClaim` | `#PostgresOffer` | Data | `opmodel.dev/opm/v1alpha1/offers/data` |
| `#RedisClaim` | `#RedisOffer` | Data | `opmodel.dev/opm/v1alpha1/offers/data` |
| `#MysqlClaim` | `#MysqlOffer` | Data | `opmodel.dev/opm/v1alpha1/offers/data` |
| `#S3Claim` | `#S3Offer` | Data | `opmodel.dev/opm/v1alpha1/offers/data` |
| `#HttpServerClaim` | `#HttpServerOffer` | Data | `opmodel.dev/opm/v1alpha1/offers/network` |
| `#GrpcServerClaim` | `#GrpcServerOffer` | Data | `opmodel.dev/opm/v1alpha1/offers/network` |
| `#CertificateClaim` | `#CertificateOffer` | Capability | `opmodel.dev/opm/v1alpha1/offers/security` |

## Capability Offers (with `#transformers`)

Capability offers declare that the provider can render platform-specific resources for a claim. They carry linked transformers.

### `#BackupOffer`

```cue
#BackupOffer: prim.#Offer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/offers/ops"
		version:     "v1"
		name:        "backup"
		description: "Declares capability to fulfill backup claims via periodic backup scheduling"
	}
	satisfies: data.#BackupClaim.metadata.fqn
}
```

**Example implementors:**

```cue
// K8up implementation
#K8upBackupOffer: ops.#BackupOffer & {
	implVersion: "1.2.0"
	#transformers: {
		(schedule_t.metadata.fqn):    schedule_t    // K8up Schedule CR
		(prebackup_t.metadata.fqn):   prebackup_t   // K8up PreBackupPod CR
	}
}

// Velero implementation
#VeleroBackupOffer: ops.#BackupOffer & {
	implVersion: "1.0.0"
	#transformers: {
		(velero_schedule_t.metadata.fqn): velero_schedule_t  // Velero Schedule CR
	}
}
```

### `#CertificateOffer`

```cue
#CertificateOffer: prim.#Offer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/offers/security"
		version:     "v1"
		name:        "certificate"
		description: "Declares capability to fulfill certificate claims via automated TLS provisioning"
	}
	satisfies: security.#CertificateClaim.metadata.fqn
}
```

## Data Offers (with `#shape`)

Data offers declare that the provider can supply typed connection details for a claim. They carry a `#shape` that must be a superset of the paired claim's `#shape`.

### `#PostgresOffer`

```cue
#PostgresOffer: prim.#Offer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/offers/data"
		version:     "v1"
		name:        "postgres"
		description: "Declares capability to provide PostgreSQL database connections"
	}
	satisfies: data.#PostgresClaim.metadata.fqn

	// Must match or be a superset of #PostgresClaim.#shape
	#shape: {
		host!:     string
		port:      uint | *5432
		dbName!:   string
		username!: string
		password!: string
		sslMode?:  "disable" | "require" | "verify-ca" | "verify-full"
	}
}
```

**Example implementor:**

```cue
// CloudNativePG implementation
#CnpgPostgresOffer: data.#PostgresOffer & {
	implVersion: "1.0.0"
	// No #transformers — data offers provide values, not rendered resources
	// Values come from the CNPG operator's generated secrets
}
```

### `#RedisOffer`

```cue
#RedisOffer: prim.#Offer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/offers/data"
		version:     "v1"
		name:        "redis"
		description: "Declares capability to provide Redis connections"
	}
	satisfies: data.#RedisClaim.metadata.fqn

	#shape: {
		host!:     string
		port:      uint | *6379
		password?: string
		db:        uint | *0
	}
}
```

### `#MysqlOffer`

```cue
#MysqlOffer: prim.#Offer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/offers/data"
		version:     "v1"
		name:        "mysql"
		description: "Declares capability to provide MySQL database connections"
	}
	satisfies: data.#MysqlClaim.metadata.fqn

	#shape: {
		host!:     string
		port:      uint | *3306
		dbName!:   string
		username!: string
		password!: string
		sslMode?:  "disable" | "required" | "verify_ca" | "verify_identity"
	}
}
```

### `#S3Offer`

```cue
#S3Offer: prim.#Offer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/offers/data"
		version:     "v1"
		name:        "s3"
		description: "Declares capability to provide S3-compatible object storage"
	}
	satisfies: data.#S3Claim.metadata.fqn

	#shape: {
		endpoint!:        string
		bucket!:          string
		region?:          string
		accessKeyID!:     string
		secretAccessKey!: string
		forcePathStyle?:  bool | *false
	}
}
```

### `#HttpServerOffer`

```cue
#HttpServerOffer: prim.#Offer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/offers/network"
		version:     "v1"
		name:        "http-server"
		description: "Declares capability to provide HTTP API endpoints"
	}
	satisfies: network.#HttpServerClaim.metadata.fqn

	#shape: {
		host!:       string
		port!:       uint
		paths?:      [...string]
		visibility!: "public" | "private" | "cluster"
		tls?:        bool
	}
}
```

### `#GrpcServerOffer`

```cue
#GrpcServerOffer: prim.#Offer & {
	metadata: {
		modulePath:  "opmodel.dev/opm/v1alpha1/offers/network"
		version:     "v1"
		name:        "grpc-server"
		description: "Declares capability to provide gRPC service endpoints"
	}
	satisfies: network.#GrpcServerClaim.metadata.fqn

	#shape: {
		host!:       string
		port!:       uint
		services?:   [...string]
		visibility!: "public" | "private" | "cluster"
		tls?:        bool
	}
}
```

## Multiple Providers, Same Offer

A key design property: the well-known Offer definition is the contract. Any provider implements it by extending the definition:

```text
#BackupOffer (well-known definition)
  |
  +-- #K8upBackupOffer (K8up implementation, implVersion: "1.2.0")
  |     #transformers: { schedule_t, prebackup_t }
  |
  +-- #VeleroBackupOffer (Velero implementation, implVersion: "1.0.0")
        #transformers: { velero_schedule_t }
```

The Platform team chooses which implementation to use by selecting providers in `#Platform.#providers`.
