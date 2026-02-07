# RFC: Interface Architecture for OPM

> **Status**: Draft / Exploration
> **Authors**: OPM Core Team
> **Date**: 2026-02-06

---

## Executive Summary

This document proposes adding **Interfaces** as a new first-class definition type in the Open Platform Model. Interfaces introduce a `provides`/`requires` model that allows module authors to declare what their components offer and depend on using well-known, typed contracts. The platform is responsible for fulfilling these contracts at deployment time.

This is the most significant architectural evolution of OPM since its inception. It transforms OPM from a deployment configuration system into an **application description language** — one where service communication, data dependencies, and infrastructure requirements are expressed as typed contracts rather than configuration details.

---

## Table of Contents

1. [Motivation](#1-motivation)
2. [Core Concept](#2-core-concept)
3. [Architecture](#3-architecture)
4. [The Interface Definition Type](#4-the-interface-definition-type)
5. [Well-Known Interface Library](#5-well-known-interface-library)
6. [Provides and Requires on Components](#6-provides-and-requires-on-components)
7. [The Three Paths](#7-the-three-paths)
8. [Platform Fulfillment](#8-platform-fulfillment)
9. [Type Safety and Validation](#9-type-safety-and-validation)
10. [Worked Example](#10-worked-example)
11. [Relationship to Existing Concepts](#11-relationship-to-existing-concepts)
12. [Pros and Cons](#12-pros-and-cons)
13. [Open Questions](#13-open-questions)
14. [Comparison with Industry](#14-comparison-with-industry)
15. [Incremental Adoption Path](#15-incremental-adoption-path)

---

## 1. Motivation

### The Problem

Today, OPM components are isolated islands. A module author defines a web service with a container, some traits, and maybe an Expose/Route for networking. But the critical question — **what does this component talk to, and what talks to it?** — is answered outside OPM, in ad-hoc configuration, environment variables, and tribal knowledge.

Consider a typical microservice:

```text
┌─────────────────────────────────────────────────────────────────┐
│  user-service                                                   │
│                                                                 │
│  What OPM knows today:                                          │
│    - Container image and resource limits                        │
│    - Number of replicas                                         │
│    - Health checks                                              │
│    - It's exposed on port 8080                                  │
│                                                                 │
│  What OPM does NOT know:                                        │
│    - It needs a PostgreSQL database                             │
│    - It needs a Redis cache                                     │
│    - It produces events to a Kafka topic                        │
│    - It provides a gRPC API consumed by 3 other services        │
│    - The connection strings for all of the above                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

Without this information, the platform cannot:

- Validate that all dependencies are satisfied before deployment
- Auto-wire connections between components
- Provision managed services (DaaS, CaaS) to fulfill requirements
- Build a service dependency graph
- Reason about the application's architecture

### The Opportunity

If OPM knows the **communication contracts** of every component, it becomes more than a deployment tool. It becomes a **language for describing applications** — their structure, their dependencies, their interfaces with the world.

### Why Now

The OPM trait system already models some communication patterns (Expose, Route traits). But these are protocol-specific plumbing, not application-level contracts. As the catalog grows with more traits (HttpRoute, GrpcRoute, TcpRoute), the pattern is clear: what module authors actually want to express is not "create an HTTPRoute with these match rules" but "I provide an HTTP API" and "I need a database."

---

## 2. Core Concept

**An Interface is a typed contract that describes a communication endpoint.**

- Module authors declare which interfaces their components `provide` (offer to others) and `require` (depend on).
- OPM publishes a catalog of **well-known interfaces** — standard types like `#HttpServer`, `#Postgres`, `#Redis`, `#KafkaTopic`.
- Because interfaces are well-known, their **shape is known at author time**. Module authors can reference interface fields directly in their definitions (e.g., `requires.db.host`).
- The **platform fulfills** `requires` at deployment time — by wiring to another component, provisioning a managed service, or binding to an external endpoint.
- The **module definition is unchanged** regardless of how the platform fulfills the requirement.

This model is analogous to interfaces in programming languages: you code against the interface, and the runtime provides the implementation.

---

## 3. Architecture

### System Overview

```text
┌─────────────────────────────────────────────────────────────────────┐
│                       OPM ARCHITECTURE                              │
│                                                                     │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │  INTERFACE CATALOG (well-known types)                         │  │
│  │                                                               │  │
│  │  Network:  #HttpServer  #GrpcServer  #TcpServer  #UdpServer   │  │
│  │  Data:     #Postgres    #Mysql    #Redis    #Mongodb   #S3    │  │
│  │  Messaging:#KafkaTopic  #NatsStream  #Amqp                    │  │
│  │  Identity: #OidcProvider                                      │  │
│  │  ...extensible by platform operators...                       │  │
│  └───────────────────────────────────────────────────────────────┘  │
│         │                                        │                  │
│         │ provides                               │ requires         │
│         ▼                                        ▼                  │
│  ┌──────────────────┐                    ┌──────────────────┐       │
│  │   Component A    │                    │   Component B    │       │
│  │                  │                    │                  │       │
│  │  provides:       │                    │  provides:       │       │
│  │    api: #Http    │◄───────────────────│    ...           │       │
│  │                  │    requires:       │                  │       │
│  │  requires:       │      api: #Http    │  requires:       │       │
│  │    db: #Postgres │                    │    db: #Postgres │       │
│  └────────┬─────────┘                    └────────┬─────────┘       │
│           │                                       │                 │
│           │ requires                              │ requires        │
│           ▼                                       ▼                 │
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │                    PLATFORM FULFILLMENT                      │   │
│  │                                                              │   │
│  │  Option A: Another component in scope provides #Postgres     │   │
│  │  Option B: Platform provisions managed DB (DaaS)             │   │
│  │  Option C: Platform binds to external service                │   │
│  │                                                              │   │
│  │  In all cases → concrete values injected into interface      │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Data Flow

```text
┌───────────────┐      ┌───────────────┐      ┌───────────────┐      ┌───────────────┐
│   Author      │      │   Platform    │      │   Render      │      │   Deploy      │
│   Time        │────▶│   Binding     │────▶│   Pipeline    │────▶│   Time        │
│               │      │               │      │               │      │               │
│ Define        │      │ Resolve       │      │ Each path has │      │ K8s resources │
│ provides &    │      │ requires to   │      │ its own       │      │ are created   │
│ requires with │      │ concrete      │      │ rendering:    │      │ with concrete │
│ well-known    │      │ providers     │      │ traits →      │      │ values        │
│ types         │      │ (in-scope,    │      │   transformers│      │               │
│               │      │  DaaS, or     │      │ interfaces →  │      │               │
│               │      │  external)    │      │   resolvers   │      │               │
└───────────────┘      └───────────────┘      └───────────────┘      └───────────────┘
```

---

## 4. The Interface Definition Type

### Position in the Definition Type System

Interface joins the existing definition types as a new first-class concept:

| Type | Question It Answers | Level |
|------|---------------------|-------|
| **Resource** | "What exists?" | Component |
| **Trait** | "How does it behave?" | Component |
| **Policy** | "What must be true?" | Scope |
| **Blueprint** | "What is the pattern?" | Component |
| **Interface** | "What does it communicate?" | Component |
| **Lifecycle** | "What happens on transitions?" | Component/Module |
| **Status** | "What is computed state?" | Module |
| **Test** | "Does the lifecycle work?" | Separate artifact |

### What Interface Infers

- "This component **communicates** via this contract"
- "This contract has a **known shape** with typed fields"
- "The **platform** is responsible for fulfilling required interfaces"
- "The module author can **reference** interface fields at definition time"

### When to Use Interface

Ask yourself:

- Does this component communicate with other services or infrastructure?
- Is the communication pattern standardized (HTTP, gRPC, database protocol)?
- Should the platform be able to provision or wire this dependency?
- Do you want type-safe references to connection details?

### Core Definition

```cue
#Interface: {
    apiVersion: "opmodel.dev/core/v0"
    kind:       "Interface"

    metadata: {
        apiVersion!:  #APIVersionType
        name!:        #NameType
        _definitionName: (#KebabToPascal & {"in": name}).out
        fqn: #FQNType & "\(apiVersion)#\(_definitionName)"

        description?: string
        labels?:      #LabelsAnnotationsType
        annotations?: #LabelsAnnotationsType
    }

    // The contract — typed fields this interface exposes.
    // When used in `provides`, the module author fills these with concrete values.
    // When used in `requires`, the platform fills these at deployment time.
    #shape!: {...}

    // Sensible defaults for the shape fields.
    #defaults: #shape
}
```

### Key Design Decision: Shape as Contract

The `#shape` field is what makes interfaces powerful. It defines a **typed contract** — a set of fields with types and constraints. For example, the Postgres interface shape includes `host`, `port`, `dbName`, `username`, `password`. These fields are:

- **Known at author time** — the module author can reference `requires.db.host` in their container env vars.
- **Typed by CUE** — invalid references (e.g., `requires.db.hostname`) fail at validation time.
- **Concrete at deploy time** — the platform fills in actual values when fulfilling the interface.

---

## 5. Well-Known Interface Library

OPM provides a catalog of standard interface types. These are published as CUE definitions in the `interfaces` module, organized by category.

### Network Interfaces

```cue
// interfaces/network/http_server.cue
#HttpServerInterface: #Interface & {
    metadata: {
        apiVersion:  "opmodel.dev/interfaces/network@v0"
        name:        "http-server"
        description: "An HTTP server endpoint"
    }

    #shape: {
        port!:       uint & >=1 & <=65535
        paths?: [...{
            path!:     string
            pathType?: "Prefix" | "Exact" | *"Prefix"
        }]
        hostnames?:  [...string]
        visibility:  "public" | "internal" | *"internal"
    }
}

// interfaces/network/grpc_server.cue
#GrpcServerInterface: #Interface & {
    metadata: {
        apiVersion:  "opmodel.dev/interfaces/network@v0"
        name:        "grpc-server"
        description: "A gRPC server endpoint"
    }

    #shape: {
        port!:       uint & >=1 & <=65535
        services?:   [...string]   // fully-qualified gRPC service names
        hostnames?:  [...string]
        visibility:  "public" | "internal" | *"internal"
    }
}

// Similarly: #TcpServerInterface, #UdpServerInterface, #WebSocketServerInterface
```

### Data Interfaces

```cue
// interfaces/data/postgres.cue
#PostgresInterface: #Interface & {
    metadata: {
        apiVersion:  "opmodel.dev/interfaces/data@v0"
        name:        "postgres"
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

// interfaces/data/redis.cue
#RedisInterface: #Interface & {
    metadata: {
        apiVersion:  "opmodel.dev/interfaces/data@v0"
        name:        "redis"
        description: "A Redis connection"
    }

    #shape: {
        host!:     string
        port:      uint | *6379
        password?: string
        db:        uint | *0
    }
}

// Similarly: #MysqlInterface, #MongodbInterface, #S3Interface
```

### Messaging Interfaces

```cue
// interfaces/messaging/kafka_topic.cue
#KafkaTopicInterface: #Interface & {
    metadata: {
        apiVersion:  "opmodel.dev/interfaces/messaging@v0"
        name:        "kafka-topic"
        description: "A Kafka topic for producing or consuming messages"
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

// Similarly: #NatsStreamInterface, #AmqpInterface
```

### Extensibility

Platform operators can define custom interfaces for their organization:

```cue
// Custom interface defined by a platform team
#InternalAuthInterface: #Interface & {
    metadata: {
        apiVersion:  "acme.com/interfaces/identity@v0"
        name:        "internal-auth"
        description: "ACME internal authentication service"
    }

    #shape: {
        endpoint!:    string
        clientId!:    string
        clientSecret!: string
        realm:        string | *"acme"
    }
}
```

---

## 6. Provides and Requires on Components

### Component-Level Fields

`provides` and `requires` are first-class fields on `#Component`:

```cue
#Component: {
    // ... existing fields (metadata, #resources, #traits, #policies, spec) ...

    // Interfaces this component implements / offers to others
    provides?: [string]: #Interface

    // Interfaces this component depends on
    requires?: [string]: #Interface
}
```

Both are maps keyed by a **local name** — an alias the module author uses to reference the interface within the component (e.g., `"db"`, `"cache"`, `"api"`).

### Provides: What a Component Offers

When a component declares `provides`, it makes an interface available for other components (or external consumers) to depend on. The module author fills in the shape with concrete configuration values:

```cue
userService: #Component & {
    provides: {
        "user-api": interfaces.#HttpServer & {
            port:       8080
            paths:      [{ path: "/api/v1/users" }]
            visibility: "public"
        }
        "user-grpc": interfaces.#GrpcServer & {
            port:     9090
            services: ["user.v1.UserService"]
        }
    }
}
```

### Requires: What a Component Needs

When a component declares `requires`, it states a dependency on an interface that the platform must fulfill. The module author references the shape's fields but does not provide values — those come from the platform:

```cue
userService: #Component & {
    requires: {
        "db":    interfaces.#Postgres
        "cache": interfaces.#Redis
    }

    spec: container: env: {
        // These references are valid because the shape is known
        DATABASE_HOST: { name: "DATABASE_HOST", value: requires.db.host }
        DATABASE_PORT: { name: "DATABASE_PORT", value: requires.db.port }
        DATABASE_NAME: { name: "DATABASE_NAME", value: requires.db.dbName }
        REDIS_URL:     { name: "REDIS_URL",     value: requires.cache.host }
    }
}
```

### The "No Injection" Model

Traditional platforms inject connection details via opaque mechanisms (environment variables from Secrets, mounted config files). OPM takes a fundamentally different approach:

**Because interfaces are well-known, the module author references their fields directly in the definition.** The interface shape acts as a typed API between the module and the platform. The platform's job is to make those references resolve to concrete values.

```
TRADITIONAL                           OPM
──────────                            ───

Module author:                        Module author:
  "Put DB_HOST somewhere              "I require #Postgres.
   I can read it"                      I reference requires.db.host"

Platform:                             Platform:
  "Here's a Secret with               "Here's the #Postgres contract
   DB_HOST=pg.svc"                     fulfilled: {host: 'pg.svc', ...}"

Problem:                              Advantage:
  No type safety.                      CUE validates the reference.
  No validation that                   Shape mismatch caught at
  DB_HOST exists or is                 definition time.
  the right type.                      Platform can verify fulfillment.
```

### When NOT to Use Interfaces: Direct Component References

Interfaces solve a specific problem: communicating with something **the module author does not control**. When a module author brings their own database component, they already know its name and ports. Using a typed interface contract for this adds ceremony without benefit.

**The rule is simple: use interfaces for external dependencies, use direct references for internal ones.**

```text
┌─────────────────────────────────────────────────────────────────────┐
│  WITHIN A MODULE: Direct references                                 │
│                                                                     │
│  The module author controls both components. They know the name,    │
│  the port, the configuration. Just reference it directly.           │
│                                                                     │
│  ┌─ Module: my-app ───────────────────────────────────────────┐     │
│  │                                                            │     │
│  │  api-server                    database                    │     │
│  │  spec: container: env:         spec: container:            │     │
│  │    DB_HOST: "database"  ◄──────  ports:                    │     │
│  │    DB_PORT: "5432"               postgres: 5432            │     │
│  │                                                            │     │
│  │  No interface needed. The module author knows both sides.  │     │
│  └────────────────────────────────────────────────────────────┘     │
│                                                                     │
│  ACROSS MODULES / TO PLATFORM: Interfaces                           │
│                                                                     │
│  The module author does NOT control the other side.                 │
│  They don't know who provides it, where it runs, or how it's        │
│  configured. They need a typed contract.                            │
│                                                                     │
│  ┌─ Module: my-app ─────────┐                                       │
│  │                          │     ┌─ ??? ──────────────────────┐    │
│  │  api-server              │     │                            │    │
│  │  requires:               │     │  Could be another module   │    │
│  │    "db": #Postgres  ◄────┼─────│  Could be platform DaaS    │    │
│  │                          │     │  Could be external service │    │
│  └──────────────────────────┘     └────────────────────────────┘    │
│                                                                     │
│  Interface needed. The provider is unknown at author time.          │
└─────────────────────────────────────────────────────────────────────┘
```

The decision matrix:

| Scenario | Approach | Why |
|----------|----------|-----|
| Component talks to sibling in same module | Direct reference (name + port) | Author controls both sides. Name and ports are known constants. |
| Component depends on another module's service | `requires: #GrpcServer` | Author doesn't control the provider. Needs a typed contract. |
| Component depends on platform infrastructure | `requires: #Postgres` | Provider is the platform itself (DaaS, managed service). Needs a contract. |
| Component depends on external service | `requires: #Postgres` | Provider is outside the system entirely. Needs a contract. |

This distinction keeps the interface system focused on where it adds real value — **the boundary between what you control and what you don't** — while keeping within-module wiring simple and explicit.

---

## 7. The Three Paths

OPM offers three independent design patterns for describing component communication and behavior. Each path has its own rendering pipeline and serves different use cases. They are peers, not layers — none compiles down to another.

```text
┌─────────────────────────────────────────────────────────────────────┐
│  PATH C: CAPABILITIES (abstract, infrastructure-like)               │
│                                                                     │
│  For infrastructure components that ARE the interface.              │
│  "I am a data-store"  "I am an event-broker"                        │
│  Platform resolves to infrastructure provisioning.                  │
│                                                                     │
│  Usage: SimpleDatabase blueprint, managed service proxies           │
│  Own rendering pipeline: capability resolvers.                      │
├─────────────────────────────────────────────────────────────────────┤
│  PATH B: INTERFACES (provides/requires, contract-driven)            │
│                                                                     │
│  For application components that CONSUME and PROVIDE interfaces.    │
│  "I provide an HTTP API"   "I require a database connection"        │
│  Platform wires dependencies, generates provider resources.         │
│                                                                     │
│  Usage: Microservices, APIs, workers, gateways                      │
│  Own rendering pipeline: interface resolvers.                       │
├─────────────────────────────────────────────────────────────────────┤
│  PATH A: TRAITS (protocol-specific, explicit)                       │
│                                                                     │
│  Direct control over networking and workload primitives.            │
│  Expose + HttpRoute + GrpcRoute + TcpRoute                          │
│  No abstraction, maximum control.                                   │
│                                                                     │
│  Usage: Fine-grained control, simple cases                          │
│  Own rendering pipeline: trait transformers.                        │
└─────────────────────────────────────────────────────────────────────┘

Each path is independent. They do NOT compile down to each other.
A component uses ONE path for a given concern. Mixing is possible
across concerns (e.g., traits for networking + interfaces for data
dependencies) but a single concern should not span multiple paths.
```

### Path Independence

Each path has its **own rendering pipeline** that produces provider-specific resources directly:

- **Path A (Traits)**: Trait transformers convert trait specs into K8s resources (Services, HTTPRoutes, Deployments, etc.) — the existing pipeline.
- **Path B (Interfaces)**: Interface resolvers fulfill `requires` contracts, resolve `provides` declarations, and generate provider resources directly. No trait intermediary.
- **Path C (Capabilities)**: Capability resolvers provision or bind infrastructure and inject connection details.

This independence means:

- Interfaces do not depend on traits. They generate their own output.
- Traits do not know about interfaces. They are self-contained.
- A component using `provides: #HttpServer` does NOT implicitly create an Expose or HttpRoute trait.
- Each path can evolve independently without cascading changes.

### When to Use Each Path

| Scenario | Recommended Path |
|----------|-----------------|
| Simple service with one port, no dependencies | Path A (Expose trait) |
| Service with HTTP routing rules | Path A (Expose + HttpRoute traits) |
| Microservice with database and cache dependencies | Path B (Interfaces) |
| Complex app with multiple APIs, dependencies, events | Path B (Interfaces) |
| Database component (IS the infrastructure) | Path C (Capabilities) |
| Managed service proxy | Path C (Capabilities) |
| Fine-grained networking control alongside interface dependencies | Path A for networking + Path B for data deps |

---

## 8. Platform Fulfillment

### The Platform's Role

The platform is responsible for **fulfilling** all `requires` declarations. Fulfillment means providing concrete values for every field in the interface's `#shape`. The platform has multiple strategies:

### Strategy 1: Cross-Module Matching

When a component in one module `requires` an interface that a component in another module `provides`, and both are deployed in the same Scope, the platform can auto-wire them. This is the primary use case for interfaces — connecting modules that don't know about each other.

```text
┌─ Scope: production ──────────────────────────────────────────────┐
│                                                                  │
│  ┌─ Module: app ───────────┐   ┌─ Module: data-tier ──────────┐  │
│  │                         │   │                              │  │
│  │  user-service           │   │  postgres-primary            │  │
│  │  ┌───────────────────┐  │   │  ┌───────────────────────┐   │  │
│  │  │ requires:         │  │   │  │ provides:             │   │  │
│  │  │   "db": #Postgres │◄─┼───┼──│  "primary": #Postgres │   │  │
│  │  └───────────────────┘  │   │  │  {                    │   │  │
│  │                         │   │  │    host: "pg.svc"     │   │  │
│  └─────────────────────────┘   │  │    port: 5432         │   │  │
│                                │  │    ...                │   │  │
│  Neither module knows the      │  │  }                    │   │  │
│  other. The platform matches   │  └───────────────────────┘   │  │
│  requires to provides across   └──────────────────────────────┘  │
│  module boundaries.                                              │
└──────────────────────────────────────────────────────────────────┘
```

The platform sees that `user-service` requires `#Postgres` and `postgres-primary` provides `#Postgres`. It unifies the provider's concrete values into the consumer's `requires.db` field.

Note: this is specifically for **cross-module** dependencies. Within a single module, the author controls both components and should use direct references (component name + port) instead of interfaces — see Section 6.

### Strategy 2: Platform-Provisioned Service (DaaS, CaaS, etc.)

When no in-scope component provides the required interface, the platform can provision infrastructure:

```text
┌─ Scope: production ───────────────────────────────────────────────┐
│                                                                   │
│  user-service                                                     │
│  ┌─────────────────────┐                                          │
│  │ requires:           │                                          │
│  │   "db": #Postgres   │◄────── No provider in scope              │
│  └─────────────────────┘                                          │
│           │                                                       │
│           │ Platform: "I can fulfill #Postgres"                   │
│           ▼                                                       │
│  ┌──────────────────────────────────────────┐                     │
│  │  Platform provisions:                    │                     │
│  │    AWS RDS instance                      │                     │
│  │    OR Google Cloud SQL                   │                     │
│  │    OR self-hosted StatefulSet            │                     │
│  │                                          │                     │
│  │  Fulfills with:                          │                     │
│  │    host: "prod-db.rds.amazonaws.com"     │                     │
│  │    port: 5432                            │                     │
│  │    dbName: "users"                       │                     │
│  │    username: "app"                       │                     │
│  │    password: <from Secret>               │                     │
│  └──────────────────────────────────────────┘                     │
└───────────────────────────────────────────────────────────────────┘
```

This is the **DaaS (Database as a Service)** model. The platform advertises which interfaces it can fulfill. The module author simply declares `requires: { "db": #Postgres }` and the platform handles the rest.

### Strategy 3: External Service Binding

The platform binds the requirement to an external, pre-existing service:

```cue
Platform binding configuration (Scope-level or Bundle-level):

bindings: {
    "user-service": {
        requires: {
            "db": {
                host:     "prod-db.example.com"
                port:     5432
                dbName:   "users"
                username: "readonly"
                password: <from external secret manager>
            }
        }
    }
}
```

### Fulfillment Validation

At deployment time, the platform MUST validate:

1. **Completeness**: Every `requires` on every component is fulfilled.
2. **Type compatibility**: The fulfilled values match the interface's `#shape` constraints.
3. **No dangling references**: Every `requires.X.field` reference in the component resolves.

If any validation fails, deployment is blocked. This provides a safety net that catches misconfiguration before anything runs.

---

## 9. Type Safety and Validation

### Three Layers of Validation

The interface system provides type safety at three stages, each catching different classes of errors:

```text
┌───────────────┐     ┌───────────────┐     ┌───────────────┐
│  Author Time  │     │  Module Time  │     │  Deploy Time  │
│               │     │               │     │               │
│  CUE validates│     │  All requires │     │  All requires │
│  field refs:  │     │  declared:    │     │  fulfilled:   │
│               │     │               │     │               │
│  requires.db  │     │  #Postgres is │     │  host, port,  │
│    .host ✓    │     │  a known      │     │  dbName are   │
│    .hostname ✗│     │  interface ✓  │     │  concrete ✓  │
│    .port ✓    │     │               │     │               │
│    .sslMode ✓ │     │  All provides │     │  Type         │
│               │     │  have concrete│     │  constraints  │
│  Field exists │     │  values for   │     │  satisfied ✓  │
│  on #Postgres │     │  shape ✓      │     │               │
│  shape? ✓/✗  │     │               │     │  No unfulfilled│
│               │     │               │     │  requires ✓   │
└───────────────┘     └───────────────┘     └───────────────┘

  Catches:             Catches:             Catches:
  Typos, wrong         Missing interface    Missing platform
  field names,         declarations,        bindings, wrong
  type mismatches      unknown interfaces   values, incomplete
                                            provisioning
```

### CUE Validation Example

```cue
// This is valid — `host` exists on #Postgres.#shape
spec: container: env: {
    DB_HOST: requires.db.host     // ✓ string field on #Postgres
}

// This is INVALID — `hostname` does not exist on #Postgres.#shape
spec: container: env: {
    DB_HOST: requires.db.hostname // ✗ CUE error: field not found
}

// This is INVALID — port is uint, not string
spec: container: env: {
    DB_PORT: requires.db.port     // ✓ but if used in string context,
                                  //   CUE catches the type mismatch
}
```

---

## 10. Worked Example

### Example 1: Module with Internal Database (Direct References)

When a module includes its own database, the author knows both components and references them directly. No interfaces are needed for within-module wiring.

```cue
#BlogModule: #Module & {
    metadata: {
        apiVersion: "acme.com/modules/blog@v0"
        name:       "blog"
        version:    "1.0.0"
    }

    #components: {
        // The API server references the database directly by name and port.
        // No interface needed — the author controls both components.
        "api": #Component & {
            metadata: {
                name: "api"
                labels: { "core.opmodel.dev/workload-type": "stateless" }
            }

            spec: container: {
                name:  "blog-api"
                image: "acme/blog-api:1.0.0"
                ports: { http: { targetPort: 8080 } }
                env: {
                    // Direct references — simple, explicit, no abstraction needed
                    DB_HOST: { name: "DB_HOST", value: "database" }   // sibling component name
                    DB_PORT: { name: "DB_PORT", value: "5432" }       // known port
                    DB_NAME: { name: "DB_NAME", value: "blog" }
                }
            }
        }

        // The database is a sibling component in the same module.
        "database": #Component & {
            metadata: {
                name: "database"
                labels: { "core.opmodel.dev/workload-type": "stateful" }
            }

            spec: container: {
                name:  "postgres"
                image: "postgres:16"
                ports: { postgres: { targetPort: 5432 } }
            }
        }
    }
}
```

### Example 2: Module with External Dependencies (Interfaces)

When a module depends on services it does not control — databases managed by the platform, APIs from other teams, messaging infrastructure — it uses interfaces.

```cue
import (
    interfaces_net  "opmodel.dev/interfaces/network@v0"
    interfaces_data "opmodel.dev/interfaces/data@v0"
    interfaces_msg  "opmodel.dev/interfaces/messaging@v0"
)

#UserServiceModule: #Module & {
    metadata: {
        apiVersion: "acme.com/modules/user@v0"
        name:       "user-service"
        version:    "1.0.0"
    }

    #components: {
        "user-api": #Component & {
            metadata: {
                name: "user-api"
                labels: { "core.opmodel.dev/workload-type": "stateless" }
            }

            // WHAT THIS COMPONENT PROVIDES TO THE OUTSIDE WORLD
            provides: {
                "http-api": interfaces_net.#HttpServer & {
                    port:       8080
                    paths:      [{ path: "/api/v1/users" }]
                    visibility: "public"
                }
                "grpc-api": interfaces_net.#GrpcServer & {
                    port:     9090
                    services: ["user.v1.UserService", "user.v1.AdminService"]
                }
            }

            // WHAT THIS COMPONENT REQUIRES FROM OUTSIDE THE MODULE
            // The module author does NOT control these — the platform fulfills them.
            requires: {
                "db":     interfaces_data.#Postgres
                "cache":  interfaces_data.#Redis
                "events": interfaces_msg.#KafkaTopic
            }

            // SPEC REFERENCES WELL-KNOWN INTERFACE FIELDS
            spec: container: {
                name:  "user-api"
                image: "acme/user-service:1.0.0"
                ports: {
                    http: { targetPort: 8080 }
                    grpc: { targetPort: 9090 }
                }
                env: {
                    // These references are type-safe — CUE validates them
                    DATABASE_HOST:     { name: "DATABASE_HOST",     value: requires.db.host }
                    DATABASE_PORT:     { name: "DATABASE_PORT",     value: "\(requires.db.port)" }
                    DATABASE_NAME:     { name: "DATABASE_NAME",     value: requires.db.dbName }
                    DATABASE_USER:     { name: "DATABASE_USER",     value: requires.db.username }
                    DATABASE_PASSWORD: { name: "DATABASE_PASSWORD", value: requires.db.password }
                    REDIS_HOST:        { name: "REDIS_HOST",        value: requires.cache.host }
                    REDIS_PORT:        { name: "REDIS_PORT",        value: "\(requires.cache.port)" }
                    KAFKA_BROKERS:     { name: "KAFKA_BROKERS",     value: requires.events.brokers[0] }
                    KAFKA_TOPIC:       { name: "KAFKA_TOPIC",       value: requires.events.topic }
                }
            }
        }
    }
}
```

### The Contrast

```text
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│  Example 1 (Blog):                 Example 2 (User Service):        │
│                                                                     │
│  Module brings its own DB.         Module depends on external DB.   │
│  Author knows both sides.          Author doesn't control the DB.   │
│                                                                     │
│  DB_HOST: "database"               DB_HOST: requires.db.host        │
│  DB_PORT: "5432"                   DB_PORT: requires.db.port        │
│        ↑                                  ↑                         │
│  Direct string reference.          Typed interface reference.       │
│  Simple. Explicit. No platform     Platform fills in the value.     │
│  involvement needed.               Could be RDS, Cloud SQL, or      │
│                                    another module's component.      │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Platform Fulfillment for Example 2

```cue
scope: #Scope & {
    metadata: { name: "production" }

    #modules: {
        "user-service": #UserServiceModule
    }

    // Platform bindings — fulfilling the requires contracts
    bindings: {
        "user-service": {
            "user-api": {
                requires: {
                    // Platform fulfills #Postgres via DaaS (AWS RDS)
                    "db": {
                        host:     "prod-users-db.rds.amazonaws.com"
                        port:     5432
                        dbName:   "users"
                        username: "app"
                        password: "{{secret:prod/users-db/password}}"
                    }
                    // Platform fulfills #Redis via another module in scope
                    // (auto-wired — a redis module in the same scope provides #Redis)
                    //
                    // Platform fulfills #KafkaTopic via managed Kafka
                    "events": {
                        brokers: ["kafka-1.prod:9092", "kafka-2.prod:9092"]
                        topic:   "user-events"
                    }
                }
            }
        }
    }
}
```

---

## 11. Relationship to Existing Concepts

### How Interface Relates to Each Definition Type

```text
┌────────────┬──────────────────────────────────────────────────────────────┐
│ Definition │ Relationship to Interface                                    │
├────────────┼──────────────────────────────────────────────────────────────┤
│ Resource   │ Interfaces describe what a Resource communicates.            │
│            │ A Container resource runs the code; interfaces describe      │
│            │ what that code talks to and offers.                          │
├────────────┼──────────────────────────────────────────────────────────────┤
│ Trait      │ Traits and interfaces are independent paths.                │
│            │ Both can produce provider resources (e.g., K8s Services)    │
│            │ but through separate rendering pipelines.                   │
├────────────┼──────────────────────────────────────────────────────────────┤
│ Policy     │ Policies can constrain interfaces.                           │
│            │ Example: "All provides must have visibility: internal"       │
│            │ or "All requires: #Postgres must use sslMode: verify-ca"     │
├────────────┼──────────────────────────────────────────────────────────────┤
│ Blueprint  │ Blueprints can pre-compose interfaces.                       │
│            │ A StatelessWorkload blueprint could include a default        │
│            │ provides: #HttpServer.                                       │
├────────────┼──────────────────────────────────────────────────────────────┤
│ Scope      │ Scopes are where provides/requires are resolved.             │
│            │ The platform matches requires to provides within a Scope.    │
├────────────┼──────────────────────────────────────────────────────────────┤
│ Transformer│ Transformers render traits. Interface resolvers render       │
│            │ interfaces. Each path has its own rendering pipeline.       │
├────────────┼──────────────────────────────────────────────────────────────┤
│ Lifecycle  │ Lifecycle steps can reference interfaces.                    │
│            │ Example: "Run migration on requires.db before upgrade"       │
├────────────┼──────────────────────────────────────────────────────────────┤
│ Status     │ Status can report interface fulfillment state.               │
│            │ Example: healthy: allRequiresFulfilled(requires)             │
└────────────┴──────────────────────────────────────────────────────────────┘
```

### Choosing Between Traits and Interfaces

Components should use the path that best fits their needs. Traits and interfaces address different concerns:

```cue
// Path A: Traits — explicit protocol-level control
myService: #Component & {
    workload_traits.#Expose & { spec: expose: { type: "ClusterIP", ports: { http: { targetPort: 8080 }}}}
    network_traits.#HttpRoute & { spec: httpRoute: { rules: [{ ... }] }}
}
```

```cue
// Path B: Interfaces — contract-driven, platform-resolved
myService: #Component & {
    provides: {
        "api": #HttpServer & { port: 8080, paths: [{ path: "/api" }], visibility: "public" }
    }
}
```

These are **different approaches**, not equivalent representations. Path A gives you direct control over the networking primitives. Path B declares intent and lets the platform decide how to fulfill it. The output may differ depending on the platform's interface resolver implementation.

---

## 12. Pros and Cons

### Pros

| Advantage | Description |
|-----------|-------------|
| **Type-safe dependencies** | `requires.db.host` is validated by CUE at definition time. Typos and type mismatches caught before deployment. |
| **Platform portability** | Module says `requires: #Postgres`, platform decides HOW (RDS, Cloud SQL, self-hosted). Module unchanged. |
| **Dependency graph** | Platform can build and validate the full service dependency graph. Detect cycles, missing dependencies, version conflicts. |
| **DaaS / managed services** | Platform can provision infrastructure to fulfill interfaces. `requires: #Postgres` → platform spins up RDS. |
| **Auto-wiring** | When provider and consumer are in the same Scope, platform can auto-connect them without manual configuration. |
| **Documentation as code** | `provides` is machine-readable documentation of what a service offers. Service catalogs become automatic. |
| **Incremental adoption** | Traits remain a fully independent path. Teams can use interfaces for new services without changing existing trait-based definitions. |
| **Extensible** | Platform operators define custom interfaces for their organization's services. |
| **Contract testing** | Because interfaces have typed shapes, contract tests can be generated automatically. |

### Cons

| Disadvantage | Description |
|--------------|-------------|
| **Complexity** | New core concept adds cognitive load. Developers must learn provides/requires in addition to resources/traits. |
| **Resolution complexity** | The platform binding/resolution logic is non-trivial. Auto-wiring, DaaS provisioning, and external binding are three different code paths. |
| **CUE late-binding challenge** | `requires` fields are types (not values) at author time. Making CUE resolve these at deploy time requires careful design of the unification pipeline. |
| **Interface versioning** | As interfaces evolve (e.g., #Postgres adds `connectionPoolSize`), backward compatibility must be managed. Breaking shape changes affect all consumers. |
| **Over-abstraction risk** | For simple services (one container, one port), interfaces add ceremony over a simple Expose trait. Path A is the right choice there. |
| **Platform burden** | Platforms must implement fulfillment logic — matching, provisioning, binding. This is significant engineering. |
| **Standard library maintenance** | OPM must maintain and evolve the well-known interface catalog. Community governance needed. |

### Risk Assessment

| Risk | Severity | Likelihood | Mitigation |
|------|----------|------------|------------|
| CUE cannot express late-binding cleanly | High | Medium | Prototype the CUE unification pipeline before committing. Spike required. |
| Interface catalog becomes too large/ungovernable | Medium | Medium | Start small (10-15 interfaces). Community governance model. SemVer on interfaces. |
| Developers avoid interfaces due to complexity | Medium | Low | Path A (traits) remains available. Good documentation. Blueprint-level integration hides complexity. |
| Platform implementations diverge on fulfillment semantics | High | Medium | Strict specification of fulfillment contract. Conformance tests. |
| Performance impact of resolution step | Low | Low | Resolution is a compile-time step, not runtime. CUE is fast for this. |

---

## 13. Open Questions

### Q1: CUE Late-Binding Mechanism

**Question**: How exactly does `requires.db.host` go from `string` (type) to `"pg.svc.cluster.local"` (value) in the CUE evaluation pipeline?

**Options**:

- A. Platform injects values into `requires` during ModuleRelease rendering (CUE unification)
- B. `requires` fields generate a parallel config structure that gets merged
- C. A pre-processing step rewrites `requires.X.field` references to concrete value paths

**Impact**: This is the most critical technical question. It determines whether the interface model works at all in CUE.

**Recommendation**: Spike / proof-of-concept before committing to the architecture.

### Q2: Interface Versioning Strategy

**Question**: How do interface shapes evolve over time?

**Options**:

- A. SemVer on the interface module (`opmodel.dev/interfaces/data@v0`, `@v1`)
- B. Individual interface versioning (`#Postgres` v1, v2)
- C. Additive-only changes (new optional fields never break existing consumers)

**Recommendation**: Option C with Option A as the major version escape hatch. New fields are always optional with defaults, so existing consumers are unaffected.

### Q3: Multiple Providers for Same Interface

**Question**: What happens when two components in a Scope both `provides: #Postgres`?

**Options**:

- A. Ambiguity error — consumer must specify which provider via `ref`
- B. Platform selects based on naming convention or labels
- C. Explicit binding configuration at Scope level

**Recommendation**: Option A with Option C as override. Ambiguity should be an error, not silently resolved.

### Q4: Circular Dependencies

**Question**: What if Component A requires an interface that Component B provides, and B requires an interface that A provides?

**Answer**: This is valid and common (mutual communication between services). The dependency graph must be a DAG for startup ordering, but not for communication. The platform must distinguish between "needs to exist" (startup dependency) and "needs to communicate with" (runtime dependency).

### Q5: Relationship Between provides and Container ports

**Question**: When a component declares `provides: { "api": #HttpServer & { port: 8080 } }`, must the Container also declare `ports: { http: { targetPort: 8080 } }`?

**Options**:

- A. Yes, both must align (interface doesn't replace Container ports)
- B. Interface generates Container port automatically (less duplication)
- C. Interface validates against Container ports (must exist)

**Recommendation**: This needs design. Duplication is undesirable but implicit generation is surprising.

### Q6: Scope of the Well-Known Library

**Question**: How many interfaces should OPM ship in v1?

**Recommendation**: Start minimal, grow based on demand:

- **v0**: HttpServer, GrpcServer, TcpServer, Postgres, Redis, Mysql (6 interfaces)
- **v1**: Add Mongodb, S3, KafkaTopic, NatsStream, Amqp, OidcProvider (~12 interfaces)
- **Community**: Platform operators publish their own

---

## 14. Comparison with Industry

| System | Model | Key Difference from OPM Interfaces |
|--------|-------|-------------------------------------|
| **Kubernetes Service** | Label selector matching | No typed contract. Consumer must know port/protocol by convention. |
| **K8s Gateway API** | Route resources reference Services | Protocol-aware routing but no dependency declaration or auto-wiring. |
| **Docker Compose** | `depends_on` + env vars | Startup ordering only. No typed contract. Connection details are manual. |
| **Terraform** | Provider model + outputs/inputs | Similar concept (outputs = provides, inputs = requires). But HCL, not a type system. No runtime portability. |
| **Crossplane** | Claims + Compositions | Very similar model. Claims ≈ requires, Compositions ≈ fulfillment. But Crossplane is K8s-only and resource-centric, not application-centric. |
| **Dapr** | Building blocks (state, pubsub, bindings) | Capability-based (closer to Path C / Capabilities). Runtime sidecars, not compile-time contracts. |
| **Score** | Workload spec with resources | Has `resources` as abstract dependencies. Similar to requires. But no well-known typed shapes. |
| **Acorn** | Services + secrets linking | Service discovery with secret injection. Closer to traditional injection than typed contracts. |
| **Radius** | Recipes + connections | Very similar philosophy. Recipes ≈ platform fulfillment. Connections ≈ requires. Radius is Azure-centric. |

OPM's differentiator: **compile-time type safety via CUE + provider-agnostic fulfillment + well-known typed interface catalog**.

---

## 15. Incremental Adoption Path

### Phase 1: Foundation (Current + Near-term)

- Path A traits: Expose, HttpRoute, GrpcRoute, TcpRoute (in progress via `add-more-traits` and `add-transformers` changes)
- These are a complete, standalone path for networking — not a prerequisite for interfaces

### Phase 2: Core Interface System

- Add `#Interface` to `core/interface.cue`
- Add `provides` and `requires` fields to `#Component`
- Publish initial well-known interfaces: HttpServer, GrpcServer, TcpServer, Postgres, Redis
- Implement Interface Resolver rendering pipeline (independent of trait transformers)
- CUE late-binding spike to validate `requires.X.field` pattern

### Phase 3: Platform Fulfillment

- Define fulfillment contract (how platforms advertise capabilities)
- Implement in-scope auto-wiring (match requires to provides)
- Implement Scope-level binding configuration
- Define DaaS provisioning interface

### Phase 4: Ecosystem

- Expand well-known interface catalog (Kafka, NATS, S3, MongoDB, etc.)
- Community-contributed interfaces
- Interface conformance testing
- Service catalog generation from provides declarations
- Contract test generation

---

## Summary

The Interface architecture transforms OPM from a deployment configuration system into an application description language. By introducing well-known, typed contracts for service communication, OPM enables:

1. **Module authors** to declare what their components provide and require, with type-safe references to dependency fields.
2. **Platform operators** to fulfill requirements through auto-wiring, managed service provisioning, or external binding.
3. **The platform** to validate the complete dependency graph before deployment, catching misconfigurations at definition time rather than runtime.

The design offers three independent paths — traits for explicit protocol control, interfaces for contract-driven dependencies, and capabilities for infrastructure abstraction. Each path has its own rendering pipeline and can be adopted independently. The critical technical risk (CUE late-binding for `requires`) should be spiked before full commitment.

The well-known interface catalog is the "standard library" of this language. Its quality, coverage, and governance will determine the success of the architecture.
