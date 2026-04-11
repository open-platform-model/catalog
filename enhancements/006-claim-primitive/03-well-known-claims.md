# Well-Known Claims — Data Interface Types

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

---

## Overview

OPM publishes a catalog of well-known claim types for common data dependencies. These are `#Claim` definitions with `#shape` — typed contracts whose fields the module author wires into component specs. The platform fills the shape with concrete values at deploy time.

## v1 Scope

| Claim | Category | Primary Use Case |
|-------|----------|-----------------|
| `#PostgresClaim` | Data | PostgreSQL database connections |
| `#RedisClaim` | Data | Redis cache/store connections |
| `#MysqlClaim` | Data | MySQL database connections |
| `#S3Claim` | Data | S3-compatible object storage |
| `#HttpServerClaim` | Network | HTTP API dependencies |
| `#GrpcServerClaim` | Network | gRPC service dependencies |

---

## Data Claims

### `#PostgresClaim`

```cue
#PostgresClaim: prim.#Claim & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/claims/data"
        version:    "v1"
        name:       "postgres"
    }
    #shape: {
        host!:     string
        port:      uint | *5432
        dbName!:   string
        username!: string
        password!: string
        sslMode?:  "disable" | "require" | "verify-ca" | "verify-full" | *"disable"
    }
    #spec: close({postgres: #shape})
}
```

### `#RedisClaim`

```cue
#RedisClaim: prim.#Claim & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/claims/data"
        version:    "v1"
        name:       "redis"
    }
    #shape: {
        host!:     string
        port:      uint | *6379
        password?: string
        db:        uint | *0
    }
    #spec: close({redis: #shape})
}
```

### `#MysqlClaim`

```cue
#MysqlClaim: prim.#Claim & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/claims/data"
        version:    "v1"
        name:       "mysql"
    }
    #shape: {
        host!:     string
        port:      uint | *3306
        dbName!:   string
        username!: string
        password!: string
        sslMode?:  "disabled" | "required" | "preferred" | *"disabled"
    }
    #spec: close({mysql: #shape})
}
```

### `#S3Claim`

```cue
#S3Claim: prim.#Claim & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/claims/data"
        version:    "v1"
        name:       "s3"
    }
    #shape: {
        endpoint!:        string
        bucket!:          string
        region?:          string
        accessKeyID!:     string
        secretAccessKey!: string
        forcePathStyle?:  bool | *false
    }
    #spec: close({s3: #shape})
}
```

---

## Network Claims

### `#HttpServerClaim`

```cue
#HttpServerClaim: prim.#Claim & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/claims/network"
        version:    "v1"
        name:       "http-server"
    }
    #shape: {
        host!:      string
        port!:      uint & >=1 & <=65535
        paths?: [...{
            path!:     string
            pathType?: "Prefix" | "Exact" | *"Prefix"
        }]
        visibility: "public" | "internal" | *"internal"
        tls?:       bool
    }
    #spec: close({httpServer: #shape})
}
```

### `#GrpcServerClaim`

```cue
#GrpcServerClaim: prim.#Claim & {
    metadata: {
        modulePath: "opmodel.dev/opm/v1alpha1/claims/network"
        version:    "v1"
        name:       "grpc-server"
    }
    #shape: {
        host!:      string
        port!:      uint & >=1 & <=65535
        services?:  [...string]
        visibility: "public" | "internal" | *"internal"
        tls?:       bool
    }
    #spec: close({grpcServer: #shape})
}
```

---

## Extensibility

Platform operators define custom claims for their organization:

```cue
#InternalAuthClaim: prim.#Claim & {
    metadata: {
        modulePath: "acme.com/claims/identity"
        version:    "v1"
        name:       "internal-auth"
    }
    #shape: {
        endpoint!:     string
        clientId!:     string
        clientSecret!: string
        realm:         string | *"acme"
    }
    #spec: close({internalAuth: #shape})
}
```

---

## Future Types (v1.1+)

| Claim | Category |
|-------|----------|
| `#KafkaTopicClaim` | Messaging |
| `#NatsStreamClaim` | Messaging |
| `#MongodbClaim` | Data |
| `#OidcProviderClaim` | Identity |
