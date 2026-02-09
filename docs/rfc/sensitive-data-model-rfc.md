# RFC: Sensitive Data Model for OPM

> **Status**: Draft / Exploration
> **Authors**: OPM Core Team
> **Date**: 2026-02-09
> **Related**: [Interface Architecture RFC](interface-architecture-rfc.md)

---

## Executive Summary

This document proposes making sensitive data a **first-class concept** in the Open Platform Model by introducing a `#Secret` type. Today, OPM treats all values identically — `db.host` and `db.password` flow through the same `#config` → `values` → transformer pipeline with no distinction. Passwords end up as plaintext strings in CUE files, git repositories, and rendered manifests.

The `#Secret` type tags a field as sensitive at the schema level. This single annotation propagates through every layer of OPM — from module definition, through release fulfillment, to transformer output — enabling the toolchain to redact, encrypt, and correctly dispatch secrets to platform-appropriate resources (K8s Secrets, ExternalSecrets, CSI volumes) without the module author managing any of that machinery.

The design supports three input paths (literal values, external references, CLI `@` tag injection) and two output targets (environment variables and volume mounts), while remaining backward compatible with existing modules.

---

## Table of Contents

1. [Motivation](#1-motivation)
2. [Core Concept: The #Secret Type](#2-core-concept-the-secret-type)
3. [Input Side: How Secrets Enter OPM](#3-input-side-how-secrets-enter-opm)
4. [Output Side: How Secrets Become Platform Resources](#4-output-side-how-secrets-become-platform-resources)
5. [The Wiring Model](#5-the-wiring-model)
6. [Provider Dispatch: Secret Source Handlers](#6-provider-dispatch-secret-source-handlers)
7. [Volume-Mounted Secrets](#7-volume-mounted-secrets)
8. [Unified Config and Secret Pattern](#8-unified-config-and-secret-pattern)
9. [Relationship to the Interface RFC](#9-relationship-to-the-interface-rfc)
10. [Backward Compatibility](#10-backward-compatibility)
11. [Experiment Learnings](#11-experiment-learnings)
12. [Pros and Cons](#12-pros-and-cons)
13. [Open Questions](#13-open-questions)

---

## 1. Motivation

### The Problem

OPM currently has no concept of "sensitive." Every value that passes through `#config` → `values` → transformer is a plain string:

```text
┌─────────────────────────────────────────────────────────────────┐
│  Module #config                                                 │
│                                                                 │
│  db: {                                                          │
│      host:     string     ← not sensitive                       │
│      password: string     ← sensitive, but OPM can't tell       │
│  }                                                              │
│                                                                 │
│  Both fields flow identically:                                  │
│    CUE file → git → rendered YAML → kubectl apply               │
│    Password is plaintext at every stage.                        │
└─────────────────────────────────────────────────────────────────┘
```

This creates several problems:

1. **No redaction**: `cue export` prints passwords alongside hostnames. Logs, CI output, and debugging sessions expose secrets.
2. **No encryption**: Stored CUE artifacts (module releases, rendered manifests) contain plaintext secrets.
3. **No external references**: There is no way to say "this value lives in Vault" or "use the existing K8s Secret called `db-creds`." The value must be inlined.
4. **No deferred resolution**: A module author cannot say "this secret must be provided at deploy time." They must either hardcode a default or leave the field unconstrained.
5. **No platform integration**: Transformers emit the same K8s resource structure for `host` and `password`. There is no dispatch to ExternalSecrets Operator, CSI drivers, or other secret management infrastructure.

### The Opportunity

If OPM knows which fields are sensitive, the entire toolchain can act on that knowledge:

- **Authors** mark fields as `#Secret` and wire them to containers — done. They do not manage how secrets are stored, fetched, or injected.
- **Users** choose how to provide secrets (literal, vault ref, `@` tag) at release time.
- **Tooling** redacts secrets in output, encrypts them in storage, validates that all required secrets are fulfilled before deploy.
- **Transformers** dispatch to the correct platform mechanism (K8s Secret, ExternalSecret CR, CSI volume) based on how the secret was provided.

### Why Now

The [Interface Architecture RFC](interface-architecture-rfc.md) introduces `provides`/`requires` with typed shapes. Those shapes include fields like `#Postgres.password` — currently typed as `string`. Without a sensitive data model, the Interface system has a blind spot: it can type-check that a password field exists, but it cannot ensure it is handled securely. This RFC fills that gap.

---

## 2. Core Concept: The #Secret Type

### Definition

`#Secret` is a **union type** that accepts three variants, each representing a different way to provide a sensitive value:

```cue
// A value that is sensitive. The field's type — not its runtime value —
// tells OPM (and its toolchain) that this data requires secure handling.
#Secret: string | #SecretLiteral | #SecretRef | #SecretDeferred
```

#### Variant 1: Literal

The user provides the actual secret value. This is the simplest path — backward compatible with how OPM works today. The value flows through the system and ends up in a K8s Secret resource.

```cue
#SecretLiteral: {
    value!: string
}
```

Use cases: dev/test environments, migrations, rapid prototyping, or organizations whose security posture permits it.

#### Variant 2: Reference

The user points to an external secret source. The value never enters OPM — the platform resolves it at deploy time.

```cue
#SecretRef: {
    // The type of secret source (e.g., "vault", "aws-sm", "gcp-sm", "k8s")
    source!: string

    // Provider-specific path to the secret
    path!: string

    // Key within the secret (when a secret contains multiple key-value pairs)
    key?: string

    // Pin to a specific version of the secret
    version?: string
}
```

Use cases: production environments with Vault, AWS Secrets Manager, GCP Secret Manager, or referencing existing K8s Secrets.

#### Variant 3: Deferred

The module author declares that a secret is required but provides no value or reference. This is a **contract** — it must be fulfilled before deployment.

```cue
#SecretDeferred: {
    required!: true

    // Human-readable description of what this secret is for
    description?: string
}
```

Use cases: module defaults ("you must provide a database password"), shared modules published to a registry, any case where the author cannot know the value at definition time.

### Semantic Tagging

The critical property of `#Secret` is not which variant is used — it is that **the field is typed as `#Secret` at all**. This is what distinguishes it from a plain `string`:

```text
┌──────────────────────────────────────────────────────────────┐
│                                                              │
│  log_level: string      → OPM treats as non-sensitive        │
│                           Appears in logs, exports, output   │
│                           Emitted as ConfigMap or plain env  │
│                                                              │
│  db_password: #Secret   → OPM treats as sensitive            │
│                           Redacted in logs and exports       │
│                           Emitted as K8s Secret              │
│                           Encrypted in stored artifacts      │
│                           Platform may resolve externally    │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

The type is the signal. The toolchain reads it.

### Value Constraints

Because `#Secret` is a CUE definition, module authors can constrain the `value` field using standard CUE expressions. No OPM-specific mechanism is needed — this is just CUE unification.

Constraints fire when the resolved `#Secret` is a `#SecretLiteral` (either written directly or injected via `@` tag). For `#SecretRef` and `#SecretDeferred`, the `value` field is not set, so constraints are inert — they serve as documentation of the expected format.

#### Simple: Minimum Length

```cue
#config: {
    db: password: #Secret & {
        value?: string & strings.MinRunes(12)
    }
}

// ✓ Passes
values: db: password: { value: "hunter2hunter2" }

// ✗ Fails: string too short
values: db: password: { value: "hunter2" }
```

#### Simple: Prefix Match

```cue
#config: {
    stripe_key: #Secret & {
        value?: string & =~"^sk_(test|live)_"
    }
}

// ✓ Passes
values: stripe_key: { value: "sk_live_abc123xyz" }

// ✗ Fails: wrong prefix
values: stripe_key: { value: "pk_live_abc123xyz" }
```

#### Moderate: PEM Certificate Format

```cue
#config: {
    tls_key: #Secret & {
        value?: string & =~"^-----BEGIN .* KEY-----"
    }
    tls_cert: #Secret & {
        value?: string & =~"^-----BEGIN CERTIFICATE-----"
    }
}
```

#### Moderate: Password Complexity

```cue
#config: {
    admin_password: #Secret & {
        // At least 16 characters, must contain uppercase, lowercase, and digit
        value?: string & =~"^.{16,}$" & =~".*[A-Z].*" & =~".*[a-z].*" & =~".*[0-9].*"
    }
}

// ✓ Passes
values: admin_password: { value: "MyStr0ngPa55word!!" }

// ✗ Fails: no uppercase letter
values: admin_password: { value: "mystr0ngpa55word!!" }
```

#### Advanced: Enum-Constrained Secret

```cue
#config: {
    // Database SSL mode — sensitive because it controls encryption behavior
    db_ssl_cert: #Secret & {
        value?: string & =~"^-----BEGIN CERTIFICATE-----"
    }
    db_ssl_mode: #Secret & {
        // Only allow secure modes in this module
        value?: "verify-ca" | "verify-full"
    }
}
```

#### Advanced: Composed Constraint Definitions

Module authors can define reusable constraint patterns:

```cue
// Reusable patterns for common secret formats
#PEMSecret: #Secret & {
    value?: string & =~"^-----BEGIN [A-Z ]+-----\n" & =~"\n-----END [A-Z ]+-----\n?$"
}

#StrongPasswordSecret: #Secret & {
    value?: string & =~"^.{16,}$" & =~".*[A-Z].*" & =~".*[a-z].*" & =~".*[0-9].*"
}

#APIKeySecret: {
    _prefix: string
    #Secret & {
        value?: string & =~"^\(_prefix)"
    }
}

// Usage in #config
#config: {
    tls_key:        #PEMSecret
    admin_password: #StrongPasswordSecret
    stripe_key:     #APIKeySecret & { _prefix: "sk_(test|live)_" }
    sendgrid_key:   #APIKeySecret & { _prefix: "SG\\." }
}
```

#### When Do Constraints Apply?

| Input Path | Constraints Validated? | Reason |
|---|---|---|
| `#SecretLiteral` `{ value: "..." }` | **Yes** | `value` is set — CUE evaluates constraints at eval time |
| `@` tag (CLI resolves to literal) | **Yes** | CLI injects `{ value: "..." }` — same CUE constraint fires |
| `#SecretRef` | **No** | `value` is not set — constraints are inert |
| `#SecretDeferred` | **No** | `value` is not set — constraints are inert |

For `#SecretRef` and `#SecretDeferred`, the constraints remain in the schema as machine-readable documentation. A platform tool that fetches secrets at deploy time could read these constraints and validate post-fetch — but that is outside CUE's evaluation scope and is a platform implementation choice.

---

## 3. Input Side: How Secrets Enter OPM

There are three paths for providing secret values. All three are valid and can coexist within a single module release.

### Path 1: Literal Values in ModuleRelease

The user writes the secret value directly in `values`. This is the current OPM pattern, now wrapped in `#SecretLiteral`:

```cue
// Module definition (developer)
#config: {
    db: {
        host:     string
        password: #Secret
    }
}

values: {
    db: {
        host:     "localhost"
        password: { required: true, description: "Database password" }
    }
}
```

```cue
// Module release (user)
values: {
    db: {
        host:     "db.prod.internal"
        password: { value: "my-secret-password" }
    }
}
```

### Path 2: External References in ModuleRelease

The user points to an external secret store:

```cue
// Module release (user)
values: {
    db: {
        host:     "db.prod.internal"
        password: {
            source: "vault"
            path:   "secret/data/prod/db"
            key:    "password"
        }
    }
}
```

Or referencing an existing K8s Secret:

```cue
values: {
    db: password: {
        source: "k8s"
        path:   "existing-db-secret"
        key:    "password"
    }
}
```

### Path 3: `@` Tag Injection (CLI Runtime)

CUE attributes (`@attr(...)`) are metadata annotations that survive evaluation. The OPM CLI reads `@secret(...)` tags and resolves them **before** CUE evaluation, injecting the fetched value as a `#SecretLiteral`:

```cue
// Module release (user)
values: {
    db: {
        host:     "db.prod.internal"
        password: _ @secret(vault, "secret/data/prod/db", "password")
    }
}
```

The CLI performs the following transformation at build time:

```text
BEFORE CLI processing:
    password: _ @secret(vault, "secret/data/prod/db", "password")

AFTER CLI processing (injected into CUE evaluation):
    password: { value: "the-actual-fetched-value" }
```

#### Key Design Decision: `@` Tags Are CLI Sugar

The `@secret(...)` tag is **not** part of the OPM schema. Module developers do not need to know about it. The developer declares `password: #Secret` — full stop. The `@` tag is one of several ways a user can fulfill that declaration. From the module's perspective, it is identical to the user having written `{ value: "..." }` directly.

This means:

- The developer's job does not change based on how secrets are provided.
- The CLI is responsible for `@` tag resolution. This is a CLI feature, not a schema feature.
- The result of `@` tag resolution is always a `#SecretLiteral` (the CLI fetches the value and wraps it).
- Future `@` tags (e.g., `@env("DB_PASSWORD")`, `@file("/run/secrets/db")`) can be added to the CLI without changing any schema.

### Summary of Input Paths

```text
┌────────────────────────────────────────────────────────────────────────┐
│                     HOW SECRETS ENTER OPM                              │
│                                                                        │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────────┐  │
│  │  Path 1: Literal │  │  Path 2: Ref     │  │  Path 3: @ Tag       │  │
│  │                  │  │                  │  │                      │  │
│  │  { value: "..." }│  │  { source: ".."  │  │  @secret(vault,...)  │  │
│  │                  │  │    path: "..."   │  │                      │  │
│  │  User provides   │  │    key: "..." }  │  │  CLI resolves to     │  │
│  │  the value.      │  │                  │  │  { value: "..." }    │  │
│  │                  │  │  Platform        │  │  before CUE eval.    │  │
│  │                  │  │  resolves at     │  │                      │  │
│  │                  │  │  deploy time.    │  │  Developer does not  │  │
│  │                  │  │                  │  │  need to support it. │  │
│  └────────┬─────────┘  └────────┬─────────┘  └──────────┬───────────┘  │
│           │                     │                       │              │
│           └─────────────────────┼───────────────────────┘              │
│                                 ▼                                      │
│                     ┌───────────────────┐                              │
│                     │  #Secret field    │                              │
│                     │  in #config       │                              │
│                     └───────────────────┘                              │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 4. Output Side: How Secrets Become Platform Resources

The transformer inspects the resolved `#Secret` value and produces different outputs depending on which variant it received.

### Dispatch Table

| Input Variant | K8s Resource Emitted | Env Var Wiring |
|---|---|---|
| `#SecretLiteral` `{ value: "..." }` | `Secret` (with `data: base64(value)`) | `valueFrom.secretKeyRef` → generated name |
| `#SecretRef` `source: "k8s"` | Nothing (resource exists in cluster) | `valueFrom.secretKeyRef` → `path` as name |
| `#SecretRef` `source: "vault"` | `ExternalSecret` CR (ESO) | `valueFrom.secretKeyRef` → generated name |
| `#SecretRef` `source: "aws-sm"` | `ExternalSecret` CR (ESO) | `valueFrom.secretKeyRef` → generated name |
| `#SecretDeferred` | **Validation error** — blocks deploy | — |

### Resource Naming

For literals and external-store refs (vault, aws-sm, etc.), the transformer generates a K8s Secret name using the pattern `{component}-{config-path}`:

```text
Component: "user-api"
Config path: "db.password"
→ K8s Secret name: "user-api-db-password"
→ K8s Secret key: "password" (leaf key of the config path)
```

For `source: "k8s"`, the `path` field IS the K8s Secret name — no generation needed.

### Output Examples

#### Literal → K8s Secret

```yaml
# Input: values: db: password: { value: "my-secret" }

apiVersion: v1
kind: Secret
metadata:
  name: user-api-db-password
  namespace: production
type: Opaque
data:
  password: bXktc2VjcmV0    # base64("my-secret")
```

#### Vault Ref → ExternalSecret (ESO)

```yaml
# Input: values: db: password: { source: "vault", path: "secret/data/prod/db", key: "password" }

apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: user-api-db-password
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-backend        # from provider config
    kind: ClusterSecretStore
  target:
    name: user-api-db-password
  data:
    - secretKey: password
      remoteRef:
        key: secret/data/prod/db
        property: password
```

#### K8s Ref → Nothing

```yaml
# Input: values: db: password: { source: "k8s", path: "existing-db-secret", key: "password" }
#
# No resource emitted — the Secret already exists in the cluster.
# The env var references it directly:
#   valueFrom:
#     secretKeyRef:
#       name: existing-db-secret
#       key: password
```

### Consistent Env Var Output

Regardless of the input variant, the container's env var wiring is always `valueFrom.secretKeyRef`. What changes is the `name` the ref points to:

```text
┌─────────────────────┐      ┌──────────────────────────────────┐
│  #SecretLiteral     │────▶│  name: "user-api-db-password"    │  (generated Secret)
│  #SecretRef (vault) │────▶│  name: "user-api-db-password"    │  (ESO-managed Secret)
│  #SecretRef (k8s)   │────▶│  name: "existing-db-secret"      │  (pre-existing Secret)
└─────────────────────┘      └──────────────────────────────────┘
                                       │
                                       ▼
                            env:
                              - name: DB_PASSWORD
                                valueFrom:
                                  secretKeyRef:
                                    name: <resolved-name>
                                    key: password
```

---

## 5. The Wiring Model

### Direct Config Reference

Developers wire secrets (and config) to container env vars using a direct CUE expression that references the `#config` field:

```cue
#config: {
    log_level: string
    db: {
        host:     string
        password: #Secret
    }
}

spec: container: env: {
    LOG_LEVEL:   { name: "LOG_LEVEL",   from: #config.log_level }
    DB_HOST:     { name: "DB_HOST",     from: #config.db.host }
    DB_PASSWORD: { name: "DB_PASSWORD", from: #config.db.password }
}
```

The `from` field is a CUE expression that resolves to either a `string` (non-sensitive config) or a `#Secret` (sensitive). The transformer inspects the resolved type and decides how to emit:

```text
from: #config.log_level
  → resolves to string
  → emit as plain env value:  { value: "info" }

from: #config.db.password
  → resolves to #Secret
  → emit as secretKeyRef:    { valueFrom: { secretKeyRef: { name: ..., key: ... } } }
```

### Why Direct References

This replaces the experiment's `env.from: { source: "app-settings", key: "LOG_LEVEL" }` pattern — which required looking up a named `configSources` resource and resolving the key at transform time. Direct references are:

1. **Type-safe**: CUE validates the reference at definition time. `from: #config.db.pasword` (typo) fails immediately.
2. **Self-documenting**: The wiring reads as "this env var comes from that config field." No indirection through named sources.
3. **Unified**: The same `from:` syntax works for config and secrets. The type of the source determines the output.

### The EnvVar Schema

```cue
#EnvVarSchema: {
    name!: string

    // Exactly one of value or from MUST be set.
    // value: inline literal (backward compatible, non-sensitive only)
    value?: string

    // from: reference to a #config field (config or secret)
    from?: _
}
```

When `from` resolves to a `#Secret`, the transformer handles it as sensitive. When it resolves to a plain `string`, the transformer emits a plain value.

---

## 6. Provider Dispatch: Secret Source Handlers

### The Handler Interface

The K8s provider registers handlers for each secret source type. A handler takes a `#SecretRef` and produces K8s resources plus a `secretKeyRef` for env var wiring:

```cue
#SecretSourceHandler: {
    #resolve: {
        // Input
        #ref:       #SecretRef
        #component: _
        #context:   #TransformerContext

        // Output: K8s resources to emit (may be empty for source: "k8s")
        resources: [string]: {...}

        // Output: the secretKeyRef for env/volume wiring
        secretKeyRef: {
            name!: string
            key!:  string
        }
    }
}
```

### Registered Handlers

```cue
// In providers/kubernetes/provider.cue
#SecretSourceHandlers: {
    // Built-in: reference to existing K8s Secret
    "k8s": #K8sSecretHandler

    // ESO-backed providers
    "vault":  #ExternalSecretHandler & { _backendRef: "vault-backend" }
    "aws-sm": #ExternalSecretHandler & { _backendRef: "aws-sm-backend" }
    "gcp-sm": #ExternalSecretHandler & { _backendRef: "gcp-sm-backend" }

    // Platform teams extend with their own
    [string]: #SecretSourceHandler
}
```

### K8s Secret Handler

The simplest handler — the secret already exists:

```cue
#K8sSecretHandler: #SecretSourceHandler & {
    #resolve: {
        resources: {}     // nothing to emit
        secretKeyRef: {
            name: #ref.path
            key:  #ref.key
        }
    }
}
```

### ExternalSecret Handler (ESO)

Emits an `ExternalSecret` CR that tells ESO to fetch from the configured backend:

```cue
#ExternalSecretHandler: #SecretSourceHandler & {
    _backendRef: string

    #resolve: {
        let _name = "\(#component.metadata.name)-\(#ref.key)"

        resources: {
            "\(_name)": {
                apiVersion: "external-secrets.io/v1beta1"
                kind:       "ExternalSecret"
                metadata: {
                    name:      _name
                    namespace: #context.namespace
                    labels:    #context.labels
                }
                spec: {
                    refreshInterval: "1h"
                    secretStoreRef: {
                        name: _backendRef
                        kind: "ClusterSecretStore"
                    }
                    target: name: _name
                    data: [{
                        secretKey: #ref.key
                        remoteRef: {
                            key:      #ref.path
                            property: #ref.key
                        }
                    }]
                }
            }
        }

        secretKeyRef: {
            name: _name
            key:  #ref.key
        }
    }
}
```

### Configuration of Backend References

The handler uses `_backendRef` to reference a `ClusterSecretStore` or `SecretStore` already deployed in the cluster. Where that store is configured is a platform-level concern:

```text
┌─────────────────────────────────────────────────────────────────┐
│  Platform Responsibility (outside OPM module scope)             │
│                                                                 │
│  1. Deploy ClusterSecretStore CRs (vault-backend, aws-sm, etc.) │
│  2. Configure ESO with credentials to access backends           │
│  3. Register handler names in the K8s provider config           │
│                                                                 │
│  OPM's responsibility:                                          │
│  1. Emit ExternalSecret CRs that reference those stores         │
│  2. Wire the resulting K8s Secret into the container env/vol    │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. Volume-Mounted Secrets

Not all secrets are environment variables. TLS certificates, service account keys, and credential files are mounted as volumes. The same `#Secret` type handles both cases — what differs is the wiring target.

### Env Var Wiring (from Section 5)

```cue
env: {
    DB_PASSWORD: { name: "DB_PASSWORD", from: #config.db.password }
}
```

### Volume Mount Wiring

```cue
volumeMounts: {
    "tls-cert": {
        mountPath: "/etc/tls"
        from:      #config.tls
    }
}
```

When `from` resolves to a `#Secret`, the transformer emits:

1. A K8s `Secret` resource (or `ExternalSecret` CR, depending on variant)
2. A `volume` entry on the pod spec referencing that Secret
3. A `volumeMount` on the container at the specified `mountPath`

```yaml
# Transformer output for volume-mounted secret
spec:
  volumes:
    - name: tls-cert
      secret:
        secretName: user-api-tls    # generated or resolved name
  containers:
    - name: user-api
      volumeMounts:
        - name: tls-cert
          mountPath: /etc/tls
          readOnly: true
```

### Multi-Key Secrets as Volumes

When a `#Secret` reference points to a secret with multiple keys, each key becomes a file in the mounted volume:

```cue
#config: {
    tls: #Secret   // could resolve to a secret with "tls.crt" and "tls.key"
}

volumeMounts: {
    "tls": {
        mountPath: "/etc/tls"
        from:      #config.tls
        // Results in:
        //   /etc/tls/tls.crt
        //   /etc/tls/tls.key
    }
}
```

---

## 8. Unified Config and Secret Pattern

Config (non-sensitive) and secrets (sensitive) use the same wiring pattern. The type of the source field determines the transformer's output behavior.

### Developer Experience

```cue
#config: {
    // Non-sensitive config — plain strings
    log_level:  string
    app_port:   int

    // Sensitive data — #Secret type
    db_password: #Secret
    api_key:     #Secret
    tls:         #Secret
}

spec: container: {
    env: {
        // All use the same from: syntax
        LOG_LEVEL:   { name: "LOG_LEVEL",   from: #config.log_level }
        APP_PORT:    { name: "APP_PORT",    from: "\(#config.app_port)" }
        DB_PASSWORD: { name: "DB_PASSWORD", from: #config.db_password }
        API_KEY:     { name: "API_KEY",     from: #config.api_key }
    }
    volumeMounts: {
        "tls": { mountPath: "/etc/tls", from: #config.tls }
    }
}
```

### Transformer Behavior by Source Type

```text
from: #config.log_level
  type: string
  ──▶ emit plain env var: { value: "info" }
      optionally: emit ConfigMap entry

from: #config.db_password
  type: #Secret
  ──▶ emit K8s Secret (or ExternalSecret)
      emit env var: { valueFrom: { secretKeyRef: { ... } } }

from: #config.tls
  type: #Secret (in volumeMount context)
  ──▶ emit K8s Secret (or ExternalSecret)
      emit volume + volumeMount
```

### Config Aggregation (Optional)

When multiple non-sensitive `from:` references exist, the transformer MAY aggregate them into a single ConfigMap per component:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: user-api-config
data:
  LOG_LEVEL: info
  APP_PORT: "8080"
```

This is an optimization, not a requirement. The transformer MAY also emit individual env vars with `value:` directly. The behavior is provider-specific.

---

## 9. Relationship to the Interface RFC

The [Interface Architecture RFC](interface-architecture-rfc.md) defines `provides`/`requires` with typed shapes. This RFC upgrades the sensitive fields in those shapes from `string` to `#Secret`.

### Before (Interface RFC as written)

```cue
#PostgresInterface: #Interface & {
    #shape: {
        host!:     string
        port:      uint | *5432
        dbName!:   string
        username!: string
        password!: string     // ← no sensitivity distinction
    }
}
```

### After (with this RFC)

```cue
#PostgresInterface: #Interface & {
    #shape: {
        host!:     string
        port:      uint | *5432
        dbName!:   string
        username!: string
        password!: #Secret    // ← now typed as sensitive
    }
}
```

### Impact on Platform Fulfillment

When the platform fulfills a `requires: { "db": #Postgres }`, it must provide a `#Secret` for `password`:

```cue
// Platform binding
bindings: {
    "user-api": requires: "db": {
        host:     "db.prod.internal"
        port:     5432
        dbName:   "users"
        username: "app"
        password: {
            source: "vault"
            path:   "secret/data/prod/db"
            key:    "password"
        }
    }
}
```

### Impact on Module Author Wiring

The module author's env var wiring works identically — `from:` references the interface field, and the transformer dispatches based on type:

```cue
requires: {
    "db": #Postgres
}

spec: container: env: {
    DB_HOST:     { name: "DB_HOST",     from: requires.db.host }        // string → plain value
    DB_PASSWORD: { name: "DB_PASSWORD", from: requires.db.password }    // #Secret → secretKeyRef
}
```

The module author does not know or care whether `password` was fulfilled with a literal, a Vault ref, or a K8s Secret ref. The wiring is the same.

---

## 10. Backward Compatibility

### Phase 1: Introduction (Non-Breaking)

`#Secret` accepts `string` as a shorthand for `#SecretLiteral`:

```cue
// Full form
password: #Secret & { value: "my-password" }

// Shorthand (string coerced to #SecretLiteral)
password: "my-password"    // → #SecretLiteral & { value: "my-password" }
```

Existing modules that pass plaintext strings into fields that become `#Secret` continue to work without modification.

### Phase 2: Warnings

The OPM CLI emits warnings when literal strings are used in `#Secret` fields:

```text
⚠ WARNING: db.password is a #Secret field with a literal value.
  Consider using a #SecretRef or @secret() tag for production.
```

This is a CLI behavior, not a CUE validation error. `cue vet` still passes.

### Phase 3: Strict Mode (Optional)

Organizations that require external secret management can enable strict mode in their platform policy:

```cue
// Policy rule: no literal secrets in production
#NoLiteralSecrets: #PolicyRule & {
    // Validates that no #Secret field in the release is a #SecretLiteral
}
```

This is opt-in. The default behavior always permits literals.

---

## 11. Experiment Learnings

The `config-sources` experiment (`experiments/001-config-sources/`) prototyped an earlier version of this design. Key learnings:

### What Worked

| Experiment Feature | Status |
|---|---|
| `#ConfigSourceSchema` with `type: "config" \| "secret"` discriminator | Validated the need for sensitivity tagging |
| `env.from: { source, key }` wiring | Validated that env vars need reference syntax beyond plain `value:` |
| Transformer dispatch (ConfigMap vs Secret based on type) | Validated that output differs based on sensitivity |
| External refs (`externalRef.name`) emitting nothing | Validated the "pre-existing resource" pattern |
| K8s resource naming `{component}-{source}` | Validated predictable naming |

### What Changes

| Experiment Approach | This RFC's Approach | Why |
|---|---|---|
| `configSources` as a separate component resource | `#Secret` as a type in `#config` | Secrets belong at the schema level, not as a parallel resource. The type system is the right place for sensitivity annotations. |
| `env.from: { source: "app-settings", key: "LOG_LEVEL" }` | `env.from: #config.log_level` | Direct CUE references are type-safe and self-documenting. No indirection through named sources. |
| `data` + `externalRef` mutual exclusivity | `#SecretLiteral` \| `#SecretRef` \| `#SecretDeferred` union | Cleaner CUE modeling. Each variant is its own type with explicit fields. |
| Config and secrets unified in `configSources` | Config is plain `string`, secrets are `#Secret`, wiring is unified via `from:` | Sensitivity is a property of the VALUE, not a property of a container resource. But the wiring pattern stays unified. |

### What Carries Forward

- The transformer dispatch pattern (literal → K8s Secret, external → nothing, etc.)
- The consistent env var output (`valueFrom.secretKeyRef` for all secret variants)
- The provider handler interface concept
- The naming convention for generated K8s resources

---

## 12. Pros and Cons

### Pros

| Advantage | Description |
|---|---|
| **Type-safe sensitivity** | `#Secret` is checked by CUE at definition time. A `string` field cannot accidentally receive a `#SecretRef`. |
| **Developer simplicity** | Author declares `#Secret`, wires with `from:`. Does not manage secret stores, injection, or encryption. |
| **User flexibility** | Three input paths (literal, ref, `@` tag) cover all deployment scenarios from dev to production. |
| **Toolchain awareness** | Every tool in the pipeline (CLI, export, CI, transformer) can distinguish sensitive from non-sensitive. |
| **Platform portability** | Module says `#Secret`. K8s provider emits K8s Secret or ExternalSecret. Future providers emit their equivalent. |
| **Backward compatible** | `#Secret` accepts `string`. Existing modules work unchanged. |
| **Interface RFC alignment** | `#Postgres.password: #Secret` makes interface shapes security-aware. |
| **Unified wiring** | `from:` works identically for config and secrets. One pattern to learn. |

### Cons

| Disadvantage | Description |
|---|---|
| **New core type** | `#Secret` is a new concept developers must learn. Adds to the already rich type vocabulary (Resource, Trait, Blueprint, Interface). |
| **CUE union complexity** | `#SecretLiteral \| #SecretRef \| #SecretDeferred` is a three-way disjunction. CUE's disjunction handling can produce confusing error messages. |
| **Provider handler implementation** | Each secret source (vault, aws-sm, gcp-sm) needs a handler. Platform teams must implement and maintain these. |
| **`@` tag requires CLI support** | The `@secret(...)` tag is useless without OPM CLI implementation. This RFC defines the contract; the CLI must deliver. |
| **String shorthand ambiguity** | If `#Secret` accepts `string`, a module author might not realize a field is sensitive. The shorthand trades clarity for convenience. |
| **ESO dependency** | The vault/aws-sm/gcp-sm handlers assume External Secrets Operator is deployed. This is a platform prerequisite, not an OPM one — but it narrows the "just works" scope. |

### Risk Assessment

| Risk | Severity | Likelihood | Mitigation |
|---|---|---|---|
| CUE cannot cleanly express `string \| struct` disjunction for `#Secret` | High | Medium | Prototype in CUE before committing. May need wrapper struct for all variants. |
| `@` tag resolution in CLI is complex (multi-provider auth) | Medium | High | Start with `@secret(k8s, ...)` only. Add vault/aws-sm incrementally. |
| ExternalSecret CRD version drift | Low | Medium | Pin to ESO v1beta1 API. Abstract behind handler interface. |
| Developers ignore `#Secret` and use `string` everywhere | Medium | Medium | Lint rules in CI. Policy rules for production namespaces. |

---

## 13. Open Questions

### Q1: CUE Representation of `#Secret`

**Question**: Can CUE cleanly express `#Secret: string | #SecretLiteral | #SecretRef | #SecretDeferred`? The `string | struct` disjunction in CUE can produce unclear error messages when validation fails.

**Options**:

- A. True disjunction: `#Secret: string | #SecretLiteral | #SecretRef | #SecretDeferred`
- B. Wrapper struct with discriminator: `#Secret: { type: "literal" | "ref" | "deferred", ... }`
- C. Always-struct: `#SecretLiteral: { value: string }` — no bare `string` shorthand

**Impact**: Option A is the most ergonomic but may have CUE limitations. Option C is the safest but requires wrapping every literal. Option B adds a discriminator field that feels heavy for simple cases.

**Recommendation**: Prototype all three in a CUE experiment. Prioritize error message clarity.

### Q2: `@` Tag Syntax

**Question**: What is the exact attribute syntax? CUE attributes have the form `@attr(arg1, arg2, ...)` where args are comma-separated tokens.

**Options**:

- A. `@secret(source, path, key)` — positional: `@secret(vault, "secret/data/db", "password")`
- B. `@secret(source=vault, path="secret/data/db", key=password)` — named
- C. `@secret("vault:secret/data/db#password")` — URI-style

**Recommendation**: Option B for clarity. Named parameters are self-documenting and extensible.

### Q3: Config Aggregation Strategy

**Question**: When multiple `from:` references point to non-sensitive `string` config fields, should the transformer aggregate them into a single ConfigMap or emit individual env vars?

**Options**:

- A. Always aggregate into one ConfigMap per component
- B. Always emit individual `env.value` entries
- C. Configurable per provider

**Recommendation**: Option C. The transformer should have a sensible default (A) but allow providers to override.

### Q4: `#SecretDeferred` Metadata

**Question**: Should `#SecretDeferred` carry hints about the secret's expected properties?

```cue
#SecretDeferred: {
    required!:    true
    description?: string
    // Potential additions:
    rotation?:    string    // "90d", "never"
    format?:      string    // "alphanumeric", "pem", "base64"
    minLength?:   int
}
```

**Impact**: Hints help platform teams and operators understand what kind of secret to provision. But they add schema surface area.

**Recommendation**: Start with `description` only. Add hints in a future iteration based on demand.

### Q5: SecretStore Configuration

**Question**: Where does the user specify which `ClusterSecretStore` to use for a given `source` type?

**Options**:

- A. Provider-level config (global per cluster)
- B. Module release-level config (per deployment)
- C. Policy-level config (per environment)

**Recommendation**: Option C. Secret store configuration is an environment-level concern. A production policy uses `vault-prod-backend`, a staging policy uses `vault-staging-backend`. This aligns with the Interface RFC's platform fulfillment model.

### Q6: Interaction with Volume Resources

**Question**: The existing `#VolumeSchema` handles PVC-based volumes. How does `#Secret`-based volume mounting interact with the existing volume system?

**Options**:

- A. `#Secret` volumes are a separate concept from PVC volumes (different wiring syntax)
- B. Unify: `volumeMounts.from` can resolve to either a volume resource or a `#Secret`
- C. `#Secret` volumes use the existing volume system with a new volume type

**Recommendation**: Option A for now. PVC volumes and secret volumes have different lifecycle and security properties. Unification can come later if patterns converge.

---

## Summary

The Sensitive Data Model introduces `#Secret` as a first-class type in OPM, making sensitivity a property of the schema rather than an afterthought. By tagging fields as `#Secret`, the entire toolchain — from module definition through CLI processing to transformer output — can handle sensitive data appropriately.

The design supports the full spectrum of secret management maturity:

- **Day 1**: Literal values in module releases (backward compatible, works today)
- **Day 2**: `@secret(...)` tags for CLI-time injection from external stores
- **Day 3**: `#SecretRef` for fully declarative, deploy-time resolution via ESO or equivalent
- **Day N**: Platform policies that enforce external-only secrets in production

The unified `from:` wiring pattern means developers learn one syntax for both config and secrets. The type of the source field determines the output — ConfigMap entry or K8s Secret, plain env var or `valueFrom.secretKeyRef`, volume mount with ConfigMap or Secret backend.

Combined with the Interface Architecture RFC, this gives OPM a complete story: interfaces define what an application communicates, and the sensitive data model ensures that the sensitive parts of those communications are handled with the security properties they require.
