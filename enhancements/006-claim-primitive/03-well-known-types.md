# Well-Known Interface Types — `#Requires` Construct

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

---

## Overview

OPM publishes a catalog of well-known interface types — standard data contracts with typed shapes. Module authors use these to declare dependencies. The platform fulfills them at deploy time.

Well-known types are published as CUE definitions, organized by category. Platform operators can extend the catalog with custom interfaces.

## v1 Scope

Start with 6 core types covering the most common dependencies:

| Interface     | Category | Primary Use Case                |
|---------------|----------|---------------------------------|
| `#HttpServer` | Network  | HTTP API dependencies           |
| `#GrpcServer` | Network  | gRPC service dependencies       |
| `#Postgres`   | Data     | PostgreSQL database connections |
| `#Redis`      | Data     | Redis cache/store connections   |
| `#Mysql`      | Data     | MySQL database connections      |
| `#S3`         | Data     | S3-compatible object storage    |

Additional types (Kafka, NATS, MongoDB, OIDC) are candidates for v1.1+.

---

## Network Interfaces

### `#HttpServer`

```cue
#HttpServerInterface: #Interface & {
    metadata: {
        modulePath: "opmodel.dev/interfaces/network"
        version:    "v1"
        name:       "http-server"
        description: "An HTTP server endpoint"
    }
    #shape: {
        host!:      string
        port!:      uint & >=1 & <=65535
        paths?: [...{
            path!:     string
            pathType?: "Prefix" | "Exact" | *"Prefix"
        }]
        hostnames?:  [...string]
        visibility:  "public" | "internal" | *"internal"
        tls?:        bool
    }
}
```

### `#GrpcServer`

```cue
#GrpcServerInterface: #Interface & {
    metadata: {
        modulePath: "opmodel.dev/interfaces/network"
        version:    "v1"
        name:       "grpc-server"
        description: "A gRPC server endpoint"
    }
    #shape: {
        host!:      string
        port!:      uint & >=1 & <=65535
        services?:  [...string]  // fully-qualified gRPC service names
        hostnames?: [...string]
        visibility: "public" | "internal" | *"internal"
        tls?:       bool
    }
}
```

---

## Data Interfaces

### `#Postgres`

```cue
#PostgresInterface: #Interface & {
    metadata: {
        modulePath: "opmodel.dev/interfaces/data"
        version:    "v1"
        name:       "postgres"
        description: "A PostgreSQL database connection"
    }
    #shape: {
        host!:     string
        port:      uint | *5432
        dbName!:   string
        username!: string
        password!: string
        sslMode?:  "disable" | "require" | "verify-ca" | "verify-full" | *"disable"
    }
}
```

### `#Redis`

```cue
#RedisInterface: #Interface & {
    metadata: {
        modulePath: "opmodel.dev/interfaces/data"
        version:    "v1"
        name:       "redis"
        description: "A Redis connection"
    }
    #shape: {
        host!:     string
        port:      uint | *6379
        password?: string
        db:        uint | *0
    }
}
```

### `#Mysql`

```cue
#MysqlInterface: #Interface & {
    metadata: {
        modulePath: "opmodel.dev/interfaces/data"
        version:    "v1"
        name:       "mysql"
        description: "A MySQL database connection"
    }
    #shape: {
        host!:     string
        port:      uint | *3306
        dbName!:   string
        username!: string
        password!: string
        sslMode?:  "disabled" | "required" | "preferred" | *"disabled"
    }
}
```

### `#S3`

```cue
#S3Interface: #Interface & {
    metadata: {
        modulePath: "opmodel.dev/interfaces/data"
        version:    "v1"
        name:       "s3"
        description: "An S3-compatible object storage endpoint"
    }
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

---

## Future Types (v1.1+)

### Messaging

```cue
#KafkaTopicInterface: #Interface & {
    metadata: {
        modulePath: "opmodel.dev/interfaces/messaging"
        version:    "v1"
        name:       "kafka-topic"
    }
    #shape: {
        brokers!:  [...string]
        topic!:    string
        groupId?:  string
        auth?: {
            mechanism?: "PLAIN" | "SCRAM-SHA-256" | "SCRAM-SHA-512"
            username?:  string
            password?:  string
        }
    }
}
```

### Identity

```cue
#OidcProviderInterface: #Interface & {
    metadata: {
        modulePath: "opmodel.dev/interfaces/identity"
        version:    "v1"
        name:       "oidc-provider"
    }
    #shape: {
        issuerUrl!:    string
        clientId!:     string
        clientSecret!: string
        scopes?:       [...string]
    }
}
```

---

## Extensibility

Platform operators can define custom interfaces for their organization:

```cue
#InternalAuthInterface: #Interface & {
    metadata: {
        modulePath: "acme.com/interfaces/identity"
        version:    "v1"
        name:       "internal-auth"
        description: "ACME internal authentication service"
    }
    #shape: {
        endpoint!:     string
        clientId!:     string
        clientSecret!: string
        realm:         string | *"acme"
    }
}
```

Custom interfaces follow the same rules as well-known types — they must have a `#shape`, metadata with FQN, and are usable in `#requires` exactly like built-in types.
