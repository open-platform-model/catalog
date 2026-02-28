# CLI: Auto-Secrets Component Generation from `_autoSecrets`

## Overview

When a module's `#config` contains fields typed as `#Secret`, OPM must create a
`opm-secrets` component at deploy time to manage the corresponding Kubernetes
Secret resources. This document describes how the CLI should do this using the
`_autoSecrets` computed field on `#ModuleRelease`.

## Why the CLI, Not CUE

CUE cannot generate the `opm-secrets` component inside `core/module_release.cue`
because doing so requires importing `resources/config` (for `#SecretsResource` /
`#Secrets`), which in turn imports `core`. That creates a circular dependency:

```
core → resources/config → core   [CYCLE — not allowed]
```

`core` CAN import `schemas` (no cycle), so `_autoSecrets` is computed in CUE
using `schemas.#AutoSecrets`. The CLI reads this pre-computed field and builds
the `opm-secrets` component in Go before passing components to transformers.

## The `_autoSecrets` Field

```cue
// In #ModuleRelease (core/module_release.cue)
_autoSecrets: (schemas.#AutoSecrets & {#in: _module.#config}).out
```

`_autoSecrets` is a hidden field (CLI-readable, not user-facing). Its type is:

```
{
    [secretName: string]: {
        [dataKey: string]: #Secret  // one of #SecretLiteral | #SecretK8sRef | #SecretEsoRef
    }
}
```

**Example** — given a module config:

```cue
#config: {
    dbUser: schemas.#Secret & {$secretName: "db-creds", $dataKey: "username"}
    dbPass: schemas.#Secret & {$secretName: "db-creds", $dataKey: "password"}
    apiKey: schemas.#Secret & {$secretName: "api-keys", $dataKey: "stripe"}
}
```

...and values:

```cue
values: {
    dbUser: {value: "admin"}          // #SecretLiteral
    dbPass: {secretName: "pg-secret", remoteKey: "pass"}  // #SecretK8sRef
    apiKey: {externalPath: "stripe/prod", remoteKey: "key"}  // #SecretEsoRef
}
```

`_autoSecrets` resolves to:

```json
{
    "db-creds": {
        "username": {"$opm": "secret", "$secretName": "db-creds", "$dataKey": "username", "value": "admin"},
        "password": {"$opm": "secret", "$secretName": "db-creds", "$dataKey": "password", "secretName": "pg-secret", "remoteKey": "pass"}
    },
    "api-keys": {
        "stripe": {"$opm": "secret", "$secretName": "api-keys", "$dataKey": "stripe", "externalPath": "stripe/prod", "remoteKey": "key"}
    }
}
```

## CLI Algorithm

After evaluating the `#ModuleRelease` CUE value, the CLI MUST:

### Step 1: Read `_autoSecrets`

```go
autoSecrets := release.LookupPath(cue.MakePath(cue.Hid("_autoSecrets", "_")))
// If the field is bottom (error) or empty struct, skip steps 2-4.
```

### Step 2: Build the `opm-secrets` component value

Construct the equivalent of:

```cue
"opm-secrets": resources_config.#Secrets & {
    metadata: {
        name: "opm-secrets"
        annotations: {
            "transformer.opmodel.dev/list-output": true
        }
    }
    spec: secrets: {
        for sName, entries in _autoSecrets {
            (sName): {
                name: sName      // auto-populated (mirrors map-key defaulting in #SecretsResource)
                data: entries
            }
        }
    }
}
```

The Go struct to marshal into the CUE value:

```go
type autoSecretsComponent struct {
    Metadata struct {
        Name        string            `json:"name"`
        Annotations map[string]any    `json:"annotations"`
    } `json:"metadata"`
    Spec struct {
        Secrets map[string]secretEntry `json:"secrets"`
    } `json:"spec"`
}

type secretEntry struct {
    Name string         `json:"name"`
    Data map[string]any `json:"data"` // raw #Secret values from CUE
}
```

### Step 3: Unify with `resources/config.#Secrets`

The synthesized component must be unified with `resources/config.#Secrets` so
that `#SecretTransformer` can recognize it via its `requiredResources` lookup
(`"opmodel.dev/resources/config/secrets@v1"`). The `#resources` map on `#Secrets`
carries the correct FQN automatically.

### Step 4: Inject into the release's component map

Add `"opm-secrets"` to the components passed to the transformer pipeline,
**only when `_autoSecrets` is non-empty**.

```go
if len(autoSecrets) > 0 {
    components["opm-secrets"] = buildOpmSecretsComponent(autoSecrets)
}
```

The injected component is then processed by `#SecretTransformer` exactly like
any user-defined Secrets component.

## Transformer Behavior (No CLI Changes Needed)

`#SecretTransformer` already handles all three variants correctly:

```
┌─────────────────┬─────────────────────────────────────────────────────┐
│ Variant         │ Transformer output                                   │
├─────────────────┼─────────────────────────────────────────────────────┤
│ #SecretLiteral  │ K8s Secret (stringData entry)                        │
│ #SecretK8sRef   │ Nothing emitted — Secret pre-exists in cluster       │
│ #SecretEsoRef   │ ExternalSecret CR (external-secrets.io/v1beta1)      │
└─────────────────┴─────────────────────────────────────────────────────┘
```

Mixed variants within a single `$secretName` group are fully supported:
literal entries produce a K8s Secret, ESO entries produce ExternalSecret CRs,
K8s refs are silently skipped.

## Naming

The K8s Secret name is computed by `#SecretImmutableName` inside the transformer:

- Non-immutable: `<$secretName>` (e.g., `db-creds`)
- Immutable: `<$secretName>-<10-char-hash>` (e.g., `db-creds-a3f9c12e4b`)

The hash is content-based (SHA256 of sorted key=value pairs), ensuring a new
name whenever the secret data changes — safe for immutable K8s Secrets.

## Env Var Wiring (Container Side)

Container env vars that reference `#Secret` fields use `from:` notation in the
module config. The `container_helpers.cue` `#ToK8sEnvVars` helper dispatches
per variant at render time:

```
┌─────────────────┬─────────────────────────────────────────────────────┐
│ Variant         │ K8s env var source                                   │
├─────────────────┼─────────────────────────────────────────────────────┤
│ #SecretLiteral  │ secretKeyRef: {name: $secretName, key: $dataKey}     │
│ #SecretK8sRef   │ secretKeyRef: {name: secretName, key: remoteKey}     │
│ #SecretEsoRef   │ secretKeyRef: {name: $secretName, key: $dataKey}     │
└─────────────────┴─────────────────────────────────────────────────────┘
```

The distinction: `#SecretK8sRef` uses its own `secretName`/`remoteKey` (the
pre-existing K8s Secret), while Literal and EsoRef both reference the
OPM-managed Secret via `$secretName`/`$dataKey`.

## Sequence Diagram

```
User             CUE (#ModuleRelease)        CLI                  Transformers
 |                      |                     |                        |
 |-- values ----------->|                     |                        |
 |                      |-- _autoSecrets ---->|                        |
 |                      |   (computed)        |                        |
 |                      |                     |-- build opm-secrets -->|
 |                      |                     |   component            |
 |                      |                     |                        |
 |                      |-- components ------>|                        |
 |                      |   (user-defined)    |-- merge + dispatch --->|
 |                      |                     |                        |
 |                      |                     |<-- K8s manifests ------|
 |<-- rendered manifests (Secrets / ExternalSecrets / Deployments) ----|
```

## Edge Cases

- **No secrets**: `_autoSecrets` is an empty struct `{}`. CLI skips injection.
- **Only K8sRef entries**: No K8s Secret emitted by transformer; only env var
  wiring is produced.
- **Collision with user component**: If the user defines a component named
  `opm-secrets` in their module, the CLI MUST error with a clear message:
  `"component name 'opm-secrets' is reserved for auto-secret injection"`.
- **Nested config fields**: `#DiscoverSecrets` traverses up to 3 levels of
  nesting. Secrets deeper than 3 levels are silently ignored — document this
  as a module author constraint.
