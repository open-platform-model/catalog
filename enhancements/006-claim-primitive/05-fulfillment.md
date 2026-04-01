# Platform Fulfillment — `#Claim` Primitive

| Field       | Value            |
| ----------- | ---------------- |
| **Status**  | Draft            |
| **Created** | 2026-03-29       |
| **Authors** | OPM Contributors |

---

## Overview

The platform fulfills Claims and Orchestrations through two mechanisms:

- **Data claims** (`#shape`): Platform injects concrete values into the claim's shape fields at deploy time
- **Operational claims** (no `#shape`): Transformers generate platform resources (K8up Schedule, etc.) at deploy time
- **Orchestrations**: The CLI/controller reads orchestration specs to execute operations at operation time

---

## Data Claim Fulfillment

### Strategy 1: External Binding (v1 primary)

The release author provides concrete values:

```cue
// releases/production/user-service/release.cue
values: {
    postgres: {
        host:     "prod-db.rds.amazonaws.com"
        port:     5432
        dbName:   "users"
        username: "app"
        password: { secretName: "db-creds", remoteKey: "password" }
    }
}
```

The platform unifies these values into the claim's `#shape`, making `spec.postgres.host` resolve to `"prod-db.rds.amazonaws.com"`.

### Strategy 2: Platform Provisioning (DaaS, future)

The platform provisions a managed service when no binding is provided. Deferred — v1 requires explicit bindings.

### Strategy 3: Cross-Module Matching (requires `#Offer`)

When a module declares an `#Offer` (enhancement 007), the Platform can match Claims to Offers across modules. The Offer carries linked Transformers for capability claims and `#shape` for data claims. See [007-offer-primitive](../007-offer-primitive/) for the full design.

### Validation

The platform validates before deployment:
1. All required `#shape` fields have concrete values
2. Values match type constraints
3. No unresolved references in component specs

Deployment fails if validation fails.

---

## Operational Claim Fulfillment

Operational claims are fulfilled by transformers that generate platform resources. These transformers are linked to their corresponding `#Offer` definitions (enhancement 007). A capability provider (K8up, Velero, cert-manager) packages the Offer with its Transformers, creating a formal link between the capability declaration and its implementation.

| Claim | Offer (007) | Transformer generates |
|-------|-------------|----------------------|
| `#BackupClaim` | `#BackupOffer` | K8up Schedule CR + optional PreBackupPod CR |

The fulfillment flow:

1. Module component declares `#BackupClaim`
2. Platform checks `#composedOffers` — is `#BackupOffer` present? (pre-render validation)
3. Matcher finds the `BackupTransformer` (linked to `#BackupOffer` via the provider)
4. Transformer generates K8up Schedule CR

If no transformer is registered for a claim, the CLI prints a warning:

```
warning: claim "backup" on component "jellyfin" cannot be fulfilled —
  no transformer registered for opmodel.dev/opm/v1alpha1/claims/data/backup@v1
  hint: add a backup capability provider to your platform definition
```

The module deploys without the unfulfilled claim's resources.

---

## Orchestration Fulfillment

Orchestrations are read by the CLI/controller at operation time:

| Orchestration | Executor | Trigger |
|---------------|----------|---------|
| `#RestoreOrchestration` | CLI | `opm release restore` |
| `#SharedNetworkOrchestration` | Transformer | Deploy time |

See `005-requirement-primitive/10-cli-integration.md` for the `opm release restore` command design.

---

## CUE Late-Binding: Open Investigation

Data claims depend on CUE's ability to:
1. Let the module author reference `spec.postgres.host` (a `string` type at author time)
2. Let the platform inject `"pg.svc.cluster.local"` (a concrete value at deploy time)
3. Have the concrete value flow through to the component's env var

### Options

**Option A: ModuleRelease Unification** — CUE unifies release values with the module's claim shapes. Most CUE-native.

**Option B: Pre-processing Rewrite** — Replace references before CUE evaluation.

**Option C: Parallel Config Merge** — Separate structure merged at evaluation time.

### Recommendation

Option A is preferred. A spike is required to verify CUE supports this pattern. **This spike must be completed before implementation.**
