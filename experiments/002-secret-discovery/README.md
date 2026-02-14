# Experiment 002: Secret Discovery & Auto-Grouping

Auto-discover `#Secret` fields from resolved `#config` values using CUE
comprehensions with a negation-based discriminator test. Group discovered
secrets by `$secretName` to generate `spec.secrets` automatically — no
explicit bridging layer required.

## Problem

RFC-0005 required module authors to manually bridge `#config` secret fields
into `spec.secrets` (a "Layer 2" declaration). This was boilerplate: the
author declared the secret in `#config`, then repeated the grouping in
`spec.secrets`, then wired it in env vars. Three steps for every secret.

The question: can we eliminate the bridging layer by auto-discovering
`#Secret` fields from the resolved config?

## Solution

### 1. `#Secret` as Contract + Routing

Module authors annotate fields with `#Secret`, setting routing info:

```cue
#config: {
    dbUser:     #Secret & {$secretName: "db-credentials", $dataKey: "username"}
    dbPassword: #Secret & {$secretName: "db-credentials", $dataKey: "password"}
    logLevel:   string
}
```

Users fulfill with a variant (literal value or reference):

```cue
values: #config & {
    dbUser:     {value: "admin"}                                       // #SecretLiteral
    dbPassword: {source: "k8s", path: "myapp-secrets", remoteKey: "pw"} // #SecretRef
    logLevel:   "info"
}
```

### 2. Negation-Based Discovery

The discriminator `$opm: "secret"` is set on all `#Secret` variants. To test if a value is a secret, we use:

```cue
(v & {$opm: !="secret", ...}) == _|_
```

This produces bottom ONLY when `$opm` is already `"secret"`. For any other value:

- **Scalars** (string, int): fail the struct check — correctly skipped
- **Anonymous open structs**: `$opm: !="secret"` is added without conflict — correctly skipped
- **Closed definition structs**: `$opm` is rejected as disallowed field — correctly skipped

No false positives regardless of struct closedness.

### 3. Three-Level Traversal

CUE has no recursion. The discovery comprehension manually traverses up to
3 levels deep, which covers the practical nesting patterns:

- Level 1: `#config.dbUser`
- Level 2: `#config.cache.password`
- Level 3: `#config.integrations.payments.stripeKey`

### 4. Auto-Grouping

Discovered secrets are grouped by `$secretName` / `$dataKey`:

```cue
spec: secrets: {
    for _k, v in _discovered {
        (v.$secretName): (v.$dataKey): v
    }
}
```

This produces the K8s Secret resource layout automatically. Mixed variants
(literal + ref in the same group) are handled per-entry by the transformer.

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| `#Secret` is a disjunction | `#SecretLiteral \| #SecretRef` | Author writes `#Secret` (contract); user picks variant |
| `$opm: "secret"` discriminator | Concrete value on every variant | Enables CUE-native discovery via negation test |
| `$secretName` / `$dataKey` | Set by author, propagated by CUE unification | Routing info without a bridging layer |
| `remoteKey` on `#SecretRef` | Separate from `$dataKey` | External key may differ from logical key |
| Negation test | `(v & {$opm: !="secret", ...}) == _|_` | No false positives on anonymous open structs |
| 3-level nesting | Fixed comprehension depth | Covers practical cases; CUE has no recursion |
| `source` defaults to `"k8s"` | `*"k8s" \| "esc"` | Most refs point to pre-existing K8s Secrets |

## Running

```bash
# Validate
cue vet main.cue

# View discovered secrets
cue eval main.cue -e _discovered --all

# View auto-grouped spec.secrets
cue eval main.cue -e spec.secrets --all

# View simulated K8s resource output
cue eval main.cue -e _transformerOutput --all

# View simulated env var wiring
cue eval main.cue -e _envTransformerOutput --all
```

## Test Coverage

The experiment validates:

- [x] Flat secrets (level 1): `dbUser`, `dbPassword`, `apiKey`
- [x] Nested secrets (level 2): `cache.password`
- [x] Deeply nested secrets (level 3): `integrations.payments.stripeKey`, etc.
- [x] Mixed variants in same group: `db-credentials` has literal + k8s ref
- [x] Anonymous open structs not false-positive: `database: {host, port}`
- [x] Scalar fields correctly skipped: `logLevel` (string), `replicas` (int)
- [x] ESC ref creates ExternalSecret CR: `cache.password`
- [x] K8s ref emits no resource: `dbPassword`
- [x] Multi-key Secret grouping: `stripe-credentials` has two entries
- [x] Env var wiring: literals use `$secretName/$dataKey`, refs use `path/remoteKey`

## Related

- [RFC-0002: Sensitive Data Model](../../../cli/docs/rfc/0002-sensitive-data-model.md)
- [RFC-0005: Environment & Config Wiring](../../../cli/docs/rfc/0005-env-config-wiring.md)
- [Experiment 001: Config Sources](../001-config-sources/)
